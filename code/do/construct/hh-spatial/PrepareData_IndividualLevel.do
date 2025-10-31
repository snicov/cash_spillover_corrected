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

do "$do/programs/run_ge_build_programs.do"

// end preliminaries

*************************
** 0. Data Preparation **
*************************

** a) For employment, get individual-by-occupation-level data **
****************************************************************
project, uses("$dt/wages_individbyoccupationlevel.dta")
use "$dt/wages_individbyoccupationlevel.dta", clear

destring s9_q4_occupation s9_q12f_othbenefits, replace
destring s9_q12a_payinkind s9_q12b_healthins s9_q12c_housing s9_q12d_clothing s9_q12e_training s9_q12f_othbenefits, replace

gen occ_skil = (inlist(s9_q4_occupation, 9,10,17,18,19,20,21,23,80,81)) if ~mi(s9_q4_occupation)
replace occ_skil = 1 if s9_q4_occupation>=24 & s9_q4_occupation<50
replace occ_skil = 1 if s9_q4_occupation>=71 & s9_q4_occupation<77 | s9_q4_occupation == 83

gen occ_unsk = 1 if occ_skil == 0
replace occ_unsk = 0 if occ_skil == 1

replace s9_q4_occupation = 15 if strpos(lower(s9_q4_occupation_oth1), "boda") > 0 | strpos(lower(s9_q4_occupation_oth1), "piki") > 0
tab s9_q4_occupation_oth1 if s9_q4_occupation == 15
replace s9_q4_occupation_oth1 = "" if s9_q4_occupation == 15

** slightly broader occupation categories **
gen occ_agri          	= (inlist(s9_q4_occupation, 1, 2,3,4)) if ~mi(s9_q4_occupation)
gen occ_rtail          	= (inlist(s9_q4_occupation, 5,6,7,8,9,10)) if ~mi(s9_q4_occupation)
gen occ_usktr       	= (inlist(s9_q4_occupation, 11,76,12,77,13,14,15,16,78,79)) if ~mi(s9_q4_occupation)
gen occ_sktr         	= (inlist(s9_q4_occupation, 80,17,18,81,19,20,21,71,72,82,73,74,75,23)) if ~mi(s9_q4_occupation)
gen occ_prof            = (inlist(s9_q4_occupation, 24,25,26,27,28,29,30,31,32)) if ~mi(s9_q4_occupation)
gen occ_other           = (inlist(s9_q4_occupation, 83,40,50,60,61)) if ~mi(s9_q4_occupation)

gen occ_nag = (occ_rtail == 1 | occ_usktr == 1 | occ_sktr == 1 | occ_prof == 1 | occ_other == 1)
cap ren s1_hhid_key hhid_key


** generate hours by sector **
order occ_skil occ_unsk occ_agri occ_nag occ_rtail occ_usktr occ_sktr occ_prof occ_other, last

ren s9_q8_hrsworked emp_hrs
foreach sec in skil unsk agri nag rtail usktr sktr prof other {
	gen emp_hrs_`sec' = emp_hrs if occ_`sec' == 1
	replace emp_hrs_`sec' = 0 if occ_`sec' != 1
}

** generate total earnings **
egen emp_ben_y = rowtotal(s9_q12a_payinkind s9_q12b_healthins s9_q12c_housing s9_q12d_clothing s9_q12e_training s9_q12f_othbenefits), m
replace emp_ben_y = emp_ben_y * 12
gen emp_cshsal_y = s9_q10_cashsalary * 12
gen emp_cshben_y = emp_ben_y + emp_cshsal_y

foreach sec in skil unsk agri nag rtail usktr sktr prof other {
	gen emp_ben_y_`sec' = emp_ben_y if occ_`sec' == 1
	gen emp_cshsal_y_`sec' = emp_cshsal_y if occ_`sec' == 1
	gen emp_cshben_y_`sec' = emp_cshben_y if occ_`sec' == 1
}

** Collapse to individual level **
foreach v of var emp_hrs* emp_cshben* emp_cshsal* emp_ben* {
	ren `v' a
	bys hhid_key hhros_num: egen `v' = sum(a), missing
	drop a
}

collapse (max) occ* (first) emp_hrs* emp_cshben* emp_cshsal* emp_ben*, by(hhid_key hhros_num)

