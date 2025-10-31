/*
 * Filename: ge_hh-welfare_baseline_vars.do
 * Description: This do file constructs the outcomes described in the HH welfare PAP
 *   on assets, consumption (with exception of Ligon analysis) and household income & revenue for baseline data. It was copied in Sep 2017, and then edited to ensure it ran on baseline data. Some outcomes were already created as part of baseline analysis dataset, but renaming to allow for ANCOVA regressions.
 *
 *   This corresponds to primary outcomes 1-4 and sections 5.1 to 5.4 of the household welfare PAP.
 *
 * This version updated to be run as part of construction of local PF outcomes.
 *
 * Authors: Michael Walker
 * Date created: 14 July 2017
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


*** loading data ***
project, uses("$da/intermediate/GE_HH-BL_setup.dta")
use "$da/intermediate/GE_HH-BL_setup.dta", clear

keep *hhid_key s1_q4_respid village_code today eligible key s6_q5* s6_q6* s6_q7* s6_q8* s7_* s8_* s9_*

* bringing in eligible_baseline (do we really need this?) **
project, uses("$da/intermediate/GE_HH-BL_frbasics.dta") preserve
merge 1:1 hhid_key using "$da/intermediate/GE_HH-BL_frbasics.dta", keepusing(eligible*)
drop _merge


** bringing in estimated ag production **
/*
/* note: as these are estimated ag profits, we need to be careful with how we use these. Go back through all of this more carefully -- may not want to bring this into LASSO stuff */
project, original("$dr/Estimated_BL_agprofits_2017-12-04.dta") preserve
merge 1:1 s1_hhid_key using "$dr/Estimated_BL_agprofits_2017-12-04.dta", gen(_mag) keepusing(agprofit_BL totagrevenue_BL)
tab _mag
drop if _mag == 2 // only want observations in master or matched
drop _mag

ren totagrevenue_BL totagrevenue
*/

/*** Land ownership ***/
* some of this already included as part of assets (to confirm)
project, uses("$da/intermediate/GE_HH-BL_assets.dta") preserve
merge 1:1 hhid_key using "$da/intermediate/GE_HH-BL_assets.dta", keepusing(*land*)
drop _merge

gen land_ownland = land_acresowned > 0 if ~mi(land_acresowned)
la var land_ownland "Owns land"

tab s6_q6b_agacresowned, m
recode s6_q6b_agacresowned (99 9999 = .)
gen land_agacresowned = s6_q6b_agacresowned
la var land_agacresowned "Acres used for ag."

* Check: acres owned and used for ag should be less than total acres owned
count if land_agacresowned > land_acresowned & ~mi(land_acresowned) & ~mi(land_agacresowned)

/* For households renting out land */
tab1 s6_q7*
recode s6_q7_rentedland (1=1) (2=0), gen(land_rentedout)
replace land_rentedout = 0 if s6_q7a_acresrented == 0
la var land_rentedout "Rented out land"

recode s6_q7a_acresrented (0 9999 = . ), gen(land_acresrentedout)
la var land_acresrentedout "Acres rented out"

count if land_acresrentedout > land_acresowned & ~mi(land_acresowned) & ~mi(land_acresrentedout)
list village_code s1_q4_respid land_acresowned land_acresrentedout s6_q5* s6_q6* s6_q7* s6_q8* if land_acresrentedout > land_acresowned & ~mi(land_acresowned) & ~mi(land_acresrentedout)

recode s6_q7b_monthsrented (0 = .), gen(land_mthsrentedout)
la var land_mthsrentedout "Months land rented out"

recode s6_q7c_landrent (99 9999 = .)
gen land_rentout = (12 * s6_q7c_landrent) / land_acresrentedout if land_rentedout == 1
la var land_rentout "Annual rental price per acre (KSH), rented out"
tab land_rentout

gen land_rentoutrev = land_mthsrentedout * s6_q7c_landrent // months rented x amount per month
la var land_rentoutrev "Income from renting out land"
tab land_rentoutrev

/* For households renting land */
gen land_acresrented = s6_q8a_acresrenting
la var land_acresrented "Acres rented"

/*
recode land_*owned land_*rented (min/-1 99/max = .) // why would we do this? some chance of these being actual values, though we may want to trim in a more systematic manner
*/

gen land_rent = (12 * s6_q8d_monthlylandrent) / land_acresrented if s6_q8_renting == 1
la var land_rent "Annual rental price per acre (KSH), among renters"

* note that endline variable is on the renting in (not out) side
recode s6_q8b_agacresrenting (10/max = .)
recode s6_q8d_monthlylandrent (99 9999 = .)

gen rent_land_mth_acre = s6_q8d_monthlylandrent / s6_q8b_agacresrenting
wins_top1 rent_land_mth_acre


/************************************/
/*     INCOME & ECONOMIC ACTIVITY   */
/************************************/

* indicator for agriculture
gen agriculture_any=0 if s7_q1_selfag!=.
replace agriculture_any=1 if s7_q1_selfag ==1
label var agriculture_any "Household Performs any Agriculture"
tab agriculture_any, m

/*S7: INDICATOR FOR FARMING*/
gen farm=0 if s7_q1_selfag!=.
replace farm=1 if s7_q2_whatag1==1 | s7_q2_whatag2==1 | s7_q2_whatag3 == 1
label var farm "Household performs agriculture (farming)"
label values farm yesno
tab farm, m


/*S7: INDICATOR FOR FARMING OR AGRICULTURE/LIVESTOCK*/
gen farmlivestock=0 if s7_q1_selfag!=.
replace farmlivestock=1 if s7_q2_whatag1 ==1 | s7_q2_whatag2 ==1 | s7_q2_whatag3 ==1 | s7_q2_whatag1 ==2 | s7_q2_whatag2 ==2 | s7_q2_whatag3 ==2
label var farmlivestock "Household performs agriculture (farming or livestock)"
label values farmlivestock yesno
tab farmlivestock, m

/*S7: INDICATOR FOR SELLS CROPS*/
gen sellcrops=0 if (s7_q2_whatag1 ==1 & s7_q5_soldcrops1==2) | (s7_q2_whatag2 ==1 & s7_q5_soldcrops2 ==2) ///
	| (s7_q2_whatag3 ==1 & s7_q5_soldcrops3 ==2)
replace sellcrops=1 if (s7_q2_whatag1 ==1 & s7_q5_soldcrops1 ==1) | (s7_q2_whatag2 ==1 & s7_q5_soldcrops2 ==1) ///
	| (s7_q2_whatag3 ==1 & s7_q5_soldcrops3 ==1)
label var sellcrops "Among farming households, sells crops"
label values sellcrops yesno
tab sellcrops if farm==1, m

gen sellsag = 0 if agriculture_any == 1
replace sellsag = 1 if s7_q5_soldcrops1 == 1 | s7_q5_soldcrops2 == 1 | s7_q5_soldcrops3 == 1
la var sellsag "Among ag households, sells output"

/* Profits from agriculture */

ren *irrigration* *irrigation*

