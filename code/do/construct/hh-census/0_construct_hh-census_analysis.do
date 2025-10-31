/*** Constructing household and village-level census datasets ***/




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


project, original("$do/programs/run_ge_build_programs.do")
include "$do/programs/run_ge_build_programs.do"


*** Constructing household-level analysis dataset ***
project, do("$do/construct/hh-census/1_hhcensus_hhlevel_analysis.do")