** generate wages by sector **
gen emp_cshben_perh = emp_cshben_y / (emp_hrs / 7 * 30 * 12)
gen emp_cshsal_perh = emp_cshsal_y / (emp_hrs / 7 * 30 * 12)
gen emp_ben_perh = emp_ben_y / (emp_hrs / 7 * 30 * 12)

foreach sec in skil unsk agri nag rtail usktr sktr prof other {
	gen emp_cshben_perh_`sec' = emp_cshben_y_`sec' / (emp_hrs_`sec' / 7 * 30 * 12)
	gen emp_cshsal_perh_`sec' = emp_cshsal_y_`sec' / (emp_hrs_`sec' / 7 * 30 * 12)
	gen emp_ben_perh_`sec' = emp_ben_y_`sec' / (emp_hrs_`sec' / 7 * 30 * 12)
}

gen emp = 1 // those are only the employed people
gen persid = _n

keep persid hhid_key hhros_num emp occ* emp_hrs* emp_cshben* emp_cshsal* emp_ben*
order persid hhid_key hhros_num emp occ* emp_hrs* emp_cshben* emp_cshsal* emp_ben*

tempfile indiv_wages
save `indiv_wages'


** b) Individual level - self employment **
*******************************************
project, uses("$da/GE_HH-Survey-EL_WageProfits_Roster.dta")
use "$da/GE_HH-Survey-EL_WageProfits_Roster.dta", clear

** merge in latitude and longitude **
preserve
project, uses("$da/GE_HH-Analysis_AllHHs.dta")
use "$da/GE_HH-Analysis_AllHHs.dta", clear
ren s1_q2b_sublocation sublocation_code
keep s1_hhid_key sublocation_code survey_mth
tempfile temp
save `temp'
restore

merge m:1 s1_hhid_key using `temp'
drop if _merge == 2

cap ren s1_hhid_key hhid_key


** Deal with self-employment outcomes **
gen selfemp = 1 if _mselfemp != 1
replace selfemp = 0 if selfemp == .
ren s8_q4_hrsworked selfemp_hrs

gen selfemp_prof_y = s8_q11a_profitlastmth * 12
gen selfemp_earn_y = s8_q7a_earningslastmth * 12

gen selfemp_prof_perh = selfemp_prof_y / (selfemp_hrs / 7 * 30 * 12)
gen selfemp_earn_perh = selfemp_earn_y / (selfemp_hrs / 7 * 30 * 12)


** Clean controls for wage regressions **
/*
replace age = s4_1_q5_age if hhros_num > 0

gen gender = s2_q3_gender
replace gender = s4_1_q4_sex if hhros_num > 0

gen edusystem = s5_q1_system
replace edusystem = s4_1_q7_edusystem if hhros_num > 0

gen highestedu = s5_q1a_highestedu
replace highestedu = s4_1_q7_highestedu if hhros_num > 0

destring highestedu, replace

gen yearsedu = 0 if edusystem==3
replace yearsedu = highestedu - 100 if edusystem == 1
replace yearsedu = highestedu - 200 if edusystem == 2 & highestedu<=207
replace yearsedu = highestedu - 201 if edusystem == 2 & highestedu>207 & highestedu<215 /* need to take one extra year off for forms */
replace yearsedu = 0 if highestedu == 130 | highestedu == 230
replace yearsedu = . if highestedu == 122 | highestedu == 222

gen noschool = edusystem == 3 if ~mi(edusystem)
la var noschool "No schooling"

gen stdschool = highestedu > 107 if edusystem == 1
replace stdschool = highestedu > 206 if edusystem == 2
replace stdschool = 0 if edusystem == 3
la var stdschool "Completed primary school"

gen someformschool = highestedu > 108 if edusystem == 1
replace someformschool = highestedu > 207 if edusystem == 2
replace someformschool = 0 if edusystem == 3
la var someformschool "Some secondary school"

gen formschool = highestedu > 111 if edusystem == 1
replace formschool = highestedu > 211 if edusystem == 2
replace formschool = 0 if edusystem == 3
la var formschool "Completed secondary school"

keep hhid_key hhros_num age gender yearsedu noschool stdschool someformschool formschool selfemp selfemp_* _mwages
order hhid_key hhros_num age gender yearsedu noschool stdschool someformschool formschool selfemp selfemp_* _mwages
*/
** merge in roster info - age, years education, etc **
cap drop _merge
project, uses("$da/GE_HH-Endline_HHRoster_LONG.dta") preserve
merge 1:1 hhid_key hhros_num using "$da/GE_HH-Endline_HHRoster_LONG.dta", keepusing(age* female male yearsedu* noschool stdschool formschool someformschool) gen(z)
tab z
drop z


** merge in employment data **
merge 1:1 hhid_key hhros_num using `indiv_wages'
tab _merge _mwages // matches nicely
drop _merge _mwages
replace emp = 0 if emp == .


