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

set varabbrev on

project, original("$dr/ent_ML/combined_ent_all_with_int.dta") preserve
use "$dr/ent_ML/combined_ent_all_with_int.dta", clear

* drop enterprises that did not consent to insterview
* destring consent_R1,replace
* foreach var of varlist consent_R*{
* 	drop if `var'==2
* }

la var ent_id "Enterprise ID"

isid call_rank
assert _rc == 0

/* Category */
gen ent_catname = proper(primary_bizcat)
encode ent_catname, gen(ent_category)
la var ent_category "Enterprise category"

/* Revenue */
qui ds q4_revenuesmth_????????
local varlist=r(varlist)
foreach var in `varlist' {
	local month_rd=proper(substr("`var'",-8,8))
	destring `var', replace
	gen `var'_DKref = (`var' == -99 | `var' == -98 | `var' == -999 | `var' == 99 | `var' == 98) if `var' != .
	recode `var' (min/-1  98 99 = .), gen(ent_revenue_`month_rd')
	tab `var'_DKref
	la var ent_revenue_`month_rd' "Revenues `month_rd'"
}


foreach month in Aug15 Sep15 Oct15 Nov15 Dec15 Jan16 Feb16 Mar16 {
	gen ent_revenue_`month'=.
	la var ent_revenue_`month' "Revenues `month'"
	qui ds ent_revenue_`month'_??
	local varlist=r(varlist)
	foreach var in `varlist' {
	* I assert that there is no conflict between data from different round for same month
	replace ent_revenue_`month'=`var' if ent_revenue_`month'==.
	* drop `var'
	}
	tab ent_revenue_`month'
}


/* Rent */
qui ds q6_rent_????????
local varlist=r(varlist)
foreach var in `varlist' {
	local month_rd=proper(substr("`var'",-8,8))
	destring `var', replace
	gen `var'_DKref = (`var' == -99 | `var' == -98 | `var' == -999 | `var' == 98 | `var' == 99) if `var' != .
	recode `var' (min/-1 98 99 = .), gen(ent_rentpayment_`month_rd')
	* 777 = own premise
	replace ent_rentpayment_`month_rd'= 0 if ent_rentpayment_`month_rd'==777
	tab `var'_DKref
	la var ent_rentpayment_`month_rd' "Monthly rent payment `month_rd'"
}
foreach month in Aug15 Sep15 Oct15 Nov15 Dec15 Jan16 Feb16 Mar16 {
	gen ent_rentpayment_`month'=.
	la var ent_rentpayment_`month' "Monthly rent payment `month'"
	qui ds ent_rentpayment_`month'_??
	local varlist=r(varlist)
	foreach var in `varlist' {
	* I assert that there is no conflict between data from different round for same month
	replace ent_rentpayment_`month'=`var' if ent_rentpayment_`month'==.

	* drop `var'
	}
	tab ent_rentpayment_`month'
}


/* Total number of employees */
forval round=1/7 {
	destring q2_numemployees_R`round', gen(ent_numemployees_R`round')
	recode ent_numemployees_R`round' (-99 -98 = .)
	la var ent_numemployees_R`round' "No. of employees in Round `round'"
	tab ent_numemployees_R`round'
	
	gen month_R`round' = mofd(today_R`round')
	format %tmMonYY month_R`round' 
	tostring month_R`round', replace format(%tmMonYY) force
}

