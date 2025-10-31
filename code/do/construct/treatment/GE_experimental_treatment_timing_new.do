
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

global token_amt_KES = 7000
global LS_amt_KES = 40000

* Local for cutoff threshold of starting transfers to village
local cutoff = 0.10

*==============================================================================*
*==========================LOAD GE TREATMENT STATUS============================*
*==============================================================================*
project, original("$dr/GE_Treat_Status_Master.dta")
use "$dr/GE_Treat_Status_Master.dta", clear

/** Dropping villages not part of final sample **/
** TK adapt this code
drop if village == "SEGA NORTH EAST RURAL" | village == "URANGA TOWN" | village == "NYANDORERA TOWN 1" | village == "NYANDORERA TOWN 2" | village == "TINGWANGI TOWN"

* Updating treatment order to exclude dropped villages
gen ge_village_order_incldropped = ge_village_order
sort ge_village_order
replace ge_village_order = _n

codebook ge_village_order

*==============================================================================*
*====================Construct experimental treatment timing===================*
*==============================================================================*

* Merging with long version of actual GD transfer data
project, original("$dr/Transfers_VillageLevel_Temporal_PUBLIC.dta") preserve
merge 1:n village_code using "$dr/Transfers_VillageLevel_Temporal_PUBLIC.dta", gen(_mergelong)

* Code for satlevel
egen sl = group(satlevel_name)
bys village_code: gen vI = (_n==1) // indicator for first village observation - used for village-level summary stats
sort village_code month
format village_code %14.0g

* generating SL start and end dates - for now, control villages have missing values for tokens
bys village_code: gen tokens_sent = (n_token>0) if n_token != . // indicator for any tokens sent that month
by village_code: gen cum_tokens = sum(n_token) // cumulative tokens sent
by village_code: egen tokens_total = sum(n_token) // total number of tokens sent
gen token_start_all = .
gen token_end_all = .
gen token_start_cutoff = .

* generating id for treatment villages - want to loop through only these to determine start/end dates
egen vid = group(village_code) if treat==1

