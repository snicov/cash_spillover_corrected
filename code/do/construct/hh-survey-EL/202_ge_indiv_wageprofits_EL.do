/*
 * Filename: 202_ge_indiv_wageprofits_EL.do
 * DESCRIPTION: This do file uses the household-level analysis dataset to generate measures of individual wage earnings and self-employment profits, both overall and by sector.
 * Inputs: GE clean endline data / analysis data, GE roster analysis data
 * Outputs:
     - 1. Individual-by-sector wage dataset
     - 2. Individual level wage and profit totals, with demographic controls
 * These output datasets serve as further inputs into the PrepareData files for spatial data.
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


/* the following is all relevant for wages */
/** saving tempfile with only adults for later merge **/
project, uses("$da/GE_HH-Endline_HHRoster_LONG.dta")
use "$da/GE_HH-Endline_HHRoster_LONG.dta", clear

tempfile hhros_adults

count

keep if age >= $adult_age

count



** generating quadratic terms for age and years of education. Only relevant for adults for later mincer specifications **
gen age2 = age * age
la var age2 "Age squared"

gen yearsedu2 = yearsedu * yearsedu
la var yearsedu2 "Years education squared"

gen yearsedu_alt2 = yearsedu_alt * yearsedu_alt
la var yearsedu_alt2 "Years education (alt) squared"


count if hhid_key == ""

save `hhros_adults'

/**********************************************/
/* INDIVIDUAL LEVEL DATASET FOR ECONOMIC ACTIVITY */
/**********************************************/

* Household-level indicators of interest to Dennis (again, need to make sure all is consolidated, and as part of the master constrution process)
** what of these should be created here, vs just pulling in from previously-constructed variables?
project, uses("$da/GE_HH-Analysis_AllHHs_nofillBL.dta")
use "$da/GE_HH-Analysis_AllHHs_nofillBL.dta", clear

/* Indicators for households engaged in agriculture, self-employment and employment */
* generating new variables so that they are named consistently
gen hh_selfag = 2 - s7_q1_selfag
la var hh_selfag "HH engages in agriculture"

gen hh_selfemp = p4_3_selfemployed // constructed based on s8_q1_selfemployed. If switching to this, then need to be careful
tab s8_q1a_numbusinesses // if report 0 businesses, changing
replace hh_selfemp = 0 if s8_q1a_numbusinesses == 0
la var hh_selfemp "HH engages in self-employment"


gen hh_emp = (s9_q1_employed == 1 | s9_q1a_volunteer == 1) if ~mi(s9_q1_employed) | ~mi(s9_q1a_volunteer) // decide how we want to consider volunteer work -- unclear if this was being brought in before

tab s9_q1b_numemp // some with zero -- using this to recode main measure
replace hh_emp = 0 if s9_q1b_numemp == 0
la var hh_emp "HH engages in wage/volunteer work"

tempfile hhdata
save `hhdata'

/******* RESHAPING TO INDIVIDUAL LEVEL FOR SECTIONS 8 AND 9 ON SELF-EMP, EMP *******/

/* doing this section by section then merging as that's a bit more manageable, can more easily make sure merging on hh roster number */


/*** WAGES FOR WAGE WORKERS ***/

** ARE WE MISSING ANY WAGE WORKERS? goinb back to surveycto, it does not appear like we had a condition here. This is explored more at household-level **
/*TK:  TO DO: make sure that we have checked that the number of wage workers reported by household matches the number that we have. Also see if there are any other roster checks that we can use to try to validate this. And what about past work? Can that be brought into individual-level dataset? */

** first, ensuring key variables have been consolidated **
desc s9_q10_cashsalary_*, full

tab s9_emp_count


local s9_keepvars "s9_q1_employed"
foreach var in  s9_q2_hhmemberemp_  s9_q3_datestart_ s9_q4_occupation_ s9_q4_occupation_oth1_ s9_q4_occupation_oth2_ s9_q4_occupation_oth3_ s9_q5_industry_ s9_q5_industry_oth_ s9_q6_empstatus_ s9_q6_empstatus_oth_ s9_q7_workpattern_ s9_q7_workpattern_oth_  s9_q8_hrsworked_ s9_q9_othemployees_ s9_q10_cashsalary_ s9_q10_cashsalaryfx_ s9_q10_cashsalaryfx_oth_ s9_q11_incometax_ s9_q11_incometaxfx_ s9_q11_incometaxfx_oth_ s9_q12a_payinkind_ s9_q12b_healthins_ s9_q12c_housing_ s9_q12d_clothing_ s9_q12e_training_ s9_q12f_othbenefits_ s9_q12_benefitsfx_ s9_q12_benefitsfx_oth_ {
    forval i=1/4 {
        local s9_keepvars "`s9_keepvars' `var'`i'"
    }
}
// note - here we do not want to keep calculations for yearly values, as it is unclear

