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

* loading some commands
project, original("$do/programs/run_ge_build_programs.do")
include "$do/programs/run_ge_build_programs.do"

*************************
** 0. Data Preparation **
*************************
project, uses("$da/GE_ENT_BL_EL_AllCombined.dta") preserve
use "$da/GE_ENT_BL_EL_AllCombined.dta", clear

** Use only endline enterprise survey and endline hh survey for agricultural enterprises **
keep if ENT_SUR_EL == 1 | HH_AGENT_SUR_EL == 1
ren ENT_SUR_EL_* *

foreach v of var HH_AGENT_SUR_EL_* {
	local name = substr("`v'",17,.)
	disp "`name'"
	capture: replace `name' = `v' if `name' == . & HH_AGENT_EL == 1
	if _rc != 0 {
		gen `name' = `v' if HH_AGENT_EL == 1
	}
}

foreach v of var HH_AGENT_EL_* {
	local name = substr("`v'",13,.)
	disp "`name'"
	capture: replace `name' = `v' if `name' == . & HH_AGENT_EL == 1
	if _rc != 0 {
		gen `name' = `v' if HH_AGENT_EL == 1
	}
}

project, original( "$dr/GE_Treat_Status_Master.dta") preserve
merge m:1 village_code using "$dr/GE_Treat_Status_Master.dta", keepusing(location_code sublocation_code treat hi_sat)
drop if _merge == 2 // those are villages where no enterprises were surveyed
drop _merge

format village_code %15.0f

** Generate primary endline outcomes **
gen operates_from_hh = (operate_from == 1) if operate_from != .
gen operates_outside_hh = 1 if operates_from_hh != 1 & operate_from != .
replace operates_outside_hh = 0 if operates_outside_hh == . & operate_from != .

** generate indicator for farm enterprise **
gen ent_ownfarm = (HH_AGENT_EL == 1)
replace operates_from_hh = 0 if ent_ownfarm == 1
replace operates_outside_hh = 0 if ent_ownfarm == 1

egen ent_type = group(ent_ownfarm operates_from_hh)

** Generate primary endline outcomes **
gen ent_profit1 = prof_mon * 12
replace ent_profit1 = prof_year if ent_profit1 == .
la var ent_profit1 "Profits, annualized"
gen ent_profit2 = prof_mon * 12 if revprof_incons != 1
replace ent_profit2 = prof_year if ent_profit2 == . & revprof_incons != 1
la var ent_profit2 "Profits (drop incons.), annualized"

gen ent_revenue1 = rev_mon * 12
replace ent_revenue1 = rev_year if ent_revenue1 == .
la var ent_revenue1 "Revenue, annualized"
gen ent_revenue2 = rev_mon * 12 if revprof_incons != 1
replace ent_revenue2 = rev_year if ent_revenue2 == . & revprof_incons != 1
la var ent_revenue2 "Revenue (drop incons.), annualized"

gen ent_profitmargin1 = ent_profit1/ent_revenue1
la var ent_profitmargin1 "Profit margin"
gen ent_profitmargin2 = ent_profit2/ent_revenue2
la var ent_profitmargin2 "Profit margin (drop incons.)"

gen ent_totaltaxes = t_county + t_national + t_chiefs + t_other
la var ent_totaltaxes "Total taxes paid last year"

gen ent_wagebill = wage_total * 12
la var ent_wagebill "Total wage bill, annualized"
gen ent_inv = inv_mon * 12
la var ent_inv "Investment, annualized"
gen ent_inventory = inventory
la var ent_inventory "Inventory"
gen ent_rent = c_rent * 12
la var ent_rent "Rent paid, annualized"
gen ent_security = c_security * 12
la var ent_security "Security costs, annualized"

gen ent_totcost = ent_wagebill + ent_rent + ent_security
replace ent_totcost = ent_wagebill + c_total if HH_AGENT_EL == 1
la var ent_totcost "Total costs, annualized"

** Slack variables **
gen ent_cust_perhour = cust_perweek/op_hoursperweek
la var ent_cust_perhour "Customers per hour business is open"

gen ent_rev_perhour = rev_mon/(op_hoursperweek*4)
la var ent_rev_perhour "Revenue per hour business is open"

