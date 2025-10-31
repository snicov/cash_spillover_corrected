
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

/****** LOADING DATASET *******/
project, uses("$da/GE_HH-Analysis_AllHHs.dta")
use "$da/GE_HH-Analysis_AllHHs", clear

*** SECTION 7 CONTAINS THE INFORMATION ON AGRICULTURAL ENTERPRISES **
tab s7_q1_selfag
keep if s7_q1_selfag == 1

************************
** OPERATIONAL CHECKS **
************************
gen HH_AGENT_SUR_EL = 1

** Clean location identifiers **
********************************

** for the remainder, we know where they are located **
ren s1_q2a_location location_name
ren s1_q2b_sublocation sublocation_name
ren s1_q2c_village village_name


** Generate survey date **
**************************
ren today HH_AGENT_SUR_EL_date

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

order location_name sublocation_name village_code village_name hhid_key HH_AGENT_SUR_EL_date consent bizcat bizcat_cons


***********************************************
** Clean up enterprise variables - section 2 **
***********************************************

** Ownership information **
***************************
gen owner_f = female

gen owner_age = age

** owner education **
gen owner_education = yearsedu

gen owner_primary = .
gen owner_secondary = .
gen owner_degree = .

** Owner residence information **
*********************************
gen owner_resident = 1 // we are only looking at enterprises within the village here


*******************************************************
** Clean up agricultural enterprise data - section 7 **
*******************************************************

** operational hours per week/day **
gen op_hoursperweek = hrsworked_ag_tot // assume FR hours correspond to business hours
tab op_hoursperweek

** Employee information **
**************************
egen emp_n_tot = rowtotal(s7_q8_numworkers_?), m
egen emp_n_outhh = rowtotal(s7_q10_outsideworkers_?), m
gen emp_n_family = emp_n_tot - emp_n_outhh


** Clean Enterprise Financial Information **
********************************************

** Costs **
ren s7_q12_outsalpaid_1_ksh cropsalarycost
ren s7_q12_outsalpaid_2_ksh livestocksalarycost
ren s7_q12_outsalpaid_3_ksh poultrysalarycost
ren s7_q12_outsalpaid_4_ksh fishpondsalarycost
ren s7_q12_outsalpaid_5_ksh othsalarycost
egen wage_total = rowtotal(cropsalarycost livestocksalarycost fishpondsalarycost poultrysalarycost othsalarycost)
replace wage_total = wage_total / 12

egen c_tools = rowtotal(s7_q13a_toolsspend_?) if !inlist(s7_q13a_toolsspend_1,-9999,99,-88,88) & !inlist(s7_q13a_toolsspend_5,-9999,99,-88,88) & !(mi(s7_q13a_toolsspend_1) & mi(s7_q13a_toolsspend_5))
egen c_animalmed = rowtotal(s7_q13b_animalmedspend_?) if !inlist(s7_q13b_animalmedspend_2,-9999,99,-88,88) & !inlist(s7_q13b_animalmedspend_3,-9999,99,-88,88) & !inlist(s7_q13b_animalmedspend_4,-9999,99,-88,88) & !inlist(s7_q13b_animalmedspend_5,-9999,99,-88,88) & !(mi(s7_q13b_animalmedspend_2) & mi(s7_q13b_animalmedspend_3) & mi(s7_q13b_animalmedspend_4) & mi(s7_q13b_animalmedspend_5))
egen c_fertilizer = rowtotal(s7_q13c_fertilizerspend_?) if !inlist(s7_q13c_fertilizerspend_1,-9999,99,-88,88) & !inlist(s7_q13c_fertilizerspend_5,-9999,99,-88,88) & !(mi(s7_q13c_fertilizerspend_1) & mi(s7_q13c_fertilizerspend_5))
egen c_irrigation = rowtotal(s7_q13d_irrigationspend_?) if !inlist(s7_q13d_irrigationspend_1,-9999,99,-88,88) & !inlist(s7_q13d_irrigationspend_2,-9999,99,-88,88) & !inlist(s7_q13d_irrigationspend_5,-9999,99,-88,88) & !(mi(s7_q13d_irrigationspend_1) & mi(s7_q13d_irrigationspend_2) & mi(s7_q13d_irrigationspend_5))
egen c_seeds = rowtotal(s7_q13e_improvedseedspend_?) if !inlist(s7_q13e_improvedseedspend_1,-9999,99,-88,88) & !inlist(s7_q13e_improvedseedspend_5,-9999,99,-88,88) & !(mi(s7_q13e_improvedseedspend_1) & mi(s7_q13e_improvedseedspend_5))
egen c_insurance = rowtotal(s7_q13f_aginsurancespend_?) if !inlist(s7_q13f_aginsurancespend_1,-9999,99,-88,88) & !inlist(s7_q13f_aginsurancespend_4,-9999,99,-88,88) & !inlist(s7_q13f_aginsurancespend_5,-9999,99,-88,88) & !(mi(s7_q13f_aginsurancespend_1) & mi(s7_q13f_aginsurancespend_4) & mi(s7_q13f_aginsurancespend_5))

** Total costs **
ren p4_5_agcosts c_total

foreach v of var c_tools c_animalmed c_fertilizer c_irrigation c_seeds c_insurance c_total {
	replace `v' = `v'/12
}

** Revenues and profits **
gen rev_year = p4_1_agrevenue
gen rev_mon = p4_1_agrevenue/12
gen prof_year = p3_1_agprofit
gen prof_mon = p3_1_agprofit/12

** Flag inconsistencies **

gen revprof_incons = 0
replace revprof_incons = 1 if prof_year > rev_year & prof_year != .


************************
/*** SAVING DATASET ***/
************************
keep HH_AGENT_SUR_EL location_name sublocation_name village_code village_name hhid_key HH_AGENT_SUR_EL_date consent bizcat bizcat_cons owner_f owner_age owner_education owner_primary owner_secondary owner_degree owner_resident op_hoursperweek emp_n_tot emp_n_family wage_total c_total  c_tools c_animalmed c_fertilizer c_irrigation c_seeds c_insurance rev_year rev_mon prof_year prof_mon revprof_incons

** Label variables **
label var hhid_key "Baseline household ID (unique with village_code)"
label var bizcat "Business category"
label var bizcat_cons "Business category (consolidated)"

label var op_hoursperweek "Number of hours open per day"

label var owner_f "Owner is female"

label var emp_n_tot "Total number of employees"
label var emp_n_family "Number of family employees"
label var wage_total "Total wage bill last month"

label var rev_mon "Revenues last month (in KES)"
label var rev_year "Revenues last year (in KES)"
label var prof_mon "Profits last month (in KES)"
label var prof_year "Profits last year (in KES)"
label var revprof_incons "Profits/Revenues flagged inconsistent"
label var c_tools "KES spent on tools"
label var c_animalmed "KES spent on animal medicine"
label var c_fertilizer "KES spent on fertilizer"
label var c_irrigation "KES spent on irrigation"
label var c_seeds "KES spent on seeds"
label var c_insurance "KES spent on insurance"
label var c_total "Total costs (in KES)"

order HH_AGENT_SUR_EL location_name sublocation_name village_code village_name hhid_key HH_AGENT_SUR_EL_date consent ///
bizcat* op_* owner_* emp_* wage_* rev_* prof_* revprof_incons c_* ///

save "$da/GE_HH-Survey-EL_AgEnterprises_Analysis_ECMA.dta", replace
project, creates("$da/GE_HH-Survey-EL_AgEnterprises_Analysis_ECMA.dta")
