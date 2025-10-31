
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

*** get actual amounts going to village buffers ***
***************************************************

project, original("$dr/VillageBuffers_TreatmentVars_PUBLIC.dta")
use "$dr/VillageBuffers_TreatmentVars_PUBLIC.dta", clear


** merge in population numbers **
*********************************
project, uses("$da/village_radiipop_long.dta") preserve
merge 1:1 village_code distance using "$da/village_radiipop_long.dta"
foreach v of var amount_* {
	replace `v' = 0 if _merge == 2 // those are villages that did not receive transfers in that buffer
}
drop _merge

foreach v of var amount_total_KES_2* { // n_* {
	replace `v' = `v'/p_total
}

foreach v of var amount_total_KES_ov_* { // n_* {
	replace `v' = `v'/p_total_ov
}

foreach v of var amount_total_KES_ownvill_* { // n_* {
	replace `v' = `v'/p_total_ownvill
}

keep village_code distance amount_* n_* p_total p_ge p_ge_treat p_ge_eligible p_ge_eligible_treat p_total_ownvill p_ge_ownvill p_ge_eligible_ownvill p_total_ov p_ge_ov p_ge_treat_ov p_ge_eligible_ov p_ge_eligible_treat_ov
order village_code distance p_total p_ge p_ge_treat p_ge_eligible p_ge_eligible_treat p_total_ownvill p_ge_ownvill p_ge_eligible_ownvill p_total_ov p_ge_ov p_ge_treat_ov p_ge_eligible_ov p_ge_eligible_treat_ov n_token_* n_token_ownvill_* n_token_ov_* /* n_LS1_* n_LS2* n_total* amount_token* amount_LS1_* amount_LS2* */ amount_total_KES_* amount_total_KES_ownvill* amount_total_KES_ov_*

reshape long n_token_ n_token_ownvill_ n_token_ov_ amount_total_KES_ amount_total_KES_ownvill_ amount_total_KES_ov_, i(village_code distance) j(month) string
rename *_ *



** Collapse own village treatment data across all buffers **
************************************************************
bys village_code distance: egen a = sum(amount_total_KES_ownvill)
bys village_code distance: egen b = sum(p_total_ownvill)

bys distance: sum a //
bys distance: sum b //
drop a b

ren p_total_ownvill a
ren p_ge_eligible_ownvill b
ren amount_total_KES_ownvill c
ren n_token_ownvill d
drop *ownvill

bys village_code month: egen amount_total_KES_ownvill = sum(c)
bys village_code month: egen n_token_ownvill = sum(d)
bys village_code month: egen p_total_ownvill = sum(a)
bys village_code month: egen p_eligible_ownvill = sum(b)

drop a b c d

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

order village_code distance month p_total_ownvill p_eligible_ownvill

label var p_total "Total number of persons living in radius band"
label var p_ge "Total number of persons living in GE villages in radius band"
label var p_ge_treat "Total number of persons living in GE treatment villages in radius band"
label var p_ge_eligible "Total number of eligible persons living in GE villages in radius band"
label var p_ge_eligible_treat "Total number of eligible persons living in GE villages treatment in radius band"
label var p_total_ownvill "Total number of persons living in own village"
label var p_eligible_ownvill "Total number of eligible persons living own village"
label var p_total_ov "Total number of persons living in radius band (excl. own village)"
label var p_ge_ov "Total number of persons living in GE villages in radius band (excl. own village)"
label var p_ge_treat_ov "Total number of persons living in GE treatment villages in radius band (excl. own village)"
label var p_ge_eligible_ov "Total number of eligible persons living in GE villages in radius band (excl. own village)"
label var p_ge_eligible_treat_ov "Total number of eligible persons living in GE treatment villages in radius band (excl. own village)"

label var n_token "Number of tokens transfered in radius band"
label var n_token_ownvill "Number of tokens transfered in own village"
label var n_token_ov "Number of tokens transfered in radius band (excl. own village)"
label var amount_total_KES "Total amount (in KES) transferred per person in radius band"
label var amount_total_KES_ownvill "Total amount (in KES) transferred per person in own village"
label var amount_total_KES_ov "Total amount (in KES) transferred per person in radius band (excl. own village)"

