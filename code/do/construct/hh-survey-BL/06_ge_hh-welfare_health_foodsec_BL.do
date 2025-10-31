/*
 * Filename: ge_hh-welfare_health_foodsec_BL.do
 * Description: This do file constructs variables related to health/nutrition
 *
 * Author: Michael Walker, updated by Justin Abraham
 * Last modified: 12 June 2017, adapting from ge_hhb_outcomes_assets_income_2017-03-03.do and incorporating suggestions from JA on psych scales.
 *
 *
 *
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


   project, original("$do/programs/run_ge_build_programs.do")
   include "$do/programs/run_ge_build_programs.do"

   // end preliminaries

project, uses("$da/intermediate/GE_HH-BL_setup.dta")
use "$da/intermediate/GE_HH-BL_setup.dta", clear

keep *hhid_key village_code eligible s12_*

** bringing in roster data **
project, uses("$da/intermediate/GE_HH-BL_hhroster.dta") preserve
merge 1:1 hhid_key using "$da/intermediate/GE_HH-BL_hhroster.dta", keepusing(numchildren)

 /************************************/
 /* SECTION 12: HEALTH AND NUTRITION */
 /************************************/

 foreach var of varlist s12_q1_nummeals s12_q2_fishmeals s12_q3_eggmeals s12_q4_appetite s12_q5_smoked s12_q6_numalcohol s12_q7_daysworked s12_q8_health1 s12_q9_health2 s12_q10a_hungryadult s12_q10b_hungrychild s12_q11a_skippedadult s12_q11b_skippedchild s12_q12a_nofoodadult s12_q12b_nofoodchild {
 	di "`var'"
 	tab `var', m
 	replace `var' = . if `var' == 77 | `var' == 88 | `var' == 99
 }

 /* S12 Q1: Number of meals yesterday */
 tab s12_q1_nummeals
 recode s12_q1_nummeals (4/6 = 3) (77=.)
 gen num_meals_yest = s12_q1_nummeals
 tab num_meals_yest
 label var num_meals_yest "Number of meals yesterday"

 /* S12 Q2-3: Number of meals with protein */
 list s12_q1_nummeals s12_q2_fishmeals s12_q3_eggmeals if s12_q3_eggmeals == 30
 * may be a better way to handle this later
 replace s12_q3_eggmeals = 3 if s12_q3_eggmeals == 30 | s12_q3_eggmeals == 8


 gen num_meals_yest_protein = 0 if s12_q2_fishmeals != . & s12_q3_eggmeals != .
 replace num_meals_yest_protein = s12_q2_fishmeals + s12_q3_eggmeals if s12_q2_fishmeals != . & s12_q3_eggmeals != .
 replace num_meals_yest_protein = 3 if num_meals_yest_protein > 3 & num_meals_yest_protein != .

 count if num_meals_yest < num_meals_yest_protein
 count if num_meals_yest == num_meals_yest_protein

 label var num_meals_yest_protein "Number of meals yesterday w/eggs or fish"

 /* Indicator for smoking */
 tab s12_q5_smoked, m
 recode s12_q5_smoked (1 = 1) (2 = 0) (nonm = .), gen(smoked)
 la var smoked "Smoked in last 7 days"

 /* Indicator for drinking alcohol */
 recode s12_q6_numalcohol (0 = 0) (1/max = 1), gen(alcohol)
 la var alcohol "Had alcohol the last 7 days"

 /* Appetite rating */
 gen appetite = 6 - s12_q4_appetite
 la var appetite "Appetite rating"


 tab s12_q7_daysworked
 replace s12_q7_daysworked = . if s12_q7_daysworked == 77 | s12_q7_daysworked == 88 | s12_q7_daysworked == 98
 replace s12_q7_daysworked = 28 if s12_q7_daysworked > 28 & s12_q7_daysworked != .

  * when constructing variables for the number of meals missed, make sure to check for whether or not the household has children

  tab1 s12_q10b_hungrychild s12_q11b_skippedchild  s12_q12b_nofoodchild if numchildren > 0 & numchildren != .
  foreach var of varlist s12_q10b_hungrychild s12_q11b_skippedchild  s12_q12b_nofoodchild {
    replace `var' = . if numchildren == 0
    }

  recode s12_q9_health2 (4 = 1) (3 = 2) (2 = 3) (1 = 4), gen(health_self)
  replace health_self = 5 if s12_q8_health1 == 1
  la var health_self "Self-reported health rating"

** recoding variables for food index - want higher values to represent greater food security, but right now some of these are the number of times going to bed hungry **
foreach var of varlist s12_q10a_hungryadult s12_q10b_hungrychild s12_q11a_skippedadult s12_q11b_skippedchild s12_q12a_nofoodadult s12_q12b_nofoodchild {
    gen `var'_fsindex = - `var'
}

