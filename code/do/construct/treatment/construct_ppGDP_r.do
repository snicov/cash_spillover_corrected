
/* do file header */
return clear
capture project, doinfo
if (_rc==0 & !mi(r(pname))) global dir `r(pdir)'  // using -project-
else {  // running directly
		if ("${ge_dir}"=="") do `"`c(sysdir_personal)'profile.do"'
		do "${ge_dir}/do/set_environment.do"
}
* Import config - running globals
/* Note: it's unclear if this will actually do anything here, or if it will need to
	 be a part of each file */
project, original("$dir/do/GE_global_setup.do")
include "$dir/do/GE_global_setup.do"

// end preliminaries

* load commands
project, original("$do/programs/run_ge_build_programs.do")
include "$do/programs/run_ge_build_programs.do"

** Set depreciation rate **
global deprate = 0.1


** Get number of people per household **
****************************************

* Calculating share eligible and share ineligible from census data
project, uses("$da/GE_HH-Census_Analysis_HHLevel.dta")
use "$da/GE_HH-Census_Analysis_HHLevel.dta", clear

summ eligible

local share_elig = r(mean)
local share_inelig = 1 - `share_elig'

* Bring in data from HH surveys
project, uses("$da/GE_HH-Survey-BL_Analysis_AllHHs.dta")
use "$da/GE_HH-Survey-BL_Analysis_AllHHs.dta", clear

* s4_q1_hhmembers contains the answer to "How many people (not including yourself) live in your household..."
gen num_hh_members = hhsize1_BL

summ num_hh_members
ttest num_hh_members, by(eligible_baseline_BL)
/*TK  NOTE: This is currently based off of calculation of eligibility at baseline. Still need to compare this
   against eligibility as calculated at the time of the census */

summ num_hh_members if eligible_baseline_BL == 1
local people_elig = r(mean)
summ num_hh_members if eligible_baseline_BL == 0
local people_inelig = r(mean)

global people_per_hh = `share_elig'*`people_elig' + `share_inelig'*`people_inelig'
disp "People per household: $people_per_hh"


** Calculate GDP per capita based on the expenditure approach **
****************************************************************

** Household expenditure **
***************************
project, uses("$da/GE_HH-Analysis_AllHHs.dta")
use "$da/GE_HH-Analysis_AllHHs.dta", clear

** add weights ***
drop if hhid_key == ""
project, uses("$da/GE_HH-Survey_Tracking_Attrition.dta") preserve
merge 1:1 hhid_key using "$da/GE_HH-Survey_Tracking_Attrition.dta", keep(1 3) nogen

** Bring in deflator **
project, uses("$da/intermediate/pricedeflator.dta") preserve
merge m:1 village_code survey_mth using "$da/intermediate/pricedeflator.dta"
drop if _merge == 2
drop _merge

egen deflator_ann = rowtotal(deflator_l1-deflator_l12)
replace deflator_ann = deflator_ann / 12

** number of households in low-sat control areas **
sum hhweight_EL if treat == 0 & hi_sat == 0
local nhh_lowsat_control = r(sum)

** consumption per capita **
gen p2_consumption_wins_r = p2_consumption_wins/deflator_ann
sum p2_consumption_wins_r if treat == 0 & hi_sat == 0 [aweight=hhweight_EL]
local pp_cons_r = r(mean) / $people_per_hh // household average / average number of people per hh

** asset depreciation per capita **
gen p1_assets_wins_r = p1_assets_wins/deflator
sum p1_assets_wins_r if treat == 0 & hi_sat == 0 [aweight=hhweight_EL]
local pp_assets_dep_r = r(mean) / $people_per_hh * $deprate // household average / number of people per hh * annual depreciation rate of stocks


** Enterprise expenditure **
****************************
** Note: We exlude investment and inventory depreciation by own-farm agriculture **
** We did not measure it **
project, uses("$da/GE_ENT-Analysis_AllENTs.dta")
use "$da/GE_ENT-Analysis_AllENTs.dta", clear
gen survey_mth = mofd(date)
format survey_mth %tm

** Bring in deflator **
merge m:1 village_code survey_mth using "$da/intermediate/pricedeflator.dta"
drop if _merge == 2
drop _merge

egen deflator_ann = rowtotal(deflator_l1-deflator_l12)
replace deflator_ann = deflator_ann / 12

** number of non-ag enterprises in low_sat control areas **
sum entweight_EL if treat == 0 & hi_sat == 0 & inlist(ent_type,1,2)
local nent_nonag_lowsat_control = r(sum)

** enterprise investment **
gen ent_inv_wins_r = ent_inv_wins/deflator_ann
sum ent_inv_wins_r if treat == 0 & hi_sat == 0 [aweight=entweight_EL]
local pp_ent_inv_r = r(mean) * `nent_nonag_lowsat_control' / `nhh_lowsat_control' / $people_per_hh
** average investment per firm * number of firms / number of households / number of people per household

** enterprise inventory **
gen ent_inventory_wins_r = ent_inventory_wins/deflator
sum ent_inventory_wins if treat == 0 & hi_sat == 0 [aweight=entweight_EL]
local pp_inventory_dep_r = r(mean) * `nent_nonag_lowsat_control' / `nhh_lowsat_control' / $people_per_hh * $deprate
** average investment per firm * number of firms / number of households / number of people per household * annual depreciation rate of stocks


** Government expenditure **
****************************
local pp_govt_exp_r = 522 // TK MW to bring in calculation here

** Aggregate to total GDP **
****************************
global pp_GDP_r =  `pp_cons_r' + `pp_assets_dep_r' + `pp_ent_inv_r' + `pp_inventory_dep_r' + `pp_govt_exp_r'
disp "Annual per capita GDP (in KES): $pp_GDP"

** Save dataset **
clear
insobs 1
gen pp_GDP_r = $pp_GDP_r
gen pp_cons_r = `pp_cons_r'
gen pp_assets_dep_r = `pp_assets_dep_r'
gen pp_ent_inv_r = `pp_ent_inv_r'
gen pp_inventory_dep_r = `pp_inventory_dep_r'
gen pp_govt_exp_r = `pp_govt_exp_r'
gen nhh_lowsat_control_r = `nhh_lowsat_control'
gen nent_nonag_lowsat_control_r = `nent_nonag_lowsat_control'

*project, uses("$dt/pp_GDP_calculated_nominal.dta") preserve
append using "$dt/pp_GDP_calculated_nominal.dta"
collapse _all

save "$da/pp_GDP_calculated.dta", replace
project, creates("$da/pp_GDP_calculated.dta")
