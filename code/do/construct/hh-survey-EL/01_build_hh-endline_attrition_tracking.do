/*
 * Filename: 01_build_hh-endline_attrition_tracking.do
 * Description: This do file constructs a dataset that is used for checking for attrition across survey rounds. This generates indicators for whether a household was surveyed
 *    at baseline and at endline 1.
 *
 * Inputs:
 *   1. GE HH Sample
 *   2. GE Census clean data
 *   3. GE Baseline clean data
 *   4. GE Endline 1 clean data
 *   5. Village treatment status
 */

/* Preliminaries */

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

/************** GENERATING DATASET *************************/

/* STARTING WITH FULL SAMPLE OF HOUSEHOLDS TARGETED FOR ENDLINE SURVEYS */
project, original("$dr/GE_HH-SampleMaster_PUBLIC.dta")
use "$dr/GE_HH-SampleMaster_PUBLIC.dta", clear

order hhid_key village_code q4_respid eligible treat hi_sat, first
order hh_baselined, before(missed_baselined)

count
local num_start = r(N)
duplicates report hhid_key

desc

/* MERGING IN HOUSEHOLD CENSUS NAMES, GPS COORDINATES, OTHER TRACKING VARIABLES */
gen master_fr_id = q4_respid

project, uses("$da/GE_HH-Census_Analysis_HHLevel.dta") preserve
merge 1:1 hhid_key using "$da/GE_HH-Census_Analysis_HHLevel.dta", keepusing(village_code eligible* fr_id master_fr_id)

tab _merge // 58 problematic observations that are in master sample but not merging with census data - what is going on here?
// TK 41 when using Analysis census data


format village_code %14.0f
tab village_code if _merge == 1

gen flag_censusnotmatch = (_merge == 1)
bys village_code : egen flag_villlevel = total(flag_censusnotmatch)
sort hhid_key
list if flag_villlevel == 1

drop if _merge == 2
drop _merge

count // should stil be at 9150 - CHECK


/* MERGING IN CLEAN BASELINE SURVEY DATA */
project, original("$dr/GE_HH-Survey-BL_PUBLIC.dta") preserve
ren q4_respid s1_q4_respid

merge 1:1 village_code s1_q4_respid using "$dr/GE_HH-Survey-BL_PUBLIC.dta", keepusing(s1_q2a_location s1_q2b_sublocation s1_q2c_village s1_target s1_target_explain s1_q7_ressex s1_consent s1_q11_proceed s2_q3_gender)

tab _merge // tk why are 5 from using not merging?

gen flag_blmerge = (_merge == 2)
drop _merge

duplicates report hhid_key
duplicates list hhid_key

replace hhid_key = string(village_code, "%14.0f") + "-" + s1_q4_respid if flag_blmerge == 1
duplicates report hhid_key

foreach var of varlist s1_q2a_location s1_q2b_sublocation s1_q2c_village s1_target s1_target_explain s1_q7_ressex s1_consent s1_q11_proceed s2_q3_gender {
    ren `var' hhb_`var'
}

/* MERGING IN CLEAN ENDLINE DATA */
replace s1_hhid_key = hhid_key if mi(s1_hhid_key)


project, original("$dr/GE_HH-Survey-EL1_PUBLIC.dta") preserve
merge 1:n s1_hhid_key using "$dr/GE_HH-Survey-EL1_PUBLIC.dta", keepusing(s1_q2a_location s1_q2b_sublocation s1_q2c_village s1_q4_respid  s1_q7_ressex s1_consent s1_q11_proceed s1_hhid_key s1_q4a_resptype s1_q4b_target_explain today)

duplicates report s1_hhid_key
duplicates tag s1_hhid_key, gen(flag_endline_duplicate)

tab _merge
gen flag_elmerge = (_merge == 2)

foreach var of varlist s1_q2a_location s1_q2b_sublocation s1_q2c_village s1_q4_respid  s1_q7_ressex s1_consent s1_q11_proceed s1_hhid_key s1_q4a_resptype s1_q4b_target_explain today {
    ren `var' hhe_`var'
}


bys hhid_key (hhe_today): drop if _n > 1

count // back to 9150

**TK issue here, make sure sample maseter has hhid_key
merge 1:1 hhid_key using "$dr/GE_HH-SampleMaster_PUBLIC.dta", gen(_mergeSM)

list hhid_key if _mergeSM == 1 // TK come back to this -- may need to drop some of these as part of cleaning up endline survey dataset

keep if _mergeSM == 3

/*** GENERATING SURVEYED VARIABLES ***/

gen surveyed_rd1 = (hhb_s1_q11_proceed == 1)
la var surveyed_rd1 "Surveyed at baseline"

gen surveyed_rd2 = (hhe_s1_q11_proceed == 1)
la var surveyed_rd2 "Surveyed at endline"

gen surveyed_both = surveyed_rd1 == 1 & surveyed_rd2 == 1
la var surveyed_both "Surveyed at baseline and endline"

gen never_surveyed = surveyed_rd1 == 0 & surveyed_rd2 == 0
la var never_surveyed "Never surveyed"

gen missed_EL = surveyed_rd2 == 0 if surveyed_rd1 == 1
la var missed_EL "Missed endline (conditional on baselined)"

gen missed_BL = surveyed_rd1 == 0 if surveyed_rd2 == 1
la var missed_BL "Missed baseline (conditional on endlined)"

gen tracked_rd1     = (hhb_s1_q11_proceed != .)
la var tracked_rd1 "Household tracked at baseline (incl decline consent)"

gen tracked_rd2     = (hhe_s1_q11_proceed != .)
la var tracked_rd2 "Household tracked at endline (incl decline consent)"

