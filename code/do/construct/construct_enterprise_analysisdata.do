/*** construct all of the enterprise data ***/

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

** baseline census **
project, do("$do/construct/ent-census-BL/ge_ent-census_baseline_cleaning.do")
project, do("$do/construct/ent-census-BL/ge_hh-ent_census_baseline_combine.do")


** baseline survey **
project, do("$do/construct/ent-survey-BL/ge_ent-survey_baseline_cleaning.do")
project, do("$do/construct/ent-survey-BL/ge_hh-agent-survey_baseline_cleaning.do")
project, do("$do/construct/ent-survey-BL/ge_hh-ent-survey_baseline_cleaning.do")

** endline census **
project, do("$do/construct/ent-census-EL/ge_ent-census_endline_cleaning.do")

** endline survey **
set varabbrev on
project, do("$do/construct/ent-survey-EL/ge_ent-survey_endline_cleaning.do")
project, do("$do/construct/ent-survey-EL/ge_hh-agent-survey_endline_cleaning.do")

** combine all enterprise data **
project, do("$do/construct/ent-combine/0_ge_hh-ent_baseline_combine.do")
project, do("$do/construct/ent-combine/3_ge_hh-ent_baseline_endline_combine.do")
project, do("$do/construct/ent-combine/4_Create_EnterpriseWeights.do")
project, do("$do/construct/ent-combine/5_Include_OwnerMatches.do")
/* Note: 6-eNT is dropping enterprises not surveyed at endline, so 6a generates stats for these,
and calculates village averages for all baseline enterprises (rather than only panel) */
project, do("$do/construct/ent-combine/6a_ENT_BaselineOnly_Data.do")
project, do("$do/construct/ent-combine/6_ENT_Combine_BL_EL.do")

set varabbrev off