forval i = 1/3 {
	* all ag sales
	gen agsaleamt`i' = s7_q5a_cropsales`i'
    replace agsaleamt`i' = 0 if s7_q5_soldcrops`i' != 1
    qui su agsaleamt`i', d
    gen agsaleamt`i'_trim = agsaleamt`i' if agsaleamt`i' < r(p99)
	la var agsaleamt`i' "Ag sales, activity `i'"
	la var agsaleamt`i'_trim "Ag sales, activity `i', top 1% trim"

	* all ag spending
    egen agspentamt`i' = rowtotal(s7_q11_outsalpaid`i' s7_q12a_toolsspend`i' s7_q12b_animalmedspend`i' s7_q12c_fertilizerspend`i' s7_q12d_irrigationspend`i' s7_q12e_improvedseedspend`i' s7_q12f_aginsurancespend`i'), m
    su agspentamt`i', d
    replace agspentamt`i' = 0 if s7_q5_soldcrops`i' != 1
    gen agspentamt`i'_trim = agspentamt`i' if agspentamt`i' < r(p99)
	la var agspentamt`i' "Ag spending, activity `i'"
	la var agspentamt`i'_trim "Ag spending, activity `i', top 1\% trim"

	* Crop sales - when whatag == 1
    gen cropsaleamt`i' = s7_q5a_cropsales`i' if s7_q2_whatag`i' == 1
    replace cropsaleamt`i' = 0 if s7_q5_soldcrops`i' != 1 & s7_q2_whatag`i' == 1
    qui su cropsaleamt`i', d
    gen cropsaleamt`i'_trim = cropsaleamt`i' if cropsaleamt`i' < r(p99)
	la var cropsaleamt`i' "Crop sales"
	la var cropsaleamt`i'_trim "Crop sales, top 1% trim"

	* crop spending - when whatag == 1
    egen cropspentamt`i' = rowtotal(s7_q11_outsalpaid`i' s7_q12a_toolsspend`i' s7_q12b_animalmedspend`i' s7_q12c_fertilizerspend`i' s7_q12d_irrigationspend`i' s7_q12e_improvedseedspend`i' s7_q12f_aginsurancespend`i') if s7_q2_whatag`i' == 1, m
	egen cropinputcosts`i' = rowtotal(s7_q12a_toolsspend`i' s7_q12b_animalmedspend`i' s7_q12c_fertilizerspend`i' s7_q12d_irrigationspend`i' s7_q12e_improvedseedspend`i' s7_q12f_aginsurancespend`i') if s7_q2_whatag`i' == 1, m
    su cropspentamt`i', d
    replace cropspentamt`i' = 0 if s7_q5_soldcrops`i' != 1 & s7_q2_whatag`i' == 1
    gen cropspentamt`i'_trim = cropspentamt`i' if cropspentamt`i' < r(p99)
	la var cropspentamt`i' "Crop spending, activity `i'"
	la var cropspentamt`i'_trim "Crop spending, top 1\% trim"

}

egen agsaleamt = rowtotal(agsaleamt?), m
summ agsaleamt, d
gen agsaleamt_trim = agsaleamt if agsaleamt < r(p99)
la var agsaleamt "Among ag households, amt of ag sales"
la var agsaleamt_trim "Among ag households, amt of ag sales, top 1\% trim"

egen cropsaleamt = rowtotal(cropsaleamt?), m
summ cropsaleamt if farm==1, d
gen cropsaleamt_trim = cropsaleamt if cropsaleamt < r(p99)
tab cropsaleamt if farm==1, m
la var cropsaleamt "Among farming households, amount of crop sales"
la var cropsaleamt_trim "Among farming households, amount of crop sales (trimmed)"

egen agspentamt = rowtotal(agspentamt?), m
summ agspentamt, d
gen agspentamt_trim = agspentamt if agspentamt < r(p99)
la var agspentamt "Among ag households, amt of salary & materials spending"
la var agspentamt_trim "Among ag households, amt of salary & materials spending (trimmed)"

egen cropspentamt = rowtotal(cropspentamt?), m
summ cropspentamt if farm==1, d
gen cropspentamt_trim = cropspentamt if cropspentamt < r(p99)
tab cropspentamt if farm==1, m
la var cropspentamt "Among farming hhs, amount of salary & materials on crops"
la var cropspentamt_trim "Among farming hhs, amount of salary & materials on crops (trimmed)"

egen cropinputcosts = rowtotal(cropinputcosts?), m
summ cropinputcosts if farm == 1, d
la var cropinputcosts "Among farming hhs, amount of input materials (non-salary) on crops"

tab1 s6_q8c_monthsrenting s6_q8d_monthlylandrent
gen aglandrentalcost = s6_q8c_monthsrenting * s6_q8d_monthlylandrent
replace aglandrentalcost = 0 if s6_q8_renting == 2
su aglandrentalcost, d
gen aglandrentalcost_trim = aglandrentalcost if aglandrentalcost < r(p99)
la var aglandrentalcost "Ag land rental cost"
la var aglandrentalcost_trim "Ag land rental cost (top1\%trim)"
* note that there is also land income from above. not counting this as ag, but will want to bring into total income measures

/* These are all old versions -- can we remove them? */
/*
gen ag_profit = agsaleamt - agspentamt - aglandrentalcost
replace ag_profit = 0 if s7_q1_selfag == 2
la var ag_profit "Total profit from agriculture and livestock in the last 12 mo. (OLD VERSION)" // we are capturing livestock output sales here, so hopefully reasonable
gen ag_profit_pos = ag_profit if ag_profit > 0
la var ag_profit_pos "Ag profits, conditional on positive profits (OLD VERSION)"

trim_top1 ag_profit ag_profit_pos
summ ag_profit, d
replace ag_profit_trim = . if ag_profit_trim < r(p1)
wins_top1 ag_profit ag_profit_pos
summ ag_profit, d
replace ag_profit_wins = r(p1) if ag_profit_wins < r(p1)

summ ag_profit*
*/

/* other variables related to ag */
/* S7: Total ag non-wage costs */
forval i=1/3 {
	tab1 s7_q12a_toolsspend`i' s7_q12b_animalmedspend`i' s7_q12c_fertilizerspend`i' s7_q12d_irrigationspend`i' s7_q12e_improvedseedspend`i' s7_q12f_aginsurancespend`i'
	foreach var of varlist s7_q12a_toolsspend`i' s7_q12b_animalmedspend`i' s7_q12c_fertilizerspend`i' s7_q12d_irrigationspend`i' s7_q12e_improvedseedspend`i' s7_q12f_aginsurancespend`i' {
		replace `var' = . if `var' == 88 | `var' == 99
	}
}

egen ag_nonwage_spend = rowtotal(s7_q12a_toolsspend? s7_q12b_animalmedspend? s7_q12c_fertilizerspend? s7_q12d_irrigationspend? s7_q12e_improvedseedspend? s7_q12f_aginsurancespend?), missing
la var ag_nonwage_spend "Total ag spending, excl wages"

/* S7: AG WAGE BILL */
tab1 s7_q11_outsalpaid? s7_q11_outsalpaidfx?
replace s7_q11_outsalpaid1 = . if s7_q11_outsalpaid1 == 99
replace s7_q11_outsalpaid2 = . if s7_q11_outsalpaid1 == 99

egen ag_wage_bill = rowtotal(s7_q11_outsalpaid1 s7_q11_outsalpaid2 s7_q11_outsalpaid3), missing
la var ag_wage_bill "Total outside ag wage bill"

gen any_poultry = 0 if ~mi(agriculture_any)
gen any_livestock = 0 if ~mi(agriculture_any)

gen sellamt_poultry = .
gen sellamt_livestock = .

forval i=1/3 {

	replace any_livestock 	 	= 1 if s7_q2_whatag`i' == 2
	replace sellamt_livestock 	= agsaleamt`i' if s7_q2_whatag`i' == 2

	replace any_poultry		 	= 1 if s7_q2_whatag`i' == 3
	replace sellamt_poultry 	= agsaleamt`i' if s7_q2_whatag`i' == 3

}

