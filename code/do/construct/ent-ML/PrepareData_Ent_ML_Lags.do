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
clear matrix
set maxvar 32000

project, uses("$da/pp_GDP_calculated.dta")
use "$da/pp_GDP_calculated.dta", clear
global pp_GDP = pp_GDP[1]
global pp_GDP_r = pp_GDP_r[1]
clear

// end preliminaries

set varabbrev on

*******************
* Creating Spatial Dataset with Time Dimension
* Date: 2019-04-16
* Author: Tilman Graff
*******************

************************
* Import Actual Treat **
************************
project, uses("$da/village_actualtreat_wide_FINAL.dta")
use "$da/village_actualtreat_wide_FINAL.dta", clear

** for now, I only keep the 0-2km buffer and do not run the BIC on spatial donuts later. This can be altered.
keep village_code month n_token_ownvill n_token_* amount_total_KES_ownvill* amount_total_KES_* p_ge*

rename *0?to??km *?to??km
rename *0?to??km_r *?to??km_r
rename *0?to??km_rsa *?to??km_rsa
rename *to0?km *to?km
rename *to0?km_r *to?km_r
rename *to0?km_rsa *to?km_rsa

rename amount_total_KES* pp_actamt*
foreach v of var pp_actamt_ownvill pp_actamt_?to?km pp_actamt_?to??km pp_actamt_??to??km pp_actamt_ov_?to?km pp_actamt_ov_?to??km pp_actamt_ov_??to??km {
	replace `v' = 1/($pp_GDP)*`v'
}

foreach v of var pp_actamt_ownvill_r pp_actamt_?to?km_r pp_actamt_?to??km_r pp_actamt_??to??km_r pp_actamt_ov_?to?km_r pp_actamt_ov_?to??km_r pp_actamt_ov_??to??km_r {
	replace `v' = 1/($pp_GDP_r)*`v'
}

rename *_eligible* *_elig*

bys village_code: egen tot_n_token_ownvill = sum(n_token_ownvill)
bys village_code: egen tot_pp_actamt_ownvill = sum(pp_actamt_ownvill)
bys village_code: egen tot_pp_actamt_ownvill_rsa = sum(pp_actamt_ownvill_rsa)

gen share_token_ownvill = n_token_ownvill / tot_n_token_ownvill
gen share_actamt_ownvill = pp_actamt_ownvill / tot_pp_actamt_ownvill
gen share_actamt_ownvill_r = pp_actamt_ownvill_rsa / tot_pp_actamt_ownvill_rsa // use deflator across entire study area to abstract from endogenous price responses

