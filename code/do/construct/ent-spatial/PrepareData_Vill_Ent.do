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

project, uses("$da/pp_GDP_calculated.dta")
use "$da/pp_GDP_calculated.dta", clear
global pp_GDP = pp_GDP[1]
global pp_GDP_r = pp_GDP_r[1]
clear

// end preliminaries
do "$do/programs/run_ge_build_programs.do"


*************************
** 0. Data Preparation **
*************************
project, uses("$da/GE_ENT-Analysis_AllENTs.dta")
use "$da/GE_ENT-Analysis_AllENTs.dta", clear

** generate village totals **
*****************************
foreach v of var * {
	cap: local l`v' : variable label `v'
		if `"`l`v''"' == "" {
		cap: local l`v' "`v'"
	}
}

bys village_code: egen sample_from_hh = sum(operates_from_hh)
bys village_code: egen sample_outside_hh = sum(operates_outside_hh)
bys village_code: egen sample_ent_ownfarm = sum(ent_ownfarm)

drop if entcode_EL != . & operates_from_hh == . // we don't know their location
collapse (mean) avgdate_vill sample_* n_allents* n_operates_* n_ent_ownfarm* n_ent_elig* n_ent_inelig* n_ent_treat* n_ent_untreat* ent_profitmargin* (sum) ent_profit1* ent_profit2* ent_revenue1* ent_revenue2* ent_totaltaxes* ent_wagebill* ent_inv ent_inv_* ent_inventory* ent_rent* ent_security* ent_totcost*, by(sublocation_code village_code hi_sat treat ent_type operates_from_hh ent_ownfarm)

foreach v of var ent_profit1* ent_profit2* ent_revenue1* ent_revenue2* ent_totaltaxes* ent_wagebill* ent_inv ent_inv_* ent_inventory* ent_rent* ent_security* ent_totcost* {
	gen a_`v' = `v'/sample_from_hh*n_operates_from_hh if operates_from_hh == 1
	replace a_`v' = `v'/sample_outside_hh*n_operates_outside_hh if operates_from_hh == 0
	replace a_`v' = `v'/sample_ent_ownfarm*n_ent_ownfarm if ent_ownfarm == 1
}

bys village_code: egen a_ent_profitmargin1 = wtmean(ent_profitmargin1), weight(a_ent_revenue1)
bys village_code: egen a_ent_profitmargin1_wins = wtmean(ent_profitmargin1_wins), weight(a_ent_revenue1_wins)
bys village_code: egen a_ent_profitmargin1_wins_PPP = wtmean(ent_profitmargin1_wins_PPP), weight(a_ent_revenue1_wins_PPP)

bys village_code: egen a_ent_profitmargin2 = wtmean(ent_profitmargin2), weight(a_ent_revenue2)
bys village_code: egen a_ent_profitmargin2_wins = wtmean(ent_profitmargin2_wins), weight(a_ent_revenue2_wins)
bys village_code: egen a_ent_profitmargin2_wins_PPP = wtmean(ent_profitmargin2_wins_PPP), weight(a_ent_revenue2_wins_PPP)

