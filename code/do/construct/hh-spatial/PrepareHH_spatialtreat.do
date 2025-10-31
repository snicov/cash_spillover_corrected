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

project, original("$do/programs/run_ge_build_programs.do")
include "$do/programs/run_ge_build_programs.do"

project, original("$dr/GE_Treat_Status_Master.dta")

** Setting up village actual spatial treatment data **
project, uses("$da/village_actualtreat_wide_FINAL.dta") preserve
use "$da/village_actualtreat_wide_FINAL.dta", clear

collapse (first) p_total_* p_eligible_* p_ge_* (sum) /* n_* */ amount_*, by(village_code)
tempfile temp_act
save `temp_act'




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

* Starting from master village-level dataset, then merging in temp files from above
use "$dr/GE_Treat_Status_Master.dta", clear

merge 1:1 village_code using `temp_act', gen(_m_act)

drop if _m_act == 1 // 5 villages not included in final sample

rename amount_total_KES* pp_actamt*
rename *_eligible* *_elig*

rename pp_actamt_0* pp_actamt_*
rename pp_actamt_ov_0* pp_actamt_ov_*
rename p_total_0* p_total_*
rename p_ge_0* p_ge_*
rename p_ge_treat_0* p_ge_treat_*
rename p_ge_elig_0* p_ge_elig_*
rename p_ge_elig_treat_0* p_ge_elig_treat_*
rename p_total_ov_0* p_total_ov_*
rename p_ge_ov_0* p_ge_ov_*
rename p_ge_treat_ov_0* p_ge_treat_ov_*
rename p_ge_elig_ov_0* p_ge_elig_ov_*
rename p_ge_elig_treat_ov_0* p_ge_elig_treat_ov_*

set varabbrev off

forval r = 2(2)8 {
	local r2 = `r' - 2

	desc pp_actamt_*`r2'to*`r'*, full

	rename pp_actamt_`r2'to0`r'km 			pp_actamt_`r2'to`r'km
	rename pp_actamt_ov_`r2'to0`r'km 		pp_actamt_ov_`r2'to`r'km
	rename pp_actamt_`r2'to0`r'km_r 		pp_actamt_`r2'to`r'km_r
	rename pp_actamt_ov_`r2'to0`r'km_r 	pp_actamt_ov_`r2'to`r'km_r
	rename pp_actamt_`r2'to0`r'km_rsa 		pp_actamt_`r2'to`r'km_rsa
	rename pp_actamt_ov_`r2'to0`r'km_rsa 	pp_actamt_ov_`r2'to`r'km_rsa

	rename p_total_`r2'to0`r'km 				p_total_`r2'to`r'km
	rename p_ge_`r2'to0`r'km 						p_ge_`r2'to`r'km
	rename p_ge_treat_`r2'to0`r'km 			p_ge_treat_`r2'to`r'km
	rename p_ge_elig_`r2'to0`r'km 			p_ge_elig_`r2'to`r'km
	rename p_ge_elig_treat_`r2'to0`r'km p_ge_elig_treat_`r2'to`r'km
	rename p_total_ov_`r2'to0`r'km 			p_total_ov_`r2'to`r'km
	rename p_ge_ov_`r2'to0`r'km 				p_ge_ov_`r2'to`r'km
	rename p_ge_elig_ov_`r2'to0`r'km 		p_ge_elig_ov_`r2'to`r'km
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

foreach inst in actamt {
	forval r = 2(2)20 {
		local r2 = `r' - 2

		replace pp_`inst'_`r2'to`r'km = 1/($pp_GDP)*pp_`inst'_`r2'to`r'km // convert to per-capita GDP amounts
		gen `inst'_`r2'to`r'km = pp_`inst'_`r2'to`r'km*($pp_GDP)/($USDKES*1000000)*p_total_`r2'to`r'km // convert to mio. USD

		replace pp_`inst'_`r2'to`r'km_r = 1/($pp_GDP_r)*pp_`inst'_`r2'to`r'km_r // convert to per-capita GDP amounts
		gen `inst'_`r2'to`r'km_r = pp_`inst'_`r2'to`r'km_r*($pp_GDP_r)/($USDKES*1000000)*p_total_`r2'to`r'km // convert to mio. USD
	}
}

foreach inst in actamt_ov {
	forval r = 2(2)20 {
		local r2 = `r' - 2

		replace pp_`inst'_`r2'to`r'km = 1/($pp_GDP)*pp_`inst'_`r2'to`r'km // convert to per-capita GDP amounts
		gen `inst'_`r2'to`r'km = pp_`inst'_`r2'to`r'km*($pp_GDP)/($USDKES*1000000)*p_total_ov_`r2'to`r'km // convert to mio. USD

		replace pp_`inst'_`r2'to`r'km_r = 1/($pp_GDP_r)*pp_`inst'_`r2'to`r'km_r // convert to per-capita GDP amounts
		gen `inst'_`r2'to`r'km_r = pp_`inst'_`r2'to`r'km_r*($pp_GDP_r)/($USDKES*1000000)*p_total_ov_`r2'to`r'km // convert to mio. USD
	}
}

foreach inst in actamt {
	forval r = 2(2)20 {
		local r2 = `r' - 2
		egen cum_`inst'_`r'km = rowtotal(`inst'_0to2km-`inst'_`r2'to`r'km)
		gen cum_pp_`inst'_`r'km = cum_`inst'_`r'km*($USDKES*1000000)/cum_p_total_`r'km/($pp_GDP)

		egen cum_`inst'_`r'km_r = rowtotal(`inst'_0to2km_r-`inst'_`r2'to`r'km_r)
		gen cum_pp_`inst'_`r'km_r = cum_`inst'_`r'km_r*($USDKES*1000000)/cum_p_total_`r'km/($pp_GDP_r)
	}
}

foreach inst in actamt_ov {
	forval r = 2(2)20 {
		local r2 = `r' - 2
		egen cum_`inst'_`r'km = rowtotal(`inst'_0to2km-`inst'_`r2'to`r'km)
		gen cum_pp_`inst'_`r'km = cum_`inst'_`r'km*($USDKES*1000000)/cum_p_total_ov_`r'km/($pp_GDP)

		egen cum_`inst'_`r'km_r = rowtotal(`inst'_0to2km_r-`inst'_`r2'to`r'km_r)
		gen cum_pp_`inst'_`r'km_r = cum_`inst'_`r'km_r*($USDKES*1000000)/cum_p_total_ov_`r'km/($pp_GDP_r)
	}
}

keep sublocation_code village_code treat hi_sat *p_total_* *p_elig* *p_ge_* *share_elig* *share_ge_* actamt_* cum_actamt_* pp_actamt_* cum_pp_actamt_*

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


** Saving dasaset **
save "$dt/Village_spatialtreat_forHH.dta", replace
project, creates("$dt/Village_spatialtreat_forHH.dta")
