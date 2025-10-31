/*
 * Filename: 201_ge_indiv_demog_EL.do
 * DESCRIPTION: This do file constructs a dataset of individual-level demographic data from the endline household roster.
 * Inputs: GE clean endline survey data
 * Output: Long dataset of household roster and demgraphic information, saved in analysis data folder
 */

/*** PART 1: PULLING AND SAVING KEY VARIABLES NEEDED FROM FR ***/
/* Notes: we denote the FR as ID 0, and pull these from the analysis dataset.
   A bit of an open question how we should best handle this as it creates a
   dependency, but using this for now and can re-visit later.
   Keeping only constructed variables */

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

project, uses("$da/GE_HH-Analysis_AllHHs_nofillBL.dta")
use "$da/GE_HH-Analysis_AllHHs_nofillBL.dta", clear

gen hhros_num = 0

* need to make sure that all FR variables that we will want to use are already created as part of FR basics
keep s1_hhid_key village_code hhros_num age* male* female* married* widowed* yearsedu*
//completed_prim* comple

tempfile fr_data
save `fr_data'


/*** GENERATING A LIST OF ADULTS IN HOUSEHOLD FROM ROSTER ***/
// need to figure out how this compares to what Rachel was doing -- have lots of leftover variables from that, need to re-work her do file

** LOADING DATA **
project, uses("$da/GE_HH-Analysis_AllHHs_nofillBL.dta") preserve
use "$da/GE_HH-Analysis_AllHHs_nofillBL.dta", clear

*ren s4_1_q8_occup_0 s4_1_q8_occup_1

tab s4_q1_hhmembers

loc keepstr "s1_hhid_key village_code s4_q1_hhmembers"

** this needs to come somewhere else as part of cleaning **
forval i = 1 / 15 {
    loc keepstr "`keepstr' s4_1_q2a_memberbl_`i' s4_1_q2ab_whyjoin_`i' s4_1_q3_sleep_`i' s4_1_q4_sex_`i' s4_1_q5_age_`i' s4_1_q5a_estimatedage_`i' s4_1_q6_relation_`i' s4_1_q6_relationoth_`i' s4_1_q7_edusystem_`i' s4_1_q7_highestedu_`i' s4_1_q8_occup_`i' s4_1_q8_occupoth1_`i' s4_1_q8_occupoth2_`i' s4_1_q8_occupoth3_`i' s4_1_q9_daysattendsch_`i'"
}


