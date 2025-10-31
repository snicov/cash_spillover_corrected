GE_HHLevel_ECMA.dta/*
 * Filename: ge_hh_cons-shares.do
 * Description: This do file calculates disaggregated expenditure
 *   shares for each consumption question that is asked as part
 *   of the household survey.
 */

* to do: integrate this into the rest of the data flow, make sure there are no additional consumption changes
* that need to be made from this code.

* Preliminaries
 return clear
 capture project, doinfo
 if (_rc==0 & !mi(r(pname))) global dir `r(pdir)'  // using -project-
 else {  // running directly
 	if ("${ge_dir}"=="") do `"`c(sysdir_personal)'profile.do"'
 	do "${ge_dir}/do/set_environment.do"

}

 ** defining globals **
 project, original("$dir/do/GE_global_setup.do")
 include "$dir/do/GE_global_setup.do"


project, uses("$da/GE_HH-Analysis_AllHHs.dta")
project, uses("$da/GE_HHLevel_ECMA.dta")
use "$da/GE_HH-Analysis_AllHHs.dta", clear

replace hhid_key  = s1_hhid_key

merge 1:1 hhid_key using "$da/GE_HHLevel_ECMA.dta", keepusing(hhweight_EL)

drop if _merge != 3

sum s4_4_q4_schexpend h2_5_educexp


local foodvars    s12_q1_cerealsamt s12_q1_rootsamt s12_q1_pulsesamt s12_q1_vegamt s12_q1_meatamt s12_q1_fishamt s12_q1_dairyeggsamt s12_q1_othanimalamt s12_q1_oilamt s12_q1_fruitsamt s12_q1_sugaramt s12_q1_sweetsamt s12_q1_softdrinksamt s12_q1_alcoholamt s12_q1_tobaccoamt s12_q1_spicesamt s12_q1_foodoutamt s12_q1_foodothamt
local freqvars    s12_q19_airtimeamt_12mth s12_q20_internetamt_12mth s12_q21_travelamt_12mth  s12_q23_clothesamt_12mth s12_q24_recamt_12mth s12_q25_personalamt_12mth s12_q26_hhitemsamt_12mth s12_q27_firewoodamt_12mth s12_q28_electamt_12mth s12_q29_wateramt_12mth
local infreqvars  h2_5_educexp s12_q30_rentamt s12_q31_housemaintamt s12_q32_houseimprovamt s12_q33_religiousamt s12_q34_charityamt s12_q35_weddingamt s12_q36_medicalamt s12_q37_hhdurablesamt s12_q38_dowryamt s12_q39_othexpensesamt
local temptvars   s12_q1_alcoholamt s12_q1_tobaccoamt   s12_q22_gamblingamt

replace s12_q39_othexpensesamt = 0 if s12_q39_othexpenses == 0
replace s4_4_q4_schexpend = 0 if s4_4_q3_haschildren == 0


summ s12_q*amt_12mth s12_q30_rentamt s12_q31_housemaintamt s12_q32_houseimprovamt s12_q33_religiousamt s12_q34_charityamt s12_q35_weddingamt s12_q36_medicalamt s12_q37_hhdurablesamt s12_q38_dowryamt s12_q39_othexpensesamt s4_4_q4_schexpend p2_consumption

* how many have missing consumption by question?
egen misscons_comp = rowmiss(s12_q*amt_12mth s12_q30_rentamt s12_q31_housemaintamt s12_q32_houseimprovamt s12_q33_religiousamt s12_q34_charityamt s12_q35_weddingamt s12_q36_medicalamt s12_q37_hhdurablesamt s12_q38_dowryamt s12_q39_othexpensesamt h2_5_educexp )

tab misscons_comp
replace p2_consumption_wins = . if misscons_comp > 2


gen foodcons_12mth = h2_1_foodcons_12mth
gen tottemptgoods_12mth = h2_3_temptgoods_12


foreach var of varlist s12_q*amt_12mth s12_q30_rentamt s12_q31_housemaintamt s12_q32_houseimprovamt s12_q33_religiousamt s12_q34_charityamt s12_q35_weddingamt s12_q36_medicalamt s12_q37_hhdurablesamt s12_q38_dowryamt s12_q39_othexpensesamt h2_5_educexp tottemptgoods_12mth {
  loc newname = substr("`var'", 8, .)
  if "`var'" == "h2_5_educexp" {
    loc newname "_schexpend"
  }
  gen `newname'_share = `var' / p2_consumption
}

foreach var of varlist foodcons_12mth freqpurchases_12mth infreqpurchases_12mth {
    gen `var'_share = `var' / p2_consumption
}

