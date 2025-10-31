/*
 * Filename: ge_hh-welfare_psych_BL.do
 * Description: This do file constructs variables related to mental health, psych and aspirations
 *
 * Author: Michael Walker, updated by Justin Abraham
 * Last modified: 20 Sep 2018: only including outcomes listed as part of HH PAP, pulling out health into a new do file

 * 12 June 2017, adapting from ge_hhb_outcomes_assets_income_2017-03-03.do and incorporating suggestions from JA on psych scales.
 *
 *
 *
 */


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


   project, original("$do/programs/run_ge_build_programs.do")
   include "$do/programs/run_ge_build_programs.do"

   // end preliminaries


project, uses("$da/intermediate/GE_HH-BL_setup.dta")
use "$da/intermediate/GE_HH-BL_setup.dta", clear

keep *hhid_key village_code subcounty eligible control_lowsat s13_* s14_*

 /************************************/
 /* SECTION 13: MENTAL WELL-BEING    */
 /************************************/

 /* JA: Below describes a recommended method for dealing with missing responses on psych scales based on Aspirations project.

 The proportion of missing responses across all respondents for a given item will be taken as an indication of poor comprehension and acceptability of the item, with 20% item non-response leading to the removal of that item from the scale. Responses of individual respondents to a given scale were dropped for a scale with 4-5 items if responses on ≥ 2 items were missing, for a scale with 6-8 items if ≥ 3 were missing, and for a scale with 9+ items if ≥ 4 were missing. When fewer items than these cutoffs are missing for a particular individual, scores are adjusted to generate homogeneous score ranges using an appropriate multiplier. We score each scale according to the instructions in the original literature.
 */

 /**** Mental well-being ****/

 /* CES-D */

 * Rename individual items
    forval i = 1/20 {

        gen cesd_`i' = s13_q`i'

    }

 * Code DK as missing
    recode cesd_* (88 = .)

 * Reverse code items
    recode cesd_4 cesd_8 cesd_12 cesd_16 (1 = 4) (2 = 3) (3 = 2) (4 = 1)

 * Calculate number of missing
    egen cesd_nummiss = rowmiss(cesd_1-cesd_20)

 * Calculate CES-D score
    egen cesd_score = rowtotal(cesd_1-cesd_20), m

 * Drop obs. with over 3 items missing
    replace cesd_score = . if cesd_nummiss > 3

 * Inflate scores to account for missing
    replace cesd_score = cesd_score * 20 / (20 - cesd_nummiss)

* label CES-D score variable
    la var cesd_score "CES-D score (raw)"
    note cesd_score: BL used 20-question CES-D scale, endline used 10-question scale. Score based on 20-question scale.

 * Standardize to control mean and SD, for eligible, ineligible and overall
 gen_index_vers cesd_score, prefix(cesd_score_z) label("CES-D score (std)")


 /* WVS */

 /* Control over one's own fate */
  gen wvs_fate = s13_q21 if s13_q21 != 88
  tab wvs_fate, m
  la var wvs_fate "WVS fate raw"

* generate standardized version by elig, inelig, all
gen_index_vers wvs_fate, prefix(wvs_fate_z) label("WVS fate (std)")


/* Checking for missing values of other questions */
tab1 s13_q22 s13_q23 s13_q24, m
gen wvs_trust = s13_q22 if s13_q22 != 88
la var wvs_trust "WVS trust raw"

gen wvs_happiness = s13_q23 if s13_q23 != 88
la var wvs_happiness "WVS happiness raw"

* recoding so that higher values are better
recode wvs_happiness (1=4) (2=3) (3=2) (4=1)
la define wvs_happy 4 "Very happy" 3 "Quite happy" 2 "Not very happy" 1 "Not at all happy"
la values wvs_happiness wvs_happy


gen wvs_satisfaction = s13_q24 if s13_q24 != 88
la var wvs_satisfaction "WVS satisfaction raw"

foreach var of varlist wvs_trust wvs_happiness wvs_satisfaction {
    local vlab = substr("`var'", 5, .)

    gen_index_vers `var', prefix(`var'_z) label("`vlab' (std)")
 }

/* Generalised self-efficacy (Schwarzer and Jerusalem 1995) */

 * Rename individual items
 ren s14_se_3a s14_se_3
 forval i = 1/10 {
     tab s14_se_`i', m
     gen selfeff_`i' = s14_se_`i'

 }

 * Recode to missing
 recode selfeff_* (min/-1 99/max = .)

 * Rowtotal creates the (row) sum of the variables in varlist, treating missing as 0.  If missing is specified and all values in varlist are missing for an observation, newvar is set to missing.
 egen selfeff_score = rowtotal(selfeff_1-selfeff_10), m

 * Rowmiss gives the number of missing values in varlist for each observation (row).
 egen selfeff_nummiss = rowmiss(selfeff_1-selfeff_10)

 * Drop obs. with over 3 items missing
 replace selfeff_score = . if selfeff_nummiss > 3

 * Inflate scores to account for missing
 replace selfeff_score = selfeff_score * 10 / (10 - selfeff_nummiss)

 label var selfeff_score "Self-efficacy"
 tab selfeff_score,m
 tab selfeff_score if subcounty != "SIAYA", m
 //didn't run in Siaya, want to check num missing outside of Siaya