** Labor market variables **
gen ent_hrs_tot = emp_h_tot
la var ent_hrs_tot "Total labor hours last week"

la var wage_h "Average hourly wage paid by enterprise"

**Generating enterprise sector**
/*
 * Sector 1: Retail
1 "Tea buying centre" 2 "Small retail" 3 "M-Pesa"
6 "Large retail" 9 "Hardware store" 16 "Bookshop"
22 "Food stall / Raw food and fruits vendor" 23 "Chemist"
27 "Petrol station"
31 "Livestock / Animal (Products) / Poultry Sale"
34 "Fish Sale / Mongering" 35 "Cereals" 36 "Agrovet"
39 "Non-Food Vendor"
*/

gen sector = 1 if inlist(bizcat, 1, 2, 3, 6, 9, 16, 22, 23, 27, 31, 34, 35, 36, 39)
replace sector = 1 if inlist(bizcat_nonfood, 2, 9, 12) // mtumba, kerosene and water all most similar to retail

/*
Sector 2: Manufacturing

 17 "Posho mill" 18 "Welding / metalwork" 19 "Carpenter"
 30 "Sale or brewing of homemade alcohol / liquor"
 38 "Jaggery"
 40 "Non-Food Producer"
*/
replace sector = 2 if inlist(bizcat, 17, 18, 19, 30, 38, 40)

/*
Sector 3: Services
4 "Mobile charging" 5 "Bank agent"
7 "Restaurant" 8 "Bar"
10 "Barber shop" 11 "Beauty shop / Salon" 12 "Butcher"
13 "Video Room/Football hall" 14 "Cyber café" 15 "Tailor"
20 "Guesthouse/ Hotel" 21 "Food stand / Prepared food vendor"
24 "Motor Vehicles Mechanic" 25 "Motorcycle Repair / Shop" 26 "Bicycle repair / mechanic shop"  28 "Piki driver" 29 "Boda driver"
32 "Oxen / donkey / tractor plouging" 37 "Photo studio"
 */
replace sector = 3 if inlist(bizcat, 4, 5, 7, 8, 10, 11, 12, 13, 14, 15, 20, 21, 24, 25, 26, 28, 29, 32, 37)
replace sector = 3 if inlist(bizcat_nonfood, 6) & sector == 3 // cobblers to services

/* agriculture -
61 (new farm enterprises), 33 (fishing) (note that there are no fishing enterprises)
*/

replace sector = 4 if inlist(bizcat, 61, 33)

la define sectors 1 "Retail" 2 "Manufacturing" 3 "Services" 4 "Agriculture"
la val sector sectors

gen all = 1
gen ent = 1 if sector == 1
gen manuf = 1 if sector == 2
gen service = 1 if sector == 3
gen agri = 1 if sector == 4


** Generate baseline controls for primary endline outcomes **
*************************************************************

/** NOTE -- THIS IS FOR ENTERPRISES FOR WHICH WE HAVE PANEL INFORMATION.
   VILLAGE-LEVEL AVERAGES ARE MERGED IN BELOW **/

** fix baseline village code **
ren HH_ENT_BL_village_code village_code_BL
replace village_code_BL = HH_AGENT_BL_village_code if HH_AGENT_BL == 1

** Here, we give the baseline survey priority over the baseline census (where we have information for both) **
gen operates_from_hh_BL = (ENT_SUR_BL_operate_from == 1) if ENT_SUR_BL_operate_from != .
replace operates_from_hh_BL = (ENT_CEN_BL_operate_from == 1) if operates_from_hh_BL == . & ENT_CEN_BL_operate_from != .
replace operates_from_hh_BL = (HH_ENT_CEN_BL_operate_from == 1) if operates_from_hh_BL == . & HH_ENT_CEN_BL_operate_from != .
corr operates_from_hh_BL operates_from_hh // there is a positive correlation, but it's not that close to 1.

gen operates_outside_hh_BL = 1 if operates_from_hh_BL != 1 & operates_from_hh_BL != .
replace operates_outside_hh_BL = 0 if operates_outside_hh_BL == . & operates_from_hh_BL != .

