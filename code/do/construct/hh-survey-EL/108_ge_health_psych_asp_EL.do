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

project, original("$do/programs/run_ge_build_programs.do")
include "$do/programs/run_ge_build_programs.do"

/*
 * Filename: ge_hhe_vars_health_psych_asp.do
 * Description: This do file constructs variables related to health/nutrition, mental health, psych and aspirations for endline survey data. Is is very closely related to version from
 *   baseline, and used the baseline file as a template.
 *
 * Author: Michael Walker, updated by Justin Abraham
 * Last modified: 12 June 2017, adapting from ge_hhb_outcomes_assets_income_2017-03-03.do and incorporating suggestions from JA on psych scales.
 *
 *
 *
 */

 ** setting up to use intermediate dataset for more modular running
 project, uses("$da/intermediate/GE_HH-EL_setup.dta") preserve

 use "$da/intermediate/GE_HH-EL_setup.dta", clear

* bringing in roster data
project, uses("$da/intermediate/GE_HH-EL_hhroster.dta") preserve
merge 1:1 s1_hhid_key using "$da/intermediate/GE_HH-EL_hhroster.dta", force // come back to remove this - I don't think we need all variables in using
assert _merge == 3
drop _merge

 /************************************/
 /* SECTION 11: HEALTH AND NUTRITION */
 /************************************/


/** Q1-3: Number of meals ***/
tab1 s11_q1_nummeals s11_q2_fishmeals s11_q3_eggmeals
destring s11_q1_nummeals s11_q2_fishmeals s11_q3_eggmeals, replace
recode s11_q1_nummeals s11_q2_fishmeals s11_q3_eggmeals (4/8 = 3) (10/max = .)
tab1 s11_q1_nummeals s11_q2_fishmeals s11_q3_eggmeals

* consistency checks across questions
count if s11_q2_fishmeals > s11_q1_nummeals & ~mi(s11_q2_fishmeals)
count if s11_q3_eggmeals > s11_q1_nummeals & ~mi(s11_q3_eggmeals)

list s11_q1_nummeals s11_q2_fishmeals s11_q3_eggmeals if (s11_q2_fishmeals > s11_q1_nummeals & ~mi(s11_q2_fishmeals)) | (s11_q3_eggmeals > s11_q1_nummeals & ~mi(s11_q3_eggmeals))

replace s11_q2_fishmeals = . if s11_q2_fishmeals > s11_q1_nummeals & ~mi(s11_q2_fishmeals)
replace s11_q3_eggmeals = . if s11_q3_eggmeals > s11_q1_nummeals & ~mi(s11_q3_eggmeals)

gen num_meals_yest = s11_q1_nummeals
tab num_meals_yest
label var num_meals_yest "Number of meals yesterday"

gen num_meals_yest_protein = 0 if s11_q2_fishmeals != . & s11_q3_eggmeals != .
replace num_meals_yest_protein = s11_q2_fishmeals + s11_q3_eggmeals if s11_q2_fishmeals != . & s11_q3_eggmeals != .
replace num_meals_yest_protein = 3 if num_meals_yest_protein > 3 & num_meals_yest_protein != .

count if num_meals_yest < num_meals_yest_protein
count if num_meals_yest == num_meals_yest_protein

replace num_meals_yest_protein = num_meals_yest if num_meals_yest < num_meals_yest_protein // accounting for possible double-counting between eggs and meat/fish

label var num_meals_yest_protein "Number of meals yesterday w/ fish, meat or eggs"

tab1 num_meals_yest num_meals_yest_protein

* when constructing variables for the number of meals missed, make sure to check for whether or not the household has children

destring s11_q10a_hungryadult s11_q10b_hungrychild s11_q11a_skippedadult s11_q11b_skippedchild s11_q12a_nofoodadult s11_q12b_nofoodchild , replace


gen numchildren = hhros_num_sch_aged


tab1 s11_q10b_hungrychild s11_q11b_skippedchild  s11_q12b_nofoodchild if numchildren > 0 & numchildren != .
foreach var of varlist s11_q10b_hungrychild s11_q11b_skippedchild  s11_q12b_nofoodchild {
  replace `var' = . if numchildren == 0
  }


/*** S11 Q10-12: family meal patterns, skipping & cutting meals ***/
tab1 s11_q10a_hungryadult s11_q10b_hungrychild s11_q11a_skippedadult s11_q11b_skippedchild s11_q12a_nofoodadult s11_q12b_nofoodchild

** consistency checks -- going entire days without food should be less than skipping/cutting meals
count if s11_q11a_skippedadult < s11_q12a_nofoodadult & ~mi(s11_q12a_nofoodadult)
count if s11_q11b_skippedchild < s11_q12b_nofoodchild & ~mi(s11_q12b_nofoodchild)

list s11_q10?_* s11_q11?_*  s11_q12?_* if s11_q11a_skippedadult < s11_q12a_nofoodadult & ~mi(s11_q12a_nofoodadult) // TO DO: this is a slightly higher number of cases than I would expect - about 2.5 % seemingly inconsistent on this. Not adjusting for now, but keep in mind


/*** PRIMARY OUTCOME: FOOD SECURITY INDEX ***/
* re-signing going hungry variables so that higher values represent higher food security
foreach var of varlist s11_q10a_hungryadult s11_q10b_hungrychild s11_q11a_skippedadult s11_q11b_skippedchild s11_q12a_nofoodadult s11_q12b_nofoodchild {
    gen `var'_fsindex = - `var'
}

