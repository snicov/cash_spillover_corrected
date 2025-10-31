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


/*** Merging and combining final household dataset sans treatment with village HH treatment variables ***/
project, uses("$dt/HH_spatial_sans_treat.dta")
project, uses("$dt/Village_spatialtreat_forHH.dta")

use "$dt/HH_spatial_sans_treat.dta", clear

merge m:1 village_code using "$dt/Village_spatialtreat_forHH.dta"
drop _merge // all merge

sort sublocation_code village_code hhid_key
order sublocation_code village_code hhid_key survey_mth eligible treat hi_sat

** check magnitudes **
bys village_code: gen a = 1 if _n == 1
sum pp_actamt_0to2km if a == 1 // on average, villages get 7.7% of per capita GDP in their 0to2km buffer.
sum pp_actamt_ov_0to2km if a == 1 // on average, villages get 7.7% of per capita GDP in their 0to2km buffer.
sum pp_actamt_ownvill if a == 1 // on average, villages get 7.7% of per capita GDP in their 0to2km buffer.
drop a

** see if amount related to treatment status **
bys village_code: gen a = 1 if _n == 1
reg pp_actamt_ov_0to2km treat if a == 1 // treatment villages get 6.7% of GDP in their smallest buffer, control villages 8.7%
reg pp_actamt_0to2km hi_sat if a == 1 // high vs. low saturation makes little difference for the 0to2km treatment
reg pp_actamt_0to2km treat hi_sat if a == 1 // high vs. low saturation makes little difference for the 0to2km treatment
drop a

sort hhid_key, stable
gen hhid = _n
order village_code hhid hhid_key

** ADD NOTE ON WHEN DATASET CREATED
notes: Dataset created at TS

** bring in baseline balance vars
merge 1:n hhid_key using "$da/GE_HH-Analysis_AllHHs_nofillBL.dta", keepusing(female_BL age25up_BL married_BL stdschool_BL haschildhh_BL selfemp_BL emp_BL )
keep if _merge == 3
drop _merge

foreach var in p1_assets_wins_PPP_BL p3_totincome_wins_PPP_BL p4_totrevenue_wins_PPP_BL{
	summ `var'
	gen `var'_z = (`var' - `r(mean)')/`r(sd)'
}

save "$da/GE_HHLevel_ECMA.dta", replace
project, creates("$da/GE_HHLevel_ECMA.dta")
