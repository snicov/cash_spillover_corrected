/*
 * Filename: ge_hhb_vars_localpf.do
 * Description: This do file creates outcomes related to local public finance and household
 *   preferences for redistribution.
 *
 * Inputs: (requires indicators from assets_income on self-emp and emp status)
 * Outputs:
 *
 * List of variables: (see Variable_Definition_Directory.xlsx)
 * -
 *
 * Note: with a number of these I may want to do a similar check as to the self-employment, where I make sure that positive contribution amounts are reported instead of just the survey question response
 *
 * Author: Michael Walker
 * Date: 25 May 2017, adopted from ge_hhb_outcomes_localpf_2017-03-03.do
 */

glo hour_labor_rate = 33 // this is from endline data on daily ag labor from VEs. Will want to come up with an updated number at some point.



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

keep *hhid_key village_code eligible treat hi_sat s1_q1b_ipaid s8_* s9_* s10_* s11_*

project, uses("$da/intermediate/GE_HH-BL_income_revenue.dta") preserve
merge 1:1 hhid_key using "$da/intermediate/GE_HH-BL_income_revenue.dta"


/*** FORMAL TAX TOTALS ***/

* Total county taxes - hhs paying taxes, annual
egen totctytax = rowtotal(selfemp_licamt_ann_emp selfemp_mktfees_ann_emp selfemp_ctytaxoth_ann_emp), missing
la var totctytax "Total county taxes (license, mkt fee, other selfemp), annual, those paying taxes"
tab totctytax if selfemp == 1, m // should have amounts for all of these
tab totctytax if selfemp == 0 // should not have amounts here - unclear how county collects from households
// is this measure the same as conditional on self employment - need to figure this out, and figure out what is the preferred way to describe


* Total county taxes - all households, annual
egen totctytax_all = rowtotal(selfemp_licamt_ann_all selfemp_mktfees_ann_all selfemp_ctytaxoth_ann_all), m
count if totctytax_all == . // should be none
la var totctytax_all "Total county taxes, annual, all hhs"

* monthly county taxes
egen totctytax_mth = rowtotal(selfemp_licamt_mth_emp selfemp_mktfees_mth_emp	 selfemp_ctytaxoth_mth_emp), m
la var totctytax_mth "Total county taxes, last mth, among those paying" // check if same as conditional on self employment
bys selfemp: tab totctytax_mth

egen totctytax_mth_all = rowtotal(selfemp_licamt_mth_all selfemp_mktfees_mth_all selfemp_ctytaxoth_mth_all), m
la var totctytax_mth_all "Total county taxes, last month, all hhs"

* winsorizing and trimming
wins_top1 totctytax totctytax_??? totctytax_mth_all
trim_top1 totctytax totctytax_??? totctytax_mth_all


* generating indicators
gen any_ctytax_selfemp = totctytax_all > 0 if selfemp == 1
la var any_ctytax_selfemp "Any county taxes for those in self-employment"

gen any_cty_taxes = (totctytax_all > 0) if ~mi(totctytax_all)
la var any_cty_taxes "Any county taxes, all hhs"

count if any_cty_taxes != any_ctytax_selfemp

* Total national taxes, those in emp or selfemp
egen totnatltax = rowtotal(emp_income_tax_ann_emp selfemp_natl_taxes_ann_emp), m
la var totnatltax "Total national taxes (income, selfemp), annual, among those in selfemp or emp"

gen totnatltax_pos = totnatltax if totnatltax > 0
la var totnatltax_pos "Total national taxes, annual, cond $>0$"

egen totnatltax_all = rowtotal(emp_income_tax_ann_all selfemp_natl_taxes_ann_all)
la var totnatltax_all "Total national taxes (annual), all hhs"

* generating monthly values
egen totnatltax_mth = rowtotal(emp_income_tax_mth_emp selfemp_natl_taxes_mth_emp), m
la var totnatltax_mth "Total national taxes (last mth), among those in selfemp or emp"

egen totnatltax_mth_all = rowtotal(emp_income_tax_mth_all selfemp_natl_taxes_mth_all), m
la var totnatltax_mth_all "Total national taxes (last mth), all hhs"

* winsorizing and trimming
wins_top1 totnatltax totnatltax_??? totnatltax_mth_all
trim_top1 totnatltax totnatltax_??? totnatltax_mth_all


* generating indicators
gen any_natl_taxes_empselfemp = (totnatltax_all > 0) if selfemp == 1 | emp == 1 & ~mi(totnatltax_all)
la var any_natl_taxes_empselfemp "Any national taxes, among those selfemp or emp"

gen any_natl_taxes = (totnatltax_all > 0) if ~mi(totnatltax_all)
la var any_natl_taxes "Any national taxes, all hhs"

count if any_natl_taxes != any_natl_taxes_empselfemp

*** Total formal taxes ***
egen total_formal_taxes = rowtotal(totnatltax_all totctytax_all) // this should be unconditional
gen total_formal_taxes_pos = total_formal_taxes if total_formal_taxes > 0 // conditional total

* By employment type
egen selfemp_tot_formaltax_ann = rowtotal(selfemp_natl_taxes_ann_all selfemp_licamt_ann_all selfemp_mktfees_ann_all selfemp_ctytaxoth_ann_all) if selfemp == 1, m
la var selfemp_tot_formaltax_ann "Total selfemp formal taxes, among selfemp"

gen totformtax_empselfemp = total_formal_taxes if selfemp == 1 | emp == 1
la var totformtax_empselfemp "Total formal taxes, among those in selfemp or emp"

la var total_formal_taxes "Total formal taxes (county + national), all hhs"
la var total_formal_taxes_pos "Total formal taxes, cond $> 0$"


* are there any additional variables that should be created here? main idea would be to condition on age or work status
wins_top1 total_formal_taxes total_formal_taxes_pos totformtax_empselfemp
trim_top1 total_formal_taxes total_formal_taxes_pos totformtax_empselfemp

* generating indicators
gen any_formal_taxes_all = (total_formal_taxes > 0) if ~mi(total_formal_taxes)
la var any_formal_taxes_all "Indicator for any formal taxes, all hhs"