foreach month in Sep15 Oct15 Nov15 Dec15 Jan16 Feb16 Mar16 Apr16 Jun16 {
	gen ent_numemployees_`month' = .
	la var ent_numemployees_`month' "Number of employees in `month'"

	forval round = 1/7 {
	* I assert that there is no conflict between data from different round for same month
	replace ent_numemployees_`month' = ent_numemployees_R`round' if month_R`round' == "`month'" & ent_numemployees_`month' == .
	* drop `var'
	}
	tab ent_numemployees_`month'
}
drop month_R?


/* Total wage bill */
qui ds q3_wagebill_????????
local varlist=r(varlist)
foreach var in `varlist' {
	local month_rd=proper(substr("`var'",-8,8))
	destring `var', replace
	gen `var'_DKref = (`var' == -99 | `var' == -98 | `var' == -999 | `var' == 98 | `var' == 99) if `var' != .
	recode `var' (min/-1 98 99 = .), gen(ent_wagebill_`month_rd')
	tab `var'_DKref
	la var ent_wagebill_`month_rd' "Total wage bill `month_rd'"
}
foreach month in Aug15 Sep15 Oct15 Nov15 Dec15 Jan16 Feb16 Mar16 {
	gen ent_wagebill_`month'=.
	la var ent_wagebill_`month' "Total wage bill `month'"
	qui ds ent_wagebill_`month'_??
	local varlist=r(varlist)
	foreach var in `varlist' {
	* I assert that there is no conflict between data from different round for same month
	replace ent_wagebill_`month'=`var' if ent_wagebill_`month'==.
	* drop `var'
	}
	replace ent_wagebill_`month' = . if ent_wagebill_`month' == 1
	tab ent_wagebill_`month'
}



/* Tax and license payments */

* recode s4_q13_islicensed (1 = 1) (2 = 0) (nonm = .), gen(ent_licensed)
* la var ent_licensed "Enterprise is licensed"

* recode s4_q13a_licensecost (min/-1 = .), gen(ent_licensecost)
* replace ent_licensecost = 0 if ~ent_licensed
* la var ent_licensecost "License cost"

* recode s4_q14_marketfees (min/-1 = .), gen(ent_marketfees)
* la var ent_marketfees "Market fees paid last mo."


* National taxes
qui ds q7_taxesnatl_????????
local varlist=r(varlist)
foreach var in `varlist' {
	local month_rd=proper(substr("`var'",-8,8))
	destring `var', replace
	gen `var'_DKref = (`var' == -99 | `var' == -98 | `var' == -999 | `var' == 98 | `var' == 99 | `var' == 888) if `var' != .
	recode `var' (min/-1 98 99 888 = .), gen(ent_nationaltaxes_`month_rd')
	tab `var'_DKref
	la var ent_nationaltaxes_`month_rd' "National taxes paid `month_rd'"
}
foreach month in Aug15 Sep15 Oct15 Nov15 Dec15 Jan16 Feb16 Mar16 {
	gen ent_nationaltaxes_`month'=.
	la var ent_nationaltaxes_`month' "National taxes paid `month'"
	qui ds ent_nationaltaxes_`month'_??
	local varlist=r(varlist)
	foreach var in `varlist' {
	* I assert that there is no conflict between data from different round for same month
	replace ent_nationaltaxes_`month'=`var' if ent_nationaltaxes_`month'==.
	* drop `var'
	}
	tab ent_nationaltaxes_`month'
}

* County taxes
qui ds  q8_taxescty_????????
local varlist=r(varlist)
foreach var in `varlist' {
	local month_rd=proper(substr("`var'",-8,8))
	destring `var', replace
	gen `var'_DKref = (`var' == -99 | `var' == -98 | `var' == -999 | `var' == 98 | `var' == 99 | `var' == 888) if `var' != .
	recode `var' (min/-1 98 99 888 = .), gen(ent_countytaxes_`month_rd')
	tab `var'_DKref
	la var ent_countytaxes_`month_rd' "County taxes paid `month_rd'"
}

foreach month in Aug15 Sep15 Oct15 Nov15 Dec15 Jan16 Feb16 Mar16 {
	gen ent_countytaxes_`month'=.
	la var ent_countytaxes_`month' "County taxes paid `month'"
	qui ds ent_countytaxes_`month'_??
	local varlist=r(varlist)
	foreach var in `varlist' {
	* I assert that there is no conflict between data from different round for same month
	replace ent_countytaxes_`month'=`var' if ent_countytaxes_`month'==.
	* drop `var'
	}
	tab ent_countytaxes_`month'
}


/* Total taxes */
foreach month in Aug15 Sep15 Oct15 Nov15 Dec15 Jan16 Feb16 Mar16 {
	egen ent_totaltaxes_`month'= rowtotal(ent_countytaxes_`month' ent_nationaltaxes_`month') if ent_countytaxes_`month' != . | ent_nationaltaxes_`month' != .
}



* recode s4_q15c_taxeslocal (min/-1 = .), gen(ent_localtaxes)
* la var ent_localtaxes "Local taxes paid last mo."

* recode s4_q15d_taxesother (min/-1 = .), gen(ent_othertaxes)
* la var ent_othertaxes "Payments to police, officials last mo."

* egen ent_totalfees = rowtotal(ent_licensecost ent_marketfees ent_*taxes), m
* la var ent_totalfees "Total taxes, fees paid last mo."

/* Profits */
qui ds q5_profitmth_????????
local varlist=r(varlist)
foreach var in `varlist' {
	local month_rd=proper(substr("`var'",-8,8))
	destring `var', replace
	gen `var'_DKref = (`var' == -99 | `var' == -98 | `var' == -999 | `var' == 98 | `var' == 99 | `var' == 999 | `var' == -96 ) if `var' != .
	recode `var' (-99 -98 -999 98 99 999 -96 = .), gen(ent_profit_`month_rd')
	tab `var'_DKref
	la var ent_profit_`month_rd' "Profits `month_rd'"
}

foreach month in Aug15 Sep15 Oct15 Nov15 Dec15 Jan16 Feb16 Mar16 {
	gen ent_profit_`month'=.
	la var ent_profit_`month' "Profits  `month'"
	qui ds ent_profit_`month'_??
	local varlist=r(varlist)
	foreach var in `varlist' {
	* I assert that there is no conflict between data from different round for same month
	replace ent_profit_`month'=`var' if ent_profit_`month'==.
	* drop `var'
	}
	tab ent_profit_`month'
}

