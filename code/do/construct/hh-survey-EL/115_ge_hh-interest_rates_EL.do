

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
 * Filename: hh_interest_rates.do
 * Description: This do file constructs loan-valued lending and borrowing rates for households.
 * Total borrowing amounts are constructed and cleaned elsewhere, but used here for weighting.
 * Author: Michael Walker
 * Date: 12/14/18
 */

 ** setting up to use intermediate dataset for more modular running
 project, uses("$da/intermediate/GE_HH-EL_setup.dta")

 use "$da/intermediate/GE_HH-EL_setup.dta", clear

** merge in some totals from assets construction **
project, uses("$da/intermediate/GE_HH-EL_hhassets.dta") preserve
merge 1:1 s1_hhid_key using "$da/intermediate/GE_HH-EL_hhassets.dta", keepusing(hh_loanamt totval_loanstaken *_loanamt)

*** local for trimming interest rates -- don't want values that are too high ***
loc maxrate = 3

/*
** check - are households more likely to have bank or savings accounts? **
/* these may be part of some other things, but want to double check effects for these first */
foreach var of varlist s10_q0_mpesaaccount s10_q1_bankaccount s10_q1a_savingsaccount {
    di "`var'"
    tab `var'
    loc newname = "has" + substr("`var'", strrpos("`var'", "_"), .)
    recode `var' (2 = 0), gen(`newname')

}

replace has_savingsaccount = 0 if has_bankaccount == 0

di "Eligible HHs"
foreach var of varlist has_mpesaaccount has_bankaccount has_savingsaccount {
    summ `var' if eligible == 1 & treat == 0 & hi_sat == 0
    reg `var' treat hi_sat if eligible == 1 , cluster(village_code)
}

di "Ineligible HHs"
foreach var of varlist has_mpesaaccount has_bankaccount has_savingsaccount {
    summ `var' if eligible == 0 & treat == 0 & hi_sat == 0
    reg `var' treat hi_sat if eligible == 0, cluster(village_code)
}

*/

/* Interest codes

1	Kenyan shillings
2	Rate/percent
4	Ugandan shillings
88	Flat rate
99	No interest
-99	Don't know

Time codes
1	Day
2	Week
3	Month
4	Year
88	Flat rate
99	No interest
-99	Don't know

*/


**** ROSCA loans ****
/*
** generating interest rate **
/* as most values reported as monthly, converting everything to this frequency. Compounding daily and weekly values */
tab s10_q3f_roscaloanintamt
recode s10_q3f_roscaloanintamt (0.88 88 = -88) (-99 -30 = .) // most likely supposed to be -88, no interest

* case 0: no interest charged. Base this on combination of int amt and time questions, then recode these and go to the rest
tab1 s10_q3f_roscaloanintunit s10_q3f_roscaloanunit if s10_q3f_roscaloanintamt == -88 | s10_q3f_roscaloanintamt == 0

tab s10_q3f_dloanintamt if s10_q3f_roscaloanunit == 99 | s10_q3f_roscaloanintunit == 99
// if they state that interest was charged, not going to consider as zero interest

replace s10_q3f_roscaloanunit = . if s10_q3f_roscaloanintamt > 0 & s10_q3f_roscaloanintamt < . & (s10_q3f_roscaloanunit == 99 | s10_q3f_roscaloanintunit == 99)
replace s10_q3f_roscaloanintunit = . if s10_q3f_roscaloanintamt > 0 & s10_q3f_roscaloanintamt < . & (s10_q3f_roscaloanunit == 99 | s10_q3f_roscaloanintunit == 99)

gen rosca_intrate = 0 if s10_q3f_roscaloanintamt == -88  // zero values of intamt should still be okay

