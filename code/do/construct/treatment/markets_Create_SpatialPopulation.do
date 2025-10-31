
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

global kenpopgrowth914 = 46024250/40237204 - 1 //population growth in Kenya overall between 2009 and 2014


************************************************
** Generate number of GE households by buffer **
************************************************

** Determine number of people per household for GE/GD data **
*************************************************************

* Calculating share eligible and share ineligible from census data
project, uses("$da/GE_HH-Census_Analysis_HHLevel.dta")
use "$da/GE_HH-Census_Analysis_HHLevel.dta", clear

summ eligible

local share_elig = r(mean)
local share_inelig = 1 - `share_elig'

* Bring in data from HH surveys
project, uses("$da/GE_HH-Survey-BL_Analysis_AllHHs.dta")
use "$da/GE_HH-Survey-BL_Analysis_AllHHs.dta", clear

* s4_q1_hhmembers contains the answer to "How many people (not including yourself) live in your household..."
gen num_hh_members = hhsize1_BL

summ num_hh_members
ttest num_hh_members, by(eligible_baseline_BL)
/* NOTE: TK This is currently based off of calculation of eligibility at baseline. Still need to compare this
   against eligibility as calculated at the time of the census */

summ num_hh_members if eligible_baseline_BL == 1
local people_elig = r(mean)
summ num_hh_members if eligible_baseline_BL == 0
local people_inelig = r(mean)

global people_per_hh = `share_elig'*`people_elig' + `share_inelig'*`people_inelig'
disp "People per household: $people_per_hh"

** Determine number of GE households by buffer **
*************************************************
project, original("$dr/MarketBuffers_GE_HHs_1km_Increments_PUBLIC.dta")
use "$dr/MarketBuffers_GE_HHs_1km_Increments_PUBLIC.dta", clear

foreach v in ge ge_treat ge_eligible ge_eligible_treat {
	gen p_`v' = hh_`v'*$people_per_hh
}

preserve
keep market_code distance village_code hh_ge hh_ge_eligible p_ge p_ge_eligible
save "$da/markets_for_RI.dta", replace
project, creates("$da/markets_for_RI.dta")
restore


order market_code distance village_code treat hh_ge hh_ge_treat* hh_ge_eligible hh_ge_eligible_treat* p_ge p_ge_treat* p_ge_eligible p_ge_eligible_treat*
save "$dt/market_buffers_hhs_ge_1km.dta", replace
project, creates("$dt/market_buffers_hhs_ge_1km.dta") preserve

gen distance2 = distance - mod(distance - 1,2) + 1
tab distance2 distance
tab distance2
replace distance = distance2
drop distance2
collapse (sum) hh_* p_* (first) treat, by(market_code distance village_code)
save "$da/market_buffers_hhs_ge.dta", replace
project, creates("$da/market_buffers_hhs_ge.dta")


************************************************
** Generate number of GD households by buffer **
************************************************
project, original("$dr/MarketBuffers_nonGE-GD_HHs_1km_Increments_PUBLIC.dta")
use "$dr/MarketBuffers_nonGE-GD_HHs_1km_Increments_PUBLIC.dta", clear

gen p_gd = hh_gd*$people_per_hh

save "$dt/market_buffers_hhs_gd_1km.dta", replace
project, creates("$dt/market_buffers_hhs_gd_1km.dta") preserve

gen distance2 = distance - mod(distance - 1,2) + 1
tab distance2 distance
tab distance2
replace distance = distance2
drop distance2
collapse (sum) hh_gd p_gd, by(market_code distance village_code)
save "$dt/market_buffers_hhs_gd.dta", replace
project, creates("$dt/market_buffers_hhs_gd.dta")


****************************************************
** Generate number of census households by buffer **
****************************************************

** Get area of each sublocation in each buffer from ArcGIS **
*************************************************************
project, original("$dr/MarketBuffers_fromCensus_1km_Increments_PUBLIC.dta")
use "$dr/MarketBuffers_fromCensus_1km_Increments_PUBLIC.dta", clear

gen distance2 = distance - mod(distance - 1,2) + 1
tab distance2 distance
tab distance2
replace distance = distance2
drop distance2
collapse (sum) p_census hh_census, by(market_code distance)
save "$dt/market_buffers_hhs_census.dta", replace
project, creates("$dt/market_buffers_hhs_census.dta")


****************************************************************
** Combine GE, GD and Census data to final population numbers **
****************************************************************
project, uses("$dt/market_buffers_hhs_gd_1km.dta")
use "$dt/market_buffers_hhs_gd_1km.dta", clear

project, original("$dr/CleanGeography_PUBLIC.dta") preserve
merge m:1 village_code using "$dr/CleanGeography_PUBLIC.dta"
drop if _merge == 2 // these are villages where we do not have gd data
keep if gd == 1 // we only want to use the gd data where we do not have data from ge
drop _merge

project, uses("$dt/market_buffers_hhs_ge_1km.dta") preserve
merge 1:1 market_code distance village_code using "$dt/market_buffers_hhs_ge_1km.dta" // none should merge
tab ge gd if _merge == 1
drop _merge

collapse (sum) hh_gd p_gd hh_ge* p_ge*, by(market_code distance)

drop if distance > 20
tempfile radiipop
save `radiipop'

use "$dr/MarketBuffers_fromCensus_1km_Increments_PUBLIC.dta", clear
merge 1:1 market_code distance using `radiipop'

replace hh_census = 0 if _merge == 2 // these are radii which have no census households in them
replace p_census = 0 if _merge == 2 // these are radii which have no census households in them

