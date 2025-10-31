

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

** programs used as part of this file
project, original("$do/programs/run_ge_build_programs.do")
include "$do/programs/run_ge_build_programs.do"
project, original("$ado/_gweightave.ado")

/*
 * Filename: ge_hhendline_vars_education.do
 * Description: This do file creates the endline Family 7 education outcomes.
 *
 * Authors: Priscila de Oliveira, Michael Walker
 *
 */


/**************************/
/*   FAMILY 7: Education  */
/**************************/
project, uses("$da/intermediate/GE_HH-EL_setup.dta")

use "$da/intermediate/GE_HH-EL_setup.dta", clear


*** PROPORTION OF SCHOOL-AGED CHILDREN IN SCHOOL
//Following PAP specification: school-aged children in 2016
//Approximating: using 7-17 year range for those surveyed in 2017
forval i=1/15 {
    gen schaged16_`i' = .
    replace schaged16_`i' = 1 if s4_1_q5_age_`i' >= 6 & s4_1_q5_age_`i' <= 16 & survey_yr == 2016
    replace schaged16_`i' = 0 if s4_1_q5_age_`i' < 6 & ~missing(s4_1_q5_age_`i')  & survey_yr == 2016 | s4_1_q5_age_`i' > 16 & ~missing(s4_1_q5_age_`i') & survey_yr == 2016
    replace schaged16_`i' = 1 if s4_1_q5_age_`i' >= 7 & s4_1_q5_age_`i' <= 17 & survey_yr == 2017
    replace schaged16_`i' = 0 if s4_1_q5_age_`i' < 7 & ~missing(s4_1_q5_age_`i')  & survey_yr == 2017 | s4_1_q5_age_`i' > 17 & ~missing(s4_1_q5_age_`i') & survey_yr == 2017
    replace schaged16_`i' = . if s4_1_q5_age_`i' == -99
}

//Generating indicator for attending school (conditional on being school-aged) in 2016
forval i=1/15 {
    gen schaged_attend16_`i' = .
    replace schaged_attend16_`i' = 1 if schaged16_`i' == 1 & s4_2_q11_attend16_`i' == 1
    replace schaged_attend16_`i' = 0 if schaged16_`i' == 1 & s4_2_q11_attend16_`i' == 0
}

egen nmbschoolaged16 = rowtotal(schaged16_1 schaged16_2 schaged16_5 schaged16_4 schaged16_5 schaged16_6 schaged16_7 schaged16_8 schaged16_9 schaged16_10 schaged16_11 schaged16_12 schaged16_13 schaged16_14 schaged16_15), m
replace nmbschoolaged16 = 0 if s4_q1_hhmembers == 0

summ nmbschoolaged16

egen nmbschaged_attend16 = rowtotal(schaged_attend16_1 schaged_attend16_2 schaged_attend16_5 schaged_attend16_4 schaged_attend16_5 schaged_attend16_6 schaged_attend16_7 schaged_attend16_8 schaged_attend16_9 schaged_attend16_10 schaged_attend16_11 schaged_attend16_12 schaged_attend16_13 schaged_attend16_14 schaged_attend16_15), m
gen p7_2_propschool = nmbschaged_attend16/nmbschoolaged16
summ p7_2_propschool
la var p7_2_propschool "P7.2: Proportion of school-aged children in school"

//Alternative: school-aged children attending school in current year (year of the survey)
//does not make a lot of difference
/* this code is not working - where are schaged_1, 2 ... variables being created?
egen nmbschoolaged_alt = rowtotal(schaged_1 schaged_2 schaged_3 schaged_4 schaged_5 schaged_6 schaged_7 schaged_8 schaged_9 schaged_10 schaged_11 schaged_12), m
replace nmbschoolaged_alt = 0 if s4_q1_hhmembers == 0
forval i=1/12 {
    gen schaged_attend_`i' = .
    replace schaged_attend_`i' = 1 if schaged_`i' == 1 & currentenrolled_`i' == 1
    replace schaged_attend_`i' = 0 if schaged_`i' == 1 & currentenrolled_`i' == 0
}
egen nmbschaged_attend_alt = rowtotal(schaged_attend_1 schaged_attend_2 schaged_attend_3 schaged_attend_4 schaged_attend_5 schaged_attend_6 schaged_attend_7 schaged_attend_8 schaged_attend_9 schaged_attend_10 schaged_attend_11 schaged_attend_12), m
gen p7_2_propschool_alt = nmbschaged_attend_alt/nmbschoolaged_alt
summ p7_2_propschool_alt
la var p7_2_propschool_alt "P7.2: Proportion of school-aged children in school (alternative)"
*/


