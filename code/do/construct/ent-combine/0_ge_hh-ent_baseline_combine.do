/* Preliminaries */
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

*** START WITH BASELINE SAMPLING FRAME **********
*** This comes from the endline tracking sheet **
*************************************************
/* OLD
project, original("$dr/GE_Endline_Ent_Census_Tracking_Dataset_2017-01-31.dta")
use "$dr/GE_Endline_Ent_Census_Tracking_Dataset_2017-01-31.dta", clear
ren ent_id ent_id_BL
ren hhc_num_hhc hh_ent_id_BL
tostring village_code, gen(hhid_key) format("%12.0f")
gen frid = string(fr_id)
replace frid = "0" + frid if length(frid) == 2
replace frid = "00" + frid if length(frid) == 1
replace hhid_key = hhid_key + "-" + frid
replace hhid_key = "" if data_source == "ENT_Census / ENT_Survey"

keep location_code location sublocation_code sublocation village_code village ent_id_BL fr_id hhid_key hh_key hhid_key hh_ent_id_BL data_source
order location_code location sublocation_code sublocation village_code village ent_id_BL fr_id hhid_key hh_key hh_ent_id_BL data_source
*/

project, original("$dr/GE_ENT-SampleMaster_PUBLIC.dta")
use "$dr/GE_ENT-SampleMaster_PUBLIC.dta", clear

keep if data_source_BL != "" // baseline frame

gen double village_code = ENT_CEN_EL_village_code
replace village_code = HH_AGENT_BL_village_code if mi(village_code)

bys village_code hh_ent_id_BL ent_id_BL (ent_id_universe): drop if _n > 1

** Merge in baseline enterprise and household census information **
project, uses("$da/GE_ENT-Census_Baseline_Analysis_ECMA.dta") preserve
merge 1:1 village_code hh_ent_id_BL ent_id_BL using "$da/GE_ENT-Census_Baseline_Analysis_ECMA.dta", gen (a)
** a == 1 : Those are presumably from the enterprise survey, not census **


** Merge in the baseline enterprise survey information
preserve
keep if ent_id_BL != .
project, uses("$da/GE_ENT-Survey-BL_Analysis_ECMA.dta") preserve
merge 1:1 village_code ent_id_BL using "$da/GE_ENT-Survey-BL_Analysis_ECMA.dta", gen(b)
** all of those match. We have survey information on about 60% of the censused enterprises.
tab a b // Indeed, the 148 additional enterprises are all from the enterprise survey (except 1. What is going on??)
foreach v of var consent open open_7d roof walls floors operate_from bizcat bizcat_products bizcat_nonfood bizcatsec bizcatsec_products bizcatsec_nonfood bizcatter bizcatquar bizcat_cons bizcatsec_cons bizcatter_cons bizcatquar_cons ent_start_year ent_start_month ent_age op_jan op_feb op_mar op_apr op_may op_jun op_jul op_aug op_sep op_oct op_nov op_dec op_seasonal op_monperyear op_M op_T op_W op_Th op_F op_Sa op_Su op_daysperweek op_hoursperweek /*op_hoursperday*/ owner_f owner_education owner_primary owner_secondary owner_degree owner_resident cust_perday cust_perweek cust_svillage cust_ssublocation cust_slocation cust_stown cust_sother emp_n_tot emp_n_family emp_n_nonfamily emp_n_f emp_n_m emp_h_tot emp_h_family emp_h_nonfamily emp_h_f emp_h_m wage_total wage_h wage_m_pp rev_mon rev_year prof_mon prof_year revprof_incons c_rent c_security electricity electricity_national electricity_genrator electricity_battery electricity_solar d_licensed d_registered t_license t_marketfees t_county t_national t_chiefs t_other {
	ren `v' ENT_SUR_BL_`v'
}

ren hh_key hh_key_BL

keep location_code sublocation_code village_code ent_id_BL fr_id_BL hh_ent_id_BL hh_key_BL hh_ent_id_BL ENT_CEN* ENT_SUR*
tempfile temp
save `temp'
restore

drop _merge
merge 1:1 village_code hh_ent_id_BL ent_id_BL using `temp' // All merge as they should
drop a _merge

** Merge in the baseline enterprise information from the BL household survey **
** Note, the hh survey was not used in creating the sampling frame -- thus, there might be additional enterprises.

project, original("$dr/GE_HH-Census-BL_PUBLIC.dta") preserve
merge m:1 hhid_key using "$dr/GE_HH-Census-BL_PUBLIC.dta", gen(abc)