save "$dt/village_actualtreat_long_nominal.dta", replace
project, creates("$dt/village_actualtreat_long_nominal.dta") preserve


** reshape to wide **
foreach v of var p_total p_ge p_ge_treat p_ge_eligible p_ge_eligible_treat p_total_ov p_ge_ov p_ge_treat_ov p_ge_eligible_ov p_ge_eligible_treat_ov n_token n_token_ov /*n_LS1 n_LS2 n_total amount_token_KES amount_LS1_KES amount_LS2_KES */ amount_total_KES amount_total_KES_ov {
	rename `v' `v'_
}

gen dist = string(distance-2) + "to" + string(distance) + "km"
replace dist = "0" + substr(dist,1,3) + "0" + substr(dist,4,3) if length(dist) == 6
replace dist = "0" + substr(dist,1,3) + substr(dist,4,4) if length(dist) == 7
drop distance

reshape wide p_total_ p_ge_ p_ge_treat_ p_ge_eligible_ p_ge_eligible_treat_ p_total_ov_ p_ge_ov_ p_ge_treat_ov_ p_ge_eligible_ov_ p_ge_eligible_treat_ov_ n_token_ n_token_ov_ /* n_LS1_ n_LS2_ n_total_ amount_token_KES_ amount_LS1_KES_ amount_LS2_KES_ */ amount_total_KES_ amount_total_KES_ov_, i(village_code month) j(dist) string
order p_total_??to* p_ge_??to* p_ge_treat_??to* p_ge_eligible_??to* p_ge_eligible_treat_??to* p_total_ov_??to* p_ge_ov_??to* p_ge_treat_ov_??to* p_ge_eligible_ov_??to* p_ge_eligible_treat_ov_??to* n_token_??to* n_token_ov* /* n_LS1* n_LS2* n_total* amount_token* amount_LS1* amount_LS2* */ amount_total_KES_??to* amount_total_KES_ov*, last

foreach dist in 00to02km 02to04km 04to06km 06to08km 08to10km 10to12km 12to14km 14to16km 16to18km 18to20km {
	label var p_total_`dist' "Total number of people living in `dist' radius band"
	label var p_ge_`dist' "Total number of people living in GE villages in `dist' radius band"
	label var p_ge_treat_`dist' "Total number of people living in treated GE villages in `dist' radius band"
	label var p_ge_eligible_`dist' "Total number of eligible people living in GE villages in `dist' radius band"
	label var p_ge_eligible_treat_`dist' "Total number of treated eligible people living in GE villages in `dist' radius band"

	label var p_total_ov_`dist' "Total number of people living in `dist' radius band (excl. own village)"
	label var p_ge_ov_`dist' "Total number of people living in treated GE villages in `dist' radius band (excl. own village)"
	label var p_ge_treat_ov_`dist' "Total number of people living in GE villages in `dist' radius band"
	label var p_ge_eligible_ov_`dist' "Total number of eligible people living in GE villages in `dist' radius band (excl. own village)"
	label var p_ge_eligible_treat_ov_`dist' "Total number of treated eligible people living in GE villages in `dist' radius band (excl. own village)"

	foreach v in total { //token LS1 LS2 {
		*label var n_`v'_`dist' "Number of `v' transfers per person going to `dist' radius band"
		label var amount_`v'_KES_`dist' "Amount of `v' transfers (KES per person) going to `dist' radius band"
		label var amount_`v'_KES_ov_`dist' "Amount of `v' transfers (KES per person) going to `dist' radius band (excl. own village)"
	}

	foreach v in token { //LS1 LS2 total {
		label var n_`v'_`dist' "Number of `v' transfers going to `dist' radius band"
		label var n_`v'_ov_`dist' "Number of `v' transfers going to `dist' radius band (excl. own village)"
	}
}

save "$dt/village_actualtreat_wide_nominal.dta", replace
project, creates("$dt/village_actualtreat_wide_nominal.dta")