gen_index_vers s12_q10a_hungryadult_fsindex s12_q10b_hungrychild_fsindex s12_q11a_skippedadult_fsindex s12_q11b_skippedchild_fsindex s12_q12a_nofoodadult_fsindex s12_q12b_nofoodchild_fsindex num_meals_yest_protein, prefix(p9_foodindex) label("Food index")



gen h9_1_skippedadult = s12_q11a_skippedadult
la var h9_1_skippedadult "Num days adults skipped/cut meals, last week"
gen h9_2_skippedchild  = s12_q11b_skippedchild
la var h9_2_skippedchild "Num days children skipped/cut meals, last week"
gen h9_3_nofoodadult = s12_q12a_nofoodadult
la var h9_3_nofoodadult "Num days adults went without food, last week"
gen h9_4_nofoodchild = s12_q12b_nofoodchild
la var h9_4_nofoodchild "Num days children went without food, last week"
gen h9_5_hungryadult = s12_q10a_hungryadult
la var h9_5_hungryadult "Num days adults went to bed hungry, last week"
gen h9_6_hungrychild = s12_q10b_hungrychild
la var h9_6_hungrychild "Num days children went to bed hungry, last week"
gen h9_7_proteinmeals = num_meals_yest_protein
la var h9_7_proteinmeals "Num meals eaten yesterday with meat, fish or eggs"


** child food security **
foreach var of varlist h9_2_skippedchild h9_4_nofoodchild h9_6_hungrychild {
	gen `var'_neg = - `var'
}
gen_index_vers h9_2_skippedchild_neg h9_4_nofoodchild_neg h9_6_hungrychild_neg, prefix(child_foodsec) label("Child food security")


/*
  egen food_index = weightave(s12_q10a_hungryadult_fsindex s12_q10b_hungrychild_fsindex s12_q11a_skippedadult_fsindex s12_q11b_skippedchild_fsindex s12_q12a_nofoodadult_fsindex s12_q12b_nofoodchild_fsindex num_meals_yest_protein), normby(control_eligible)
  la var food_index "Food index (std by elig, control)"

  egen food_index_c = weightave(s12_q10a_hungryadult_fsindex s12_q10b_hungrychild_fsindex s12_q11a_skippedadult_fsindex s12_q11b_skippedchild_fsindex s12_q12a_nofoodadult_fsindex s12_q12b_nofoodchild_fsindex num_meals_yest_protein), normby(control)
  la var food_index_c "Food index (std by control)"

  egen food_index_lsce = weightave(s12_q10a_hungryadult_fsindex s12_q10b_hungrychild_fsindex s12_q11a_skippedadult_fsindex s12_q11b_skippedchild_fsindex s12_q12a_nofoodadult_fsindex s12_q12b_nofoodchild_fsindex num_meals_yest_protein), normby(control_lowsat_eligible)
  la var food_index_lsce "Food index (std by low-sat, control, eligible)"
*/


/*** DAYS OF WORK/SCHOOL MISSED ***/
ren s12_q7_daysworked s12_q7_daysmissed

tab s12_q7_daysmissed
recode s12_q7_daysmissed (min/-1 = .) (36/max = .) (28/35 = 28)
// some answered last month instead of last 4 weeks. Assuming low 30s responses were intended to be all of last month

gen health_daysmissed = s12_q7_daysmissed
la var health_daysmissed "Number of days of work/school missed due to health, last 4 weeks"


/*** HEALTH INDEX (COME BACK AND ADD THIS IN) ***/
/* this will only be the self-reported health measure, as that is the only
    measure of the index that we collected at baseline */


** saving **
drop s12_*
save "$da/intermediate/GE_HH-BL_health_foodsec.dta", replace
project, creates("$da/intermediate/GE_HH-BL_health_foodsec.dta")
