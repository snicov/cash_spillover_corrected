* add in version here?
clear all
set more off
pause on


** Stata options
set more off
set matsize 1000
set maxvar 32000


global dir "${ge_dir}"

adopath ++ "$dir/ado/ssc"
adopath ++ "$dir/ado"


* Disable project (since running do-files directly)
cap program drop project
program define project
	syntax [,do(string) creates(string) uses(string) original(string) preserve]

	if "`do'" != "" {
		do `do'
	}
	else {
		di "Project is disabled, skipping project command. (To re-enable, run -{stata program drop project}-)"
	}
end