gen any_formal_taxes_empselfemp = (total_formal_taxes > 0) if (selfemp == 1 | emp == 1) & ~mi(total_formal_taxes)
la var any_formal_taxes_empselfemp "Indicator for any formal taxes, among selfemp or emp"

/********************************************/
/*   INFORMAL TAXES		 					*/
/********************************************/

/* Enterprise informal taxes */

tab1 s8_q17f_localtaxes? // no DK/refuse, but what to make of 8?
* Monthly
egen selfemp_inftax_mth_emp = rowtotal(s8_q17f_localtaxes?), m
count if selfemp_inftax_mth_emp == . & selfemp == 1 // should not be many, only any DK values
la var selfemp_inftax_mth_emp "Selfemp informal tax (last mth), among selfemp"

gen selfemp_inftax_mth_pos = selfemp_inftax_mth_emp if selfemp_inftax_mth_emp > 0
la var selfemp_inftax_mth_pos "Selfemp informal tax (last mth), cond $>0$"

gen selfemp_inftax_mth_all = selfemp_inftax_mth_emp
replace selfemp_inftax_mth_all = 0 if selfemp == 0
la var selfemp_inftax_mth_all "Selfemp informal tax (last mth), all hhs"

* Annual
forval i=1/3 {
	gen selfemp_inftax_`i'_ann = s8_q17f_localtaxes`i' * 12
	la var selfemp_inftax_`i'_ann "Selfemp informal tax paid for ent `i' (ann)"
}
egen selfemp_inftax_ann_emp = rowtotal(selfemp_inftax_?_ann), missing
la var selfemp_inftax_ann_emp "Total informal taxes for selfemp (annual), among selfemp"
tab selfemp_inftax_ann_emp if selfemp == 1, m // are there any missing values here?

gen selfemp_inftax_ann_pos 		= selfemp_inftax_ann_emp if selfemp_inftax_ann_emp > 0
la var selfemp_inftax_ann_pos "Total informal taxes for selfemp (annual), cond $>0$"

gen selfemp_inftax_ann_all 		= selfemp_inftax_ann_emp
replace selfemp_inftax_ann_all 	= 0 if selfemp == 0
la var selfemp_inftax_ann_all "Total informal taxes for selfemp (annual), all hhs"

* winsorizing and trimming
wins_top1 selfemp_inftax_ann_??? selfemp_inftax_mth_???
trim_top1 selfemp_inftax_ann_??? selfemp_inftax_mth_???

* generating indicators
gen any_selfemp_inftax_emp 	= selfemp_inftax_ann_all > 0 if selfemp == 1 & ~mi(selfemp_inftax_ann_all)
gen any_selfemp_inftax_all 	= selfemp_inftax_ann_all > 0 if ~mi(selfemp_inftax_ann_all)

la var any_selfemp_inftax_emp "Any selfemp informal taxes, among selfemp"
la var any_selfemp_inftax_all "Any selfemp informal taxes, all hhs"


/***** HARAMBEES *****/
/* Here, I generate measures (both overall, counts and indicators) of total harambee payments and a total of harambee payments on local
public goods */

tab s10_q9_harambee
tab s10_q9a_numharambee

gen any_harambee = (s10_q9_harambee == 1) if s10_q9_harambee != .
label var any_harambee "Indicator for contributed to harambee in last 12 months"

* figure out how to clean this better
recode s10_q9a_numharambee (50 99 = .) // I don't know what to do with the 50 - pretty big outlier, didn't collect information on harmabees up to the max in the loop