gen_index_vers s11_q10a_hungryadult_fsindex s11_q10b_hungrychild_fsindex s11_q11a_skippedadult_fsindex s11_q11b_skippedchild_fsindex s11_q12a_nofoodadult_fsindex s11_q12b_nofoodchild_fsindex num_meals_yest_protein, prefix(p9_foodindex) label("Food Security Index")


/*
egen food_index = weightave(s11_q10a_hungryadult_fsindex s11_q10b_hungrychild_fsindex s11_q11a_skippedadult_fsindex s11_q11b_skippedchild_fsindex s11_q12a_nofoodadult_fsindex s11_q12b_nofoodchild_fsindex num_meals_yest_protein), normby(eligible_control_lowsat)
la var food_index "Food index (std by elig, control, low sat)"

egen food_index_i = weightave(s11_q10a_hungryadult_fsindex s11_q10b_hungrychild_fsindex s11_q11a_skippedadult_fsindex s11_q11b_skippedchild_fsindex s11_q12a_nofoodadult_fsindex s11_q12b_nofoodchild_fsindex num_meals_yest_protein), normby(ineligible_control_lowsat)
la var food_index "Food index (std by inelig, control, low sat)"


egen food_index_ec = weightave(s11_q10a_hungryadult_fsindex s11_q10b_hungrychild_fsindex s11_q11a_skippedadult_fsindex s11_q11b_skippedchild_fsindex s11_q12a_nofoodadult_fsindex s11_q12b_nofoodchild_fsindex num_meals_yest_protein), normby(elig_control)
la var food_index_ec "Food index (std by control)"
*/



** generating and labeling variables for analysis dataset - using above but into consistent format **
gen h9_1_skippedadult = s11_q11a_skippedadult
la var h9_1_skippedadult "Num days adults skipped/cut meals, last week"
gen h9_2_skippedchild  = s11_q11b_skippedchild
la var h9_2_skippedchild "Num days children skipped/cut meals, last week"
gen h9_3_nofoodadult = s11_q12a_nofoodadult
la var h9_3_nofoodadult "Num days adults went without food, last week"
gen h9_4_nofoodchild = s11_q12b_nofoodchild
la var h9_4_nofoodchild "Num days children went without food, last week"
gen h9_5_hungryadult = s11_q10a_hungryadult
la var h9_5_hungryadult "Num days adults went to bed hungry, last week"
gen h9_6_hungrychild = s11_q10b_hungrychild
la var h9_6_hungrychild "Num days children went to bed hungry, last week"
gen h9_7_proteinmeals = num_meals_yest_protein
la var h9_7_proteinmeals "Num meals eaten yesterday with meat, fish or eggs"



/***** HEALTH OUTCOMES ***********/


*** SELF-REPORTED HEATLH ***
destring s11_q8_health1 s11_q9_health2, replace
tab1 s11_q8_health1 s11_q9_health2

gen health_self = 5 if s11_q8_health1 == 1 // self-reported health very good
replace health_self = 4 if s11_q9_health2 == 1
replace health_self = 3 if s11_q9_health2 == 2
replace health_self = 2 if s11_q9_health2 == 3
replace health_self = 1 if s11_q9_health2 == 4

tab health_self
label var health_self "Self-reported health"


*** INDEX OF RECENT SYMPTOMS ***

/* CODING OF HEALTH SYMPTOMS
1	Fever
2	Persistent cough
3	Always feeling tired
4	Stomach pain
5	Worms
6	Blood in stool
7	Rapid weight loss
8	Frequent diarrhea
9	Skin rash or irritation
10	Open sores / boils
11	Difficulty Swallowing
12	Serious wound or injury
13	Malaria
14	Typhoid
15	Tuberculosis
16	Sores or ulcers on the genitals
17	Cholera
18	Yellow fever
19	Asthma / breathlessness at night
20	Frequent and excessive urination
21	Constant thirst / increased drinking of fluids
22	Diabetes
25	high blood pressure/hypertension
23	Men only:  Unusual discharge from the tip of the penis
24	NONE
*/

split s11_q13_symptomlist, gen(tmp_healthsymp_)
destring tmp_healthsymp_*, replace

foreach stem in fever cough tired stompain worms bloodystool weightloss diarrhea rash opensores swallow wound malaria typhoid tb gensores cholera yellowfever asthma frequrine thirst diabetes hyperten discharge none {
    gen healthsymp_`stem' = 0 if ~mi(s11_q13_symptomlist)
}


forval i=1/15 {
    replace healthsymp_fever        = 1 if tmp_healthsymp_`i' == 1
    replace healthsymp_cough        = 1 if tmp_healthsymp_`i' == 2
    replace healthsymp_tired        = 1 if tmp_healthsymp_`i' == 3
    replace healthsymp_stompain     = 1 if tmp_healthsymp_`i' == 4
    replace healthsymp_worms        = 1 if tmp_healthsymp_`i' == 5
    replace healthsymp_bloodystool  = 1 if tmp_healthsymp_`i' == 6
    replace healthsymp_weightloss   = 1 if tmp_healthsymp_`i' == 7
    replace healthsymp_diarrhea     = 1 if tmp_healthsymp_`i' == 8
    replace healthsymp_rash         = 1 if tmp_healthsymp_`i' == 9
    replace healthsymp_opensores    = 1 if tmp_healthsymp_`i' == 10
    replace healthsymp_swallow      = 1 if tmp_healthsymp_`i' == 11
    replace healthsymp_wound        = 1 if tmp_healthsymp_`i' == 12
    replace healthsymp_malaria      = 1 if tmp_healthsymp_`i' == 13
    replace healthsymp_typhoid      = 1 if tmp_healthsymp_`i' == 14
    replace healthsymp_tb           = 1 if tmp_healthsymp_`i' == 15
    replace healthsymp_gensores     = 1 if tmp_healthsymp_`i' == 16
    replace healthsymp_cholera      = 1 if tmp_healthsymp_`i' == 17
    replace healthsymp_yellowfever  = 1 if tmp_healthsymp_`i' == 18
    replace healthsymp_asthma       = 1 if tmp_healthsymp_`i' == 19
    replace healthsymp_frequrine    = 1 if tmp_healthsymp_`i' == 20
    replace healthsymp_thirst       = 1 if tmp_healthsymp_`i' == 21
    replace healthsymp_diabetes     = 1 if tmp_healthsymp_`i' == 22
    replace healthsymp_hyperten     = 1 if tmp_healthsymp_`i' == 25
    replace healthsymp_discharge    = 1 if tmp_healthsymp_`i' == 23
    replace healthsymp_none         = 1 if tmp_healthsymp_`i' == 24
}


