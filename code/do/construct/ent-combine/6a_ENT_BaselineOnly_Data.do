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

** Keep only baseline values **

keep if HH_ENT_BL == 1 | HH_ENT_SUR_BL_consent == 1 | ENT_SUR_BL_bizcat != . | ENT_CEN_BL_bizcat != . | HH_AGENT_BL == 1
tab1 HH_ENT_BL HH_ENT_SUR_BL_consent ENT_SUR_BL_bizcat ENT_CEN_BL_bizcat


** fix baseline village code **
ren HH_ENT_BL_village_code village_code_BL
replace village_code_BL = HH_AGENT_BL_village_code if HH_AGENT_BL == 1

codebook village_code_BL

gen double village_code = village_code_BL

project, original( "$dr/GE_Treat_Status_Master.dta") preserve
merge m:1 village_code using "$dr/GE_Treat_Status_Master.dta", keepusing(location_code sublocation_code treat hi_sat)
drop if _merge == 2 // those are villages where no enterprises were surveyed
drop _merge

format village_code %15.0f

** Generate baseline controls for primary endline outcomes **
*************************************************************

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
*replace prof_mon1_BL = HH_AGENT_SUR_BL_prof_year / 12 if prof_mon1_BL == . // we did not measure baseline ag profits well
gen ent_profit1_BL = prof_mon1_BL * 12
la var ent_profit1_BL "Baseline profits, annualized"

gen prof_mon2_BL = ENT_SUR_BL_prof_mon if ENT_SUR_BL_revprof_incons != 1
replace prof_mon2_BL = HH_ENT_SUR_BL_prof_mon if prof_mon2_BL == . & HH_ENT_SUR_BL_revprof_incons != 1
replace prof_mon2_BL = HH_ENT_CEN_BL_prof_mon if prof_mon2_BL == . & HH_ENT_CEN_BL_revprof_incons != 1
*replace prof_mon2_BL = HH_AGENT_SUR_BL_prof_year / 12 if prof_mon2_BL == . & HH_AGENT_SUR_BL_revprof_incons != 1
gen ent_profit2_BL = prof_mon2_BL * 12
la var ent_profit2_BL "Baseline profits (drop incons.), annualized"

gen rev_mon1_BL = ENT_SUR_BL_rev_mon
replace rev_mon1_BL = HH_ENT_SUR_BL_rev_mon if rev_mon1_BL == .
replace rev_mon1_BL = HH_ENT_CEN_BL_rev_mon if rev_mon1_BL == .
*replace rev_mon1_BL = HH_AGENT_SUR_BL_rev_year / 12 if rev_mon1_BL == .
gen ent_revenue1_BL = rev_mon1_BL * 12
la var ent_revenue1_BL "Baseline revenue, annualized"

gen rev_mon2_BL = ENT_SUR_BL_rev_mon if ENT_SUR_BL_revprof_incons != 1
replace rev_mon2_BL = HH_ENT_SUR_BL_rev_mon if rev_mon2_BL == . & HH_ENT_SUR_BL_revprof_incons != 1
replace rev_mon2_BL = HH_ENT_CEN_BL_rev_mon if rev_mon2_BL == . & HH_ENT_CEN_BL_revprof_incons != 1
*replace rev_mon2_BL = HH_AGENT_SUR_BL_rev_year / 12 if rev_mon2_BL == . & HH_AGENT_SUR_BL_revprof_incons != 1
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
replace ent_totcost_BL = HH_AGENT_SUR_BL_c_total if ent_totcost_BL == .
la var ent_totcost_BL "Baseline total costs, annualized"


** baseline date **
gen date_BL = ENT_SUR_BL_date
replace date_BL = ENT_CEN_BL_date  if mi(date_BL) & ~mi(ENT_CEN_BL_date)
replace date_BL = HH_ENT_CEN_BL_date if mi(date_BL) & ~mi(HH_ENT_CEN_BL_date)
replace date_BL = HH_AGENT_BL_date if mi(date_BL) & ~mi(HH_AGENT_BL_date)
replace date_BL = HH_AGENT_SUR_BL_date if mi(date_BL) & ~mi(HH_AGENT_SUR_BL_date)


drop ENT_* HH_ENT_* HH_AGENT_*

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
	/*
		forval j = 1/ 3 {
			summ `v'_wins_s_PPP if sector == `i' & ent_type == `j', d

			replace `v'_wins_s_PPP = r(p99) if `v'_wins_s_PPP > r(p99) & ~mi(`v'_wins_s_PPP) & sector == `i' & ent_type == `j'
		}
	}
	loc vl : var label `v'
	la var `v'_wins_s_PPP "`vl' (wins. top 1% by sector, PPP)"
	*/
}


