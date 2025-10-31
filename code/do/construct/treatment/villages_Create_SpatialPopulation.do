
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

** TK where do we use this?
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
*project, uses("$da/GE_HH-Survey-BL_Analysis_AllHHs.dta")
use "$da/GE_HH-Survey-BL_Analysis_AllHHs.dta", clear

* s4_q1_hhmembers contains the answer to "How many people (not including yourself) live in your household..."
gen num_hh_members = hhsize1_BL

summ num_hh_members
ttest num_hh_members, by(eligible_baseline_BL)
/* NOTE: This is currently based off of calculation of eligibility at baseline. Still need to compare this
   against eligibility as calculated at the time of the census */

summ num_hh_members if eligible_baseline_BL == 1
local people_elig = r(mean)
summ num_hh_members if eligible_baseline_BL == 0
local people_inelig = r(mean)

global people_per_hh = `share_elig'*`people_elig' + `share_inelig'*`people_inelig'
disp "People per household: $people_per_hh"
* TK come back to see how this compares if we use census -- census likely cleaner

** Determine number of GE households by buffer **
*************************************************
project, original("$dr/VillageBuffers_GE_HHs_1km_Increments_PUBLIC.dta")
use "$dr/VillageBuffers_GE_HHs_1km_Increments_PUBLIC.dta", clear

foreach v in ge ge_treat ge_eligible ge_eligible_treat {
	gen p_`v' = hh_`v'*$people_per_hh

	gen hh_`v'_ownvill = hh_`v' if treatvill_code == village_code
	gen p_`v'_ownvill = hh_`v'*$people_per_hh if treatvill_code == village_code

	gen hh_`v'_ov = hh_`v' if treatvill_code != village_code
	gen p_`v'_ov = hh_`v'*$people_per_hh if treatvill_code != village_code
}

order treatvill_code distance village_code treat hh_ge hh_ge_ownvill hh_ge_ov hh_ge_treat* hh_ge_eligible hh_ge_eligible_ownvill hh_ge_eligible_ov hh_ge_eligible_treat* p_ge p_ge_ownvill p_ge_ov p_ge_treat* p_ge_eligible p_ge_eligible_ownvill p_ge_eligible_ov p_ge_eligible_treat*
compress
save "$dt/village_buffers_hhs_ge_1km.dta", replace
project, creates("$dt/village_buffers_hhs_ge_1km.dta") preserve

gen distance2 = distance - mod(distance - 1,2) + 1
tab distance2 distance
tab distance2
replace distance = distance2
drop distance2
collapse (sum) hh_* p_* (first) treat, by(treatvill_code distance village_code)
compress
save "$da/village_buffers_hhs_ge.dta", replace
project, creates("$da/village_buffers_hhs_ge.dta")


************************************************
** Generate number of GD households by buffer **
************************************************
project, original("$dr/VillageBuffers_nonGE-GD_HHs_1km_Increments_PUBLIC.dta")
use "$dr/VillageBuffers_nonGE-GD_HHs_1km_Increments_PUBLIC.dta", clear

gen p_gd = hh_gd*$people_per_hh

save "$dt/village_buffers_hhs_gd_1km.dta", replace
project, creates("$dt/village_buffers_hhs_gd_1km.dta") preserve

gen distance2 = distance - mod(distance - 1,2) + 1
tab distance2 distance
tab distance2
replace distance = distance2
drop distance2
collapse (sum) hh_gd p_gd, by(treatvill_code distance village_code)
save "$da/village_buffers_hhs_gd.dta", replace
project, creates("$da/village_buffers_hhs_gd.dta")


****************************************************
** Generate number of census households by buffer **
****************************************************
project, original("$dr/VillageBuffers_fromCensus_1km_Increments_PUBLIC.dta")
use "$dr/VillageBuffers_fromCensus_1km_Increments_PUBLIC.dta", clear

gen distance2 = distance - mod(distance - 1,2) + 1
tab distance2 distance
tab distance2
replace distance = distance2
drop distance2
collapse (sum) p_census hh_census, by(treatvill_code distance)
save "$da/village_buffers_hhs_census.dta", replace
project, creates("$da/village_buffers_hhs_census.dta")


****************************************************************
** Combine GE, GD and Census data to final population numbers **
****************************************************************
project, uses("$dt/village_buffers_hhs_gd_1km.dta")
use "$dt/village_buffers_hhs_gd_1km.dta", clear

