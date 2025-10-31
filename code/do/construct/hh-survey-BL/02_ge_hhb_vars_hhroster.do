/*
 * Filename: ge_hhb_vars_hhroster.do
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
  - number of household members
  - household-level indicators for max education, number of workers, adults and children
  - children's education and educational spending

* Author: Michael Walker
* Date created: 25 May 2017, the first part adopted from ge_outcomes_hhbaseline_2016-05-03.do
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

keep hhid_key today village_code eligible s1_q4_respid s4_* s5_* s7_q1_selfag s7_q6_selfhoursworked* s8_q1_selfemployed s9_q1_employed // come back for s5 -- need to be more precise depending on keep strategy

** bringing in age from FR basics **
project, uses("$da/intermediate/GE_HH-BL_frbasics.dta") preserve
merge 1:1 hhid_key using "$da/intermediate/GE_HH-BL_frbasics.dta", keepusing(age)

/*********************************************/
/* SECTION 4: NUMBER OF CHILDREN IN HH       */
/*********************************************/

/** NUMBER OF HOUSEHOLD MEMBERS **/
tab s4_q1_hhmembers
* max number of hh members: 15 - this is used in later loops
gen hhsize1 = 1 + s4_q1_hhmembers
la var hhsize1 "Number of hh members"
char define hhsize1[vnote] "(S4Q1 + 1)"


/** Generating variables from household roster data - converting to long **/
* preserving data before reshape
preserve

keep village_code s1_q4_respid s4_*

forval i=1/15 {
    replace s4_q8_occup`i' = subinstr(s4_q8_occup`i', "other", "777", 1)
}

count
summ s4_q1_hhmembers // these two provide info on number of obs that we should have in roster data

reshape long s4_q2_rosnum s4_q3_sleep s4_q4_sex s4_q5_age s4_q5a_estimatedage s4_q6_relation s4_q7_educ s4_q8_occup s4_q8_occup_other  s4_q9_schoolatt, i(village_code s1_q4_respid) j(hhmember)

count
drop if s4_q2_rosnum == . // these should all be missing - keep seeing the same number of missing obs, reshape seems to be creating 15 hh members for all households. we don't want obs for the rest

* splitting occupation variable
split s4_q8_occup , gen(hhmem_occ) destring

/* Alternate count of number of household members - only those that spent the night the previous night */
tab s4_q3_sleep, m
recode s4_q3_sleep (1 = 1) (2 = 0), gen(slept_here)
tab slept_here, m


/** AGE VARIABLES **/

tab s4_q5_age, m
recode s4_q5_age 999 = ., gen(age)


gen adults      = age >= 18   if ~mi(age)
gen children    = age < 18    if ~mi(age)
gen under6      = age <= 6    if ~mi(age)
gen under3      = age <= 3    if ~mi(age)
gen under1      = age <=1     if ~mi(age)
gen sch_aged    = (children == 1 & under3 == 0) if ~mi(age)

* making best guess based on missing ages, in order to ensure that overall totals match
tab hhmember if age== .
tab s4_q6_relation if age == .
* setting spouse, any parents / grandparents to adults
replace adults = 1 if (s4_q6_relation ==  16| s4_q6_relation == 6 | s4_q6_relation == 2 | s4_q6_relation == 4 | s4_q6_relation == 5) & age == .

* for children/others, harder to classify - basing on status and standard completed
tab1 hhmem_occ? if age == . & adults == .
tab1 s4_q7_educ if age == . & adults == . & hhmem_occ1 == 50

/** come back to finishing this **/

/** GENDER **/
tab s4_q4_sex, m
* lots of these are missing - not sure why. will have to look back into that.

/** RELATIONSHIP TO FR **/
tab s4_q6_relation, m // looks like same number of obs as sex - did we not collect this for some subcounties?
gen spouse = (s4_q6_relation == 6) if ~mi(s4_q6_relation) // most useful for figuring out hh head


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
*/
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
save "$da/GE_HH-Baseline_HHRoster_long.dta", replace
project, creates("$da/GE_HH-Baseline_HHRoster_long.dta") preserve


collapse (sum) workers adults children numchild1 = under1 numchild3 = under3 numchild6 = under6 numschage = sch_aged hhsize2 = slept_here numstudents = student (max) max_age = age max_edu = years_edu (mean) spouse_age spouse_edu (sum) num_spouse = spouse, by(village_code s1_q4_respid)

ren workers numworkers
ren adults numadults
ren children numchildren