tab1 farm any_poultry any_livestock if eligible_baseline == 1
summ cropsaleamt sellamt_* if eligible_baseline == 1


/*** ARRANGING BASELINE AG DATA ***/
recode s7_q3_agacres? (99 9999 = .)



* look into further: over 10, and either don't report land ownership or report small amount, but not immediately clear how to correct: 601040502008-022, 601040603008-010,  601040103001-023

gen aglanduse = s7_q3_agacres1
replace aglanduse = s7_q3_agacres2 if mi(aglanduse)
replace aglanduse = s7_q3_agacres3 if mi(aglanduse)


* looping through activities to generate crop-specific measures
gen s7_q6_selfhoursworked_crops = .
gen s7_q7_peopleworked_crops = .
gen s7_q8_hhhoursworked_crops = .
gen s7_q9_outsidepeopleworked_crops = .
gen s7_q10_outsidehoursworked_crops = .



forval i=1/3 {
    replace s7_q6_selfhoursworked_crops = s7_q6_selfhoursworked`i' if s7_q2_whatag`i' == 1
    replace s7_q7_peopleworked_crops = s7_q7_peopleworked`i' if s7_q2_whatag`i' == 1
    replace s7_q8_hhhoursworked_crops   = s7_q8_hhhoursworked`i' if s7_q2_whatag`i' == 1
    replace s7_q9_outsidepeopleworked_crops  = s7_q9_outsidepeopleworked`i' if s7_q2_whatag`i' == 1
    replace s7_q10_outsidehoursworked_crops  = s7_q10_outsidehoursworked`i' if s7_q2_whatag`i' == 1
}

recode s7_q6_selfhoursworked_crops s7_q7_peopleworked_crops s7_q8_hhhoursworked_crops s7_q9_outsidepeopleworked_crops s7_q10_outsidehoursworked_crops (99 = .)

* handling outliers
replace s7_q7_peopleworked_crops = 2 if s1_hhid_key == "601040602014-051" // had reported 20000, but no outside workers, FR and HH report hours
replace s7_q9_outsidepeopleworked_crops = . if inlist(s1_hhid_key, "601050203007-078", "601040201009-090", "601040504011-015") // I don't see a clear way to update/correct these




* q7 should be total number of workers, including FR, hh members, and those outside the household
** part 1: flagging inconsistencies
* step 1: flagging cases with 0 workers, but the FR reports hours - adding in FR
gen flag_ownhrs = s7_q7_peopleworked_crops == 0 & s7_q6_selfhoursworked_crops > 0 & ~mi(s7_q6_selfhoursworked_crops)

* step 2: flagging cases with 0 workers, but household reports hours
gen flag_hhhrs = s7_q7_peopleworked_crops == 0 & s7_q8_hhhoursworked_crops > 0 & ~mi(s7_q8_hhhoursworked_crops)

* step 3: flagging cases where both FR and household (not FR) report hours, but total number of workers is less than 2
gen flag_ownhhhrs = s7_q7_peopleworked_crops < 2 & s7_q6_selfhoursworked_crops > 0 & ~mi(s7_q6_selfhoursworked_crops) & s7_q8_hhhoursworked_crops > 0 & ~mi(s7_q8_hhhoursworked_crops)

* step 4: flagging cases where total number of workers outside the household is more than the total number of workers reported in q8
gen flag_outworkers = s7_q7_peopleworked_crops < s7_q9_outsidepeopleworked_crops & ~mi(s7_q9_outsidepeopleworked_crops)

tab1 flag_ownhrs flag_hhhrs flag_ownhhhrs flag_outworkers

** step 2: addressing flagged inconsistencies **
replace s7_q7_peopleworked_crops = 1 if flag_ownhrs == 1
replace s7_q7_peopleworked_crops = 1 if flag_hhhrs == 1 & flag_ownhrs == 0
replace s7_q7_peopleworked_crops = 2 if flag_hhhrs == 1

* assuming that if outworkers > total workers, outworkers not included in this count at all
replace s7_q7_peopleworked_crops = s7_q7_peopleworked_crops + s7_q9_outsidepeopleworked_crops if flag_outworkers == 1 & ~mi(s7_q9_outsidepeopleworked_crops)

tab s7_q7_peopleworked_crops
* replacing those that remain at zero but with some land, output as missing
replace s7_q7_peopleworked_crops = . if s7_q7_peopleworked_crops == 0

gen numcropworkers = s7_q7_peopleworked_crops

** crops grown **
gen croplist = s7_q4_whatcrops1 if s7_q2_whatag1 == 1
replace croplist = s7_q4_whatcrops2 if s7_q2_whatag2 == 1
replace croplist = s7_q4_whatcrops3 if s7_q2_whatag3 == 1

replace croplist = subinstr(croplist, "other", "77", 1)

split croplist, gen(crop_)

destring crop_? crop_??, replace

tab1 crop_? crop_??