/* TO DO: double check that Self-efficacy question numbers are the same, then bring in labels from endline */


 * Standardize to control mean and SD by eligibility and overall
 gen_index_vers selfeff_score, prefix(selfeff_score_z) label("Self-efficacy, std")


/* Indicator variables, calculating by eligibility */

 xtile fatemedian_e = wvs_fate if eligible == 1, n(2)
 replace fatemedian_e = fatemedian_e - 1
  la var fatemedian_e "Above median WVS Fate, eligible HHs"

  xtile fatemedian_ie = wvs_fate if eligible == 0, n(2)
  replace fatemedian_ie = fatemedian_ie - 1
   la var fatemedian_ie "Above median WVS Fate, ineligible HHs"

 gen fatemedian = fatemedian_e if eligible ==1
 replace fatemedian = fatemedian_ie if eligible == 0
 la var fatemedian "Above median WVS fate, by eligibility"

 xtile semedian_e = selfeff_score if eligible == 1, n(2)
 replace semedian_e = semedian_e - 1
 la var semedian_e "Above median self-efficacy, eligible HHs"

 xtile semedian_ie = selfeff_score if eligible == 0, n(2)
 replace semedian_ie = semedian_ie - 1
 la var semedian_ie "Above median self-efficacy, ineligible HHs"

 gen semedian = semedian_e if eligible == 1
 replace semedian = semedian_ie if eligible == 0
 la var semedian "Above median self-efficacy, by eligibility"


