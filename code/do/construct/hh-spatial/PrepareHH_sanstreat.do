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

project, uses("$da/pp_GDP_calculated.dta")
use "$da/pp_GDP_calculated.dta", clear
global pp_GDP = pp_GDP[1]
global pp_GDP_r = pp_GDP_r[1]
clear

// end preliminaries

project, original("$do/programs/run_ge_build_programs.do")
include "$do/programs/run_ge_build_programs.do"


************************
** 0. Data Preparation **
*************************
project, uses("$da/GE_HH-Analysis_AllHHs.dta")
use "$da/GE_HH-Analysis_AllHHs.dta", clear
ren s1_q2b_sublocation sublocation_code
destring sublocation_code, replace

** LOOK AT REVENUE / PROFITS / WAGE INCOME OF HOUSEHOLDS **
***********************************************************
gen selfag = 2 - s7_q1_selfag

** agricultural revenue / costs / profits **
ren totcropproduction_ksh cropproduction
replace cropproduction = 0 if cropproduction == . & !missing(selfag)

gen cropsales_v1 = totcropsales_bycrop if !missing(selfag)
replace cropsales_v1 = 0 if cropsales_v1 == . & !missing(selfag)

gen cropsales_v2 = cropsales_q6 if !missing(selfag)
replace cropsales_v2 = 0 if cropsales_v2 == . & !missing(selfag)

gen cropowncons_v1 = cropproduction - cropsales_v1 if !missing(selfag)
replace cropowncons_v1 = 0 if cropowncons_v1 == . & !missing(selfag)

gen cropowncons_v2 = cropproduction - cropsales_v2 if !missing(selfag)
replace cropowncons_v2 = 0 if cropowncons_v2 == . & !missing(selfag)

egen animalproduction = rowtotal(s7_q6aa_outputsales_2 s7_q6aa_outputsales_3 s7_q6aa_outputsales_4 s7_q6aa_cropsales_5 beef_owncons poultry_owncons egg_owncons) if !missing(selfag)
egen animalowncons = rowtotal(beef_owncons poultry_owncons egg_owncons) if !missing(selfag)
egen animalsales = rowtotal(s7_q6aa_outputsales_2 s7_q6aa_outputsales_3 s7_q6aa_outputsales_4 s7_q6aa_cropsales_5) if !missing(selfag)

ren s7_q12_outsalpaid_1_ksh cropsalarycost
ren s7_q12_outsalpaid_2_ksh livestocksalarycost
ren s7_q12_outsalpaid_3_ksh poultrysalarycost
ren s7_q12_outsalpaid_4_ksh fishpondsalarycost
ren s7_q12_outsalpaid_5_ksh othsalarycost
egen totagsalarycost = rowtotal(cropsalarycost livestocksalarycost fishpondsalarycost poultrysalarycost othsalarycost) if !missing(selfag)


** employment on own farm - labor demand **
** sum acros _1-_4: own, household, outside work
recode s7_q7_hoursworked_* (-99 = .)
tab1 s7_q7_hoursworked_*
egen fr_hrs_ag = rowtotal(s7_q7_hoursworked_*) if !missing(selfag)

recode s7_q9_hhhoursworked_* (-99 = .)
tab1 s7_q9_hhhoursworked_* // a few outlier values - what's going on with these?

** total number of workers
recode s7_q8_numworkers_? s7_q10_outsideworkers_? (-99 = .)

egen num_tot_agworkers = rowtotal(s7_q8_numworkers_?), m
egen num_outhh_agworkers = rowtotal(s7_q10_outsideworkers_?), m

gen num_hh_agworkers = 	num_tot_agworkers - num_outhh_agworkers
tab num_hh_agworkers if s7_q1_selfag == 1, m

gen problem_hhagworkers = num_hh_agworkers < 0 | (num_hh_agworkers > 15 & ~mi(num_hh_agworkers ))

egen othhh_hrs_ag = rowtotal(s7_q9_hhhoursworked_*), m

gen aghrs_per_worker = othhh_hrs_ag / num_hh_agworkers

summ aghrs_per_worker if problem_hhagworkers == 0

list aghrs_per_worker othhh_hrs_ag num_hh_agworkers if aghrs_per_worker > 60 & ~mi(aghrs_per_worker )

// capping ag hours at 80 per worker

list aghrs_per_worker othhh_hrs_ag num_hh_agworkers if othhh_hrs_ag > 80 & ~mi(othhh_hrs_ag) & problem_hhagworkers == 1

** we didn't have more than 15 household members from the household roster, so unclear what's going on with those reporting more than that number of household members. Need to figure out where we think noise is most likely coming from.

replace othhh_hrs_ag = . if othhh_hrs_ag ==  18018
* top-coding other non-missing responses
replace othhh_hrs_ag = num_hh_agworkers * 80 if othhh_hrs_ag > num_hh_agworkers * 80 & ~mi(othhh_hrs_ag) & problem_hhagworkers == 0 // there are some negative values, etc that we don't want to bring into this command yet


egen hh_hrs_ag = rowtotal(othhh_hrs_ag fr_hrs_ag) if !missing(selfag)

recode s7_q11_outsidehoursworked_* (-99 = .)
egen outside_hrs_ag = rowtotal(s7_q11_outsidehoursworked_*) if !missing(selfag)

egen tot_hrs_ag = rowtotal(hh_hrs_ag outside_hrs_ag) if !missing(selfag)


** self-employment revenue / costs / profits **
egen nonag_numemployees = rowtotal(s8_q6_numemployees_*) if !missing(selfemp)
egen nonag_hhemployees = rowtotal(s8_q6a_hhemployees_*) if !missing(selfemp)
egen nonag_employeeslast6mth = rowtotal(s8_q6b_employeeslast6mth_*) if !missing(selfemp)