foreach j of numlist 1/25 30 77 {
    gen grewcrop`j' = 0 if ~mi(croplist)

forval i=1/10 {
    replace grewcrop`j' = 1 if crop_`i' == `j'

} // end loop over crops grown responses

} // end loop over crop types


** checking baseline components of estimates
summ cropsaleamt aglanduse numcropworkers

tab1 grewcrop*



/***** SECTION 8: SELF-EMPLOYMENT INCOME ******/


* overall self-employed
gen selfemp = s8_q1_selfemployed
replace selfemp = 0 if selfemp == 2
label var selfemp "Self-employed"
tab selfemp, m
/*note: as similar to KLPS, we may want to define this based on whether earn positive profits...can fix after profits calculated*/


/* Profits from self-employment */

replace s8_q1a_numbusinesses = 0 if s8_q1_selfemployed == 2

forval i = 1/3 {

    gen selfemp_flag`i' = s8_q7b_earningslastyr`i' < s8_q11b_profitlastyr`i'

    gen selfemp_earnings`i' = s8_q7b_earningslastyr`i'
	tab selfemp_earnings`i' if s8_q1a_numbusinesses < `i' // should not be any
    //replace selfemp_earnings`i' = 0 if s8_q1a_numbusinesses < `i' - come back to this
    qui su selfemp_earnings`i', d
    la var selfemp_earnings`i' "Self-emp earnings, ent `i'"

    recode s8_q6b_wagebill`i' s8_q15a_rentamount`i' s8_q16a_elecwater`i' s8_q16b_insurance`i' s8_q16c_interest`i' s8_q16d_goodsresale`i' s8_q16e_inputs`i' s8_q16f_repairs`i' s8_q16g_security`i' s8_q16h_othercosts`i' s8_q17a_healthinsurance`i' s8_q17b_marketfees`i' s8_q17d_countytaxes`i' s8_q17e_nationaltaxes`i' s8_q17f_localtaxes`i' s8_q17g_bribes`i' (min/-1 99 999 9999 = .)

    egen selfemp_costs`i' = rowtotal(s8_q6b_wagebill`i' s8_q15a_rentamount`i' s8_q16a_elecwater`i' s8_q16b_insurance`i' s8_q16c_interest`i' s8_q16d_goodsresale`i' s8_q16e_inputs`i' s8_q16f_repairs`i' s8_q16g_security`i' s8_q16h_othercosts`i' s8_q17a_healthinsurance`i' s8_q17b_marketfees`i' s8_q17d_countytaxes`i' s8_q17e_nationaltaxes`i' s8_q17f_localtaxes`i' s8_q17g_bribes`i'), m

	tab selfemp_costs`i' if s8_q1a_numbusinesses < `i' // should not be any
    //replace selfemp_costs`i' = 0 if s8_q1a_numbusinesses < `i'
    qui su selfemp_costs`i', d
    la var selfemp_costs`i' "Self-emp costs, ent `i'"

	* Reported profits
	count if selfemp_flag`i' == 1
	di "number of flagged earnings < profits, ent `i': `r(N)'"
	list s8_q7b_earningslastyr`i' s8_q11b_profitlastyr`i' if selfemp_flag`i' == 1 // what to do about these?
    gen selfemp_profit`i' = s8_q11b_profitlastyr`i' if selfemp_flag`i' == 0 // should check this without the restriction as well
	* Calculated profits (earnings - costs. Costs in last month, so multiplying by 12)
	gen selfemp_profit`i'_calc = selfemp_earnings`i' - 12*selfemp_costs`i' if selfemp_flag`i' == 0
	* Combined - taking reported, filling with calculated when missing
	gen selfemp_profit`i'_comb = selfemp_profit`i'
	replace selfemp_profit`i'_comb = selfemp_profit`i'_calc if mi(selfemp_profit`i') & selfemp_flag`i' == 0

	la var selfemp_profit`i' "Self-emp profits (report), ent`i'"
	la var selfemp_profit`i'_calc "Self-emp profits (calc), ent`i'"
	la var  selfemp_profit`i'_comb "Self-emp profits (combined), ent`i'"


}
* Total profits
egen selfemp_profit = rowtotal(selfemp_profit?), m
la var selfemp_profit "Total profit from non-ag. business in the last 12 mo."
egen selfemp_profit_calc = rowtotal(selfemp_profit?_calc), m
la var selfemp_profit_calc "Total profit from non-ag buisness in the last 12 mo (calculated)"
char define selfemp_profit_calc[vnote] "Total revenues - total costs"
egen selfemp_profit_comb = rowtotal(selfemp_profit?_comb), m
la var selfemp_profit_comb "Total profit from non-ag business in the last 12 mo (combined)"
char define selfemp_profit_comb[vnote] "Total reported profit, filled in with calculated profits when reported profits missing/DK"

* Total earnings
egen selfemp_earnings = rowtotal(selfemp_earnings?), m
la var selfemp_earnings "Total earnings from non-ag business in the last 12 mo."

egen selfemp_costs = rowtotal(selfemp_costs?), m
la var selfemp_costs "Total costs from non-ag business in the last 12 mo."

* trimming and winsorizing - across ineligible and eligible combined
trim_top1 selfemp_profit selfemp_profit_calc selfemp_profit_comb selfemp_earnings selfemp_costs
wins_top1 selfemp_profit selfemp_profit_calc selfemp_profit_comb selfemp_earnings selfemp_costs



/****************************************/
/* S9: EMPLOYMENT 						*/
/****************************************/

tab s9_q1_employed, m
gen emp = 0 if s9_q1_employed != .
replace emp = 1 if s9_q1_employed == 1
la var emp "Indicator for employed/working for wages"


/* Income from employment in-kind transfers, wages, and salaries */

replace s9_numemployment = 0 if s9_q1_employed == 2

gen svy_mth = mofd(today)

forval i = 1/3 {
	* generating number of months worked - based on start date for full/part time, seasonal based on months worked question
	tab s9_q2_datestart`i'
	tab s9_q6_workpattern`i'
	gen empstartmth`i' = mofd(s9_q2_datestart`i')
	gen emp_monthsworked`i' = svy_mth - empstartmth`i' + 1 if s9_q6_workpattern`i' == "1" | s9_q6_workpattern`i' == "2"
	replace emp_monthsworked`i' = . if emp_monthsworked`i' < 0
	replace emp_monthsworked`i' = 12 if emp_monthsworked`i' > 12 & ~mi(emp_monthsworked`i')
	* for now, assuming that people would have remembered if they started in last year - setting these to 12

	tab s9_q6a_workmonths`i'
    gen seas_emp_monthsworked`i' = wordcount(s9_q6a_workmonths`i')
	replace emp_monthsworked`i' = seas_emp_monthsworked`i' if s9_q6_workpattern`i' == "3"

	tab emp_monthsworked`i' if emp==1, m // will have some missing values after job 1

	la var emp_monthsworked`i' "Number of months worked, job `i'"
	tab emp_monthsworked`i'

	tab1 s9_q9_cashsalary`i' s9_q11a_payinkind`i' s9_q11b_healthinsurance`i' s9_q11c_housing`i' s9_q11d_clothing`i' s9_q11e_training`i' s9_q11f_otherbenefits`i'

    egen emp_income`i' = rowtotal(s9_q9_cashsalary`i' s9_q11a_payinkind`i' s9_q11b_healthinsurance`i' s9_q11c_housing`i' s9_q11d_clothing`i' s9_q11e_training`i' s9_q11f_otherbenefits`i'), m
    replace emp_income`i' = emp_income`i' * emp_monthsworked`i'
    replace emp_income`i' = 0 if s9_numemployment < `i'
    qui su emp_income`i', d
    la var emp_income`i' "Emp income, job `i'"

	* separate variables for certain types of income
	gen emp_cashsal`i' = s9_q9_cashsalary`i' * emp_monthsworked`i'
	qui su emp_cashsal`i', d
	la var emp_cashsal`i' "Emp cash salary, job `i'"

	egen emp_earnings`i' = rowtotal(s9_q9_cashsalary`i' s9_q11a_payinkind`i'), m
	replace emp_earnings`i' = emp_earnings`i' * emp_monthsworked`i'
	qui su emp_earnings`i', d
	la var emp_earnings`i' "Emp earnings (cash+in-kind), job `i'"

	egen emp_benefits`i' = rowtotal(s9_q11b_healthinsurance`i' s9_q11c_housing`i' s9_q11d_clothing`i' s9_q11e_training`i' s9_q11f_otherbenefits`i'), m
	replace emp_benefits`i' = emp_benefits`i' * emp_monthsworked`i'
	la var emp_benefits`i' "Emp benefits, job `i'"
}

