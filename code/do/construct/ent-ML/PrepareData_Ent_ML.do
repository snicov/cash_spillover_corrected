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

set varabbrev on

*	Author: Francis Wong
*	Date: August 16, 2016
*	This do file will call all the others for the purpose of constructing the
*		the enterprise survey data set
*
* INPUTS:
*   - raw enterprise phone survey data
*   - village-level treatment status data
*   - treatment density data for enterprises (should be run before this)
*
*  OUTPUT:
*   - 2 analysis datasets that contain outcome data and treatment status. One version is in wide
*     format and the other is in long format.
*
* 	Last modified: 19 Dec 2016: incorporating merges of treatment status datasets for analysis.
*       - 13 Dec 2016 by Michael Walker: basing combining rounds off of an updated
*    	phone survey dataset that adds in village codes and incorporates checks for some
*		duplicates identified as part of the data analysis and endline surveys.

/**** AMOUNT OF MONEY TRANSFERRED INTO TREATMENT VILLAGES OVER THE STUDY PERIOD ****/
project, uses("$dt/GE_experimental_timing_long_FINAL.dta")
use "$dt/GE_experimental_timing_long_FINAL.dta", clear

keep if month <= tm(2016m4) // keeping pre and period of phone surveys
gen pre = (month < tm(2015m8))
collapse (sum) amount_total_KES, by(village_code pre )
reshape wide amount_total_KES, i(village_code) j(pre)

ren amount_total_KES0 amount_total_KES_pre
ren amount_total_KES1 amount_total_KES

tempfile amounts
save `amounts'

* Start date for wide
project, uses("$dt/GE_experimental_timing_long_FINAL.dta")
use "$dt/GE_experimental_timing_long_FINAL.dta", clear
keep village_code exp_start_1
bys village_code: keep if _n==1

tempfile startdt
save `startdt'

* start date for long
project, uses("$dt/GE_experimental_timing_long_FINAL.dta")
use "$dt/GE_experimental_timing_long_FINAL.dta", clear
keep village_code month exp_start_1
keep if month < tm(2016m7)
bys village_code month: keep if _n==1


tempfile startlong
save `startlong'


/* Merge in treatment status - WIDE */
project, original("$dr/GE_ENT-Prices-ML_PUBLIC.dta")
use "$dr/GE_ENT-Prices-ML_PUBLIC.dta", clear

gen village_code_str = village_code
destring village_code, replace

cap drop treat hi_sat

project, original("$dr/GE_Treat_Status_Master.dta") preserve
merge n:1 village_code using "$dr/GE_Treat_Status_Master.dta", keepusing(treat hi_sat satlevel_name ge_village_order) gen(_merge_vt)
tab _merge_vt
keep if _merge_vt == 3 // all in master should merge. Will be some in using that do not merge due to no enterprises in those villages. Checks as fo 12/20 2:15 PM
drop _merge_vt

codebook treat hi_sat

* Merging in experimental start date
merge n:1 village_code using `startdt'

keep if _merge==3
drop _merge


** merge in enterprise universe id **
*************************************
preserve
project, original("$dr/GE_ENT-SampleMaster_PUBLIC.dta") preserve
use "$dr/GE_ENT-SampleMaster_PUBLIC.dta", clear
keep if call_rank_ML != .
keep *universe* call_rank_ML

** some are duplicate -- this is where one BL enterprise may match to two ML.
** take a random one **
gen a = runiform()
bys call_rank_ML (a): drop if _n > 1
drop a
tempfile temp
save `temp'
restore

ren call_rank call_rank_ML
merge 1:1 call_rank_ML using `temp' // all merge
drop _merge


** Generate enterprise sampling weights **
******************************************

** We sampled all enterprises operating outside the homestead -- they get sampling weight == 1 **
** Those are identified by having an ent_id **
tab s1_q3_operatefrom if ent_id == ., m
gen entweight_ML = 1 if ent_id != .