** For intensive labor supply, generate unconditionals **
*********************************************************
foreach v of var selfemp_hrs selfemp_prof_y selfemp_earn_y {
	gen `v'_all = `v'
	replace `v'_all = 0 if selfemp == 0
}

foreach v of var occ_* emp_hrs* emp_*y* {
	gen `v'_all = `v'
	replace `v'_all = 0 if emp == 0
}


** Generate FR level variables **
*********************************
//foreach v of var age gender yearsedu noschool stdschool someformschool formschool selfemp* emp occ_* emp_hrs* emp_*y* emp_*perh* {
foreach v of var age yearsedu noschool stdschool someformschool formschool selfemp* emp occ_* emp_hrs* emp_*y* emp_*perh* {
	gen fr_`v' = `v' if hhros_num == 0
}

** Generate HH level variables **
*********************************

** Self-employment **
bys hhid_key: egen hh_selfemp = max(selfemp)
replace hh_selfemp = . if hhros_num != 0

foreach v of var selfemp_hrs* selfemp_prof_y* selfemp_earn_y* {
	bys hhid_key: egen hh_`v' = sum(`v'), missing
	replace hh_`v' = . if hhros_num != 0
}

foreach v in selfemp_prof selfemp_earn {
	gen hh_`v'_perh = hh_`v'_y / hh_selfemp_hrs if hh_selfemp == 1
}

** Employment **
foreach v of var emp occ_* {
	bys hhid_key: egen hh_`v' = max(`v')
	replace hh_`v' = . if hhros_num != 0
}

foreach v of var emp_hrs* emp_*y* {
	bys hhid_key: egen hh_`v' = sum(`v'), missing
	replace hh_`v' = . if hhros_num != 0
}

foreach v in emp_cshben emp_cshsal emp_ben {
	gen hh_`v'_perh = hh_`v'_y / hh_emp_hrs

	foreach sec in skil unsk agri nag rtail usktr sktr prof other {
		gen hh_`v'_perh_`sec' = hh_`v'_y_`sec' / hh_emp_hrs_`sec' if hh_emp == 1
	}
}



keep hhid_key hhros_num  ///
age* male female yearsedu* noschool stdschool someformschool formschool ///
selfemp selfemp_hrs* selfemp_*y* selfemp_*perh* emp occ_* emp_hrs* emp_cshben_y* emp_cshben_perh* emp_cshsal_y* emp_cshsal_perh* emp_ben_y* emp_ben_perh* ///
fr_age  fr_noschool fr_stdschool fr_someformschool fr_formschool ///
fr_selfemp fr_selfemp_hrs* fr_selfemp_*y* fr_selfemp_*perh* fr_emp fr_occ_* fr_emp_hrs* fr_emp_cshben_y* fr_emp_cshben_perh* fr_emp_cshsal_y* fr_emp_cshsal_perh* fr_emp_ben_y* fr_emp_ben_perh* ///
hh_selfemp hh_selfemp_hrs* hh_selfemp_*y* hh_selfemp_*perh* hh_emp hh_occ_* hh_emp_hrs* hh_emp_cshben_y* hh_emp_cshben_perh* hh_emp_cshsal_y* hh_emp_cshsal_perh* hh_emp_ben_y* hh_emp_ben_perh*

keep hhid_key hhros_num  ///
age* yearsedu* noschool stdschool someformschool formschool ///
selfemp selfemp_hrs* selfemp_*y* selfemp_*perh* emp occ_* emp_hrs* emp_cshben_y* emp_cshben_perh* emp_cshsal_y* emp_cshsal_perh* emp_ben_y* emp_ben_perh* ///
fr_age /*fr_gender  fr_years*edu* */ fr_noschool fr_stdschool fr_someformschool fr_formschool ///
fr_selfemp fr_selfemp_hrs* fr_selfemp_*y* fr_selfemp_*perh* fr_emp fr_occ_* fr_emp_hrs* fr_emp_cshben_y* fr_emp_cshben_perh* fr_emp_cshsal_y* fr_emp_cshsal_perh* fr_emp_ben_y* fr_emp_ben_perh* ///
hh_selfemp hh_selfemp_hrs* hh_selfemp_*y* hh_selfemp_*perh* hh_emp hh_occ_* hh_emp_hrs* hh_emp_cshben_y* hh_emp_cshben_perh* hh_emp_cshsal_y* hh_emp_cshsal_perh* hh_emp_ben_y* hh_emp_ben_perh*

