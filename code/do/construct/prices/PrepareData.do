
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

project, uses("$dt/pp_GDP_calculated_nominal.dta")
use "$dt/pp_GDP_calculated_nominal.dta", clear
global pp_GDP = pp_GDP[1]
clear

// end preliminaries

* load commands
project, original("$do/programs/run_ge_build_programs.do")
include "$do/programs/run_ge_build_programs.do"


*************************
** 0. Data Preparation **
*************************

** loading price data **
project, uses("$dt/H1_idx.dta")
use "$dt/H1_idx.dta", clear

** bring in market

** merge with actual treatment data **
rename market_id market_code
project, uses("$da/market_actualtreat_wide_FINAL.dta") preserve
merge 1:1 market_code month using "$da/market_actualtreat_wide_FINAL.dta"
replace market_id = market_code if market_id == .

tab month _merge

** merge == 1 are observations from 2014m08, where we have price data, but no transfers went out yet **
** I fix this here by setting transfer amounts to zero **
foreach v of varlist *km {
	replace `v' = 0 if _merge == 1
}

** also fix population counts **
foreach v of varlist p_total* p_ge* {
	bysort market_code (month): replace `v' = `v'[_N] if _merge == 1
}

** merge == 2 are observations where we still have transfer data going out, but no longer have any market prices - drop those.
drop if _merge == 2
drop _merge

sort market_id month

*******************************************
** Generate Sublocation Treatment Status **
*******************************************
preserve
project, original("$dr/Transfers_VillageLevel_Temporal_PUBLIC.dta") preserve
use "$dr/Transfers_VillageLevel_Temporal_PUBLIC.dta", clear

tostring village_code, gen(sublocation_code) format(%12.0f)
replace sublocation_code = substr(sublocation_code,1,9)
destring sublocation_code, replace
format sublocation_code %9.0f

bysort village_code (month): gen a = sum(n_trans)
drop if a == 0
collapse (mean) hi_sat (min) month, by(subcounty sublocation_code)
save "$dt/sublocation_treatment.dta", replace
project, creates("$dt/sublocation_treatment.dta")
restore

** assign markets in out-of-sample sublocations to the nearest sublocation **
replace sublocation_code = 601020402 if market_id == 109
replace sublocation_code = 601010201 if market_id == 118
replace sublocation_code = 601050502 if market_id == 206
replace sublocation_code = 601050101 if market_id == 209
replace sublocation_code = 601040104 if market_id == 307
replace sublocation_code = 601040107 if market_id == 312

** One market is only slightly outside the study area - assign this market to the closest sublocation **
replace sublocation_code = 601010301 if market_id == 101

merge m:1 sublocation_code month using "$dt/sublocation_treatment.dta", update
drop if _merge == 2 // these are sublocations which have no markets

gen post = 1 if inlist(_merge,3,4)
drop _merge

** fix hi-sat for markets in non-sample sublocations **
bysort market_id: egen temp = min(hi_sat)
replace hi_sat = temp
drop temp

** generate post and hi_sat*post **
bysort market_id (month): replace post = sum(post)

replace post = 1 if market_id == 101 & month > tm(2014m9)
gen hi_sat_post = hi_sat*post

gen subcounty_str = subcounty
drop subcounty
gen subcounty = 1 if subcounty_str == "SIAYA"
replace subcounty = 2 if subcounty_str == "UGUNJA"
replace subcounty = 3 if subcounty_str == "UKWALA"

** merge in market characteristics **
project, original("$dr/MarketDataMaster_PUBLIC.dta") preserve
merge m:1 market_id using "$dr/MarketDataMaster_PUBLIC.dta"
drop _merge

** clean up **
order district location_code sublocation_code market_id latitude longitude market_size OnMainRoad subloc_in_sample hi_sat post hi_sat_post month

***************************************
** Generate market and month dummies **
***************************************
levelsof market_id, local(markets)

foreach m in `markets' {
	gen mkt_`m' = 1 if market_id == `m'
	replace mkt_`m' = 0 if market_id != `m'
}

levelsof month, local(months)
foreach m in `months' {
	local name = string(`m', "%tm")

	gen m_`name' = 1 if month == `m'
	replace m_`name' = 0 if m_`name' == .

	gen hisat_`name' = 1 if month == `m' & hi_sat == 1
	replace hisat_`name' = 0 if hisat_`name' == . & hi_sat != .
}