foreach var of varlist s10_q3f_roscaloanunit s10_q3f_roscaloanintunit {
    replace `var' = 99 if s10_q3f_roscaloanintamt == -88 // this should exclude these obs from the other calculations
}

* case 1: reported as rate / percent
tab s10_q3f_roscaloanintunit // how do we want to treat no interest? zero?
tab s10_q3f_roscaloanintamt if s10_q3f_roscaloanintunit == 2
list s10_q3d_roscaloanamt s10_q3f_roscaloanintamt s10_q3f_roscaloanintunit if s10_q3f_roscaloanintamt >=50 & s10_q3f_roscaloanintunit == 2 & ~mi(s10_q3f_roscaloanintamt)
* these look very strongly like amounts -- MW recoding
replace s10_q3f_roscaloanintunit = 1 if s10_q3f_roscaloanintamt >= 50 & ~mi(s10_q3f_roscaloanintamt) // there will still be some 100s

* for values reported in rates, setting to the rate
* adjusting to monthly for those not reported at that frequency
tab s10_q3f_roscaloanunit if s10_q3f_roscaloanintunit == 2

replace rosca_intrate = (1 + s10_q3f_roscaloanintamt / 100)^30 - 1 if s10_q3f_roscaloanintunit == 2 &  s10_q3f_roscaloanunit == 1 // converting daily values
replace rosca_intrate = (1 +s10_q3f_roscaloanintamt / 100)^4 - 1 if s10_q3f_roscaloanintunit == 2 & s10_q3f_roscaloanunit == 2 // converting weekly values
replace rosca_intrate = s10_q3f_roscaloanintamt / 100 if s10_q3f_roscaloanintunit == 2 & s10_q3f_roscaloanunit == 3 // monthly values -- no adjustment
replace rosca_intrate = (1 +s10_q3f_roscaloanintamt / 100)^(1/12) - 1 if s10_q3f_roscaloanintunit == 2 & s10_q3f_roscaloanunit == 4 // converting yearly values


* Case 2: Amounts reported in Kenya shillings
tab s10_q3f_roscaloanunit if s10_q3f_roscaloanintunit == 1 // amounts that should be changed per line

replace rosca_intrate = (1 + (s10_q3f_roscaloanintamt / s10_q3d_roscaloanamt))^30 - 1 if s10_q3f_roscaloanintunit == 1 & s10_q3f_roscaloanunit == 1 // daily rate
replace rosca_intrate = (1 + (s10_q3f_roscaloanintamt / s10_q3d_roscaloanamt))^4 - 1 if s10_q3f_roscaloanintunit == 1 & s10_q3f_roscaloanunit == 2 // weekly rate
replace rosca_intrate = (s10_q3f_roscaloanintamt / s10_q3d_roscaloanamt) if s10_q3f_roscaloanintunit == 1 & s10_q3f_roscaloanunit == 3 // monthly rate
replace rosca_intrate = (1 + (s10_q3f_roscaloanintamt / s10_q3d_roscaloanamt))^(1/12) - 1 if s10_q3f_roscaloanintunit == 1 & s10_q3f_roscaloanunit == 4 // annual rate to monthly

** how many missing values remain now?
count if s10_q3f_roscaloanintamt != . & rosca_intrate == .
tab1 s10_q3f_* if s10_q3f_roscaloanintamt != . & rosca_intrate == .

summ rosca_intrate
recode rosca_intrate (`maxrate' / max = .)
summ rosca_intrate


** for now, just setting some of these to missing -- not sure what to do, as I think some of the units are off for conversions but otherwise amounts might be ok **

/* COME BACK TO THIS -- STILL A BIT TRICKY
* Case 3: flat rate -- use date loan due
tab s10_q3f_roscaloanintamt if s10_q3f_roscaloanintunit == 88
tab s10_q3h_roscaloanduedate if s10_q3f_roscaloanintunit == 88
gen roscaloanduedate = date(s10_q3h_roscaloanduedate, "MDY")
replace roscaloanduedate = date(s10_q3h_roscaloanduedate, "DMY") if mi(roscaloanduedate)
gen roscaduemonth = mofd(roscaloanduedate)
format roscaduemonth %tm
replace roscaduemonth = . if roscaduemonth== tm(1900m1) | roscaduemonth== tm(1990m1) // value for no due date


gen roscaloan_nummonths = roscaduemonth - svy_mth
tab roscaloan_nummonths // what to do about negative values? how many?
tab roscaloan_nummonths if s10_q3f_roscaloanintunit == 88
count if roscaloan_nummonths < 0 & s10_q3f_roscaloanintunit == 88

*/
*/

*** tab all amount variables first for cleaning ***
ren s10_q6c_mshwariintamount s10_q6c_mshwariintamt
ren s10_q8c_intamount   s10_q8c_intamt
ren hh_loanamt hhloan_loanamt

tab1 s10_q*intamt
recode s10_q*intamt (0.88 88 -85 -80 -8 = -88) (0.99 = -99)
recode s10_q6c_mshwariintamt (-75 = .)
recode s10_q3f_roscaloanintamt (-30 = .)

//s10_q3d_roscaloanamt s10_q3f_roscaloanintamt s10_q3f_roscaloanunit s10_q3f_roscaloanintunit s10_q4a_bankloanamt s10_q4c_bankloanintamt s10_q4c_bankloanunit s10_q4c_bankloanintunit
//s10_q5a_shylockamt s10_q5c_shylockintamt s10_q5c_shylockunit s10_q5c_shylockintunit s10_q6a_mshwariamt s10_q6c_mshwariintamount s10_q6c_mshwariunit s10_q6c_mshwariintunit s10_q7b_hhloanamt s10_q7d_hhloanintamt s10_q7d_hhloanunit s10_q7d_hhloanintunit s10_q8b_amt s10_q8c_intamount s10_q8c_unit s10_q8c_intunit


foreach bub in rosca bank shylock mshwari hhloan hhlend {
*** rosca loans ***
if "`bub'" == "rosca" {
    loc intamtpre   "s10_q3f_roscaloan"
    loc tunitpre    "`intamtpre'"
    loc iunitpre    "`intamtpre'"
    loc lamtpre     "s10_q3d_roscaloan"
}
*** bank loans ***
if "`bub'" == "bank" {
    loc intamtpre "s10_q4c_bankloan"
    loc tunitpre "s10_q4c_bankloan"
    loc iunitpre = "s10_q4c_bankloan"
    loc lamtpre "s10_q4a_bankloan"
}
if "`bub'" == "shylock" {
    loc intamtpre       "s10_q5c_shylock"
    loc tunitpre        "`intamtpre'"
    loc iunitpre        "`intamtpre'"
    loc lamtpre         "s10_q5a_shylock"
}
if "`bub'" == "mshwari" {
    loc intamtpre       "s10_q6c_`bub'"
    loc tunitpre        "`intamtpre'"
    loc iunitpre        "`intamtpre'"
    loc lamtpre         "s10_q6a_`bub'"
}
if "`bub'" == "hhloan" {
    loc intamtpre       "s10_q7d_`bub'"
    loc tunitpre        "`intamtpre'"
    loc iunitpre        "`intamtpre'"
    loc lamtpre         "s10_q7b_hhloan"
}
if "`bub'" == "hhlend" {
    loc intamtpre       "s10_q8c_"
    loc tunitpre        "`intamtpre'"
    loc iunitpre        "`intamtpre'"
    loc lamtpre         "s10_q8b_"
}


tab `intamtpre'intamt
recode `intamtpre'intamt  (-99 0.99 = .) // most likely supposed to be -99, don't know


* case 0: no interest charged. Base this on combination of int amt and time questions, then recode these and go to the rest
tab1 `iunitpre'intunit `tunitpre'unit if `intamtpre'intamt == -88 | `intamtpre'intamt == 0

tab `intamtpre'intamt if `tunitpre'unit == 99 | `iunitpre'intunit == 99
// if they state that interest was charged, not going to consider as zero interest

replace `tunitpre'unit = . if `intamtpre'intamt > 0 & `intamtpre'intamt < . & (`tunitpre'unit == 99 | `iunitpre'intunit == 99)
replace `iunitpre'intunit = . if `intamtpre'intamt > 0 & `intamtpre'intamt < . & (`tunitpre'unit == 99 | `iunitpre'intunit == 99)

gen `bub'_intrate = 0 if `intamtpre'intamt == -88  // zero values of intamt should still be okay

foreach var of varlist `tunitpre'unit `iunitpre'intunit {
    replace `var' = 99 if `intamtpre'intamt == -88 // this should exclude these obs from the other calculations
}

** if intunit 99 and amount == 0, setting to zero
replace `bub'_intrate = 0 if `intamtpre'intamt == 0 & `iunitpre'intunit == 99

* case 1: reported as rate / percent
tab `iunitpre'intunit // how do we want to treat no interest? zero?
tab `intamtpre'intamt if `iunitpre'intunit == 2
list `lamtpre'amt `intamtpre'intamt `iunitpre'intunit if `intamtpre'intamt >=50 & `iunitpre'intunit == 2 & ~mi(`intamtpre'intamt)
* these look very strongly like amounts -- MW recoding
replace `iunitpre'intunit = 1 if `intamtpre'intamt >= 50 & ~mi(`intamtpre'intamt) // there will still be some 100s

