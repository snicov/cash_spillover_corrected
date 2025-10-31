
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

 keep *hhid_key today village_code eligible s1_q1b_ipaid s7_* s8_* s9_*

* need household size for one outcome
project, uses("$da/intermediate/GE_HH-BL_hhroster.dta") preserve
merge 1:1 hhid_key using "$da/intermediate/GE_HH-BL_hhroster.dta", keepusing(hhsize*)
drop _merge

** FR hours worked **
local max_weekly_hrs = 120

* FR hours ag *
tab1 s7_q6_selfhoursworked?
recode s7_q6_selfhoursworked? (99 = .)

egen hrsworked_ag_tot = rowtotal(s7_q6_selfhoursworked1 s7_q6_selfhoursworked2 s7_q6_selfhoursworked3), m
replace hrsworked_ag_tot = 0 if s7_q1_selfag==2
summ hrsworked_ag_tot
la var hrsworked_ag_tot "FR total hours worked in ag, last 7 days"

* FR hours self-emp *
tab1 s8_q4_hrsworked?

tab s8_q1_selfemployed
egen hrsworked_self_main = rowtotal(s8_q4_hrsworked1 s8_q4_hrsworked2 s8_q4_hrsworked3), m
replace hrsworked_self_main = 0 if s8_q1_selfemployed == 2

* FR hours emp *
recode s9_q7_emphrs? (99= .)
tab1 s9_q7_emphrs?
tab s9_q1_employed

egen hrsworked_emp_main = rowtotal(s9_q7_emphrs1 s9_q7_emphrs2 s9_q7_emphrs3), m
replace hrsworked_emp_main = 0 if s9_q1_employed == 2

* generating total *
egen p10_hrsworked = rowtotal(hrsworked_ag_tot hrsworked_self_main hrsworked_emp_main), m
tab p10_hrsworked, m

** capping hours **
recode hrsworked_ag_tot hrsworked_self_main hrsworked_emp_main p10_hrsworked (`max_weekly_hrs'/ max = `max_weekly_hrs')
summ  hrsworked_ag_tot hrsworked_self_main hrsworked_emp_main p10_hrsworked


*** Family hours ag **
tab1 s7_q8_hhhoursworked?
recode s7_q8_hhhoursworked? (99 = .)
egen hh_hrs_ag = rowtotal(s7_q8_hhhoursworked1 s7_q8_hhhoursworked2 s7_q8_hhhoursworked3), m

gen aghrs_perhhmember = hh_hrs_ag / hhsize1

replace hh_hrs_ag = . if aghrs_perhhmember > `max_weekly_hrs'


** saving constructed variables **
drop s7_* s8_* s9_*
save "$da/intermediate/GE_HH-BL_laborsupply.dta", replace
project, creates("$da/intermediate/GE_HH-BL_laborsupply.dta")
