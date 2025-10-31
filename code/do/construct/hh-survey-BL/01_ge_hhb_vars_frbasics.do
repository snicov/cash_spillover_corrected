/*
 * Filename: ge_hhb_vars_frbasics.do
 *
 * Description: creates variables describing basic features of respondents using baseline
 *   data for GE household baseline analysis dataset. This will be useful for calculating summary
 *   stats.
 *
 * INPUT: dataset created by previous do file in construct_hhbaseline_analysis.do
 * OUTPUT: new temporary dataset with the following variables, to be used by following do file
 *     in construct_hhbaseline_analysis.do
 *
 *  LIST OF VARIABLES:
 - eligibility status
 - FR age, year of birth, age indicators
 - marital status
 - educational attainment (and indicators)
 - gender

* Author: Michael Walker
* Date created: 25 May 2017, adapting from ge_controls_hhbaseline_2015-12-09.do
*/

/* Preliminaries - commenting out so that these can be run as a group */
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

//project, original("$do/programs/run_ge_build_programs.do")
//include "$do/programs/run_ge_build_programs.do" // check to make sure files are using these

// end preliminaries

*** loading setup dataset ***
project, uses("$da/intermediate/GE_HH-BL_setup.dta")
use "$da/intermediate/GE_HH-BL_setup.dta", clear

keep hhid_key village_code today key s1_* s2_* s5_* s6_q0*

/***** ELIGIBILITY STATUS VARIABLES (MEASURED AT BASELINE) *****/

foreach var of varlist s6_q0a_floor s6_q0b_roof s6_q0c_walls {
	tab `var', m
}


gen floor_elig = 0 if s6_q0a_floor != "" // restrict this to not being other as well? We'd want to clean the other ones
replace floor_elig = 1 if s6_q0a_floor=="mud"
gen roof_elig = 0 if s6_q0b_roof != ""
replace roof_elig = 1 if s6_q0b_roof=="grass" | s6_q0b_roof=="leaves"
gen walls_elig = 0 if s6_q0c_walls != ""
replace walls_elig = 1 if s6_q0c_walls=="mud"

la var floor_elig "Traditional (mud) floors"
la var roof_elig "Traditional (thatch) roof"
la var walls_elig "Traditional (mud) walls"


gen eligible_baseline = 0
replace eligible_baseline = 1 if roof_elig==1
la var eligible_baseline "Eligible (thatched-roof), BL survey"

gen eligible_all_BL = 0
replace eligible_all_BL = 1 if roof_elig == 1 & floor_elig == 1 & walls_elig == 1
la var eligible_all_BL "Eligible (100\% traditional), BL survey"

tab eligible_baseline, m
tab eligible_all_BL, m

count
count if eligible_baseline != eligible_all_BL // less than 1/2 of 1%. Not too worried about this.

tab village_code eligible_baseline, m


/***** FR AGE *****/

foreach var of varlist s2_q4_dob s2_q4_mob s2_q4_yob s2_q4_yobestimated s2_q4a_age s2_q4a_agecalc {
	tab `var', m
}

list today s2_q4* if abs(s2_q4a_age - s2_q4a_agecalc) > 1 & s2_q4a_age != . & s2_q4a_agecalc != .

list s2_q4* if inlist(s2_q4_dob, 205, 997) | (s2_q4_mob >12 & ( s2_q4_mob != 99 & s2_q4_mob != 9999 & s2_q4_mob !=.))

replace s2_q4_dob = . if inlist(s2_q4_dob, 0, 96, 99, 205, 997, 9999)
replace s2_q4_mob = . if inlist(s2_q4_mob, 0, 99, 9999)
replace s2_q4_yob = . if inlist(s2_q4_yob, 99,999,9999)
replace s2_q4_yob = s2_q4_yob + 1900 if inlist(s2_q4_yob, 32,49,71,82)

tab s2_q4a_age if s2_q4_dob == . & s2_q4_mob== . & s2_q4_yob == .
list s2_q4* if s2_q4a_age == 1943
replace s2_q4a_age = 73 if s2_q4a_age == 1943