collapse (mean) avgdate_vill sample_* n_allents* n_operates_* n_ent_ownfarm* n_ent_elig* n_ent_inelig* n_ent_treat* n_ent_untreat* ent_profitmargin* (sum) a_ent_profit1* a_ent_profit2* a_ent_revenue1* a_ent_revenue2* a_ent_totaltaxes* a_ent_wagebill* a_ent_inv a_ent_inv_* a_ent_inventory* a_ent_rent* a_ent_security* a_ent_totcost*, by(sublocation_code village_code hi_sat treat)
drop if treat == .
ren a_ent_* ent_*
foreach v of var * {
        capture: label var `v' "`l`v''"
}
ren ent_* vill_*


************************************
** Add shares going to each group **
************************************
/*
** TODO: Attribute shares of profits / revenues / costs to each group by ownership **
foreach v of var n_allents n_operates_* vill_* {
	gen `v'_st = 1/6
	gen `v'_sut = 5/6
}
*/

*****************************************
** Generate spatial treatment measures **
*****************************************

** Merge with village actual spatial treatment data **
preserve
project, uses("$da/village_actualtreat_wide_FINAL.dta")
use "$da/village_actualtreat_wide_FINAL.dta", clear
collapse (first) p_total_* p_eligible_* p_ge_* (sum) /* n_* */ amount_*, by(village_code)
tempfile temp
save `temp'
restore

merge m:1 village_code using `temp'
drop _merge // all merge


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
rename *_eligible* *_elig*

rename pp_actamt_0* pp_actamt_*
rename pp_actamt_ov_0* pp_actamt_ov_*
rename p_total_0* p_total_*
rename p_ge_0* p_ge_*
rename p_ge_elig_0* p_ge_elig_*
rename p_ge_elig_treat_0* p_ge_elig_treat_*
rename p_total_ov_0* p_total_ov_*
rename p_ge_ov_0* p_ge_ov_*
rename p_ge_elig_ov_0* p_ge_elig_ov_*
rename p_ge_elig_treat_ov_0* p_ge_elig_treat_ov_*

forval r = 2(2)8 {
	local r2 = `r' - 2
	rename pp_actamt_`r2'to0`r'km 			pp_actamt_`r2'to`r'km
	rename pp_actamt_ov_`r2'to0`r'km 		pp_actamt_ov_`r2'to`r'km
	rename pp_actamt_`r2'to0`r'km_r 		pp_actamt_`r2'to`r'km_r
	rename pp_actamt_ov_`r2'to0`r'km_r 	pp_actamt_ov_`r2'to`r'km_r
	rename pp_actamt_`r2'to0`r'km_rsa 		pp_actamt_`r2'to`r'km_rsa
	rename pp_actamt_ov_`r2'to0`r'km_rsa 	pp_actamt_ov_`r2'to`r'km_rsa

	rename p_total_`r2'to0`r'km p_total_`r2'to`r'km
	rename p_ge_`r2'to0`r'km p_ge_`r2'to`r'km
	rename p_ge_elig_`r2'to0`r'km p_ge_elig_`r2'to`r'km
	rename p_ge_elig_treat_`r2'to0`r'km p_ge_elig_treat_`r2'to`r'km
	rename p_total_ov_`r2'to0`r'km p_total_ov_`r2'to`r'km
	rename p_ge_ov_`r2'to0`r'km p_ge_ov_`r2'to`r'km
	rename p_ge_elig_ov_`r2'to0`r'km p_ge_elig_ov_`r2'to`r'km
	rename p_ge_elig_treat_ov_`r2'to0`r'km p_ge_elig_treat_ov_`r2'to`r'km
}


** generate treatment measures **
*********************************

** own village **
*****************
gen share_elig_ownvill = p_elig_ownvill/p_total_ownvill

replace pp_actamt_ownvill = 1/($pp_GDP)*pp_actamt_ownvill // convert to per-capita GDP amounts
gen actamt_ownvill = pp_actamt_ownvill*($pp_GDP)/($USDKES*1000000)*p_total_ownvill // convert to mio. USD

replace pp_actamt_ownvill_r = 1/($pp_GDP_r)*pp_actamt_ownvill_r // convert to per-capita GDP amounts
gen actamt_ownvill_r = pp_actamt_ownvill_r*($pp_GDP_r)/($USDKES*1000000)*p_total_ownvill // convert to mio. USD

** overall and other villages **
********************************
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

forval r = 2(2)20 {
	local r2 = `r' - 2

	gen share_ge_elig_ov_`r2'to`r'km = p_ge_elig_ov_`r2'to`r'km/p_total_ov_`r2'to`r'km
	gen share_ge_elig_treat_ov_`r2'to`r'km = p_ge_elig_treat_ov_`r2'to`r'km/p_ge_elig_ov_`r2'to`r'km
	replace share_ge_elig_treat_ov_`r2'to`r'km = 0 if p_ge_elig_ov_`r2'to`r'km == 0 // setting to zero if no eligibles in radi range

	egen cum_p_total_ov_`r'km = rowtotal(p_total_ov_0to2km-p_total_ov_`r2'to`r'km)
	egen cum_p_ge_ov_`r'km = rowtotal(p_ge_ov_0to2km-p_ge_ov_`r2'to`r'km)
	egen cum_p_ge_elig_ov_`r'km = rowtotal(p_ge_elig_ov_0to2km-p_ge_elig_ov_`r2'to`r'km)
	egen cum_p_ge_elig_treat_ov_`r'km = rowtotal(p_ge_elig_treat_ov_0to2km-p_ge_elig_treat_ov_`r2'to`r'km)

	gen cum_share_ge_elig_ov_`r'km = cum_p_ge_elig_ov_`r'km/cum_p_total_ov_`r'km
	gen cum_share_ge_elig_treat_ov_`r'km = cum_p_ge_elig_treat_ov_`r'km/cum_p_ge_elig_ov_`r'km
}