** For those operating within the homestead, we have a random sample **
** We sampled randomly within sublocation across all business types in our 4 categories **
preserve
project, uses("$da/GE_HH-ENT_Baseline_Combined.dta")
use "$da/GE_HH-ENT_Baseline_Combined.dta", clear
keep if HH_ENT_CEN_BL_date != .
tab HH_ENT_CEN_BL_operate_from // for sampling, only those within homestead where used
keep if HH_ENT_CEN_BL_operate_from == 1

tab HH_ENT_CEN_BL_bizcat
keep if inlist(HH_ENT_CEN_BL_bizcat,2,9,15,17)

gen primary_bizcat = "hardware" if HH_ENT_CEN_BL_bizcat == 9
replace primary_bizcat = "posho" if HH_ENT_CEN_BL_bizcat == 17
replace primary_bizcat = "sretail" if HH_ENT_CEN_BL_bizcat == 2
replace primary_bizcat = "tailor" if HH_ENT_CEN_BL_bizcat == 15

gen n_ent = 1
collapse (sum) n_ent, by(subcounty)
*collapse (sum) n_ent, by(subcounty primary_bizcat)
*drop if primary_bizcat == ""
*tab primary_bizcat
tempfile nent
save `nent', replace
restore

merge m:1 subcounty using `nent' // all merge
drop _merge
*merge m:1 subcounty primary_bizcat using `nent'

** define weight as inverse sampling weight **
gen a = 1 if ent_id == .
bys subcounty: egen n_sample = sum(a)
drop a

replace entweight_ML = n_ent / n_sample if ent_id == .
drop n_ent n_sample

** Across all enterprises, we sampled 25% of those initially missed for intensive tracking
** those get a weight that is 4 times as high **
replace entweight_ML = entweight_ML * sampwt

keep *universe* call_rank_ML entweight_ML
tempfile weightdta
save `weightdta', replace

/* Merge in treatment status - LONG */
project, original("$dr/GE_ENT-Prices-ML_PUBLIC.dta")
use "$dr/GE_ENT-Prices-ML_PUBLIC.dta", clear

** Reshape to long format **
reshape long  p_tailor_ p_grind1kg_ , i(call_rank) j(month) string

tab month
ren month month_str
gen month = monthly(month_str, "M20Y")
format month %tm


la var p_tailor_ "Tailor prices (simple patch)"
la var p_grind1kg_ "Price of grinding 1kg of maize"

** Generate log prices **
gen ln_p_tailor = ln(p_tailor_)
gen ln_p_grind1kg = ln(p_grind1kg)


** merge in weights **
ren call_rank call_rank_ML
merge m:1 call_rank_ML using `weightdta'
drop if _merge == 2
drop _merge // all from master merge
order ent_key_universe ent_id_universe call_rank_ML entweight_ML

project, original("$dr/GE_Treat_Status_Master.dta") preserve
merge n:1 village_code using "$dr/GE_Treat_Status_Master.dta", keepusing(treat hi_sat satlevel_name ge_village_order) gen(_merge_vt)
tab _merge_vt
keep if _merge_vt == 3 // all in master should merge. Will be some in using that do not merge due to no enterprises in those villages.
drop _merge _merge_vt


cap drop _merge

merge n:1 village_code using `amounts'
keep if _merge == 3
drop _merge

merge n:1 village_code month using `startlong'
drop if _merge == 2 // all from master should match
drop _merge


** Merge in dynamic treatment amounts **
****************************************

** generate full time series **
tab month
sum month
local minmonth = `r(min)'
expand 2 if month == `r(min)', gen(dupl)
replace month = `r(min)' - 18 if dupl == 1

foreach v of varlist p_* ln_p_* {
	replace `v' = . if dupl == 1
}

tsset call_rank month
tsfill, full
sort call_rank month
bysort call_rank: carryforward _all, replace
drop dupl

sort village_code call_rank month
project, uses("$da/village_actualtreat_wide_FINAL.dta") preserve
merge m:1 village_code month using "$da/village_actualtreat_wide_FINAL.dta"

tab month if _merge == 1 // these are all pre-treatment
** set pre-treatment to zero **
foreach v of varlist n_* amount_* {
	replace `v' = 0 if _merge == 1
}

drop if _merge == 2 // those are villages not contained in our midline survey or months after the end of the midline survey
drop _merge

