
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

* dataset dependencies
project, uses("$da/GE_HH-Census_Analysis_HHLevel.dta")
project, uses("$da/GE_HH-Survey-BL_Analysis_AllHHs.dta")
project, uses("$da/GE_ENT-Analysis_AllENTs.dta")
project, uses("$da/GE_HH-Analysis_AllHHs.dta")

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
project, uses("$da/GE_HH-Survey-BL_Analysis_AllHHs.dta") preserve
use "$da/GE_HH-Survey-BL_Analysis_AllHHs.dta", clear

* s4_q1_hhmembers contains the answer to "How many people (not including yourself) live in your household..."
gen num_hh_members = hhsize1_BL

summ num_hh_members
ttest num_hh_members, by(eligible_baseline_BL)
/* NOTE: This is currently based off of calculation of eligibility at baseline. Still need to compare this
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
project, uses("$da/GE_HH-Analysis_AllHHs.dta") preserve
use "$da/GE_HH-Analysis_AllHHs.dta", clear

** add weights ***
drop if hhid_key == ""
project, uses("$da/GE_HH-Survey_Tracking_Attrition.dta") preserve
merge 1:1 hhid_key using "$da/GE_HH-Survey_Tracking_Attrition.dta"
drop if _merge == 2

** number of households in low-sat control areas **
sum hhweight_EL if treat == 0 & hi_sat == 0
local nhh_lowsat_control = r(sum)

** consumption per capita **
sum p2_consumption_wins if treat == 0 & hi_sat == 0 [aweight=hhweight_EL]
local pp_cons = r(mean) / $people_per_hh // household average / average number of people per hh

** asset depreciation per capita **
sum p1_assets_wins if treat == 0 & hi_sat == 0 [aweight=hhweight_EL]
local pp_assets_dep = r(mean) / $people_per_hh * $deprate // household average / number of people per hh * annual depreciation rate of stocks


** Enterprise expenditure **
****************************
** Note: We exlude investment and inventory depreciation by own-farm agriculture **
** We did not measure it **
project, uses("$da/GE_ENT-Analysis_AllENTs.dta") preserve
use "$da/GE_ENT-Analysis_AllENTs.dta", clear

** number of non-ag enterprises in low_sat control areas **
sum entweight_EL if treat == 0 & hi_sat == 0 & inlist(ent_type,1,2)
local nent_nonag_lowsat_control = r(sum)

** enterprise investment **
sum ent_inv_wins if treat == 0 & hi_sat == 0 [aweight=entweight_EL]
local pp_ent_inv = r(mean) * `nent_nonag_lowsat_control' / `nhh_lowsat_control' / $people_per_hh
** average investment per firm * number of firms / number of households / number of people per household

** enterprise inventory **
sum ent_inventory_wins if treat == 0 & hi_sat == 0 [aweight=entweight_EL]
local pp_inventory_dep = r(mean) * `nent_nonag_lowsat_control' / `nhh_lowsat_control' / $people_per_hh * $deprate
** average investment per firm * number of firms / number of households / number of people per household * annual depreciation rate of stocks


** Government expenditure **
****************************
local pp_govt_exp = 522 // MW to bring in calculation here

** Aggregate to total GDP **
****************************
global pp_GDP =  `pp_cons' + `pp_assets_dep' + `pp_ent_inv' + `pp_inventory_dep' + `pp_govt_exp'
disp "Annual per capita GDP (in KES): $pp_GDP"

** Save dataset **
clear
insobs 1
gen pp_GDP = $pp_GDP
gen phh_GDP = $pp_GDP * $people_per_hh
gen pp_cons = `pp_cons'
gen pp_assets_dep = `pp_assets_dep'
gen pp_ent_inv = `pp_ent_inv'
gen pp_inventory_dep = `pp_inventory_dep'
gen pp_govt_exp = `pp_govt_exp'
gen nhh_lowsat_control = `nhh_lowsat_control'
gen nent_nonag_lowsat_control = `nent_nonag_lowsat_control'
save "$dt/pp_GDP_calculated_nominal.dta", replace
project, creates("$dt/pp_GDP_calculated_nominal.dta")