forval i = 1/12 {
	di "`i'"
	tab s10_q9b_purpose`i'
	tab s10_q9b_purpose_other`i'
	gen haram_purpose`i' = s10_q9b_purpose`i'
	replace haram_purpose`i' = "11" if haram_purpose`i' == "other"
	destring haram_purpose`i', replace
	replace haram_purpose`i' = 12 if s10_q9b_purpose`i' == "1"
	replace haram_purpose`i' = 8 if s10_q9b_purpose_other`i' == "Church"
	replace s10_q9b_purpose_other`i' = "" if s10_q9b_purpose_other`i' == "Church"
	replace haram_purpose`i' = 9 if s10_q9b_purpose_other`i' == "Wedding" | s10_q9b_purpose_other`i' == "Weding"
	replace s10_q9b_purpose_other`i' = "" if s10_q9b_purpose_other`i' == "Wedding" | s10_q9b_purpose_other`i' == "Weding"
	replace haram_purpose`i' = 14 if s10_q9b_purpose_other`i' == "Chama" | s10_q9b_purpose_other`i' == "Rosca" | s10_q9b_purpose_other`i' == "ROSCA"
	replace s10_q9b_purpose_other`i' = "" if s10_q9b_purpose_other`i' == "Chama" | s10_q9b_purpose_other`i' == "Rosca" | s10_q9b_purpose_other`i' == "ROSCA"

	* replacing based on having church in the string
	gen churchchecka = strpos(s10_q9b_purpose_other`i', "Church")
	gen churchcheckb = strpos(s10_q9b_purpose_other`i', "church")
	gen churchcheck`i' = ((churchchecka > 0 & churchchecka!=.) | (churchcheckb>0 & churchcheckb!=.)) if s10_q9b_purpose_other`i' != ""
	tab s10_q9b_purpose_other`i' if churchcheck`i'==1
	replace haram_purpose`i' = 8 if churchcheck`i' == 1
	replace s10_q9b_purpose_other`i' = "" if churchcheck`i' == 1
	drop churchcheck*


*	replace haram_purpose`i' = 5 if s10_q9b_purpose`i'
*	tab s10_q9b_amount`i'
*	replace s10_q9b_amount`i' = . if s10_q9b_amount`i' == 88 | s10_q9b_amount`i' == 99 | s10_q9b_amount`i' == 999

}

* continued cleaning of harambee purpose codes
replace haram_purpose1 = 1 if inlist(s10_q9b_purpose_other1, "Additional of classrooms in the school", "Community Polytechnic", "Wanted to build more classes", "Purchase of a bus")
replace s10_q9b_purpose_other1 = "" if inlist(s10_q9b_purpose_other1, "Additional of classrooms in the school", "Community Polytechnic", "Wanted to build more classes", "Purchase of a bus")

replace haram_purpose1 = 4 if inlist(s10_q9b_purpose_other1 , "Burial")
replace s10_q9b_purpose_other1 = "" if inlist(s10_q9b_purpose_other1 , "Burial")

replace haram_purpose1 = 6 if inlist(s10_q9b_purpose_other1, "For medical treatment", "Hospital bill", "Medical", "Medical Expenses", "Medical bill", "Medical expenses", "Medication fee", "Accidental treatment")
replace s10_q9b_purpose_other1 = "" if inlist(s10_q9b_purpose_other1, "For medical treatment", "Hospital bill", "Medical", "Medical Expenses", "Medical bill", "Medical expenses", "Medication fee", "Accidental treatment")

replace haram_purpose1 = 7 if inlist(s10_q9b_purpose_other1, "Development group", "For a group activity", "For some group", "Fundraiser for women group", "Group", "Group Contribution", "Group development", "Group fundraising")
replace s10_q9b_purpose_other1 = "" if inlist(s10_q9b_purpose_other1, "Development group", "For a group activity", "For some group", "Fundraiser for women group", "Group", "Group Contribution", "Group development", "Group fundraising")

replace haram_purpose1 = 7 if inlist(s10_q9b_purpose_other1, "Women Group", "Women group", "Youth", "Youth development", "Youth development fundraiser", "Youth development project")
replace s10_q9b_purpose_other1 = "" if inlist(s10_q9b_purpose_other1, "Women Group", "Women group", "Youth", "Youth development", "Youth development fundraiser", "Youth development project")

replace haram_purpose1 = 8 if inlist(s10_q9b_purpose_other1, "Buying motorcycle Present to the priest", "Churh", "Construction of pastors' house")
replace s10_q9b_purpose_other1 = "" if inlist(s10_q9b_purpose_other1, "Buying motorcycle Present to the priest", "Churh", "Construction of pastors' house")

replace haram_purpose1 = 9 if inlist(s10_q9b_purpose_other1 , "Wedding ceremony")
replace s10_q9b_purpose_other1 = "" if inlist(s10_q9b_purpose_other1 , "Wedding ceremony")

replace haram_purpose1 = 13 if inlist(s10_q9b_purpose_other1, "Community development", "Village contibution", "Welcoming Party", "District officer visit")
replace s10_q9b_purpose_other1 = "" if inlist(s10_q9b_purpose_other1, "Community development", "Village contibution", "Welcoming Party", "District officer visit")

replace haram_purpose1 = 14 if inlist(s10_q9b_purpose_other1, "For orphan children","Opherns", "Welfare", "Welfare group", "Welfare groups", "Welfare harambee", "Widows contribution", "Boda boda welfaire")
replace s10_q9b_purpose_other1 = "" if inlist(s10_q9b_purpose_other1, "For orphan children","Opherns", "Welfare", "Welfare group", "Welfare groups", "Welfare harambee", "Widows contribution", "Boda boda welfaire")

replace haram_purpose1 = 15 if inlist(s10_q9b_purpose_other1, "Assets for chama", "Harambee for Mary go round", "Marry go round", "Mary go round", "Mary go round Harambee", "Meet go round", "Merry go round", "Merry go round harambee to boost kitty", "Merry to round")
replace haram_purpose1 = 15 if inlist(s10_q9b_purpose_other1, "Mery go round group", "Mery go round harambee", "ROSCA", "Rosca", "Rosca development", "Rosca harambee", "Rosca tent", "rosca/chama")
replace s10_q9b_purpose_other1 = "" if inlist(s10_q9b_purpose_other1,"Assets for chama", "Harambee for Mary go round", "Marry go round", "Mary go round", "Mary go round Harambee", "Meet go round", "Merry go round", "Merry go round harambee to boost kitty", "Merry to round")
replace s10_q9b_purpose_other1 = "" if inlist(s10_q9b_purpose_other1, "Mery go round group", "Mery go round harambee", "ROSCA", "Rosca", "Rosca development", "Rosca harambee", "Rosca tent", "rosca/chama")

* Purpose 2
replace haram_purpose2 = 1 if inlist(s10_q9b_purpose_other2, "Building more classes")
replace s10_q9b_purpose_other2 = "" if inlist(s10_q9b_purpose_other2, "Building more classes")

replace haram_purpose2 = 5 if inlist(s10_q9b_purpose_other2, "School fee", "For uniform to orphan kids")
replace s10_q9b_purpose_other2 = "" if inlist(s10_q9b_purpose_other2, "School fee", "For uniform to orphan kids")

replace haram_purpose2 = 6 if inlist(s10_q9b_purpose_other2, "Hospital bill")
replace s10_q9b_purpose_other2 = "" if inlist(s10_q9b_purpose_other2, "Hospital bill")

replace haram_purpose2 = 7 if inlist(s10_q9b_purpose_other2, "Group Development", "Group development", "Groups", "Small groups/welfare", "Women group development", "Buying tents for  bodaboda development")
replace s10_q9b_purpose_other2 = "" if inlist(s10_q9b_purpose_other2, "Group Development", "Group development", "Groups", "Small groups/welfare", "Women group development")

replace haram_purpose2 = 8 if inlist(s10_q9b_purpose_other2, "Buying a car for the priest", "Chuch harambee")
replace s10_q9b_purpose_other2 = "" if inlist(s10_q9b_purpose_other2, "Buying a car for the priest", "Chuch harambee")

replace haram_purpose2 = 9 if inlist(s10_q9b_purpose_other2, "Wedding ceremony", "Wedding contribution", "Wedding harambee", "Weding")
replace s10_q9b_purpose_other2 = "" if inlist(s10_q9b_purpose_other2, "Wedding ceremony", "Wedding contribution", "Wedding harambee", "Weding")

replace haram_purpose2 = 13 if inlist(s10_q9b_purpose_other2, "Buying community assets")
replace s10_q9b_purpose_other2 = "" if inlist(s10_q9b_purpose_other2, "Buying community assets")

replace haram_purpose2 = 14 if inlist(s10_q9b_purpose_other2, "Orphanage construction")
replace s10_q9b_purpose_other2 = "" if inlist(s10_q9b_purpose_other2, "Orphanage construction")

replace haram_purpose2 = 15 if inlist(s10_q9b_purpose_other2, "Chama", "Mary-go round Harambee", "Merry go round", "Rosca", "Rossca")

* Purpose 3
replace haram_purpose3 = 1 if s10_q9b_purpose_other3 == "School costruction"
replace s10_q9b_purpose_other3 = "" if s10_q9b_purpose_other3 == "School costruction"

replace haram_purpose3 = 6 if inlist(s10_q9b_purpose_other3, "Hospital bill", "Medical Expenses", "Medication fee")
replace s10_q9b_purpose_other3 = "" if inlist(s10_q9b_purpose_other3, "Hospital bill", "Medical Expenses", "Medication fee")

replace haram_purpose3 = 14 if inlist(s10_q9b_purpose_other3, "Building a house")
replace s10_q9b_purpose_other3 = "" if inlist(s10_q9b_purpose_other3, "Building a house")

tab1 s10_q9b_purpose_other1 s10_q9b_purpose_other2 s10_q9b_purpose_other3 s10_q9b_purpose_other4


/* Updating harambee purpose codes */
label define s7_purp 1	"School Facilities" 2 "Health clinic" 3	"Water resources" 4	"Bereavement" 5	"School scholarship (busary)" 6	"Medical expenses" 7 "Community group development project" 8 "Church" 9 "Wedding" 11 "Other" 12 "Schooling (unspecified)" 13 "Community development/fees (other)" 14 "Social Welfare (other)" 15 "ROSCA/Chama/Merry-go-round"
label values haram_purpose? haram_purpose?? s7_purp

egen haram_amt_cond = rowtotal(s10_q9b_amount?), missing
la var haram_amt_cond "Harambee amount (cond on giving), all purposes"

gen haram_amt_all = haram_amt_cond
replace haram_amt_all = 0 if any_harambee == 0
la var haram_amt_all "Harambee amount, all purposes, all hhs"

forval i=1/12 {
	di "Harambee `i'"
	gen haram_pg`i' = s10_q9b_amount`i' if inlist(haram_purpose`i', 1, 2, 3, 7, 13)
	tab s10_q9b_purpose_other`i' if haram_purpose`i' == 11 | haram_purpose`i' == 12
	gen haram_pg`i'_sch = haram_pg`i'
	replace haram_pg`i'_sch = s10_q9b_amount`i' if haram_purpose`i' == 12
}

