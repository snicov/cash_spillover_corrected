

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
/*
 * Filename: ge_hhendling_vars_crime.do
 * Description: This do file constructs variables related to crime for endline survey data. These questions were not included as part of the baseline survey. These are constructed to be the same as in the GE household welfare pre-analysis plan.
 *
 * Author: Michael Walker
 *
 *
 *
 */

 ** setting up to use intermediate dataset for more modular running
 project, uses("$da/intermediate/GE_HH-EL_setup.dta")

 use "$da/intermediate/GE_HH-EL_setup.dta", clear


 /************************************/
 /* CRIME / VICTIMIZATION            */
 /************************************/

 *** theft ***
 tab1 s10_q28_steallivestock s10_q29_stealhhitems s10_q30_stealcash
 tab1 s10_q28a_numtimes s10_q29a_numtimes s10_q30a_numtimes

 replace s10_q28a_numtimes = 0 if s10_q28_steallivestock == 0
 replace s10_q29a_numtimes = 0 if s10_q29_stealhhitems == 0
 replace s10_q30a_numtimes = 0 if s10_q30_stealcash == 0

 replace s10_q30a_numtimes = . if s10_q30a_numtimes == 350 // very large, seems like an amount

 egen crime_anythefts = rowmax(s10_q28_steallivestock s10_q29_stealhhitems s10_q30_stealcash)
 egen crime_numthefts = rowtotal(s10_q28a_numtimes s10_q29a_numtimes s10_q30a_numtimes), m

 la var crime_anythefts "Indicator for victim of any theft in the last 12 mos"
 la var crime_numthefts "Number of times victimized by theft in the last 12 mos"

 tab1 crime_anythefts crime_numthefts

 gen p12_1_theft = crime_numthefts
 la var p12_1_theft "Number of times victimized by theft in the last year"

 *** assault ***
 tab1 s10_q31_assaultnoweapon s10_q32_assaultweapon s10_q33_victimarson s10_q34_victimwitchcraft
 ren s10_32a_numtimes s10_q32a_numtimes
 tab1 s10_q31a_numtimes s10_q32a_numtimes s10_q33a_numtimes s10_q34a_numtimes


 foreach var of varlist s10_q31_assaultnoweapon s10_q32_assaultweapon s10_q33_victimarson s10_q34_victimwitchcraft {
     local prefix = substr("`var'", 1, 7)
     replace `prefix'a_numtimes = 0 if `var' == 0
 }

 egen crime_anyassaults = rowmax(s10_q31_assaultnoweapon s10_q32_assaultweapon s10_q33_victimarson s10_q34_victimwitchcraft)
 egen crime_numassaults = rowtotal(s10_q31a_numtimes s10_q32a_numtimes s10_q33a_numtimes s10_q34a_numtimes), m

 la var crime_anyassaults "Indicator for victim of any assault, arson or witchcraft in last 12 mos"
 la var crime_numassaults "Number of times victim of assault, arson or witchcraft in last 12 mos"

 tab1 crime_anyassaults crime_numassaults

 gen p12_2_assault = crime_numassaults
 la var p12_2_assault "Number of times victim of assault, arson, or witchcraft in the last year"


 *** unreported crime ***
 tab1 s10_q*b_reportcrime

 local i=1
 foreach var of varlist s10_q*b_reportcrime {
     gen tmp_unreportedcrime_`i' = (`var' == 0)
     local ++i
 }
 egen crime_anyunreported = rowmax(tmp_unreportedcrime_*)
 la var crime_anyunreported "Indicator for any unreported crimes"
 tab crime_anyunreported
 drop tmp_unreportedcrime_*

 gen p12_3_unreported = crime_anyunreported
 la var p12_3_unreported "Did not report crime in the last year"

 *** neighborhood safety ***
 tab s10_q36_neighbsafety
 tab s10_q36_neighbsafety, nol

 gen crime_worry = (s10_q36_neighbsafety > 0) if ~mi(s10_q36_neighbsafety)
 la var crime_worry "Indicator for somewhat or very worried about crime/safety in neighborhood"
 gen p12_4_worry = crime_worry
 la var p12_4_worry "Respondent has been worried about crime in the neighborhood in the last year"



 *** SAVING INTERMEDIATE DATASET ***
 keep s1_hhid_key crime_* p12_*
 compress
 save "$da/intermediate/GE_HH-EL_security.dta", replace
 project, creates("$da/intermediate/GE_HH-EL_security.dta")