summ *surveyed* missed_* tracked_*


/** Ensuring full set of treatment status interactions are created **/

ren treat_elig treat_eligible
gen treat_hisat = treat * hi_sat
gen hisat_eligible = hi_sat * eligible
gen treat_hisat_eligible = treat * hi_sat * eligible

gen lowsat = (hi_sat == 0) if ~mi(hi_sat)

gen control_lowsat = control * lowsat

codebook eligible hh_baselined treat treat_eligible hi_sat treat_hisat hisat_eligible treat_hisat_eligible

* filling in variables that need filling in
summ treat eligible treat_eligible hi_sat treat_hisat hisat_eligible treat_hisat_eligible

 desc eligible*, full
 tab1 eligible*

* bringing in saturation cluster
drop _merge
project, original("$dr/GE_Treat_Status_Master.dta") preserve
merge n:1 village_code using "$dr/GE_Treat_Status_Master.dta", keepusing(treat hi_sat satlevel_name)

drop if _merge == 2 // villages that we dropped

egen satcluster = group(satlevel_name)

** other variables that need to be updated **
codebook village_code satcluster

** CONSTRUCTING HOUSEHOLD SURVEY WEIGHTS **
preserve
use "$da/GE_HH-Census_Analysis_HHLevel.dta", clear

gen hh_ind = 1

collapse (sum) num_eligible = eligible (sum) pop_hh = hh_ind, by(village_code)

tempfile vill_cens
save `vill_cens'

restore

merge n:1 village_code using `vill_cens', keepusing(num_eligible pop_hh) gen(_merge_vl)

tab _merge_vl
codebook village_code // should have 653

ren num_eligible num_eligible_hhc
gen num_ineligible_hhc = pop_hh - num_eligible_hhc // what about any missing eligible cases here?

gen elig_BL = eligible * surveyed_rd1
gen inelig_BL = ineligible * surveyed_rd1
gen elig_EL = eligible * surveyed_rd2
gen inelig_EL = ineligible * surveyed_rd2
gen elig_panel = eligible * surveyed_both
gen inelig_panel = ineligible * surveyed_both

sort village_code
by village_code: egen num_elig_BL = total(elig_BL)
by village_code: egen num_inelig_BL = total(inelig_BL)
by village_code: egen num_elig_EL = total(elig_EL)
by village_code: egen num_inelig_EL = total(inelig_EL)
by village_code: egen num_elig_panel = total(elig_panel)
by village_code: egen num_inelig_panel = total(inelig_panel)
by village_code: egen num_elig_sample = total(eligible)
by village_code: egen num_inelig_sample = total(ineligible)

foreach bub in BL EL panel sample {
    di "Weights for `bub'"
    gen elig_weight_`bub' =  num_eligible_hhc / num_elig_`bub'
    gen inelig_weight_`bub' = num_ineligible_hhc / num_inelig_`bub'

    codebook elig_weight_`bub' inelig_weight_`bub'
    summ elig_weight_`bub' inelig_weight_`bub'
}

gen hhweight_EL = elig_weight_EL if eligible == 1 & surveyed_rd2 == 1
replace hhweight_EL = inelig_weight_EL if eligible == 0 & surveyed_rd2 == 1

gen hhweight_BL = elig_weight_BL if eligible == 1 & surveyed_rd1 == 1
replace hhweight_BL = inelig_weight_BL if eligible == 0 & surveyed_rd1 == 1

gen hhweight_panel = elig_weight_panel if eligible == 1 & surveyed_both == 1
replace hhweight_panel = inelig_weight_panel if eligible == 0 & surveyed_both == 1

gen     hhweight_sample     = elig_weight_sample if eligible == 1
replace hhweight_sample     = inelig_weight_sample if eligible == 0

/** weights enforcing each village is weighted the same, based on sampling strategy (8 elig, 4 inelig) **/

gen hhweight_villelig   = 1 / ( 8 / num_elig_EL) if eligible == 1
gen hhweight_villinelig = 1 / ( 4 / num_inelig_EL) if eligible == 0


*** labeling variables ***
la var hhid_key         "Unique household ID"
la var village_code     "Village code"
la var eligible         "Eligible HH"
la var treat            "Treatment Village"
la var hi_sat           "High Saturation Sublocation"
la var male             "Male"
la var female           "Female"
la var control          "Control Village"
la var ineligible       "Ineligible HH"
la var treat_eligible   "Treat Vill $\times$ Eligible HH"
la var treat_inelig     "Treat Vill $\times$ Ineligible HH"
la var control_elig     "Control Vill $\times$ Eligible HH"
la var control_inelig   "Control Vill $\times$ Ineligible HH"
la var control_lowsat   "Control Vill $\times$ Low Sat"
la var low_sat          "Low saturation sublocation"
la var hh_baselined         "Household baselined"
la var missed_baselined     "Household missed at baseline"
la var baselined_target     "Target baseline household"
la var baselined_added      "Added baseline household"

la var treat_hisat              "Treat $\times$ High Sat"
la var hisat_eligible           "High Sat $\times$ Eligible HH"
la var treat_hisat_eligible     "Treat $\times$ High Sat $\times$ Eligible HH"
la var satcluster               "Saturation cluster"
la var hhweight_EL              "Endline survey household weights"
la var hhweight_BL              "Baseline survey household weights"
la var hhweight_panel           "Panel survey household weights"
la var hhweight_sample          "Full sample household weights"

cap drop _merge*

/*** SAVING DATASET ***/
compress
note: Dataset created TS

save "$da/GE_HH-Survey_Tracking_Attrition.dta", replace
project, creates("$da/GE_HH-Survey_Tracking_Attrition.dta")
