/*
 * Filename: 1_construct_hh-outcomes_EL.do
 * Description: This do file constructs an analysis dataset
 *    of endline household survey outcomes. It also merges in baseline values of these outcomes. This serves as the basis for the spatial treatment dataset that adds in additional treatment variables.
 * Author: Michael Walker
 * Date: 17 Jun 2019 -- building on previous work
 */

/* Preliminaries */
clear
clear matrix
clear mata


* running globals *
project, do("$do/GE_global_setup.do")

cap log close
log using "$dl/1_construct_hh-outcomes_EL_`c(current_date)'.log", replace text

** setting up dataset **
project, do("$do/construct/hh-survey-EL/100a_ge_hh-survey-EL_data_setup.do")
do "$do/construct/hh-survey-EL/100a_ge_hh-survey-EL_data_setup.do"

/********************************/
/* COVARIATES FOR HETEROGENEITY */
/********************************/

** basic demographic variables **
project, do("$do/construct/hh-survey-EL/101_ge_frbasics_EL.do")
project, do("$do/construct/hh-survey-EL102_ge_hhroster_EL.do")


/************** RUNNING DO FILES TO CREATE ENDLINE OUTCOMES *************************/
* generating ag production dataset
project, do("$do/construct/103_ge_agproduction_EL.do")

** generate household-level education outcomes. Individual-level education outcomes come later **
project, do("$do/construct/104_ge_educationHH_EL.do")
project, do("$do/construct/105_ge_assets_EL.do")
project, do("$do/construct/106_ge_consexp_EL.do")
project, do("$do/construct/107_ge_income_revenue_EL.do")

project, do("$do/construct/108_ge_health_psych_asp_EL.do")
project, do("$do/construct/109_ge_crimesafety_EL.do")
project, do("$do/construct/110_ge_femaleempowerment_EL.do")
project, do("$do/construct/111_ge_laborsupplyHH_EL.do") // this still needs to be checked
project, do("$do/construct/112_ge_migration_transfers_EL.do")

** other ad-hoc variables - later, integrate into the rest **
/* These are generally from local PF stuff */
project, do("$do/construct/113_ge_commoutcomes_EL.do")

** list randomization outcomes **
//do "114_ge_listrand_EL.do" - this do file was just basic cleaning. Need to instead move this to analysis versions of the variables
project, do("$do/115_ge_hh-interest_rates_EL.do")

/* Layna was working on integrating this in a different branch. Update with her stuff when ready.

* generating flow value of durables dataset - generate list of unit prices
if `run_flowval' == 1 {
    do "116_ge_usercost_rentalequiv_EL.do"
}

* merge flow value in with outcomes data -- 2nd part of the build_usercost_rentequiv_EL do file
use "$dt/GE_HH-Endline_Outcomes.dta", clear
merge 1:1 s1_hhid_key
*/

** combining into endline dataset **
project, do("$do/117_ge_combine_EL_datasets.do")

** filling in and generating missing indicators for outcome variables **
/* given this mixes eligible and ineligible households, does it matter how we do this? */
project, uses("$da/GE_HH-Analysis_AllHHs_nofillBL.dta")
use "$da/GE_HH-Analysis_AllHHs_nofillBL.dta", clear

foreach var of varlist *BL {
    if substr("`var'", 1, 1) != "M" {
      cap gen M`var' = (mi(`var'))
      tab M`var'
      summ `var'
      replace `var' = r(mean) if M`var' == 1
    }
}


/*
** generating PPP values - move to each individual do file **
foreach var of varlist p3_totincome_wins p3_1_agprofit_wins p3_2_nonagprofit_wins p3_3_wageearnings_wins nonagincome_wins p4_totrevenue_wins p4_1_agrevenue_wins p4_2_nonagrevenue_wins p4_4_totcosts_wins p4_5_agcosts_wins p4_6_nonagcosts_wins health_medexpend_wins p7_1_educexpense_wins p11_6_nettransfers_wins2 nettransfersHH_first4_wins2 nettransfersfamily_first4_wins2 nettransfersHHvill_first4_wins2 amttransrecHH_first4_wins transrecfamily_first4_wins transrecHHvill_first4_wins amttranssentHH_first4_wins transsentfamily_first4_wins transsentHHvill_first4_wins {
    * endline
    gen `var'_PPP = `var' * $ppprate
    loc vl : var label `var'
    la var `var'_PPP "`vl' (PPP)"

    * baseline
    cap ds `var'_BL
    if _rc == 0 {
        gen `var'_PPP_BL = `var'_BL * $ppprate
        loc vlb : var label `var'_BL
        la var `var'_PPP_BL "`vlb' (PPP)"
    }
}
*/

** DO WE NEED THIS? CAN WE RE-ORGANIZE SO THAT EVERYTHING IS OFF OF THE SPATIAL DATASET? **
compress
save "$da/GE_HH-Analysis_AllHHs.dta", replace
project, creates("$da/GE_HH-Analysis_AllHHs.dta")
/*
unclear if we need the rest of these
/*** GENERATING ANALYSIS ELIGIBLE VERSION ***/
use "$da/GE_HH-Analysis_AllHHs_nofillBL_$date.dta", clear
keep if eligible == 1

save "$da/GE_HH-Analysis_EligibleSample_nofillBL_$date.dta", replace

** filling in and generating missing indicators for outcome variables **
/* COME BACK TO: WHAT IS THE RIGHT WAY TO HANDLE TRIMMED VALUES HERE? I DON'T THINK I WANT TO SET TO THE MEAN, THOUGH I'M NOT SURE. CURRENTLY THESE ARE GETTING SET TO THE MEAN */

*removing covariates (hh characteristics, etc) from list being filled in
foreach var of varlist p1*BL h1*BL p3*BL p4*BL p5*BL h5*BL p9*BL h9*BL {
    gen M`var' = (mi(`var'))
    tab M`var'
    summ `var'
    replace `var' = r(mean) if M`var' == 1
}

compress

save "$da/GE_HH-Analysis_EligibleSample_$date.dta", replace

*/
