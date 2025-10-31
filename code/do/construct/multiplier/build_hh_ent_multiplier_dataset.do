*************************************
* Build Multiplier Dataset
* Tilman Graff
* 2019-07-24
* This file constructs a joint enterprise + household dataset with which we can
*************************************
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

project, uses("$da/pp_GDP_calculated.dta")
use "$da/pp_GDP_calculated.dta", clear
global pp_GDP = pp_GDP[1]
global pp_GDP_r = pp_GDP_r[1]
clear

// end preliminaries

* load commands
project, original("$do/programs/run_ge_build_programs.do")
include "$do/programs/run_ge_build_programs.do"


*************************************
** 0. Import Everything and Merge **
*************************************

** get total number of households by group and village **
project, uses("$da/GE_HHLevel_ECMA.dta") preserve
use "$da/GE_HHLevel_ECMA.dta", clear
keep village_code treat hi_sat eligible hhweight_EL
bys village_code: egen n_elig = sum(hhweight_EL) if eligible == 1
bys village_code: egen n_inelig = sum(hhweight_EL) if eligible == 0
bys village_code: egen n_hh = sum(hhweight_EL)
bys village_code: egen n_hh_treat = sum(hhweight_EL) if eligible == 1 & treat == 1
replace n_hh_treat = 0 if treat == 0
bys village_code: egen n_hh_untreat = sum(hhweight_EL) if eligible == 0 | treat == 0

sum hhweight_EL if treat == 1
global n_hh_treatall = `r(sum)'

sum hhweight_EL if treat == 0
global n_hh_controlall = `r(sum)'

sum hhweight_EL if treat == 0 & hi_sat == 0
global n_hh_lowsatcontrol = `r(sum)'

sum hhweight_EL if eligible == 1 & treat == 1
global n_hh_treat = `r(sum)'
sum hhweight_EL if eligible == 0 | treat == 0
global n_hh_untreat = `r(sum)'
sum hhweight_EL
global n_hh_tot = `r(sum)'

collapse (mean) n_elig n_inelig n_hh n_hh_treat n_hh_untreat, by(village_code)
tempfile temphh
save `temphh'

** get total number of enterprises by group and village **
project, uses("$da/GE_VillageLevel_ECMA.dta") preserve
use "$da/GE_VillageLevel_ECMA.dta", clear
cap la var n_allents "Number of enterprises"
cap la var n_operates_from_hh "Number of enterprises, non-ag operated from hh"
cap la var n_operates_outside_hh "Number of enterprises, non-ag operated outside hh"
cap la var n_ent_ownfarm "Number of enterprises, own-farm agriculture"
keep village_code n_allents n_operates_from_hh n_operates_outside_hh
tempfile tempent
save `tempent'


** Get amount transfered per treated eligible household -- nominal and deflated **
project, uses("$da/village_actualtreat_wide_FINAL.dta")
use "$da/village_actualtreat_wide_FINAL.dta", clear
keep village_code month amount_total_KES_ownvill amount_total_KES_ownvill_r p_total_ownvill
replace amount_total_KES_ownvill = amount_total_KES_ownvill * p_total_ownvill // now, amount_total_KES_ownvill is the total amount transfered in KES
sum amount_total_KES_ownvill

global amt_per_hh_treated = `r(sum)' / $n_hh_treat
disp "$amt_per_hh_treated"

** now deflated version **
replace amount_total_KES_ownvill_r = amount_total_KES_ownvill_r * p_total_ownvill // now, amount_total_KES_ownvill is the total amount transfered in KES
sum amount_total_KES_ownvill_r

global amt_per_hh_treated_r = `r(sum)' / $n_hh_treat
disp "$amt_per_hh_treated_r"