egen emp_income = rowtotal(emp_income?), m
la var emp_income "Total value of employment wages & benefits in last 12 months" // I may need to note that this does not collect all past jobs. So if quit and not currently employed, we may be missing this

foreach stem in cashsal earnings benefits {
	egen emp_`stem' = rowtotal(emp_`stem'?), m
}
la var emp_cashsal "Total cash salary, last 12 months"
la var emp_earnings "Total earnings (cash + pay in kind), last 12 months"
la var emp_benefits "Total benefits, last 12 months"

* trimming and winsorizing
trim_top1 emp_income emp_cashsal emp_earnings emp_benefits
wins_top1 emp_income emp_cashsal emp_earnings emp_benefits

* generating indicators
gen emp_hasearnings = emp_earnings > 0 & ~mi(emp_earnings)
la var emp_hasearnings "Earns some wage/salary from jobs"

gen emp_hasincome = emp_income > 0 & ~mi(emp_income)
la var emp_hasincome "Earns some income from jobs"


/* Total household income */
egen total_selfemp_emp_income = rowtotal(selfemp_profit emp_income), m
la var total_selfemp_emp_income "Total non-ag (wage, selfemp) income in last 12 mo."

egen total_nonag_income = rowtotal(selfemp_profit emp_income land_rentoutrev), m
la var total_nonag_income "Total non-ag income in the last 12 mo. (incl land rev)"
egen total_income = rowtotal( selfemp_profit emp_income land_rentoutrev), m // Tk: come back to this: ag_profit
la var total_income "Total income in the last 12 mo."

* trimming and winsorizing
wins_top1 total_selfemp_emp_income total_nonag_income total_income
trim_top1 total_selfemp_emp_income total_nonag_income total_income

* Total revenue
egen total_agselfemprev 			= rowtotal(selfemp_earnings agsaleamt), m
egen total_agselfemprev_wageinc 	= rowtotal(selfemp_earnings agsaleamt emp_income), m

summ total_agselfemprev total_agselfemprev_wageinc


/***** FORMAL TAXES & LICENSES *****/
/* This is from local pf do files. Need to go through and keep just what is needed for household impacts */

* indicator for self-emp enterprise licensed with county
tab1 s8_q8_islicensed?
gen selfemp_islicensed = 0 if selfemp == 1
gen selfemp_islicensed_prim = selfemp_islicensed // indicator for primary
replace selfemp_islicensed = 1 if s8_q8_islicensed1 == 1
replace selfemp_islicensed = 1 if s8_q8_islicensed2 == 1
replace selfemp_islicensed = 1 if s8_q8_islicensed3 == 1
la var selfemp_islicensed_prim "Primary self-emp enterprise licensed w/ county govt"
label var selfemp_islicensed "Self-employment enterprise (any) licensed w/ county gov't"
label values selfemp_islicensed* yesno

tab1 selfemp_islicensed*
count if selfemp_islicensed != selfemp_islicensed_prim // how many are different?

* Is business registered with national govt
tab1 s8_q9_isregistered?
tab1 s8_q10_islimitedco?
forval i=1/3 {
	recode s8_q9_isregistered`i' (1=1) (2=0), gen(selfemp_entreg_`i')
	la var selfemp_entreg_`i' "Indicator for ent name registered with natl govt"
	recode s8_q10_islimitedco`i' (1=1) (2=0), gen(selfemp_entllc_`i')
	la var selfemp_entllc_`i' "Indicator for ent `i' an LLC"
}
egen selfemp_entreg = rowmax(selfemp_entreg_?) // will be 0 if none LLC, 1 if at least one
la var selfemp_entreg "Indicator for having ent name registered with natl govt"
egen selfemp_entllc = rowmax(selfemp_entllc_?) // will be 0 if none LLC, 1 if at least one
la var selfemp_entllc "Indicator for having ent that's LLC"


* Total license payments
tab1 s8_q8a_licenseamount? s8_q8b_licensevalid?

list s8_q8a_licenseamount1 s8_q8b_licensevalid1 if key == "uuid:182b30a3-7f3d-424a-b841-a1f5b459fe9a"
replace s8_q8a_licenseamount1 = 5500 if key == "uuid:182b30a3-7f3d-424a-b841-a1f5b459fe9a"
replace s8_q8b_licensevalid1 = 12 if key == "uuid:182b30a3-7f3d-424a-b841-a1f5b459fe9a"

replace s8_q8a_licenseamount1 = . if s8_q8a_licenseamount1 == 99

gen selfemp_licamt_1 = s8_q8a_licenseamount1
gen selfemp_licamt_1_ann = s8_q8a_licenseamount1 * (12 / s8_q8b_licensevalid1) if selfemp_islicensed == 1
la var selfemp_licamt_1 "Amount of county license for those licensed (total)"
la var selfemp_licamt_1_ann "Amount of county license for those licensed w/ county (annual)"
tab1 selfemp_licamt_1 selfemp_licamt_1_ann s8_q8a_licenseamount1 s8_q8b_licensevalid1

gen selfemp_licamt_2 = s8_q8a_licenseamount2
gen selfemp_licamt_2_ann = s8_q8a_licenseamount2 * (12 / s8_q8b_licensevalid2) if selfemp_islicensed == 1
label var selfemp_licamt_2 "Amount of county license for 2nd enterprise for those licensed w/ county (total)"
label var selfemp_licamt_2_ann "Amount of county license for 2nd enterprise for those licensed w/ county (annual)"
tab1 selfemp_licamt_2 selfemp_licamt_2_ann s8_q8a_licenseamount2 s8_q8b_licensevalid2

gen selfemp_licamt_3 = s8_q8a_licenseamount3
gen selfemp_licamt_3_ann = s8_q8a_licenseamount3 * (12 / s8_q8b_licensevalid3) if selfemp_islicensed == 1
label var selfemp_licamt_3 "Amount of county license for 3rd enterprise for those licensed w/ county (total)"
label var selfemp_licamt_3_ann "Amount of county license for 3rd enterprise for those licensed w/ county (annual)"
tab1 selfemp_licamt_3 selfemp_licamt_3_ann s8_q8a_licenseamount3 s8_q8b_licensevalid3

egen selfemp_licamt_ann_pos = rowtotal(selfemp_licamt_?_ann), missing // should be conditional on being licensed
replace selfemp_licamt_ann_pos = . if selfemp_licamt_ann_pos == 0
la var selfemp_licamt_ann_pos "Total county license amount (annual), cond $>0$"

