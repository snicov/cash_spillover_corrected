/*** construct all of the spatial data including treatment ***/

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

** constructing spatial household data **
project, do("$do/construct/hh-spatial/PrepareData_HHLevel.do")
project, do("$do/construct/hh-spatial/PrepareData_HHLevel_Lags_New.do")
project, do("$do/construct/hh-spatial/PrepareData_IndividualLevel.do")

** generate spatial datasets -- enterprises **
project, do("$do/construct/ent-spatial/PrepareData_Vill_Ent.do")
project, do("$do/construct/ent-spatial/PrepareData_Ent.do")
project, do("$do/construct/ent-spatial/PrepareData_Ent_Lags.do")
project, do("$do/construct/ent-ML/PrepareData_Ent_ML.do")