replace hhsize2 = hhsize2 + 1 // adding back in FR

la var numworkers "Number of workers (ag, self-emp or emp) in HH, HH roster"
la var numadults "Number of adults (>=18) in HH, HH roster"
la var numchildren "Number of children (<18) in HH, HH roster"
la var numschage "Number of school-aged children in HH (>3,<18), HH roster"
la var numstudents "Number of students in HH, HH roster"
la var numchild6 "Number of young children in HH (<=6), HH roster"
la var numchild3 "Number of children 3 or under in HH, HH roster"
la var numchild1 "Number of children 1 or under in HH, HH roster"
la var hhsize2 "Number of household members that slept at home last night"
la var max_age "Oldest household member on hh roster"
la var max_edu "Maximum education attainment by household member on hh roster"
la var spouse_age "Spouse age (mean if more than 1), HH roster"
la var spouse_edu "Spouse years of education (mean if more than 1), HH roster"
la var num_spouse "Number of spouses, HH roster"

tempfile hhroster
save `hhroster'


restore
merge 1:1 village_code s1_q4_respid using `hhroster', gen(_mhhros)
tab _mhhros // all should merge - from same dataset
drop _mhhros
tab hhsize2, m
replace hhsize2 = 1 if s4_q1_hhmembers == 0 & hhsize2 == . // filling in for those that did not have roster

/* Adding FR back into constructed household roster variables */
// if household size 1 == 1, then no roster. Starting these at zero, then adding FR back in where appropriate
foreach var of varlist numworkers numadults numchildren numschage numstudents numchild6 numchild3 numchild1 num_spouse{
    replace `var' = 0 if hhsize1 == 1
}

* augmenting count of adults to take into account FR
tab age
gen fr_under18 = age < 18 // ignoring missing values here so totals below will work
gen fr_over18 = age >= 18  // considering those with missing age over 18

replace numadults = numadults + fr_over18
replace numchildren = numchildren + fr_under18
replace numschage = numschage + fr_under18

gen haschildhh = (numchildren > 0) if ~mi(numchildren)
la var haschildhh "Indicator for children living in the household"


* summing counts of workers to take into account FR
** TO DO: figure out if there is a better way to deal with this. We may be missing some household members that do ag work on their own farm if, due to seasonality, they did not work on the farm in the last week
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

count if hhros_numcheck1 != hhsize1




/********************************************/
/* SECTION 5: EDUCATION-RELATED OUTCOMES    */
/********************************************/


/*** CHILDREN'S EDUCATION ***/

/* Children attending school */
tab s5_q8_haschildren, m

gen has_children = 0 if s5_q8_haschildren != .
replace has_children = 1 if s5_q8_haschildren == 1
la var has_children "Indicator for having children (S5)"

tab s5_q8a_numchildren, m
gen num_children = s5_q8a_numchildren if s5_q8a_numchildren != .
la var num_children "Number of children (S5)"

replace has_children = 0 if num_children == 0
replace num_children = . if num_children == 98


tab s5_q9_numattendschool, m
gen num_child_school = s5_q9_numattendschool
la var num_child_school "Number of children attending school (S5)"

count if num_child_school > num_children & num_child_school ~= . & num_children != .

gen has_child_sch = (num_child_school>0) if num_child_school != .
tab has_child_sch
label var has_child_sch "Among those w/children, Indicator for having a child in school"
label values has_child_sch yesno

/** TO ADD: CONSISTENCY CHECKS BETWEEN HOUSEHOLD ROSTER SECTION AND THIS SECTION. THERE MAY BE SOME
DISAGREEMENTS BUT MOST SHOULD AGREE **/


** generating indicators for type of school child attending **
tab1 s5_q11_schooltype*
destring s5_q11_schooltype? s5_q11_schooltype??, replace


local schtypes "prim sec coll univ voc"

forval i=1/15 {
    gen schprim`i' = s5_q11_schooltype`i' == 1 if ~mi(s5_q11_schooltype`i')
	gen schsec`i' = s5_q11_schooltype`i' == 2 if ~mi(s5_q11_schooltype`i')
	gen schcoll`i' = s5_q11_schooltype`i' == 3 if ~mi(s5_q11_schooltype`i')
	gen schuniv`i' = s5_q11_schooltype`i' == 4 if ~mi(s5_q11_schooltype`i')
	gen schvoc`i' = s5_q11_schooltype`i' == 5 if ~mi(s5_q11_schooltype`i')
    * come back to fill in the rest
}

/* Total educational expenditures. Still have some outliers here, trimming largest total ed expenditures later*/

/* replacing dk amounts */
recode s5_q14_schfeesterm* s5_q15_suppliescost? s5_q15_suppliescost?? s5_q17_schoolcontribs? s5_q17_schoolcontribs?? (99 88 98 999 9999 = .) // need to look into 96 values a bit more

/** school fees **/
recode s5_q14_schfeesterm* (99 88 98 = .)
forval i=1/15 {
    foreach var of varlist s5_q14_schfeesterm?`i' {
        di "`var'"
        tab `var'
        foreach sch of local schtypes {
            gen `var'_`sch' = `var' if sch`sch'`i' == 1
			tab `var'_`sch'
        }
    }
}

* defintely some outliers that need to be looked into, but will come back to these - check on school level for these, figure out what university costs
tab1 s5_q14_schoolfeesfx* /* children 1, 2 and 4 need to be checked*/


/* STILL TO DO: FIGURE OUT EXACT CORRECTIONS FOR THESE CASES */

forval i=1/2 {
	foreach var of varlist s5_q14_schfeesterm?`i' {
				replace `var' = `var'*$ugx_kes if s5_q14_schoolfeesfx`i' == 2
	}
}



egen school_fees_nonmiss = rownonmiss(s5_q14_schfeesterm*) if has_child_sch==1
egen school_fees_allchildren = rowtotal(s5_q14_schfeesterm*) if has_child_sch == 1, m
la var school_fees_allchildren "Total school fees, among those with children in school"
gen avg_school_fees_perchild = school_fees_allchildren / num_child_school
la var avg_school_fees_perchild "Mean school fees paid per child, among those w/child in sch"
summ school_fees_allchildren avg_school_fees*

foreach sch of local schtypes {
    egen schfees_`sch'_allchildren = rowtotal(s5_q14_schfeesterm*_`sch') if has_child_sch == 1, m
    la var schfees_`sch'_allchildren "School fees for `sch', among those with children in sch"
}


/** school supplies **/
forval i=1/15 {
    foreach var of varlist s5_q15_suppliescost`i' {
        di "`var'"
        tab `var'
        foreach sch of local schtypes {
            gen `var'_`sch' = `var' if sch`sch'`i' == 1
        }
    }
}