*** UNDERTAKEN NEW FORM OF EDUCATION OR TRAINING
tab s5_q7_newedu
gen p7_3_neweduc = s5_q7_newedu
destring s5_q3_, replace
replace p7_3_neweduc = s5_q3_ if mi(p7_3_neweduc) // come back to check on this
tab p7_3_neweduc
la var p7_3_neweduc "P7.3: Undertaken new form of education"

*** NUMBER OF DAYS ATTENDED SCHOOL IN THE LAST FIVE DAYS SCHOOL WAS IN SESSION
//School-aged in current year (using survey year as current year)
forval i=1/15 {
    gen schaged_`i' = .
    replace schaged_`i' = 1 if s4_1_q5_age_`i' >= 6 & s4_1_q5_age_`i' <= 16
    replace schaged_`i' = 0 if s4_1_q5_age_`i' < 6 & ~missing(s4_1_q5_age_`i') | s4_1_q5_age_`i' > 16 & ~missing(s4_1_q5_age_`i')
    replace schaged_`i' = . if s4_1_q5_age_`i' == -99
}

forval i=1/12 {
    gen currentenrolled_`i' = 1 if s4_2_q11_attend16_`i' == 1 & survey_yr == 2016 | s4_2_q22_attend17_`i' == 1 & survey_yr == 2017
    replace currentenrolled_`i' = 0 if s4_2_q11_attend16_`i' == 0 & survey_yr == 2016 | s4_2_q22_attend17_`i' == 0 & survey_yr == 2017
}
//only 1-12 for s4_2_q22_attend17 and s4_1_q9_daysattendsch, but 1-15 for s4_2_q11_attend16
forval i=13/15 {
    gen currentenrolled_`i' = 1 if s4_2_q11_attend16_`i' == 1 & survey_yr == 2016
	replace currentenrolled_`i' = 0 if s4_2_q11_attend16_`i' == 0 & survey_yr == 2016
}