egen hh_hrs_selfemp = rowtotal(s8_q4_hrsworked_*) if !missing(selfemp)
ren hrsworked_self_main fr_hrs_selfemp
replace fr_hrs_selfemp = . if missing(selfemp)




*************************************

/** MW additions: figure out exactly where these should slot in **/
** Household level: Extensive margin
ren selfag hh_selfag
la var hh_selfag "HH engages in agriculture"

gen hh_selfemp = p4_3_selfemployed // constructed based on s8_q1_selfemployed. If switching to this, then need to be careful
tab s8_q1a_numbusinesses // if report 0 businesses, changing
replace hh_selfemp = 0 if s8_q1a_numbusinesses == 0

gen hh_emp = (s9_q1_employed == 1 | s9_q1a_volunteer == 1) if ~mi(s9_q1_employed) | ~mi(s9_q1a_volunteer) // decide how we want to consider volunteer work -- unclear if this was being brought in before
tab s9_q1b_numemp // some with zero -- using this to recode main measure
replace hh_emp = 0 if s9_q1b_numemp == 0


** Wage employment sectors **
gen hh_emp_occ_nonag = 0 if ~mi(hh_emp)
la var hh_emp_occ_nonag "dummy for any hh member employed in non-agriculture"

gen hh_emp_occ_agfish = 0 if ~mi(hh_emp)
la var hh_emp_occ_agfish "dummy for any hh member employed in agriculture"

gen hh_emp_occ_retail = 0 if ~mi(hh_emp)
la var hh_emp_occ_retail "dummy for any hh member employed in retail"

gen hh_emp_occ_skill = 0 if ~mi(hh_emp)
la var hh_emp_occ_skill "dummy for any hh member employed in skilled trade"

gen hh_emp_occ_unskill = 0 if ~mi(hh_emp)
la var hh_emp_occ_unskill "dummy for any hh member employed in unskilled trade"

gen hh_emp_occ_prof = 0 if ~mi(hh_emp)
la var hh_emp_occ_prof "dummy for any hh member employed in professional jobs"

gen hh_emp_occ_other = 0 if ~mi(hh_emp)
la var hh_emp_occ_other "dummy for any hh member employed in other jobs"

** checking reported hours worked for those in self-employment **
forval i = 1 / 5 {
	tab s8_q4_hrsworked_`i'
	recode s8_q4_hrsworked_`i' (120/max = .)
}