** generate indicator for farm enterprise **
gen ent_ownfarm_BL = (HH_AGENT_BL == 1)
replace operates_from_hh_BL = 0 if ent_ownfarm_BL == 1
replace operates_outside_hh_BL = 0 if ent_ownfarm_BL == 1

egen ent_type_BL = group(ent_ownfarm_BL operates_from_hh_BL)

** Baseline sector **
*********************
gen bizcat_BL = ENT_SUR_BL_bizcat
replace bizcat_BL = HH_ENT_SUR_BL_bizcat if bizcat == .
replace bizcat_BL = HH_ENT_CEN_BL_bizcat  if bizcat == .
replace bizcat_BL = HH_AGENT_SUR_BL_bizcat if bizcat == .

** Services
gen sector_BL = 1 if inlist(bizcat_BL, 1, 2, 3, 6, 9, 12, 16, 22, 23, 27, 34, 35, 36, 39, 31)

** Manufacturing
replace sector_BL = 2 if inlist(bizcat_BL, 15, 17, 18, 19, 30, 40, 33, 32, 38)

** Services
replace sector_BL = 3 if inlist(bizcat_BL, 4, 5, 7, 8, 10, 11, 13, 14, 20, 21, 24, 25, 26, 28, 29, 37)

** Agriculture **
replace sector_BL = 4 if inlist(bizcat_BL, 61)


** Baseline profits / revenues **
*********************************
gen prof_mon1_BL = ENT_SUR_BL_prof_mon
replace prof_mon1_BL = HH_ENT_SUR_BL_prof_mon if prof_mon1_BL == .
replace prof_mon1_BL = HH_ENT_CEN_BL_prof_mon if prof_mon1_BL == .
gen ent_profit1_BL = prof_mon1_BL * 12
la var ent_profit1_BL "Baseline profits, annualized"

gen prof_mon2_BL = ENT_SUR_BL_prof_mon if ENT_SUR_BL_revprof_incons != 1
replace prof_mon2_BL = HH_ENT_SUR_BL_prof_mon if prof_mon2_BL == . & HH_ENT_SUR_BL_revprof_incons != 1
replace prof_mon2_BL = HH_ENT_CEN_BL_prof_mon if prof_mon2_BL == . & HH_ENT_CEN_BL_revprof_incons != 1
gen ent_profit2_BL = prof_mon2_BL * 12
la var ent_profit2_BL "Baseline profits (drop incons.), annualized"

gen rev_mon1_BL = ENT_SUR_BL_rev_mon
replace rev_mon1_BL = HH_ENT_SUR_BL_rev_mon if rev_mon1_BL == .
replace rev_mon1_BL = HH_ENT_CEN_BL_rev_mon if rev_mon1_BL == .
gen ent_revenue1_BL = rev_mon1_BL * 12
la var ent_revenue1_BL "Baseline revenue, annualized"

gen rev_mon2_BL = ENT_SUR_BL_rev_mon if ENT_SUR_BL_revprof_incons != 1
replace rev_mon2_BL = HH_ENT_SUR_BL_rev_mon if rev_mon2_BL == . & HH_ENT_SUR_BL_revprof_incons != 1
replace rev_mon2_BL = HH_ENT_CEN_BL_rev_mon if rev_mon2_BL == . & HH_ENT_CEN_BL_revprof_incons != 1
gen ent_revenue2_BL = rev_mon2_BL * 12
la var ent_revenue2_BL "Baseline revenue (drop incons.), annualized"

gen ent_profitmargin1_BL = ent_profit1_BL/ent_revenue1_BL
la var ent_profitmargin1_BL "Baseline profit margin"
gen ent_profitmargin2_BL = ent_profit2_BL/ent_revenue2_BL
la var ent_profitmargin2_BL "Baseline profit margin (drop incons.)"

gen ent_totaltaxes_BL = ENT_SUR_BL_t_county + ENT_SUR_BL_t_national + ENT_SUR_BL_t_chiefs + ENT_SUR_BL_t_other
replace ent_totaltaxes_BL = HH_ENT_SUR_BL_t_county + HH_ENT_SUR_BL_t_national + HH_ENT_SUR_BL_t_chiefs + HH_ENT_SUR_BL_t_other if ent_totaltaxes_BL == .
la var ent_totaltaxes_BL "Baseline total taxes paid last year"