forval i=1/12 {
	replace s4_1_q9_daysattendsch_`i' = . if s4_1_q9_daysattendsch_`i' == -99
    tab s4_1_q9_daysattendsch_`i'
    gen p7_4_daysattendsch_`i' = s4_1_q9_daysattendsch_`i' if schaged_`i' == 1 | currentenrolled_`i' == 1
    replace p7_4_daysattendsch_`i' = 0 if schaged_`i' == 1 & currentenrolled_`i' == 0 & missing(p7_4_daysattendsch_`i')
    summ p7_4_daysattendsch_`i'
    la var p7_4_daysattendsch_`i' "P7.4: Number of days attended school in last 5 sessions"
}


*** PER-CHILD SCHOOL RELATED EXPENDITURES IN THE 3 MOST RECENT SCHOOL TERMS

forval i=1/12 {
    recode s4_2_q6_schfees15_term1_`i' s4_2_q6_schfees15_term2_`i' s4_2_q6_schfees15_term3_`i' s4_2_q17_schfees16_term1_`i' s4_2_q17_schfees16_term2_`i' s4_2_q17_schfees16_term3_`i' s4_2_q27_schfees17_term1_`i' s4_2_q7_schsupplies15_`i' s4_2_q18_schsupplies16_`i' s4_2_q28_schsupplies17_`i' s4_2_q9_schcontrib15_`i' s4_2_q20_schcontrib16_`i' s4_2_q30_schcontrib17_`i' (-99 -96 = .)
}

* this needs to be based in part on what we asked, and in part on what aligns with dates. We didn't immediately adjust, so should in part be by date and in part by survey version

* TO DO: almost no one is on semesters, and of these over half are in later versions where we have overall question, but should consider incorporating these too into overall expenditure measure

forval i=1/12 {
    egen schfees_last3_i_`i' = rowtotal(s4_2_q6_schfees15_term2_`i' s4_2_q6_schfees15_term3_`i' s4_2_q17_schfees16_term1_`i') if survey_mth >= 676 & survey_mth <= 678, m

    egen schfees_last3_ii_`i' = rowtotal(s4_2_q6_schfees15_term3_`i' s4_2_q17_schfees16_term1_`i' s4_2_q17_schfees16_term2_`i') if survey_mth >= 679 & survey_mth <= 682, m
    egen schfees_last3_iii_`i' = rowtotal(s4_2_q17_schfees16_term1_`i' s4_2_q17_schfees16_term2_`i' s4_2_q17_schfees16_term3_`i') if survey_mth >= 683 & survey_mth <= 686, m
    egen schfees_last3_iv_`i' = rowtotal(s4_2_q17_schfees16_term2_`i' s4_2_q17_schfees16_term3_`i' s4_2_q27_schfees17_term1_`i') if survey_mth >= 687 & survey_mth <= 688, m

    egen schsupplies_2015_`i' = rowtotal(s4_2_q7_schsupplies15_`i' s4_2_q9_schcontrib15_`i'), m
    egen schsupplies_2016_`i' = rowtotal(s4_2_q18_schsupplies16_`i' s4_2_q20_schcontrib16_`i'), m
    egen schsupplies_2017_`i' = rowtotal(s4_2_q28_schsupplies17_`i' s4_2_q30_schcontrib17_`i'), m

    gen schsupplies_i_`i' = (schsupplies_2015_`i'*2 + schsupplies_2016_`i')/3 if survey_mth >= 676 & survey_mth <= 678
    gen schsupplies_ii_`i' = (schsupplies_2015_`i' + schsupplies_2016_`i'*2)/3 if survey_mth >= 679 & survey_mth <= 682
    gen schsupplies_iii_`i' = schsupplies_2016_`i' if survey_mth >= 683 & survey_mth <= 686
    gen schsupplies_iv_`i' = (schsupplies_2016_`i'*2 + schsupplies_2017_`i')/3 if survey_mth >= 687 & survey_mth <= 688

    egen schexp_last3_i_`i' = rowtotal(schfees_last3_i_`i' schsupplies_i_`i') if survey_mth >= 676 & survey_mth <= 678
    egen schexp_last3_ii_`i' = rowtotal(schfees_last3_ii_`i' schsupplies_ii_`i') if survey_mth >= 679 & survey_mth <= 682
    egen schexp_last3_iii_`i' = rowtotal(schfees_last3_iii_`i' schsupplies_iii_`i') if survey_mth >= 683 & survey_mth <= 686
    egen schexp_last3_iv_`i' = rowtotal(schfees_last3_iv_`i' schsupplies_iv_`i') if survey_mth >= 687 & survey_mth <= 688

    gen p7_5_schexpenditures_`i' = schexp_last3_i_`i' if survey_mth >= 676 & survey_mth <= 678 & currentenrolled_`i' == 1
    replace p7_5_schexpenditures_`i' = schexp_last3_ii_`i' if survey_mth >= 679 & survey_mth <= 682 & currentenrolled_`i' == 1
    replace p7_5_schexpenditures_`i' = schexp_last3_iii_`i' if survey_mth >= 683 & survey_mth <= 686 & currentenrolled_`i' == 1
    replace p7_5_schexpenditures_`i' = schexp_last3_iv_`i' if survey_mth >= 687 & survey_mth <= 688 & currentenrolled_`i' == 1
    summ p7_5_schexpenditures_`i'
    la var p7_5_schexpenditures_`i' "P7.5: Per child school-related expenditures in the last 3 terms"

    wins_top1 p7_5_schexpenditures_`i'
    summ p7_5_schexpenditures_`i'_wins
    trim_top1 p7_5_schexpenditures_`i'
    summ p7_5_schexpenditures_`i'_trim
}