** CROSS-CHECK WITH household level labor supply variables **
preserve
project, uses("$da/GE_HHLevel_ECMA.dta")
use "$da/GE_HHLevel_ECMA.dta", clear
keep hhid hhid_key survey_mth sublocation_code village_code eligible treat hi_sat hhweight_EL hh_selfag hh_hrs_ag fr_hrs_ag hh_selfemp hh_hrs_selfemp fr_hrs_selfemp hh_emp p10_*
order hhid hhid_key survey_mth sublocation_code village_code eligible treat hi_sat hhweight_EL hh_selfag hh_hrs_ag fr_hrs_ag hh_selfemp hh_hrs_selfemp fr_hrs_selfemp hh_emp p10_*

ren hh_hrs_selfemp hh_selfemp_hrs
ren fr_hrs_selfemp fr_selfemp_hrs

foreach v of var hh_selfag hh_hrs_ag fr_hrs_ag hh_selfemp hh_selfemp_hrs fr_selfemp_hrs hh_emp p10_* {
	ren `v' new_`v'
}
tempfile temp
save `temp'
restore

merge m:1 hhid_key using `temp'
drop _merge
foreach v of var new_* {
	replace `v' = . if hhros_num != 0
}

foreach v of var hh_selfemp hh_selfemp_hrs fr_selfemp_hrs hh_emp {
	corr `v' new_`v' // these are all very very close. Leave for now
}

ren new_hh_selfag hh_selfag
ren new_hh_hrs_ag hh_selfag_hrs
ren new_fr_hrs_ag fr_selfag_hrs
ren new_p10_5_hoursjobsearch fr_jobsearch_hrs
ren new_p10_6_hourschores fr_chores_hrs
ren new_p10_7_leisurehours fr_leisure_hrs1
ren new_p10_7_leisurehours_v2 fr_leisure_hrs2

drop new_*
**********

** WINSORIZING AND GENERATING PPP VALUES **
*******************************************
foreach v of var *_y* *_perh* {
		wins_top1 `v'
		gen `v'_winP = `v'_wins * $ppprate
		drop `v'_wins

		*loc vl : var label `v'
		*la var `v'_wins "`vl' (wins. top 1%)"
		*la var `v'_wins_PPP "`vl' (wins. top 1%, PPP)"

		gen l_`v' = ln(`v')
		*gen l_`v'_wins = ln(`v'_wins)
		gen l_`v'_winP = ln(`v'_winP)
}


/*
order hhid_key latitude longitude survey_mth hhweight_EL sublocation_code village_code eligible treat hi_sat hhros_num  ///
age* /*male female*/ yearsedu* noschool stdschool someformschool formschool ///
selfemp selfemp_hrs* selfemp_*y* selfemp_*perh* l_selfemp_*y* l_selfemp_*perh* emp occ_* emp_hrs* emp_cshben_y* emp_cshben_perh* emp_cshsal_y* emp_cshsal_perh* emp_ben_y* emp_ben_perh* l_emp_cshben_y* l_emp_cshben_perh* l_emp_cshsal_y* l_emp_cshsal_perh* l_emp_ben_y* l_emp_ben_perh* ///
fr_age fr_gender fr_yearsedu fr_noschool fr_stdschool fr_someformschool fr_formschool ///
fr_jobsearch_hrs fr_chores_hrs fr_leisure_hrs1 fr_leisure_hrs2 fr_selfag_hrs fr_selfemp selfemp fr_selfemp_hrs* fr_selfemp_*y* fr_selfemp_*perh* l_fr_selfemp_*y* l_fr_selfemp_*perh* fr_emp fr_occ_* fr_emp_hrs* fr_emp_cshben_y* fr_emp_cshben_perh* fr_emp_cshsal_y* fr_emp_cshsal_perh* fr_emp_ben_y* fr_emp_ben_perh* l_fr_emp_cshben_y* l_fr_emp_cshben_perh* l_fr_emp_cshsal_y* l_fr_emp_cshsal_perh* l_fr_emp_ben_y* l_fr_emp_ben_perh* ///
hh_selfag hh_selfag_hrs hh_selfemp selfemp hh_selfemp_hrs* hh_selfemp_*y* hh_selfemp_*perh* l_hh_selfemp_*y* l_hh_selfemp_*perh* hh_emp hh_occ_* hh_emp_hrs* hh_emp_cshben_y* hh_emp_cshben_perh* hh_emp_cshsal_y* hh_emp_cshsal_perh* hh_emp_ben_y* hh_emp_ben_perh* l_hh_emp_cshben_y* l_hh_emp_cshben_perh* l_hh_emp_cshsal_y* l_hh_emp_cshsal_perh* l_hh_emp_ben_y* l_hh_emp_ben_perh* ///