foreach v of var p_total_ownvill p_eligible_ownvill amount_total_KES_ownvill n_token_ownvill p_total_??to??km p_ge_??to??km p_ge_treat_??to??km p_ge_eligible_??to??km p_ge_eligible_treat_??to??km p_total_ov_??to??km p_ge_ov_??to??km p_ge_treat_ov_??to??km p_ge_eligible_ov_??to??km p_ge_eligible_treat_ov_??to??km {
	bys call_rank: egen a = mean(`v')
	replace `v' = a
	drop a
}

sort call_rank month
tab month
tab call_rank
tab village_code

*** Generate final treatment measures **
****************************************
rename *_eligible* *_elig*
rename amount_total_KES* pp_actamt*

rename pp_actamt_0* pp_actamt_*
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
	rename pp_actamt_`r2'to0`r'km pp_actamt_`r2'to`r'km
	rename p_total_`r2'to0`r'km p_total_`r2'to`r'km
	rename p_ge_`r2'to0`r'km p_ge_`r2'to`r'km
	rename p_ge_elig_`r2'to0`r'km p_ge_elig_`r2'to`r'km
	rename p_ge_elig_treat_`r2'to0`r'km p_ge_elig_treat_`r2'to`r'km
	rename p_total_ov_`r2'to0`r'km p_total_ov_`r2'to`r'km
	rename p_ge_ov_`r2'to0`r'km p_ge_ov_`r2'to`r'km
	rename p_ge_elig_ov_`r2'to0`r'km p_ge_elig_ov_`r2'to`r'km
	rename p_ge_elig_treat_ov_`r2'to0`r'km p_ge_elig_treat_ov_`r2'to`r'km
}

** generate instruments **
**************************
gen share_elig_ownvill = p_elig_ownvill/p_total_ownvill

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

order p_total_ownvill p_elig_ownvill share_elig_ownvill p_total_?to* p_total_??to* p_ge_?to* p_ge_??to* p_ge_elig_?to* p_ge_elig_??to* p_ge_elig_treat_?to* p_ge_elig_treat_??to* p_total_ov_* p_ge_ov_* p_ge_elig_ov_* p_ge_elig_treat_ov_* share_ge_elig_?to* share_ge_elig_??to* share_ge_elig_treat_?to* share_ge_elig_treat_??to* share_ge_elig_ov_?to* share_ge_elig_ov_??to* share_ge_elig_treat_ov_?to* share_ge_elig_treat_ov_??to* cum_p_total_?km cum_p_total_??km cum_p_ge_?km cum_p_ge_??km cum_p_ge_elig_?km cum_p_ge_elig_??km cum_p_ge_elig_treat_?km cum_p_ge_elig_treat_??km cum_p_total_ov_?km cum_p_total_ov_??km cum_p_ge_ov_?km cum_p_ge_ov_??km cum_p_ge_elig_ov_?km cum_p_ge_elig_ov_??km cum_p_ge_elig_treat_ov_?km cum_p_ge_elig_treat_ov_??km cum_share_ge_elig_?km cum_share_ge_elig_??km cum_share_ge_elig_treat_?km cum_share_ge_elig_treat_??km cum_share_ge_elig_ov_* cum_share_ge_elig_treat_ov_*, last


** generate quarterly instrument measures **
********************************************
foreach inst in actamt {
	forval r = 2(2)20 {
		local r2 = `r' - 2

		replace pp_`inst'_`r2'to`r'km = 1/($pp_GDP)*pp_`inst'_`r2'to`r'km
		gen q_pp_`inst'_`r2'to`r'km = (pp_`inst'_`r2'to`r'km + L.pp_`inst'_`r2'to`r'km + L2.pp_`inst'_`r2'to`r'km)

		gen `inst'_`r2'to`r'km = pp_`inst'_`r2'to`r'km*($pp_GDP)/($USDKES*1000000)*p_total_`r2'to`r'km
		gen q_`inst'_`r2'to`r'km = `inst'_`r2'to`r'km + L.`inst'_`r2'to`r'km + L2.`inst'_`r2'to`r'km

	}
}