/* Prices */
ds q1a_price_tailor_????????
local varlist=r(varlist)
foreach var in `varlist' {
	local month_rd=proper(substr("`var'",-8,8))
	destring `var', replace
	gen `var'_DKref = (`var' == -99 | `var' == -98 | `var' == -999 | `var' == 98 | `var' == 99 | `var' == 999 | `var' == -96 | `var' == 998 | `var' == 9998 | `var' == 0) if `var' != .
	recode `var' (0 -99 -98 -999 98 99 999 -96 998 9998 = .), gen(p_tailor_`month_rd')
	tab `var'_DKref
	la var p_tailor_`month_rd' "Tailor prices (simple patch), `month_rd'"
}

browse p_tailor*
foreach month in Sep15 Oct15 Nov15 Dec15 Jan16 Feb16 Mar16 Apr16 {
	gen a_`month' = 0
	gen p_tailor_`month'=.
	la var p_tailor_`month' "Tailor prices (simple patch), `month_rd'"
	qui ds p_tailor_`month'_??
	local varlist=r(varlist)
	foreach var in `varlist' {
	* I assert that there is no conflict between data from different round for same month
	replace a_`month' = 1 if p_tailor_`month' != `var' & p_tailor_`month' != . & `var' != .
	replace p_tailor_`month' = `var' if p_tailor_`month' == .
	* drop `var'
	}
	tab p_tailor_`month'
}
sum a_*
browse p_tailor_Oct15* *price_tailor*oct15* if a_Oct15 == 1
** According to MW, we should just take the first round for which we have data
** This is what we have done!
drop a_*


** Fix maize grinding prices **
browse q1a_grind1gg_sep15_R1 q1a_grindmaize1kg_sep15_R1 if q1a_grind1gg_sep15_R1 != "" // no overlap
replace q1a_grindmaize1kg_sep15_R1 = q1a_grind1gg_sep15_R1 if q1a_grind1gg_sep15_R1 != ""
drop q1a_grind1gg_sep15_R1

browse q2a_grind1gg_aug15_R1 q2a_grindmaize1kg_aug15_R1 if q2a_grind1gg_aug15_R1 != "" // no overlap
replace q2a_grindmaize1kg_aug15_R1 = q2a_grind1gg_aug15_R1 if q2a_grind1gg_aug15_R1 != ""
drop q2a_grind1gg_aug15_R1

browse q1b_grind20gg_sep15_R1 q1b_grindmaize20kg_sep15_R1 if q1b_grind20gg_sep15_R1 != "" // no overlap
replace q1b_grindmaize20kg_sep15_R1 = q1b_grind20gg_sep15_R1 if q1b_grind20gg_sep15_R1 != ""
drop q1b_grind20gg_sep15_R1

browse q2b_grind20gg_aug15_R1 q2b_grindmaize20kg_aug15_R1 if q2b_grind20gg_aug15_R1 != "" // no overlap
replace q2b_grindmaize20kg_aug15_R1 = q2b_grind20gg_aug15_R1 if q2b_grind20gg_aug15_R1 != ""
drop q2b_grind20gg_aug15_R1

browse apr16q1a_grind1gg_apr16_R6 q1a_grind1gg_apr16_R6 if apr16q1a_grind1gg_apr16_R6 != "" // no overlap
replace q1a_grind1gg_apr16_R6 = apr16q1a_grind1gg_apr16_R6 if apr16q1a_grind1gg_apr16_R6 != ""
drop apr16q1a_grind1gg_apr16_R6

browse apr16q1b_grind20gg_apr16_R6 q1b_grind20gg_apr16_R6 if apr16q1b_grind20gg_apr16_R6 != "" // no overlap
replace q1a_grind1gg_apr16_R6 = q1b_grind20gg_apr16_R6 if apr16q1b_grind20gg_apr16_R6 != ""
drop apr16q1b_grind20gg_apr16_R6

ren *grind1gg* *grind1kg*
ren *grind20gg* *grind20kg*
ren *grindmaize1kg* *grind1kg*
ren *grindmaize20kg* *grind20kg*

browse *grind1kg* *grind20kg*
destring *grind1kg* *grind20kg*, replace

foreach v in grind1kg grind20kg {
	ds *`v'_????????
	local varlist=r(varlist)
	foreach var in `varlist' {
		local month_rd=proper(substr("`var'",-8,8))
		destring `var', replace
		gen `var'_DKref = (`var' == -99 | `var' == -98 | `var' == -999 | `var' == 98 | `var' == 99 | `var' == 999 | `var' == -96 | `var' == 998 | `var' == 9998 | `var' == 0) if `var' != .
		recode `var' (0 -99 -98 -999 98 99 999 -96 998 9998 = .), gen(p_`v'_`month_rd')
		tab `var'_DKref
		la var p_`v'_`month_rd' "Tailor prices (simple patch), `month_rd'"
	}

	browse p_`v'*
	foreach month in Aug15 Sep15 Oct15 Nov15 Dec15 Jan16 Feb16 Mar16 Apr16 {
		gen p_`v'_`month'=.
		la var p_`v'_`month' "Maize grinding prices, `month_rd'"
		qui ds p_`v'_`month'_??
		local varlist=r(varlist)
		foreach var in `varlist' {
		* I assert that there is no conflict between data from different round for same month
		replace p_`v'_`month' = `var' if p_`v'_`month' == .
		* drop `var'
		}
		tab p_`v'_`month'
	}
}