gen wage_total_BL = ENT_SUR_BL_wage_total
replace wage_total_BL = HH_ENT_SUR_BL_wage_total if wage_total_BL == .
replace wage_total_BL = HH_AGENT_SUR_BL_wage_total if wage_total_BL == .
gen ent_wagebill_BL = wage_total_BL * 12
la var ent_wagebill_BL "Baseline total wage bill, annualized"

gen c_rent_BL = ENT_SUR_BL_c_rent
replace c_rent_BL = HH_ENT_SUR_BL_c_rent if c_rent_BL == .
gen ent_rent_BL = c_rent_BL * 12
la var ent_rent_BL "Baseline rent paid, annualized"

gen ent_totcost_BL = ent_wagebill_BL + ENT_SUR_BL_c_rent + ENT_SUR_BL_c_security
replace ent_totcost_BL = ent_wagebill_BL + HH_ENT_SUR_BL_c_rent + HH_ENT_SUR_BL_c_utilities + HH_ENT_SUR_BL_c_repairs + HH_ENT_SUR_BL_c_healthinsurance + HH_ENT_SUR_BL_c_vandalism if ent_totcost_BL == .
replace ent_totcost_BL = ent_wagebill_BL + HH_AGENT_SUR_BL_c_total if ent_totcost_BL == .
la var ent_totcost_BL "Baseline total costs, annualized"

drop ENT_* HH_ENT_* HH_AGENT_*

** Winsorize and PPP **
foreach v of var ent_profit? ent_profitmargin? ent_revenue? ent_totaltaxes ent_wagebill ent_inv ent_inventory ent_rent ent_security ent_totcost wage_h {
	wins_top1 `v', by(ent_type)
	gen `v'_wins_PPP = `v'_wins * $ppprate

	loc vl : var label `v'
	la var `v'_wins "`vl' (wins. top 1%)"
	la var `v'_wins_PPP "`vl' (wins. top 1%, PPP)"
}

** non-PPP outcomes **
foreach v of var ent_cust_perhour op_hoursperday op_hoursperweek {
	wins_top1 `v', by(ent_type)
}

** winsorize for some outcomes by sector **
foreach v of var ent_profit? ent_profitmargin? ent_revenue? ent_totaltaxes ent_wagebill ent_inv ent_inventory ent_rent ent_security ent_totcost wage_h ent_rev_perhour {
	gen `v'_wins_s_PPP = `v' * $ppprate

** looping through sectors **
	forval i = 1 / 4 {
		summ `v'_wins_s_PPP if sector == `i', d
		replace `v'_wins_s_PPP = r(p99) if sector == `i' & `v'_wins_s_PPP > r(p99) & ~mi(`v'_wins_s_PPP)
		local vl : var label `v'
		la var `v'_wins_s_PPP "`vl' (wins by sector)"
	}
}

** non-PPP outcomes **
foreach v of var ent_cust_perhour op_hoursperday op_hoursperweek {
	gen `v'_wins_s = `v'
	forval i = 1 / 4 {
		summ `v' if sector == `i', d
		replace `v'_wins_s = r(p99) if sector == `i' & `v' > r(p99) & ~mi(`v')
		local vl : var label `v'
		la var `v'_wins_s "`vl' (wins by sector)"
	}
}


** take logs for some skewed outcomes **
foreach v of var ent_cust_perhour ent_rev_perhour {
	gen ln_`v' = ln(`v')
	local vl : variable label `v'
	la var ln_`v' "Log `vl'"
}


foreach v of var ent_profit?_BL ent_profitmargin?_BL ent_revenue?_BL ent_totaltaxes_BL ent_wagebill_BL ent_rent_BL ent_totcost_BL {
	wins_top1 `v', by(ent_type)
	gen `v'_wins_PPP = `v'_wins * $ppprate

	loc vl : var label `v'
	la var `v'_wins "`vl' (wins. top 1%)"
	la var `v'_wins_PPP "`vl' (wins. top 1%, PPP)"
}


* also generating versions by sector *
foreach v of var ent_profit?_BL ent_profitmargin?_BL ent_revenue?_BL ent_totaltaxes_BL ent_wagebill_BL ent_rent_BL ent_totcost_BL {
	gen `v'_wins_s_PPP = `v' * $ppprate

	forval i = 1 / 4 {

	summ `v'_wins_s_PPP if sector == `i' , d

	replace `v'_wins_s_PPP = r(p99) if `v'_wins_s_PPP > r(p99) & ~mi(`v'_wins_s_PPP) & sector == `i'
	loc vl : var label `v'
	la var `v'_wins_s_PPP "`vl' (wins. top 1% by sector, PPP)"
}
}


** rename **
foreach v of var *BL_wins* {
	local name = substr("`v'",1,strpos("`v'","_BL")) + substr("`v'",strpos("`v'","_BL") + 4,.) + "_BL"
	disp "`name'"
	rename `v' `name'
}

** Set baseline control to average and add indicator for missing values **
foreach v of var ent_profit?_*BL ent_profitmargin*_BL ent_revenue*_BL ent_totaltaxes_*BL ent_wagebill_*BL ent_rent_*BL ent_totcost_*BL{
	gen M`v' = (`v' == .)
	label var M`v' "`v' missing at BL"

	foreach typ in 1 2 3 {
		sum `v' [weight=entweight_EL] if ent_type == `typ'
		if `r(N)' == 0 {
			** set to overall mean when there is no baseline for any in this category
			summ M`v' if ent_type == `typ'
			assert r(min) == 1 & r(max) == 1
			summ `v' [weight=entweight_EL]
			replace `v' = r(mean) if `v' == . & ent_type == `typ'
		}
		else {
			sum `v' [weight=entweight_EL] if ent_type == `typ'
			replace `v' = r(mean) if `v' == . & ent_type == `typ'
		}
	}
}