** checking reported hours worked for those in employment **
forval i = 1 / 4 {
	tab s9_q8_hrsworked_`i' // nothing over 120 - make sure I know where these were top-coded
}


** looping through occupations **
forval i = 1 / 4 {
	** indicator for being in ag laborer, livestock, or fishing -- not counting selling own ag products, considering that retail ***
	replace hh_emp_occ_agfish = 1 if inlist(s9_q4_occupation_`i', 1, 2, 3, 4)
	replace hh_emp_occ_nonag = 1 if hh_emp == 1 & hh_emp_occ_agfish == 0

	replace hh_emp_occ_retail = 1 if inlist(s9_q4_occupation_`i', 5,6,7,8,9,10)
	replace hh_emp_occ_unskill = 1 if inlist(s9_q4_occupation_`i', 11,76,12,77,13,14,15,16,78)
	replace hh_emp_occ_skill = 1 if inlist(s9_q4_occupation_`i', 79,80,17,18,81,19,20,21,71,72,82,73,74,75,23)
	replace hh_emp_occ_prof = 1 if inlist(s9_q4_occupation_`i', 24,25,26,27,28,29,30,31,32)
	replace hh_emp_occ_other = 1 if inlist(s9_q4_occupation_`i', 83,40,50,60,61)
}



** Wage employment sectors **
gen hh_emp_hrs = 0 if ~mi(hh_emp)
la var hh_emp_hrs "Household hours employed"

gen hh_emp_hrs_occ_nonag = 0 if ~mi(hh_emp_hrs)
la var hh_emp_hrs_occ_nonag "Household hours employed in non-agriculture"

gen hh_emp_hrs_occ_agfish = 0 if ~mi(hh_emp_hrs)
la var hh_emp_hrs_occ_agfish "Household hours employed in agriculture"

gen hh_emp_hrs_occ_retail = 0 if ~mi(hh_emp_hrs)
la var hh_emp_hrs_occ_retail "Household hours employed in retail"

gen hh_emp_hrs_occ_skill = 0 if ~mi(hh_emp_hrs)
la var hh_emp_hrs_occ_skill "Household hours employed in skilled trade"

gen hh_emp_hrs_occ_unskill = 0 if ~mi(hh_emp_hrs)
la var hh_emp_hrs_occ_unskill "Household hours employed in unskilled trade"

gen hh_emp_hrs_occ_prof = 0 if ~mi(hh_emp_hrs)
la var hh_emp_hrs_occ_prof "Household hours employed in professional jobs"

gen hh_emp_hrs_occ_other = 0 if ~mi(hh_emp_hrs)
la var hh_emp_hrs_occ_other "Household hours employed in other jobs"


** looping through occupations **
forval i = 1 / 4 {
	** indicator for being in ag laborer, livestock, or fishing -- not counting selling own ag products, considering that retail ***
	replace hh_emp_hrs = hh_emp_hrs + s9_q8_hrsworked_`i' if s9_q8_hrsworked_`i' != .

	replace hh_emp_hrs_occ_agfish = hh_emp_hrs_occ_agfish + hh_emp_hrs if inlist(s9_q4_occupation_`i', 1, 2, 3, 4) &  s9_q8_hrsworked_`i' != .
	replace hh_emp_hrs_occ_nonag = hh_emp_hrs_occ_nonag + hh_emp_hrs if hh_emp_hrs_occ_agfish == 0 &  s9_q8_hrsworked_`i' != .

	replace hh_emp_hrs_occ_retail = hh_emp_hrs_occ_retail + hh_emp_hrs if inlist(s9_q4_occupation_`i', 5,6,7,8,9,10) & s9_q8_hrsworked_`i' != .
	replace hh_emp_hrs_occ_unskill = hh_emp_hrs_occ_unskill + hh_emp_hrs if inlist(s9_q4_occupation_`i', 11,76,12,77,13,14,15,16,78) &  s9_q8_hrsworked_`i' != .
	replace hh_emp_hrs_occ_skill = hh_emp_hrs_occ_skill + hh_emp_hrs if inlist(s9_q4_occupation_`i', 79,80,17,18,81,19,20,21,71,72,82,73,74,75,23) &  s9_q8_hrsworked_`i' != .
	replace hh_emp_hrs_occ_prof = hh_emp_hrs_occ_prof + hh_emp_hrs if inlist(s9_q4_occupation_`i', 24,25,26,27,28,29,30,31,32) &  s9_q8_hrsworked_`i' != .
	replace hh_emp_hrs_occ_other = hh_emp_hrs_occ_other + hh_emp_hrs if inlist(s9_q4_occupation_`i', 83,40,50,60,61) &  s9_q8_hrsworked_`i' != .
}

gen hh_n = hhsize1 // number of household members from roster


** Labor supply at the household level **

egen fr_hrs_ag_selfemp = rowtotal(fr_hrs_ag fr_hrs_selfemp), m
recode fr_hrs_ag_selfemp (120/max = 120)
la var fr_hrs_ag_selfemp "Respondent hours worked in ag \& self-employment, last 7 days"
gen fr_hrs_emp = p10_hrsworked - fr_hrs_ag_selfemp // kludge, but works for now
la var fr_hrs_emp "Respondent hours worked in employment, last 7 days"

egen hh_hrs_ag_selfemp = rowtotal(hh_hrs_ag hh_hrs_selfemp), m
//recode hh_hrs_ag_selfemp (120/max = 120) // MW comment - why was this here? This was for household, not individual. If lots of household members working, very plausible that we could have over 120
la var hh_hrs_ag_selfemp "Household hours worked in ag \& self-employment, last 7 days"

tab1 hh_hrs_ag_selfemp hh_emp_hrs // naming here annoyingly inconsistent
tab hh_n, sum(hh_hrs_ag_selfemp)
tab hh_n, sum(hh_emp_hrs)

egen hh_hrs_total = rowtotal(hh_hrs_ag_selfemp hh_emp_hrs), m
la var hh_hrs_total "Household total hours worked"

summ hh_hrs_ag_selfemp hh_emp_hrs hh_hrs_total

// convert into measures of per-worker (ie age >=18) at endline as a check


**********************************


** home rental prices **
************************
tab s6_q5_homestatus
gen rents_home = s6_q5_homestatus == 2 if ~mi(s6_q5_homestatus)
la var rents_home "Indicator for renting home"

recode s6_q5b_mthhomerent (-99=.)
ren s6_q5b_mthhomerent rent_home_mth
la var rent_home_mth "Monthly home rental amount"


*** Land rentals ***
* indicator for households that are renting
recode s6_q8_landrenting (2=0), gen(rents_land)
la var rents_land "Indicator for renting land"

tab1 s6_q8a_acresrenting s6_q8c_monthsrenting s6_q8d_mthlandrent s6_q8di_mthlandrentfx s6_q8dii_landrentperiod s6_q8diii_seasonlength
list s6_q8a_acresrenting s6_q8c_monthsrenting s6_q8d_mthlandrent s6_q8di_mthlandrentfx s6_q8dii_landrentperiod s6_q8diii_seasonlength if s6_q8di_mthlandrentfx == 3 // I am going to ignore these for now -- seem plausibly Kenyan shillings
list s1_hhid_key s6_q8a_acresrenting s6_q8b_agacresrenting s6_q8c_monthsrenting s6_q8d_mthlandrent s6_q8di_mthlandrentfx s6_q8dii_landrentperiod s6_q8diii_seasonlength if s6_q8a_acresrenting >=6 & ~mi(s6_q8a_acresrenting)

gen check1 = s6_q8a_acresrenting >=6 if ~mi(s6_q8a_acresrenting)
replace s6_q8a_acresrenting = s6_q8b_agacresrenting if s6_q8a_acresrenting >= 6 & s6_q8a_acresrenting == s6_q8c_monthsrenting & ~mi(s6_q8a_acresrenting)
replace s6_q8a_acresrenting = s6_q8b_agacresrenting if s6_q8a_acresrenting >= 1000 & ~mi(s6_q8a_acresrenting)


replace s6_q8d_mthlandrent = 4000 if s1_hhid_key == "601010204007-113"
replace s6_q8c_monthsrenting = 2 if s1_hhid_key == "601040507005-019" // season was listed as 2 months, so going with that
replace s6_q8c_monthsrenting = 12 if s1_hhid_key == "601050101003-080" // this was the answer for ag acres renting
replace s6_q8c_monthsrenting = 12  if s1_hhid_key == "601030302007-062" // matching this with rental period price - unlikely to be 6's all the way across

/*  601020403008-045  this one still looks weird - 8 acres, all used for ag, for 8 months. Rental price looks very low. In ag section, report using 1 acre for agriculture in s7, report owning 0.5 acres for ag in s6, So instead, assuming 0.5 acres for 8 months, all used for ag */
replace s6_q8a_acresrenting     = 0.5 if s1_hhid_key == "601020403008-045"
replace s6_q8b_agacresrenting   = 0.5 if s1_hhid_key == "601020403008-045"

list s1_hhid_key s6_q8a_acresrenting s6_q8b_agacresrenting s6_q8c_monthsrenting s6_q8d_mthlandrent s6_q8di_mthlandrentfx s6_q8dii_landrentperiod s6_q8diii_seasonlength if check1 == 1 // look more reasonable now, dropping check
drop check1

list s1_hhid_key s6_q8a_acresrenting s6_q8b_agacresrenting s6_q8c_monthsrenting s6_q8d_mthlandrent s6_q8di_mthlandrentfx s6_q8dii_landrentperiod s6_q8diii_seasonlength  if s6_q8d_mthlandrent < 200 & s6_q8d_mthlandrent > 0
replace s6_q8d_mthlandrent = . if s6_q8d_mthlandrent < 100 // some missing, some months, rather than rates

* monthly amount renting per acre
gen         rent_land_mth = s6_q8d_mthlandrent if s6_q8dii_landrentperiod == 3 // monthly period
replace     rent_land_mth = s6_q8d_mthlandrent / 12 if s6_q8dii_landrentperiod == 1 // yearly period
replace     rent_land_mth = s6_q8d_mthlandrent / s6_q8diii_seasonlength if s6_q8dii_landrentperiod == 2 // seasonal period


gen rent_land_mth_acre = rent_land_mth /  s6_q8a_acresrenting
la var rent_land_mth_acre "Monthly land rental price per acre (tenants)"

gen rent_land_acres = s6_q8a_acresrenting
la var rent_land_acres "Number of acres renting (tenants)"

summ rent_land_mth rent_land_mth_acre rent_land_acres


/*** RENTING OUT LAND ***/
* indicator for households that are renting out
recode s6_q7_rentedland (2=0), gen(rentsout_land)
la var rentsout_land "Indicator for renting out land"
replace rentsout_land = 0 if s6_q6_acresowned == 0 // those with no land do not rent any out, and we did not ask this question to them
tab rentsout_land

* monthly amount renting out per acre
tab1 s6_q7a_acresrented s6_q7b_monthsrented s6_q7ci_landrent s6_q7cii_landrentfx s6_q7cii_landrentfx_oth s6_q7ciii_landrentperiod s6_q7civ_seasonlength

** handling problem cases - months rented not reported in months
list s6_q7a_acresrented s6_q7b_monthsrented s6_q7ci_landrent s6_q7ciii_landrentperiod s6_q7civ_seasonlength if s6_q7b_monthsrented < 1
/* given these reported a yearly land rental period, and 88% of rentals are for the year, assuming months rented should have been 12 */
replace s6_q7b_monthsrented = 12 if s6_q7b_monthsrented < 1 & s6_q7ciii_landrentperiod == 1

list s6_q7a_acresrented s6_q7b_monthsrented s6_q7ci_landrent s6_q7ciii_landrentperiod s6_q7civ_seasonlength if s6_q7ci_landrent < 100 & s6_q7ci_landrent > 0
replace s6_q7ci_landrent = . if s6_q7ci_landrent > 0 & s6_q7ci_landrent < 100 // no clear way to deal with these, can impute mean price and replace later if needed

list s6_q7a_acresrented s6_q7b_monthsrented s6_q7ci_landrent s6_q7ciii_landrentperiod s6_q7civ_seasonlength if s6_q7a_acresrented >= 6 & ~mi(s6_q7a_acresrented) // these look okay - seem plausible

gen         rentout_land_mth = s6_q7ci_landrent if s6_q7ciii_landrentperiod == 3 // monthly period
replace     rentout_land_mth = s6_q7ci_landrent / 12 if s6_q7ciii_landrentperiod == 1 // yearly period
replace     rentout_land_mth = s6_q7ci_landrent / s6_q7civ_seasonlength if s6_q7ciii_landrentperiod == 2 // seasonal period

gen rentout_land_mth_acre = rentout_land_mth /  s6_q7a_acresrented
la var rentout_land_mth_acre "Monthly land rental price per acre (landlords)"

gen rentout_land_acres = s6_q7a_acresrented
la var rentout_land_acres "Number of acres rented out (landlords)"

summ rentout_land_mth rentout_land_mth_acre rentout_land_acres


** Land prices **
gen owns_land = s6_q6_acresowned > 0 if ~mi(s6_q6_acresowned)
tab owns_land
la var owns_land "Indicator for owning land"

gen own_land_acres = s6_q6_acresowned
la var own_land_acres "Acres of land owned (incl those with no land)"

* cost of buying an acre of land - based on directly asking for cost to buy an acre of land, but only for those owning any land, as we ask for comparable quality to their own land *
//replace s6_q6a_acrevalue = . if s6_q6a_acrevalue >= 20e6 // handful of large outliers - from a quick batch of googling, it seems like prices around 1M are reasonable for plots being sold on the internet.
replace land_price = .  if land_price >= 20e6 // this is constructed in asset do file

ren land_price landprice
la var landprice "Price of one acre of land"

/*
/*** HOUSEHOLD-LEVEL WAGE RESULTS ***/
** shares of households with a member working for wages **
tab emp
bys eligible: tab emp

** number of household members working for wages (conditional and unconditional) **
gen num_hhmem_emp = s9_q1b_numemp if emp == 1
replace emp = 0 if num_hhmem_emp == 0
replace num_hhmem_emp = . if num_hhmem_emp == 0

bys eligible: tab num_hhmem_emp

gen num_hhmem_emp_all = num_hhmem_emp
replace num_hhmem_emp_all = 0 if emp == 0

by eligible: tab num_hhmem_emp_all


** share of FRs working for wages **
tab1 s9_q2_hhmemberemp_?
gen fr_emp = (s9_q2_hhmemberemp_1 == 0 | s9_q2_hhmemberemp_2 == 0 | s9_q2_hhmemberemp_3 == 0 | s9_q2_hhmemberemp_4 == 0) if ~mi(emp)

by eligible: tab fr_emp

gen skillocc = 0 if ~mi(s9_q4_occupation_1)
forval i=1/4 {
    tab s9_q4_occupation_`i'
    replace skillocc = 1 if inlist(s9_q4_occupation_`i', 9,10,14,17,18,19,20)
    replace skillocc = 1 if s9_q4_occupation_`i'>=24 & s9_q4_occupation_`i'<50
    replace skillocc = 1 if s9_q4_occupation_`i'>=71 & s9_q4_occupation_`i'<78 | s9_q4_occupation_`i' == 83
}

gen unskillocc = 1 if skillocc == 0

by eligible: summ emp num_hhmem_emp_all num_hhmem_emp fr_emp skillocc unskillocc

la var hh_selfemp "Houseld in self-employment"
la var skillocc "Indicator for skilled employment"
la var num_hhmem_emp_all "Number of household members employed (all HHs)"
la var num_hhmem_emp "Number of household members employed (cond on emp)"
la var fr_emp "FR employed"
*/

******************************
** Add in capital cost data **
******************************
egen any_loan = rowmax(any_roscaloan any_bankloan any_shylock any_mshwari any_hhloan)
egen tot_loanamt = rowtotal(*_loanamt)

*****************************
** Add in tax outcomes 	   **
*****************************

project, original("$dr/Walker_HHTax_ECMA_PUBLIC.dta") preserve
merge 1:1 hhid_key using "$dr/Walker_HHTax_ECMA_PUBLIC.dta", keepusing(h24_totinftax_wins h23_totformaltax_wins selfemp_mktfees_ann_w_all selfemp_licamt_ann_all_wins emp_income_tax_ann_w_all totctytax_all_wins totnatltax_all_wins)

foreach var of varlist h24_totinftax_wins h23_totformaltax_wins selfemp_mktfees_ann_w_all selfemp_licamt_ann_all_wins emp_income_tax_ann_w_all totctytax_all_wins totnatltax_all_wins {
	gen `var'_PPP = `var'*$ppprate
	loc vl : variable label `var'
	la var `var'_PPP "`vl' (PPP)"
}

** Total local (county + informal) taxes paid, as this relevant for local GDP
egen tottaxpaid_all_wins_PPP = rowtotal(totctytax_all_wins_PPP h24_totinftax_wins_PPP), m
summ  tottaxpaid_all_wins_PPP

loc taxvars h24_totinftax_*PPP h23_totformaltax_*PPP selfemp_mktfees_ann_w_all_*PPP selfemp_licamt_ann_all_*PPP emp_income_tax_ann_w_all_*PPP totctytax_all_*PPP totnatltax_all_*PPP tottaxpaid_all_*PPP


*****************************
** Define psych outcomes   **
*****************************
loc psychvars ""
//h5_1_cesd h5_2_happiness h5_3_satisfaction h5_4_stress h5_5_asp h5_6_selfeff h5_7_loc h5_8_hope

*****************************
** Define child outcomes   **
*****************************
egen p7_4_daysattendsch_mean = rowmean(p7_4_*)
egen p7_5_schexpenditures_mean = rowmean(p7_5_schexpenditures_*_wins_PPP)

gen time_with_children = 0
foreach v of varlist s17_q*_activity*_v2{
	replace time_with_children = time_with_children + .5 if `v' == 13
}

* child food security index
foreach var of varlist h9_2_skippedchild h9_4_nofoodchild h9_6_hungrychild {
	gen `var'_neg = - `var'
}
gen_index_vers h9_2_skippedchild_neg h9_4_nofoodchild_neg h9_6_hungrychild_neg, prefix(child_foodsec) label("Child food security")

loc childvars p7_1_educexpense_wins_PPP p7_2_propschool p7_4_daysattendsch_mean p7_5_schexpenditures_mean /*p7_6_daysmissedsch_mean*/ h9_2_skippedchild h9_4_nofoodchild h9_6_hungrychild time_with_children child_foodsec

*****************************
** Define crime outcomes   **
*****************************
loc crimevars crime_numthefts crime_anythefts crime_anyassaults crime_numassaults crime_anyunreported crime_worry
loc crimevars_n ""
* re-signing index variables so that higher values represent higher security
foreach var of varlist crime_numthefts crime_anythefts crime_anyassaults crime_numassaults crime_anyunreported crime_worry {
	gen `var'_n = -`var'
	local crimevars_n "`crimevars_n' `var'_n"
}

gen_index_vers crime_numthefts_n crime_numassaults_n crime_anyunreported_n crime_worry_n, prefix(security_index)

loc crimevars `crimevars' security_index


*********************************
** Define expenditure outcomes **
*********************************
loc expvars durables_exp* nondurables_exp* h2_1_foodcons_12mth_wins_PPP h2_3_temptgoods_12_wins_PPP h2_4_housingexp_wins_PPP h2_5_educexp_wins_PPP h2_6_medicalexp_wins_PPP h2_7_socialexp_wins_PPP  amttransrec_wins_PPP amttranssent_wins_PPP nettransfersHHvill_f4_wins_PPP nettransfersfamily_f4_wins_PPP

loc expassetsvars s12_q1_cerealsamt_12mth s12_q1_rootsamt_12mth s12_q1_pulsesamt_12mth s12_q1_vegamt_12mth s12_q1_meatamt_12mth s12_q1_fishamt_12mth s12_q1_dairyeggsamt_12mth s12_q1_othanimalamt_12mth s12_q1_oilamt_12mth s12_q1_fruitsamt_12mth s12_q1_sugaramt_12mth s12_q1_sweetsamt_12mth s12_q1_softdrinksamt_12mth s12_q1_spicesamt_12mth s12_q1_foodoutamt_12mth s12_q1_foodothamt_12mth h2_3_temptgoods_12 ///
s12_q19_airtimeamt_12mth s12_q20_internetamt_12mth s12_q21_travelamt_12mth s12_q22_gamblingamt_12mth s12_q25_personalamt_12mth s12_q23_clothesamt_12mth s12_q26_hhitemsamt_12mth s12_q27_firewoodamt_12mth s12_q28_electamt_12mth s12_q29_wateramt_12mth ///
s12_q24_recamt_12mth s12_q33_religiousamt s12_q34_charityamt s12_q35_weddingamt s12_q38_dowryamt ///
h2_5_educexp s12_q30_rentamt h2_6_medicalexp s12_q39_othexpensesamt ///
s6_q13a_bicyclevalue s6_q13b_motorcyclevalue s6_q13c_carvalue s6_q13d_kerosenevalue s6_q13e_radiovalue s6_q13f_sewingvalue ///
s6_q13g_lanternvalue s6_q13h_bedvalue s6_q13hh_generatorvalue s6_q13i_mattressvalue s6_q13j_bednetvalue s6_q13k_tablevalue s6_q13l_sofavalue s6_q13m_chairvalue s6_q13n_cupboardsvalue ///
s6_q13o_clockvalue s6_q13p_elecironvalue s6_q13q_televisionvalue s6_q13r_computervalue s6_q13s_mobilevalue s6_q13t_carbatteryvalue s6_q13u_boatvalue ///
s6_q13v_sheetsvalue s6_q13w_farmtoolsvalue s6_q13x_handcartvalue s6_q13y_wbarrowvalue s6_q13z_oxplowvalue s6_q13aa_cattlevalue s6_q13bb_goatvalue ///
s6_q13cc_sheepvalue s6_q13dd_chickenvalue s6_q13ee_othbirdvalue s6_q13ff_pigvalue s6_q13gg_solarvalue h1_10_housevalue


*********************************
** Define health outcomes **
*********************************

loc healthvars health_self healthsymp_index health_hasmajorprob health_daysmissed health_majorprobresolve  health_numvisits health_medexpend*


*********************************
** Define female empowerment outcomes **
*********************************

loc femvars p8_1_violence_index p8_4_freqviolence p8_6_freqemotviolence freq_sexualviolence p8_2_attitude_index p8_10_maleorientrespond p8_11_domviolence p8_9_maritalcont


*********************************
** Define educ empowerment outcomes **
*********************************
egen p7_6_daysmissed_mean = rowmean(s4_2_q21a_daysmissed_*)

loc eduvars p7_1_educexpense_wins_PPP p7_2_propschool p7_3_neweduc p7_4_daysattendsch_mean p7_5_schexpenditures_mean p7_6_daysmissed_mean


loc hhroster_vars "hhros_num_sch_aged hhros_num_in_sch numadults numprimeage"




** NOW BIG  COMMAND **
**************************
ren totselfempprofit1_selfemp totsempprofit1_selfemp
ren nonagcosts_* nagc_*
foreach v in nagc nagc_other nagc_security nagc_repairs nagc_inputs nagc_goodsresale nagc_interest nagc_insurance nagc_elecwater nagc_rent nagc_wagebill {
	gen `v'_yrly = `v'_mth*12
}

keep sublocation_code village_code hhid_key survey_mth eligible treat hi_sat p?_* p??_* h?_?_* h?_??_* ///
hh_selfag p3_1_agprofit totagrevenue cropproduction cropowncons* cropsales* animalproduction animalowncons animalsales aglanduse totagcosts aglandcost totcropcosts totlivestockcosts totpoultrycosts totfishpondcosts totothagcosts cropinputcosts livestockinputcosts poultryinputcosts fishpondinputcosts othinputcosts totagsalarycost cropsalarycost livestocksalarycost fishpondsalarycost poultrysalarycost othsalarycost ///
tot_hrs_ag fr_hrs_ag fr_hrs_ag_selfemp hh_hrs_ag_selfemp fr_hrs_emp hh_emp_hrs hh_hrs_ag hh_hrs_total outside_hrs_ag hh_selfemp p3_2_nonagprofit totselfempprofit12_all totsempprofit1_selfemp totselfempprofit1_all totselfemprev p4_6_nonagcosts totnonagcosts_selfemp nagc_yrly nagc_other_yrly nagc_security_yrly nagc_repairs_yrly nagc_inputs_yrly nagc_goodsresale_yrly nagc_interest_yrly nagc_insurance_yrly nagc_elecwater_yrly nagc_rent_yrly nagc_wagebill_yrly ///
nonag_numemployees nonag_hhemployees nonag_employeeslast6mth fr_hrs_selfemp hh_hrs_selfemp ///
owns_land own_land_acres landprice rentsout_land rentout_land_acres rentout_land_mth rentout_land_mth_acre rents_land rent_land_acres rent_land_mth rent_land_mth_acre rents_home rent_home_mth ///
hh_n hh_emp* amttransrec amttranssent ///
any_loan any_roscaloan any_bankloan any_shylock any_mshwari any_hhloan tot_loanamt rosca_loanamt bank_loanamt shylock_loanamt mshwari_loanamt hhloan_loanamt lw_intrate rosca_intrate bank_intrate shylock_intrate mshwari_intrate hhloan_intrate any_hhlend hhlend_intrate ///
`taxvars' `psychvars' `childvars' `crimevars' `expvars' `expassetsvars' `healthvars' `femvars' `eduvars' `hhroster_vars' assets_* totval_*assets* M* *BL


order p*, sequential
order sublocation_code village_code hhid_key  survey_mth eligible treat hi_sat ///
hh_selfag p3_1_agprofit totagrevenue cropproduction cropowncons* cropsales* animalproduction animalowncons animalsales aglanduse totagcosts aglandcost totcropcosts totlivestockcosts totpoultrycosts totfishpondcosts totothagcosts cropinputcosts livestockinputcosts poultryinputcosts fishpondinputcosts othinputcosts totagsalarycost cropsalarycost livestocksalarycost fishpondsalarycost poultrysalarycost othsalarycost ///
tot_hrs_ag fr_hrs_ag fr_hrs_ag_selfemp hh_hrs_ag_selfemp fr_hrs_emp hh_emp_hrs hh_hrs_ag outside_hrs_ag hh_selfemp p3_2_nonagprofit totselfempprofit12_all totsempprofit1_selfemp totselfempprofit1_all totselfemprev p4_6_nonagcosts totnonagcosts_selfemp nagc_yrly nagc_other_yrly nagc_security_yrly nagc_repairs_yrly nagc_inputs_yrly nagc_goodsresale_yrly nagc_interest_yrly nagc_insurance_yrly nagc_elecwater_yrly nagc_rent_yrly nagc_wagebill_yrly ///
nonag_numemployees nonag_hhemployees nonag_employeeslast6mth fr_hrs_selfemp hh_hrs_selfemp ///
owns_land own_land_acres landprice rentsout_land rentout_land_acres rentout_land_mth rentout_land_mth_acre rents_land rent_land_acres rent_land_mth rent_land_mth_acre rents_home rent_home_mth ///
hh_n hh_emp* amttransrec amttranssent ///
any_loan any_roscaloan any_bankloan any_shylock any_mshwari any_hhloan tot_loanamt rosca_loanamt bank_loanamt shylock_loanamt mshwari_loanamt hhloan_loanamt lw_intrate rosca_intrate bank_intrate shylock_intrate mshwari_intrate hhloan_intrate any_hhlend hhlend_intrate ///
`taxvars' `psychvars' `childvars' `crimevars' `expvars' `expassetsvars' `healthvars' `femvars' `eduvars' `hhroster_vars' `expassetsvars'



** WINSORIZING AND GENERATING PPP VALUES **
*******************************************
foreach v of var p3_1_agprofit totagrevenue cropproduction cropowncons* cropsales* animalproduction animalowncons animalsales totagcosts aglandcost totcropcosts totlivestockcosts totpoultrycosts totfishpondcosts totothagcosts cropinputcosts livestockinputcosts poultryinputcosts fishpondinputcosts othinputcosts totagsalarycost cropsalarycost livestocksalarycost fishpondsalarycost poultrysalarycost othsalarycost ///
p3_2_nonagprofit totselfempprofit12_all totsempprofit1_selfemp totselfempprofit1_all totselfemprev p4_6_nonagcosts totnonagcosts_selfemp nagc_yrly nagc_other_yrly nagc_security_yrly nagc_repairs_yrly nagc_inputs_yrly nagc_goodsresale_yrly nagc_interest_yrly nagc_insurance_yrly nagc_elecwater_yrly nagc_rent_yrly nagc_wagebill_yrly ///
landprice* rentout_land_mth rentout_land_mth_acre rent_land_mth rent_land_mth_acre rents_home rent_home_mth  ///
tot_loanamt rosca_loanamt bank_loanamt shylock_loanamt mshwari_loanamt hhloan_loanamt {
	    capture confirm variable `v'_wins
		if _rc {
			wins_top1 `v'
			gen `v'_wins_PPP = `v'_wins * $ppprate
		}

		loc vl : var label `v'
		la var `v'_wins "`vl' (wins. top 1%)"
		la var `v'_wins_PPP "`vl' (wins. top 1%, PPP)"
}

foreach v of var *_intrate {
		wins_top1 `v'
}



** Generate market access measures **
preserve
project, uses("$da/village_radiipop_wide_1km.dta")
use "$da/village_radiipop_wide_1km.dta", clear
keep village_code p_total*
bys village_code: keep if _n == 1
rename p_total* p_total_*

gen market_access = 0
forval r = 1(1)10 {
	replace market_access = market_access + (`r' - 0.5)^(-8) * p_total_`r'
}

xtile q4_market_access = market_access, n(4)
xtile q2_market_access = market_access, n(2)

keep village_code market_access q?_*
tempfile temp
save `temp'
restore

merge m:1 village_code using `temp' // all merge
drop if _merge == 2
drop _merge


** Add in some aggregations on profits **
*****************************************
gen totprofit_wins_PPP = p3_1_agprofit_wins_PPP + p3_2_nonagprofit_wins_PPP // TK this was created as p3_, which is used in main budget table, but there used rowtotal -- which do we think is best? why do we have more ag than non-ag observations?
gen totrevenue_wins_PPP = totagrevenue_wins_PPP + p4_2_nonagrevenue_wins_PPP // TK this was created as p4_totrevenue, but there used rowtotal -- which do we think is best? why do we have more ag than non-ag observations?
gen totcosts_wins_PPP = totagcosts_wins_PPP + p4_6_nonagcosts_wins_PPP // TK we already have this too, though maybe with rowtotal instead


order totprofit_wins_PPP totrevenue_wins_PPP totcosts_wins_PPP p3_1_agprofit* totagrevenue* cropproduction* cropowncons* cropsales* animalproduction* animalowncons* animalsales* aglanduse* totagcosts* aglandcost* totcropcosts* totlivestockcosts* totpoultrycosts* totfishpondcosts* totothagcosts* cropinputcosts* livestockinputcosts* poultryinputcosts* fishpondinputcosts* othinputcosts* totagsalarycost* cropsalarycost* livestocksalarycost* fishpondsalarycost* poultrysalarycost* othsalarycost* ///
hh_selfag p3_1_agprofit* totagrevenue* cropproduction* cropowncons** cropsales** animalproduction* animalowncons* animalsales* aglanduse* totagcosts* aglandcost* totcropcosts* totlivestockcosts* totpoultrycosts* totfishpondcosts* totothagcosts* cropinputcosts* livestockinputcosts* poultryinputcosts* fishpondinputcosts* othinputcosts* totagsalarycost* cropsalarycost* livestocksalarycost* fishpondsalarycost* poultrysalarycost* othsalarycost* ///
tot_hrs_ag* fr_hrs_ag* fr_hrs_ag_selfemp* hh_hrs_ag_selfemp* fr_hrs_emp* hh_emp_hrs* hh_hrs_ag* outside_hrs_ag* hh_selfemp* p3_2_nonagprofit* totselfempprofit12_all* totsempprofit1_selfemp* totselfempprofit1_all* totselfemprev* p4_6_nonagcosts* totnonagcosts_selfemp* nagc_yrly* nagc_other_yrly* nagc_security_yrly* nagc_repairs_yrly* nagc_inputs_yrly* nagc_goodsresale_yrly* nagc_interest_yrly* nagc_insurance_yrly* nagc_elecwater_yrly* nagc_rent_yrly* nagc_wagebill_yrly* ///
nonag_numemployees* nonag_hhemployees* nonag_employeeslast6mth* fr_hrs_selfemp* hh_hrs_selfemp* ///
owns_land* own_land_acres* landprice* rentsout_land* rentout_land_acres* rentout_land_mth* rentout_land_mth_acre* rents_land* rent_land_acres* rent_land_mth* rent_land_mth_acre* rents_home* rent_home_mth* ///
hh_n hh_emp* amttransrec* amttranssent* ///
any_loan* any_roscaloan* any_bankloan* any_shylock* any_mshwari* any_hhloan* tot_loanamt* rosca_loanamt* bank_loanamt* shylock_loanamt* mshwari_loanamt* hhloan_loanamt* lw_intrate* rosca_intrate* bank_intrate* shylock_intrate* mshwari_intrate* hhloan_intrate* any_hhlend* hhlend_intrate* ///
`taxvars' `psychvars' `childvars' `crimevars' `expvars' `expassetsvars' `healthvars' `femvars' `eduvars'


drop if hhid_key == "" // figure out where these are coming from

** add weights **
project, uses("$da/GE_HH-Survey_Tracking_Attrition.dta") preserve
merge 1:1 hhid_key using "$da/GE_HH-Survey_Tracking_Attrition.dta"
drop if _merge == 2

keep sublocation_code village_code satcluster hhid_key hhweight_EL survey_mth eligible treat hi_sat *market_access* p?_* p??_* h?_?_* h?_??_* ///
totprofit_wins_PPP totrevenue_wins_PPP totcosts_wins_PPP  hh_selfag p3_1_agprofit* totagrevenue* cropproduction* cropowncons** cropsales** animalproduction* animalowncons* animalsales* aglanduse* totagcosts* aglandcost* totcropcosts* totlivestockcosts* totpoultrycosts* totfishpondcosts* totothagcosts* cropinputcosts* livestockinputcosts* poultryinputcosts* fishpondinputcosts* othinputcosts* totagsalarycost* cropsalarycost* livestocksalarycost* fishpondsalarycost* poultrysalarycost* othsalarycost* ///
tot_hrs_ag* fr_hrs_ag* fr_hrs_ag_selfemp* hh_hrs_ag_selfemp* fr_hrs_emp* hh_emp_hrs* hh_hrs_ag* outside_hrs_ag* hh_hrs_total* hh_selfemp* p3_2_nonagprofit* totselfempprofit12_all* totsempprofit1_selfemp* totselfempprofit1_all* totselfemprev* p4_6_nonagcosts* totnonagcosts_selfemp* nagc_yrly* nagc_other_yrly* nagc_security_yrly* nagc_repairs_yrly* nagc_inputs_yrly* nagc_goodsresale_yrly* nagc_interest_yrly* nagc_insurance_yrly* nagc_elecwater_yrly* nagc_rent_yrly* nagc_wagebill_yrly* ///
nonag_numemployees* nonag_hhemployees* nonag_employeeslast6mth* fr_hrs_selfemp* hh_hrs_selfemp* ///
owns_land* own_land_acres* landprice* rentsout_land* rentout_land_acres* rentout_land_mth* rentout_land_mth_acre* rents_land* rent_land_acres* rent_land_mth* rent_land_mth_acre* rents_home* rent_home_mth* ///
hh_n hh_emp* amttransrec* amttranssent* ///
any_loan* any_roscaloan* any_bankloan* any_shylock* any_mshwari* any_hhloan* tot_loanamt* rosca_loanamt* bank_loanamt* shylock_loanamt* mshwari_loanamt* hhloan_loanamt* lw_intrate* rosca_intrate* bank_intrate* shylock_intrate* mshwari_intrate* hhloan_intrate* any_hhlend* hhlend_intrate* ///
`taxvars' `psychvars' `childvars' `crimevars' `expvars' `expassetsvars' `healthvars' `femvars' `eduvars' `hhroster_vars'  assets_* totval_*assets* M* *BL

order village_code hhid_key hhweight_EL survey_mth eligible treat hi_sat *market_access*

save "$dt/HH_spatial_sans_treat.dta", replace
project, creates("$dt/HH_spatial_sans_treat.dta")