tab s2_q4a_age if s2_q4a_age >=99 & s2_q4a_age != .

replace s2_q4a_age = . if s2_q4a_age ==999

*replacing 99+ values that are estimated age with missing
replace s2_q4a_age = . if s2_q4_yobestimated == 1 & s2_q4a_age >=99
* replacing 99+ values that don't have a year of birth - assuming similar to estimated
replace s2_q4a_age = . if s2_q4a_age >= 99 & s2_q4_yob == .

list s2_q4* if s2_q4a_age >=99 & s2_q4a_age != .

tab s2_q4a_age if s2_q4_yobestimated == 1


/* Currently using reported age - could also use year of birth instead */
destring s2_q4a_agecalc*, replace


*count if s2_q4a_age > s2_q4a_agecalc | s2_q4a_age < s2_q4a_agecalc1 /* FIGURE OUT WHAT'S GOING WRONG HERE - WHY DON'T WE HAVE AGECALC1? */
*list s2_q4* if s2_q4a_age > s2_q4a_agecalc | s2_q4a_age < s2_q4a_agecalc1

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
replace age = yofd(today) - s2_q4_yob 	if age == . & s2_q4_yob != . & s2_q4_yobestimated == 2 & abs(s2_q4a_agecalc - s2_q4a_age) > 1
replace age = s2_q4a_age		if age == . & s2_q4a_age != . & s2_q4_yobestimated == 1 & abs(s2_q4a_agecalc - s2_q4a_age) > 1
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

