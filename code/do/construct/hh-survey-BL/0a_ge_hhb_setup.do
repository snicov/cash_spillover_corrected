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

/*** SETTING UP FOR THE BASELINE DATA CONSTRUCTION PROCESS ***/

/************************************************/
/*** LOADING DATA ***/
project, original("$dr/GE_HH-Survey-BL_PUBLIC.dta")
use "$dr/GE_HH-Survey-BL_PUBLIC.dta", clear

** display notes for when this dataset was created **
notes _dta


/**************************/
/*  SECTION 1             */
/**************************/

/** Dropping surveys with no consent/unable to continue **/
tab s1_consent, m
tab s1_q11_proceed, m

keep if s1_consent==1
drop if s1_q11_proceed != 1

tab s1_q2c_village

** bringing in census eligibility **
cap drop hhid_key
gen hhid_key = s1_hhid_key

** TO DO: this should be changed to the sample master dataset **
project, original("$dr/GE_HH-SampleMaster_PUBLIC.dta") preserve
merge 1:1 hhid_key using "$dr/GE_HH-SampleMaster_PUBLIC.dta", keepusing(hhid_key eligible treat* hi_sat) gen(_m1)

assert _m1 != 1 // there should be no obs that don't match sample master
keep if _m1 == 3 // dropping those that are only in sample master

tab treat

gen control = 1 - treat
gen lowsat =  1 - hi_sat


* generating additional treatment variables - some of these can be incorporated into sample master
gen low_sat = hi_sat == 0 if ~mi(hi_sat)
gen control_eligible = control * eligible
gen control_lowsat = control * low_sat
gen elig_control_lowsat = eligible * control * low_sat


** saving setup dataset **
save "$da/intermediate/GE_HH-BL_setup.dta", replace
project, creates("$da/intermediate/GE_HH-BL_setup.dta")