replace healthsymp_discharge = . if s2_q3_gender == 2

* none mismatch - setting none to zero for any cases where another symptom was reported
egen any_symptom = rowmax(healthsymp_fever healthsymp_cough healthsymp_tired healthsymp_stompain healthsymp_worms healthsymp_bloodystool healthsymp_weightloss healthsymp_diarrhea healthsymp_rash healthsymp_opensores healthsymp_swallow healthsymp_wound healthsymp_malaria healthsymp_typhoid healthsymp_tb healthsymp_gensores healthsymp_cholera healthsymp_yellowfever healthsymp_asthma healthsymp_frequrine healthsymp_thirst healthsymp_diabetes healthsymp_hyperten healthsymp_discharge)
tab any_symptom
tab any_symptom if healthsymp_none == 1
replace healthsymp_none = 0 if any_symptom == 1
la var any_symptom "Indicator for any recent health symptoms"
la var healthsymp_none "Indicator for no recent health symptoms"

egen num_symptoms = rowtotal(healthsymp_fever healthsymp_cough healthsymp_tired healthsymp_stompain healthsymp_worms healthsymp_bloodystool healthsymp_weightloss healthsymp_diarrhea healthsymp_rash healthsymp_opensores healthsymp_swallow healthsymp_wound healthsymp_malaria healthsymp_typhoid healthsymp_tb healthsymp_gensores healthsymp_cholera healthsymp_yellowfever healthsymp_asthma healthsymp_frequrine healthsymp_thirst healthsymp_diabetes healthsymp_hyperten healthsymp_discharge)
la var num_symptoms "Number of health symptoms"

tab1 healthsymp_*
drop tmp_healthsymp_*

* labeling variables
la var healthsymp_fever   "Indicator for Fever, last 4 weeks"
la var healthsymp_cough   "Indicator for Persistent cough, last 4 weeks"
la var healthsymp_tired   "Indicator for Always feeling tired, last 4 weeks"
la var healthsymp_stompain    "Indicator for Stomach pain, last 4 weeks"
la var healthsymp_worms   "Indicator for Worms, last 4 weeks"
la var healthsymp_bloodystool "Indicator for Blood in stool, last 4 weeks"
la var healthsymp_weightloss  "Indicator for Rapid weight loss, last 4 weeks"
la var healthsymp_diarrhea    "Indicator for Frequent diarrhea, last 4 weeks"
la var healthsymp_rash    "Indicator for Skin rash or irritation, last 4 weeks"
la var healthsymp_opensores   "Indicator for Open sores / boils, last 4 weeks"
la var healthsymp_swallow "Indicator for Difficulty Swallowing, last 4 weeks"
la var healthsymp_wound   "Indicator for Serious wound or injury, last 4 weeks"
la var healthsymp_malaria "Indicator for Malaria, last 4 weeks"
la var healthsymp_typhoid "Indicator for Typhoid, last 4 weeks"
la var healthsymp_tb  "Indicator for Tuberculosis, last 4 weeks"
la var healthsymp_gensores    "Indicator for Sores or ulcers on the genitals, last 4 weeks"
la var healthsymp_cholera "Indicator for Cholera, last 4 weeks"
la var healthsymp_yellowfever "Indicator for Yellow fever, last 4 weeks"
la var healthsymp_asthma  "Indicator for Asthma / breathlessness at night, last 4 weeks"
la var healthsymp_frequrine   "Indicator for Frequent and excessive urination, last 4 weeks"
la var healthsymp_thirst  "Indicator for Constant thirst / increased drinking of fluids, last 4 weeks"
la var healthsymp_diabetes    "Indicator for Diabetes, last 4 weeks"
la var healthsymp_hyperten    "Indicator for high blood pressure/hypertension, last 4 weeks"
la var healthsymp_discharge   "(Men only) Indicator for Unusual discharge from the tip of the penis, last 4 weeks"

** generating health symptom index **

gen_index_vers healthsymp_fever healthsymp_cough healthsymp_tired healthsymp_stompain healthsymp_worms healthsymp_bloodystool healthsymp_weightloss healthsymp_diarrhea healthsymp_rash healthsymp_opensores healthsymp_swallow healthsymp_wound healthsymp_malaria healthsymp_typhoid healthsymp_tb healthsymp_gensores healthsymp_cholera healthsymp_yellowfever healthsymp_asthma healthsymp_frequrine healthsymp_thirst healthsymp_diabetes healthsymp_hyperten healthsymp_discharge, prefix(healthsymp_index) label("Recent health symptom index")