keep hhid_key latitude longitude survey_mth hhweight_EL sublocation_code village_code eligible treat hi_sat hhros_num  ///
age /*gender */ yearsedu noschool stdschool someformschool formschool ///
selfemp selfemp_hrs* selfemp_*y* selfemp_*perh* l_selfemp_*y* l_selfemp_*perh* emp occ_* emp_hrs* emp_cshben_y* emp_cshben_perh* emp_cshsal_y* emp_cshsal_perh* emp_ben_y* emp_ben_perh* l_emp_cshben_y* l_emp_cshben_perh* l_emp_cshsal_y* l_emp_cshsal_perh* l_emp_ben_y* l_emp_ben_perh* ///
fr_age /*fr_gender fr_yearsedu*/ fr_noschool fr_stdschool fr_someformschool fr_formschool ///
fr_jobsearch_hrs fr_chores_hrs fr_leisure_hrs1 fr_leisure_hrs2 fr_selfag_hrs fr_selfemp selfemp fr_selfemp_hrs* fr_selfemp_*y* fr_selfemp_*perh* l_fr_selfemp_*y* l_fr_selfemp_*perh* fr_emp fr_occ_* fr_emp_hrs* fr_emp_cshben_y* fr_emp_cshben_perh* fr_emp_cshsal_y* fr_emp_cshsal_perh* fr_emp_ben_y* fr_emp_ben_perh* l_fr_emp_cshben_y* l_fr_emp_cshben_perh* l_fr_emp_cshsal_y* l_fr_emp_cshsal_perh* l_fr_emp_ben_y* l_fr_emp_ben_perh* ///
hh_selfag hh_selfag_hrs hh_selfemp selfemp hh_selfemp_hrs* hh_selfemp_*y* hh_selfemp_*perh* l_hh_selfemp_*y* l_hh_selfemp_*perh* hh_emp hh_occ_* hh_emp_hrs* hh_emp_cshben_y* hh_emp_cshben_perh* hh_emp_cshsal_y* hh_emp_cshsal_perh* hh_emp_ben_y* hh_emp_ben_perh* l_hh_emp_cshben_y* l_hh_emp_cshben_perh* l_hh_emp_cshsal_y* l_hh_emp_cshsal_perh* l_hh_emp_ben_y* l_hh_emp_ben_perh* ///
*/

** Merge with village actual spatial treatment data **
******************************************************
merge m:1 village_code using "$dt/Village_spatialtreat_forHH.dta"
drop _merge // all merge

sort sublocation_code village_code hhid_key
gen persid = _n
order sublocation_code village_code hhid_key persid survey_mth eligible treat hi_sat

save "$da/GE_HHIndividualWageProfits_ECMA.dta", replace
project, creates("$da/GE_HHIndividualWageProfits_ECMA.dta")


/*
Are we still using this anywhere? come back after making sure that all analyses can be re-generated

***************************************
** b) Individual-by-occupation level **
***************************************
use "$dr/GE_wages_individuals.dta", clear

** merge in latitude and longitude **
preserve
use "$da/GE_HH-Analysis_AllHHs_$hhdate.dta", clear
ren s19_gps_latitude latitude
ren s19_gps_longitude longitude
keep s1_hhid_key latitude longitude survey_mth
tempfile temp
save `temp'
restore

merge m:1 s1_hhid_key using `temp'
drop if _merge == 2

ren s1_hhid_key hhid_key

ren *unskilltrade* *unskill*
ren *skilltrade* *skill*

** generate hours by sector **
gen occ_nag = (occ_rtail == 1 | occ_unskill == 1 | occ_skill == 1 | occ_prof == 1)

/* Sample already only those employed
ren occ_* occ_*_all
gen occ_d = (occ_ag == 1 | occ_nag == 1)
foreach sec in agri nag rtail unskill skill prof {
	gen occ_`sec' = occ_`sec'_all
	replace occ_`sec' = . if occ_d == 0
}
*/