gen selfemp_licamt_ann_emp = selfemp_licamt_ann_pos
replace selfemp_licamt_ann_emp = 0 if selfemp == 1 & selfemp_islicensed == 0
la var selfemp_licamt_ann_emp "Total county license amount (annual) for those in selfemp"
tab selfemp_licamt_ann_emp if selfemp == 1, m
summ selfemp_licamt_ann_emp

egen selfemp_licamt_ann_all = rowtotal(selfemp_licamt_?_ann) // no , m - we want zeros for HHs with no license fees. Make sure there are no folks getting caught up in this that should not be. Any with missing self-emp variable?
la var selfemp_licamt_ann_all "Annual cty license amount (all)"

gen selfemp_licamt_mth_emp = selfemp_licamt_ann_emp / 12
la var selfemp_licamt_mth_emp "Monthly cty license amount (coverted from annual), among selfemp"

gen selfemp_licamt_mth_all = selfemp_licamt_ann_all / 12
la var selfemp_licamt_mth_all "Monthly cty license amount (coverted from annual), all hhs"

* winsorizing and trimming
wins_top1 selfemp_licamt_ann_emp selfemp_licamt_ann_pos selfemp_licamt_ann_all selfemp_licamt_mth_emp
trim_top1 selfemp_licamt_ann_emp selfemp_licamt_ann_pos selfemp_licamt_ann_all selfemp_licamt_mth_emp


* generating indicators (payment > 0, not just license)
gen any_selfemp_licamt_emp	= selfemp_licamt_ann_all > 0 if selfemp == 1 & ~mi(selfemp_licamt_ann_all)
gen any_selfemp_licamt_all 	= selfemp_licamt_ann_all > 0 if ~mi(selfemp_licamt_ann_all)
la var any_selfemp_licamt_emp "Any license payments, among selfemp"
la var any_selfemp_licamt_emp "Any license payments, all hhs"

/* MARKET FEES */
* Create 3 versions of this variable for analysis: i) _emp - no missing values those in selfemp ii) _pos: only positive values iii) _all, filling in zeros for households with no payments, outside of self employment

* Monthly values
tab1 s8_q17b_marketfees?
egen selfemp_mktfees_mth_emp = rowtotal(s8_q17b_marketfees?), m
la var selfemp_mktfees_mth_emp "Total market fees (last mth), those in selfemp"

gen selfemp_mktfees_mth_pos = selfemp_mktfees_mth_emp
replace selfemp_mktfees_mth_pos	= . if selfemp_mktfees_mth_emp == 0
la var selfemp_mktfees_mth_pos "Total market fees (last mth), cond $>0$"

gen selfemp_mktfees_mth_all 	= selfemp_mktfees_mth_emp
replace selfemp_mktfees_mth_all = 0 if selfemp == 0
la var selfemp_mktfees_mth_all "Total market fees (last mth), all hhs"

* Annual values
forval i=1/3 {
	gen selfemp_mktfees_`i'_ann = s8_q17b_marketfees`i'*12
}
egen selfemp_mktfees_ann_emp = rowtotal(selfemp_mktfees_?_ann), missing
replace selfemp_mktfees_ann_emp = 0 if selfemp == 0 & selfemp_mktfees_ann_emp == . // any obs here?
la var selfemp_mktfees_ann_emp "Total market fees (annual), those in selfemp"
tab selfemp_mktfees_ann_emp if selfemp == 1, m // should not have any missing

gen selfemp_mktfees_ann_pos = selfemp_mktfees_ann_emp
replace selfemp_mktfees_ann_pos = . if selfemp_mktfees_ann_pos == 0
la var selfemp_mktfees_ann_pos "Total market fees (annual), cond $>0$"


gen selfemp_mktfees_ann_all = selfemp_mktfees_ann_emp
replace selfemp_mktfees_ann_all = 0 if selfemp == 0
count if selfemp_mktfees_ann_all == . // should be none
la var selfemp_mktfees_ann_all "Total market fees (annual), all hhs"

* winsorizing and trimming
wins_top1 selfemp_mktfees_mth_emp selfemp_mktfees_mth_pos selfemp_mktfees_mth_all selfemp_mktfees_ann_emp selfemp_mktfees_ann_pos selfemp_mktfees_ann_all

trim_top1 selfemp_mktfees_mth_emp selfemp_mktfees_mth_pos selfemp_mktfees_mth_all selfemp_mktfees_ann_emp selfemp_mktfees_ann_pos selfemp_mktfees_ann_all


* generating indicators
gen any_selfemp_mktfees_emp 	= selfemp_mktfees_ann_all > 0 if selfemp == 1 & ~mi(selfemp_mktfees_ann_all)
gen any_selfemp_mktfees_all 	= selfemp_mktfees_ann_all > 0 if ~mi(selfemp_mktfees_ann_all)
la var any_selfemp_mktfees_emp "Any market fees, among selfemp"
la var any_selfemp_mktfees_all "Any market fees, all hhs"

/* Self-emp county taxes */
* generating monthly and annual amounts, broken down by those in self-employment, those with positive values and all hhs

tab1 s8_q17d_countytaxes? // what's going on with the 8 here?

* Monthly values
egen selfemp_ctytaxoth_mth_emp 		= rowtotal(s8_q17d_countytaxes?), m
replace selfemp_ctytaxoth_mth_emp 	= 0 	if selfemp == 1 & selfemp_ctytaxoth_mth_emp == . // I don't think any should be replaced here - check
la var selfemp_ctytaxoth_mth_emp "Total other county selfemp taxes, among selfemp"

gen selfemp_ctytaxoth_mth_pos		 = selfemp_ctytaxoth_mth_emp
replace selfemp_ctytaxoth_mth_pos	 = . 	if selfemp_ctytaxoth_mth_pos == 0
la var selfemp_ctytaxoth_mth_pos "Total other county selfemp taxes, cond $>0$"

gen selfemp_ctytaxoth_mth_all = selfemp_ctytaxoth_mth_emp
replace selfemp_ctytaxoth_mth_all = 0 if selfemp == 0
la var selfemp_ctytaxoth_mth_all "total other county selfemp taxes, all hhs"

* Annual values
forval i=1/3 {
	gen selfemp_ctytaxoth_`i'_ann = s8_q17d_countytaxes`i' * 12
}
egen selfemp_ctytaxoth_ann_emp = rowtotal(selfemp_ctytaxoth_?_ann), missing
la var selfemp_ctytaxoth_ann_emp "Total other county selfemp taxes (annual), among selfemp"
tab selfemp_ctytaxoth_ann_emp if selfemp == 1, m // should be no missing. If there are missing values, then need to replace as zero

gen selfemp_ctytaxoth_ann_pos 		= selfemp_ctytaxoth_ann_emp
replace selfemp_ctytaxoth_ann_pos 	= . 	if selfemp_ctytaxoth_ann_pos == 0
la var selfemp_ctytaxoth_ann_pos "Total other county selfemp taxes (annual), cond $>0$"