tab1 s5_q15_suppliescostfx*/*will want to check all of these, but starting with just 1*/

forval i=1/5 {
	replace s5_q15_suppliescost`i' = s5_q15_suppliescost`i'*$ugx_kes if s5_q15_suppliescostfx`i' == 2
}


egen school_supplies_nonmiss = rownonmiss(s5_q15_suppliescost? s5_q15_suppliescost??) if has_child_sch==1
egen school_supplies_allchildren = rowtotal(s5_q15_suppliescost? s5_q15_suppliescost??) if has_child_sch==1, m
la var school_supplies_allchildren "Total spending on school supplies, among those w/child in sch"
gen avg_school_supplies_perchild = school_supplies_allchildren / num_child_school
la var avg_school_supplies_perchild "Mean supply spending per child, among those w/child in sch"

local schtypes "prim" // sec coll univ voc"
foreach sch of local schtypes {
    egen schsupplies_`sch'_allchildren = rowtotal(s5_q15_suppliescost*_`sch') if has_child_sch == 1, m
    la var schsupplies_`sch'_allchildren "School supply spending for `sch', among those with children in sch"
}

summ school_supplies_allchildren avg_school_supplies*

/** school contributions **/
* note: asked if there were any development projects before asking about contributions
forval i=1/15 {
    foreach var of varlist s5_q17_schoolcontribs`i' {
        di "`var'"
        tab `var'
        foreach sch of local schtypes {
            gen `var'_`sch' = `var' if sch`sch'`i' == 1
        }
    }
}

tab1 s5_q17_schoolcontribsfx*

egen school_contribs_nonmiss = rownonmiss(s5_q17_schoolcontribs? s5_q17_schoolcontribs??) if has_child_sch==1
egen schcontrib_childschdev = rowtotal(s5_q17_schoolcontribs? s5_q17_schoolcontribs??) if has_child_sch==1, m
la var schcontrib_childschdev "Total school contributions, among those w/child in sch & dev project"

gen schcontrib_childsch = schcontrib_childschdev
replace schcontrib_childsch = 0 if has_child_sch == 1 & mi(schcontrib_childsch) // setting to zero for those with a child in school but no development project spending
la var schcontrib_childsch "Total school contribs, among those w/child in sch"