* classifying other amounts that seem like public goods / contributions
replace haram_pg1 = s10_q9b_amount1 if inlist(s10_q9b_purpose_other1, "To start a youth group", "Silver jubilee", "Women Group Development(Not member of the group)", "Cultural") // there are still a number of others. There are also others that do not have a reported value. May want to do some checks counting these all as one or the other
replace haram_pg2 = s10_q9b_amount2 if inlist(s10_q9b_purpose_other2, "Sport tournament")

replace haram_pg4 = s10_q9b_amount4 if inlist(s10_q9b_purpose_other4, "Visitors")


/* Main public good variables */
egen haram_amt_pg_cond = rowtotal(haram_pg? haram_pg??) if any_harambee == 1
la var haram_amt_pg_cond "Harambee amount for public goods, cond on giving to haram"
gen haram_amt_pg_all = haram_amt_pg_cond
replace haram_amt_pg_all = 0 if any_harambee == 0
la var haram_amt_pg_all "Harambee amount for public goods (uncond)"

* including undefined school harambees
egen haram_amt_pgsch_cond = rowtotal(haram_pg*_sch ) if any_harambee == 1
la var haram_amt_pgsch_cond "Harambee amount for public goods (incl more sch), cond"
gen haram_amt_pgsch_all = 0 if any_harambee == 0
la var haram_amt_pgsch_all "Harambee amount for public goods (incl more sch), uncond"

* winsorizing and trimming
wins_top1 haram_amt_cond haram_amt_all haram_amt_pg_cond haram_amt_pg_all haram_amt_pgsch_cond haram_amt_pgsch_all
trim_top1 haram_amt_cond haram_amt_all haram_amt_pg_cond haram_amt_pg_all haram_amt_pgsch_cond haram_amt_pgsch_all

* indicators for public good harambees
gen any_haram_pg = (haram_amt_pg_all > 0) if ~mi(haram_amt_pg_all)
gen any_haram_pgsch = (haram_amt_pgsch_all > 0) if ~mi(haram_amt_pgsch_all)
la var any_haram_pg "Any harambee contrib for PGs"
la var any_haram_pgsch "Any harambee contrib for PGs (incl sch)"

/* TO DO: I may want some variables that are at the harambee level from household reports - for each harambee, what is household average contribution, and how does this vary by eligibility? Overall, what is the breakdown in terms of the number of harambees by type? This may provide more traction on whether I should include undefined school contributions - does it seem like there are lots for busary or lots for school construction? */

/** Contributions to village services **/

** other village contributions
tab s10_q11_villagecontrib
tab s10_q11a_villageamt

gen any_villservice_contribs = (s10_q11_villagecontrib == 1)
label var any_villservice_contribs "Indicator for other contributions to village collected by local official"
gen villservice_contrib_amt = s10_q11a_villageamt if any_villservice_contribs == 1
label var villservice_contrib_amt "Amount of contributions to village if contrib>0"
gen villservice_contrib_amt_all = villservice_contrib_amt
replace villservice_contrib_amt_all = 0 if any_villservice_contribs == 0
la var villservice_contrib_amt_all "Amount of contrib to village services, all hhs"

* winsorizing and trimming
wins_top1 villservice_contrib_amt villservice_contrib_amt_all
trim_top1 villservice_contrib_amt villservice_contrib_amt_all


/** Other contributions **/
/* Like harambees, generate a total amt indicator as reference, then check to see if any of these are for public goods */

tab1 s10_q12b_purpose?
tab1 s10_q12b_purpose_other?


