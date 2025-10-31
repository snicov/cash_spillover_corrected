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

*****************************************
*** Load endline census tracking sheet **
*****************************************
project, original("$dr/GE_ENT-SampleMaster_PUBLIC.dta") preserve
use "$dr/GE_ENT-SampleMaster_PUBLIC.dta", clear
gen double village_code = ENT_CEN_EL_village_code

** merge in baseline enterprise census **
preserve
keep if data_source_BL == "ENT_Census / ENT_Survey"

duplicates list ent_id_BL village_code if data_source_BL == "ENT_Census / ENT_Survey"
bys ent_id_BL village_code (ent_id_universe): drop if _n > 1

duplicates report ent_id_BL village_code

project, uses("$da/intermediate/GE_ENT-Census_Baseline_noHHEnt.dta") preserve
merge 1:1 ent_id_BL village_code using "$da/intermediate/GE_ENT-Census_Baseline_noHHEnt.dta"
keep if _merge == 3
drop _merge
foreach v of var consent open open_7d roof walls floors operate_from bizcat bizcat_products bizcat_nonfood bizcatsec bizcatsec_products bizcatsec_nonfood bizcatter bizcatter_nonfood bizcatquar bizcatquar_nonfood bizcatquint bizcat_cons bizcatsec_cons bizcatter_cons bizcatquar_cons bizcatquint_cons owner_f owner_resident openM openT openW openTh openF openSa openSu hours_open {
	ren `v' ENT_CEN_BL_`v'
}
tempfile temp1
save `temp1'
restore

** merge in baseline household census enterprise data **
preserve
keep if data_source_BL == "HH_Census"

duplicates list hh_ent_id_BL
bys hh_ent_id_BL (ent_id_universe): drop if _n > 1

duplicates report hh_ent_id_BL

project, original("$dr/GE_HH-Census-BL_Enterprises_PUBLIC.dta") preserve
merge 1:1 hh_ent_id_BL using "$dr/GE_HH-Census-BL_Enterprises_PUBLIC.dta"
drop _merge // all merge
foreach v of var consent roof walls floors operate_from bizcat bizcat_nonfood bizcat_cons rev_mon prof_mon revprof_incons {
	cap ren `v' HH_ENT_CEN_BL_`v'
}
tempfile temp2
save `temp2'
restore

use `temp1', clear
append using `temp2'

** Bringing in treatment status information **
project, original("$dr/GE_Treat_Status_Master.dta") preserve
merge n:1 village_code using "$dr/GE_Treat_Status_Master.dta", keepusing(treat hi_sat) keep(1 3)

order subcounty location_code sublocation_code village_code  ent_id_BL fr_id hh_key hh_ent_id_BL eligible treat hi_sat data_source_BL

/*** SAVING DATASET ***/
save "$da/GE_ENT-Census_Baseline_Analysis_ECMA.dta", replace
project, creates("$da/GE_ENT-Census_Baseline_Analysis_ECMA.dta")