drop _merge
sort market_code distance

foreach v of var hh_* p_* {
	replace `v' = 0 if `v' == .
}

egen hh_total = rowtotal(hh_census hh_gd hh_ge)
egen p_total = rowtotal(p_census p_gd p_ge)

order market_code distance hh_total hh_census hh_ge_eligible hh_ge_treat hh_ge_eligible_treat hh_gd hh_ge p_total p_ge p_ge_eligible p_ge_treat p_ge_eligible_treat p_census p_gd

drop if distance > 20
save "$da/market_radiipop_long_1km.dta", replace
project, creates("$da/market_radiipop_long_1km.dta") preserve

keep market_code distance hh_total hh_ge hh_ge_treat hh_ge_eligible hh_ge_eligible_treat p_total p_ge p_ge_treat p_ge_eligible p_ge_eligible_treat
gen share_ge_elig_treat = hh_ge_eligible_treat / hh_ge_eligible
reshape wide hh_total hh_ge hh_ge_treat hh_ge_eligible hh_ge_eligible_treat p_total p_ge p_ge_treat p_ge_eligible p_ge_eligible_treat share_ge_elig_treat, i(market_code) j(distance)

order market_code hh_tot* hh_ge? hh_ge?? hh_ge_eligible? hh_ge_eligible?? hh_ge_treat? hh_ge_treat?? hh_ge_eligible_treat? hh_ge_eligible_treat?? p_tot* p_ge? p_ge?? p_ge_eligible? p_ge_eligible?? p_ge_treat? p_ge_treat?? p_ge_eligible_treat? p_ge_eligible_treat??

clonevar market_id = market_code
order market_id market_code

save "$da/market_radiipop_wide_1km.dta", replace
project, creates("$da/market_radiipop_wide_1km.dta")



** Create 2km versions **
*************************
project, uses("$da/market_radiipop_long_1km.dta")
use "$da/market_radiipop_long_1km.dta", replace

gen distance2 = distance - mod(distance - 1,2) + 1
tab distance2 distance
tab distance2
replace distance = distance2
drop distance2

collapse (sum) hh_* p_*, by(market_code distance)
save "$da/market_radiipop_long.dta", replace
project, creates("$da/market_radiipop_long.dta") preserve

keep market_code distance hh_total hh_ge hh_ge_treat hh_ge_eligible hh_ge_eligible_treat p_total p_ge p_ge_treat p_ge_eligible p_ge_eligible_treat
gen share_ge_elig_treat = hh_ge_eligible_treat / hh_ge_eligible
reshape wide hh_total hh_ge hh_ge_treat hh_ge_eligible hh_ge_eligible_treat p_total p_ge p_ge_treat p_ge_eligible p_ge_eligible_treat share_ge_elig_treat, i(market_code) j(distance)

order market_code hh_tot* hh_ge? hh_ge?? hh_ge_eligible? hh_ge_eligible?? hh_ge_treat? hh_ge_treat?? hh_ge_eligible_treat? hh_ge_eligible_treat?? p_tot* p_ge? p_ge?? p_ge_eligible? p_ge_eligible?? p_ge_treat? p_ge_treat?? p_ge_eligible_treat? p_ge_eligible_treat??

clonevar market_id = market_code
order market_id market_code

save "$da/market_radiipop_wide.dta", replace
project, creates("$da/market_radiipop_wide.dta")

/*
xxx

****************************************************************
** Quick consistency check with Francis' previous methodology **
****************************************************************
use "$da/market_radiipop_wide.dta", clear

rename market_code market_id
merge 1:1 market_id using "$dir/../population/dta/market_pop_in_radii_bands.dta"

log using "$dl/pop_comparison_with_Francis_method", replace
scatter p_total2 totalpop_0to2km
corr p_total2 totalpop_0to2km

** correlation is 0.83 overall - this is because
** a) I use HH GPS not village averages
** b) I add in sublocations outside the study area
** c) I use a different method of dealing with partial-coverage sublocations (assigning the remaining households to the leftover area, whereas Francis assumed the missing villages were of average size and added those)

scatter p_total6 totalpop_4to6km
corr p_total6 totalpop_4to6km

scatter p_total10 totalpop_8to10km
corr p_total10 totalpop_8to10km

** the correlation gets worse as bins increase in size - this indicates that adding sublocations outside the study area plays a large role.
count if p_total2 < totalpop_0to2km
count if p_total4 < totalpop_2to4km
count if p_total6 < totalpop_4to6km
count if p_total8 < totalpop_6to8km
count if p_total10 < totalpop_8to10km

** at the 2km radius, there are some radii bands which have a smaller population, but not by much
** no larger radii bands have a smaller population using the new methodology - this highlights the fact that we take in data from sublocations outside the study area.

** To check how much adding sublocations outside the study area contributes, I look at a set of markets which are located in the center of the study area:
scatter p_total2 totalpop_0to2km if inlist(market_id,116,201,203,209,307,308,312,317)
corr p_total2 totalpop_0to2km if inlist(market_id,116,201,203,209,307,308,312,317)
** correlation is 0.99 - so adding sublocations outside the study area seems to be the main driver of the differences

scatter p_total2 totalpop_0to2km if inlist(market_id,109,110,113,115,116,118,126,129,201,203,209,307,308,312,317)
corr p_total2 totalpop_0to2km if inlist(market_id,109,110,113,115,116,118,126,129,201,203,209,307,308,312,317)
** correlation is 0.98 for a larger set of central markets - this corroborates the finding
log off
