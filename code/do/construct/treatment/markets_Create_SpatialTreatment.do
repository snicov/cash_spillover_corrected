
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

set varabbrev on
// end preliminaries

** Get actual amounts going to market buffers **
************************************************
project, original("$dr/MarketBuffers_TreatmentVars_PUBLIC.dta")
use "$dr/MarketBuffers_TreatmentVars_PUBLIC.dta", clear


** merge in population numbers **
*********************************
project, uses("$da/market_radiipop_long.dta") preserve
merge 1:1 market_code distance using "$da/market_radiipop_long.dta"
drop _merge // all merge

foreach v of var amount_* n_* {
	replace `v' = `v'/p_total
}

keep market_code distance amount_* n_* p_total p_ge p_ge_treat p_ge_eligible p_ge_eligible_treat
order market_code distance p_total p_ge p_ge_treat p_ge_eligible p_ge_eligible_treat n_token_* n_LS1_* n_LS2* n_total* amount_token* amount_LS1_* amount_LS2* amount_total_KES_*

reshape long n_token_ n_LS1_ n_LS2_ n_total_ amount_token_KES_ amount_LS1_KES_ amount_LS2_KES_ amount_total_KES_, i(market_code distance) j(month) string
rename *_ *

** Clean up and Save **
***********************
gen year = substr(month,1,4)
gen month1 = substr(month,6,2)
gen month2 = "jan" if month1 == "01"
replace month2 = "feb" if month1 == "02"
replace month2 = "mar" if month1 == "03"
replace month2 = "apr" if month1 == "04"
replace month2 = "may" if month1 == "05"
replace month2 = "jun" if month1 == "06"
replace month2 = "jul" if month1 == "07"
replace month2 = "aug" if month1 == "08"
replace month2 = "sep" if month1 == "09"
replace month2 = "oct" if month1 == "10"
replace month2 = "nov" if month1 == "11"
replace month2 = "dec" if month1 == "12"
egen month3 = concat(month2 year)

gen month4 = monthly(month3, "MY")
format month4 %tm

drop month year month1 month2 month3
rename month4 month

order market_code distance month

label var p_total "Total number of persons living in radius band"
label var p_ge "Total number of persons living in GE villages in radius band"
label var p_ge_treat "Total number of persons living in GE treatment villages in radius band"
label var p_ge_eligible "Total number of eligible persons living in GE villages in radius band"
label var p_ge_eligible_treat "Total number of eligible persons living in GE villages treatment in radius band"
label var n_token "Number of tokens transfered per person in radius band"
label var n_LS1 "Number of 1st lump sum transfers per person in radius band"
label var n_LS2 "Number of 2nd lump sum transfers per person in radius band"
label var n_total "Total number of transfers per person in radius band"

label var amount_token "Amount (in KES) of tokens transfered per person in radius band"
label var amount_LS1 "Amount (in KES)  of 1st lump sum transfers per person in radius band"
label var amount_LS2 "Amount (in KES)  of 2nd lump sum transfers per person in radius band"
label var amount_total "Total amount (in KES) transferred per person in radius band"

save "$da/market_actualtreat_long_FINAL.dta", replace
project, creates("$da/market_actualtreat_long_FINAL.dta") preserve

** reshape to wide **
foreach v of var p_total p_ge p_ge_treat p_ge_eligible p_ge_eligible_treat n_token n_LS1 n_LS2 n_total amount_token_KES amount_LS1_KES amount_LS2_KES amount_total_KES {
	rename `v' `v'_
}

gen dist = string(distance-2) + "to" + string(distance) + "km"
replace dist = "0" + substr(dist,1,3) + "0" + substr(dist,4,3) if length(dist) == 6
replace dist = "0" + substr(dist,1,3) + substr(dist,4,4) if length(dist) == 7
drop distance

reshape wide p_total_ p_ge_ p_ge_treat_ p_ge_eligible_ p_ge_eligible_treat_ n_token_ n_LS1_ n_LS2_ n_total_ amount_token_KES_ amount_LS1_KES_ amount_LS2_KES_ amount_total_KES_, i(market_code month) j(dist) string
order p_total_??to* p_ge_??to* p_ge_treat_??to* p_ge_eligible_??to* p_ge_eligible_treat_??to* n_token_??to* n_LS1* n_LS2* n_total* amount_token* amount_LS1* amount_LS2* amount_total_KES_??to*, last

foreach dist in 00to02km 02to04km 04to06km 06to08km 08to10km 10to12km 12to14km 14to16km 16to18km 18to20km {
	label var p_total_`dist' "Total number of people living in `dist' radius band"
	label var p_ge_`dist' "Total number of people living in GE villages in `dist' radius band"
	label var p_ge_treat_`dist' "Total number of people living in treated GE villages in `dist' radius band"
	label var p_ge_eligible_`dist' "Total number of eligible people living in GE villages in `dist' radius band"
	label var p_ge_eligible_treat_`dist' "Total number of treated eligible people living in GE villages in `dist' radius band"

	foreach v in total token LS1 LS2 {
		label var n_`v'_`dist' "Number of `v' transfers per person going to `dist' radius band"
		label var amount_`v'_KES_`dist' "Amount of `v' transfers (KES per person) going to `dist' radius band"
	}
}

clonevar market_id = market_code

save "$da/market_actualtreat_wide_FINAL.dta", replace
project, creates("$da/market_actualtreat_wide_FINAL.dta")

set varabbrev off
