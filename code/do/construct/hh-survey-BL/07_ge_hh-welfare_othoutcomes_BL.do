/*
 * other analysis variables
 * do file that holds baseline outcomes that are not part of PAP but still of interest
 * Include listing somewhere so that can easily know where to go
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

keep *hhid_key village_code eligible s10_*


/************************************/
/*  FINANCIAL VARIABLES             */
/************************************/

/* Indicators for bank accounts */
recode s10_q0_mpesaaccount (1 = 1) (2 = 0) (nonm = .), gen(fin_mpesa)
la var fin_mpesa "Has Mpesa account"

recode s10_q1_bankaccount (1 = 1) (2 = 0) (nonm = .), gen(fin_banking)
la var fin_banking "Has bank account"

recode s10_q2_sacco (1 = 1) (2 = 0) (nonm = .), gen(fin_sacco)
la var fin_sacco "Participates in SACCO"

recode s10_q3_rosca (1 = 1) (2 = 0) (nonm = .), gen(fin_rosca)
la var fin_rosca "Participates in ROSCA"


** saving **
drop s10_*

save "$da/intermediate/GE_HH-BL_othoutcomes.dta", replace
project, creates("$da/intermediate/GE_HH-BL_othoutcomes.dta")