foreach inst in actamt  {
	forval r = 2(2)20 {
		local r2 = `r' - 2

		replace pp_`inst'_`r2'to`r'km = 1/($pp_GDP)*pp_`inst'_`r2'to`r'km // convert to per-capita GDP amounts
		gen `inst'_`r2'to`r'km = pp_`inst'_`r2'to`r'km*($pp_GDP)/($USDKES*1000000)*p_total_`r2'to`r'km // convert to mio. USD

		replace pp_`inst'_`r2'to`r'km_r = 1/($pp_GDP_r)*pp_`inst'_`r2'to`r'km_r // convert to per-capita GDP amounts
		gen `inst'_`r2'to`r'km_r = pp_`inst'_`r2'to`r'km_r*($pp_GDP_r)/($USDKES*1000000)*p_total_`r2'to`r'km // convert to mio. USD
	}
}

foreach inst in actamt_ov  {
	forval r = 2(2)20 {
		local r2 = `r' - 2

		replace pp_`inst'_`r2'to`r'km = 1/($pp_GDP)*pp_`inst'_`r2'to`r'km // convert to per-capita GDP amounts
		gen `inst'_`r2'to`r'km = pp_`inst'_`r2'to`r'km*($pp_GDP)/($USDKES*1000000)*p_total_ov_`r2'to`r'km // convert to mio. USD

		replace pp_`inst'_`r2'to`r'km_r = 1/($pp_GDP_r)*pp_`inst'_`r2'to`r'km_r // convert to per-capita GDP amounts
		gen `inst'_`r2'to`r'km_r = pp_`inst'_`r2'to`r'km_r*($pp_GDP_r)/($USDKES*1000000)*p_total_ov_`r2'to`r'km // convert to mio. USD
	}
}

foreach inst in actamt  {
	forval r = 2(2)20 {
		local r2 = `r' - 2
		egen cum_`inst'_`r'km = rowtotal(`inst'_0to2km-`inst'_`r2'to`r'km)
		gen cum_pp_`inst'_`r'km = cum_`inst'_`r'km*($USDKES*1000000)/cum_p_total_`r'km/($pp_GDP)

		egen cum_`inst'_`r'km_r = rowtotal(`inst'_0to2km_r-`inst'_`r2'to`r'km_r)
		gen cum_pp_`inst'_`r'km_r = cum_`inst'_`r'km_r*($USDKES*1000000)/cum_p_total_`r'km/($pp_GDP_r)
	}
}

foreach inst in actamt_ov  {
	forval r = 2(2)20 {
		local r2 = `r' - 2
		egen cum_`inst'_`r'km = rowtotal(`inst'_0to2km-`inst'_`r2'to`r'km)
		gen cum_pp_`inst'_`r'km = cum_`inst'_`r'km*($USDKES*1000000)/cum_p_total_ov_`r'km/($pp_GDP)

		egen cum_`inst'_`r'km_r = rowtotal(`inst'_0to2km_r-`inst'_`r2'to`r'km_r)
		gen cum_pp_`inst'_`r'km_r = cum_`inst'_`r'km_r*($USDKES*1000000)/cum_p_total_ov_`r'km/($pp_GDP_r)
	}
}


drop *p_ge_treat_*

** Order variables **

** Order people variables **
order p_total_ownvill, last
order p_total_?to?km p_total_?to??km p_total_??to??km, last sequential
order p_total_ov_?to?km p_total_ov_?to??km p_total_ov_??to??km, last sequential

order cum_p_total_?km cum_p_total_??km, last sequential
order cum_p_total_ov_?km cum_p_total_ov_??km, last sequential

order p_ge_?to?km p_ge_?to??km p_ge_??to??km, last sequential
order p_ge_ov_?to?km p_ge_ov_?to??km p_ge_ov_??to??km, last sequential