/* DK / refuse across variables */
egen ent_revenue_sumDKref = rowtotal(q4_revenuesmth_*_DKref), missing
egen ent_profit_sumDKref = rowtotal(q5_profitmth_*_DKref), missing
egen ent_nationaltaxes_sumDKref  = rowtotal(q7_taxesnatl_*_DKref), missing
egen ent_countytaxes_sumDKref = rowtotal(q8_taxescty_*_DKref), missing
egen ent_wagebill_sumDKref = rowtotal(q3_wagebill_*_DKref), missing
egen p_tailor_sumDKref = rowtotal(*price_tailor_*_DKref), missing

egen times_surveyed = rowtotal(surveyed_RD?)

foreach var in ent_revenue ent_profit ent_nationaltaxes ent_countytaxes ent_wagebill p_tailor { // p_grind1kg p_grind20kg {
	egen `var'_nonmiss = rownonmiss(`var'_?????)
	gen `var'_shareDKref = `var'_sumDKref / times_surveyed
}

summ *_sumDKref
summ *_nonmiss
summ *_shareDKref


/* Operational indicator */
* Here I define operating_*==0 if the business category is reported as "none" in that round
* operating_*==1 if business category is reported but not as "none"
qui ds q6a_bizcat_??
local varlist=r(varlist)
foreach var in `varlist' {
	local round=proper(substr("`var'",-2,2))
	gen operating_`round'=0 if `var'=="none"
	replace operating_`round'=1 if `var'!="none" &`var'!=""
	la var operating_`round' "Operational in `round'"

	gen operating_in4cat_`round'=1 if `var'=="hardware" |`var'=="posho"| `var'=="tailor" | `var'=="sretail"
	replace operating_in4cat_`round'=0 if `var'!="" & operating_in4cat_`round'!=1
	la var operating_in4cat_`round' "Operational in posho mill, tailor, small retail or hardware shop in `round'"
}

** Constructing Alternative measure for operational indicator
*  If the enterprise did not consent or consent variable is missing, the operational indicator is missing. If the enterprise consent to be surveyed, but did not report any profit, revenue, wage bill, rent, or tax, then operating_alt_*==0. If any of these variables is reported, then operating_alt_*==1


* Generate missing indicator for each month_rd,the indicator is missing if the enterprise did not consent or consent variable is missing
destring consent_R1,replace

* Some issues with R7, didn't include Mar16_R7
foreach month_rd in Aug15_R1 Sep15_R1 Oct15_R2 Sep15_R2 Oct15_R3 Sep15_R3 Nov15_R3 Dec15_R3 Jan16_R4 Dec15_R4 Nov15_R4 Sep15_R5 Jan16_R5 Feb16_R5 Nov15_R5 Dec15_R5 Feb16_R6 Jan16_R6 {
	local rd=substr("`month_rd'",-2,2)
	gen miss_profit_`month_rd'=(ent_profit_`month_rd'==.)
	replace miss_profit_`month_rd'=. if consent_`rd'==2 |consent_`rd'==.
	gen miss_revenue_`month_rd'=(ent_revenue_`month_rd'==.)
	replace miss_revenue_`month_rd'=. if consent_`rd'==2 |consent_`rd'==.
	gen miss_rentpayment_`month_rd'=(ent_rentpayment_`month_rd'==.)
	replace miss_rentpayment_`month_rd'=. if consent_`rd'==2 |consent_`rd'==.
	gen miss_wagebill_`month_rd'=(ent_wagebill_`month_rd'==.)
	replace miss_wagebill_`month_rd'=. if consent_`rd'==2 |consent_`rd'==.
	gen miss_nationaltaxes_`month_rd'=(ent_nationaltaxes_`month_rd'==.)
	replace miss_nationaltaxes_`month_rd'=. if consent_`rd'==2 |consent_`rd'==.
	gen miss_countytaxes_`month_rd'=(ent_countytaxes_`month_rd'==.)
	replace miss_countytaxes_`month_rd'=. if consent_`rd'==2 |consent_`rd'==.
}

* Aug15_R1
* Sep15_R1 Sep15_R2 Sep15_R3 Sep15_R5
* Oct15_R2 Oct15_R3
* Nov15_R3 Nov15_R4 Nov15_R5
* Dec15_R3 Dec15_R4 Dec15_R5
* Jan16_R4 Jan16_R5 Jan16_R6
* Feb16_R5 Feb16_R6