forval i=1/328 {
	qui{
	summ month if tokens_sent > 0 & vid == `i' & tokens_sent != .
	replace token_start_all = r(min) if vid == `i' //token start month
	replace token_end_all = r(max) if vid == `i' //token end month
	summ month if cum_tokens>=tokens_total*`cutoff' & vid == `i'
	replace token_start_cutoff = r(min) if vid == `i' //first month in which at least 10 percent of the total token transfers were sent
	}
}
format token_start_all token_start_cutoff %tm


* Comparing overall start to cutoff start
list vid token_start* if vI & treat==1
count if token_start_all != token_start_cutoff  & vI & treat
local frac=r(N)/328
di "Fraction where cutoff is different from overall: `frac'"


* Examine number of months between beginning and end of token transfers
gen token_diff_all = token_end_all - token_start_all + 1
gen token_diff_cutoff = token_end_all - token_start_cutoff + 1

tab1 token_diff_* if vI

gen actual_tokens = n_token
bys village_code: egen total_tokens = total(n_token)


/* Looking in more depth at distribution of tokens */
preserve
local nmon = 13
local nmon_1 = `nmon'-1


*For tokens
forval i=0/`nmon_1' {
	* Overall version: number/percent of tokens sent in each month, starting with first month tokens sent
	gen num_tokens_actual`i' = actual_tokens if month == (token_start_all + `i')
	gen pct_tokens_actual`i' = num_tokens_actual`i' / total_tokens

	* Cutoff version: number/percent of tokens sent in each month, starting with first month of cutoff
	gen num_tokens_actual`i'_c = actual_tokens if month == (token_start_cutoff + `i')
	gen pct_tokens_actual`i'_c = num_tokens_actual`i'_c / total_tokens
}

gen num_tokens_actualpre_c_tmp = actual_tokens if month < token_start_cutoff & token_start_cutoff != . // number of tokens before token start cutoff
bys village_code: egen num_tokens_actualpre_c = total(num_tokens_actualpre_c_tmp) // in each village, total number of tokens before token start cutoff
drop num_tokens_actualpre_c_tmp
gen pct_tokens_actualpre_c = num_tokens_actualpre_c / total_tokens //in each village, percent of tokens before token start cutoff


* Remainder of tokens assigned to month nmon
collapse num_tokens_actual* pct_tokens_actual* total_tokens, by(village_code)

* List desired variables manually
local nt_list1 num_tokens_actual0 num_tokens_actual1 num_tokens_actual2 num_tokens_actual3 num_tokens_actual4 num_tokens_actual5 num_tokens_actual6 num_tokens_actual7 num_tokens_actual8 num_tokens_actual9 num_tokens_actual10 num_tokens_actual11 num_tokens_actual12 // num_tokens_actual13 num_tokens_actual14 num_tokens_actual15 num_tokens_actual16 num_tokens_actual17
local nt_list1_c num_tokens_actual0_c num_tokens_actual1_c num_tokens_actual2_c num_tokens_actual3_c num_tokens_actual4_c num_tokens_actual5_c num_tokens_actual6_c num_tokens_actual7_c num_tokens_actual8_c num_tokens_actual9_c num_tokens_actual10_c num_tokens_actual11_c num_tokens_actual12_c // num_tokens_actual13_c num_tokens_actual14_c num_tokens_actual15_c num_tokens_actual16_c num_tokens_actual17_c

egen num_tokens_actual1_`nmon_1' = rowtotal(`nt_list1'), missing // number of tokens sent in the month range specified by the previous local command
egen num_tokens_actual1_`nmon_1'_c = rowtotal(num_tokens_actualpre_c `nt_list1_c'), missing // number of tokens sent over specified month ranges
gen num_tokens_actual`nmon' = total_tokens - num_tokens_actual1_`nmon_1' // difference in total tokens and tokens sent over specified month range
label var num_tokens_actual`nmon' "Number of tokens in month `nmon' and later"
gen num_tokens_actual`nmon'_c = total_tokens - num_tokens_actual1_`nmon_1'_c // difference in total tokens and tokens sent over specified month range with cutoff
label var num_tokens_actual`nmon'_c "Number of tokens in month `nmon' and later using cutoff"
gen pct_tokens_actual`nmon'= num_tokens_actual`nmon' / total_tokens
label var pct_tokens_actual`nmon' "Share of tokens in month `nmon' and later"
gen pct_tokens_actual`nmon'_c = num_tokens_actual`nmon'_c / total_tokens
label var pct_tokens_actual`nmon'_c "Share of tokens in month `nmon' and later using cutoff"

drop *actual1_`nmon_1'*
order num_tokens_actual* pct_tokens_actual*, last sequential
summ pct_tokens_actual*


* Label variables
forval i=0/`nmon_1' {
	label var num_tokens_actual`i' "Number of tokens in month `i'"
	label var pct_tokens_actual`i' "Share of tokens in month `i'"
	label var num_tokens_actual`i'_c "Number of tokens in month `i' using cutoff"
	label var pct_tokens_actual`i'_c "Share of tokens in month `i' using cutoff"
}
label var pct_tokens_actualpre_c "Share of tokens in months before cutoff"
label var num_tokens_actualpre_c "Number of tokens in months before cutoff"

tempfile coll1
save `coll1'

restore

merge n:1 village_code using `coll1'
drop _merge

summ pct_tokens_actual*_c if treat & vI
summ pct_tokens_actual? pct_tokens_actual?? if treat & vI

bys subcounty: summ pct_tokens_actual*_c if treat & vI
by subcounty: summ pct_tokens_actual? pct_tokens_actual?? if treat & vI




***********************************
*** EXPERIMENTAL STARTING MONTH ***
***********************************

/* START MONTH 1: EVENLY SPACING OVER ALL VILLAGES, now taking holidays into account */
gen exp_start_1 = .
local pace = ceil(653/11.5) // not counting half of January - no transfers due to Christmas

