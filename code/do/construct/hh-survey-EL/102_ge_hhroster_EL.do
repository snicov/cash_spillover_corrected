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

/*
 * Filename: ge_hhendline_vars_hhroster.do
 *
 * Description: creates variables describing basic features of respondents using endline
 *   data for GE household endline analysis dataset.
 *
 * NOTE ON 12/4 - RIGHT NOW JUST TRYING TO GET INFO ON HOUSEHOLD SIZE UP AND RUNNING. REST WILL COME LATER
 *
 * INPUT: dataset created by previous do file in construct_hhbaseline_analysis.do
 * OUTPUT: new temporary dataset with the following variables, to be used by following do file
 *     in construct_hhbaseline_analysis.do
 *
 *  LIST OF VARIABLES:
  - number of household members
  - household-level indicators for max education, number of workers, adults and children
  - children's education and educational spending

* Author: Michael Walker
* Date created: 25 May 2017, the first part adopted from ge_outcomes_hhbaseline_2016-05-03.do
*/

** setting up to use intermediate dataset for more modular running
project, uses("$da/intermediate/GE_HH-EL_setup.dta")

use "$da/intermediate/GE_HH-EL_setup.dta", clear

keep s1_hhid_key village_code s2_q4a_age s4_*
/*********************************************/
/* SECTION 4: NUMBER OF CHILDREN IN HH       */
/*********************************************/

/** NUMBER OF HOUSEHOLD MEMBERS **/
tab s4_q1_hhmembers
* max number of hh members: 15 - this is used in later loops
gen hhsize1 = 1 + s4_q1_hhmembers
la var hhsize1 "Number of hh members"
char define hhsize1[vnote] "(S4Q1 + 1)"

* temporary - school-aged children count
gen hhros_num_sch_aged = 0 /* if s4_nonmiss > 0 & s4_nonmiss != .*/
gen hhros_num_in_sch = 0
gen numadults = 1 // assuming FR is an adult
gen numprimeage = 0
local primeagemax = 55