* Generate missing indicator for each month, the indicator is missing if the enterprise did not consent or consent variable is missing
foreach var in miss_profit_ miss_revenue_ miss_rentpayment_ miss_wagebill_ miss_nationaltaxes_ miss_countytaxes_ {
gen `var'Aug15=`var'Aug15_R1
gen `var'Sep15=(`var'Sep15_R1==1&`var'Sep15_R2==1&`var'Sep15_R3==1&`var'Sep15_R5==1) if !(`var'Sep15_R1==.&`var'Sep15_R2==.&`var'Sep15_R3==.&`var'Sep15_R5==.)
gen `var'Oct15=(`var'Oct15_R2==1&`var'Oct15_R3==1) if !(`var'Oct15_R2==.&`var'Oct15_R3==.)
gen `var'Nov15=(`var'Nov15_R3==1&`var'Nov15_R4==1&`var'Nov15_R5==1) if !(`var'Nov15_R3==.&`var'Nov15_R4==.&`var'Nov15_R5==.)
gen `var'Dec15=(`var'Dec15_R3==1&`var'Dec15_R4==1&`var'Dec15_R5==1) if !(`var'Dec15_R3==.&`var'Dec15_R4==.&`var'Dec15_R5==.)
gen `var'Jan16=(`var'Jan16_R6==1&`var'Jan16_R4==1&`var'Jan16_R5==1) if !(`var'Jan16_R6==.&`var'Jan16_R4==.&`var'Jan16_R5==.)
gen `var'Feb16=(`var'Feb16_R6==1&`var'Feb16_R5==1) if !(`var'Feb16_R6==.&`var'Feb16_R5==.)

* Generate missing indicator for each round,the indicator is missing if the enterprise did not consent or consent variable is missing
gen `var'R1=(`var'Sep15_R1==1&`var'Aug15_R1==1) if !(`var'Sep15_R1==.&`var'Aug15_R1==.)
gen `var'R2=(`var'Sep15_R2==1&`var'Oct15_R2==1) if !(`var'Sep15_R2==.&`var'Oct15_R2==.)
gen `var'R3=(`var'Sep15_R3==1&`var'Oct15_R3==1&`var'Nov15_R3==1) if !(`var'Sep15_R3==.&`var'Oct15_R3==.&`var'Nov15_R3==.)
gen `var'R4=(`var'Dec15_R4==1&`var'Jan16_R4==1&`var'Nov15_R4==1) if !(`var'Dec15_R4==.&`var'Jan16_R4==.&`var'Nov15_R4==.)
gen `var'R5=(`var'Dec15_R5==1&`var'Jan16_R5==1&`var'Feb16_R5==1&`var'Nov15_R5==1) if !(`var'Dec15_R5==.&`var'Jan16_R5==.&`var'Feb16_R5==.&`var'Nov15_R5==.)
gen `var'R6=(`var'Jan16_R6==1&`var'Feb16_R6==1) if !(`var'Jan16_R6==.&`var'Feb16_R6==.)
}

* Generate alternative operational indicator for each month
foreach month in Aug15 Sep15 Oct15 Nov15 Dec15 Jan16 Feb16{
gen operating_alt_m_`month'=!(miss_profit_`month'==1 & miss_revenue_`month'==1 & miss_rentpayment_`month'==1 & miss_wagebill_`month'==1 & miss_nationaltaxes_`month'==1 & miss_countytaxes_`month'==1)
replace operating_alt_m_`month'=. if (miss_profit_`month'==. & miss_revenue_`month'==. & miss_rentpayment_`month'==. & miss_wagebill_`month'==. & miss_nationaltaxes_`month'==. & miss_countytaxes_`month'==.)
la var operating_alt_m_`month' "Alternative Operational measure in `month'"
}

* Generate alternative operational indicator for each round
foreach rd in R1 R2 R3 R4 R5 R6 {
gen operating_alt_`rd'=!(miss_profit_`rd'==1 & miss_revenue_`rd'==1 & miss_rentpayment_`rd'==1 & miss_wagebill_`rd'==1 & miss_nationaltaxes_`rd'==1 & miss_countytaxes_`rd'==1)
replace operating_alt_`rd'=. if (miss_profit_`rd'==. & miss_revenue_`rd'==. & miss_rentpayment_`rd'==. & miss_wagebill_`rd'==. & miss_nationaltaxes_`rd'==. & miss_countytaxes_`rd'==.)
la var operating_alt_`rd' "Alternative Operational measure in `rd'"
}
drop miss* ent_profit_?????_?? ent_revenue_?????_?? ent_rentpayment_?????_?? ent_wagebill_?????_?? ent_nationaltaxes_?????_?? ent_countytaxes_?????_??