order district location location_code sublocation sublocation_code market_id mkt_* latitude longitude market_size subloc_in_sample hi_sat post hi_sat_post month m_* hisat_* pidx_* p_total_* p_ge_??to* p_ge_eligible*


**********************************************
** Rename variables for naming restrictions **
**********************************************
rename *nondurall* *ndall*

*****************************************
** Generate spatial treatment measures **
*****************************************

*************************************************************************************************
** Our preferred measures are
**
** A) Per capita measures / percent of consumption expenditures (GDP)
** 1. Total amount as a fraction of per person average consumption expenditure (GDP) in each 2km radii band in the last 3 months
** 2. Experimental amount as a fraction of per person average consumption expenditure (GDP) in each 2km radii band in the last 3 months (using different rollout speeds in each county, and a 10% cutoff for the start date)
**
** B) Total amount measures
** 1. Amount (in 1'000'000 USD) in each 2km radii band in the last 3 months
** 2. Experimental amount (in 1'000'000 USD) in each 2km radii band in the last 3 months (using different rollout speeds in each county, and a 10% cutoff for the start date)
**
** C) Cumulated buffer measures
** For all of those measures, I also create the cumulative amount up to a certain distance,
** e.g. the total amount per person sent to HHs between 0 - 8km from the market.
**
** We can add additional measures later.
*************************************************************************************************
rename amount_total_KES* pp_actamt*
ren *eligible_* *elig_*

rename pp_actamt_0* pp_actamt_*
rename p_total_0* p_total_*
rename p_ge_0* p_ge_*
rename p_ge_elig_0* p_ge_elig_*
rename p_ge_elig_treat_0* p_ge_elig_treat_*

forval r = 2(2)8 {
	local r2 = `r' - 2
	rename pp_actamt_`r2'to0`r'km pp_actamt_`r2'to`r'km
	rename p_total_`r2'to0`r'km p_total_`r2'to`r'km
	rename p_ge_`r2'to0`r'km p_ge_`r2'to`r'km
	rename p_ge_elig_`r2'to0`r'km p_ge_elig_`r2'to`r'km
	rename p_ge_elig_treat_`r2'to0`r'km p_ge_elig_treat_`r2'to`r'km
}

** generate instruments **
**************************
forval r = 2(2)20 {
	local r2 = `r' - 2

	gen share_ge_elig_`r2'to`r'km = p_ge_elig_`r2'to`r'km/p_total_`r2'to`r'km
	gen share_ge_elig_treat_`r2'to`r'km = p_ge_elig_treat_`r2'to`r'km/p_ge_elig_`r2'to`r'km

	egen cum_p_total_`r'km = rowtotal(p_total_0to2km-p_total_`r2'to`r'km)
	egen cum_p_ge_`r'km = rowtotal(p_ge_0to2km-p_ge_`r2'to`r'km)
	egen cum_p_ge_elig_`r'km = rowtotal(p_ge_elig_0to2km-p_ge_elig_`r2'to`r'km)
	egen cum_p_ge_elig_treat_`r'km = rowtotal(p_ge_elig_treat_0to2km-p_ge_elig_treat_`r2'to`r'km)

	gen cum_share_ge_elig_`r'km = cum_p_ge_elig_`r'km/cum_p_total_`r'km
	gen cum_share_ge_elig_treat_`r'km = cum_p_ge_elig_treat_`r'km/cum_p_ge_elig_`r'km
}

order p_total_?to* p_total_??to* p_ge_?to* p_ge_??to* p_ge_elig_?to* p_ge_elig_??to* p_ge_elig_treat_?to* p_ge_elig_treat_??to* share_ge_elig_?to* share_ge_elig_??to* share_ge_elig_treat_?to* share_ge_elig_treat_??to* cum_p_total_?km cum_p_total_??km cum_p_ge_?km cum_p_ge_??km cum_p_ge_elig_?km cum_p_ge_elig_??km cum_p_ge_elig_treat_?km cum_p_ge_elig_treat_??km cum_share_ge_elig_?km cum_share_ge_elig_??km cum_share_ge_elig_treat_?km cum_share_ge_elig_treat_??km, last

** Generate the different quarterly measures **
***********************************************

** Get lags of the instrument and set to zero **
sum month
expand 2 if month == `r(min)', gen(dupl)
replace month = `r(min)'- 2 if dupl == 1
tab month
sort market_id month

foreach v of varlist pidx_* pidx2_* {
	replace `v' = . if dupl == 1
}

