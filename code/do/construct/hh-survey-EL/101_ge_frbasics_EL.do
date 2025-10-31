/*
 * Filename: 101_ge_frbasics_EL.do
 *
 * Description: creates variables describing basic features of respondents using endline
 *   data for GE household endline analysis dataset. We want to run this first as it includes
 *   a number of preliminaries, such as household size, that will be used later. Repurposes baseline do file.
 *
 * THIS NEEDS TO BE UPDATED [INPUT: dataset created by previous do file in construct_hhbaseline_analysis.do
 * OUTPUT: new temporary dataset with the following variables, to be used by following do file
 *     in construct_hhbaseline_analysis.do]
 *
 *  LIST OF VARIABLES:
  - FR age, year of birth, age indicators
 - marital status
 - educational attainment (and indicators)
 - gender

* Author: Michael Walker
* Date created: 4 Dec 2017, from ge_hhb_vars_frbasics.do
* Last modified: 14 Oct 2019, bringing in modular data structure and project command
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

// end preliminaries





** load dataset **
* starting point - dataset with basic setup (merging with HH master, etc)
project, uses("$da/intermediate/GE_HH-EL_setup.dta")
use "$da/intermediate/GE_HH-EL_setup.dta", clear

/***** FR AGE *****/
destring s2_q4_dob s2_q4_mob s2_q4_yob s2_q4a_yobestimated s2_q4a_age s2_q4a_agecalc , replace
foreach var of varlist s2_q4_dob s2_q4_mob s2_q4_yob s2_q4a_yobestimated s2_q4a_age s2_q4a_agecalc {
	tab `var', m
}

*replacing 99+ values that are estimated age with missing
replace s2_q4a_age = . if s2_q4a_yobestimated == 1 & s2_q4a_age >=99
* replacing 99+ values that don't have a year of birth - assuming similar to estimated
replace s2_q4a_age = . if s2_q4a_age >= 99 & s2_q4_yob == .

list s2_q4* if s2_q4a_age >=99 & s2_q4a_age != .

tab s2_q4a_age if s2_q4a_yobestimated == 1

recode s2_q4_dob s2_q4_mob s2_q4_yob s2_q4a_age (-99 9999 = .)


list today s2_q4* if abs(s2_q4a_age - s2_q4a_agecalc) > 1 & s2_q4a_age != . & s2_q4a_agecalc != .



/* Currently using reported age - could also use year of birth instead */
destring s2_q4a_agecalc*, replace

count if s2_q4a_age > s2_q4a_agecalc | s2_q4a_age < s2_q4a_agecalc1
list s2_q4* if s2_q4a_age > s2_q4a_agecalc | s2_q4a_age < s2_q4a_agecalc1

/* CALCULATING AGE: RULES
 1. If they gave a full date of birth, using this in the calculation
 2. If they gave a month and year of birth, using this in the calculation (assuming born on 15th)
 2a. If YOB & age within 1 year, use given age
 3. If they gave a year of birth and it was not estimated, and s2_q4a_age differs by more than 1
     year, using year of survey - yob
 4. If they gave a year of birth and it was estimated, and s2_q4a_age differs by more than 1 year,
     take stated age
*/

gen fr_birthday = mdy(s2_q4_mob, s2_q4_dob, s2_q4_yob) if s2_q4_mob != . & s2_q4_dob != . & s2_q4_yob != .
replace fr_birthday = mdy(s2_q4_mob, 15, s2_q4_yob) if s2_q4_mob != . & s2_q4_dob == . & s2_q4_yob != .
la var fr_birthday "FR date of birth"

* checking survey date
tab today, m

gen age = floor((today - fr_birthday) / 365)
replace age = s2_q4a_age 		if s2_q4a_age != . & abs(s2_q4a_agecalc - s2_q4a_age) <= 1
replace age = yofd(today) - s2_q4_yob 	if age == . & s2_q4_yob != . & s2_q4a_yobestimated == 2 & abs(s2_q4a_agecalc - s2_q4a_age) > 1
replace age = s2_q4a_age		if age == . & s2_q4a_age != . & s2_q4a_yobestimated == 1 & abs(s2_q4a_agecalc - s2_q4a_age) > 1
replace age = s2_q4a_age 		if age == . & s2_q4_yob == .
la var age "FR age"

tab age, m

/** Indicators based on age **/
* First, indicators for different age cutoffs

recode age (6/17 = 1) (nonm = 0), gen(age6)
la var age6 "Age 6-17"

recode age (18/24 = 1) (nonm = 0), gen(age18)
la var age18 "Age 18-24"

recode age (25/39 = 1) (nonm = 0), gen(age25)
la var age25 "Age 25-39"

recode age (40/59 = 1) (nonm = 0), gen(age40)
la var age40 "Age 40-59"

recode age (60/max = 1) (nonm = 0), gen(age60)
la var age60 "Age 60 or older"


* Second, new variable that groups ages into bins
gen agegrp = .

* generating age groups - can later check how this looks by gender
local i = 15
local agegrp = 4
label define agegrp 3 "10 to 14"

while `i' < 100 {
	local j = `i' + 5
	replace agegrp = `agegrp' if age >=`i' & age < `j'
	label define agegrp `agegrp' "`i' to `j'", add
	local ++agegrp
	local i = `i' + 5
}
replace agegrp = 21 if age>=100 & age != .
label define agegrp 21 "Over 100", add
label values agegrp agegrp
la var agegrp "FR age, grouped"
tab agegrp, m



