/*
 * Filename: ge_hh-survey-EL_data_setup.do
 * Description: This do file loads the raw household endline survey data
 *    runs some checks, and merges in status information from the census.
 *    These are needed for some of the construction. It also drops non-consents.
 */

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


project, original("$dr/GE_HH-Survey-EL1_PUBLIC.dta")
project, original("$dr/GE_HH-SampleMaster_PUBLIC.dta")

** create required folders **
cap mkdir "$da/intermediate"

/*
* create dataset of ID corrections *
import excel using "~/Dropbox/GE_Endline2/fieldactivities/TrackingSheets/data_final/GE_Survey_to_Census_ID_corrections_EDITED_20191001.xlsx", clear first
ren hhid_key s1_hhid_key
ren SUR_EL_ctokey key
tempfile corrections
save `corrections'
*/

***** LOADING CLEAN DATASET *****
use "$dr/GE_HH-Survey-EL1_PUBLIC.dta", clear


notes _dta // displaying when raw dataset created

* keeping only surveys for which we could proceed. If we oculd not proceed, we do not have data
* Tracking and attrition rates are constructed by separate tracking and attrition do file
drop if s1_q11_proceed != 1

/** Generating and checking identifiers **/
assert village_code == s1_q2c_village // all match
format village_code %14.0f

/* this is now done in cleaning do files
* Checking for duplicates among household keys
duplicates report s1_hhid_key
duplicates list s1_hhid_key
bys s1_hhid_key (today): gen countobs = _n
tab countobs
drop if countobs == 2 // in cases of duplicates, keeping first survey. To do - check to make sure these are the surveys that we want to keep
*/

/*
/* corrections from endline 2 in order to merge with baseline -- figure out where these should be located */
* the following corrections should be made in advance to successfully merge with baseline values *
replace s1_hhid_key = "601010103003-039" if key == "uuid:ed2b8868-bdf0-48c7-b05c-dbc16b623186"
replace s1_hhid_key = "601010103003-072" if key == "uuid:d2afa329-d69a-495d-91f9-a4f837e97276"
replace s1_hhid_key = "601010103003-079" if key == "uuid:a65410ea-2c77-487b-9927-f3d272dd5770"
replace s1_hhid_key = "601010103003-085" if key == "uuid:0556a2f6-eaad-443c-bc62-951943d6f3b5"
replace s1_hhid_key = "601010103003-140" if key == "uuid:b7b45d9f-803b-4e8a-91de-1172fe29c655"


merge 1:1 s1_hhid_key key using `corrections', keepusing(correction correct_hhid_key hhid_key_SUR CEN_BL_ctokey)
drop if _merge == 2
drop _merge

list s1_hhid_key correct_hhid_key if correction == 1

replace s1_hhid_key = correct_hhid_key if correction == 1 & ~mi(correct_hhid_key)

drop if key == "uuid:99bd7eb7-c71e-4423-b433-3082b19785f0" // this is a duplicate of same person, observation not needed for this purpose
drop if key == "uuid:a1dc5f4e-f685-4f5b-b62f-cc73ec82829e" // may want to do one more check through this one -- think right to drop this, but less clear

duplicates report s1_hhid_key
duplicates list s1_hhid_key
*/

* this is likely not meaningful without applying same changes as above to sample master, right?
merge 1:1 s1_hhid_key using "$dr/GE_HH-SampleMaster_PUBLIC.dta", gen(_mb) keepusing(s1_hhid_key eligible treat hi_sat)

** Generating some general variables **
*survey year
format today %td
gen survey_yr = yofd(today)

*survey month
gen survey_mth = mofd(today)
format survey_mth %tm

count


// once re-running, add eligible_control control_lowsat back to this list

desc eligible*, full
tab1 eligible*

gen ineligible = (eligible == 0) if ~mi(eligible)

*** THIS IS SOMETHING TILMAN CHANGED // BE READY TO DELETE IF PRODUCES WEIRD RESULTS WITH STANDARDISATION
gen control = 1 - treat
gen low_sat = 1 - hi_sat
***


gen eligible_control = eligible * control
gen control_lowsat = control * low_sat // drop once new version of Tracking and Attrition dataset created
gen elig_control_lowsat = eligible * control * low_sat
gen control_lowsat_eligible = elig_control_lowsat
gen ineliglible_control_lowsat = ineligible * control * low_sat

drop if _mb!=3 // need to look into those that are in data, but not in sample. Likewise need to make somre final tracking data - those with _mb == 2 are those that declined or that we did not find.


** saving dataset **
save "$da/intermediate/GE_HH-EL_setup.dta", replace
project, creates("$da/intermediate/GE_HH-EL_setup.dta")