** rename **
foreach v of var *BL_wins* {
	local name = substr("`v'",1,strpos("`v'","_BL")) + substr("`v'",strpos("`v'","_BL") + 4,.) + "_BL"
	disp "`name'"
	rename `v' `name'
}

ren *profitmargin* *profmarg*

gen baselined_ENT = 1

*** SAVING BASELINE DATASET ***
save "$da/GE_ENT-Analysis_BL.dta", replace
project, creates("$da/GE_ENT-Analysis_BL.dta") preserve


** Generate mean values by operate_from and village **
foreach v of var prof_mon1_BL ent_profit1_BL prof_mon2_BL ent_profit2_BL rev_mon1_BL ent_revenue1_BL rev_mon2_BL ent_revenue2_BL ent_profmarg1_BL ent_profmarg2_BL ent_totaltaxes_BL wage_total_BL ent_wagebill_BL c_rent_BL ent_rent_BL ent_totcost_BL ent_profit1_wins_BL ent_profit1_wins*_PPP_BL ent_profit2_wins_BL ent_profit2_wins*_PPP_BL ent_profmarg1_wins_BL ent_profmarg1_wins*_PPP_BL ent_profmarg2_wins_BL ent_profmarg2_wins*_PPP_BL ent_revenue1_wins_BL ent_revenue1_wins*_PPP_BL ent_revenue2_wins_BL ent_revenue2_wins*_PPP_BL ent_totaltaxes_wins_BL ent_totaltaxes_wins*_PPP_BL ent_wagebill_wins_BL ent_wagebill_wins*_PPP_BL ent_rent_wins_BL ent_rent_wins*_PPP_BL ent_totcost_wins_BL ent_totcost_wins*_PPP_BL {
	local name = subinstr("`v'","_BL","_vBL",.)
	bys village_code_BL ent_type_BL: egen double `name' = wtmean(`v'), weight(entweight_BL)
}

drop village_code
ren village_code_BL village_code
project, original("$dr/GE_Treat_Status_Master.dta") preserve
merge m:1 village_code using "$dr/GE_Treat_Status_Master.dta", gen(_m) keepusing(village_code flag_dropvill)
tab _m flag_dropvill // 11 villages are missing.
drop if flag_dropvill == 1
drop if _m == 1 // those must be mistakes in villages codes, since they don't appear in the masterlist
drop flag_dropvill

** make sure each village has every observation **
** This should be for ent_type_BL in {1,2,3} for each of the 653 villages **
preserve
keep village_code
bys village_code: drop if _n > 1

expand 3
bys village_code: gen ent_type_BL = _n
tempfile allvilobs
save `allvilobs'
restore 

collapse (mean) *_vBL (sum) entweight_BL, by(village_code ent_type_BL)
drop if ent_type_BL == .

merge 1:1 village_code ent_type_BL using `allvilobs', gen(hasBL)

foreach v of var *_vBL* {
	replace `v' = . if hasBL == 2
}

drop hasBL 
bys village_code: gen a = _N
tab a // all observations here
drop a

** Set baseline control to average and add indicator for missing values **
foreach v of var ent_profit?_*vBL ent_profmarg*_vBL ent_revenue*_vBL ent_totaltaxes_*vBL ent_wagebill_*vBL ent_rent_*vBL ent_totcost_*vBL{
	gen M`v' = (`v' == .)
	label var M`v' "`v' missing at BL"

	foreach typ in 1 2 3 {
		sum `v' [weight=entweight_BL] if ent_type == `typ'
		if `r(N)' == 0 {
			** set to overall mean when there is no baseline for any in this category
			summ M`v' if ent_type == `typ'
			assert r(min) == 1 & r(max) == 1
			summ `v' [weight=entweight_BL]
			replace `v' = r(mean) if `v' == . & ent_type == `typ'
		}
		else {
			sum `v' [weight=entweight_BL] if ent_type == `typ'
			replace `v' = r(mean) if `v' == . & ent_type == `typ'
		}
	}
}

ren ent_type_BL ent_type

save "$da/intermediate/GE_ENT_BL_VillageAvg.dta", replace
project, creates("$da/intermediate/GE_ENT_BL_VillageAvg.dta")