ren s9_q8_hrsworked hrs_tot

*gen hrs_tot_all = hrs_tot
*replace hrs_tot_all = 0 if hrs_tot_all == .

foreach sec in agri nag rtail unskill skill prof {
	gen hrs_`sec' = hrs_tot if occ_`sec' == 1
	replace hrs_`sec' = 0 if hrs_`sec' == .

	*gen hrs_`sec'_all = hrs_tot
	*replace hrs_`sec'_all = 0 if hrs_`sec'_all == .
}

/*
** generate total earnings **
drop *_PPP *_wins

gen wageben_y = tot_cash_noncash_earnings*12
gen wagesal_y = s9_q12_cahsalary*12
gen ben_y = tot_noncash_ben*12

gen wageben_y_all = wageben_y
replace wageben_y_all = 0 if wageben_y_all == 0
gen wagesal_y_all = wagesal_y
replace wagesal_y_all = 0 if wagesal_y_all == 0
gen ben_y_all = ben_y
replace ben_y_all = 0 if ben_y_all == 0
*/


** generate wages by sector **
gen wageben_perh = hrwage_cashnoncash
gen wagesal_perh = hrwage_cashsal
gen ben_perh = tot_noncash_ben*(7/30) / hrs_tot

foreach sec in agri nag rtail unskill skill prof {
	gen wageben_perh_`sec' = wageben_perh if occ_`sec' == 1
	gen wagesal_perh_`sec' = wagesal_perh if occ_`sec' == 1
	gen ben_perh_`sec' = ben_perh if occ_`sec' == 1
}

keep hhid_key latitude longitude survey_mth village_code eligible treat hi_sat treat_eligible treat_inelig treat_hisat treat_hisat_eligible eligible_control eligible_baseline_BL satcluster hhros_num emp_num skillocc unskillocc occ_* hrs_* *_perh*
order hhid_key latitude longitude survey_mth village_code eligible treat hi_sat treat_eligible treat_inelig treat_hisat treat_hisat_eligible eligible_control eligible_baseline_BL satcluster hhros_num emp_num skillocc unskillocc occ_* hrs_* *_perh*


** add weights **
merge m:1 hhid_key using "$da/GE_HH-Survey_Tracking_Attrition_RA_2018-02-26.dta"
drop if _merge == 2

keep hhid_key latitude longitude survey_mth hhweight_EL village_code eligible treat hi_sat treat_eligible treat_inelig treat_hisat treat_hisat_eligible eligible_control eligible_baseline_BL satcluster hhros_num emp_num skillocc unskillocc occ_* hrs_* *_perh*

** Merge with village actual spatial treatment data **
preserve
use "$da/village_actualtreat_wide_FINAL.dta", clear
collapse (first) p_total_* p_eligible_* p_ge_* dist_ (sum) /* n_* */ amount_*, by(village_code)
tempfile temp
save `temp'
restore

merge m:1 village_code using `temp'
drop _merge // all merge

** Merge with village experimental spatial treatment data **
preserve
use "$da/village_exptreat_wide_FINAL.dta", clear
collapse (first) p_total_* p_ge_* dist_ (sum) exp_*, by(village_code)
tempfile temp
save `temp'
restore

merge m:1 village_code using `temp'
drop _merge // all merge

sort village_code hhid_key hhros_num emp_num
order village_code hhid_key latitude longitude survey_mth hhros_num emp_num


** WINSORIZING AND GENERATING PPP VALUES **
*******************************************
foreach v of var wageben* wagesal* ben* {
		capture confirm variable `v'_wins
		if _rc {
			wins_top1 `v'
			gen `v'_wins_PP = `v'_wins * $ppprate
		}

		loc vl : var label `v'
		la var `v'_wins_PPP "`vl' (wins. top 1%, PPP)"

		gen l_`v' = ln(`v')
		gen l_`v'_win_PP = ln(`v'_wins_PPP)
}



*****************************************
** Generate spatial treatment measures **
*****************************************