forval i = 1/6 {
	di "Other contribution `i'"
	tab s10_q12b_purpose`i'
	tab s10_q12b_purpose_other`i'
	gen othcontrib_purpose`i' = s10_q12b_purpose`i'
	replace othcontrib_purpose`i' = "11" if othcontrib_purpose`i' == "other"
	destring othcontrib_purpose`i', replace
	replace othcontrib_purpose`i' = 12 if s10_q12b_purpose`i' == "1"
	replace othcontrib_purpose`i' = 8 if strpos(lower(s10_q12b_purpose_other`i'), "church") > 0
	replace s10_q12b_purpose_other`i' = "" if strpos(lower(s10_q12b_purpose_other`i'), "church") > 0

	replace othcontrib_purpose`i' = 9 if strpos(lower(s10_q12b_purpose_other`i'), "wedding") > 0
	replace s10_q12b_purpose_other`i' = "" if strpos(lower(s10_q12b_purpose_other`i'), "wedding") > 0

	replace othcontrib_purpose`i' = 4 if strpos(lower(s10_q12b_purpose_other`i'), "funeral") > 0
	replace s10_q12b_purpose_other`i' = "" if strpos(lower(s10_q12b_purpose_other`i'), "funeral") > 0
}

* Other purpose 1

replace othcontrib_purpose1 = 3 if s10_q12b_purpose_other1 == "Waterpoint"
replace s10_q12b_purpose_other1 = "" if s10_q12b_purpose_other1 == "Waterpoint"

replace othcontrib_purpose1 = 6 if inlist(s10_q12b_purpose_other1, "Accident", "To pay hospital bill", "Sick patient", "Medical Bill", "Health sponsor")
replace s10_q12b_purpose_other1 = "" if inlist(s10_q12b_purpose_other1, "Accident", "To pay hospital bill", "Sick patient", "Medical Bill", "Health sponsor")

replace othcontrib_purpose1 = 7 if inlist(s10_q12b_purpose_other1, "Building police post", "Construction ass chief office", "For chiefcamp development", "Construction of Assistant chief's office")
replace s10_q12b_purpose_other1 = "" if inlist(s10_q12b_purpose_other1, "Building police post", "Construction ass chief office", "For chiefcamp development", "Construction of Assistant chief's office")

replace othcontrib_purpose1 = 8 if inlist(s10_q12b_purpose_other1, "Sending priest for further studies", "Churh")
replace s10_q12b_purpose_other1 = "" if inlist(s10_q12b_purpose_other1, "Sending priest for further studies", "Churh")


replace othcontrib_purpose1 = 13 if strpos(lower(s10_q12b_purpose_other1), "public holiday") > 0 | inlist(s10_q12b_purpose_other1, "Village contribution for any emergencies", "For jahamuhuri day", "For building", "Visitors", "Tree planting")
replace s10_q12b_purpose_other1 = "" if strpos(lower(s10_q12b_purpose_other1), "public holiday") > 0 | inlist(s10_q12b_purpose_other1, "Village contribution for any emergencies", "For jahamuhuri day", "For building", "Visitors", "Tree planting", "Buying chairs for community")


* Other purpose 2

* Other purpose 3

*Fine --> move to later section - check for double counting

tab1 s10_q12b_purpose_other?



/* Updating harambee purpose codes */
label values othcontrib_purpose? s7_purp

tab s10_q12_othercontrib , m
tab s10_q12_othercontrib, nol
recode s10_q12_othercontrib (1 = 1) (2 = 0),gen(any_othcontrib)
la var any_othcontrib "Any other contribution (all purposes)"

egen othcontrib_amt_cond = rowtotal(s10_q12b_amount?), missing
la var othcontrib_amt_cond "Other contrib amount (cond on giving), all purposes"

gen othcontrib_amt_all = othcontrib_amt_cond
replace othcontrib_amt_all = 0 if any_othcontrib == 0
la var othcontrib_amt_all "Other contrib amount, all purposes, all hhs"

forval i=1/6 {
	di "Other contrib `i'"
	gen othcontrib_pg`i' = s10_q12b_amount`i' if inlist(othcontrib_purpose`i', 1, 2, 3, 7, 13)
	tab s10_q12b_purpose_other`i' if othcontrib_purpose`i' == 11 | othcontrib_purpose`i' == 12
	gen othcontrib_pg`i'_sch = othcontrib_pg`i'
	replace othcontrib_pg`i'_sch = s10_q12b_amount`i' if othcontrib_purpose`i' == 12
}

/* Main other contribution public good variables */
egen othcontrib_amt_pg_cond = rowtotal(othcontrib_pg?) if any_othcontrib == 1
la var othcontrib_amt_pg_cond "Other contrib amount for public goods, cond on giving"
gen othcontrib_amt_pg_all = othcontrib_amt_pg_cond
replace othcontrib_amt_pg_all = 0 if any_othcontrib == 0
la var othcontrib_amt_pg_all "Oth contrib amount for public goods (uncond)"

* including undefined school harambees
egen othcontrib_amt_pgsch_cond = rowtotal(othcontrib_pg*_sch ) if any_othcontrib == 1
la var othcontrib_amt_pgsch_cond "Oth contrib amount for public goods (incl more sch), cond"
gen othcontrib_amt_pgsch_all = 0 if any_othcontrib == 0
la var othcontrib_amt_pgsch_all "Other contrib amount for public goods (incl more sch), all hhs"

* winsorizing and trimming
wins_top1 othcontrib_amt_cond othcontrib_amt_all othcontrib_amt_pg_cond othcontrib_amt_pg_all othcontrib_amt_pgsch_cond othcontrib_amt_pgsch_all
trim_top1 othcontrib_amt_cond othcontrib_amt_all othcontrib_amt_pg_cond othcontrib_amt_pg_all othcontrib_amt_pgsch_cond othcontrib_amt_pgsch_all

* generating indicators for PG other contribs
gen any_othcontrib_pg 		= othcontrib_amt_pg_all > 0 if ~mi(othcontrib_amt_pg_all)
gen any_othcontrib_pgsch 	= othcontrib_amt_pgsch_all > 0 if ~mi(othcontrib_amt_pgsch_all)
la var any_othcontrib_pg "Any other PG contribution"
la var any_othcontrib_pgsch "Any other PG contribution (incl more sch)"