local startm = tm(2014m9) // First transfers went out Sep 2014
forval i=0/3 {
	di "Start: `startm' I: `i' Pace: `pace'"
	replace exp_start_1 = `startm'+`i' if ge_village_order > `i'*`pace' & ge_village_order <= (`i'+1)*`pace'
}

replace exp_start_1 = tm(2015m1) if ge_village_order > 4*`pace' & ge_village_order <= 4.5*`pace'
local j=0.5
foreach i in 4.5 5.5 6.5 7.5 8.5 9.5 10.5 {
	replace exp_start_1 = `startm'+`i'+`j' if ge_village_order > `i'*`pace' & ge_village_order <= (`i'+1)*`pace'
}

format exp_start_1 %tm
desc exp_start_1
tab exp_start_1

tab exp_start_1, m

tab exp_start_1 if vI, m

/* START MONTH 2: EVENLY SPACING OVER SUBCOUNTIES */
local num_vill_SIAYA = 203
local num_vill_UGUNJA = 166
local num_vill_UKWALA = 284

local siaya_speed = 51 // 203 villages from September to December (4 months)
local ugunja_speed = 66 // 166 villages from February to 1/2 of April (2.5 months)
local ukwala_speed = 63 // 284 villages from 1/2 April to August (4.5 months)

local num_months_siaya = 4
local num_vill_siaya = 203

local num_months_ugunja = 4
local num_vill_ugunja = 166

gen month_start_num = .

* Assigning Siaya
gen exp_start_2 = .
local startm = tm(2014m9)
forval i=0/3 {
	di "Start: `startm' I: `i' Pace: `siaya_speed'"
	replace exp_start_2 = `startm' + `i' if subcounty == "SIAYA" & ge_village_order > (`i'*`siaya_speed') & ge_village_order <= (`i'+1)*`siaya_speed'
}
tab exp_start_2 if subcounty == "SIAYA", m

*Assigning Ugunja
foreach k of numlist 6 7 8{
	local j=`k' - `num_months_siaya' - 2 // subtracting 2 b/c no transfers in January
	local i=`k' - `num_months_siaya' - 1 //
	replace month_start_num = floor(`k') if subcounty == "UGUNJA" & ge_village_order > (`j'*`ugunja_speed' + `num_vill_siaya') & ge_village_order <= (`i'*`ugunja_speed' + `num_vill_siaya')
}
tab month_start_num if subcounty == "UGUNJA" & vI, m

*Assigning Ukwala
foreach k of numlist 8 9 10 11 12 {
	local j=`k' - `num_months_siaya' - `num_months_ugunja' - 1
	local i=`k' - `num_months_siaya' - `num_months_ugunja'
	replace month_start_num = floor(`k') if subcounty == "UKWALA" & ge_village_order > (`j'*`ukwala_speed' + `num_vill_siaya' + `num_vill_ugunja' + 32) & ge_village_order <= (`i'*`ukwala_speed' + `num_vill_siaya' + `num_vill_ugunja' + 32)
}
tab month_start_num if subcounty == "UKWALA" & vI, m
tab month_start_num, m

gen month_start = mofd(td(15aug2014)) // month before sep, as adding in one month
replace exp_start_2 = month_start + month_start_num if exp_start_2 == .
drop month_start


format exp_start_2 %tm
tab exp_start_2


/** SHARE OF HOUSEHOLDS IN STARTING MONTH **/

/* LOCALS: DISTRIBUTION OF HOUSEHOLD SHARES */
preserve
project, uses("$da/GE_HH-Census_Analysis_HHLevel.dta") preserve
use "$da/GE_HH-Census_Analysis_HHLevel.dta", clear
collapse (sum) total_elig=eligible, by(village_code)
** DE -- Checked this matches: GE_Analysis_VillageLevel_2017-07-17.dta" TK **
tempfile temp
save `temp'
restore

merge n:1 village_code using `temp'
drop _merge

/* defining monthly shares - calculations from below */

* Replace missing number and percent observations with zero
forval i = 0/`nmon' {
		replace num_tokens_actual`i'_c = 0 if num_tokens_actual`i'_c == . & num_tokens_actual0_c != .
		replace num_tokens_actual`i' = 0 if num_tokens_actual`i' == . & num_tokens_actual0 != .
		replace pct_tokens_actual`i'_c = 0 if pct_tokens_actual`i'_c == . & pct_tokens_actual0_c != .
		replace pct_tokens_actual`i' = 0 if pct_tokens_actual`i' == . & pct_tokens_actual0 != .
}