* for values reported in rates, setting to the rate
* adjusting to monthly for those not reported at that frequency
tab `tunitpre'unit if `iunitpre'intunit == 2

replace `bub'_intrate = (1 + `intamtpre'intamt / 100)^30 - 1 if `iunitpre'intunit == 2 &  `tunitpre'unit == 1 // converting daily values
replace `bub'_intrate = (1 +`intamtpre'intamt / 100)^4 - 1 if `iunitpre'intunit == 2 & `tunitpre'unit == 2 // converting weekly values
replace `bub'_intrate = `intamtpre'intamt / 100 if `iunitpre'intunit == 2 & `tunitpre'unit == 3 // monthly values -- no adjustment
replace `bub'_intrate = (1 +`intamtpre'intamt / 100)^(1/12) - 1 if `iunitpre'intunit == 2 & `tunitpre'unit == 4 // converting yearly values


* Case 2: Amounts reported in Kenya shillings
tab `tunitpre'unit if `iunitpre'intunit == 1 // amounts that should be changed per line

replace `bub'_intrate = (1 + (`intamtpre'intamt / `lamtpre'amt))^30 - 1 if `iunitpre'intunit == 1 & `tunitpre'unit == 1 // daily rate
replace `bub'_intrate = (1 + (`intamtpre'intamt / `lamtpre'amt))^4 - 1 if `iunitpre'intunit == 1 & `tunitpre'unit == 2 // weekly rate
replace `bub'_intrate = (`intamtpre'intamt / `lamtpre'amt) if `iunitpre'intunit == 1 & `tunitpre'unit == 3 // monthly rate
replace `bub'_intrate = (1 + (`intamtpre'intamt / `lamtpre'amt))^(1/12) - 1 if `iunitpre'intunit == 1 & `tunitpre'unit == 4 // annual rate to monthly