/* NOT IN PAP, BUT USEFUL: cleaning reasons for enterprises closing */
/* Cleaning closures for summary stats
	- creating a "mechanical/techical issues" option: 7
	- creating a "personal reasons" option: 9
	- all other: 10
	Note that some of 7  may be related to lack of capital - can't afford repairs
*/
/*
replace ent_closure_R1 = "9" if inlist(ent_closure_other_R1, "Was sick", "Due to separation with the couple", "Other commitments", "Business owner closed the business and relocated", "The owner went to school", "The enterprise house was under repair")
replace ent_closure_R1 = "9" if inlist(ent_closure_other_RD1, "Home affairs which he was not ready to specify,will consume before end of this month", "Was sick and could not manage the business")
replace ent_closure_R1 = "7" if inlist(ent_closure_other_RD1, "Network disconnection by safaricom. The enterprise was an mpesa shop.", "Mechanical break down", "Mechanical brake down", "The poshomil broke down", "Mechanical brakedown")
replace ent_closure_R1 = "1 7" if  ent_closure_other_RD1=="Poshomill got spoilt, still unable to raise capital to buy the required spare part"
replace ent_closure_R1 = "10" if ent_closure_other_RD1 == "Fr is was an employee and since he left the job, enterprise owner closed that mpesa"

replace ent_closure_R2 = "9" if inlist(ent_closure_other_RD2, "She has had other commitments (sickness) and is yet to resume", "Enterprise owner is bedridden/insane", "Illness of the enterprise owner.", "Travelled", "The person working there gave birth")
replace ent_closure_R2 = "9" if inlist(ent_closure_other_RD2, "Family wrangles over the kiosk", "Joined her husband in town", "Fr migrated to another town Kisumu", "Business was far from the owners residents", "Its a small retail mpesa, its closed since the employer left for Nairobi with the mpesa sim")
replace ent_closure_R2 = "7" if inlist(ent_closure_other_RD2, "Machine not working due to technical problem", "No electricity to run the machine due to a problem with the transformer", "Mechanical problem", "The machine is having mechanical problem", "The poshomil broke down", "Mechanical problem", "Mechanical problem")
replace ent_closure_R2 = "10" if ent_closure_other_RD2=="Enterprise closed down after the census was done, when surveyed in October, it was not operating a sretail anymore and was reported as " | ent_closure_other_RD2=="They are still looking for a place to relocate the business" | ent_closure_other_RD2 == "The enterprise owner moved the business to wagai" | ent_closure_other_RD2 =="Enterprise category changed"

replace ent_closure_R3 = "9" if inlist(ent_closure_other_RD3, "Enterprise owner is sick")
replace ent_closure_R3 = "7" if inlist(ent_closure_other_RD3, "Machine broke down.", "Machine broke down", "Machine Broke down,fr is yet to repair", "Machine broke down", "Mechanical breakdown", "Machine broke down. Yet to be restarted.", "The small transformer installed cannot operate the posho mill. They are waiting for Kenya power to change it.")


replace ent_closure_R4 = "9" if inlist(ent_closure_other_RD4, "Fr feel sick from 28 january and went off business.", "Fr is on maternity leave and shall resume when the baby shall have reached six months old", "Fr got sick", "Enterprise owner incapacitated due to illness", "The fr is sick", "The enterprise owner sick", "Fr is care giving in Nairobi,for her convalescent father.")
replace ent_closure_R4 = "9" if inlist(ent_closure_other_RD4, "Fr is sick Admitted in hospital", "FR has been sick since January", "FR has a patient in Bungoma District and so the Enterprise has closed down temporarily")
replace ent_closure_R4 = "7" if inlist(ent_closure_other_RD4, "Mechanical problem", "There was problem with the transformer", "Dealer with draw m pesa line", "There is no power transformer blored", "Due to construction works going on,power was disconnected a month ago,and is yet to be reconnected.")
replace ent_closure_R4 = "10" if inlist(ent_closure_other_RD4, "Fr says her employee in the shop left for college forcing her to close down the enterprise.", "Person who was selling for the respondent moved out hence the business stopped", "Fr was sent away by the shop owner and now doesn't have any house to sell his goods", "Absensia of the employee", "Looking for a trust worthy person")
replace ent_closure_R4 = "1 9" if ent_closure_other_RD4 == "Fr is sick and has used the capital for her medication"

replace ent_closure_R5 = "5" if ent_closure_other_RD5 == "It was built along the road and with the road expansion it was removed"
replace ent_closure_R5 = "7" if ent_closure_other_RD5 == "Transformer got spoiled that was supplying energy to the poshomill"
replace ent_closure_R5 = "9" if inlist(ent_closure_other_RD5, "Closed the business for personal reasons", "Used capital to clear hospital bill", "FR went back to school", "Fr has been busy handling other family things couldn't do business", "Matanity leave", "They have been having some family issues to attend to", "Illness")
replace ent_closure_R5 = "9" if inlist(ent_closure_other_RD5, "Fr was sick hence had sought treatment in Nairobi. She is yet to resume her business", "Fr says that she has been unwell hence unable to attend the enterprise.", "External family wrangles and every time in sighting her employees to go away")
replace ent_closure_R5 = "9" if inlist(ent_closure_other_RD5, "Fr had a problem and spent her capital on the problem forcing her to temporarily close down the business.")
replace ent_closure_R5 = "10" if inlist(ent_closure_other_RD5, "Lack of empleyee")
replace ent_closure_R5 = "1 9" if (ent_closure_R5 == "1 other" & ent_closure_other_RD5 == "The FR sick") | (ent_closure_other_RD5 == "Spent capital to settle hospital bill")


replace ent_closure_R6 = "9" if inlist(ent_closure_other_RD6, "Fr is sick", "The fr is bed ridden", "Fr says she delivered a child in October hence has been on maternity leave from her job.", "Fr moved to another town hence closed down the enterprise.", "Fr commited somewhere")
replace ent_closure_R6 = "7" if ent_closure_other_RD6=="Transformer broke down."
replace ent_closure_R6 = "5" if ent_closure_other_RD6=="Business tools were taken away by government officials due to failure to pay revenues in time"


forval i=1/6 {
	replace ent_closure_R`i' = trim(subinstr(ent_closure_R`i', "other", "", 1))
	di "RD `i'"
	tab ent_closure_R`i'
	gen misclass_RD`i' = (ent_closure_R`i' == "6")
}
replace misclass_RD4 = 1 if ent_closure_R4 == "1 6"
*/