**********************************************
** Merge in village-level baseline controls **
**********************************************
project, uses("$da/intermediate/GE_ENT_BL_VillageAvg.dta") preserve

merge m:1 village_code ent_type using "$da/intermediate/GE_ENT_BL_VillageAvg.dta"
list village_code ent_type operates_from_hh if _merge == 1 // those have operates_from_hh missing or are from strange villages
drop if _merge == 1
drop if _merge == 2 // we don't have enteprises of that type from those villages in the survey
drop _merge
** note: there are only 649 villages in the endline census

**************************
*** Add in Census Data ***
**************************
preserve
project, uses("$da/GE_ENT_BL_EL_AllCombined.dta")
use "$da/GE_ENT_BL_EL_AllCombined.dta", clear

** where survey and census disagree, set location equal to survey **
count if ENT_CEN_EL_operate_from != ENT_SUR_EL_operate_from & ENT_SUR_EL_operate_from != .
replace ENT_CEN_EL_operate_from = ENT_SUR_EL_operate_from if ENT_CEN_EL_operate_from != ENT_SUR_EL_operate_from & ENT_SUR_EL_operate_from != .

gen n_operates_from_hh = (ENT_CEN_EL_operate_from == 1) if ENT_CEN_EL_operate_from != .
gen n_operates_outside_hh = (ENT_CEN_EL_operate_from != 1) if ENT_CEN_EL_operate_from != .
gen n_ent_ownfarm = (HH_AGENT_EL == 1) * 0.964 // not quite all households have an own-farm enterprise
egen n_allents = rowtotal(n_operates_from_hh n_operates_outside_hh n_ent_ownfarm)

gen n_ent_elig = (ownerm_eligible == 1)
gen n_ent_inelig = (ownerm_eligible == 0)
gen n_ent_treat = (ownerm_eligible == 1 & ownerm_treat == 1)
gen n_ent_eligcontrol = (ownerm_eligible == 1 & ownerm_treat == 0)
gen n_ent_untreat = (ownerm_eligible == 0 | ownerm_treat == 0)

