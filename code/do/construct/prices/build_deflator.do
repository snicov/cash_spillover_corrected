*************************************
* Deflate Multiplier Dataset
* Tilman Graff
* 2019-07-24
* This file constructs a joint enterprise + household dataset with which we can
*************************************
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

* load commands
project, original("$do/programs/run_ge_build_programs.do")
include "$do/programs/run_ge_build_programs.do"

************************************
** first, create deflator dataset **
************************************
project, uses("$da/GE_MarketData_Panel_ECMA.dta")
use "$da/GE_MarketData_Panel_ECMA.dta", clear
keep month market_id pidx_wKLPS_med

tsset market_id month
tsfill, full
bysort market_id: carryforward pidx_wKLPS_med, gen(newprice)
gsort market_id -month
bysort market_id: carryforward pidx_wKLPS_med, gen(newprice2)

replace pidx_wKLPS_med = newprice if mi(pidx_wKLPS_med) & !mi(newprice)
replace pidx_wKLPS_med = newprice2 if mi(pidx_wKLPS_med) & !mi(newprice2)

gsort market_id month
drop newprice*

gen thismonth = pidx_wKLPS_med if month == tm(2015m1)

bys market_id: egen m2015m1 = mean(thismonth)
drop thismonth

*gen deflator = pidx_wKLPS_med - m2015m1 + 1
gen deflator = exp(pidx_wKLPS_med)/exp(m2015m1)

** generate overall deflator **
bys month: egen a = mean(pidx_wKLPS_med)
bys month: egen b = mean(m2015m1)
gen deflator_studyarea = exp(a)/exp(b)
tab deflator_studyarea

keep market_id month deflator*
reshape wide deflator*, i(market_id) j(month)

tempfile deflator
save `deflator'


*** Merge with village-market mapping dataset ***
project, original("$dr/Village_NearestMkt_PUBLIC.dta")
use "$dr/Village_NearestMkt_PUBLIC.dta", clear

merge n:1 market_id using `deflator'
keep if _merge == 3
drop _merge

reshape long deflator deflator_studyarea, i(village_code) j(month)
format month %tm

drop market_id
ren month survey_mth

tsset village_code survey_mth


******************
* introduce lags *
******************
forvalues l = 0/33 {
	gen deflator_l`l' = l`l'.deflator
	gen deflator_studyarea_l`l' = l`l'.deflator
}

order deflator_*, last sequential

save "$da/intermediate/pricedeflator.dta", replace
project, creates("$da/intermediate/pricedeflator.dta")