foreach mon in Aug15 Sep15 Oct15 Nov15 Dec15 Jan16 Feb16 Mar16 Apr16 Jun16 {
    gen surveyed_`mon' = 0
	gen success_`mon' = 0
	gen operating_in4cat_`mon' = .
}

forval j=1/7 {
	gen month_R`j' = mofd(today_R`j')
	foreach mon in Aug15 Sep15 Oct15 Nov15 Dec15 Jan16 Feb16 Mar16 Apr16 Jun16 {
		local mm = monthly("`mon'", "M20Y")
		replace surveyed_`mon' = 1 if month_R`j' == `mm'
		replace success_`mon' = 1 if month_R`j' == `mm' & consent_R`j' == 1
		replace operating_in4cat_`mon' = operating_in4cat_R`j' if month_R`j' == `mm'
	}
}

* generating retrospective operating variables
destring operation_*, replace
foreach mon in Oct15 Nov15 Dec15 Jan16 Feb16 Mar16 {
	local intmon = lower(subinstr("`mon'", "15","2015", 1))
	local intmon = lower(subinstr("`intmon'", "16","2016", 1))
	di "Month: `mon' Intmonth: `intmon'"
	gen int_operating_in4cat_`mon' = (operation_`intmon'_R5 == 1 | operation_tailor_`intmon'_R5 == 1 | operation_hardware_`intmon'_R5 == 1 | operation_sretail_`intmon'_R5 == 1)
	replace int_operating_in4cat_`mon' = . if operation_`intmon'_R5 == . & operation_tailor_`intmon'_R5  == . & operation_hardware_`intmon'_R5 == . & operation_sretail_`intmon'_R5 == . // if all of these missing, setting variable to missing
	replace operating_in4cat_`mon' = int_operating_in4cat_`mon' if operating_in4cat_`mon' == . & int_operating_in4cat_`mon' != . // updating main operatiional variable
}


tab1 month_R?
foreach var of varlist surveyed_????? operating_in4cat_????? {
	di "Variable `var': Num non-missing"
	count if `var' != .
}

destring village_code, replace
save "$da/GE_ENT-Midline_wide_CLEAN_FINAL.dta", replace
project, creates("$da/GE_ENT-Midline_wide_CLEAN_FINAL.dta") preserve

/*
tab1 ent_misclassified_*
egen misclass_rowtot = rowtotal(ent_misclassified_R?)
tab misclass_rowtot
count if misclass_rowtot > 0
gen misclass = (misclass_rowtot > 0)

drop if misclass == 1
count // should be 1929
*/

keep call_rank village_code ent_id fr_id p_tailor_????? p_grind1kg_????? p_grind20kg_????? ent_profit_?????  ent_revenue_????? ent_rentpayment_????? ent_wagebill_????? ent_*taxes_????? operating_in4cat_????? ent_numemployees_????? prim* subcounty location gps_latitude gps_longitude longitude latitude sublocation sublocation_code surveyed_RD? sampwt today_R? consent_R? success_?????
order subcounty location sublocation sublocation_code village_code ent_id fr_id call_rank sampwt gps_latitude gps_longitude latitude longitude primary_bizcat prim_* today_R? consent_R? surveyed_RD? operating_* success_*

/*
foreach mon in aug15 sep15 oct15 nov15 dec15 jan16 feb16 mar16 apr16 {
    gen surveyed_`mon' = 0
	gen success_`mon' = 0
	gen operating_`mon' = .
	gen operating_in4cat_`mon' = .
}

forval j=1/7 {
	gen month_R`j' = mofd(today_R`j')
	foreach mon in aug15 sep15 oct15 nov15 dec15 jan16 feb16 mar16 apr16 {
		local mm = monthly("`mon'", "M20Y")
		replace surveyed_`mon' = 1 if month_R`j' == `mm'
		replace success_`mon' = 1 if month_R`j' == `mm' & consent_R`j' == 1
		replace operating_`mon' = operating_R`j' if month_R`j' == `mm'
		replace operating_in4cat_`mon' = operating_in4cat_R`j' if month_R`j' == `mm'
	}
}

tab1 month_R?
foreach var of varlist surveyed_????? operating_????? operating_in4cat_????? {
	di "Variable `var': Num non-missing"
	count if `var' != .
}

*/


reshape long  p_tailor_ p_grind1kg_ p_grind20kg_ ent_profit_  ent_numemployees_ ent_revenue_ ent_rentpayment_  ent_wagebill_  ent_nationaltaxes_ ent_countytaxes_ ent_totaltaxes_ operating_in4cat_  success_, i(call_rank) j(month) string

la var ent_numemployees_ "Number of employees"
la var ent_revenue_ "Revenues"
la var ent_rentpayment_ "Monthly rent payment"
la var ent_wagebill_ "Total wage bill"
la var ent_nationaltaxes_ "National taxes paid"
la var ent_countytaxes_ "County taxes paid"
la var ent_totaltaxes_ "Total taxes paid"
la var ent_profit_ "Profits"
la var operating_in4cat_ "Operating (in sample)"
la var p_tailor_ "Tailor prices (simple patch)"
la var p_grind1kg_ "Price of grinding 1kg of maize"
la var p_grind20kg_ "Price of grinding 20kg of maize"
tab month

* For taxes, mostly are zeros

/* Truncation (twosided) at 0.01 */

foreach var of varlist ent_profit_  ent_revenue_  ent_wagebill_  ent_nationaltaxes_ ent_countytaxes_ ent_totaltaxes_ {

	qui sum `var', d
	gen `var'trunc = `var' if `var' >= `r(p1)' & `var' <= `r(p99)'
	loc varla: var la `var'
	la var `var'trunc "`varla' (Trunc.)"
}

