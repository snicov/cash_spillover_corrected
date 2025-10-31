/* do file header */
return clear
capture project, doinfo
if (_rc==0 & !mi(r(pname))) global dir `r(pdir)'  // using -project-
else {  // running directly
    if ("${ge_dir}"=="") do `"`c(sysdir_personal)'profile.do"'
    do "${ge_dir}/do/set_environment.do"
}

* Import config - running globals
project, original("$dir/do/GE_global_setup.do")
include "$dir/do/GE_global_setup.do"

// end preliminaries


/****** LOADING DATASET *******/
project, uses("$da/GE_HH-Survey-BL_Analysis_AllHHs.dta")
use "$da/GE_HH-Survey-BL_Analysis_AllHHs.dta", clear
cap drop _merge _m?

*** SECTION 7 CONTAINS THE INFORMATION ON AGRICULTURAL ENTERPRISES **
keep if agriculture_any == 1

************************
** OPERATIONAL CHECKS **
************************

** Clean location identifiers **
********************************
** TK come back to change these
** for the remainder, we know where they are located **
ren s1_q2a_location location_name
ren s1_q2b_sublocation sublocation_name
ren s1_q2c_village village_name


** Generate survey date **
**************************
ren svydate_BL HH_AGENT_SUR_BL_date

**************************
** Section 1 - Cleaning **
**************************

** Check consent **
rename s1_consent consent

** Physical Business Characteristics **
***************************************

** we don't use those here, since farms are somewhat different **

** Business Categories **
*************************

** For now, classify each farm as a unified enterprise, same category **
gen bizcat = "own_farm"
replace bizcat = "61" if bizcat == "own_farm"

destring bizcat, replace

label def bizcat 1 "Tea buying centre" 2 "Small retail" 3 "M-Pesa" 4 "Mobile charging" 5 "Bank agent" 6 "Large retail" 7 "Restaurant" 8 "Bar" 9 "Hardware store" 10 "Barber shop" 11 "Beauty shop / Salon" 12 "Butcher" 13 "Video Room/Football hall" 14 "Cyber café" 15 "Tailor" 16 "Bookshop" 17 "Posho mill" 18 "Welding / metalwork" 19 "Carpenter" 20 "Guesthouse/ Hotel" ///
21 "Food stand / Prepared food vendor" 22 "Food stall / Raw food and fruits vendor" 23 "Chemist" 24 "Motor Vehicles Mechanic" 25 "Motorcycle Repair / Shop" 26 "Bicycle repair / mechanic shop" 27 "Petrol station" 28 "Piki driver" 29 "Boda driver" 30 "Sale or brewing of homemade alcohol / liquor" 31 "Livestock / Animal (Products) / Poultry Sale" 32 "Oxen / donkey / tractor plouging" 33 "Fishing" 34 "Fish Sale / Mongering" 35 "Cereals" 36 "Agrovet" 37 "Photo studio" 38 "Jaggery" 39 "Non-Food Vendor" 40 "Non-Food Producer" ///
41 "Other (specify)" 42 "None" 51 "Nonfood vendor or producer" 61 "Own farm enterprise", replace

label val bizcat bizcat
tab bizcat

** generate aggregated business categories **
*********************************************
gen bizcat_cons = 9

order location_name sublocation_name village_code village_name hhid_key HH_AGENT_SUR_BL_date consent bizcat bizcat_cons

***********************************************
** Clean up enterprise variables - section 2 **
***********************************************

** Ownership information **
***************************
gen owner_f = female_BL

gen owner_age = age_BL

** owner education **
gen owner_education = yearsedu2_BL
gen owner_primary = stdschool_BL
gen owner_secondary = formschool_BL
gen owner_degree = (yearsedu_BL==15) if ~mi(yearsedu_BL)

** Owner residence information **
*********************************
gen owner_resident = 1 // we are only looking at enterprises within the village here

*******************************************************
** Clean up agricultural enterprise data - section 7 **
*******************************************************
project, uses("$da/intermediate/GE_HH-BL_setup.dta") preserve
merge 1:1 hhid_key using "$da/intermediate/GE_HH-BL_setup.dta", keepusing(s7_*)

* this should be moved into cleaning for raw data
cap rename s7_q12d_irrigrationspend? s7_q12d_irrigationspend?

** operational hours per week/day **
egen op_hoursperweek = rowtotal(s7_q6_selfhoursworked?) if !inlist(s7_q6_selfhoursworked1,-9999,99,-88,88) & !inlist(s7_q6_selfhoursworked2,-9999,99,-88,88) & !inlist(s7_q6_selfhoursworked3,-9999,99,-88,88) & !(mi(s7_q6_selfhoursworked1) & mi(s7_q6_selfhoursworked2) & s7_q6_selfhoursworked3)
// assume FR hours correspond to business hours
tab op_hoursperweek

** Employee information **
**************************
egen emp_n_tot = rowtotal(s7_q7_peopleworked?), m
egen emp_n_outhh = rowtotal(s7_q9_outsidepeopleworked?), m
gen emp_n_family = emp_n_tot - emp_n_outhh


** Clean Enterprise Financial Information **
********************************************

** Costs **
gen wage_total = ag_wage_bill / 12
count if wage_total != . & emp_n_outhh == 0
replace wage_total = 0 if emp_n_outhh == 0


