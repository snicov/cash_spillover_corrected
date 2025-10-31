
** This do file generates the actual treatment data for markets
** - based on the GPS location of GD households **
** - based on the population count created in markets_Create_Populationn **

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


***********************************
** I. ACTUAL TREATMENT VARIABLES **
***********************************

*** Long version ***
********************
project, uses("$dt/village_actualtreat_long_nominal.dta") preserve
use "$dt/village_actualtreat_long_nominal.dta", clear

** now deflated version **
ren month survey_mth
project, uses("$da/intermediate/pricedeflator.dta") preserve
merge m:1 village_code survey_mth using "$da/intermediate/pricedeflator.dta", keep(3) nogen keepusing(deflator*)
ren survey_mth month

** deflate treatment amounts **
foreach v of var amount_total_KES amount_total_KES_ov amount_total_KES_ownvill {
	gen `v'_r = `v' / deflator
	gen `v'_rsa = `v' / deflator_studyarea
}

label var deflator "Deflator to January 2015 prices in this village"
label var deflator_studyarea "Deflator to January 2015 avg. prices across entire study area"
label var amount_total_KES_r "Total amount (in Jan 2015 KES) transferred per person in radius band"
label var amount_total_KES_ownvill_r "Total amount (in Jan 2015 KES) transferred per person in own village"
label var amount_total_KES_ov_r "Total amount (in Ja n2015 KES) transferred per person in radius band (excl. own village)"

save "$da/village_actualtreat_long_FINAL.dta", replace
project, creates("$da/village_actualtreat_long_FINAL.dta")


*** Wide version ***
********************
project, uses("$dt/village_actualtreat_wide_nominal.dta")
use "$dt/village_actualtreat_wide_nominal.dta", clear

** now deflated version **
ren month survey_mth
project, uses("$da/intermediate/pricedeflator.dta") preserve
merge 1:1 village_code survey_mth using "$da/intermediate/pricedeflator.dta", keep(3) nogen keepusing(deflator*)
ren survey_mth month

** deflate treatment amounts **
foreach v of var amount_total_KES_ownvill amount_total_KES_??to??km amount_total_KES_ov_??to??km {
	gen `v'_r = `v' / deflator
	gen `v'_rsa = `v' / deflator_studyarea
}

label var deflator "Deflator to January 2015 prices in this village"
label var deflator_studyarea "Deflator to January 2015 avg. prices across entire study area"
label var amount_total_KES_ownvill_r "Total amount (in Jan 2015 KES) transferred per person in own village"
foreach dist in 00to02km 02to04km 04to06km 06to08km 08to10km 10to12km 12to14km 14to16km 16to18km 18to20km {

	foreach v in total { //token LS1 LS2 {
		label var amount_`v'_KES_`dist'_r "Amount of `v' transfers (2015 Jan KES per person) going to `dist' radius band"
		label var amount_`v'_KES_ov_`dist'_r "Amount of `v' transfers (2015 Jan KES per person) going to `dist' radius band (excl. own village)"
	}
}

order *_r, last sequential

save "$da/village_actualtreat_wide_FINAL.dta", replace
project, creates("$da/village_actualtreat_wide_FINAL.dta")


