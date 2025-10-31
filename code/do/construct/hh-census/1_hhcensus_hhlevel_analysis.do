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


/***** LOADING DATASET *****/
project, original("$dr/GE_HH-Census-BL_PUBLIC.dta")

use "$dr/GE_HH-Census-BL_PUBLIC.dta", clear


/* checking and cleaning variables */
gen roof_elig = 0 if ~mi(roof)
replace roof_elig = 1 if inlist(roof, "grass", "leaves")
replace roof_elig = 1 if inlist(roof_other, "Canvas", "Canvas Tent", "Canvas tent", "Polythene and grass", "Polythine  bags", "Reeds and grass", "Unfinished (grass and polythene)")

gen walls_elig = 0 if ~mi(walls)
replace walls_elig = 1 if inlist(walls, "mud", "none_incomplete", "half")
replace walls_elig = 1 if inlist(walls_other, "Canvas Tent", "Canvas tent", "")

gen floor_elig = 0 if ~mi(floor)
replace floor_elig = 1 if inlist(floor_other, "mud", "half") 
replace floor_elig = 1 if inlist(floor_other, "Incomplete", "No floor", "None")

gen eligible_check1 = roof_elig == 1
gen eligible_check2 = (roof_elig ==1 & walls_elig == 1 & floor_elig == 1)

tab eligible eligible_check1

gen eligible_all = (roof_elig == 1 & floor_elig == 1 & walls_elig == 1)
la var eligible_all "Eligible (100% traditional)"

* marital status
tab marital_status, m
gen single = (marital_status == "single") if marital_status != ""
gen couple = (marital_status == "couple") if marital_status != ""
gen widow = (marital_status == "widow_widower" & who_hh == "female") if marital_status != ""
gen widower = (marital_status == "widow_widower" & who_hh == "male") if marital_status != ""
gen poly = (marital_status == "polygamous") if marital_status != ""

tab has_biz
tab biz_location1

gen entI = (has_biz == "yes")
gen homebizI = (biz_location1 == "in_home") if biz_location1 != ""
gen villbizI = (biz_location1 == "within_village") if biz_location1 != ""
gen outbizI = (biz_location1 == "outside_village") if biz_location1 != ""

summ *I


/***** MERGING IN VILLAGE-LEVEL TREATMENT STATUS VARIABLES *****/
merge n:1 village_code using "$dr/GE_Treat_Status_Master.dta", keepusing(treat hi_sat widow_pilot_sample widow_pilot_treat)
drop if _merge == 2 // these should be flagged villages

gen treat_hisat = treat * hi_sat

/***** SAVING DATASET *****/
compress
note: Dataset created at TS

save "$da/GE_HH-Census_Analysis_HHLevel.dta", replace
project, creates("$da/GE_HH-Census_Analysis_HHLevel.dta")