** Get actual and experimental start dates **
project, uses("$dt/GE_experimental_timing_long_FINAL.dta")
use "$dt/GE_experimental_timing_long_FINAL.dta", clear
collapse (first) act_start_c exp_start_1 treat, by(village_code)
gen transfersstart = act_start_c
replace transfersstart = exp_start_1 if mi(transfersstart)
format transfersstart %tm
ren transfersstart survey_mth
project, uses("$da/intermediate/pricedeflator.dta") preserve
merge n:1 village_code survey_mth using "$da/intermediate/pricedeflator.dta", keep(3) nogen keepusing(deflator)
ren survey_mth transfersstart
ren deflator transferdeflator
tempfile startdates
save `startdates'


**************************
** Now combine all data **
**************************
project, uses("$da/GE_HHLevel_ECMA.dta")
use "$da/GE_HHLevel_ECMA.dta", clear
destring sublocation_code, replace
project, uses("$da/GE_HHTemporal_ECMA.dta") preserve
merge 1:1 hhid_key using "$da/GE_HHTemporal_ECMA.dta"
drop _merge // works well!

* generate expenditure excluding furniture
gen p2_exp_for_multiplier = p2_consumption - h2_8_hhdurablesexp
wins_top1 p2_exp_for_multiplier

* generate assets with housing value **
gen totval_hhassets_h = totval_hhassets + h1_10_housevalue
wins_top1 totval_hhassets_h


** generate baseline multiplier asset measure ** (this should now be coming earlier)
//gen totval_hhassets_PPP_BL = assets_agtools_PPP_BL + assets_livestock_PPP_BL + assets_prod_nonag_PPP_BL + assets_nonprod_PPP_BL
//wins_top1 totval_hhassets_PPP_BL
//gen Mtotval_hhassets_PPP_BL = mi(totval_hhassets_PPP_BL)

** merge in enterprise outcomes for own-farm data **
preserve
project, uses("$da/GE_Enterprise_ECMA.dta") preserve
use "$da/GE_Enterprise_ECMA.dta", clear
keep if ent_type == 3
tempfile temp
save `temp'
restore

cap destring sublocation_code, replace

merge 1:1 hhid_key using `temp'
drop _merge // works well!

** merge in enterprise outcomes for non-agricultural businesses **
preserve
project, uses("$da/GE_Enterprise_ECMA.dta") preserve
use "$da/GE_Enterprise_ECMA.dta", clear
drop if ent_type == 3
project, uses("$da/Ent_SpatialData_Temporal.dta") preserve
merge 1:m entcode_EL using "$da/Ent_SpatialData_Temporal.dta"
drop if _merge != 3
drop _merge
tempfile temp
save `temp'
restore

append using `temp'

** Merge in village level totals **
merge m:1 village_code using `temphh'
drop _merge
merge m:1 village_code using `tempent'
drop _merge

** Merge in months since
project, uses("$da/GE_HH-Analysis_AllHHs.dta") preserve
merge m:1 village_code using `startdates', keepusing(exp_start_1)
gen months_since_exp_start = survey_mth - exp_start_1

** Merge in lagged deflators
project, uses("$da/intermediate/pricedeflator.dta") preserve
merge n:1 village_code survey_mth using "$da/intermediate/pricedeflator.dta", keep(3) nogen keepusing(deflator*)

** This dataset now contains all enterprises and all household outcomes

*************************************
** 0. Rename long variable names
*************************************

foreach v of varlist pp_actamt_*{
	loc newname = subinstr("`v'", "pp_actamt_", "pac_", 1)
	ren `v' `newname'
}

ren p2_exp_for_multiplier_wins p2_exp_mult_wins

*************************************
** Set outcomes relative to the transfer amount **
*************************************
sort village_code hhid_key

replace aglandcost_wins = 0 if aglandcost_wins == .
replace ent_rent_wins = 0 if ent_rent_wins == .
gen ent_rentcost_wins = (aglandcost_wins + ent_rent_wins) // this includes rental and land rental costs of enterprises
cap: gen ent_rentcost_wins_BL = (aglandcost_wins_BL + ent_rent_wins_BL) // this includes rental and land rental costs of enterprises

/* in the following we need to distinguish between variables that are asked monthly (How much wages did you pay last month? etc) and then annualised. And those that are
   immediately asked for the entire year (how much eages did you earn in the last 12 months in total? etc). This is important because we need to deflate this differently.
*/

** deflate and normalise those variables that are asked monthly or which are annualised
foreach v of var ent_profit2_wins ent_wagebill_wins ent_rentcost_wins ent_inv_wins {
	gen `v'_r = (`v' / deflator) / $amt_per_hh_treated_r / 4
	replace `v' = `v' / $amt_per_hh_treated / 4
}

** deflate and normalise those variables that are asked retrospectively for the entire year
forval i = 0/11 {
	gen a`i' = ln(deflator_l`i')
}
egen deflator_ann = rowtotal(a0-a11)
replace deflator_ann = deflator_ann / 12
replace deflator_ann = exp(deflator_ann)
drop a? a??

foreach v of var p2_exp_mult_wins nondurables_exp_wins p3_3_wageearnings_wins p3_totincome_wins ent_totaltaxes_wins {
	gen `v'_r = (`v' / deflator_ann) / $amt_per_hh_treated_r / 4
	replace `v' = `v' / $amt_per_hh_treated / 4
}

foreach v of var p1_assets_wins /*multiplier_assets_wins*/ totval_hhassets_wins totval_hhassets_h_wins ent_inventory_wins {
	gen `v'_r = (`v' / deflator) / $amt_per_hh_treated_r
	replace `v' = `v' / $amt_per_hh_treated
}