gen selfemp_ctytaxoth_ann_all = selfemp_ctytaxoth_ann_emp
replace selfemp_ctytaxoth_ann_all = 0 if selfemp == 0
la var selfemp_ctytaxoth_ann_all "Total selfemp other county taxes (annual), all hhs"

* winsorizing and trimming
wins_top1 selfemp_ctytaxoth_mth_??? selfemp_ctytaxoth_ann_???
trim_top1 selfemp_ctytaxoth_mth_??? selfemp_ctytaxoth_ann_???

* generating indicators
gen any_selfemp_ctytaxoth_emp = selfemp_ctytaxoth_ann_all > 0 if selfemp == 1 & ~mi(selfemp_ctytaxoth_ann_all)
gen any_selfemp_ctytaxoth_all = selfemp_ctytaxoth_ann_all >0 & ~mi(selfemp_ctytaxoth_ann_all)
la var any_selfemp_ctytaxoth_emp	"Any other county selfemp taxes, among selfemp"
la var any_selfemp_ctytaxoth_all 	"Any other county selfemp taxes, all hhs"


/** self-emp national taxes **/
tab1 s8_q17e_nationaltaxes?

* Monthly values
egen selfemp_natl_taxes_mth_emp = rowtotal(s8_q17e_nationaltaxes?), m
la var selfemp_natl_taxes_mth_emp "Total national selfemp taxes (last mth), among selfemp"
tab selfemp_natl_taxes_mth_emp if selfemp == 1 // should be no missing values

gen selfemp_natl_taxes_mth_pos 		= selfemp_natl_taxes_mth_emp
replace selfemp_natl_taxes_mth_pos	= . 	if selfemp_natl_taxes_mth_pos == 0
la var selfemp_natl_taxes_mth_pos "Total national selfemp taxes (last mth), among selfemp, cond $>0$"

gen selfemp_natl_taxes_mth_all 		= selfemp_natl_taxes_mth_emp
replace selfemp_natl_taxes_mth_all	= 0 if selfemp == 0
la var selfemp_natl_taxes_mth_all "Total national selfemp taxes (last mth), all hhs"

* Annual values
forval i=1/3 {
	gen selfemp_natl_taxes_`i'_ann = s8_q17e_nationaltaxes`i' * 12
}
egen selfemp_natl_taxes_ann_emp = rowtotal(selfemp_natl_taxes_?_ann), missing
la var selfemp_natl_taxes_ann_emp "Total selfemp national taxes (annual), among those in selfemp"
tab selfemp_natl_taxes_ann_emp if selfemp == 1, m

gen selfemp_natl_taxes_ann_pos		 = selfemp_natl_taxes_ann_emp
replace selfemp_natl_taxes_ann_pos	 = . if selfemp_natl_taxes_ann_pos == 0
la var selfemp_natl_taxes_ann_pos "Total national selfemp taxes (annual), cond $>0$"

gen selfemp_natl_taxes_ann_all = selfemp_natl_taxes_ann_emp
replace selfemp_natl_taxes_ann_all = 0 if selfemp == 0
la var selfemp_natl_taxes_ann_all "Total selfemp national taxes (annual), all hhs"

** winsorizing and trimming variables
wins_top1 selfemp_natl_taxes_mth_??? selfemp_natl_taxes_ann_???
trim_top1 selfemp_natl_taxes_mth_??? selfemp_natl_taxes_ann_???

** indicators
gen any_selfemp_natltax_emp = selfemp_natl_taxes_ann_all > 0 if selfemp == 1 & ~mi(selfemp_natl_taxes_ann_all)
la var any_selfemp_natltax_emp "Any natl selfemp taxes, among those in selfemp"

gen any_selfemp_natltax_all = selfemp_natl_taxes_ann_all > 0 if ~mi(selfemp_natl_taxes_ann_all)
la var any_selfemp_natltax_all "Any natl selfemp taxes, all hhs"



/* Employees: income taxes (national) */

/*** AMT PAID IN INCOME TAX ***/
tab1 s9_q10_incometax?
gen emp_income_tax_prim = s9_q10_incometax1
label var emp_income_tax_prim "Income tax paid by those in employment, primary job, last mth"

* Monthly income tax
egen emp_income_tax_mth_emp = rowtotal(s9_q10_incometax?), missing
replace emp_income_tax_mth_emp = 0 if emp == 1 & emp_income_tax_mth_emp == . // any replacements here?
la var emp_income_tax_mth_emp "Employment income tax (last mth), among employed"

gen emp_income_tax_mth_pos = emp_income_tax_mth_emp
replace emp_income_tax_mth_pos = . if emp_income_tax_mth_emp == 0
la var emp_income_tax_mth_pos "Employment income tax (last mth), cond $>0$"

gen emp_income_tax_mth_all 	= emp_income_tax_mth_emp
replace emp_income_tax_mth_all = 0 if emp == 0
count if emp_income_tax_mth_all == . // shouldn't be any (or if some, very few from income tax DKs)
la var emp_income_tax_mth_all "Employment income tax (last mth), all hhs"

* Annual income tax
* looping through jobs
forval i=1/3 {
	replace s9_q10_incometax`i' = . if s9_q10_incometax`i' == s9_q9_cashsalary`i' & s9_q10_incometax`i' != 0

	gen emp_income_tax_`i'_ann = s9_q10_incometax`i' * 12 // see above for tax scale - this is annualizing from last month if tax scale = 12
	la var emp_income_tax_`i'_ann "Income tax paid (annual), job `i'"
}

egen emp_income_tax_ann_emp = rowtotal(emp_income_tax_?_ann), missing // this should be conditional on having employment job
la var emp_income_tax_ann_emp "Total income tax (annual), among employed"
tab emp_income_tax_ann_emp if emp == 1, m // should not be any missing

gen emp_income_tax_ann_pos = emp_income_tax_ann_emp
replace emp_income_tax_ann_pos = . if emp_income_tax_ann_emp == 0
la var emp_income_tax_ann_pos "Total income tax (annual), cond $>0$"

gen emp_income_tax_ann_all = emp_income_tax_ann_emp
replace emp_income_tax_ann_all = 0 if emp == 0 // unconditional, as this may still be of interest, but constructing this way drops any that were missing as part of being employed
la var emp_income_tax_ann_emp "Total income tax (annual), all hhs"
tab emp_income_tax_ann_all

* winsorizing and trimming
wins_top1 emp_income_tax_mth_??? emp_income_tax_ann_???
trim_top1 emp_income_tax_mth_??? emp_income_tax_ann_???

* generating indicators
gen any_income_tax_emp =  (emp_income_tax_ann_emp > 0) if emp == 1 & ~mi(emp_income_tax_ann_emp)
la var any_income_tax_emp "Any income tax paid, conditional on being employed"

gen any_income_tax = (emp_income_tax_ann_all > 0) if ~mi(emp_income_tax_ann_emp)
tab any_income_tax
la var any_income_tax "Indicator for paid any income tax, all hhs"