/***** PLACE OF BIRTH *****/
/*
tab s2_q5a_country, m
// note: there are still some inconsistencies here- people listing couny as busia uganda, but country as Kenya, etc.

tab s2_q5b_county, m
destring s2_q5b_county, replace

tab s2_q5d_town, m // did not ask for people born in Siaya
tab s2_q5d_town_other
replace s2_q5d_town = "777" if s2_q5d_town == "other"
destring s2_q5d_town, replace
replace s2_q5d_town = 3 if inlist(s2_q5d_town_other, "Kisumu town")
replace s2_q5d_town = 7 if s2_q5d_town_other == "Kampala"
replace s2_q5d_town = 6 if s2_q5d_town_other == "Nakuru"
replace s2_q5d_town_other = "" if inlist(s2_q5d_town_other, "Kampala", "Kisumu town", "Nakuru") // consider mamboleo part of kisumu?

* still more cleaning that can be done for these, but able to create variables below with this as is

* INDICATOR FOR BORN IN SIAYA COUNTY
gen born_siaya = (s2_q5b_county == 10) if ~mi(s2_q5b_county)
la var born_siaya "FR born in Siaya County"
tab born_siaya, m

* INDICATOR FOR BORN IN CITY
recode s2_q5d_town (2/7 = 1) (nonm = 0), gen(born_city)
replace born_city = 0 if s2_q5b_county == 1 // If born in Siaya, not born in city. Did not ask this question for people born in Siaya.
la var born_city "Born in a city"
tab born_city, m


* INDICATOR FOR BORN IN SAME VILLAGE NOW LIVING IN
gen born_samevill = (s2_q5g_village_code == s1_q2c_village)
la var born_samevill "Born in same village in which currently living"
tab born_samevill, m

*/

/***** ANY CLAN INDICATORS HERE? *****/
* options: could try to consolidate these into common ones, there's a lot of spelling issues at the moment




/***** GENDER *****/

tab s2_q3_gender

// note: this was coded differently in the SurveyCTO version than in the baseline survey
gen male = (s2_q3_gender == 1) if s2_q3_gender != .
la var male "Indicator for FR male"
recode male (1 = 0) (0 = 1), gen(female)
la var female "Indicator for FR female"

* are all of these filled in? we don't want any missing
tab male, m
tab female, m


/***** MARITAL STATUS *****/
tab s5_q12_maritalstatus, m
tab s5_q12_maritalstatus, m nol


/* generating indicators */
gen single = (inlist(s5_q12_maritalstatus, 1,7,8)) if s5_q12_maritalstatus != . /*what do we include in single? Include cohabitating?*/
la var single "FR single/separated/divorced"
gen married = (inlist(s5_q12_maritalstatus,2,3,4)) if s5_q12_maritalstatus != .
la var married "FR married or cohabitating (not poly)"
gen poly = (inlist(s5_q12_maritalstatus, 5,6)) if s5_q12_maritalstatus != .
la var poly "FR polygamous"
gen widowed = (s5_q12_maritalstatus==9) if s5_q12_maritalstatus != .
la var widowed "FR widowed"
tab single, m
tab married, m
tab poly, m
tab widowed