** components of food **
foreach var of local foodvars {
  loc newname = substr("`var'", 8, .)
  gen `newname'_share_food = `var'_12mth / foodcons_12mth
}
** components of frequent purchases **
foreach var of local freqvars {
  loc newname = substr("`var'", 8, .)
  gen `newname'_share_freq = `var' / freqpurchases_12mth
}
** components of infrequent purchases **
foreach var of local infreqvars {
  loc newname = substr("`var'", 8, .)
  if "`var'" == "h2_5_educexp" {
    loc newname "_schexpend"
  }
  gen `newname'_share_infreq = `var' / infreqpurchases_12mth
}

** components of temptation goods **
foreach var of local temptvars {
  loc newname = substr("`var'", 8, .)
  gen `newname'_share_tempt = `var'_12mth / tottemptgoods_12mth
}


/**** ASSET SHARES ****/
egen tothhassets = rowtotal(s6_q13*value), m

foreach var of varlist s6_q13*value {
  local name_end = strpos("`var'", "value")
  local newname = substr("`var'", 9, `name_end' - 9 )
  gen asset_`newname'_share = `var' / tothhassets
}


/************************************/
* alternate sets of shares above *

* services
local servicesvars s12_q1_foodoutamt_12mth s12_q21_travelamt_12mth s12_q25_personalamt_12mth s12_q35_weddingamt
local servicesvars_conservative `servicesvars' s12_q1_alcoholamt_12mth s12_q20_internetamt_12mth s12_q23_clothesamt_12mth s12_q36_medicalamt

egen services = rowtotal(`servicesvars'), m
egen services_conserv = rowtotal(`servicesvars_conservative'), m


foreach var of varlist services services_conserv {
  gen `var'_share = `var' / p2_consumption
}

summ services* services_conserv*, d

// some of these seem way too small
drop if p2_consumption < 10000 // a bit ad-hoc, come back to consider as part of full restructuring

collapse *_share* [pweight=hhweight_EL]
list

egen tot_cons_shares = rowtotal(cerealsamt_12mth_share rootsamt_12mth_share pulsesamt_12mth_share vegamt_12mth_share meatamt_12mth_share fishamt_12mth_share dairyeggsamt_12mth_share othanimalamt_12mth_share oilamt_12mth_share fruitsamt_12mth_share sugaramt_12mth_share sweetsamt_12mth_share softdrinksamt_12mth_share alcoholamt_12mth_share tobaccoamt_12mth_share spicesamt_12mth_share foodoutamt_12mth_share foodothamt_12mth_share _airtimeamt_12mth_share _internetamt_12mth_share _travelamt_12mth_share _gamblingamt_12mth_share _clothesamt_12mth_share _recamt_12mth_share _personalamt_12mth_share _hhitemsamt_12mth_share _firewoodamt_12mth_share _electamt_12mth_share _wateramt_12mth_share _rentamt_share _housemaintamt_share _houseimprovamt_share _religiousamt_share _charityamt_share _weddingamt_share _medicalamt_share _hhdurablesamt_share _dowryamt_share _othexpensesamt_share _schexpend_share)
summ tot_cons_shares
// still missing something -- only summing to 96%, what could that be?
summ foodcons_12mth_share freqpurchases_12mth_share infreqpurchases_12mth_share

** check asset total **
egen tot_asset_shares = rowtotal(asset_*_share)
summ tot_asset_shares


* clean up names
ren *__* *_*
ren _* *
ren *_12mth_* *_*
ren *amt_* *_*

foreach var of varlist *_share {
  local namepos = strpos("`var'", "_") - 1
  local namestr = proper(substr("`var'", 1, `namepos'))
  di "`namestr'"
  la var `var' "`namestr' share of total consumption (annualized)"
}

foreach var of varlist asset_*_share {
  local namepos = strlen("`var'")
  local namestr = proper(substr("`var'", 7, `namepos' - 12))
  di "`namestr'"
  la var `var' "`namestr' share of total HH durable assets"
}


foreach var of varlist *_share_food {
  local namepos = strpos("`var'", "_") - 1
  local namestr = proper(substr("`var'", 1, `namepos'))
  di "`namestr'"
  la var `var' "`namestr' share of food consumption (annualized)"
}

foreach var of varlist *_share_freq {
  local namepos = strpos("`var'", "_") - 1
  local namestr = proper(substr("`var'", 1, `namepos'))
  di "`namestr'"
  la var `var' "`namestr' share of frequent consumption (annualized)"
}


foreach var of varlist *_share_infreq {
  local namepos = strpos("`var'", "_") - 1
  local namestr = proper(substr("`var'", 1, `namepos'))
  di "`namestr'"
  la var `var' "`namestr' share of infrequent consumption (annualized)"
}


foreach var of varlist *_share_tempt {
  local namepos = strpos("`var'", "_") - 1
  local namestr = proper(substr("`var'", 1, `namepos'))
  di "`namestr'"
  la var `var' "`namestr' share of temptation good consumption (annualized)"
}


** services shares **


save "$da/GE_EL_consshares.dta", replace