project, original("$dr/CleanGeography_PUBLIC.dta") preserve
merge m:1 village_code using "$dr/CleanGeography_PUBLIC.dta"
drop if _merge == 2 // these are villages where we do not have gd data
keep if gd == 1 // we only want to use the gd data where we do not have data from ge
drop _merge

project, uses("$dt/village_buffers_hhs_ge_1km.dta") preserve
merge 1:1 treatvill_code distance village_code using "$dt/village_buffers_hhs_ge_1km.dta" // none should merge
tab ge gd if _merge == 1
drop _merge

collapse (sum) hh_gd p_gd hh_ge* p_ge*, by(treatvill_code distance)

drop if distance > 20
tempfile radiipop
save `radiipop'

use "$dr/VillageBuffers_fromCensus_1km_Increments_PUBLIC.dta", clear
drop if distance > 20

merge 1:1 treatvill_code distance using `radiipop'
replace hh_census = 0 if _merge == 2 // these are radii which have no census households in them
replace p_census = 0 if _merge == 2 // these are radii which have no census households in them

drop _merge
sort treatvill_code distance

foreach v of var hh_* p_* {
	replace `v' = 0 if `v' == .
}

egen hh_total = rowtotal(hh_census hh_gd hh_ge)
egen hh_total_ov = rowtotal(hh_census hh_gd hh_ge_ov)
egen hh_total_ownvill = rowtotal(hh_ge_ownvill)
egen p_total = rowtotal(p_census p_gd p_ge)
egen p_total_ov = rowtotal(p_census p_gd p_ge_ov)
egen p_total_ownvill = rowtotal(p_ge_ownvill)

drop if distance > 20
rename treatvill_code village_code
save "$da/village_radiipop_long_1km.dta", replace
project, creates("$da/village_radiipop_long_1km.dta") preserve

keep village_code distance hh_total hh_ge hh_ge_treat hh_ge_eligible hh_ge_eligible_treat p_total p_ge p_ge_treat p_ge_eligible p_ge_eligible_treat hh_total_ownvill hh_ge_ownvill hh_ge_treat_ownvill hh_ge_eligible_ownvill hh_ge_eligible_treat_ownvill p_total_ownvill p_ge_ownvill p_ge_treat_ownvill p_ge_eligible_ownvill p_ge_eligible_treat_ownvill hh_total_ov hh_ge_ov hh_ge_treat_ov hh_ge_eligible_ov hh_ge_eligible_treat_ov p_total_ov p_ge_ov p_ge_treat_ov p_ge_eligible_ov p_ge_eligible_treat_ov
reshape wide hh_total hh_ge hh_ge_treat hh_ge_eligible hh_ge_eligible_treat p_total p_ge p_ge_treat p_ge_eligible p_ge_eligible_treat hh_total_ownvill hh_ge_ownvill hh_ge_treat_ownvill hh_ge_eligible_ownvill hh_ge_eligible_treat_ownvill p_total_ownvill p_ge_ownvill p_ge_treat_ownvill p_ge_eligible_ownvill p_ge_eligible_treat_ownvill hh_total_ov hh_ge_ov hh_ge_treat_ov hh_ge_eligible_ov hh_ge_eligible_treat_ov p_total_ov p_ge_ov p_ge_treat_ov p_ge_eligible_ov p_ge_eligible_treat_ov, i(village_code) j(distance)

order village_code hh_total? hh_total?? hh_ge? hh_ge?? hh_ge_treat? hh_ge_treat?? hh_ge_eligible? hh_ge_eligible?? hh_ge_eligible_treat? hh_ge_eligible_treat?? p_total? p_total?? p_ge? p_ge?? p_ge_treat? p_ge_treat?? p_ge_eligible? p_ge_eligible?? p_ge_eligible_treat? p_ge_eligible_treat?? hh_total_ownvill? hh_total_ownvill?? hh_ge_ownvill? hh_ge_ownvill?? hh_ge_treat_ownvill? hh_ge_treat_ownvill?? hh_ge_eligible_ownvill? hh_ge_eligible_ownvill?? hh_ge_eligible_treat_ownvill? hh_ge_eligible_treat_ownvill?? p_total_ownvill? p_total_ownvill?? p_ge_ownvill? p_ge_ownvill?? p_ge_treat_ownvill? p_ge_treat_ownvill?? p_ge_eligible_ownvill? p_ge_eligible_ownvill?? p_ge_eligible_treat_ownvill? p_ge_eligible_treat_ownvill?? hh_total_ov? hh_total_ov?? hh_ge_ov? hh_ge_ov?? hh_ge_treat_ov? hh_ge_treat_ov?? hh_ge_eligible_ov? hh_ge_eligible_ov?? hh_ge_eligible_treat_ov? hh_ge_eligible_treat_ov?? p_total_ov? p_total_ov?? p_ge_ov? p_ge_ov?? p_ge_treat_ov? p_ge_treat_ov?? p_ge_eligible_ov? p_ge_eligible_ov?? p_ge_eligible_treat_ov? p_ge_eligible_treat_ov??
save "$da/village_radiipop_wide_1km.dta", replace
project, creates("$da/village_radiipop_wide_1km.dta")