** baseline numbers **
gen operates_from_hh_BL = (ENT_SUR_BL_operate_from == 1) if ENT_SUR_BL_operate_from != .
replace operates_from_hh_BL = (ENT_CEN_BL_operate_from == 1) if operates_from_hh_BL == . & ENT_CEN_BL_operate_from != .
replace operates_from_hh_BL = (HH_ENT_CEN_BL_operate_from == 1) if operates_from_hh_BL == . & HH_ENT_CEN_BL_operate_from != .
corr operates_from_hh_BL n_operates_from_hh // there is a positive correlation, but it's not that close to 1.

gen operates_outside_hh_BL = 1 if operates_from_hh_BL != 1 & operates_from_hh_BL != .
replace operates_outside_hh_BL = 0 if operates_outside_hh_BL == . & operates_from_hh_BL != .

** generate indicator for farm enterprise **
gen ent_ownfarm_BL = (HH_AGENT_BL == 1)
replace operates_from_hh_BL = 0 if ent_ownfarm_BL == 1
replace operates_outside_hh_BL = 0 if ent_ownfarm_BL == 1

tab operates_from_hh_BL HH_ENT_BL // WORKS

gen n_operates_from_hh_BL = (operates_from_hh_BL == 1) if operates_from_hh_BL != .
gen n_operates_outside_hh_BL = (operates_from_hh_BL == 0) if HH_ENT_BL == 1 & operates_from_hh_BL != .
gen n_ent_ownfarm_BL = (ent_ownfarm_BL == 1) * 0.964 if ent_ownfarm_BL != . // not quite all households have an own-farm enterprise
egen n_allents_BL = rowtotal(n_operates_from_hh_BL n_operates_outside_hh_BL n_ent_ownfarm_BL)

** fix village code **
list ENT_SUR_EL_village_code ENT_CEN_EL_village_code if ENT_SUR_EL_village_code != ENT_CEN_EL_village_code & ENT_SUR_EL_village_code != . // some enterprises changed villages, adjust
replace ENT_CEN_EL_village_code = ENT_SUR_EL_village_code if ENT_SUR_EL_village_code != ENT_CEN_EL_village_code & ENT_SUR_EL_village_code != .
gen double village_code = ENT_CEN_EL_village_code
replace village_code = HH_ENT_BL_village_code if village_code == .
replace village_code = HH_ENT_BL_village_code if village_code == .
replace village_code = HH_AGENT_EL_village_code if village_code == .

** fix date for agricultural enterprises **
replace ENT_CEN_EL_date = HH_AGENT_SUR_EL_date if HH_AGENT_EL == 1
collapse (sum) n_allents* n_operates_from_hh* n_operates_outside_hh* n_ent_ownfarm* n_ent_elig* n_ent_inelig* n_ent_treat* n_ent_untreat* (mean) avgdate_vill=ENT_CEN_EL_date, by(village_code)

* bringing in full list of villages, setting those without any enterprises in census to zero
project, original("$dr/GE_Treat_Status_Master.dta") preserve
merge 1:1 village_code using "$dr/GE_Treat_Status_Master.dta", gen(_m) keepusing(village_code flag_dropvill)

drop if flag_dropvill == 1
drop if _m == 1 // what's going on here? see about fixing these
drop _m flag_dropvill

codebook village_code // should have 653

foreach var of varlist n_allents* n_operates_from_hh* n_operates_outside_hh* n_ent_ownfarm* n_ent_elig* n_ent_inelig*  n_ent_treat* n_ent_untreat* {
	replace `var' = 0 if `var' == .
}

summ avgdate_vill
replace avgdate_vill = r(mean) if avgdate_vill == .

tempfile temp
save `temp'
restore

merge m:1 village_code using `temp'
drop if _merge != 3 // these are problematic village codes
drop _merge

save "$da/intermediate/TEMP_ENT_CHECKS.dta", replace


** drop duplicate village-level observations **
foreach v of var n_allents* n_operates_from_hh* n_operates_outside_hh* n_ent_ownfarm* n_ent_elig* n_ent_inelig*  n_ent_treat* n_ent_untreat*{ //sample_from_hh sample_outside_hh{
	bys village_code (ent_id_universe): replace `v' = . if _n > 1
}

save "$da/GE_ENT-Analysis_AllENTs.dta", replace
project, creates("$da/GE_ENT-Analysis_AllENTs.dta")
