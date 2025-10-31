/* Description: This do file runs do files to do the following:
 	1. Generates final household dataset without spatial treatment
	2. Generates household village-level treatment information
	3. Combines these together */
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

** Preparing final household dataset (note: we could move this into the rest of the construction flow)
project, do("$do/construct/hh-spatial/PrepareHH_sanstreat.do")

** Generate household-level spatial treatment data **
project, do("$do/construct/hh-spatial/PrepareHH_spatialtreat.do")


** Combining into final dataset **
project, do("$do/construct/hh-spatial/PrepareHH_combine.do")