/*
egen healthsymp_index = weightave(healthsymp_fever healthsymp_cough healthsymp_tired healthsymp_stompain healthsymp_worms healthsymp_bloodystool healthsymp_weightloss healthsymp_diarrhea healthsymp_rash healthsymp_opensores healthsymp_swallow healthsymp_wound healthsymp_malaria healthsymp_typhoid healthsymp_tb healthsymp_gensores healthsymp_cholera healthsymp_yellowfever healthsymp_asthma healthsymp_frequrine healthsymp_thirst healthsymp_diabetes healthsymp_hyperten healthsymp_discharge), normby(eligible_control_lowsat)
la var healthsymp_index "Recent health symptom index (std by elig, control, low sat)"

egen healthsymp_index_i = weightave(healthsymp_fever healthsymp_cough healthsymp_tired healthsymp_stompain healthsymp_worms healthsymp_bloodystool healthsymp_weightloss healthsymp_diarrhea healthsymp_rash healthsymp_opensores healthsymp_swallow healthsymp_wound healthsymp_malaria healthsymp_typhoid healthsymp_tb healthsymp_gensores healthsymp_cholera healthsymp_yellowfever healthsymp_asthma healthsymp_frequrine healthsymp_thirst healthsymp_diabetes healthsymp_hyperten healthsymp_discharge), normby(inelig_control_lowsat)
la var healthsymp_index_i "Recent health symptom index (std by inelig, control, low sat)"


egen healthsymp_index_ec = weightave(healthsymp_fever healthsymp_cough healthsymp_tired healthsymp_stompain healthsymp_worms healthsymp_bloodystool healthsymp_weightloss healthsymp_diarrhea healthsymp_rash healthsymp_opensores healthsymp_swallow healthsymp_wound healthsymp_malaria healthsymp_typhoid healthsymp_tb healthsymp_gensores healthsymp_cholera healthsymp_yellowfever healthsymp_asthma healthsymp_frequrine healthsymp_thirst healthsymp_diabetes healthsymp_hyperten healthsymp_discharge), normby(eligible_control)
la var healthsymp_index_ec "Recent health symptom index (std by elig, control)"
*/

*** DAYS OF WORK / SCHOOL MISSED DUE TO HEALTH ***
destring s11_q7_daysworked , replace
recode s11_q7_daysworked (min/-1 = .)
tab s11_q7_daysworked
gen health_daysmissed = s11_q7_daysworked
la var health_daysmissed "Number of days of work/school missed due to health, last 4 weeks"

*** MAJOR HEALTH PROBLEM ***
destring s11_q18_majorhealthprob, replace
tab1 s11_q18_majorhealthprob
gen health_hasmajorprob = s11_q18_majorhealthprob == 1 if ~mi(s11_q18_majorhealthprob)
la var health_hasmajorprob "Since baseline, has had major health problem affecting work/life"

*** MAJOR HEALTH PROBLEM RESOLVED ***
destring s11_q21_healthprob_resolve_?, replace
tab1 s11_q21_healthprob_resolve_?

forval i=1/3 {
    gen tmp_healthprob_resolve_`i' = s11_q21_healthprob_resolve_`i' == 1
}
egen health_majorprobresolve = rowmax(tmp_healthprob_resolve_?) if health_hasmajorprob == 1
la var health_majorprobresolve "Since baseline, has had major health problem resolved (cond health prob)"

tab1 health_hasmajorprob health_majorprobresolve


*** NUMBER OF HOSPITAL / CLINIC VISITS ***
destring s11_q14_hosvisits, replace
tab s11_q14_hosvisits

gen health_numvisits = s11_q14_hosvisits
la var health_numvisits "Num visits to hospital / clinic, last 4 weeks"

*** TOTAL MEDICAL EXPENDITURE, LAST 4 WEEKS ***
destring s11_q15?_amtpaid*, replace

tab1 s11_q15?_amtpaid*

egen health_medexpend = rowtotal(s11_q15a_amtpaid_medcare s11_q15b_amtpaid_modmed s11_q15c_amtpaid_tradmed), m
la var health_medexpend "Expenditure on medical care and treatments, last 4 weeks"

summ health_medexpend, d


wins_top1 health_medexpend
sum health_medexpend_wins
trim_top1 health_medexpend
sum health_medexpend_trim

foreach var of varlist health_medexpend* {
    loc vl : var label `var'
    gen `var'_PPP = `var' * $ppprate
    la var `var'_PPP "`vl' (PPP)"
}



*** HEALTH STATUS INDEX ***
gen health_nomajorprob = 1 - health_hasmajorprob