* generating age groups - basic pattern looks similar (see Aakash's code review file for details)
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

** Pre-specified measure of heterogeneity: over age 25 at baseline
gen age25up = (age >= 25) if ~mi(age)
tab age25up
la var age25up "Respondent aged 25 or older"


/***** PLACE OF BIRTH *****/
/*
tab s2_q5a_country, m
replace s2_q5a_country = "1" if s2_q5a_country_other == "Busia" // county lists Busia as well, is this Kenya or Uganda?

tab s2_q5b_county, m
replace s2_q5b_county = "10" if s2_q5b_county_other == "Bondo"
replace s2_q5b_county_other = "" if s2_q5b_county_other == "Bondo"
replace s2_q5b_county = "777" if s2_q5b_county == "other"
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
*/

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




/***** GENDER *****/
tab s1_q7_ressex, m
tab s1_q7_ressex, nol

tab s2_q3_gender

count if s2_q3_gender!=s1_q7_ressex



* ensuring that all fixed
count if s2_q3_gender != s1_q7_ressex
list key s1_hhid_key s1_q7_ressex s2_q3_gender if s2_q3_gender!=s1_q7_ressex // will need to look into these

gen male = (s2_q3_gender == 2) if s2_q3_gender != .
la var male "Indicator for FR male"
recode male (1 = 0) (0 = 1), gen(female)
la var female "Indicator for FR female"

* are all of these filled in? we don't want any missing
tab male, m
tab female, m


/***** MARITAL STATUS *****/
tab s5_q7_maritalstatus, m
tab s5_q7_maritalstatus, m nol


/* generating indicators */
gen single = (inlist(s5_q7_maritalstatus, 1,7,8)) if s5_q7_maritalstatus != . /*what do we include in single? Include cohabitating?*/
la var single "FR single/separated/divorced"
gen married = (inlist(s5_q7_maritalstatus,2,3,4)) if s5_q7_maritalstatus != .
la var married "FR married or cohabitating (not poly)"
gen poly = (inlist(s5_q7_maritalstatus, 5,6)) if s5_q7_maritalstatus != .
la var poly "FR polygamous"
gen widowed = (s5_q7_maritalstatus==9) if s5_q7_maritalstatus != .
la var widowed "FR widowed"
tab single, m
tab married, m
tab poly, m
tab widowed



/***** EDUCATIONAL ATTAINMENT *****/

tab s5_q1_system, m
tab s5_q1a_highestedu, m
tab s5_q2_higheredu, m
tab s5_q2a_highestotheredu, m
tab s5_q2a_highestotheredu

destring s5_q1a_highestedu s5_q2a_highestotheredu, replace

/* looking into voc ed */



gen yearsedu = 0 if s5_q1_system=="noschooling"
replace yearsedu = s5_q1a_highestedu - 100 if s5_q1_system == "current"
replace yearsedu = s5_q1a_highestedu - 200 if s5_q1_system == "previous" & s5_q1a_highestedu<=207
replace yearsedu = s5_q1a_highestedu - 201 if s5_q1_system == "previous" & s5_q1a_highestedu>207 & s5_q1a_highestedu<215 /* need to take one extra year off for forms */
replace yearsedu = 0 if s5_q1a_highestedu == 130 | s5_q1a_highestedu == 230

tab yearsedu if s5_q2a_highestotheredu != . & s5_q2a_highestotheredu != 888
replace s5_q2a_highestotheredu = . if s5_q2a_highestotheredu==888

/* Following KLPS (at least parent) methodology */
replace yearsedu = 14 if s5_q2a_highestotheredu==115 | s5_q2a_highestotheredu == 117 | s5_q2a_highestotheredu==119
replace yearsedu = 15 if s5_q2a_highestotheredu==116 | s5_q2a_highestotheredu == 118 | s5_q2a_highestotheredu==120 | s5_q2a_highestotheredu==121

/* Alternative method */
gen yearsedu2 = yearsedu
replace yearsedu2 = 13 if s5_q2a_highestotheredu==115 | s5_q2a_highestotheredu==117
replace yearsedu2 = 14 if s5_q2a_highestotheredu == 116 | s5_q2a_highestotheredu==118
replace yearsedu2 = 15 if s5_q2a_highestotheredu==119
replace yearsedu2 = 16 if s5_q2a_highestotheredu==120
replace yearsedu2 = 17 if s5_q2a_highestotheredu==121

tab yearsedu, m
tab yearsedu2, m

label var yearsedu "FR years of education (14=incomplete coll/univ/poly, 15=complete coll/univ/poly)"
label var yearsedu2 "FR years of education (up to 17 for higher ed)"

/** EDUCATION LEVEL INDICATORS **/
gen noschool = s5_q1_system == "noschooling" if ~mi(s5_q1_system)
la var noschool "No schooling"

gen stdschool = s5_q1a_highestedu > 107 & s5_q1a_highestedu != 130 & s5_q1a_highestedu != 122 if s5_q1_system == "current"
replace stdschool = s5_q1a_highestedu > 206 & s5_q1a_highestedu != 230 & s5_q1a_highestedu != 222 if s5_q1_system == "previous"
replace stdschool = 0 if s5_q1_system == "noschooling"
la var stdschool "Completed primary school"

gen someformschool = s5_q1a_highestedu > 108 & s5_q1a_highestedu != 130 & s5_q1a_highestedu != 122 if s5_q1_system == "current"
replace someformschool = s5_q1a_highestedu > 207 & s5_q1a_highestedu != 230 & s5_q1a_highestedu != 222 if s5_q1_system == "previous"
replace someformschool = 0 if s5_q1_system == "noschooling"
la var someformschool "Some secondary school"

gen formschool = s5_q1a_highestedu > 111 & s5_q1a_highestedu != 130 & s5_q1a_highestedu != 122 if s5_q1_system == "current"
replace formschool = s5_q1a_highestedu > 211 & s5_q1a_highestedu != 230 & s5_q1a_highestedu != 222 if s5_q1_system == "previous"
replace formschool = 0 if s5_q1_system == "noschooling"
la var formschool "Completed secondary school"


** saving dataset, keeping only generated variables **
keep *hhid_key village_code today fr_birthday age* yearsedu* *male *school single married poly widowed *_elig eligible* born*

save "$da/intermediate/GE_HH-BL_frbasics.dta", replace
project, creates("$da/intermediate/GE_HH-BL_frbasics.dta")