* reverse coding cesd for index, generating overall index
foreach suf in e ie  {
    if "`suf'" == "e" local cond "if eligible == 1"
    if "`suf'" == "ie" local cond "if eligible == 0"

    gen cesd_score_z_neg_`suf' = - cesd_score_z_`suf'

    di "suf: `suf' cond: `cond' nb: `nb'"

    egen p5_psych_index_`suf' = weightave(cesd_score_z_neg_`suf' wvs_happiness wvs_satisfaction) `cond', normby(control_lowsat`nb')

    la var p5_psych_index_`suf' "Subjective well-being index"
    note p5_psych_index_`suf' : baseline version only contains CES-D, happiness and satistfaction. Did not collect stress as part of baseline

    local cond ""
}
// setting values "outside sample" to missing
replace p5_psych_index_e = . if eligible != 1
replace p5_psych_index_ie = . if eligible != 0
* generating overall measure normalized by moments for each separately
gen p5_psych_index = p5_psych_index_e if eligible == 1
replace p5_psych_index = p5_psych_index_ie if eligible == 0
la var p5_psych_index "P5 Psych Index, all HHs, normalized by eligibility"



** Pre-specified measure of heterogeneity: above/below median for pysch index **
summ p5_psych_index if eligible == 1, d
gen highpsych = (p5_psych_index > r(p50)) if ~mi(p5_psych_index) & eligible == 1
summ p5_psych_index if eligible == 0, d
replace highpsych = (p5_psych_index > r(p50)) if ~mi(p5_psych_index) & eligible == 0
la var highpsych "Above median baseline psych index"



 /****************************************/
 /* SECTION 14: ASPIRATIONS OUTCOMES     */
 /****************************************/

 /* Locus of control */

 * Replace as missing
    recode s14_loc_* (min/-1 99/max = .)

 * LOC construct subscales
 egen loc_intscore = rowtotal(s14_loc_1a s14_loc_11 s14_loc_14 s14_loc_4 s14_loc_8), m
 label var loc_intscore "Locus of control - internal"
 egen loc_fatescore = rowtotal(s14_loc_10 s14_loc_15 s14_loc_3 s14_loc_5 s14_loc_9), m
 label var loc_fatescore "Locus of control - fate"
 egen loc_othersscore = rowtotal(s14_loc_12 s14_loc_13 s14_loc_21 s14_loc_23 s14_loc_24 s14_loc_6a s14_loc_7), m
 label var loc_othersscore "Locus of control - powerful others"

 * Count missing items
 egen loc_intmiss = rowmiss(s14_loc_1a s14_loc_11 s14_loc_14 s14_loc_4 s14_loc_8)
 egen loc_fatemiss = rowmiss(s14_loc_10 s14_loc_15 s14_loc_3 s14_loc_5 s14_loc_9)
 egen loc_othersmiss = rowmiss(s14_loc_12 s14_loc_13 s14_loc_21 s14_loc_23 s14_loc_24 s14_loc_6a s14_loc_7)

 * Drop if missing 2 or more items
 replace loc_intscore = . if loc_intmiss > 1
 replace loc_fatescore = . if loc_fatemiss > 1
 replace loc_othersscore = . if loc_othersmiss > 2

 * Inflate score to account for missing
 replace loc_intscore = loc_intscore * 5 / (5 - loc_intmiss)
 replace loc_fatescore = loc_fatescore * 5 / (5 - loc_fatemiss)
 replace loc_othersscore = loc_othersscore * 7 / (7 - loc_othersmiss)

 * Standardize to control mean and SD
 foreach var of varlist loc_*score {
     loc vlab : var label `var'
     loc newlab = subinstr("`vlab'", "raw", "std", 1)

     gen_index_vers `var', prefix(`var'_z) label("`newlab'")
 }

 /* THESE VARIABLES HAVE CHANGED FROM ASP PILOTING - NEED TO MAKE SURE I KNOW HOW TO PROPERLY CONSTRUCT THESE
    BEFORE MOVING FORWARD
 *locus of control measure
 	forval x=1/15 {
 	recode loc`x' -55=. -99=. -77=.
 	}

 	egen loc_int=rowtotal(loc1 loc4 loc8 loc11 loc14)
 	egen loc_fate=rowtotal(loc3 loc5 loc9 loc10 loc15)
 	egen loc_others=rowtotal(loc2 loc6 loc7 loc12 loc13)

 	egen locmiss=rowmiss(loc1 loc2 loc3 loc4 loc5 loc6 loc7 loc8 loc9 loc10 loc11 loc12 loc13 loc14 loc15)

 	foreach x in int fate others {
 	replace loc_`x'=. if locmiss>3 & locmiss~=.
 	}

 	label var loc_int "Locus of control - internal"
 	label var loc_fate "Locus of control - fate"
 	label var loc_others "Locus of control - powerful others"

 	drop selfeffmiss gritmiss locmiss
 */



 /* Aspirations (Bernard et al 2014) */

 gen a_income = s14_income_asp
 gen a_assets = s14_assets_asp

 recode a_income a_assets (min/-1 999 995 998 99 = .)

 encode s14_i_girl_edu_asp, gen(a_girledu)
 replace a_girledu = . if inrange(a_girledu, 1, 3)
 replace a_girledu = a_girledu + 9 if inrange(a_girledu, 4, 7)
 replace a_girledu = a_girledu + 1 if inrange(a_girledu, 8, 13)
 replace a_girledu = 0 if a_girledu == 14
 replace a_girledu = 4 if a_girledu == 15
 replace a_girledu = 5 if a_girledu == 16
 replace a_girledu = 7 if a_girledu == 17
 replace a_girledu = 8 if a_girledu == 18
 replace a_girledu = a_girledu - 6 if inrange(a_girledu, 19, 23)

 encode s14_i_boy_edu_asp, gen(a_boyedu)
 replace a_boyedu = . if inrange(a_boyedu, 1, 3)
 replace a_boyedu = a_boyedu + 9 if inrange(a_boyedu, 4, 7)
 replace a_boyedu = a_boyedu + 1 if inrange(a_boyedu, 8, 13)
 replace a_boyedu = 0 if a_boyedu == 14
 replace a_boyedu = 4 if a_boyedu == 15
 replace a_boyedu = 6 if a_boyedu == 16
 replace a_boyedu = 8 if a_boyedu == 17
 replace a_boyedu = a_boyedu - 5 if inrange(a_boyedu, 18, 22)

 egen a_edu = rowmean(a_girledu a_boyedu)
 la var a_edu "Education aspirations raw"

 recode s14_macarthur_asp (11/max = .), gen(a_social)
 la var a_social "Social aspirations raw"

 foreach var in a_income a_assets a_edu a_social {

     * updating to calculate standardization by eligibility status
     local vargen "gen"
     forval elig = 0 / 1 {
         qui sum `var' if eligible == `elig', d
         local p1 = r(p1)
         local p99 = r(p99)
         qui sum `var' if inrange(`var', `p1', `p99') & control_lowsat == 0 & eligible == `elig'
         `vargen' `var'_std = (`var' - `r(mean)') / `r(sd)' if inrange(`var', `p1', `p99') & eligible == `elig'

         local vargen "replace"
     }
// end of loop by eligibility status
 }
 // end of variable loop


label var a_income_std "Income aspirations std by eligibility"
label var a_assets_std "Wealth aspirations std by eligibility"
label var a_edu_std "Education aspirations std by eligibility"
label var a_social_std "Social status aspirations std by eligibility"


gen a_index = ((a_income_std * s14_beans_income) + (a_assets_std * s14_beans_assets) + (a_edu_std * s14_beans_edu) + (a_social_std * s14_beans_social)) / 20 if s14_beans_total == "20"
la var a_index "Aspirations Index"

*** naming variables for consistency with hh welfare PAP ***
// should the following be standardized values or not? using standardized for now, as it's easier for me to interpret
ren cesd_score h5_1_cesd
la var  h5_1_cesd "Depression (CESD 20 question)"

ren wvs_happiness_z* h5_2_happiness*
ren wvs_satisfaction_z* h5_3_satisfaction*
ren a_index h5_5_asp
ren selfeff_score_z* h5_6_selfeff*
ren loc_fatescore_z* h5_7_loc*

** saving **
drop s13_* s14_*
save "$da/intermediate/GE_HH-BL_psych.dta", replace
project, creates("$da/intermediate/GE_HH-BL_psych.dta")