** how many missing values remain now?
count if `intamtpre'intamt != . & `bub'_intrate == .
tab1 `intamtpre'* if `intamtpre'intamt != . & `bub'_intrate == .

summ `bub'_intrate
recode `bub'_intrate (`maxrate' / max = .)
summ `bub'_intrate

}
// end loop through types of loans & lending


summ *_intrate


/*** FINAL HOUSEHOLD NUMBERS ***/
** share of households with any borrowing **
gen any_borrow = (totval_loanstaken > 0) if ~mi(totval_loanstaken)
tab any_borrow, m

** household loan-value weighted interest rate **
* generating total borrowing for which we have interest rates *
foreach bub in rosca bank shylock mshwari hhloan {
    gen temp_`bub'borr = `bub'_loanamt if ~mi(`bub'_intrate)
}
egen temp_totborr = rowtotal(temp_*borr), m

* tricky to get this right with missing values *
gen lw_intrate = 0
foreach bub in rosca bank shylock mshwari hhloan {
    replace lw_intrate = lw_intrate + (`bub'_loanamt / temp_totborr) * `bub'_intrate if `bub'_intrate != .
}

replace lw_intrate = . if temp_totborr == .

summ *_intrate


** higher than expected # of missing values -- from flat rate? **
loc i = 4
foreach bub in bankloan shylock mshwari  {
    gen `bub'_flatrate = s10_q`i'c_`bub'intunit == 88 if ~mi( s10_q`i'c_`bub'intunit)
    loc ++i
}
gen rosca_flatrate = s10_q3f_roscaloanunit == 88 if ~mi(s10_q3f_roscaloanunit)
gen hhloan_flatrate = s10_q7d_hhloanintamt == 88 if ~mi(s10_q7d_hhloanintamt )
gen hhlend_flatrate = s10_q8c_intunit == 88 if ~mi( s10_q8c_intunit)

egen num_types = rownonmiss(*_flatrate)
egen num_flat = rowtotal(*_flatrate), m

gen share_flat = num_flat / num_types
tab share_flat

*** indicators for any borrowing ***
gen any_roscaloan   = s10_q3c_roscaloan == 1 if ~mi(s10_q3c_roscaloan)
gen any_bankloan    = s10_q4_bankloan   == 1 if ~mi(s10_q4_bankloan)
gen any_shylock     = s10_q5_shylock    == 1 if ~mi(s10_q5_shylock)
gen any_mshwari     =  s10_q6_mshwari   == 1 if ~mi(s10_q6_mshwari)
gen any_hhloan      = s10_q7_hhloan     == 1 if ~mi(s10_q7_hhloan)
gen any_hhlend      = s10_q8_lentmoney  == 1 if ~mi(s10_q8_lentmoney)


*** saving dataset ***
keep s1_hhid_key any_* share_* *_intrate hhloan_*
save "$da/intermediate/GE_HH-EL_loanrates.dta", replace
project, creates("$da/intermediate/GE_HH-EL_loanrates.dta")