egen c_tools = rowtotal(s7_q12a_toolsspend?) if !inlist(s7_q12a_toolsspend1,-9999,99,-88,88) & !inlist(s7_q12a_toolsspend2,-9999,99,-88,88) & !inlist(s7_q12a_toolsspend3,-9999,99,-88,88) & !(mi(s7_q12a_toolsspend1) & mi(s7_q12a_toolsspend2) & mi(s7_q12a_toolsspend3))
egen c_animalmed = rowtotal(s7_q12b_animalmedspend?) if !inlist(s7_q12b_animalmedspend1,-9999,99,-88,88) & !inlist(s7_q12b_animalmedspend2,-9999,99,-88,88) & !inlist(s7_q12b_animalmedspend3,-9999,99,-88,88) & !(mi(s7_q12b_animalmedspend1) & mi(s7_q12b_animalmedspend2) & mi(s7_q12b_animalmedspend3))
egen c_fertilizer = rowtotal(s7_q12c_fertilizerspend?) if !inlist(s7_q12c_fertilizerspend1,-9999,99,-88,88) & !inlist(s7_q12c_fertilizerspend2,-9999,99,-88,88) & !inlist(s7_q12c_fertilizerspend3,-9999,99,-88,88) & !(mi(s7_q12c_fertilizerspend1) & mi(s7_q12c_fertilizerspend2) & mi(s7_q12c_fertilizerspend3))
egen c_irrigation = rowtotal(s7_q12d_irrigationspend?) if !inlist(s7_q12d_irrigationspend1,-9999,99,-88,88) & !inlist(s7_q12d_irrigationspend2,-9999,99,-88,88) & !inlist(s7_q12d_irrigationspend3,-9999,99,-88,88) & !(mi(s7_q12d_irrigationspend1) & mi(s7_q12d_irrigationspend2) & mi(s7_q12d_irrigationspend3))
egen c_seeds = rowtotal(s7_q12e_improvedseedspend?) if !inlist(s7_q12e_improvedseedspend1,-9999,99,-88,88) & !inlist(s7_q12e_improvedseedspend2,-9999,99,-88,88) & !inlist(s7_q12e_improvedseedspend3,-9999,99,-88,88) & !(mi(s7_q12e_improvedseedspend1) & mi(s7_q12e_improvedseedspend2) & mi(s7_q12e_improvedseedspend3))
egen c_insurance = rowtotal(s7_q12f_aginsurancespend?) if !inlist(s7_q12f_aginsurancespend1,-9999,99,-88,88) & !inlist(s7_q12f_aginsurancespend2,-9999,99,-88,88) & !inlist(s7_q12f_aginsurancespend3,-9999,99,-88,88) & !(mi(s7_q12f_aginsurancespend1) & mi(s7_q12f_aginsurancespend2) & mi(s7_q12f_aginsurancespend3))

** Total costs **
ren p4_5_agcosts_BL c_total

foreach v of var c_tools c_animalmed c_fertilizer c_irrigation c_seeds c_insurance c_total {
	replace `v' = `v'/12
}

** Investment **
** We don't have a direct investment measure here, so use only components we definitely classify as investment **

** Revenues and profits **
gen rev_year = .
gen prof_year = .
// not using these, but keeping in in case needed for code not to break

** Deal with inconsistencies **
gen revprof_incons = 0
replace revprof_incons = 1 if prof_year > rev_year & prof_year != .


************************
/*** SAVING DATASET ***/
************************
keep location_name sublocation_name village_code village_name hhid_key HH_AGENT_SUR_BL_date consent bizcat bizcat_cons owner_f owner_age owner_education owner_primary owner_secondary owner_degree owner_resident op_hoursperweek emp_n_tot emp_n_family wage_total c_tools c_animalmed c_fertilizer c_irrigation c_seeds c_insurance c_total rev_year prof_year revprof_incons

** Label variables **
label var hhid_key "Baseline household ID (unique with village_code)"
label var bizcat "Business category"
label var bizcat_cons "Business category (consolidated)"

label var op_hoursperweek "Number of hours open per day"

label var owner_f "Owner is female"
label var owner_education "Owner - years of education"
label var owner_primary "Owner - completed primary school"
label var owner_secondary "Owner - completed secondary school"
label var owner_degree  "Owner - has a degree"
label var owner_resident "Owner - resident in the same village"
*label var owner_location_code "Owner - location code of residence"
*label var owner_sublocation_code "Owner - sublocation code of residence"
*label var owner_village_code "Owner - village code of residence"

label var emp_n_tot "Total number of employees"
label var emp_n_family "Number of family employees"
label var wage_total "Total wage bill last month"

*label var rev_mon "Revenues last month (in KES)"
label var rev_year "Revenues last year (in KES)"
*label var prof_mon "Profits last month (in KES)"
label var prof_year "Profits last year (in KES)"
label var revprof_incons "Profits/Revenues flagged inconsistent"
label var c_tools "KES spent on tools"
label var c_animalmed "KES spent on animal medicine"
label var c_fertilizer "KES spent on fertilizer"
label var c_irrigation "KES spent on irrigation"
label var c_seeds "KES spent on seeds"
label var c_insurance "KES spent on insurance"
label var c_total "Total costs (in KES)"
*label var c_utilities "KES spent on utilities"
*label var c_repairs "KES spent on repairs"
*label var c_healthinsurance "KES spent on health insurance"
*label var c_vandalism "KES spent on vandalism"


order location_name sublocation_name village_code village_name hhid_key HH_AGENT_SUR_BL_date consent ///
bizcat* /* op_* */ owner_* /* emp_* */ wage_* rev_* prof_* revprof_incons c_* ///

save "$da/GE_HH-Survey-BL_AgEnterprises_Analysis_ECMA.dta", replace
project, creates("$da/GE_HH-Survey-BL_AgEnterprises_Analysis_ECMA.dta")