forval r = 2(2)10 {
	local r2 = `r' - 2
	gen share_ge_elig_treat_`r2'to`r'km = p_ge_elig_treat_`r2'to`r'km/p_ge_elig_`r2'to`r'km
	gen share_ge_elig_treat_ov_`r2'to`r'km = p_ge_elig_treat_ov_`r2'to`r'km/p_ge_elig_ov_`r2'to`r'km
  replace share_ge_elig_treat_ov_`r2'to`r'km = 0 if p_ge_elig_ov_`r2'to`r'km == 0 // setting to zero if no eligibles in radi range

	bys village_code: egen tot_n_token_`r2'to`r'km = sum(n_token_`r2'to`r'km)
	bys village_code: egen tot_n_token_ov_`r2'to`r'km = sum(n_token_ov_`r2'to`r'km)

	bys village_code: egen tot_pp_actamt_`r2'to`r'km = sum(pp_actamt_`r2'to`r'km)
	bys village_code: egen tot_pp_actamt_ov_`r2'to`r'km = sum(pp_actamt_ov_`r2'to`r'km)

	bys village_code: egen tot_pp_actamt_`r2'to`r'km_rsa = sum(pp_actamt_`r2'to`r'km_rsa)
	bys village_code: egen tot_pp_actamt_ov_`r2'to`r'km_rsa = sum(pp_actamt_ov_`r2'to`r'km_rsa)


	gen share_token_`r2'to`r'km = n_token_`r2'to`r'km / tot_n_token_`r2'to`r'km
	gen share_token_ov_`r2'to`r'km = n_token_ov_`r2'to`r'km / tot_n_token_ov_`r2'to`r'km

	gen share_actamt_`r2'to`r'km = pp_actamt_`r2'to`r'km / tot_pp_actamt_`r2'to`r'km
	gen share_actamt_ov_`r2'to`r'km = pp_actamt_ov_`r2'to`r'km / tot_pp_actamt_ov_`r2'to`r'km

	gen share_actamt_`r2'to`r'km_r = pp_actamt_`r2'to`r'km_rsa / tot_pp_actamt_`r2'to`r'km_rsa // use deflator across entire study area to abstract from endogenous price responses
	gen share_actamt_ov_`r2'to`r'km_r = pp_actamt_ov_`r2'to`r'km_rsa / tot_pp_actamt_ov_`r2'to`r'km_rsa // use deflator across entire study area to abstract from endogenous price responses
}

reshape wide n_token_* pp_actamt_* share_actamt_* share_token_* , i(village_code) j(month)

drop tot* p_ge*

tempfile temp
save `temp'

project, uses("$da/Ent_ML_SpatialData_long_FINAL.dta")
use "$da/Ent_ML_SpatialData_long_FINAL.dta", clear
drop p_total_* p_ge_* share_ge_* cum_* *actamt*
merge m:1 village_code using `temp'
drop if _merge == 2
drop _merge


foreach v in n_token_ share_token_ pp_actamt_ share_actamt_ {
	order `v'*, last sequential
}

****************************************
* Align temporal data to survey month **
****************************************
gen survey_mth = month
foreach measure in "n_token" "share_token" "pp_actamt" "share_actamt" { // Variables to create lags for
	foreach dist in "ownvill" "0to2km" "2to4km" "4to6km" "6to8km" "8to10km" "ov_0to2km" "ov_2to4km" "ov_4to6km" "ov_6to8km" "ov_8to10km" {

		forval monthsback = 0(1)32 { // I am looping over all possible lags

			gen x_`measure'_`dist'_l`monthsback' = 0

			qui levelsof survey_mth

			foreach calendarmonth in `r(levels)'{ // Now I am looping over all calendar months with conducted surveys

				loc rel_month = `calendarmonth' - `monthsback' // this is the month which is exactly the lag amount of months away from the survey month

				capture confirm variable `measure'_`dist'`rel_month'
				if !_rc {
					replace x_`measure'_`dist'_l`monthsback' = `measure'_`dist'`rel_month' if survey_mth == `calendarmonth'
				}
			}
		}
	}
}

foreach measure in "pp_actamt" "share_actamt" { // Variables to create lags for
	foreach dist in "ownvill_r" "0to2km_r" "2to4km_r" "4to6km_r" "6to8km_r" "8to10km_r" "ov_0to2km_r" "ov_2to4km_r" "ov_4to6km_r" "ov_6to8km_r" "ov_8to10km_r" {

		forval monthsback = 0(1)32 { // I am looping over all possible lags

			gen x_`measure'_`dist'_l`monthsback' = 0

			qui levelsof survey_mth

			foreach calendarmonth in `r(levels)'{ // Now I am looping over all calendar months with conducted surveys

				loc rel_month = `calendarmonth' - `monthsback' // this is the month which is exactly the lag amount of months away from the survey month

				capture confirm variable `measure'_`dist'`rel_month'
				if !_rc {
					replace x_`measure'_`dist'_l`monthsback' = `measure'_`dist'`rel_month' if survey_mth == `calendarmonth'
				}
			}
		}
	}
}

drop pp_actamt* share_actamt*
ren x_pp* pp*
ren x_n* n*
ren x_share* share*


***********************
* Create Instruments **
***********************

forval monthsback = 0(1)32{

	** actual tokens **
	gen t_share_token_ownvill_l`monthsback' = treat * share_token_ownvill_l`monthsback'
	replace t_share_token_ownvill_l`monthsback' = 0 if share_actamt_ownvill_l`monthsback' == .

	** actual amounts**
	gen t_share_actamt_ownvill_l`monthsback' = treat * share_actamt_ownvill_l`monthsback'
	replace t_share_actamt_ownvill_l`monthsback' = 0 if share_actamt_ownvill_l`monthsback' == .

	gen t_share_actamt_ownvill_r_l`monthsback' = treat * share_actamt_ownvill_r_l`monthsback'
	replace t_share_actamt_ownvill_r_l`monthsback' = 0 if share_actamt_ownvill_r_l`monthsback' == .

	forval r = 2(2)10 {
		local r2 = `r' - 2

		** actual tokens **
		gen t_share_token_`r2'to`r'km_l`monthsback' = share_ge_elig_treat_`r2'to`r'km * share_token_`r2'to`r'km_l`monthsback'
		gen t_share_token_ov_`r2'to`r'km_l`monthsback' = share_ge_elig_treat_ov_`r2'to`r'km * share_token_ov_`r2'to`r'km_l`monthsback'

		replace t_share_token_`r2'to`r'km_l`monthsback' = 0 if t_share_token_`r2'to`r'km_l`monthsback' == .
		replace t_share_token_ov_`r2'to`r'km_l`monthsback' = 0 if t_share_token_ov_`r2'to`r'km_l`monthsback' == .

		** actual amounts**
		gen t_share_actamt_`r2'to`r'km_l`monthsback' = share_ge_elig_treat_`r2'to`r'km * share_actamt_`r2'to`r'km_l`monthsback'
		gen t_share_actamt_ov_`r2'to`r'km_l`monthsback' = share_ge_elig_treat_ov_`r2'to`r'km * share_actamt_ov_`r2'to`r'km_l`monthsback'

		replace t_share_actamt_`r2'to`r'km_l`monthsback' = 0 if t_share_actamt_`r2'to`r'km_l`monthsback' == .
		replace t_share_actamt_ov_`r2'to`r'km_l`monthsback' = 0 if t_share_actamt_ov_`r2'to`r'km_l`monthsback' == .

		gen t_share_actamt_`r2'to`r'km_r_l`monthsback' = share_ge_elig_treat_`r2'to`r'km * share_actamt_`r2'to`r'km_r_l`monthsback'
		gen t_share_actamt_ov_`r2'to`r'km_r_l`monthsback' = share_ge_elig_treat_ov_`r2'to`r'km * share_actamt_ov_`r2'to`r'km_r_l`monthsback'

		replace t_share_actamt_`r2'to`r'km_r_l`monthsback' = 0 if t_share_actamt_`r2'to`r'km_r_l`monthsback' == .
		replace t_share_actamt_ov_`r2'to`r'km_r_l`monthsback' = 0 if t_share_actamt_ov_`r2'to`r'km_r_l`monthsback' == .
	}
}

foreach v in token actamt {
	order t_share_`v'*, last sequential
}

****************************
* Aggregate onto quarters **
****************************
foreach measure in "n_token" "share_token" "t_share_token" "pp_actamt" "share_actamt" "t_share_actamt" { // Variables to create lags for
	foreach dist in "ownvill" "0to2km" "2to4km" "4to6km" "6to8km" "8to10km" "ov_0to2km" "ov_2to4km" "ov_4to6km" "ov_6to8km" "ov_8to10km" {
		forval quartersback = 1(1)11{

			loc m1 = `quartersback'*3 - 3
			loc m2 = `quartersback'*3 - 2
			loc m3 = `quartersback'*3 - 1

			gen `measure'_`dist'_q`quartersback' = `measure'_`dist'_l`m1' + `measure'_`dist'_l`m2' + `measure'_`dist'_l`m3'

		}

		*gen `measure'_q10 = `measure'_l27
		*drop `measure'_l`m1' `measure'_l`m2' `measure'_l`m3'
	}
}


foreach measure in "pp_actamt" "share_actamt" "t_share_actamt" { // Variables to create lags for
	foreach dist in "ownvill_r" "0to2km_r" "2to4km_r" "4to6km_r" "6to8km_r" "8to10km_r" "ov_0to2km_r" "ov_2to4km_r" "ov_4to6km_r" "ov_6to8km_r" "ov_8to10km_r" {
		forval quartersback = 1(1)11{

			loc m1 = `quartersback'*3 - 3
			loc m2 = `quartersback'*3 - 2
			loc m3 = `quartersback'*3 - 1

			gen `measure'_`dist'_q`quartersback' = `measure'_`dist'_l`m1' + `measure'_`dist'_l`m2' + `measure'_`dist'_l`m3'
		}

		*gen `measure'_q10 = `measure'_l27
		*drop `measure'_l`m1' `measure'_l`m2' `measure'_l`m3'
	}
}

drop *_ownvill6?? *km6??
*drop *_l? *_l??


*******************
* Save
*******************
save "$da/Ent_ML_SpatialData_Temporal.dta", replace
project, creates("$da/Ent_ML_SpatialData_Temporal.dta")