/* Truncation right tail at 0.01 */
foreach var of varlist ent_profit_  ent_revenue_  ent_wagebill_  ent_nationaltaxes_ ent_countytaxes_ ent_totaltaxes_ {

	qui sum `var', d
	gen `var'trunc_rt = `var' if `var' <= `r(p99)'
	loc varla: var la `var'
	la var `var'trunc_rt "`varla' (Trunc. Right tail)"
}

/* Winsorization at 0.01 */

foreach var of varlist ent_profit_  ent_revenue_  ent_wagebill_  ent_nationaltaxes_ ent_countytaxes_ ent_totaltaxes_ {

	winsor `var', gen(`var'wins) p(0.01)
	loc varla: var la `var'
	la var `var'wins "`varla' (Wins.)"

}

/* Winsorization right tail at 0.01 */
foreach var of varlist ent_profit_  ent_revenue_  ent_wagebill_  ent_nationaltaxes_ ent_countytaxes_ ent_totaltaxes_ {

	winsor `var', gen(`var'wins_rt) p(0.01) highonly
	loc varla: var la `var'
	la var `var'wins_rt "`varla' (Wins. Right tail)"

}

* Except ent_profit_, right tail Winsorization are exactly the same as twosided Winsorization.
* count if  ent_revenue_wins_rt != ent_revenue_wins
* count if  ent_profit_wins_rt != ent_profit_wins
* count if  ent_wagebill_wins_rt != ent_wagebill_wins
* count if  ent_nationaltaxes_wins_rt != ent_nationaltaxes_wins
* count if  ent_countytaxes_wins_rt != ent_countytaxes_wins

/* IHS transform */

foreach var of varlist ent_profit_ ent_revenue_  ent_wagebill_  ent_nationaltaxes_ ent_countytaxes_ ent_totaltaxes_{

	gen `var'ihs = asinh(`var')
	loc varla: var la `var'
	la var `var'ihs "`varla' (IHS)"

}

/* Generate log prices */
gen ln_p_tailor = ln(p_tailor_)
gen ln_p_grind1kg = ln(p_grind1kg)
gen ln_p_grind20kg = ln(p_grind20kg)


/* Save */
rename month month_str
gen month= monthly(month_str,"MY",2050)
format %tmMonYY month
sort call_rank month
order call_rank month month_str
destring village_code, replace
save "$da/GE_ENT-Midline_long_CLEAN_FINAL.dta", replace
project, creates("$da/GE_ENT-Midline_long_CLEAN_FINAL.dta")