******************************************
** II. EXPERIMENTAL TREATMENT VARIABLES **
******************************************
/*
*** Long version ***
********************
project, uses("$dt/village_exptreat_long_nominal.dta") preserve
use "$dt/village_exptreat_long_nominal.dta", clear

** now deflated version **
ren month survey_mth
project, uses("$da/intermediate/pricedeflator.dta") preserve
merge m:1 village_code survey_mth using "$da/intermediate/pricedeflator.dta", keep(3) nogen keepusing(deflator*)
ren survey_mth month

** deflate treatment amounts **
foreach v of var exp_amt* {
	gen `v'_r = `v' / deflator
	gen `v'_rsa = `v' / deflator_studyarea
}

label var deflator "Deflator to January 2015 prices in this village"
label var deflator_studyarea "Deflator to January 2015 avg. prices across entire study area"
label var exp_amt_KES_1_r "Predicted amount (Jan 2015 KES) sent per person - 1st method"
label var exp_amt_KES_1_ownvill_r "Predicted amount (Jan 2015 KES) sent per person - 1st method, to own village"
label var exp_amt_KES_1_ov_r "Predicted amount (Jan 2015 KES) sent per person - 1st method, to other villages"
label var exp_amt_c_KES_1_r "Predicted amount (Jan 2015 KES) sent per person - 1st method, 10% cutoff"
label var exp_amt_c_KES_1_ownvill_r "Predicted amount (Jan 2015 KES) sent per person - 1st method, 10% cutoff, to own village"
label var exp_amt_c_KES_1_ov_r "Predicted amount (Jan 2015 KES) sent per person - 1st method, 10% cutoff, to other villages"
label var exp_amt_KES_2_r "Predicted amount (Jan 2015 KES) sent per person - 2nd method"
label var exp_amt_KES_2_ownvill_r "Predicted amount (Jan 2015 KES) sent per person - 2nd method, to own village"
label var exp_amt_KES_2_ov_r "Predicted amount (Jan 2015 KES) sent per person - 2nd method, to other villages"
label var exp_amt_c_KES_2_r "Predicted amount (Jan 2015 KES) sent per person - 2nd method, 10% cutoff"
label var exp_amt_c_KES_2_ownvill_r "Predicted amount (Jan 2015 KES) sent per person - 2nd method, 10% cutoff, to own village"
label var exp_amt_c_KES_2_ov_r "Predicted amount (Jan 2015 KES) sent per person - 2nd method, 10% cutoff, to other villages"

save "$da/village_exptreat_long_FINAL.dta", replace
project, creates("$da/village_exptreat_long_FINAL.dta")


*** Wide version ***
********************
project, uses("$dt/village_exptreat_wide_nominal.dta")
use "$dt/village_exptreat_wide_nominal.dta", replace

** now deflated version **
ren month survey_mth
project, uses("$da/intermediate/pricedeflator.dta") preserve
merge 1:1 village_code survey_mth using "$da/intermediate/pricedeflator.dta", keep(3) nogen keepusing(deflator*)
ren survey_mth month

** deflate treatment amounts **
foreach v of var exp_amt* {
	gen `v'_r = `v' / deflator
	gen `v'_rsa = `v' / deflator_studyarea
}

label var deflator "Deflator to January 2015 prices in this village"
label var deflator_studyarea "Deflator to January 2015 avg. prices across entire study area"
label var exp_amt_KES_1_ownvill_r "Predicted amount (Jan 2015 KES) sent per person - 1st method, to own village"
label var exp_amt_KES_2_ownvill_r "Predicted amount (Jan 2015 KES) sent per person - 2nd method, to own village"
label var exp_amt_c_KES_2_ownvill_r "Predicted amount (Jan 2015 KES) sent per person - 2nd method, 10% cutoff, to own village"
label var exp_amt_c_KES_1_ownvill_r "Predicted amount (Jan 2015 KES) sent per person - 1st method, 10% cutoff, to own village"

foreach dist in 00to02km 02to04km 04to06km 06to08km 08to10km 10to12km 12to14km 14to16km 16to18km 18to20km {

	label var exp_amt_KES_1_`dist'_r "Predicted amt (Jan 2015 KES per person) sent in `dist' buffer - 1st method"
	label var exp_amt_KES_1_ov_`dist'_r "Predicted amt (Jan 2015 KES per person) sent in `dist' buffer - 1st method, other villages"
	label var exp_amt_c_KES_1_`dist'_r "Predicted amt (Jan 2015 KES per person) sent in `dist' buffer - 1st method, 10% cutoff"
	label var exp_amt_c_KES_1_ov_`dist'_r "Predicted amt (Jan 2015 KES per person) sent in `dist' buffer - 1st method, 10% cutoff, other villages"
	label var exp_amt_KES_2_`dist'_r "Predicted amt (Jan 2015 KES per person) sent in `dist' buffer - 2nd method"
	label var exp_amt_KES_2_ov_`dist'_r "Predicted amt (Jan 2015 KES per person) sent in `dist' buffer - 2nd method, other villages"
	label var exp_amt_c_KES_2_`dist'_r "Predicted amt (Jan 2015 KES per person) sent in `dist' buffer - 2nd method, 10% cutoff"
	label var exp_amt_c_KES_2_ov_`dist'_r "Predicted amt (Jan 2015 KES per person) sent in `dist' buffer - 2nd method, 10% cutoff, other villages"
}

save "$da/village_exptreat_wide_FINAL.dta", replace
project, creates("$da/village_exptreat_wide_FINAL.dta")
*/