/** ve taxes/ fees ***/
tab s10_q13_veothertaxes
tab s10_q13a_veothertaxesamt
tab s10_q13b_vefinesamt

egen tmp_ve_taxes_fines = rowtotal(s10_q13a_veothertaxesamt s10_q13b_vefinesamt), m

tab tmp_ve_taxes_fines if s10_q13_veothertaxes == 1, m // so all report positive values for either taxes or fines

recode s10_q13_veothertaxes (2 = 0), gen(any_vetaxfines)
la var any_vetaxfines "Any VE/AC taxes or fines"

egen ve_amt_taxesfines_pos = rowtotal(s10_q13a_veothertaxesamt s10_q13b_vefinesamt), missing
label var ve_amt_taxesfines_pos "Amount of other taxes, fees and fines by local officials if $>0$"

ge ve_amt_taxesfines_all = ve_amt_taxesfines_pos
replace ve_amt_taxesfines_all = 0 if ~mi(s10_q13_veothertaxes)
la var ve_amt_taxesfines_all "Amount of other taxes, fees and fines, all"


** taxes **
gen ve_amt_taxes_pos = s10_q13a_veothertaxesamt
replace ve_amt_taxes_pos = . if ve_amt_taxes_pos == 0
la var ve_amt_taxes_pos "Amount paid to VE in other taxes (cond $>0$)"
gen ve_amt_taxes_all = s10_q13a_veothertaxesamt
replace ve_amt_taxes_all = 0 if ~mi(s10_q13_veothertaxes) & mi(ve_amt_taxes_all)
la var ve_amt_taxes_all "Amount paid to VE in other taxes, all"

* winsorizing and trimming
wins_top1 ve_amt_taxes_pos ve_amt_taxes_all
trim_top1 ve_amt_taxes_pos ve_amt_taxes_all

* generating indicator
gen any_ve_othtax = ve_amt_taxes_all > 0 if ~mi(s10_q13_veothertaxes)
la var any_ve_othtax "Indicator for paid any other taxes to VE"

** fines **
gen ve_amt_fines_pos = s10_q13b_vefinesamt
replace ve_amt_fines_pos = . if ve_amt_fines_pos == 0
la var ve_amt_fines_pos "Amount paid to VE in fines (cond $>0$)"
gen ve_amt_fines_all = s10_q13b_vefinesamt
replace ve_amt_fines_all = 0 if mi(s10_q13b_vefinesamt) & ~mi(s10_q13_veothertaxes)
la var ve_amt_fines_all "Amount paid to VE in fines, all"

* winsorizing and trimming
wins_top1 ve_amt_fines_pos ve_amt_fines_all
trim_top1 ve_amt_fines_pos ve_amt_fines_all

* generating indicator
gen any_ve_fines = ve_amt_fines_all > 0 if ~mi(s10_q13_veothertaxes)
la var any_ve_fines "Indicator for paying any VE fines"

/* Totalling Village contributions */
* Totaling village contribs, other contributions & VE taxes

egen vill_contrib_cond = rowtotal(villservice_contrib_amt othcontrib_amt_pg_cond ve_amt_taxes_pos), missing
tab vill_contrib_cond // confirm all values > 0
la var vill_contrib_cond "Total village contributions, cond $>0$"

egen vill_contrib_all = rowtotal(villservice_contrib_amt_all othcontrib_amt_pg_all ve_amt_taxes_all), m
count if vill_contrib_all == . // should not be many (if any)
la var vill_contrib_all "Total village contributions, all"

egen vill_contrib_sch_cond = rowtotal(villservice_contrib_amt othcontrib_amt_pgsch_cond ve_amt_taxes_pos), missing
tab vill_contrib_sch_cond // confirm all > 0
la var vill_contrib_sch_cond "Total village contributions, including all sch contribs, cond $>0$"

egen vill_contrib_sch_all = rowtotal(villservice_contrib_amt othcontrib_amt_pgsch_all ve_amt_taxes_all)
la var vill_contrib_sch_all "Total village contributions, including all sch contribs, all"

egen vill_contrib_sch_fines_cond = rowtotal(villservice_contrib_amt othcontrib_amt_pgsch_cond ve_amt_taxesfines_pos), missing
tab vill_contrib_sch_fines_cond // confirm all > 0
la var vill_contrib_sch_fines_cond "Total village contribs, incl all sch \& fines, cond $>0$"

egen vill_contrib_sch_fines_all = rowtotal(villservice_contrib_amt_all othcontrib_amt_pgsch_all ve_amt_taxesfines_all)
la var vill_contrib_sch_fines_all "Total village contribs, incl all sch \& fines, all"

* winsorizing and trimming
wins_top1 vill_contrib_sch_fines_cond vill_contrib_sch_fines_all
trim_top1 vill_contrib_sch_fines_cond vill_contrib_sch_fines_all

* generating indicators
gen any_villtax_contrib = vill_contrib_all > 0 if ~mi(vill_contrib_all)
la var any_villtax_contrib "Indicator for any village contribution"

gen any_villtax_sch_contrib = vill_contrib_sch_all > 0 if ~mi(vill_contrib_sch_all)
la var any_villtax_sch_contrib "Indicator for any village contrib, incl all sch"

gen any_villtax_sch_fines_contrib = vill_contrib_sch_fines_all > 0 if ~mi(vill_contrib_sch_fines_all)
la var any_villtax_sch_fines_contrib "Indicator for any village contrib, incl all sch \& fines"

/* Labor as informal taxation - I think I measure this better at endline, so will want to update then */
tab s10_q14_commlabor, m
recode s10_q14_commlabor (1 = 1) (2 = 0), gen(any_labor_tax)
la var any_labor_tax "Indicator for any informal labor tax, s10q14"

tab s10_q14a_commlaborhrs // what to make of the very high numbers?
gen labor_tax_hrs = s10_q14a_commlaborhrs
la var labor_tax_hrs "Number of informal labor tax hours, cond $>0$"

gen labor_tax_hrs_all = labor_tax_hrs
replace labor_tax_hrs_all = 0 if any_labor_tax == 0
la var labor_tax_hrs_all "Number of informal labor tax hours, all hhs"