order cum_p_ge_?km cum_p_ge_??km, last sequential
order cum_p_ge_ov_?km cum_p_ge_ov_??km, last sequential

order p_elig_ownvill, last
order p_ge_elig_?to?km p_ge_elig_?to??km p_ge_elig_??to??km, last sequential
order p_ge_elig_ov_?to?km p_ge_elig_ov_?to??km p_ge_elig_ov_??to??km, last sequential

order cum_p_ge_elig_?km cum_p_ge_elig_??km, last sequential
order cum_p_ge_elig_ov_?km cum_p_ge_elig_ov_??km, last sequential

order p_elig_ownvill, last
order p_ge_elig_treat_?to?km p_ge_elig_treat_?to??km p_ge_elig_treat_??to??km, last sequential
order p_ge_elig_treat_ov_?to?km p_ge_elig_treat_ov_?to??km p_ge_elig_treat_ov_??to??km, last sequential

order cum_p_ge_elig_treat_?km cum_p_ge_elig_treat_??km, last sequential
order cum_p_ge_elig_treat_ov_?km cum_p_ge_elig_treat_ov_??km, last sequential

** order share of people variables **
order share_elig_ownvill, last
order share_ge_elig_?to?km share_ge_elig_?to??km share_ge_elig_??to??km, last sequential
order share_ge_elig_ov_?to?km share_ge_elig_ov_?to??km share_ge_elig_ov_??to??km, last sequential

order cum_share_ge_elig_?km cum_share_ge_elig_??km, last sequential
order cum_share_ge_elig_ov_?km cum_share_ge_elig_ov_??km, last sequential

order share_ge_elig_treat_?to?km share_ge_elig_treat_?to??km share_ge_elig_treat_??to??km, last sequential
order share_ge_elig_treat_ov_?to?km share_ge_elig_treat_ov_?to??km share_ge_elig_treat_ov_??to??km, last sequential

order cum_share_ge_elig_treat_?km cum_share_ge_elig_treat_??km, last sequential
order cum_share_ge_elig_treat_ov_?km cum_share_ge_elig_treat_ov_??km, last sequential

** order actual amount variables **
order actamt_ownvill, last
order actamt_?to?km actamt_?to??km actamt_??to??km, last sequential
order actamt_ov_?to?km actamt_ov_?to??km actamt_ov_??to??km, last sequential
order cum_actamt_?km cum_actamt_??km, last sequential
order cum_actamt_ov_?km cum_actamt_ov_??km, last sequential

order pp_actamt_ownvill, last
order pp_actamt_?to?km pp_actamt_?to??km pp_actamt_??to??km, last sequential
order pp_actamt_ov_?to?km pp_actamt_ov_?to??km pp_actamt_ov_??to??km, last sequential
order cum_pp_actamt_?km cum_pp_actamt_??km, last sequential
order cum_pp_actamt_ov_?km cum_pp_actamt_ov_??km, last sequential

** real versions **
order actamt_ownvill_r, last
order actamt_?to?km_r actamt_?to??km_r actamt_??to??km_r, last sequential
order actamt_ov_?to?km_r actamt_ov_?to??km_r actamt_ov_??to??km_r, last sequential
order cum_actamt_?km_r cum_actamt_??km_r, last sequential
order cum_actamt_ov_?km_r cum_actamt_ov_??km_r, last sequential

order pp_actamt_ownvill_r, last
order pp_actamt_?to?km_r pp_actamt_?to??km_r pp_actamt_??to??km_r, last sequential
order pp_actamt_ov_?to?km_r pp_actamt_ov_?to??km_r pp_actamt_ov_??to??km_r, last sequential
order cum_pp_actamt_?km_r cum_pp_actamt_??km_r, last sequential
order cum_pp_actamt_ov_?km_r cum_pp_actamt_ov_??km_r, last sequential

order pp_actamt_ownvill_rsa, last
order pp_actamt_?to?km_rsa pp_actamt_?to??km_rsa pp_actamt_??to??km_rsa, last sequential
order pp_actamt_ov_?to?km_rsa pp_actamt_ov_?to??km_rsa pp_actamt_ov_??to??km_rsa, last sequential



order sublocation_code village_code hi_sat treat
save "$da/GE_VillageLevel_ECMA.dta", replace
project, creates("$da/GE_VillageLevel_ECMA.dta")
