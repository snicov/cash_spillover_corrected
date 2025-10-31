

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


/*
 * Filename: ge_hh-welfare_consexp_EL.do
 * Description: This do file constructs the outcomes described in the HH welfare PAP on consumption & expenditure (with exception of Ligon analysis)
 *   This corresponds to primary outcomes 1-4 and sections 5.1 to 5.4 of the household welfare PAP.
 *
 * Note: make sure that flow value calculations are incorporated into this
 *
 *
 * Authors: Michael Walker
 * Last modified: 28 Sep 2018, generating based on ge_hh-welfare_assets_cons_inc_outcomes_v5.do. Adding PPP calculation
 * Date created: 14 July 2017
 */

 project, uses("$da/intermediate/GE_HH-EL_setup.dta")

 use "$da/intermediate/GE_HH-EL_setup.dta", clear

* bring in education expenditure off the bat
project, uses("$da/intermediate/GE_HH-EL_hheducation.dta") preserve
merge 1:1 s1_hhid_key using "$da/intermediate/GE_HH-EL_hheducation.dta", keepusing(h2_5_educexp*)
assert _merge == 3
drop _merge

/****************************/
/*   FAMILY 2: CONSUMPTION  */
/****************************/

// checking for missing consumption sections -- since
egen s12_cons_nonmiss = rownonmiss(s12_q*), strok

tab s12_cons_nonmiss
gen cons_missing = (s12_cons_nonmiss < 15) // these are those for which survey finished early, or did not complete consumption section. Will set to missing.