* Replace number of tokens in pre with missing if first month is missing
replace num_tokens_actualpre_c = . if num_tokens_actual1_c == .


/* OVERALL AVERAGE */
forval i=0/`nmon' {
		summ pct_tokens_actual`i'
		local m`i'_tokens_overall = r(mean)
}


/* OVERALL AVERAGE WITH CUTOFF */
forval i=0/`nmon' {
		summ pct_tokens_actual`i'_c
		local m`i'_tokens_overall_c = r(mean)
}


**********************************************
*** COMBINING INTO EXPERIMENTAL TREATMENTS ***
**********************************************


/* Measure 1 */
***************

** number of transfers **
gen exp_n_token_1 = 0
gen exp_n_token_c_1 = 0

forval i = 0/`nmon_1' {
	replace exp_n_token_1 = total_elig*`m`i'_tokens_overall' if month == (exp_start_1 + `i')
	replace exp_n_token_c_1 = total_elig*`m`i'_tokens_overall_c' if month == (exp_start_1 + `i')
}


/* Generating amounts */
sort village_code month
gen exp_n_LS1_1 = L2.exp_n_token_1
replace exp_n_LS1_1 = 0 if exp_n_LS1_1 == .
gen exp_n_LS2_1 = L8.exp_n_token_1
replace exp_n_LS2_1 = 0 if exp_n_LS2_1 == .
gen exp_amount_KES_1 = exp_n_token_1*$token_amt_KES + (exp_n_LS1_1+exp_n_LS2_1)*$LS_amt_KES
gen exp_amount_USD_1 = exp_amount_KES_1/$USDKES

gen exp_n_LS1_c_1 = L2.exp_n_token_c_1
replace exp_n_LS1_c_1 = 0 if exp_n_LS1_c_1 == .
gen exp_n_LS2_c_1 = L8.exp_n_token_c_1
replace exp_n_LS2_c_1 = 0 if exp_n_LS2_c_1 == .
gen exp_amount_c_KES_1 = exp_n_token_c_1*$token_amt_KES + (exp_n_LS1_c_1+exp_n_LS2_c_1)*$LS_amt_KES
gen exp_amount_c_USD_1 = exp_amount_c_KES_1/$USDKES


* All (ie including control) vs treat only
gen exp_n_tokenALL_1 = exp_n_token_1
replace exp_n_token_1 = . if treat == 0
gen exp_amountALL_KES_1= exp_amount_KES_1
replace exp_amount_KES_1 = . if treat == 0
gen exp_amountALL_USD_1= exp_amount_USD_1
replace exp_amount_USD_1 = . if treat == 0

label var exp_n_tokenALL_1 "Predicted no. of tokens sent (TREAT and CONTROL) - 1st method"
label var exp_n_token_1 "Predicted no. of tokens sent (TREAT) - 1st method"
label var exp_amountALL_KES_1 "Predicted amount of cash (KES) sent (TREAT and CONTROL) - 1st method"
label var exp_amount_KES_1 "Predicted amount of cash (KES) sent (TREAT) - 1st method"
label var exp_amountALL_USD_1 "Predicted amount of cash (USD) sent (TREAT and CONTROL) - 1st method"
label var exp_amount_USD_1 "Predicted amount of cash (USD) sent (TREAT) - 1st method"


gen exp_n_tokenALL_c_1 = exp_n_token_c_1
replace exp_n_token_c_1 = . if treat == 0
gen exp_amountALL_c_KES_1= exp_amount_c_KES_1
replace exp_amount_c_KES_1 = . if treat == 0
gen exp_amountALL_c_USD_1= exp_amount_c_USD_1
replace exp_amount_c_USD_1 = . if treat == 0

label var exp_n_tokenALL_c_1 "Predicted no. of tokens sent (TREAT and CONTROL) - 1st method, 10% cutoff"
label var exp_n_token_c_1 "Predicted no. of tokens sent (TREAT) - 1st method, 10% cutoff"
label var exp_amountALL_c_KES_1 "Predicted amount of cash (KES) sent (TREAT and CONTROL) - 1st method, 10% cutoff"
label var exp_amount_c_KES_1 "Predicted amount of cash (KES) sent (TREAT) - 1st method, 10% cutoff"
label var exp_amountALL_c_USD_1 "Predicted amount of cash (USD) sent (TREAT and CONTROL) - 1st method, 10% cutoff"
label var exp_amount_c_USD_1 "Predicted amount of cash (USD) sent (TREAT) - 1st method, 10% cutoff"


/* Measure 2 */
***************

** number of transfers **
gen exp_n_token_2 = 0
gen exp_n_token_c_2 = 0

forval i = 0/`nmon_1' {
	replace exp_n_token_2 = total_elig*`m`i'_tokens_overall' if month == (exp_start_2 + `i')
	replace exp_n_token_c_2 = total_elig*`m`i'_tokens_overall_c' if month == (exp_start_2 + `i')
}

/* Generating amounts */
sort village_code month
gen exp_n_LS1_2 = L2.exp_n_token_2
replace exp_n_LS1_2 = 0 if exp_n_LS1_2 == .
gen exp_n_LS2_2 = L8.exp_n_token_2
replace exp_n_LS2_2 = 0 if exp_n_LS2_2 == .
gen exp_amount_KES_2 = exp_n_token_2*$token_amt_KES + (exp_n_LS1_2+exp_n_LS2_2)*$LS_amt_KES
gen exp_amount_USD_2 = exp_amount_KES_2/$USDKES

gen exp_n_LS1_c_2 = L2.exp_n_token_c_2
replace exp_n_LS1_c_2 = 0 if exp_n_LS1_c_2 == .
gen exp_n_LS2_c_2 = L8.exp_n_token_c_2
replace exp_n_LS2_c_2 = 0 if exp_n_LS2_c_2 == .
gen exp_amount_c_KES_2 = exp_n_token_c_2*$token_amt_KES + (exp_n_LS1_c_2+exp_n_LS2_c_2)*$LS_amt_KES
gen exp_amount_c_USD_2 = exp_amount_c_KES_2/$USDKES


* All (ie including control) vs treat only
gen exp_n_tokenALL_2 = exp_n_token_2
replace exp_n_token_2 = . if treat == 0
gen exp_amountALL_KES_2= exp_amount_KES_2
replace exp_amount_KES_2 = . if treat == 0
gen exp_amountALL_USD_2= exp_amount_USD_2
replace exp_amount_USD_2 = . if treat == 0

label var exp_n_tokenALL_2 "Predicted no. of tokens sent (TREAT and CONTROL) - 2nd method"
label var exp_n_token_2 "Predicted no. of tokens sent (TREAT) - 2nd method"
label var exp_amountALL_KES_2 "Predicted amount of cash (KES) sent (TREAT and CONTROL) - 2nd method"
label var exp_amount_KES_2 "Predicted amount of cash (KES) sent (TREAT) - 2nd method"
label var exp_amountALL_USD_2 "Predicted amount of cash (USD) sent (TREAT and CONTROL) - 2nd method"
label var exp_amount_USD_2 "Predicted amount of cash (USD) sent (TREAT) - 2nd method"


gen exp_n_tokenALL_c_2 = exp_n_token_c_2
replace exp_n_token_c_2 = . if treat == 0
gen exp_amountALL_c_KES_2= exp_amount_c_KES_2
replace exp_amount_c_KES_2 = . if treat == 0
gen exp_amountALL_c_USD_2= exp_amount_c_USD_2
replace exp_amount_c_USD_2 = . if treat == 0

label var exp_n_tokenALL_c_2 "Predicted no. of tokens sent (TREAT and CONTROL) - 2nd method, 10% cutoff"
label var exp_n_token_c_2 "Predicted no. of tokens sent (TREAT) - 2nd method, 10% cutoff"
label var exp_amountALL_c_KES_2 "Predicted amount of cash (KES) sent (TREAT and CONTROL) - 2nd method, 10% cutoff"
label var exp_amount_c_KES_2 "Predicted amount of cash (KES) sent (TREAT) - 2nd method, 10% cutoff"
label var exp_amountALL_c_USD_2 "Predicted amount of cash (USD) sent (TREAT and CONTROL) - 2nd method, 10% cutoff"
label var exp_amount_c_USD_2 "Predicted amount of cash (USD) sent (TREAT) - 2nd method, 10% cutoff"


** COMPARING ACTUAL AND EXPERIMENTAL TREATMENT **
** Nicer versions of this analysis created in midline/analysis/treatment **

** Correlations **
corr n_token n_token2 exp_n_token_1 exp_n_token_2 exp_n_token_c_1 exp_n_token_c_2
corr amount_total_KES exp_amount_KES_1 exp_amount_KES_2


** Cleaning and Saving **
*************************
keep location_code location_name sublocation_code sublocation_name village_code month hi_sat treat token_start_all token_start_cutoff n_trans n_token n_token2 n_LS1 n_LS2 n_split amount_total_KES amount_token_KES amount_LS1_KES amount_LS2_KES amount_total_USD amount_token_USD amount_LS1_USD amount_LS2_USD exp_start_1 exp_n_token_1 exp_n_token_c_1 exp_amount_KES_1 exp_amount_c_KES_1 exp_amount_USD_1 exp_amount_c_USD_1 exp_n_tokenALL_1 exp_n_tokenALL_c_1 exp_amountALL_KES_1 exp_amountALL_c_KES_1 exp_amountALL_USD_1 exp_amountALL_c_USD_1 exp_start_2 exp_n_token_2 exp_n_token_c_2 exp_amount_KES_2 exp_amount_c_KES_2 exp_amount_USD_2 exp_amount_c_USD_2 exp_n_tokenALL_2 exp_n_tokenALL_c_2 exp_amountALL_KES_2 exp_amountALL_c_KES_2 exp_amountALL_USD_2 exp_amountALL_c_USD_2
order location_code location_name sublocation_code sublocation_name village_code month hi_sat treat token_start_all token_start_cutoff n_trans n_token n_token2 n_LS1 n_LS2 n_split amount_total_KES amount_token_KES amount_LS1_KES amount_LS2_KES amount_total_USD amount_token_USD amount_LS1_USD amount_LS2_USD exp_start_1 exp_n_token_1 exp_n_token_c_1 exp_amount_KES_1 exp_amount_c_KES_1 exp_amount_USD_1 exp_amount_c_USD_1 exp_n_tokenALL_1 exp_n_tokenALL_c_1 exp_amountALL_KES_1 exp_amountALL_c_KES_1 exp_amountALL_USD_1 exp_amountALL_c_USD_1 exp_start_2 exp_n_token_2 exp_n_token_c_2 exp_amount_KES_2 exp_amount_c_KES_2 exp_amount_USD_2 exp_amount_c_USD_2 exp_n_tokenALL_2 exp_n_tokenALL_c_2 exp_amountALL_KES_2 exp_amountALL_c_KES_2 exp_amountALL_USD_2 exp_amountALL_c_USD_2

label var exp_start_1 "Experimental start date of the village using 1st approach in PAP"
label var exp_start_2 "Experimental start date of the village using 2nd approach in PAP"

rename token_start_all act_start
label var act_start "Actual start date of the village - all tokens"
rename token_start_cutoff act_start_c
label var act_start_c "Actual start date of the village - at least fraction `cutoff' of total tokens sent"
label var n_trans "Actual number of transfers by GD"
label var n_token "Actual no. of tokens transferred"
label var n_token2 "Actual no. of households receiving 1st ever transfer"
label var n_LS1 "Actual no. of households receiving 1st lump sum transfer"
label var n_LS2 "Actual no. of households receiving 2nd lump sum transfer"
label var n_split "Actual no. of transfers going to split households"

label var amount_total_KES "Actual amount of cash (in KES) sent - total"
label var amount_token_KES "Actual amount of cash (in KES) sent - token transfers"
label var amount_LS1_KES "Actual amount of cash (in KES) sent - 1st lump sum transfer"
label var amount_LS2_KES "Actual amount of cash (in KES) sent - 2ns lump sum transfer"

label var amount_total_USD "Actual amount of cash (in USD) sent - total"
label var amount_token_USD "Actual amount of cash (in USD) sent - token transfers"
label var amount_LS1_USD "Actual amount of cash (in USD) sent - 1st lump sum transfer"
label var amount_LS2_USD "Actual amount of cash (in USD) sent - 2ns lump sum transfer"


** This dataset contains the actual and experimental treatment amounts for each village
save "$dt/GE_experimental_timing_long_FINAL.dta", replace
project, creates("$dt/GE_experimental_timing_long_FINAL.dta") preserve

** Generate wide version **
tostring month, usedisp replace force
replace month = substr(month,1,5) + "0" + substr(month,6,1) if length(month) == 6

foreach v of var exp_n* exp_amount* {
	rename `v' `v'_
}

keep location_code location_name sublocation_code sublocation_name village_code month hi_sat treat exp*

reshape wide exp_n_token_1_ exp_n_token_c_1_ exp_amount_KES_1_ exp_amount_c_KES_1_ exp_amount_USD_1_ exp_amount_c_USD_1_ exp_n_tokenALL_1_ exp_n_tokenALL_c_1_ exp_amountALL_KES_1_ exp_amountALL_c_KES_1_ exp_amountALL_USD_1_ exp_amountALL_c_USD_1_ exp_n_token_2_ exp_n_token_c_2_ exp_amount_KES_2_ exp_amount_c_KES_2_ exp_amount_USD_2_ exp_amount_c_USD_2_ exp_n_tokenALL_2_ exp_n_tokenALL_c_2_ exp_amountALL_KES_2_ exp_amountALL_c_KES_2_ exp_amountALL_USD_2_ exp_amountALL_c_USD_2_, i(village_code) j(month) string

foreach v of var exp* {
	replace `v' = 0 if `v' == .
	rename `v' =
}

order _all, sequential
order location_code location_name sublocation_code sublocation_name village_code hi_sat treat exp_start_1 exp_n_token_1* exp_n_token_c_1* exp_amount_KES_1* exp_amount_c_KES_1* exp_amount_USD_1* exp_amount_c_USD_1* exp_n_tokenALL_1* exp_n_tokenALL_c_1* exp_amountALL_KES_1* exp_amountALL_c_KES_1* exp_amountALL_USD_1* exp_amountALL_c_USD_1* exp_start_2 exp_n_token_2* exp_n_token_c_2* exp_amount_KES_2* exp_amount_c_KES_2* exp_amount_USD_2* exp_amount_c_USD_2* exp_n_tokenALL_2* exp_n_tokenALL_c_2* exp_amountALL_KES_2* exp_amountALL_c_KES_2* exp_amountALL_USD_2* exp_amountALL_c_USD_2*

save "$dt/GE_experimental_timing_wide_FINAL.dta", replace
project, creates("$dt/GE_experimental_timing_wide_FINAL.dta")
