

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

/************************************************/
/*  PREPPING BASELINE DATA                      */
/************************************************/
/* this generates a temporary dataset "$dt/prepped_BL.dta", which can be merged below */
/* It calls one other program - ge_hh-welfare_baseline_vars.do. This renames some of the baseline
   variables to match endline versions of the names. May still want to move all of these to a more
   consistent naming set-up. */
project, uses("$da/GE_HH-Survey-BL_Analysis_AllHHs.dta") // eventually bring into flow, and construct variables below as part of that
use "$da/GE_HH-Survey-BL_Analysis_AllHHs.dta", clear







/************************************************/
/*  COMPILING ENDLINE DATASETS                   */
/************************************************/
* ideally start with sample master instead -- come back to this
use "$da/intermediate/GE_HH-EL_setup.dta", clear

gen hhid_key = s1_hhid_key

* come back to make this more restrictive, but right now preparedata file uses some of these variables
keep hhid_key treat eligible s1_* today s1_hhid_key village_code
//drop s4_1_*

local i = 1
foreach stub in frbasics hhroster agproduction_wide hhassets hhexpenditure income_revenue health_psych_asp ///
            hheducation femempower hhlaborsupply security migration_transfers ///
            commoutcomes loanrates {
              project, uses("$da/intermediate/GE_HH-EL_`stub'.dta") preserve

              merge 1:1 s1_hhid_key using "$da/intermediate/GE_HH-EL_`stub'.dta", gen(_m`i') update replace
              local ++i
}

tab1 _m*


/************************************************/
/*  MERGING ENDLINE & BASELINE DATA             */
/************************************************/
merge 1:1 s1_hhid_key using "$da/GE_HH-Survey-BL_Analysis_AllHHs.dta", gen(_mBL) keepusing(*_BL baselined) force // if there are additional variables that we need to add, do this above

* these should now already be dropped
drop if _mBL == 2 // can't estimate treatment effects for those we didn't find in round 2. This should also drop ineligible households here

replace baselined = 0 if baselined == .
tab baselined


** bringing in experimental start date **
/*
project, uses("$dt/GE_experimental_timing_wide_FINAL.dta") preserve
merge n:1 village_code using "$dt/GE_experimental_timing_wide_FINAL.dta", gen(_mt) keepusing(exp_start_1)

cap gen svy_mth = mofd(today)
tab svy_mth
gen months_since_start = svy_mth - exp_start_1

tab months_since_start
summ months_since_start, d

gen hi_time = (months_since_start > r(p50)) if ~mi(months_since_start)
tab hi_time
*/
** bringing in saturation cluser variable **
merge n:1 village_code using "$dr/GE_Treat_Status_Master.dta", keepusing(treat  satlevel_name hi_sat) update

//assert _merge != 4 & _merge != 5
assert  _merge != 5 // come back to this -- new after changing sample master
drop if _merge == 2
// drop 1's too?
drop _merge

/*
*** bringing in household weights ***
project, uses("$da/GE_HH-Survey_Tracking_Attrition.dta") preserve
replace hhid_key = s1_hhid_key if mi(hhid_key)
merge 1:1 hhid_key using "$da/GE_HH-Survey_Tracking_Attrition.dta", keepusing(hhweight_EL)
drop if _merge == 2
drop _merge
*/
gen hhweight_EL = 1 // temp while we get this up and running -- where do we want weights to be stored?
/*** saving dataset that has not been filled in ***/
compress

note: Dataset created at TS

** all HHs
save "$da/GE_HH-Analysis_AllHHs_nofillBL.dta", replace
project, creates("$da/GE_HH-Analysis_AllHHs_nofillBL.dta") preserve

** filling in and generating missing indicators for outcome variables **
/* given this mixes eligible and ineligible households, does it matter how we do this? */
sleep 1000
project, uses("$da/GE_HH-Analysis_AllHHs_nofillBL.dta")
use "$da/GE_HH-Analysis_AllHHs_nofillBL.dta", clear


foreach var of varlist *BL {
    gen M`var' = (mi(`var'))
    tab M`var'
    summ `var' [weight=hhweight_EL]
    replace `var' = r(mean) if M`var' == 1
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

** Checking sublocation codes **
gen vill_str = strofreal(village_code , "%16.0f")
gen vill_sl = substr(vill_str , 1, 9)
count if vill_sl != s1_q2b_sublocation
replace s1_q2b_sublocation = vill_sl if vill_sl != s1_q2b_sublocation // should be 1 change, for SL that was not in sample


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