/***** EDUCATIONAL ATTAINMENT *****/

tab s5_q1_system, m
tab s5_q1a_highestedu, m

* no schooling response for system
gen yearsedu = 0 if s5_q1_system==2

/* current school system (s4_1_q7_edusystem == 1)- stds 1 -8, then forms 1 - 4 */
/* Up through form 4 are coded from 101 - 112, so subtracting off 100 */

replace yearsedu = s5_q1a_highestedu - 100 if s5_q1_system == 1

/* previous school system (s4_1_q7_edusystem == 3) - stds 1 - 7, forms 1 - 6 */
/* there is no 208 code so need to account for this when subtracting off years of education */
replace yearsedu = s5_q1a_highestedu - 200 if s5_q1_system == 3 & s5_q1a_highestedu<=207
replace yearsedu = s5_q1a_highestedu - 201 if s5_q1_system == 3 & s5_q1a_highestedu>207 & s5_q1a_highestedu<215 /* need to take one extra year off for forms */

** Setting ECD/pre-K to 0 **
replace yearsedu = 0 if s5_q1a_highestedu == 130 | s5_q1a_highestedu == 230

** no one in special ed categories **
count if s5_q1a_highestedu == 122 | s5_q1a_highestedu == 222


/* Following KLPS (at least parent) methodology */
replace yearsedu = 14 if s5_q1a_highestedu==115 | s5_q1a_highestedu == 117 | s5_q1a_highestedu==119
replace yearsedu = 15 if s5_q1a_highestedu==116 | s5_q1a_highestedu == 118 | s5_q1a_highestedu==120 | s5_q1a_highestedu==121

/* Alternative method */
gen yearsedu_alt = yearsedu
replace yearsedu_alt = 13 if s5_q1a_highestedu==115 | s5_q1a_highestedu==117
replace yearsedu_alt = 14 if s5_q1a_highestedu == 116 | s5_q1a_highestedu==118
replace yearsedu_alt = 15 if s5_q1a_highestedu==119
replace yearsedu_alt = 16 if s5_q1a_highestedu==120
replace yearsedu_alt = 17 if s5_q1a_highestedu==121

tab yearsedu, m
tab yearsedu_alt, m

label var yearsedu "FR years of education (14=incomplete coll/univ/poly, 15=complete coll/univ/poly)"
label var yearsedu_alt "FR years of education (up to 17 for higher ed)"

/** EDUCATION LEVEL INDICATORS **/
gen noschool = s5_q1_system == 2 if ~mi(s5_q1_system)
replace noschool = 1 if s5_q1a_highestedu == 130 | s5_q1a_highestedu == 230
la var noschool "No schooling"

gen stdschool = yearsedu >= 8 & ~mi(yearsedu) if s5_q1_system == 1
replace stdschool = yearsedu >= 7 & ~mi(yearsedu) if s5_q1_system == 3
replace stdschool = 0 if noschool == 1
la var stdschool "Completed primary school"

gen someformschool = yearsedu > 8 & ~mi(yearsedu) if s5_q1_system == 1
replace someformschool = yearsedu > 7 & ~mi(yearsedu) if s5_q1_system == 3
replace someformschool = 0 if noschool == 1
la var someformschool "Some secondary school"

gen formschool = yearsedu >= 12 if s5_q1_system == 1
replace formschool = yearsedu > 12 if s5_q1_system == 1 // inequality here as under previous system had to finish 13 years
replace formschool = 0 if noschool == 1
la var formschool "Completed secondary school"


** save dataset here, keeping only generated variables **
keep s1_hhid_key village_code today fr_birthday age* yearsedu* *school single married poly widowed
save "$da/intermediate/GE_HH-EL_frbasics.dta", replace
project, creates("$da/intermediate/GE_HH-EL_frbasics.dta")