/*********************************/
/*   FAMILY 3: income & profits  */
/*********************************/

** using estimates based on Nick Li's do file here in order to get at actual crop production

/*
gen p3_1_agprofit = agprofit_BL
la var p3_1_agprofit "P3.1: Total profits from ag. and livestock in the last 12 months"

wins_top1 p3_1_agprofit
summ p3_1_agprofit_wins
trim_top1 p3_1_agprofit
summ p3_1_agprofit_trim
*/

gen p3_2_nonagprofit = selfemp_profit
replace p3_2_nonagprofit = 0 if selfemp == 0
la var p3_2_nonagprofit "P3.2: Total profits from non-ag. business in the last 12 months"

wins_top1 p3_2_nonagprofit
summ p3_2_nonagprofit_wins
trim_top1 p3_2_nonagprofit
summ p3_2_nonagprofit_trim


*** TOTAL AFTER-TAX VALUE OF WAGES, SALARIES AND IN-KIND TRANFERS EARNED LAST 12 MONTHS ***

desc emp_earnings emp_income emp_income_tax_ann_emp
summ emp_earnings emp_income emp_income_tax_ann_emp

gen yrlyincometax = emp_income_tax_ann_emp
gen yrlyincometax_neg = - yrlyincometax

egen netearnings_emp = rowtotal(emp_income yrlyincometax_neg), m
summ netearnings_emp

gen netearnings_all = netearnings_emp
replace netearnings_all = 0 if emp == 0
gen p3_3_wageearnings = netearnings_all
la var p3_3_wageearnings "P3.3: Total after-tax wage earnings in the last 12 months"

wins_top1 p3_3_wageearnings
summ p3_3_wageearnings_wins
trim_top1 p3_3_wageearnings
summ p3_3_wageearnings_trim

*** HOURLY WAGE RATE FOR THOSE EMPLOYED/WORKING FOR WAGES ***
* this should be created on an individual-level dataset. is there anything else we want on that level?

*** SUMMARY MEASURE: TOTAL HOUSEHOLD INCOME IN THE LAST 12 MONTHS ***

egen p3_totincome = rowtotal( p3_2_nonagprofit p3_3_wageearnings), m // tk: taking out for a minute: p3_1_agprofit
la var p3_totincome "P3: Total household income (selfemp + emp) in the last 12 months"
summ p3_totincome

wins_top1 p3_totincome
summ p3_totincome_wins
trim_top1 p3_totincome
summ p3_totincome_trim

** total profit **
egen  totprofit = rowtotal(p3_2_nonagprofit), m //TK: removing for now: p3_1_agprofit
wins_top1 totprofit


/*********************************/
/*   FAMILY 4: business revenue  */
/*********************************/

*** TOTAL REVENUE FROM AGRICULTURE AND LIVESTOCK IN THE LAST 12 MONTHS ***
/*
gen p4_1_agrevenue = totagrevenue
la var p4_1_agrevenue "P4.1: Total revenue from ag. and livestock in the last 12 months"

wins_top1 p4_1_agrevenue
summ p4_1_agrevenue_wins
trim_top1 p4_1_agrevenue
summ p4_1_agrevenue_trim
*/

*** TOTAL REVENUE FROM NON-AG. BUSINESS IN THE LAST 12 MONTHS ***
//It says sum of variables 8.8b but I believe it is 8.7b

gen p4_2_nonagrevenue = selfemp_earnings
replace p4_2_nonagrevenue = 0 if selfemp == 0
la var p4_2_nonagrevenue "P4.2: Total revenue from non-ag. business in the last 12 months"

wins_top1 p4_2_nonagrevenue
summ p4_2_nonagrevenue_wins
trim_top1 p4_2_nonagrevenue
summ p4_2_nonagrevenue_trim

*** NON-AG. BUSINESS OWNED BY HOUSEHOLD ***
gen p4_3_selfemployed = selfemp
la var p4_3_selfemployed "P4.3: Non-ag. business owned by household"
summ p4_3_selfemployed


*** TOTAL COSTS IN AGRICULTURE AND LIVESTOCK IN THE LAST 12 MONTHS ***

gen p4_5_agcosts = agspentamt
la var p4_5_agcosts "P4.5: Total costs in agriculture and livestock in the last 12 months"
summ p4_5_agcosts

wins_top1 p4_5_agcosts
summ p4_5_agcosts_wins
trim_top1 p4_5_agcosts
summ p4_5_agcosts_trim

*** TOTAL COSTS IN NON-AG. BUSINESS IN THE LAST 12 MONTHS ***

egen totnonagcosts_selfemp = rowtotal(selfemp_costs selfemp_licamt_ann_emp), m
summ totnonagcosts_selfemp

gen totnonagcosts_all = totnonagcosts_selfemp
replace totnonagcosts_all = 0 if selfemp == 0

gen p4_6_nonagcosts = totnonagcosts_all
la var p4_6_nonagcosts "P4.6: Total costs in non-ag. business in the last 12 months"
summ p4_6_nonagcosts

wins_top1 p4_6_nonagcosts
summ p4_6_nonagcosts_wins
trim_top1 p4_6_nonagcosts
summ p4_6_nonagcosts_trim

*** 4.4 TOTAL COSTS IN THE LAST 12 MONTHS ***

egen totcosts = rowtotal(agspentamt  totnonagcosts_all), m
summ totcosts

gen p4_4_totcosts = totcosts
la var p4_4_totcosts "P4.4: Total costs in the last 12 months"
summ p4_4_totcosts

wins_top1 p4_4_totcosts
summ p4_4_totcosts_wins
trim_top1 p4_4_totcosts
summ p4_4_totcosts_trim


*** SUMMARY MEASURE: TOTAL HOUSEHOLD BUSINESS REVENUE IN THE LAST 12 MONTHS ***

egen p4_totrevenue = rowtotal( p4_2_nonagrevenue), m // TK: removing for now: p4_1_agrevenue
la var p4_totrevenue "P4: Total business revenue in the last 12 months"

wins_top1 p4_totrevenue
summ p4_totrevenue_wins
trim_top1 p4_totrevenue
summ p4_totrevenue_trim


*** GENERATING PPP VALUES ***
foreach var of varlist p3_totincome* /*p3_1_agprofit**/  p3_2_nonagprofit* p3_3_wageearnings* p4_totrevenue* /*p4_1_agrevenue* */ p4_2_nonagrevenue* p4_4_totcosts* p4_5_agcosts* p4_6_nonagcosts* totprofit* {
    loc vl : var label `var'
    gen `var'_PPP = `var' * $ppprate
    la var `var'_PPP "`vl' (PPP)"
}

** saving **
drop  s6_q5* s6_q6* s6_q7* s6_q8* s7_* s8_* s9_*
cap drop _merge
save "$da/intermediate/GE_HH-BL_income_revenue.dta", replace
project, creates("$da/intermediate/GE_HH-BL_income_revenue.dta")