keep `keepstr'


reshape long s4_1_q2a_memberbl_ s4_1_q2ab_whyjoin_ s4_1_q3_sleep_ s4_1_q4_sex_ s4_1_q5_age_ s4_1_q5a_estimatedage_ s4_1_q6_relation_ s4_1_q6_relationoth_ s4_1_q7_edusystem_ s4_1_q7_highestedu_ s4_1_q8_occup_ s4_1_q8_occupoth1_ s4_1_q8_occupoth2_ s4_1_q8_occupoth3_ s4_1_q9_daysattendsch_, i(s1_hhid_key village_code s4_q1_hhmembers) j(hhros_num)

ren s4*_ s4*

** dropping obs with all missing **
drop if hhros_num > s4_q1_hhmembers

egen allmiss = rowmiss(s4_*)
tab allmiss

drop if allmiss >= 15


** GENDER **
gen female = (s4_1_q4_sex == 1) if ~mi(s4_1_q4_sex)
gen male  = (s4_1_q4_sex == 2) if ~mi(s4_1_q4_sex)

** HOUSEHOLD MEMBER AGE **
tab s4_1_q5_age
recode s4_1_q5_age (-99 = .), gen(age)

** OCCUPATION **
split s4_1_q8_occup, gen(occ) destring



** EDUCATION LEVELS **

* YEARS OF EDUCATION *
gen yearsedu = 0 if s4_1_q7_edusystem==2

/* current school system (s4_1_q7_edusystem == 1)- stds 1 -8, then forms 1 - 4 */
/* Up through form 4 are coded from 101 - 112, so subtracting off 100 */
replace yearsedu = s4_1_q7_highestedu - 100 if s4_1_q7_edusystem == 1

/* previous school system (s4_1_q7_edusystem == 3) - stds 1 - 7, forms 1 - 6 */
/* there is no 208 code so need to account for this when subtracting off years of education */
replace yearsedu = s4_1_q7_highestedu - 200 if s4_1_q7_edusystem == 3 & s4_1_q7_highestedu<=207
replace yearsedu = s4_1_q7_highestedu - 201 if s4_1_q7_edusystem == 3 & s4_1_q7_highestedu>207 & s4_1_q7_highestedu<215 /* need to take one extra year off for forms since no 208 code */

* Codes 130/230 -- ECD / pre-K only *
replace yearsedu = 0 if s4_1_q7_highestedu == 130 | s4_1_q7_highestedu == 230
* Special Education - setting to missing (TO DO: figure out if there is a better way to hande) *
replace yearsedu = . if s4_1_q7_highestedu == 122 | s4_1_q7_highestedu == 222

/* Those with higher levels of education - following KLPS (at least parent) methodology */
replace yearsedu = 14 if s4_1_q7_highestedu==115 | s4_1_q7_highestedu == 117 | s4_1_q7_highestedu==119
replace yearsedu = 15 if s4_1_q7_highestedu==116 | s4_1_q7_highestedu == 118 | s4_1_q7_highestedu==120 | s4_1_q7_highestedu==121

/* Alternative method */
gen yearsedu_alt = yearsedu
replace yearsedu_alt = 13 if s4_1_q7_highestedu==115 | s4_1_q7_highestedu==117
replace yearsedu_alt = 14 if s4_1_q7_highestedu == 116 | s4_1_q7_highestedu==118
replace yearsedu_alt = 15 if s4_1_q7_highestedu==119
replace yearsedu_alt = 16 if s4_1_q7_highestedu==120
replace yearsedu_alt = 17 if s4_1_q7_highestedu==121

tab yearsedu, m
tab yearsedu_alt, m

label var yearsedu "HH member years of edu (14=some coll/univ/poly, 15=complete coll/univ/poly)"
label var yearsedu_alt "HH member years of education (up to 17 for higher ed)"

/** EDUCATION LEVEL INDICATORS **/
gen noschool = s4_1_q7_edusystem == 2 if ~mi(s4_1_q7_edusystem)
replace noschool = 0 if s4_1_q7_highestedu == 100 | s4_1_q7_highestedu == 200
la var noschool "No schooling"


gen stdschool = yearsedu >= 8 & ~mi(yearsedu) if s4_1_q7_edusystem == 1
replace stdschool = yearsedu >= 7 & ~mi(yearsedu) if s4_1_q7_edusystem == 3
replace stdschool = 0 if noschool == 1
la var stdschool "Completed primary school"

gen someformschool = yearsedu > 8 & ~mi(yearsedu) if s4_1_q7_edusystem == 1
replace someformschool = yearsedu > 7 & ~mi(yearsedu) if s4_1_q7_edusystem == 3
replace someformschool = 0 if noschool == 1
la var someformschool "Some secondary school"

gen formschool = yearsedu >= 12 if s4_1_q7_edusystem == 1
replace formschool = yearsedu > 12 if s4_1_q7_edusystem == 1 // inequality here as under previous system had to finish 13 years
replace formschool = 0 if noschool == 1
la var formschool "Completed secondary school"



/** adding in FR to the roster - merge in info separately **/
append using `fr_data'


* still need to bring in migration data? Or keep as separate? Can also make sure schooling data is ready to merge

/*** SAVING HOUSEHOLD ROSTER ***/
gen hhid_key = s1_hhid_key

compress
save "$da/GE_HH-Endline_HHRoster_LONG.dta", replace
project, creates("$da/GE_HH-Endline_HHRoster_LONG.dta")