*************************************
** a. Generate additional variables **
*************************************

** Here, we prepare the dataset, and set quantities that remain the same across all iterations **
** This should save time when we actually iterate **

** Generate quarter dummies for consumption IRF **
gen quarter = qofd(dofm(survey_mth))

** generate interactions of quarterly treatment measures **
gen ineligible = 1 - eligible

foreach inst in pac {
	foreach loc in ownvill 0to2km ov_0to2km 2to4km ov_2to4km 4to6km ov_4to6km 6to8km ov_6to8km 8to10km ov_8to10km {
		forval q = 1/10 {
			gen `inst'_`loc'_el_q`q' = `inst'_`loc'_q`q' * eligible
			gen `inst'_`loc'_r_el_q`q' = `inst'_`loc'_r_q`q' * eligible
		}
		forval q = 1/10 {
			gen `inst'_`loc'_in_q`q' = `inst'_`loc'_q`q' * ineligible
			gen `inst'_`loc'_r_in_q`q' = `inst'_`loc'_r_q`q' * ineligible
		}
	}
}

** generate interactions of quarterly instrument measures **
foreach inst in actamt {
	foreach loc in ownvill 0to2km ov_0to2km 2to4km ov_2to4km 4to6km ov_4to6km 6to8km ov_6to8km 8to10km ov_8to10km {
		forval q = 1/10 {
			gen t_shr_`inst'_`loc'_el_q`q' = t_share_`inst'_`loc'_q`q' * eligible
		}
		forval q = 1/10 {
			gen t_shr_`inst'_`loc'_in_q`q' = t_share_`inst'_`loc'_q`q' * ineligible
		}
	}
}

foreach inst in actamt {
	foreach loc in ownvill 0to2km ov_0to2km 2to4km ov_2to4km 4to6km ov_4to6km 6to8km ov_6to8km 8to10km ov_8to10km {
		forval q = 1/10 {
			gen t_shr_`inst'_`loc'_r_el_q`q' = t_share_`inst'_`loc'_r_q`q' * eligible
		}
		forval q = 1/10 {
			gen t_shr_`inst'_`loc'_r_in_q`q' = t_share_`inst'_`loc'_r_q`q' * ineligible
		}
	}
}

** generate interactions of overall instrument measures **
forval r = 2(2)10 {
	local r2 = `r' - 2

	gen pac_`r2'to`r'km_eligible = pac_`r2'to`r'km * eligible
	gen pac_`r2'to`r'km_ineligible = pac_`r2'to`r'km * ineligible

	gen pac_`r2'to`r'km_r_eligible = pac_`r2'to`r'km_r * eligible
	gen pac_`r2'to`r'km_r_ineligible = pac_`r2'to`r'km_r * ineligible

	gen share_ge_elig_treat_`r2'to`r'km_el = share_ge_elig_treat_`r2'to`r'km * eligible
	gen share_ge_elig_treat_`r2'to`r'km_in = share_ge_elig_treat_`r2'to`r'km * ineligible
}

order share_ge_elig_treat_*km_el, last sequential
order share_ge_elig_treat_*km_in, last sequential

order pac_ov_*km, last sequential
order pac_ownvill, last sequential
order pac_*km, last sequential
order pac_*km_eligible, last sequential
order pac_*km_ineligible, last sequential
order pac_*km_el_q?*, last sequential
order pac_*km_in_q?*, last sequential

order pac_ov_*km_r, last sequential
order pac_ownvill_r, last sequential
order pac_*km_r, last sequential
order pac_*km_r_eligible, last sequential
order pac_*km_r_ineligible, last sequential
order pac_*km_r_el_q?*, last sequential
order pac_*km_r_in_q?*, last sequential

*************************************
** Save **
*************************************

* keeping only variables needed for multiplier datasets
local identifiers "*hhid* village_code sublocation_code satcluster treat hi_sat eligible ineligible *ent_type* *weight* survey_mth *market_access* ent_id_universe"
local outcomes "*p2_exp_mult_wins* *nondurables_exp_wins* *totval_hhassets_wins* *totval_hhassets_h* *h1_10_housevalue_wins* *ent_inv_wins* *p3_3_wageearnings_wins* *p3_totincome_wins* *ent_profit2_wins* *ent_rentcost_wins* *ent_totaltaxes_wins* *ent_inventory_wins*"
local end_exg "pac_*  *share_* quarter *shr*" 

keep `identifiers' `outcomes' `end_exg'

save "$da/HH_ENT_Multiplier_Dataset_ECMA.dta", replace
project, creates("$da/HH_ENT_Multiplier_Dataset_ECMA.dta")
