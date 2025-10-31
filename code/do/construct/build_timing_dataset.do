* Preliminaries
return clear
capture project, doinfo
if (_rc==0 & !mi(r(pname))) global dir `r(pdir)'  // using -project-
else {  // running directly
	if ("${ge_dir}"=="") do `"`c(sysdir_personal)'profile.do"'
	do "${ge_dir}/do/set_environment.do"
}

** defining globals **
project, original("$dir/do/GE_global_setup.do")
include "$dir/do/GE_global_setup.do"


/*** CREATING SURVEY AND TRANSFER TIMING DATASET ***/

*** listing dataset dependencies ***
project, uses("$dt/GE_experimental_timing_wide_FINAL.dta")
project, original("$dr/Transfers_VillageLevel_Temporal_PUBLIC.dta") // consider if this should eventually be constructed


/*** EXTRACT TRANSFER TIMING ***/
*** pull out experimental start

use village_code treat hi_sat exp_start_1 using "$dt/GE_experimental_timing_wide_FINAL.dta", clear

tempfile expstart
save `expstart'

*** pull out transfer dates
use "$dr/Transfers_VillageLevel_Temporal_PUBLIC.dta", clear

merge n:1 village_code using `expstart', keepusing(exp_start_1)

gen tmp_tokenmth = month    if n_token > 0
gen tmp_LS1mth = month      if n_LS1 > 0
gen tmp_LS2mth = month      if n_LS2 > 0

collapse (min) token_start = tmp_tokenmth LS1_start = tmp_LS1mth LS2_start = tmp_LS2mth, by(village_code)

gen transdata = 1

merge n:1 village_code using `expstart', keepusing(exp_start_1)

tempfile trans_start_village
save `trans_start_village'

tostring village_code, gen(vc_str) format(%14.0f)
gen sl_code = substr(vc_str, 1, 9)
destring sl_code, gen(subloc_code)



collapse (min) exp_start_1 token_start LS1_start LS2_start (median) exp_start_SL_med = exp_start_1 token_start_SL_med = token_start LS1_start_SL_med = LS1_start LS2_start_SL_med = LS2_start , by(subloc_code)

tempfile trans_start_SL
save `trans_start_SL'

** generating long version of transaction data
use `trans_start_village', clear

ren token_start calmonth1
ren LS1_start calmonth2
ren LS2_start calmonth3
gen expmonth1 = calmonth1 - exp_start_1
gen expmonth2 = calmonth2 - exp_start_1
gen expmonth3 = calmonth3 - exp_start_1

ren exp_start_1 calmonth0

reshape long calmonth expmonth , i(village_code ) j(transnum)

format calmonth expmonth %tm

tempfile trans_startmth_long
save `trans_startmth_long'

/*** GENERATING HOUSEHOLD CENSUS SURVEY DATE DATA ***/
project, uses("$da/GE_HH-Census_Analysis_HHLevel.dta") preserve // may want to change this to using once fully integrated, depends on pipelines.
use "$da/GE_HH-Census_Analysis_HHLevel.dta", clear

gen census_date = today

ren sublocation_code  subloc_code

// why are these the variables that we are keeping?
keep eligible treat hi_sat census_date village_code subloc_code
gen hhcensus = 1

tempfile hh_census
save `hh_census'

*** baseline household survey data ***
project, uses("$da/GE_HH-Survey-BL_Analysis_AllHHs.dta"	) preserve // see note for census
use "$da/GE_HH-Survey-BL_Analysis_AllHHs.dta", clear

gen baseline_date = svydate_BL
keep s1_hhid_key village_code baseline_date

tempfile hh_baseline
save `hh_baseline'

/*** GENERATING HOUSEHOLD SURVEY DATE DATA ***/
project, uses("$da/GE_HH-Analysis_AllHHs.dta") preserve // see note above
use "$da/GE_HH-Analysis_AllHHs.dta", clear

gen endline_date = today

//gen double subloc_code = real(substr(hhid_key, 1, length(hhid_key) - 7))

keep eligible treat hi_sat endline_date hhid_key village_code
// this was no longer appearing -- satcluster -- not sure why, not clear it's needed, but can think through

format village_code %14.0f
gen hhsurvey = 1

tempfile hh_endline
save `hh_endline'