keep s1_hhid_key treat* eligible* *hi_sat* village_code*  `s9_keepvars'


cap tostring s9_q4_occupation_* s9_q4_occupation_oth1_* s9_q4_occupation_oth2_* s9_q4_occupation_oth3_* *oth*, replace


reshape long s9_q2_hhmemberemp_  s9_q3_datestart_ s9_q4_occupation_ s9_q4_occupation_oth1_ s9_q4_occupation_oth2_ s9_q4_occupation_oth3_ s9_q5_industry_ s9_q5_industry_oth_ s9_q6_empstatus_ s9_q6_empstatus_oth_ s9_q7_workpattern_ s9_q7_workpattern_oth_  s9_q8_hrsworked_ s9_q9_othemployees_ s9_q10_cashsalary_ s9_q10_cashsalaryfx_ s9_q10_cashsalaryfx_oth_ s9_q11_incometax_ s9_q11_incometaxfx_ s9_q11_incometaxfx_oth_ s9_q12a_payinkind_ s9_q12b_healthins_ s9_q12c_housing_ s9_q12d_clothing_ s9_q12e_training_ s9_q12f_othbenefits_ s9_q12_benefitsfx_ s9_q12_benefitsfx_oth_ , i(s1_hhid_key) j(emp_num)

ren *_ * // dropping trailing underscores

tab1 s9_q2_hhmemberemp

gen hhros_num = s9_q2_hhmemberemp

drop if hhros_num == .

/*
** bring in saturation cluster **
merge n:1 village_code using "$dr/GE_Treat_Status_Master.dta", keepusing(satlevel_name)

egen satcluster = group(satlevel_name)
gen treat_eligible = treat * eligible
*/

/*** INDIVIDUAL OCCUPATION-LEVEL - SAVE HERE? ***/
** bringing in household member demographic information
project, uses("$da/GE_HH-Endline_HHRoster_LONG.dta") preserve
merge n:1 s1_hhid_key hhros_num using "$da/GE_HH-Endline_HHRoster_LONG.dta"


drop if _merge == 2
drop _merge

replace hhid_key = s1_hhid_key if hhid_key == "" // TK: why is this occuring?

save "$dt/wages_individbyoccupationlevel.dta", replace
project, creates("$dt/wages_individbyoccupationlevel.dta") preserve

** consolidate **
destring s9_q9_othemployees, replace
destring s9_q12d_clothing s9_q12f_othbenefits , replace
summ

recode s9_q9_othemployees (-99 = .)

gen job_count = 1

collapse (sum) job_count s9_q8_hrsworked s9_q9_othemployees s9_q10_cashsalary s9_q11_incometax s9_q12a_payinkind s9_q12b_healthins s9_q12c_housing s9_q12d_clothing s9_q12e_training s9_q12f_othbenefits, ///
    by(s1_hhid_key hhros_num  treat hi_sat eligible village_code )

save "$dt/wages_individlevel.dta", replace
project, creates("$dt/wages_individlevel.dta") preserve

/*** SELF-EMPLOYMENT OUTCOMES BY WORKER ***/

use `hhdata', clear

local s8_varlist "s8_q1_selfemployed s8_q1a_numbusinesses"
cap tostring s8_q14_startresourcefx*, replace
cap tostring s8_q18_vanddetails_*, replace