foreach v of varlist n_* m_* amount_*  pp_actamt_* {
	replace `v' = 0 if dupl == 1
}

xtset market_id month
tsfill, full
sort market_id month
bysort market_id: carryforward _all, replace
drop dupl

** generate quarterly instrument measures **
********************************************
xtset market_id month
foreach inst in actamt  {
	forval r = 2(2)20 {
		local r2 = `r' - 2

		replace pp_`inst'_`r2'to`r'km = 1/($pp_GDP)*pp_`inst'_`r2'to`r'km
		gen q_pp_`inst'_`r2'to`r'km = (pp_`inst'_`r2'to`r'km + L.pp_`inst'_`r2'to`r'km + L2.pp_`inst'_`r2'to`r'km)

		gen `inst'_`r2'to`r'km = pp_`inst'_`r2'to`r'km*($pp_GDP)/($USDKES*1000000)*p_total_`r2'to`r'km
		gen q_`inst'_`r2'to`r'km = `inst'_`r2'to`r'km + L.`inst'_`r2'to`r'km + L2.`inst'_`r2'to`r'km

	}
}

** Check magnitudes **
bysort market_id: egen actamt_totGDP_0to2km = sum(pp_actamt_0to2km)
sum actamt_totGDP_0to2km
** Markets receive on average 6.1% of annual GDP in their 0to2km buffers, but the distribution ranges from near 0 to 13.5% of annual GDP **
** These numbers lign up with our total numbers **

order actamt_* pp_actamt_* q_actamt_* q_pp_actamt_*, last

foreach inst in actamt  {
	forval r = 2(2)20 {
		local r2 = `r' - 2
		egen cum_`inst'_`r'km = rowtotal(`inst'_0to2km-`inst'_`r2'to`r'km)
		egen q_cum_`inst'_`r'km = rowtotal(q_`inst'_0to2km-q_`inst'_`r2'to`r'km)

		gen cum_pp_`inst'_`r'km = cum_`inst'_`r'km*($USDKES*1000000)/cum_p_total_`r'km/($pp_GDP)
		gen q_cum_pp_`inst'_`r'km = q_cum_`inst'_`r'km*($USDKES*1000000)/cum_p_total_`r'km/($pp_GDP)
	}
}

order actamt_* q_actamt_* cum_actamt_* q_cum_actamt_* pp_actamt_* q_pp_actamt_* cum_pp_actamt_* q_cum_pp_actamt_* /* expamt_* q_expamt_* cum_expamt_* q_cum_expamt_* pp_expamt_* q_pp_expamt_* cum_pp_expamt_* q_cum_pp_expamt_* */, last
drop if month < tm(2014m8)

** Generate lagged instrument measures **
*****************************************
sum month
expand 2 if month == `r(min)', gen(dupl)
replace month = `r(min)'-18 if dupl == 1

expand 2 if month == `r(max)', gen(dupl2)
replace month = `r(max)'+6 if dupl2 == 1

scalar max = `r(max)'

foreach v of varlist pidx_* pidx2_* { //h2* avail* vendor* {
	replace `v' = . if dupl == 1
}

foreach v of varlist n_* m_* amount_*  actamt_* cum_actamt_* pp_actamt_* cum_pp_actamt_*  /* exp_* expamt_* cum_expamt_* pp_expamt_* cum_pp_expamt_* */ q_* {
	replace `v' = 0 if dupl == 1
}

tsfill, full
sort market_id month
bysort market_id: carryforward _all, replace

foreach v of varlist pidx_* pidx2_* { //h2* avail* vendor* {
	replace `v' = . if month > max
}

foreach v of varlist n_* m_* amount_*  actamt_* cum_actamt_* pp_actamt_* cum_pp_actamt_* /*exp_* expamt_* cum_expamt_* pp_expamt_* cum_pp_expamt_* */ q_* {
	replace `v' = 0 if month > max
}

drop dupl dupl2

** Create new variables - cumulative over past 1-18 months **
** Note: pre-treatment-period values are considered zero **
foreach inst in actamt  { //expamt
	forval r = 2(2)20 {
		local r2 = `r' - 2
		forval lag=0(1)18 {
			tsegen tcum_l`lag'_`inst'_`r2'to`r'km = rowtotal(L(0/`lag').`inst'_`r2'to`r'km)
		}
	}
}