foreach suf in "e" "ie" {
    gen healthsymp_index_neg_`suf' = - healthsymp_index_`suf'

    if "`suf'" == "e" local cond "if eligible == 1"
    if "`suf'" == "ie" local cond "if eligible == 0"

    di "`cond'"

    egen p6_healthstatus_`suf' = weightave(health_self healthsymp_index_neg_`suf' health_nomajorprob) `cond', normby(control_lowsat)

    la var p6_healthstatus_`suf' "P6 Health Status Index (std by control, low sat)"

}
replace p6_healthstatus_e   = . if eligible != 1
replace p6_healthstatus_ie  = . if eligible != 0

gen     p6_healthstatus = p6_healthstatus_e     if eligible == 1
replace p6_healthstatus = p6_healthstatus_ie    if eligible == 0
la var  p6_healthstatus "P6 Health Status Index (std by control, low sat)"





/*
 /* Indicator for smoking */
 tab s11_q5_smoked, m
 recode s11_q5_smoked (1 = 1) (2 = 0) (nonm = .), gen(smoked)
 la var smoked "Smoked in last 7 days"

 /* Indicator for drinking alcohol */
 recode s11_q6_numalcohol (0 = 0) (1/max = 1), gen(alcohol)
 la var alcohol "Had alcohol the last 7 days"

 /* Appetite rating */
 gen appetite = 6 - s11_q4_appetite
 la var appetite "Appetite rating"


 tab s11_q7_daysworked
 replace s11_q7_daysworked = . if s11_q7_daysworked == 77 | s11_q7_daysworked == 88 | s11_q7_daysworked == 98
 replace s11_q7_daysworked = 28 if s11_q7_daysworked > 28 & s11_q7_daysworked != .

*/


 /************************************/
 /* SECTION 13: MENTAL WELL-BEING    */
 /************************************/

 /* JA: Below describes a recommended method for dealing with missing responses on psych scales based on Aspirations project.

 The proportion of missing responses across all respondents for a given item will be taken as an indication of poor comprehension and acceptability of the item, with 20% item non-response leading to the removal of that item from the scale. Responses of individual respondents to a given scale were dropped for a scale with 4-5 items if responses on ≥ 2 items were missing, for a scale with 6-8 items if ≥ 3 were missing, and for a scale with 9+ items if ≥ 4 were missing. When fewer items than these cutoffs are missing for a particular individual, scores are adjusted to generate homogeneous score ranges using an appropriate multiplier. We score each scale according to the instructions in the original literature.
 */

 /**** Mental well-being ****/

 /* CES-D */

* step 1: combining across different survey forms

destring  s14_q?_cesd* s14_q??_cesd*, replace

 * Rename individual items
    forval i = 1/10 {
        gen cesd_`i' = s14_q`i'_cesd`i'
        if `i' != 5 & `i' != 8 {
            recode cesd_`i' (4 = 3) (3 = 2) (2 = 1) (1 = 0)
        }
    }

 * Code DK as missing
    recode cesd_* (-88 = .)

 * Reverse code items
    recode cesd_5 cesd_8 (1 = 3) (2 = 2) (3 = 1) (4 = 0)

    la define cesd10 0 "Rarely or none of the time" 1 "Some or a little of the time" 2 "Occasionally or a moderate amount of time" 3 "All of the time"

    * labeling variables
    la var cesd_1 "I was bothered by things that usually don’t bother me"
    la var cesd_2 "I had a problem in concentration on what I was doing"
    la var cesd_3 "I felt depressed and troubled in my mind"
    la var cesd_4 "I felt that everthing that I did took up all my energy"
    la var cesd_5 "I felt hopeful about the future (reverse-coded)"
    la var cesd_6 "I felt afraid"
    la var cesd_7 "I had difficulty in sleeping peacefully"
    la var cesd_8 "I was happy (reverse-coded)"
    la var cesd_9 "I felt lonely"
    la var cesd_10 "I lacked the motivation to do anything"

la values cesd_? cesd_?? cesd10

 * Calculate number of missing
    egen cesd_nummiss = rowmiss(cesd_1-cesd_10)

 * Calculate CES-D score
    egen cesd_score = rowtotal(cesd_1-cesd_10), m

 * Drop obs. with over 20% of items missing
    replace cesd_score = . if cesd_nummiss > 2

 * Inflate scores to account for missing
    replace cesd_score = cesd_score * 10 / (10 - cesd_nummiss)

    la var cesd_score "CES-D score (raw), increasing in depression"


    * Indicator for depression (score of 10 or higher, according to Center for Epidemiologic Studies Depression Scale Revised (CESD-R- 10))
    gen cesd_depressed = cesd_score >= 10  if ~mi(cesd_score)
    la var cesd_depressed "Indicator for depressed (CESD score $>=$10)"


 * Standardize to control mean and SD, and

    gen_index_vers cesd_score, prefix(cesd_score_z) label("CES-D score (std), increasing in depression")


 /* WVS */

 /* Control over one's own fate */
  gen wvs_fate = s14_q21_wvs_fate if s14_q21_wvs_fate != -88
  tab wvs_fate, m
  la var wvs_fate "WVS fate raw"

  gen_index_vers wvs_fate, prefix(wvs_fate_z) label("WVS fate (std)")


 /* Checking for missing values of other questions */
 tab1  s14_q23_wvs_happiness s14_q24_wvs_satisfaction, m
 gen wvs_happiness = s14_q23_wvs_happiness if s14_q23_wvs_happiness != -88
 la var wvs_happiness "WVS happiness raw"


* recoding so that higher values are better
recode wvs_happiness (1=4) (2=3) (3=2) (4=1)
la define wvs_happy 4 "Very happy" 3 "Quite happy" 2 "Not very happy" 1 "Not at all happy"
la values wvs_happiness wvs_happy

 gen wvs_satisfaction = s14_q24_wvs_satisfaction if s14_q24_wvs_satisfaction != -88
 la var wvs_satisfaction "WVS satisfaction raw"

 foreach var of varlist wvs_happiness wvs_satisfaction {

     local vlab = substr("`var'", 5, .)

     gen_index_vers `var', prefix(`var'_z) label("`vlab' (std)")

 }

/*
 /* Generalised self-efficacy (Schwarzer and Jerusalem 1995) */
destring s15_4_q*_se_*, replace
 * Rename individual items
 forval i=1/10 {
     tab s15_4_q`i'_se_`i', m
     gen selfeff_`i' = s15_4_q`i'_se_`i'

 }

 * Recode to missing
 recode selfeff_* (min/-1 99/max = .)

 * Rowtotal creates the (row) sum of the variables in varlist, treating missing as 0.  If missing is specified and all values in varlist are missing for an observation, newvar is set to missing.
 egen selfeff_score = rowtotal(selfeff_1-selfeff_10), m

 * Rowmiss gives the number of missing values in varlist for each observation (row).
 egen selfeff_nummiss = rowmiss(selfeff_1-selfeff_10)

 * Drop obs. with over 3 items missing
 replace selfeff_score = . if selfeff_nummiss > 3

 * Inflate scores to account for missing
 replace selfeff_score = selfeff_score * 10 / (10 - selfeff_nummiss)

 tab selfeff_score,m
 label var selfeff_score "Self-efficacy"

 * Standardize to control mean and SD
 gen_index_vers selfeff_score, prefix(selfeff_score_z) label("Self-efficacy, std")


la var selfeff_1 "I can always manage to solve difficult problems if I try hard enough"
la var selfeff_2 "If someone opposes me, I can find the means and ways to get what I want"
la var selfeff_3 "It is easy for me to stick to my aims and accomplish my goals"
la var selfeff_4 "I am confident that I could deal efficiently with unexpected events"
la var selfeff_5 "Thanks to my resourcefulness, I know how to handle unforeseen situations"
la var selfeff_6 "I can solve most problems if I invest the necessary effort"
la var selfeff_7 "I can remain calm when facing difficulties bc I can rely on my coping abilities"
la var selfeff_8 "When I am confronted with a problem, I can usually find several solutions"
la var selfeff_9 "If I am in trouble, I can usually think of a solution"
la var selfeff_10 "I can usually handle whatever comes my way"
*/

*** perceived stress index ***

recode s15_7_*pss* (min/-1 = .)

forval i=1/4 {
    gen stress_`i' = s15_7_q`i'_pss`i'
}
recode stress_2 stress_3 (5=1) (4=2) (2=4) (1=5) // reverse-coding the positive outcomes, so that greater values indicate greater stress, as in Cohen et al paper

egen stress_score = rowtotal(stress_1-stress_4), m

* Rowmiss gives the number of missing values in varlist for each observation (row).
egen stress_nummiss = rowmiss(stress_1-stress_4)

* Drop obs. with over 1 items missing (since only 4 questions)
replace stress_score = . if stress_nummiss > 1

* Inflate scores to account for missing
replace stress_score = stress_score * 4 / (4 - stress_nummiss)

la var stress_score "Perceived Stress"

* generating standardized version by eligibility
gen_index_vers stress_score, prefix(stress_score_z) label("Perceived Stress (std)")

la var stress_1 "Unable to control the important things in life"
la var stress_2 "Certain in ability to overcome personal problems (reverse-coded)"
la var stress_3 "Things were going your way (reverse-coded)"
la var stress_4 "Problems too much for you to manage"

*** Hope ***
/*
tab1 s15_6_q1_sn1 s15_6_q2_sn2 s15_6_q3_sn3 s15_6_q4_sn4 s15_6_q5_sn5 s15_6_q6_sn6 s15_6_q7_sn7 s15_6_q8_sn8
recode  s15_6_q1_sn1 s15_6_q2_sn2 s15_6_q3_sn3 s15_6_q4_sn4 s15_6_q5_sn5 s15_6_q6_sn6 s15_6_q7_sn7 s15_6_q8_sn8 (min/-1 = .)

forval i=1/8 {
    gen hope_`i' = s15_6_q`i'_sn`i'
}


egen hope_score = rowtotal(hope_?), m

egen hope_nummiss = rowmiss(hope_?)

* drop items with more than 2 items missing
replace hope_score = . if hope_nummiss > 2

replace hope_score = hope_score * 8 / (8 - hope_nummiss)

la var hope_score "Hope (Schneider)"


* generating standardized version by eligibility
gen_index_vers hope_score, prefix(hope_score_z) label("Hope (Schneider), std")

* labeling components
la var hope_1  "I can think of many ways to get out of my difficult situations"
la var hope_2  "I tirelessly put much effort to achieve my goals"
la var hope_3  "There are lots of ways around any problem"
la var hope_4  "I can think of many ways to get the things in life that are most important to me"
la var hope_5  "Even when others discouraged by challenges, I can face challenges"
la var hope_6  "The lessons I have learnt in the past have prepared me well for my future"
la var hope_7  "I have been successful in my life"
la var hope_8  "I always accomplish all my goals"

/* Indicator variables, calculating by eligibility */

 xtile fatemedian_e = wvs_fate if eligible == 1, n(2)
 replace fatemedian_e = fatemedian_e - 1
  la var fatemedian_e "Above median WVS Fate, eligible HHs"

  xtile fatemedian_ie = wvs_fate if eligible == 0, n(2)
  replace fatemedian_ie = fatemedian_ie - 1
   la var fatemedian_ie "Above median WVS Fate, ineligible HHs"

 gen fatemedian = fatemedian_e if eligible ==1
 replace fatemedian = fatemedian_ie if eligible == 0
 la var fatemedian "Above median WVS fate, by eligibility"

 xtile semedian_e = selfeff_score if eligible == 1, n(2)
 replace semedian_e = semedian_e - 1
 la var semedian_e "Above median self-efficacy, eligible HHs"

 xtile semedian_ie = selfeff_score if eligible == 0, n(2)
 replace semedian_ie = semedian_ie - 1
 la var semedian_ie "Above median self-efficacy, ineligible HHs"

 gen semedian = semedian_e if eligible == 1
 replace semedian = semedian_ie if eligible == 0
 la var semedian "Above median self-efficacy, by eligibility"
*/

** reverse coding items so that all are increasing in subjective well-being

local psych_neg "cesd_score_z stress_score_z"

foreach suf in e ie  {
    if "`suf'" == "e" local cond "if eligible == 1"
    if "`suf'" == "ie" local cond "if eligible == 0"

    foreach var of local psych_neg {
        gen `var'_neg_`suf' = - `var'_`suf'
    }

    egen p5_psych_index_`suf' = weightave(cesd_score_z_neg_`suf' wvs_happiness wvs_satisfaction stress_score_z_neg_`suf') `cond', normby(control_lowsat`nb')

    la var p5_psych_index_`suf' "Subjective well-being index"
    note p5_psych_index_`suf' : baseline version only contains CES-D, happiness and satistfaction. Did not collect stress as part of baseline

    local cond ""
}
// setting values "outside sample" to missing
replace p5_psych_index_e = . if eligible != 1
replace p5_psych_index_ie = . if eligible != 0
** generating overall index for both
gen p5_psych_index = p5_psych_index_e if eligible == 1
replace p5_psych_index = p5_psych_index_ie if eligible == 0
la var p5_psych_index "Subjective well-being index"

 /****************************************/
 /* SECTION 14: ASPIRATIONS OUTCOMES     */
 /****************************************/

 /* Locus of control */
/* Note: we cut some questions from this section as survey progressed.
  * for all households, we should have info for the loc_fatescore.
  Starting with this analysis, then turning to ones with partial coverage */

/*
  * LOC construct subscales
  destring s15_5_q5_loc_10 s15_5_q1_loc_15 s15_5_q4_loc_3 s15_5_q2_loc_5 s15_5_q3_loc_9, replace
  tab1 s15_5_q5_loc_10 s15_5_q1_loc_15 s15_5_q4_loc_3 s15_5_q2_loc_5 s15_5_q3_loc_9, m
  recode s15_5_q5_loc_10 s15_5_q1_loc_15 s15_5_q4_loc_3 s15_5_q2_loc_5 s15_5_q3_loc_9 (min/-1 99/max = .)

  egen loc_fatescore = rowtotal(s15_5_q5_loc_10 s15_5_q1_loc_15 s15_5_q4_loc_3 s15_5_q2_loc_5 s15_5_q3_loc_9), m
  label var loc_fatescore "Locus of control - fate"

/*
rest of these -- not urgent, may want to cut from any main analysis files
*/
local loc_int s15_5_loc_1a_v2_5 s15_5_loc_11_v2_5 s15_5_loc_14_v2_5 s15_5_loc_4_v2_5 s15_5_loc_8_v2_5
destring `loc_int', replace
tab1 `loc_int', m
recode `loc_int' (min/-1 99/max = .)

egen loc_intscore = rowtotal(`loc_int'), m
label var loc_intscore "Locus of control - internal"

local loc_others s15_5_loc_12_v2_5 s15_5_loc_13_v2_5 s15_5_loc_21_v2_5 s15_5_loc_23_v2_5 s15_5_loc_24_v2_5 s15_5_loc_6a_v2_5 s15_5_loc_7_v2_5
destring `loc_others', replace
tab1 `loc_others'
recode `loc_others' (min/-1 99/max = .)

* for the other subscales, we only have these from a subset of the first households that we surveyed. Including here just so we have it, though won't want to use in main analysis
egen loc_othersscore = rowtotal(`loc_others'), m
label var loc_othersscore "Locus of control - powerful others"

 * Count missing items
 egen loc_fatemiss = rowmiss(s15_5_q1_loc_15 s15_5_q2_loc_5  s15_5_q3_loc_9 s15_5_q4_loc_3  s15_5_q5_loc_10)

* labeling individual variables
la var s15_5_q1_loc_15 "To a great extent my life is controlled by accidental happenings"
la var  s15_5_q2_loc_5 "Often there is no chance of protecting my personal interests from bad luck"
la var s15_5_q3_loc_9 "When I get what I want, it’s usually because I'm lucky"
la var s15_5_q4_loc_3 "I have often found that what is going to happen will happen"
la var s15_5_q5_loc_10 "Not good to plan bc many things a matter of good or bad fortune"


 egen loc_intmiss = rowmiss(`loc_int')
 egen loc_othersmiss = rowmiss(`loc_others')

 * Drop if missing 2 or more items
 replace loc_intscore = . if loc_intmiss > 1
 replace loc_fatescore = . if loc_fatemiss > 1
 replace loc_othersscore = . if loc_othersmiss > 2

 * Inflate score to account for missing
 replace loc_intscore = loc_intscore * 5 / (5 - loc_intmiss)
 replace loc_fatescore = loc_fatescore * 5 / (5 - loc_fatemiss)
 replace loc_othersscore = loc_othersscore * 7 / (7 - loc_othersmiss)

 * Standardize to control mean and SD

 foreach var of varlist loc_*score {
     loc vlab : var label `var'
     loc newlab = subinstr("`vlab'", "raw", "std", 1)

     gen_index_vers `var', prefix(`var'_z) label("`newlab'")
 }



  /* Aspirations (Bernard et al 2014) */

 gen a_income = s15_1_q2_income_asp
 gen a_assets = s15_1_q4_assets_amt_asp

 recode a_income a_assets (min/-1 999 995 998 99 = .)

 //encode s4_imaginary_girl_edu_asp, gen(a_girledu)
 gen a_girledu = s4_imaginary_girl_edu_asp
 replace a_girledu = . if inrange(a_girledu, 1, 3)
 replace a_girledu = a_girledu + 9 if inrange(a_girledu, 4, 7)
 replace a_girledu = a_girledu + 1 if inrange(a_girledu, 8, 13)
 replace a_girledu = 0 if a_girledu == 14
 replace a_girledu = 4 if a_girledu == 15
 replace a_girledu = 5 if a_girledu == 16
 replace a_girledu = 7 if a_girledu == 17
 replace a_girledu = 8 if a_girledu == 18
 replace a_girledu = a_girledu - 6 if inrange(a_girledu, 19, 23)

 //encode s4_imaginary_boy_edu_asp, gen(a_boyedu)
 gen a_boyedu = s4_imaginary_boy_edu_asp
 replace a_boyedu = . if inrange(a_boyedu, 1, 3)
 replace a_boyedu = a_boyedu + 9 if inrange(a_boyedu, 4, 7)
 replace a_boyedu = a_boyedu + 1 if inrange(a_boyedu, 8, 13)
 replace a_boyedu = 0 if a_boyedu == 14
 replace a_boyedu = 4 if a_boyedu == 15
 replace a_boyedu = 6 if a_boyedu == 16
 replace a_boyedu = 8 if a_boyedu == 17
 replace a_boyedu = a_boyedu - 5 if inrange(a_boyedu, 18, 22)

 egen a_edu = rowmean(a_girledu a_boyedu)
 la var a_edu "Education aspirations raw"

 recode s15_2_q2_macarthur_asp (11/max = .), gen(a_social)
 la var a_social "Social aspirations raw"

 la var a_income "Income aspirations raw"
 la var a_assets "Wealth aspirations raw"


 foreach var in a_income a_assets a_edu a_social {

     * updating to calculate standardization by eligibility status
     local vargen "gen"
     forval elig = 0 / 1 {
         qui sum `var' if eligible == `elig', d
         local p1 = r(p1)
         local p99 = r(p99)
         qui sum `var' if inrange(`var', `p1', `p99') & control_lowsat == 0 & eligible == `elig'
         `vargen' `var'_std = (`var' - `r(mean)') / `r(sd)' if inrange(`var', `p1', `p99') & eligible == `elig'

         local vargen "replace"
     }
 // end of loop by eligibility status
 }
 // end of variable loop

 label var a_income_std "Income aspirations std by eligibility"
 label var a_assets_std "Wealth aspirations std by eligibility"
 label var a_edu_std "Education aspirations std by eligibility"
 label var a_social_std "Social status aspirations std by eligibility"

* checking weights
tab1 s15_3_q1a_wgt_income s15_3_q1b_wgt_assets s15_3_q1c_wgt_social s15_3_q1d_wgt_edu s15_3_q1_total

egen total_asp_weights = rowtotal(s15_3_q1a_wgt_income s15_3_q1b_wgt_assets s15_3_q1c_wgt_social s15_3_q1d_wgt_edu), m

// New try from Tilman


foreach suf in e ie  {
    if "`suf'" == "e" local cond "if eligible == 1"
    if "`suf'" == "ie" local cond "if eligible == 0"

    egen a_index_`suf' = weightave(a_income a_edu a_assets a_social) `cond', normby(control_lowsat`nb')

    la var p5_psych_index_`suf' "Aspirations Index"
    local cond ""
}
// setting values "outside sample" to missing
replace a_index_e = . if eligible != 1
replace a_index_ie = . if eligible != 0
** generating overall index for both
gen a_index = a_index_e if eligible == 1
replace a_index = a_index_ie if eligible == 0

qui summ a_index if eligible == 1 & hi_sat == 0 & treat == 0
gen a_index_z = (a_index - `r(mean)') / `r(sd)'

//gen a_index = ((a_income_std * s15_3_q1a_wgt_income) + (a_assets_std * s15_3_q1b_wgt_assets) + (a_edu_std * s15_3_q1d_wgt_edu) + (a_social_std * s15_3_q1c_wgt_social)) / 20 if s15_3_q1_total == 20
la var a_index_z "Aspirations Index"

/*
//replace a_index = (a_index-`r(mean)')/`r(sd)'

gen_index_vers a_index, prefix(a_index_z) label("Aspirations, std")


/* note - there may be ways to fill in some of these observations - follow up with Johannes and figure out how to handle this at some point going forward
//gen a_index_fill
*/
*/
*** naming variables for consistency with hh welfare PAP ***
// should the following be standardized values or not? using standardized for now, as it's easier for me to interpret
// TG, 2019-01-15: I do now standardise CESD questions
gen h5_1_cesd = cesd_score_z
la var  h5_1_cesd "Depression (std)"

ren wvs_happiness_z* h5_2_happiness*
ren wvs_satisfaction_z* h5_3_satisfaction*
ren stress_score_z* h5_4_stress*
ren a_index_z h5_5_asp
ren selfeff_score_z* h5_6_selfeff*
ren loc_fatescore_z* h5_7_loc*
ren hope_score_z* h5_8_hope*

foreach var of varlist h5_2_happiness* {
    la var `var' "Happiness"
}
foreach var of varlist h5_3_satisfaction* {
    la var `var' "Life satisfaction"
}
foreach var of varlist h5_4_stress* {
    la var `var' "Perceived stress"
}
la var h5_5_asp "Aspirations"
foreach var of varlist h5_6_selfeff* {
    la var `var' "Self-efficacy "
}
foreach var of varlist h5_7_loc* {
    la var `var' "Locus of control"
}
foreach var of varlist h5_8_hope* {
    la var `var' "Hope (Schneider)"
}
*/

*** SAVING INTERMEDIATE DATASET ***
keep s1_hhid_key p5_* p6_* p9* h9* health* //h5_*
save "$da/intermediate/GE_HH-EL_health_psych_asp.dta", replace
project, creates("$da/intermediate/GE_HH-EL_health_psych_asp.dta")