*************************************************************************************************
** Our preferred measures are
**
** A) Per capita measures / percent of consumption expenditures (GDP)
** 1. Total amount as a fraction of per person average consumption expenditure (GDP) in each 2km radii band in the last 3 months
** 2. Experimental amount as a fraction of per person average consumption expenditure (GDP) in each 2km radii band in the last 3 months (using different rollout speeds in each county, and a 10% cutoff for the start date)
**
** B) Total amount measures
** 1. Amount (in 1'000'000 USD) in each 2km radii band in the last 3 months
** 2. Experimental amount (in 1'000'000 USD) in each 2km radii band in the last 3 months (using different rollout speeds in each county, and a 10% cutoff for the start date)
**
** C) Cumulated buffer measures
** For all of those measures, I also create the cumulative amount up to a certain distance,
** e.g. the total amount per person sent to HHs between 0 - 8km from the market.
**
** We can add additional measures later.
*************************************************************************************************
rename amount_total_KES* pp_actamt*
rename exp_amount_c_KES_2* pp_expamt*

rename pp_actamt_0* pp_actamt_*
rename pp_actamt_ov_0* pp_actamt_ov_*
rename pp_expamt_0* pp_expamt_*
rename p_total_0* p_total_*
rename p_ge_0* p_ge_*
rename p_ge_eligible_0* p_ge_eligible_*
rename p_total_ov_0* p_total_ov_*
rename p_ge_ov_0* p_ge_ov_*
rename p_ge_eligible_ov_0* p_ge_eligible_ov_*

forval r = 2(2)8 {
	local r2 = `r' - 2
	rename pp_actamt_`r2'to0`r'km pp_actamt_`r2'to`r'km
	rename pp_actamt_ov_`r2'to0`r'km pp_actamt_ov_`r2'to`r'km
	rename pp_expamt_`r2'to0`r'km pp_expamt_`r2'to`r'km
	rename p_total_`r2'to0`r'km p_total_`r2'to`r'km
	rename p_ge_`r2'to0`r'km p_ge_`r2'to`r'km
	rename p_ge_eligible_`r2'to0`r'km p_ge_eligible_`r2'to`r'km
	rename p_total_ov_`r2'to0`r'km p_total_ov_`r2'to`r'km
	rename p_ge_ov_`r2'to0`r'km p_ge_ov_`r2'to`r'km
	rename p_ge_eligible_ov_`r2'to0`r'km p_ge_eligible_ov_`r2'to`r'km
}


** generate instrument measures **
**********************************

** own village **
*****************
gen share_eligible_ownvill = p_eligible_ownvill/p_total_ownvill

replace pp_actamt_ownvill = 1/($pp_GDP)*pp_actamt_ownvill // convert to per-capita GDP amounts
gen actamt_ownvill = pp_actamt_ownvill*($pp_GDP)/($USDKES*1000000)*p_total_ownvill // convert to mio. USD


** overall and other villages **
********************************
forval r = 2(2)20 {
	local r2 = `r' - 2

	gen share_ge_eligible_`r2'to`r'km = p_ge_eligible_`r2'to`r'km/p_total_`r2'to`r'km

	egen cum_p_total_`r'km = rowtotal(p_total_0to2km-p_total_`r2'to`r'km)
	egen cum_p_ge_`r'km = rowtotal(p_ge_0to2km-p_ge_`r2'to`r'km)
	egen cum_p_ge_eligible_`r'km = rowtotal(p_ge_eligible_0to2km-p_ge_eligible_`r2'to`r'km)
	gen cum_share_ge_eligible_`r'km = cum_p_ge_eligible_`r'km/cum_p_total_`r'km
}

forval r = 2(2)20 {
	local r2 = `r' - 2

	gen share_ge_eligible_ov_`r2'to`r'km = p_ge_eligible_ov_`r2'to`r'km/p_total_ov_`r2'to`r'km

	egen cum_p_total_ov_`r'km = rowtotal(p_total_ov_0to2km-p_total_ov_`r2'to`r'km)
	egen cum_p_ge_ov_`r'km = rowtotal(p_ge_ov_0to2km-p_ge_ov_`r2'to`r'km)
	egen cum_p_ge_eligible_ov_`r'km = rowtotal(p_ge_eligible_ov_0to2km-p_ge_eligible_ov_`r2'to`r'km)
	gen cum_share_ge_eligible_ov_`r'km = cum_p_ge_eligible_ov_`r'km/cum_p_total_ov_`r'km
}