replace numprimeage = 1 if (s2_q4a_age >= 18 & s2_q4a_age < `primeagemax')

cap tostring s4_1_q8_occup_15, replace

forval i=1/15 {
	replace hhros_num_sch_aged = hhros_num_sch_aged + 1 if (s4_1_q5_age_`i' >=3 & s4_1_q5_age_`i' <=18) | (strpos(s4_1_q8_occup_`i', "50") > 0) // the latter condition is tricky, since some older people will be in school. Counting age as unknown or age > 18 & in school as school aged, but only if they are still a student
	replace hhros_num_in_sch = hhros_num_in_sch + 1 if strpos(s4_1_q8_occup_`i', "50") > 0
  replace numadults = numadults + 1 if s4_1_q5_age_`i' >=18 & ~mi(s4_1_q5_age_`i')
  replace numprimeage = numprimeage + 1 if s4_1_q5_age_`i' >=18 & s4_1_q5_age_`i' < `primeagemax' & ~mi(s4_1_q5_age_`i')
}



/* Note: the following method uses the wide form of the data. There are some aspects that may
  be more elegant using long form. Switching to that below but keeping this part, just commenting out

/* not counting those that didn't sleep at home last night */
forval i=1/15 {
	gen hh_roscount`i' = 0 if s4_q2_rosnum`i' != .
	replace hh_roscount`i' = 1 if s4_q3_sleep`i' == 1
}
egen hhsize2 = rowtotal(hh_roscount*)
replace hhsize2 = hhsize2 + 1 //adding in respondent

tab hhsize1, m
tab hhsize2, m
summ hhsize*


gen hhros_num_sch_aged = 0/* if s4_nonmiss > 0 & s4_nonmiss != .*/
gen hhros_num_in_sch = 0

forval i=1/15 {
	replace hhros_num_sch_aged = hhros_num_sch_aged + 1 if (s4_q5_age`i' >=3 & s4_q5_age`i' <=18) | (s4_q8_occup`i' == "50") *the latter condition is tricky, since some older people will be in school. Counting age as unknown or age > 18 & in school as school aged, but only if they are still a student
	replace hhros_num_in_sch = hhros_num_in_sch + 1 if s4_q8_occup`i' == "50"
}

tab hhros_num_sch_aged, m /*this does not pick up students at boarding school. Can more easily construct this for Ugunja, but ignoring for now*/
tab hhros_num_in_sch, m

* generating percent - missing values for all households with no school-aged children
gen hhros_pct_in_sch = hhros_num_in_sch / hhros_num_sch_aged if hhros_num_sch_aged > 0 & hhros_num_sch_aged != .
summ hhsize* hhros_num* hhros_pct*

END WIDE VERSION
*/

/*
forval i=1/15 {
    assert s4_q8_occupother`i' == ""
    drop s4_q8_occupother`i'
}
*/

/*
/** Generating variables from household roster data - converting to long **/
* preserving data before reshape
preserve

keep village_code s1_hhid_key s4_*

/* ignoring occupation for now
forval i=1/15 {
    replace s4_q8_occup`i' = subinstr(s4_q8_occup`i', "other", "777", 1)
}
*/

count
summ s4_q1_hhmembers // these two provide info on number of obs that we should have in roster data

reshape long s4_q2_rosnum s4_q3_sleep s4_q4_sex s4_q5_age s4_q5a_estimatedage s4_q6_relation s4_q7_educ s4_q8_occup s4_q8_occup_other  s4_q9_schoolatt, i(village_code s1_hhid_key) j(hhmember)

count
drop if s4_q2_rosnum == . // these should all be missing - keep seeing the same number of missing obs, reshape seems to be creating 15 hh members for all households. we don't want obs for the rest

* splitting occupation variable
//split s4_q8_occup , gen(hhmem_occ) destring

/* Alternate count of number of household members - only those that spent the night the previous night */
tab s4_q3_sleep, m
recode s4_q3_sleep (1 = 1) (2 = 0), gen(slept_here)
tab slept_here, m


/** AGE VARIABLES **/

tab s4_q5_age, m
recode s4_q5_age 999 = ., gen(age)


gen adults      = age >= 18   if ~mi(age)
gen primeage    = age >=18 & age <60 if ~mi(age)
gen children    = age < 18    if ~mi(age)
gen under6      = age <= 6    if ~mi(age)
gen under3      = age <= 3    if ~mi(age)
gen under1      = age <=1     if ~mi(age)
gen sch_aged    = (children == 1 & under3 == 0) if ~mi(age)

/*
* additional indicators on the basis of Olken-Singhal equivalency scales
gen osinfant = age <= 4         if ~mi(age)
gen oschild = age > 4 & age <=14 if ~mi(age)
gen osadult = age > 14            if ~mi(age)
*/

* making best guess based on missing ages, in order to ensure that overall totals match
tab hhmember if age== .
tab s4_q6_relation if age == .
* setting spouse, any parents / grandparents to adults
replace adults = 1 if (s4_q6_relation == 6 | s4_q6_relation == 2 | s4_q6_relation == 4 | s4_q6_relation == 5) & age == .

/*
* for children/others, harder to classify - basing on status and standard completed
tab1 hhmem_occ? if age == . & adults == .
tab1 s4_q7_educ if age == . & adults == . & hhmem_occ1 == 50

/** come back to finishing this **/
*/

/** GENDER **/
tab s4_q4_sex, m
* lots of these are missing - not sure why. will have to look back into that.

/** RELATIONSHIP TO FR **/
tab s4_q6_relation, m // looks like same number of obs as sex - did we not collect this for some subcounties?
gen spouse = (s4_q6_relation == 6) if ~mi(s4_q6_relation) // most useful for figuring out hh head


/* Cleaning other occupations */
/*
* need to come back and clear out other for resolved cases.
* NOTE: these are occcupations. May not be current. endline survey would be best for this.

* too young responses - make sure ages are not DK
gen tooyoung = inlist(s4_q8_occup_other, "9 month old", "A child", "A kid who is still at home", "Has not started going to school", "Has not started school yet", "Hasn't started school", "No work,still a minor", "still young to be in school")
replace tooyoung = 1 if inlist(s4_q8_occup_other, "Not in school", "Not of school age", "Not schooling", "Not started schooling", "Not yet started school", "She is 7month old", "Still a baby not yet joined school", "Still a kid", "Still very young")
replace tooyoung = 1 if strpos(lower(s4_q8_occup_other),  "still young") > 0

gen disabled = inlist(s4_q8_occup_other, "She sick cannot perform any job", "She is lame just at home", "None(Paralyzed)", "No work Aneta is sickling", "Mentally challenged", " Mentally ill", "Mentally unstable", "Just at home and she is completely ill", "He can't talk neither speak")
replace disabled = 1 if inlist(s4_q8_occup_other, "Blind does no work", "Currently ill and bed ridden.")
replace disabled = 1 if strpos(s4_q8_occup_other, "Is mentally disturbed therefore depen") > 0

* student
tab s4_q8_occup if  s4_q8_occup_other == "In collage" | s4_q8_occup_other == "Started school this term" | s4_q8_occup_other == "Pupil" // all other - can be replaced
replace s4_q8_occup = "50" if s4_q8_occup_other == "In collage" | s4_q8_occup_other == "Started school this term" | s4_q8_occup_other == "Pupil"

* no work
tab s4_q8_occup if inlist(s4_q8_occup_other, "She is just at home", "None", "No occupation", "No job FRS wife is bed wriden", "No job", "Never started schooling no work", "Just stays at home no occupation", "Just stays at home", "Just at home") | inlist(s4_q8_occup_other, "Don't do anything") | disabled == 1
replace s4_q8_occup = "60" if inlist(s4_q8_occup_other, "She is just at home", "None", "No occupation", "No job FRS wife is bed wriden", "No job", "Never started schooling no work", "Just stays at home no occupation", "Just stays at home", "Just at home")
replace s4_q8_occup = "60" if inlist(s4_q8_occup_other, "Don't do anything")
replace s4_q8_occup = "60" if disabled == 1

*assuming retired
tab s4_q8_occup if s4_q8_occup_other== "Very old they are just at home" | s4_q8_occup_other == "They are over 100years hence don't know" | s4_q8_occup_other == "Over aged just at home" // all other, can be replaced
replace s4_q8_occup = "61" if s4_q8_occup_other== "Very old they are just at home" | s4_q8_occup_other == "They are over 100years hence don't know" | s4_q8_occup_other == "Over aged just at home" // check age for 2nd one

* various types of selling - is this the best fit for all of these?
replace s4_q8_occup = subinstr(s4_q8_occup, "777", "6", 1) if inlist(s4_q8_occup_other, "Business lady, sells ropes", "Burns charcoal") // need to add more here

* Vehicle taxi - including bikes, motorcycles
replace s4_q8_occup = subinstr(s4_q8_occup, "777", "14", 1) if strpos(lower(s4_q8_occup_other), "boda") > 0 | strpos(lower(s4_q8_occup_other), "piki") > 0 | s4_q8_occup_other == "Conductor of a matatu" | strpos(lower(s4_q8_occup_other), "motorcycle") > 0

* NGO field worker - code 27

replace s4_q8_occup = subinstr(s4_q8_occup, "777", "14", 1) if s4_q8_occup_other == "Field Officer/ evidence action"


* other skilled construction
replace s4_q8_occup = subinstr(s4_q8_occup, "777", "71", 1) if s4_q8_occup_other == "Fundi Plastic"


* local brewer - code 78
replace s4_q8_occup = subinstr(s4_q8_occup, "777", "78", 1) if inlist(s4_q8_occup_other, "Brewing alcohol", "Local Brewer")

* bicycle repair - code 79
replace s4_q8_occup = subinstr(s4_q8_occup, "777", "79", 1) if s4_q8_occup_other == "Repairs bicycles"

* shoes - code 81
replace s4_q8_occup = subinstr(s4_q8_occup, "777", "81", 1) if inlist(s4_q8_occup_other,"Cobbler", "Cobler")

* bricks - code 82
replace s4_q8_occup = subinstr(s4_q8_occup, "777", "82", 1) if strpos(lower(s4_q8_occup_other), "brick") > 0

//"Making bricks for building houses."

* Religious leader - code 83
replace s4_q8_occup = subinstr(s4_q8_occup, "777", "83", 1) if s4_q8_occup_other == "Preacher/Priest"


/* Generating indicators from occupational status */


* Ag loop
gen hhmem_ag = 0 if ~mi(s4_q8_occup) | hhmem_occ1 != 99
forval i=1/4 {
    replace hhmem_ag = 1 if inlist(hhmem_occ`i', 1, 3, 4)
}
gen hhmem_sch = 0 if ~mi(s4_q8_occup) | hhmem_occ1 != 99
forval i=1/4 {
    replace hhmem_sch = 1 if hhmem_occ`i' == 50
}
/*
this and the next are a bit hard to classify with current list. Will want to review again */
gen hhmem_selfemp = 0 if ~mi(s4_q8_occup) | hhmem_occ1 != 99
forval i=1/4 {
    replace hhmem_selfemp = 1 if hhmem_occ`i' == 5 | hhmem_occ`i' == 6 | hhmem_occ`i' == 7 | hhmem_occ`i' == 9
}
gen hhmem_emp = 0 if ~mi(s4_q8_occup) | hhmem_occ1 != 99
forval i=1/4 {
    replace hhmem_emp = 1 if hhmem_occ`i' == 2 | hhmem_occ`i' == 8 | hhmem_occ`i' == 10
}

gen notworking = 0 if ~mi(s4_q8_occup) | hhmem_occ1 != 99 // only want to exclude if don't know for any occupation
forval i = 1/4 {
    replace notworking = 1 if hhmem_occ`i' == 50 | hhmem_occ`i' == 60 | hhmem_occ`i' == 61
}
tab1 hhmem_occ* if notworking == 1 // for now, assuming that any cases of multiple mean this is a past, not current occupation

gen student = 0 if ~mi(s4_q8_occup) | hhmem_occ1 != 99
forval i=1/4 {
    replace student = 1 if hhmem_occ`i' == 50
}
tab student
tab age if student == 1


recode notworking 0=1 1=0, gen(workers)
*/

/** EDUCATIONAL ATTAINMENT **/
tab s4_q7_educ, m
recode s4_q7_educ 131 = .
gen years_edu = s4_q7_educ - 100
replace years_edu = 14 if s4_q7_educ==115 | s4_q7_educ == 117 | s4_q7_educ==119
replace years_edu = 15 if s4_q7_educ==116 | s4_q7_educ == 118 | s4_q7_educ==120 | s4_q7_educ==121
replace years_edu = 0 if s4_q7_educ == 130
replace years_edu = . if s4_q7_educ == 122 // special education - not sure how else to code this

tab years_edu
tab s4_q7_educ if years_edu > 12

/* generating spouse variables */
gen spouse_age = age if spouse == 1
gen spouse_edu = years_edu if spouse == 1

/** SAVING HH ROSTER FOR ANALYSIS **/
save "$da/intermediate/GE_HH-Endline_HHRoster_long.dta", replace
project, creates("$da/intermediate/GE_HH-Endline_HHRoster_long.dta") preserve


//collapse (sum) workers adults children numchild1 = under1 numchild3 = under3 numchild6 = under6 numschage = sch_aged hhsize2 = slept_here numstudents = student (max) max_age = age max_edu = years_edu (mean) spouse_age spouse_edu (sum) num_spouse = spouse (sum) num_osadult = osadult (sum) num_oschild = oschild (sum) num_osinfant = osinfant, by(village_code s1_q4_respid)
collapse (sum) adults primeage children numchild1 = under1 numchild3 = under3 numchild6 = under6 numschage = sch_aged  (max) max_age = age max_edu = years_edu (mean) spouse_age spouse_edu (sum) num_spouse = spouse, by(village_code s1_hhid_key)
//ren workers numworkers
ren primeage numprimeage
ren adults numadults
ren children numchildren

//replace hhsize2 = hhsize2 + 1 // adding back in FR

//la var numworkers "Number of workers (ag, self-emp or emp) in HH, HH roster"
la var numadults "Number of adults (>=18) in HH, HH roster"
la var numchildren "Number of children (<18) in HH, HH roster"
la var numschage "Number of school-aged children in HH (>3,<18), HH roster"
//la var numstudents "Number of students in HH, HH roster"
la var numchild6 "Number of young children in HH (<=6), HH roster"
la var numchild3 "Number of children 3 or under in HH, HH roster"
la var numchild1 "Number of children 1 or under in HH, HH roster"
//la var hhsize2 "Number of household members that slept at home last night"
la var max_age "Oldest household member on hh roster"
la var max_edu "Maximum education attainment by household member on hh roster"
la var spouse_age "Spouse age (mean if more than 1), HH roster"
la var spouse_edu "Spouse years of education (mean if more than 1), HH roster"
la var num_spouse "Number of spouses, HH roster"
/*
la var num_osadult "Number of adults (>14), HH roster"
la var num_oschild "Number of children (5-14), HH roster"
la var num_osinfant "Number of infants (<4), HH roster"
*/

tempfile hhroster
save `hhroster'


restore
merge 1:1 village_code s1_hhid_key using `hhroster', gen(_mhhros)
tab _mhhros // all should merge - from same dataset
drop _mhhros
tab hhsize2, m
replace hhsize2 = 1 if s4_q1_hhmembers == 0 & hhsize2 == . // filling in for those that did not have roster

foreach var of varlist numworkers numadults numchildren numschage numstudents numchild6 numchild3 numchild1 num_spouse num_osadult num_oschild num_osinfant {
    replace `var' = 0 if hhsize1 == 1 // if household size 1 == 1, then no roster
}


* augmenting count of adults to take into account FR
tab age
gen fr_under18 = age < 18 // ignoring missing values here so totals below will work
gen fr_over18 = age >= 18  // considering those with missing age over 18

replace numadults = numadults + fr_over18
replace numchildren = numchildren + fr_under18
replace numschage = numschage + fr_under18

//replace num_osadult = num_osadult + 1 // adding in FR, all 15 or over


gen haschildhh = (numchildren > 0) if ~mi(numchildren)
la var haschildhh "Indicator for children living in the household"

* summing counts of workers to take into account FR
gen fr_selfagworker = 0 if s7_q1_selfag == 2
replace fr_selfagworker = 1 if s7_q6_selfhoursworked1 > 0 & ~mi(s7_q6_selfhoursworked1)
replace fr_selfagworker = 1 if s7_q6_selfhoursworked2 > 0 & ~mi(s7_q6_selfhoursworked2)
replace fr_selfagworker = 1 if s7_q6_selfhoursworked3 > 0 & ~mi(s7_q6_selfhoursworked3)


tab1 s8_q1_selfemployed s9_q1_employed

gen fr_worker = (s8_q1_selfemployed == 1 | s9_q1_employed == 1 | fr_selfagworker == 1)
count if fr_worker == .

replace numworkers = numworkers + fr_worker

* checking for consistency between age-related household summaries and total number of household members - what to do about cases where age was not known?
egen hhros_numcheck1 = rowtotal(numadults numchildren)
egen hhros_numcheck2 = rowtotal(num_osadult num_oschild num_osinfant)

count if hhros_numcheck1 != hhsize1
count if hhros_numcheck2 != hhsize1
*/

//drop s4_*

** saving dataset, indicating dependencies **
compress
save "$da/intermediate/GE_HH-EL_hhroster.dta", replace
project, creates("$da/intermediate/GE_HH-EL_hhroster.dta")