**double-checking consistency with outcome P7.1
egen totexpend_p7_5 = rowtotal(p7_5_schexpenditures_1 p7_5_schexpenditures_2 p7_5_schexpenditures_3 p7_5_schexpenditures_4 p7_5_schexpenditures_5 p7_5_schexpenditures_6 p7_5_schexpenditures_7 p7_5_schexpenditures_8 p7_5_schexpenditures_9 p7_5_schexpenditures_10 p7_5_schexpenditures_11 p7_5_schexpenditures_12), m


*** TOTAL EDUCATION EXPENDITURE IN THE LAST 12 MONTHS

gen p7_1_educexpense = s4_4_q4_schexpend
recode p7_1_educexpense -99 = .

tab version if ~mi(p7_1_educexpense) // not including versions before 12 - replacing this with total of other measure. TO DO - make sure consistent with Rachel's work. Also check whether this should bring in non-household expenses (older child, etc)
replace p7_1_educexpense = totexpend_p7_5 if version < 12 & mi(p7_1_educexpense)

summ p7_1_educexpense
la var p7_1_educexpense "P7.1: Total education expenditure in the last 12 months"


wins_top1 p7_1_educexpense
summ p7_1_educexpense_wins
trim_top1 p7_1_educexpense
summ p7_1_educexpense_trim

** education expenditure also outcome for family 2
gen h2_5_educexp = p7_1_educexpense
replace h2_5_educexp = 0 if nmbschoolaged16 == 0 & mi(h2_5_educexp)
la var h2_5_educexp "P2.5: Total education expenditure in the last 12 months"
wins_top1 h2_5_educexp
trim_top1 h2_5_educexp
summ h2_5_educexp*


* comparing expenditure measures
summ totexpend_p7_5 p7_1_educexpense, d
gen totexpend_p7_5_neg = - totexpend_p7_5
egen diff_p7_1_p7_5 = rowtotal(p7_1_educexpense totexpend_p7_5_neg), m
summ diff_p7_1_p7_5


/*** PRIMARY OUTCOME FOR EDUCATION - INDEX ***/
* since this combines education expenditure with proportion in school, conditioning on whether household has school-aged children. May want to do something else here

gen p7_1_eduexp_wins_haschild = p7_1_educexpense_wins if nmbschoolaged16 > 0 & ~mi(nmbschoolaged16)

gen_index_vers p7_1_eduexp_wins_haschild p7_2_propschool, prefix(p7_eduindex_haschild) label("Education Index (among those with school-aged children)")

summ p7_eduindex_haschild*

gen_index_vers p7_1_educexpense_wins p7_2_propschool, prefix(p7_eduindex_all) label("Education Index (all households)")

/*** GENERATING PPP VALUES FOR MONETARY OUTCOMES ***/
foreach var of varlist p7_1_educexpense* p7_5_schexpenditures_* {
    loc vl : var label `var'
    gen `var'_PPP = `var' * $ppprate
    la var `var'_PPP "`vl' (PPP)"
}

*** SAVING INTERMEDIATE DATASET ***
keep s1_hhid_key h2_5_educexp* p7_*
save "$da/intermediate/GE_HH-EL_hheducation.dta", replace
project, creates("$da/intermediate/GE_HH-EL_hheducation.dta")