foreach inst in actamt  { //expamt
	forval r = 2(2)20 {
		forval lag=0(1)18 {
			tsegen tcum_l`lag'_`inst'_`r'km = rowtotal(L(0/`lag').cum_`inst'_`r'km)
		}
	}
}



foreach inst in pp_actamt  { //pp_expamt
	forval r = 2(2)20 {
		local r2 = `r' - 2
		forval lag=0(1)18 {
			tsegen tcum_l`lag'_`inst'_`r2'to`r'km = rowtotal(L(0/`lag').`inst'_`r2'to`r'km)
			*replace tcum_l`lag'_`inst'_`r'km = tcum_l`lag'_`inst'_`r'km(`lag'+1) // used only if using monthly/quarterly/etc. GDP
		}
	}
}

foreach inst in pp_actamt  { //pp_expamt
	forval r = 2(2)20 {
		forval lag=0(1)18 {
			tsegen tcum_l`lag'_`inst'_`r'km = rowtotal(L(0/`lag').cum_`inst'_`r'km)
			*replace tcum_l`lag'_`inst'_`r'km = tcum_l`lag'_`inst'_`r'km(`lag'+1) // used only if using monthly/quarterly/etc. GDP
		}
	}
}

order tcum*, last sequential
order tcum*to*, last


*** Generate IV measures ***
****************************

forval r = 2(2)20 {
	local r2 = `r' - 2
	bys market_id: egen tot_tcum_l2_pp_actamt_`r2'to`r'km = sum(tcum_l2_pp_actamt_`r2'to`r'km)
	gen tcum_l2_IV_`r2'to`r'km =  share_ge_elig_treat_`r2'to`r'km * (tcum_l2_pp_actamt_`r2'to`r'km / tot_tcum_l2_pp_actamt_`r2'to`r'km)

	bys market_id: egen tot_pp_actamt_`r2'to`r'km = sum(pp_actamt_`r2'to`r'km)
	gen IV_`r2'to`r'km =  share_ge_elig_treat_`r2'to`r'km * (pp_actamt_`r2'to`r'km / tot_pp_actamt_`r2'to`r'km)


}


** Generate market access measures **
preserve
collapse (mean) distroad*, by(market_code)
project, uses("$da/market_radiipop_wide_1km.dta") preserve
merge m:1 market_code using "$da/market_radiipop_wide_1km.dta"
keep market_code p_total* distroad*

bys market_code: keep if _n == 1
rename p_total* p_total_*
rename market_code market_id

egen distroad = rowmin(distroad_a distroad_b distroad_c)
replace distroad = 1/distroad
gen market_access = 0
forval elas = 0.1(0.1)0.5 {
	local elas2 = `elas'*10
	gen market_access_elas_`elas2' = 0
}

forval r = 1(1)10 {
	replace market_access = market_access + (`r' - 0.5)^(-8) * p_total_`r'

	** repeat this for different elasticities of trade costs tau with respect to distance **
	forval elas = 0.1(0.1)0.5 {
		local elas2 = `elas'*10
		local tau = exp(`elas'*ln(`r'))
		replace market_access_elas_`elas2' = market_access_elas_`elas2' + (`tau' - 0.5)^(-8) * p_total_`r'
	}
}

xtile q4_distroad = distroad, n(4)
xtile q4_market_access = market_access, n(4)

forval elas = 0.1(0.1)0.5 {
	local elas2 = `elas'*10
	xtile q4_market_access_elas_`elas2' = market_access_elas_`elas2', n(4)
}

xtile q2_distroad = distroad, n(2)
xtile q2_market_access = market_access, n(2)

forval elas = 0.1(0.1)0.5 {
	local elas2 = `elas'*10
	xtile q2_market_access_elas_`elas2' = market_access_elas_`elas2', n(2)
}

corr distroad market_access
reg distroad market_access // those are strongly correlated - as expected

corr q2_market_access*

keep market_id distroad market_access* q?_*
tempfile temp
save `temp'
restore

merge m:1 market_id using `temp' // all merge
drop _merge

sort market_id month
xtset market_id month
order district location location_code sublocation sublocation_code market_id mkt_*  latitude longitude market_size distroad q2_distroad q4_distroad q2_market_access q4_market_access

save "$da/GE_MarketData_Panel_ECMA.dta", replace
project, creates("$da/GE_MarketData_Panel_ECMA.dta")
