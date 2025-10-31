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

/*** Master file to call relevant household analysis dataset construction files ***/

** constructing household census **
project, do("$do/construct/hh-census/0_construct_hh-census_analysis.do")

** constructing household baseline data **
project, do("$do/construct/hh-survey-BL/0_construct_hh-survey-BL_analysis.do")

** constructing household endline data **
project, do("$do/construct/hh-survey-EL/0_construct_hh-survey-EL_analysis.do")

* End result of this is non-spatial analysis dataset, with baseline data merged in

** constructing individual-level data **
project, do("$do/construct/hh-survey-EL/201_ge_indiv_demog_EL.do")
project, do("$do/construct/hh-survey-EL/202_ge_indiv_wageprofits_EL.do")