** Check magnitudes **
bysort call_rank: egen actamt_totGDP_0to2km = sum(pp_actamt_0to2km)
sum actamt_totGDP_0to2km
** Enterprises receive on average 8.4% of annual GDP in their 0to2km buffers, but the distribution ranges from near 0 to 24% of annual GDP **
** These numbers lign up with our total numbers **
drop actamt_totGDP_0to2km

order actamt_* pp_actamt_* q_actamt_* q_pp_actamt_*, last

foreach inst in actamt {
	forval r = 2(2)20 {
		local r2 = `r' - 2
		egen cum_`inst'_`r'km = rowtotal(`inst'_0to2km-`inst'_`r2'to`r'km)
		egen q_cum_`inst'_`r'km = rowtotal(q_`inst'_0to2km-q_`inst'_`r2'to`r'km)

		gen cum_pp_`inst'_`r'km = cum_`inst'_`r'km*($USDKES*1000000)/cum_p_total_`r'km/($pp_GDP)
		gen q_cum_pp_`inst'_`r'km = q_cum_`inst'_`r'km*($USDKES*1000000)/cum_p_total_`r'km/($pp_GDP)
	}
}

order actamt_* q_actamt_* cum_actamt_* q_cum_actamt_* pp_actamt_* q_pp_actamt_* cum_pp_actamt_* q_cum_pp_actamt_*, last

** Generate lagged instrument measures **
*****************************************
foreach inst in actamt {
	forval r = 2(2)20 {
		local r2 = `r' - 2
		forval lag=0(1)18 {
			tsegen tcum_l`lag'_`inst'_`r2'to`r'km = rowtotal(L(0/`lag').`inst'_`r2'to`r'km)
		}
	}
}

foreach inst in actamt {
	forval r = 2(2)20 {
		forval lag=0(1)18 {
			tsegen tcum_l`lag'_`inst'_`r'km = rowtotal(L(0/`lag').cum_`inst'_`r'km)
		}
	}
}

foreach inst in pp_actamt {
	forval r = 2(2)20 {
		local r2 = `r' - 2
		forval lag=0(1)18 {
			tsegen tcum_l`lag'_`inst'_`r2'to`r'km = rowtotal(L(0/`lag').`inst'_`r2'to`r'km)
			}
	}
}

foreach inst in pp_actamt {
	forval r = 2(2)20 {
		forval lag=0(1)18 {
			tsegen tcum_l`lag'_`inst'_`r'km = rowtotal(L(0/`lag').cum_`inst'_`r'km)
			}
	}
}

order tcum*, last sequential
order tcum*to*, last

** Generate market access measures **
preserve
project, uses("$da/village_radiipop_wide_1km.dta")
use "$da/village_radiipop_wide_1km.dta", clear
keep village_code p_total*
bys village_code: keep if _n == 1
rename p_total* p_total_*

gen market_access = 0
forval r = 1(1)10 {
	replace market_access = market_access + (`r' - 0.5)^(-8) * p_total_`r'
}

xtile q4_market_access = market_access, n(4)
xtile q2_market_access = market_access, n(2)

keep village_code market_access q?_*
tempfile temp
save `temp'
restore

merge m:1 village_code using `temp' // all merge
drop if _merge == 2
drop _merge

** Generate month, village and enterprise dummies **
levelsof month, local(mths)
foreach month in `mths' {
	gen m_`month' = (month == `month')
}

levelsof village_code, local(vils)
foreach vil in `vils' {
	gen v_`vil' = (village_code == `vil')
}

levelsof call_rank, local(ents)
foreach ent in `ents' {
	gen entid_`ent' = (call_rank == `ent')
}

** Clean up and Save **

sort village_code call_rank month
xtset call_rank month
order call_rank month month_str subcounty sublocation_code village_code *universe* ent_id fr_id sampwt entweight* /*primary_bizcat prim_sretail prim_posho prim_hardware prim_tailor*/ market_access q4_market_access q2_market_access

** order treatment variables **
*******************************

save "$da/Ent_ML_SpatialData_long_FINAL.dta", replace
project, creates("$da/Ent_ML_SpatialData_long_FINAL.dta")