gen schcontrib_allchild     = schcontrib_childsch
replace schcontrib_allchild = 0 if haschildhh == 1 & mi(schcontrib_allchild) // setting zero for any households with children in the household, but no school contributions
la var schcontrib_allchild "Total school contributions, all hhs with children (zero if no child in sch)"

gen schcontrib_all = schcontrib_allchild
replace schcontrib_all = 0 if ~mi(haschildhh) & mi(schcontrib_all)
la var schcontrib_all "Total school contributions, all hhs (zero for those w/o children in school)"


gen avg_schcontrib_perchild = schcontrib_childsch / num_child_school
la var avg_schcontrib_perchild "Mean school contribs per child, among those w/child in sch"
summ schcontrib_childsch avg_schcontrib_perchild*



foreach sch of local schtypes {
    egen schcontrib_`sch'_childschdev   = rowtotal(s5_q17_schoolcontribs*_`sch'), m
    la var schcontrib_`sch'_childschdev "School contribs for `sch', among those with children in school & dev project"
    egen schcontrib_`sch'_childsch      = rowtotal(s5_q17_schoolcontribs*_`sch') if has_child_sch == 1
    la var schcontrib_`sch'_childsch "School contribs for `sch', among those with children in sch"

    gen schcontrib_`sch'_allchild       = schcontrib_`sch'_childsch
    replace schcontrib_`sch'_allchild   = 0 if haschildhh == 1 & has_child_sch == 0
    la var schcontrib_`sch'_allchild "School contribs for `sch', among those with children"

    gen schcontrib_`sch'_all       = schcontrib_`sch'_allchild
    replace schcontrib_`sch'_all   = 0 if haschildhh == 0
    la var schcontrib_`sch'_all    "School contribs for `sch', all households"
}

summ schcontrib*

/** total educational expenses **/

egen total_edu_expenses = rowtotal(school_fees_allchildren  school_supplies_allchildren  schcontrib_childsch) if has_child_sch == 1
la var total_edu_expenses "Total education expenses, among those w/child in sch"
gen total_edu_expenses_all = total_edu_expenses
replace total_edu_expenses_all = 0 if has_child_sch == 0 | has_children == 0 // assuming no education expenses for those with no children in school, no children
la var total_edu_expenses_all "Total education expenses, all HH"


summ total_edu_expenses*

count if has_child_sch == 1 & total_edu_expenses == 0 /*these seem like strange cases, will want to look into these and child ages */

summ total_edu_expenses, d
summ total_edu_expenses if s5_q8_haschildren == 1, d
summ total_edu_expenses if s5_q9_numattendschool>0 & s5_q9_numattendschool!=.

summ total_edu_expenses, d
trim_top1 total_edu_expenses total_edu_expenses_all
wins_top1 total_edu_expenses total_edu_expenses_all

summ total_edu_expenses*, d

gen avg_ttl_edu_exp_perchild = total_edu_expenses / num_child_school
la var avg_ttl_edu_exp_perchild "Mean total edu expenses per child, cond child in sch"

trim_top1 avg_ttl_edu_exp_perchild
wins_top1 avg_ttl_edu_exp_perchild

* total primary school expenses *
foreach sch of local schtypes {
    egen total_edu_`sch'_allchildren = rowtotal(schfees_`sch'_allchildren schsupplies_`sch'_allchildren schcontrib_`sch'_childsch) if has_child_sch == 1, m
    la var total_edu_`sch'_allchildren "Total education expenses for `sch', among those with children in sch"
    trim_top1 total_edu_`sch'_allchildren
    wins_top1 total_edu_`sch'_allchildren
}

** proportion of school age children in school **
/* for now, basing this off of the household roster. consider if there are any ways that
    would more closely match endline data during endline code review */
gen prop_sch = numstudents / numschage
tab prop_sch
la var prop_sch "Proportion of school-aged children in school (HH roster)"


/*** EDUCATION INDEX ***/
gen_index_vers prop_sch total_edu_expenses_wins, prefix(p7_edu_index) label("Education index")


** saving, keeping only generated variables **
// dropping kept survey variables
drop s4_* s5_* s7_q1_selfag s7_q6_selfhoursworked* s8_q1_selfemployed s9_q1_employed

save "$da/intermediate/GE_HH-BL_hhroster.dta", replace
project, creates("$da/intermediate/GE_HH-BL_hhroster.dta")