replace labor_tax_hrs = . if labor_tax_hrs == 6000 // this seems way too high - some other outliers as well

summ any_labor_tax labor_tax_hrs*

gen labor_tax_ksh_cond = labor_tax_hrs * $hour_labor_rate
la var labor_tax_ksh_cond "Value of labor hours (constant ag wage rate), cond $>0$"

gen labor_tax_ksh_all = labor_tax_hrs_all * $hour_labor_rate
la var labor_tax_ksh_all "Value of labor hours (constant ag wage rate), all hhs"

wins_top1 labor_tax_ksh_cond labor_tax_ksh_all
trim_top1 labor_tax_ksh_cond labor_tax_ksh_all

* 5% report community labor, 40 hrs over last 12 months (excluding a few large outliers)


/*** TOTAL INFORMAL TAXES ***/

* bring in labor amounts here? but wage rate estimated from endline, which is less than ideal. Use for now, add to to-do list to get baseline measure of labor (I should be able to develop a household-specific measure following Olken-Singhal)
project, uses("$da/intermediate/GE_HH-BL_hhroster.dta") preserve
merge 1:1 hhid_key using "$da/intermediate/GE_HH-BL_hhroster.dta", keepusing(schcontrib*) gen(_mhh)
drop _mhh

egen total_informal_taxes_cash = rowtotal(selfemp_inftax_ann_all haram_amt_pg_all vill_contrib_all schcontrib_all)
la var total_informal_taxes_cash "Total informal monetary taxes, all"

egen total_inftax_schfines_cash = rowtotal(selfemp_inftax_ann_all haram_amt_pgsch_all vill_contrib_sch_fines_all schcontrib_all) // this should be largest - focus on getting bound for now, then see how different. If very different can narrow.
la var total_inftax_schfines_cash "Total informal monetary taxes, including fines \& all sch haram"

egen total_informal_taxes = rowtotal(selfemp_inftax_ann_all haram_amt_pg_all vill_contrib_all labor_tax_ksh_all schcontrib_all), m
la var total_informal_taxes "Total informal taxes (incl labor), all hhs"

gen total_informal_taxes_pos = total_informal_taxes if total_informal_taxes > 0 & ~mi(total_informal_taxes)
la var total_informal_taxes_pos "Total informal taxes (incl labor), cond $>0$"

egen total_informal_taxes_sch_fines = rowtotal(selfemp_inftax_ann_all haram_amt_pgsch_all vill_contrib_sch_fines_all labor_tax_ksh_all), m
la var total_informal_taxes_sch_fines "Total informal taxes (incl labor, fines \& all sch haram)"

gen total_informal_taxes_cond = total_informal_taxes if total_informal_taxes > 0
la var total_informal_taxes_cond "Total informal taxes paid, cond $>0$"

gen any_informal_monetary = total_informal_taxes_cash > 0 if ~mi(total_informal_taxes_cash)
la var any_informal_monetary "Indicator for paid informal tax in cash" // check if this also included in=kind
gen any_informal_tax = any_informal_monetary == 1 | any_labor_tax == 1
la var any_informal_tax "Indicator for paid any informal tax (incl labor)"



egen tottaxpaid_all = rowtotal(total_formal_taxes total_informal_taxes), m

wins_top1 tottaxpaid_all
gen tottaxpaid_all_wins_PPP = tottaxpaid_all_wins * $ppprate

/*** BRIBES - DON'T REALLY FIT INTO ANY OF THE ABOVE, BUT MAY BE INTERESTING AS A COMPARISON
     POINT AND FOR SCALE. Note that this is only for enterprises, doesn't capture other bribes
	 that households may have paid ***/

/* Bribes by enterprise */
tab1 s8_q17g_bribes?

* monthly

* annual
forval i=1/3 {
	gen selfemp_bribes_`i'_ann = s8_q17g_bribes`i' * 12
	la var selfemp_bribes_`i'_ann "Selfemp bribes for enterprise `i' (ann)"
}


/** TOTAL BRIBES **/
egen selfemp_bribes_ann_emp = rowtotal(selfemp_bribes_1_ann selfemp_bribes_2_ann selfemp_bribes_3_ann), missing
la var selfemp_bribes_ann_emp "Total bribes paid, for those in self emp"
tab selfemp_bribes_ann_emp if selfemp == 1, m


gen selfemp_bribes_ann_all = selfemp_bribes_ann_emp
replace selfemp_bribes_ann_all = 0 if selfemp == 0
label var selfemp_bribes_ann_all "Total selfemp bribes, all"



gen any_bribes_selfemp = selfemp_bribes_ann_all > 0 if selfemp == 1
la var any_bribes_selfemp "Indicator for paid any bribes with selfemp"