foreach inst in actamt expamt {
	forval r = 2(2)20 {
		local r2 = `r' - 2

		replace pp_`inst'_`r2'to`r'km = 1/($pp_GDP)*pp_`inst'_`r2'to`r'km // convert to per-capita GDP amounts
		gen `inst'_`r2'to`r'km = pp_`inst'_`r2'to`r'km*($pp_GDP)/($USDKES*1000000)*p_total_`r2'to`r'km // convert to mio. USD
	}
}

foreach inst in actamt_ov {
	forval r = 2(2)20 {
		local r2 = `r' - 2

		replace pp_`inst'_`r2'to`r'km = 1/($pp_GDP)*pp_`inst'_`r2'to`r'km // convert to per-capita GDP amounts
		gen `inst'_`r2'to`r'km = pp_`inst'_`r2'to`r'km*($pp_GDP)/($USDKES*1000000)*p_total_ov_`r2'to`r'km // convert to mio. USD
	}
}

order actamt_* actamt_ov_* pp_actamt_* pp_actamt_ov_* expamt_* pp_expamt_*, last

foreach inst in actamt expamt {
	forval r = 2(2)20 {
		local r2 = `r' - 2
		egen cum_`inst'_`r'km = rowtotal(`inst'_0to2km-`inst'_`r2'to`r'km)
		gen cum_pp_`inst'_`r'km = cum_`inst'_`r'km*($USDKES*1000000)/cum_p_total_`r'km/($pp_GDP)
	}
}

foreach inst in actamt_ov {
	forval r = 2(2)20 {
		local r2 = `r' - 2
		egen cum_`inst'_`r'km = rowtotal(`inst'_0to2km-`inst'_`r2'to`r'km)
		gen cum_pp_`inst'_`r'km = cum_`inst'_`r'km*($USDKES*1000000)/cum_p_total_ov_`r'km/($pp_GDP)
	}
}

order share_eligible_ownvill actamt_ownvill pp_actamt_ownvill share_ge_* cum_share_ge* actamt_* cum_actamt_* pp_actamt_* cum_pp_actamt_* expamt_* cum_expamt_* pp_expamt_* cum_pp_expamt_*, last

keep hhid_key latitude longitude survey_mth hhweight_EL village_code eligible treat hi_sat treat_eligible treat_inelig treat_hisat treat_hisat_eligible eligible_control eligible_baseline_BL satcluster hhros_num emp_num skillocc unskillocc occ_* hrs_* wageben_* l_wageben_* wagesal_* l_wagesal_* ben_* l_ben_* *ownvill p_total_* p_ge_* share_ge_* cum_share_ge_* actamt_* cum_actamt_* pp_actamt_* cum_pp_actamt_* expamt_* cum_expamt_* pp_expamt_* cum_pp_expamt_*
//order hhid_key latitude longitude survey_mth hhweight_EL village_code eligible treat hi_sat treat_eligible treat_inelig treat_hisat treat_hisat_eligible eligible_control eligible_baseline_BL satcluster hhros_num emp_num skillocc unskillocc occ_* hrs_* wageben_* l_wageben_* wagesal_* l_wagesal_* ben_* l_ben_* *ownvill p_total_* p_ge_* share_ge_* cum_share_ge_* actamt_* cum_actamt_* pp_actamt_* cum_pp_actamt_* expamt_* cum_expamt_* pp_expamt_* cum_pp_expamt_*

** check magnitudes **
bys village_code: gen a = 1 if _n == 1
sum pp_actamt_0to2km if a == 1 // on average, villages get 7.7% of per capita GDP in their 0to2km buffer.
sum pp_actamt_ov_0to2km if a == 1 // on average, villages get 7.7% of per capita GDP in their 0to2km buffer.
sum pp_actamt_ownvill if a == 1 // on average, villages get 7.7% of per capita GDP in their 0to2km buffer.
drop a

** see if amount related to treatment status **
bys village_code: gen a = 1 if _n == 1
reg pp_actamt_ov_0to2km treat if a == 1 // treatment villages get 6.7% of GDP in their smallest buffer, control villages 8.7%
reg pp_actamt_0to2km hi_sat if a == 1 // high vs. low saturation makes little difference for the 0to2km treatment
reg pp_actamt_0to2km treat hi_sat if a == 1 // high vs. low saturation makes little difference for the 0to2km treatment
drop a

gen persid = _n
order persid hhid_key

save "$da/HH_SpatialData_IndividualbyEmploymentWages_FINAL_mincer.dta", replace
*/