/*** GENERATING MARKET PRICE DATE DATASET ***/
	project, uses("$da/GE_MarketData_Panel_ECMA.dta") preserve
	use "$da/GE_MarketData_Panel_ECMA.dta", clear

	keep subcounty sublocation market_id month
	gen mkt_date_survey = month

	codebook mkt_date_survey
	format mkt_date_survey %tm
	tab mkt_date_survey

	drop if mkt_date_survey < tm(2014m10)

tab mkt_date_survey
codebook mkt_date_survey
drop if mkt_date_survey > tm(2017m3)

tab sublocation

gen exp_start_mkt = tm(2014m8) if subcounty == 1
replace exp_start_mkt = tm(2015m1) if subcounty == 2
replace exp_start_mkt = tm(2015m3) if subcounty == 3

tempfile mkt_svy_dates
save `mkt_svy_dates'

/*** GENERATING ENTERPRISE census DATE DATASET ***/
project, original("$dr/GE_ENT-Census-EL1_PUBLIC.dta") preserve // see note above
use "$dr/GE_ENT-Census-EL1_PUBLIC.dta", clear

ren cen_date ent_cen_date

keep village_code end_entcode end_ent_key ent_cen_date

tempfile ent_cen_EL
save `ent_cen_EL'

/*** GENERATING ENTERPRISE SURVEY DATE DATASET ***/
project, original("$dr/GE_ENT-Survey-EL1_PUBLIC.dta") preserve // see note above
use "$dr/GE_ENT-Survey-EL1_PUBLIC.dta", clear

keep village_code entcode_EL surveyed end_sur_date
keep if surveyed == 1

tempfile ent_svy_EL
save `ent_svy_EL'

***********************************************
* 						COMBINING DATASETS
***********************************************
use `hh_census'
foreach stub in trans_start_village trans_startmth_long hh_baseline hh_endline mkt_svy_dates ent_svy_EL ent_cen_EL {
	append using ``stub''
}

** merge on experimental start **
merge n:1 village_code using `expstart', gen(_m_expstart) update
// cases that do not merge - market surveys, 2 other observations that will have to look into.


ren exp_start_1 exp_start1

format *_date %tdYY_Mon_DD
la var exp_start1 "Exp. start month"

gen census_mon = mofd(census_date)
la var census_mon "Household & enterprise census"

gen baseline_mon = mofd(baseline_date)
la var baseline_mon "Household & enterprise baseline survey"

gen endline_mon = mofd(endline_date)
la var endline_mon "Household endline survey"

la var token_start "1st GD transfer"

gen firsttransfer_mon = LS1_start
la var firsttransfer_mon "2nd GD transfer"

gen lasttransfer_mon = LS2_start
la var lasttransfer_mon "3rd GD transfer"

gen mkt_mon = mofd(mkt_date_survey)
la var mkt_mon "Market price survey"

gen entcend_mon = mofd(ent_cen_date)
la var entcend_mon "Enterprise endline census"

gen entsend_mon = mofd(end_sur_date)
la var entsend_mon "Enterprise endline survey"

format *_mon %tm

gen exptocensus     = census_mon - exp_start1
gen exptobase       = baseline_mon - exp_start1
gen exptotoken      = token_start - exp_start1
gen exptofirst      = firsttransfer_mon - exp_start1
gen exptolast       = lasttransfer_mon - exp_start1
gen exptoend        = endline_mon - exp_start1
gen exptoentc       = entcend_mon - exp_start1
gen exptoents       = entsend_mon - exp_start1
gen exptomkt        = mkt_mon - exp_start_mkt


** mean endline
gen tokentoend  = endline_mon - token_start
gen basetoend   = endline_mon - baseline_mon
summ exptoend tokentoend basetoend, d

* Labeling variables
la var exptocensus "Household & Enterprise Census"
la var exp_start1 "Experimental start"
la var exptobase "Household & Enterprise baseline survey"
la var exptotoken "1st GD transfer"
la var exptofirst "2nd GD transfer"
la var exptolast "3rd transfer"
la var exptoend "Household endline survey"
//la var exptoll1 "Local leader round 1"
//la var exptoll2 "Local leader round 2"
la var exptoentc "Enterprise endline census"
la var exptoents "Enterprise endline survey"
la var exptomkt "Market price survey"
//la var exptoentp "Enterprise phone survey"


** saving final date dataset **
save "$da/GE_Survey_and_Transfer_Dates.dta", replace
project, creates("$da/GE_Survey_and_Transfer_Dates.dta")