** part 1: food consumption
recode s12_q1_alcoholamt -96 = .
foreach var in s12_q1_cerealsamt s12_q1_rootsamt s12_q1_pulsesamt s12_q1_vegamt s12_q1_meatamt s12_q1_fishamt s12_q1_dairyeggsamt s12_q1_othanimalamt s12_q1_oilamt s12_q1_fruitsamt s12_q1_sugaramt s12_q1_sweetsamt s12_q1_softdrinksamt s12_q1_alcoholamt s12_q1_tobaccoamt s12_q1_spicesamt s12_q1_foodoutamt s12_q1_foodothamt {
    recode `var' -99 = .
    tab `var'
    tab version if mi(`var')
    // Survey asked "in the past 7 days"; converting to yearly values
    gen `var'_12mth = 52*`var'
    summ `var'_12mth
}

egen foodcons_12mth = rowtotal(s12_q1_cerealsamt_12mth s12_q1_rootsamt_12mth s12_q1_pulsesamt_12mth s12_q1_vegamt_12mth s12_q1_meatamt_12mth s12_q1_fishamt_12mth s12_q1_dairyeggsamt_12mth s12_q1_othanimalamt_12mth s12_q1_oilamt_12mth s12_q1_fruitsamt_12mth s12_q1_sugaramt_12mth s12_q1_sweetsamt_12mth s12_q1_softdrinksamt_12mth s12_q1_spicesamt_12mth s12_q1_foodoutamt_12mth s12_q1_foodothamt_12mth), m
replace foodcons_12mth = . if cons_missing == 1
summ foodcons_12mth
tab version if mi(foodcons_12mth)
// removing alcohol and tobacco - 29 Sep 2018

** part 2: frequent purchases in last month
foreach var in s12_q19_airtimeamt s12_q20_internetamt s12_q21_travelamt s12_q22_gamblingamt s12_q23_clothesamt s12_q24_recamt s12_q25_personalamt s12_q26_hhitemsamt s12_q27_firewoodamt s12_q28_electamt s12_q29_wateramt {
    recode `var' -99 = .
    tab `var'
    tab version if mi(`var')
    // Survey asked "in the past one month"; converting to yearly values
    gen `var'_12mth = 12*`var'
    summ `var'_12mth
}

egen freqpurchases_12mth = rowtotal(s12_q19_airtimeamt_12mth s12_q20_internetamt_12mth s12_q21_travelamt_12mth  s12_q23_clothesamt_12mth s12_q24_recamt_12mth s12_q25_personalamt_12mth s12_q26_hhitemsamt_12mth s12_q27_firewoodamt_12mth s12_q28_electamt_12mth s12_q29_wateramt_12mth), m
replace freqpurchases_12mth = . if cons_missing == 1
summ freqpurchases_12mth
tab version if mi(freqpurchases_12mth)
// removing gambling - 29 sep 2018

** part 3: infrequent purchases in last 12 months
destring s4_4_q4_schexpend, replace

replace s12_q39_othexpensesamt = 0 if s12_q39_othexpenses == 0 // setting as zero for those with no other expenses

foreach var in s4_4_q4_schexpend s12_q30_rentamt s12_q31_housemaintamt s12_q32_houseimprovamt s12_q33_religiousamt s12_q34_charityamt s12_q35_weddingamt s12_q36_medicalamt s12_q37_hhdurablesamt s12_q38_dowryamt s12_q39_othexpensesamt {
    recode `var' -99 = .
    tab `var'
    tab version if mi(`var')
}
tab version if mi(s4_4_q4_schexpend) // think we are missing this from earlier versions. Will have to figure out how to construct based on other school info.

tab version if mi(h2_5_educexp)
sum s4_4_q4_schexpend h2_5_educexp

// 2018-02-13: updating this to include the h2_5_educexp variable, created as part of the education do file.
  egen infreqpurchases_12mth = rowtotal(h2_5_educexp s12_q30_rentamt s12_q31_housemaintamt s12_q32_houseimprovamt s12_q33_religiousamt s12_q34_charityamt s12_q35_weddingamt s12_q36_medicalamt s12_q37_hhdurablesamt s12_q38_dowryamt s12_q39_othexpensesamt), m
replace infreqpurchases_12mth = . if cons_missing == 1

summ infreqpurchases_12mth
tab version if mi(infreqpurchases_12mth)

** temptation goods
egen tottemptgoods_12mth = rowtotal(s12_q1_alcoholamt_12mth s12_q1_tobaccoamt_12mth s12_q22_gamblingamt_12mth), m
replace tottemptgoods_12mth = . if cons_missing == 1
summ tottemptgoods_12mth


** combining into total consumption measure

egen totconsumption = rowtotal(foodcons_12mth freqpurchases_12mth infreqpurchases_12mth tottemptgoods_12mth), m
replace totconsumption = . if cons_missing == 1
summ totconsumption

gen p2_consumption = totconsumption
la var p2_consumption "P2: Total consumption expenditure in last 12 months"

wins_top1 p2_consumption
summ p2_consumption_wins
trim_top1 p2_consumption
summ p2_consumption_trim



*** TOTAL FOOD CONSUMPTION IN THE LAST 12 MONTHS ***
gen h2_1_foodcons_12mth = foodcons_12mth
la var h2_1_foodcons_12mth "P2.1: Food consumption expenditure (annualized from last 7 days)"
wins_top1 h2_1_foodcons_12mth
summ h2_1_foodcons_12mth_wins
trim_top1 h2_1_foodcons_12mth
summ h2_1_foodcons_12mth_trim

** other categories as a reference **
wins_top1 freqpurchases_12mth
la var freqpurchases_12mth "Frequent non-food purchases (annualized from last month)"

wins_top1 infreqpurchases_12mth
la var infreqpurchases_12mth "Infrequent purchases, last 12 months"

*** ANNUAL CONSUMPTION OF 23 ITEMS THAT WE RAN AS LSMS-STYLE ***


*** MARGINAL UTILITIES OF CONSUMPTION EXPENDITURE ***

*** TOTAL EXPENDITURE ON TEMPTATION GOODS IN THE LAST MONTH ***
foreach var in s12_q1_alcoholamt s12_q1_tobaccoamt {
// Survey asked "in the past 7 days"; converting to monthly values
    gen `var'_mth = 4*`var'
    summ `var'_mth
}

egen tottemptgoods = rowtotal(s12_q1_alcoholamt_mth s12_q1_tobaccoamt_mth s12_q22_gamblingamt), m
summ tottemptgoods

gen h2_3_temptgoods = tottemptgoods
la var h2_3_temptgoods "P2.3: Total expenditure on temptation goods in the last month"

wins_top1 h2_3_temptgoods
summ h2_3_temptgoods_wins
trim_top1 h2_3_temptgoods
summ h2_3_temptgoods_trim

// Annualize
gen h2_3_temptgoods_12 = h2_3_temptgoods*12
wins_top1 h2_3_temptgoods_12
summ h2_3_temptgoods_12_wins
trim_top1 h2_3_temptgoods_12
summ h2_3_temptgoods_12_trim

*** TOTAL HOUSING EXPENDITURE IN THE LAST 12 MONTHS ***
egen housingexp = rowtotal(s12_q30_rentamt s12_q31_housemaintamt s12_q32_houseimprovamt), m
summ housingexp

gen h2_4_housingexp = housingexp
la var h2_4_housingexp "P2.4: Total housing expenditure in the last 12 months"

wins_top1 h2_4_housingexp
summ h2_4_housingexp_wins
trim_top1 h2_4_housingexp
summ h2_4_housingexp_trim

*** TOTAL EDUCATION EXPENDITURE IN THE LAST 12 MONTHS ***
/* this is  constructed as part of the education do file */

*** TOTAL MEDICAL EXPENDITURE IN THE LAST 12 MONTHS ***
tab s12_q36_medicalamt
recode s12_q36_medicalamt -99 = .
gen h2_6_medicalexp = s12_q36_medicalamt
la var h2_6_medicalexp "P2.6: Total medical expenditure in the last 12 months"

wins_top1 h2_6_medicalexp
summ h2_6_medicalexp_wins
trim_top1 h2_6_medicalexp
summ h2_6_medicalexp_trim

*** TOTAL SOCIAL EXPENDITURE IN THE LAST 12 MONTHS ***
summ s12_q24_recamt_12mth s12_q33_religiousamt s12_q34_charityamt s12_q35_weddingamt s12_q38_dowryamt
egen socialexp = rowtotal(s12_q24_recamt_12mth s12_q33_religiousamt s12_q34_charityamt s12_q35_weddingamt s12_q38_dowryamt), m
summ socialexp

gen h2_7_socialexp = socialexp
la var h2_7_socialexp "P2.7: Total social expenditure in the last 12 months"

wins_top1 h2_7_socialexp
summ h2_7_socialexp_wins
trim_top1 h2_7_socialexp
summ h2_7_socialexp_trim

*** TOTAL EXPENDITURE ON HH DURABLES IN THE LAST 12 MONTHS ***
gen hhdurablesexp = s12_q37_hhdurablesamt
summ hhdurablesexp

gen h2_8_hhdurablesexp = hhdurablesexp
la var h2_8_hhdurablesexp "P2.8: Total expenditure on HH durables in the last 12 months"

wins_top1 h2_8_hhdurablesexp
summ h2_8_hhdurablesexp_wins
trim_top1 h2_8_hhdurablesexp
summ h2_8_hhdurablesexp_trim

*** all durabable expenditure ***
egen durables_exp = rowtotal( s12_q31_housemaintamt s12_q32_houseimprovamt s12_q37_hhdurablesamt ), m
replace durables_exp = . if cons_missing == 1

*** TOTAL EXPENDITURE ON NON - DURABLES IN THE LAST 12 MONTHS ***
egen nondurables_exp = rowtotal(h2_1_foodcons_12mth s12_q19_airtimeamt_12mth s12_q20_internetamt_12mth s12_q21_travelamt_12mth s12_q22_gamblingamt_12mth s12_q25_personalamt_12mth s12_q23_clothesamt_12mth s12_q26_hhitemsamt_12mth s12_q27_firewoodamt_12mth s12_q28_electamt_12mth s12_q29_wateramt_12mth ///
	h2_5_educexp s12_q30_rentamt h2_6_medicalexp h2_7_socialexp s12_q39_othexpensesamt h2_3_temptgoods_12), m
replace nondurables_exp = . if cons_missing == 1

wins_top1 durables_exp nondurables_exp
trim_top1 durables_exp nondurables_exp

*** TOTAL FLOW VALUE OF DURABLES IN THE LAST 12 MONTHS ***




*** TOTAL CONSUMPTION IN THE LAST 12 MONTHS, INCLUDING FLOW VALUE OF DURABLES ***



**** PER CAPITA VERSION OF CONSUMPTION MEASURES ****
* bring in household size information
project, uses("$da/intermediate/GE_HH-EL_hhroster.dta") preserve
merge 1:1 s1_hhid_key using "$da/intermediate/GE_HH-EL_hhroster.dta", keepusing(hhsize1)
assert _merge == 3
drop _merge

foreach var of varlist p2_consumption h2_1_foodcons_12mth h2_3_temptgoods_12 h2_4_housingexp h2_5_educexp h2_6_medicalexp h2_7_socialexp h2_8_hhdurablesexp durables_exp nondurables_exp {
    local vl : var label `var'
    gen `var'_pc = `var' / hhsize1
    la var `var'_pc "`vl' (per-capita)"
    wins_top1 `var'_pc
    trim_top1 `var'_pc
}


/*** PPP VERSION OF CONSUMPTION MEASURES ***/
foreach var of varlist p2_consumption* h2_1_foodcons_12mth* h2_3_temptgoods_12* h2_4_housingexp* h2_5_educexp* h2_6_medicalexp* h2_7_socialexp* h2_8_hhdurablesexp* freqpurchases_12mth infreqpurchases_12mth durables_exp* nondurables_exp* {
	loc vl : variable label `var'
	gen `var'_PPP = `var' * $ppprate
	la var `var'_PPP "`vl' (PPP)"
}



*** SAVING INTERMEDIATE DATASET ***
keep s1_hhid_key p2_consumption* h2_1_foodcons_12mth* h2_3_temptgoods_12* h2_4_housingexp* h2_5_educexp* h2_6_medicalexp* h2_7_socialexp* h2_8_hhdurablesexp* freqpurchases_12mth infreqpurchases_12mth durables_exp* nondurables_exp* s12_*
save  "$da/intermediate/GE_HH-EL_hhexpenditure.dta", replace
project, creates("$da/intermediate/GE_HH-EL_hhexpenditure.dta")