** It should be easy to match households that only have one business **
preserve
project, uses("$da/intermediate/GE_HH-ENT-Survey_Baseline_CLEAN_FINAL.dta")
use "$da/intermediate/GE_HH-ENT-Survey_Baseline_CLEAN_FINAL.dta", clear
cap drop a
bys hhid_key: gen a = _N
tab a //
keep if a == 1
drop a
foreach v of var consent bizcat bizcat_products bizcat_nonfood bizcat_cons ent_start_year ent_start_month ent_age op_jan op_feb op_mar op_apr op_may op_jun op_jul op_aug op_sep op_oct op_nov op_dec op_seasonal op_monperyear op_hoursperweek owner_f owner_age owner_education owner_primary owner_secondary owner_degree owner_resident emp_n_tot emp_n_family wage_total rev_mon rev_year prof_mon prof_year revprof_incons c_rent c_utilities c_repairs c_healthinsurance c_vandalism d_licensed d_registered t_license t_marketfees t_county t_national t_chiefs t_other {
	cap rename `v' HH_ENT_SUR_BL_`v'
}
cap: drop _merge
tempfile temp2
save `temp2'
restore

cap: drop _merge
merge m:1 hhid_key using `temp2'
tab _merge if data_source_BL == ""
tab _merge has_biz if data_source_BL == ""
tab _merge biz_location1

** There are 985 enterprises in the household survey (3/4!!) that are classified as within-hh/within-village but do not show up in the tracking sheet.
** The reason is that the HH Census was used to create the tracking sheet, and there are:
** 980 households are classified as either a) having no enterprise, or b) an enterprise outside the village
** 866 hh have no enterpise in the census, but report having one in the survey
** 105 hh have an enterprise 'outside the village' in the census, but 'inside the hh / village' in the survey.
** We take the tracking sheet as reference

drop if abc == 2 // those are households from the HH Census
drop today key ipaid infosource homeless roof roof_other walls walls_other floor floor_other marital_status who_hh has_biz biz_category1 biz_relationship1 biz_revenue1 biz_profit1 biz_location1 biz_category2 biz_relationship2 biz_revenue2 biz_profit2 biz_location2 bizcatnonfood1 bizcatnonfood2 fr_id master_fr_id biz_category3 bizcatnonfood3 biz_relationship3 biz_revenue3 biz_profit3 biz_location3 abc location_name sublocation_name village_name
tab _merge
drop if _merge == 2 // those are hhid_key that need to be fixed.
** Bottom line, only 347 hh enterprises in the tracking sheet merge with the survey.

** Deal with households that have multiple firms (in the tracking sheet) **
cap drop a
bys hhid_key: gen a = _N
tab a _merge // only 3 households merge because they only have one enterprise in the survey, but two in the census
browse if a > 1 & _merge == 3 // figure out which one corresponds

foreach v of var HH_ENT_SUR_BL_* {
	capture: replace `v' = . if hh_ent_id_BL == 2705
	capture: replace `v' = "" if hh_ent_id_BL == 2705

	capture: replace `v' = . if hh_ent_id_BL == 2728
	capture: replace `v' = "" if hh_ent_id_BL == 2728

	capture: replace `v' = . if hh_ent_id_BL == 4554
	capture: replace `v' = "" if hh_ent_id_BL == 4554
}

drop _merge


**************************************************
*** Append baseline household farm enterprises ***
**************************************************
preserve
project, original("$dr/GE_HH-Census-BL_PUBLIC.dta") preserve
use "$dr/GE_HH-Census-BL_PUBLIC.dta", clear

gen HH_AGENT_CEN_BL = 1
ren today HH_AGENT_CEN_BL_date
ren fr_id fr_id_BL

foreach v of var location_code sublocation_code village_code  {
	ren `v' HH_AGENT_CEN_BL_`v'
}

keep fr_id_BL hhid_key HH_AGENT_CEN_BL*
order fr_id_BL hhid_key HH_AGENT_CEN_BL HH_AGENT_CEN_BL*

** merge in baseline census information **
project, uses("$da/GE_HH-Survey-BL_AgEnterprises_Analysis_ECMA.dta") preserve
merge 1:1 hhid_key using "$da/GE_HH-Survey-BL_AgEnterprises_Analysis_ECMA.dta"
drop if _merge == 2 
gen HH_AGENT_SUR_BL = (_merge == 3)
drop _merge

foreach v of var consent bizcat bizcat_cons owner_f owner_age owner_education owner_primary owner_secondary owner_degree owner_resident wage_total rev_year prof_year revprof_incons c_total c_tools c_animalmed c_fertilizer c_irrigation c_seeds c_insurance {
	ren `v' HH_AGENT_SUR_BL_`v'
}

tempfile temp
save `temp'
restore

drop a
append using `temp'

replace HH_AGENT_CEN_BL = 0 if HH_AGENT_CEN_BL == .
replace HH_AGENT_SUR_BL = 0 if HH_AGENT_SUR_BL == .

drop location_name sublocation_name village_name

**********************************************
*** SAVE COMBINED CLEANED BASELINE DATASET ***
**********************************************
save "$da/GE_HH-ENT_Baseline_Combined.dta", replace
project, creates("$da/GE_HH-ENT_Baseline_Combined.dta")