** Create 2km versions **
*************************
project, uses("$da/village_radiipop_long_1km.dta")
use "$da/village_radiipop_long_1km.dta", replace

gen distance2 = distance - mod(distance - 1,2) + 1
tab distance2 distance
tab distance2
replace distance = distance2
drop distance2

collapse (sum) hh_* p_*, by(village_code distance)
save "$da/village_radiipop_long.dta", replace
project, creates("$da/village_radiipop_long.dta") preserve

keep village_code distance hh_total hh_ge hh_ge_treat hh_ge_eligible hh_ge_eligible_treat p_total p_ge p_ge_treat p_ge_eligible p_ge_eligible_treat hh_total_ownvill hh_ge_ownvill hh_ge_treat_ownvill hh_ge_eligible_ownvill hh_ge_eligible_treat_ownvill p_total_ownvill p_ge_ownvill p_ge_treat_ownvill p_ge_eligible_ownvill p_ge_eligible_treat_ownvill hh_total_ov hh_ge_ov hh_ge_treat_ov hh_ge_eligible_ov hh_ge_eligible_treat_ov p_total_ov p_ge_ov p_ge_treat_ov p_ge_eligible_ov p_ge_eligible_treat_ov
reshape wide hh_total hh_ge hh_ge_treat hh_ge_eligible hh_ge_eligible_treat p_total p_ge p_ge_treat p_ge_eligible p_ge_eligible_treat hh_total_ownvill hh_ge_ownvill hh_ge_treat_ownvill hh_ge_eligible_ownvill hh_ge_eligible_treat_ownvill p_total_ownvill p_ge_ownvill p_ge_treat_ownvill p_ge_eligible_ownvill p_ge_eligible_treat_ownvill hh_total_ov hh_ge_ov hh_ge_treat_ov hh_ge_eligible_ov hh_ge_eligible_treat_ov p_total_ov p_ge_ov p_ge_treat_ov p_ge_eligible_ov p_ge_eligible_treat_ov, i(village_code) j(distance)

order village_code hh_total? hh_total?? hh_ge? hh_ge?? hh_ge_treat? hh_ge_treat?? hh_ge_eligible? hh_ge_eligible?? hh_ge_eligible_treat? hh_ge_eligible_treat?? p_total? p_total?? p_ge? p_ge?? p_ge_treat? p_ge_treat?? p_ge_eligible? p_ge_eligible?? p_ge_eligible_treat? p_ge_eligible_treat?? hh_total_ownvill? hh_total_ownvill?? hh_ge_ownvill? hh_ge_ownvill?? hh_ge_treat_ownvill? hh_ge_treat_ownvill?? hh_ge_eligible_ownvill? hh_ge_eligible_ownvill?? hh_ge_eligible_treat_ownvill? hh_ge_eligible_treat_ownvill?? p_total_ownvill? p_total_ownvill?? p_ge_ownvill? p_ge_ownvill?? p_ge_treat_ownvill? p_ge_treat_ownvill?? p_ge_eligible_ownvill? p_ge_eligible_ownvill?? p_ge_eligible_treat_ownvill? p_ge_eligible_treat_ownvill?? hh_total_ov? hh_total_ov?? hh_ge_ov? hh_ge_ov?? hh_ge_treat_ov? hh_ge_treat_ov?? hh_ge_eligible_ov? hh_ge_eligible_ov?? hh_ge_eligible_treat_ov? hh_ge_eligible_treat_ov?? p_total_ov? p_total_ov?? p_ge_ov? p_ge_ov?? p_ge_treat_ov? p_ge_treat_ov?? p_ge_eligible_ov? p_ge_eligible_ov?? p_ge_eligible_treat_ov? p_ge_eligible_treat_ov??

save "$da/village_radiipop_wide.dta", replace
project, creates("$da/village_radiipop_wide.dta")