foreach var in ///
   s8_q2_industry_ s8_q3_withinvillage_ s8_q3a_operatedwhere_ s8_q3b_decisionmakerrosnum_ s8_q4_hrsworked_ s8_q5_monthsworked_ s8_q6_numemployees_ s8_q6a_hhemployees_ s8_q6b_employeeslast6mth_ s8_q6b_wagebill_ s8_q6b_wagebillfx_ s8_q6b_wagebillfx_oth_ s8_q7a_earningslastmth_ s8_q7b_earningslastyr_ s8_q7_earningsfx_ s8_q7_earningsfx_oth_ s8_q8_licensed_ s8_q8a_licensecost_ s8_q8b_licensevalid_ s8_q9_registered_ s8_q10_limitedco_ s8_q11a_profitlastmth_ s8_q11b_profitlastyr_ s8_q11_profitfx_ s8_q11_profitfx_oth_ s8_q12_startmth_ s8_q12_startyr_ s8_q13_startamt_ s8_q13_startamtfx_ s8_q13_startamtfx_oth_ s8_q14_startresource_ s8_q14_startresourcefx_ s8_q15_ownpremises_ s8_q15a_rentamt_ s8_q15a_rentamtfx_ s8_q15a_rentamtfx_oth_ s8_q16a_elecwater_ s8_q16b_insurance_ s8_q16c_interest_ s8_q16d_goodsresale_ s8_q16e_inputs_ s8_q16f_repairs_ s8_q16g_security_ s8_q16h_othercosts s8_q16_costsfx_ s8_q16_costsfx_oth_ s8_q17a_healthinsur_ s8_q17b_marketfees_ s8_q17c_countytaxes_ s8_q17d_natltaxes s8_q17e_localtaxes_ s8_q17f_bribes_ s8_q17_expensesfx_ s8_q17_expensesfx_oth_ s8_q18_vanddetails_ s8_q18_vandamt_ s8_q18_vandfx_ s8_q18_vandfx_oth_ {
     forval i=1/5 {
         loc s8_varlist "`s8_varlist' `var'`i'"
     }
} // end variable loop