/************************************/
/* SECTION 11: ATTITUDES            */
/************************************/
/*
 * I don't think we use any of this, commenting and can then cut from replication materials
rename s11_11_taxes40000 s11_q11_taxes40000

foreach var of varlist s11* {
	di "`var'"
	tab `var', m
}



* correcting based on comments
foreach var of varlist s11_q8_taxes5000 s11_q9_taxes10000 s11_q10_taxes20000 s11_q11_taxes40000 {
	replace `var' = 0 if s11_focomments == "Once you buy a product you are already taxed so you should not pay tax again" // this was set as DK --> seems FO mistake
}

egen s11_miss = rowmiss(s11*)
tab s1_q1b_ipaid s11_miss
gen s11_miss_over1 = (s11_miss>1)
tab s1_q1b_ipaid s11_miss_over1, row


** generating variables **
tab s11_q1_govtreducediff
tab s11_q1_govtreducediff, nol
recode s11_q1_govtreducediff (1 2 = 1) (3 4 5 = 0) (-99 -88 99 = .), gen(agree_govtreducediff)
tab agree_govtreducediff, m

tab s11_q2_localreducediff
tab s11_q2_localreducediff, nol
recode s11_q2_localreducediff (1 2 = 1) (3 4 5 = 0) (-99 -88 99 = .), gen(agree_llreducediff)
tab agree_llreducediff, m

tab s11_q3_commamounts
tab s11_q3_commamounts, nol
recode s11_q3_commamounts (3 4 = 1) (1 2 5 = 0) (-99 -88 99 = .), gen(agree_payability)

tab s11_q4_equality
tab s11_q4_equality, nol
recode s11_q4_equality (1/4 = 1) (5/10 = 0) (-99 -88 99 = .), gen(agree_incomeequal)

tab s11_q5_govtresponsibility
tab s11_q5_govtresponsibility, nol
recode s11_q5_govtresponsibility (1/4 = 1) (5/10 = 0) (-99 -88 99 = .), gen(agree_govtresponsible)

tab s11_q6_commresponsibility
tab s11_q6_commresponsibility, nol
recode s11_q6_commresponsibility (1/4 = 1) (5/10 = 0) (-99 -88 99 = .), gen(agree_commresponsible)


*** Tax Plan Progressivity ***
tab1 s11_q8_taxes5000 s11_q9_taxes10000 s11_q10_taxes20000 s11_q11_taxes40000

recode s11_q8_taxes5000 s11_q9_taxes10000 s11_q10_taxes20000 s11_q11_taxes40000 (-99 -88 99 = .)

summ s11_q8_taxes5000 s11_q9_taxes10000 s11_q10_taxes20000 s11_q11_taxes40000

gen taxrate5000     = s11_q8_taxes5000/ 5000
gen taxrate10000    = s11_q9_taxes10000 / 10000
gen taxrate20000    = s11_q10_taxes20000 / 20000
gen taxrate40000    = s11_q11_taxes40000 / 40000

* replacing tax rates over 1 with missing values
foreach var of varlist taxrate* {
    replace `var' = . if `var' > 1
}

egen tmp_taxrate_nonmiss = rownonmiss(taxrate5000 taxrate10000 taxrate20000 taxrate40000)
tab tmp_taxrate_nonmiss
gen taxrate_nonmiss = (tmp_taxrate_nonmiss != 0) if ~mi(tmp_taxrate_nonmiss)


summ taxrate*
gen zerotaxrate = taxrate5000 ==0 & taxrate10000 == 0 & taxrate20000 == 0 & taxrate40000 == 0
tab zerotaxrate

gen taxrate1_prog = taxrate10000 > taxrate5000 if ~mi(taxrate10000) & ~mi(taxrate5000)
gen taxrate2_prog = taxrate20000 > taxrate10000 if ~mi(taxrate10000) & ~mi(taxrate20000)
gen taxrate3_prog = taxrate40000 > taxrate20000 if ~mi(taxrate20000) & ~mi(taxrate40000)

tab1 taxrate?_prog

gen taxrate1_prop = taxrate10000 == taxrate5000 if ~mi(taxrate10000) & ~mi(taxrate5000)
gen taxrate2_prop = taxrate20000 == taxrate10000 if ~mi(taxrate10000) & ~mi(taxrate20000)
gen taxrate3_prop = taxrate40000 == taxrate20000 if ~mi(taxrate20000) & ~mi(taxrate40000)

tab1 taxrate?_prop

gen taxrate1_reg = taxrate10000 < taxrate5000 if ~mi(taxrate5000) & ~mi(taxrate10000)
gen taxrate2_reg = taxrate20000 < taxrate10000 if ~mi(taxrate10000) & ~mi(taxrate20000)
gen taxrate3_reg = taxrate40000 < taxrate20000 if ~mi(taxrate20000) & ~mi(taxrate40000)

tab1 taxrate?_reg

gen taxrate_strictprog = taxrate1_prog == 1 & taxrate2_prog ==1 & taxrate3_prog == 1 if ~mi(taxrate1_prog) & ~mi(taxrate2_prog) & ~mi(taxrate3_prog)

gen taxrate_weakprog = (taxrate1_prog == 1 | taxrate1_prop ==1) & (taxrate2_prog == 1 | taxrate2_prop == 1) & (taxrate3_prog == 1 | taxrate3_prop==1) & (taxrate1_prog==1 | taxrate2_prog==1 | taxrate3_prog==1)

gen taxrate_prop = taxrate1_prop == 1 & taxrate2_prop == 1 & taxrate3_prop == 1 if ~mi(taxrate1_prog) & ~mi(taxrate2_prog) & ~mi(taxrate3_prog) & ~mi(taxrate1_prop) & ~mi(taxrate2_prop) & ~mi(taxrate3_prop)

gen taxrate_weakreg = (taxrate1_reg == 1 | taxrate1_prop==1) & (taxrate2_reg == 1 | taxrate2_prop==1) & (taxrate3_reg == 1 | taxrate3_prop == 1) & (taxrate1_reg == 1 | taxrate2_reg == 1 | taxrate3_reg ==1) if ~mi(taxrate1_reg) & ~mi(taxrate2_reg) & ~mi(taxrate3_reg) & ~mi(taxrate1_prop) & ~mi(taxrate2_prop) & ~mi(taxrate3_prop)

gen taxrate_strictreg = taxrate1_reg == 1 & taxrate2_reg == 1 & taxrate3_reg == 1 if ~mi(taxrate1_reg) & ~mi(taxrate2_reg) & ~mi(taxrate3_reg)

tab1 zerotaxrate taxrate_strictprog taxrate_weakprog taxrate_prop taxrate_weakreg taxrate_strictreg

** 8.1 Mean Effects Index
* creating z-scores for variables that will be included in mean effects index
me_prep  agree_govtreducediff agree_llreducediff agree_payability agree_incomeequal agree_govtresponsible agree_commresponsible taxrate_weakprog taxrate_strictprog

egen h81_supportredist = rowmean(agree_govtreducediff_z agree_llreducediff_z agree_payability_z agree_incomeequal_z agree_govtresponsible_z agree_commresponsible_z taxrate_weakprog_z)
la var h81_supportredist "H8.1 Support for Redistribution"

summ h81_supportredist
summ h81_supportredist if treat == 0 & hi_sat == 0
*/

** saving **
drop s8_* s9_* s10_* s11_*
save "$da/intermediate/GE_HH-BL_localpf.dta", replace
project, creates("$da/intermediate/GE_HH-BL_localpf.dta")