keep s1_hhid_key treat* eligible* *hi_sat* village_code* `s8_varlist' //s8_hhmm* -- need to drop this, figure out how/where this breaks anything TK
tostring s8_q3b_decisionmakerrosnum* s8_q5_monthsworked*, replace
reshape long s8_q2_industry_ s8_q3_withinvillage_ s8_q3a_operatedwhere_ s8_q3b_decisionmakerrosnum_ s8_q4_hrsworked_ s8_q5_monthsworked_ s8_q6_numemployees_ s8_q6a_hhemployees_ s8_q6b_employeeslast6mth_ s8_q6b_wagebill_ s8_q6b_wagebillfx_ s8_q6b_wagebillfx_oth_ s8_q7a_earningslastmth_ s8_q7b_earningslastyr_ s8_q7_earningsfx_ s8_q7_earningsfx_oth_ s8_q8_licensed_ s8_q8a_licensecost_ s8_q8b_licensevalid_ s8_q9_registered_ s8_q10_limitedco_ s8_q11a_profitlastmth_ s8_q11b_profitlastyr_ s8_q11_profitfx_ s8_q11_profitfx_oth_ s8_q12_startmth_ s8_q12_startyr_ s8_q13_startamt_ s8_q13_startamtfx_ s8_q13_startamtfx_oth_ s8_q14_startresource_ s8_q14_startresourcefx_ s8_q15_ownpremises_ s8_q15a_rentamt_ s8_q15a_rentamtfx_ s8_q15a_rentamtfx_oth_ s8_q16a_elecwater_ s8_q16b_insurance_ s8_q16c_interest_ s8_q16d_goodsresale_ s8_q16e_inputs_ s8_q16f_repairs_ s8_q16g_security_ s8_q16h_othercosts s8_q16_costsfx_ s8_q16_costsfx_oth_ s8_q17a_healthinsur_ s8_q17b_marketfees_ s8_q17c_countytaxes_ s8_q17d_natltaxes s8_q17e_localtaxes_ s8_q17f_bribes_ s8_q17_expensesfx_ s8_q17_expensesfx_oth_ s8_q18_vanddetails_ s8_q18_vandamt_ s8_q18_vandfx_ s8_q18_vandfx_oth_, i(s1_hhid_key) j(selfemp_num)

ren *_ * // dropping trailing underscores

tab selfemp_num
tab s8_q3b_decisionmakerrosnum

// Treating irst person listed as main decisionmaker

split s8_q3b_decisionmakerrosnum

gen hhros_num = s8_q3b_decisionmakerrosnum1
destring hhros_num, replace

drop if hhros_num == . // dropping observations with no actual self-employment activity. reshape tries to create balanced panel

summ
recode s8_q6b_wagebill (99 1 = .)

duplicates report s1_hhid_key hhros_num

gen ent_count = 1

** collapsing to one observation per person **
collapse (sum) ent_count s8_q4_hrsworked s8_q6_numemployees s8_q6a_hhemployees s8_q6b_employeeslast6mth s8_q6b_wagebill s8_q7a_earningslastmth s8_q7b_earningslastyr  s8_q8a_licensecost s8_q9_registered s8_q15a_rentamt s8_q16a_elecwater s8_q16b_insurance s8_q16c_interest s8_q16d_goodsresale s8_q16e_inputs s8_q16f_repairs s8_q16g_security s8_q16h_othercosts s8_q17a_healthinsur s8_q17b_marketfees s8_q17c_countytaxes s8_q17d_natltaxes s8_q17e_localtaxes s8_q17f_bribes s8_q11a_profitlastmth s8_q11b_profitlastyr ///
s8_q3_withinvillage s8_q8_licensed, ///
    by(s1_hhid_key hhros_num treat hi_sat eligible village_code )

** saving **
save "$dt/selfemp_individlevel.dta", replace
project, creates("$dt/selfemp_individlevel.dta")

/**** setting up individual-level dataset ****/

** starting with household roster of adults **
project, uses("$da/GE_HH-Endline_HHRoster_LONG.dta")
use "$da/GE_HH-Endline_HHRoster_LONG.dta", clear

** merging with wage work **
merge 1:1 s1_hhid_key hhros_num using "$dt/wages_individlevel.dta", gen(_mwages)

** merging with self-employment **
merge 1:1 s1_hhid_key hhros_num using "$dt/selfemp_individlevel.dta", gen(_mselfemp)


** keeping only adults
keep if age >= $adult_age

// checked names, these seem to be matching well to same people

/**** GENERATING COMBINED, INDIVIDUAL-LEVEL OUTCOMES ****/
summ s8_q11a_profitlastmth s8_q7a_earningslastmth s9_q10_cashsalary s9_q12a_payinkind s9_q12b_healthins s9_q12c_housing s9_q12d_clothing s9_q12e_training s9_q12f_othbenefits
summ s8_q4_hrsworked s9_q8_hrsworked
recode s8_q4_hrsworked (120/max = 120)

recode s8_q11a_profitlastmth s8_q7a_earningslastmth s9_q10_cashsalary s9_q12a_payinkind s9_q12b_healthins s9_q12c_housing s9_q12d_clothing s9_q12e_training s9_q12f_othbenefits (-99 -88 = .)

* for profits, set those less than zero to missing
replace s8_q11a_profitlastmth = . if s8_q11a_profitlastmth < 0

* profits per hour *
gen hrprofit = s8_q11a_profitlastmth / (s8_q4_hrsworked*(30/7)) // total profits last month divided by hours last week, converted to monthly hours
la var hrprofit "Self-emp profits / hr (main decisionmaker)"

* earnings per hour *
gen hrselfempearn = s8_q7a_earningslastmth / (s9_q8_hrsworked*(30/7))
la var hrselfempearn "Self-emp earnings / hr (main decisionmaker)"

* wages per hour *
gen hrwagesal = s9_q10_cashsalary / (s9_q8_hrsworked*(30/7))
la var hrwagesal "Hourly wages for wage workers (cash salary)"

* wages + benefits per hour *
egen wagebenefits_mth = rowtotal(s9_q10_cashsalary s9_q12a_payinkind s9_q12b_healthins s9_q12c_housing s9_q12d_clothing s9_q12e_training s9_q12f_othbenefits), m

gen hrwageben = wagebenefits_mth/ (s9_q8_hrsworked*(30/7))
la var hrwageben "Hourly wages for wage workers (cash sal + benefits)"

* total profits + wages per hour *
egen totprofitwage = rowtotal(s8_q11a_profitlastmth s8_q7a_earningslastmth), m
la var totprofitwage "Total self-employed profits and wage earnings last month"
egen hrs_selfempwage = rowtotal(s8_q4_hrsworked s9_q8_hrsworked), m

gen hrprofitwage = totprofitwage / (hrs_selfempwage*(30/7))
la var hrprofitwage "Total wages and profits / hr"

** converting to PPP, taking logs **

foreach var of varlist hrprofit hrselfempearn hrwagesal hrwageben hrs_selfempwage hrprofitwage totprofitwage {
    di "`var'"
    summ `var', d
    replace `var' = r(p99) if `var' > r(p99) & ~mi(`var')
    gen `var'_PPP = `var' * $ppprate
    gen ln`var' = ln(`var')
    loc vl : var label `var'
    la var `var'_PPP "`vl' (PPP)"
    la var ln`var' "Log `vl'"

    summ *`var'*
}

** labeling other variables **
la var s8_q4_hrsworked "Hours worked in self-employment"
la var s9_q8_hrsworked "Hours worked in wage employment"
la var hrs_selfempwage "Hours worked in self-employment or wage employment"

** saving **
save "$da/GE_HH-Survey-EL_WageProfits_Roster.dta", replace
project, creates("$da/GE_HH-Survey-EL_WageProfits_Roster.dta")
