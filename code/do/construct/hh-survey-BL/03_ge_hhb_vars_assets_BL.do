/*
 * Filename: ge_hh-welfare_assets_BL.do
 * Description: This do file constructs outcomes on assets to match those at endline defined in the household impacts PAP. It builds on ge_hhb_vars_assets_income.do, but restricts attention to only those outcomes that we included as part of the PAP.
 *
 * Author: Michael Walker
 * Last modified: 29 Sep 2018, adapting from ge_hhb_outcomes_assets_income.do
 *
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

 keep *hhid_key today village_code eligible s1_q1b_ipaid s6_* s10_*


/********************************************/
/* SECTION 6: HOUSING MATERIALS AND ASSETS  */
/********************************************/



/** SETTING UP S6 ASSETS - REPLACING DK / REFUSE VALUES **/
* IS THERE ANY WAY I CAN FURTHER STREAMLINE THIS?

/** Moveable Assets **/
local asset_quantities "s6_q13a_bicycle s6_q13b_motorcycle s6_q13c_car s6_q13d_kerosene s6_q13e_radio s6_q13f_sewing s6_q13g_kerosenelantern s6_q13h_bed s6_q13i_mattress s6_q13j_bednet s6_q13k_table s6_q13l_sofa s6_q13m_chair s6_q13n_cupboards s6_q13o_clock_watch s6_q13p_eleciron s6_q13q_television s6_q13r_computer s6_q13s_mobile s6_q13t_carbattery s6_q13u_boat s6_q13v_metalsheets s6_q13w_farmtools s6_q13x_handcart s6_q13y_wheelbarrow s6_q13z_oxplow s6_q13aa_cattle s6_q13bb_goat s6_q13cc_sheep s6_q13dd_chicken s6_q13ee_othbird s6_q13ff_pig s6_q13gg_solar s6_q13hh_generator"
local assets ""
foreach var of local asset_quantities {
	local shorten = substr("`var'", 8,.)
	local und_loc = strpos("`shorten'", "_")
	local short=substr("`shorten'",`und_loc'+1,.)
	local assets "`assets' `short'"
}

di "`assets'"

foreach asset of local asset_quantities {
	tab `asset', m
	replace `asset' = . if `asset' == 99 | `asset' == 88
	replace `asset'value = . if `asset'value == 99 | `asset'value == 88 | `asset'value == 999 | `asset'value == 98 /*for now, setting DK as missing - can decide to handle this differently later if desired*/
	replace `asset'value = 0 if `asset' == 0
	tab `asset'value, m

	* Generating unit values of assets
	gen `asset'_unitval = `asset'value / `asset'
	di "`asset'"
	tab `asset'_unitval, m

	* Imputing missing asset values based on number of assets x unit value, by eligibility status
	gen `asset'valueimp = `asset'value
	summ `asset'_unitval if eligible == 1
	replace `asset'valueimp = `asset' * r(mean) if `asset'valueimp == . & eligible == 1
	summ `asset'_unitval if eligible == 0
	replace `asset'valueimp = `asset' * r(mean) if `asset'valueimp == . & eligible == 0
}

egen assetvalue_missing = rowmiss(s6_q13*value)
egen assetvalue_imp_miss = rowmiss(s6_q13*valueimp)
tab s1_q1b_ipaid assetvalue_missing /*pretty good*/




/*** P1.1 TOTAL VALUE OF LIVESTOCK ***/
tab1 s6_q13aa_cattlevalue s6_q13bb_goatvalue s6_q13cc_sheepvalue s6_q13dd_chickenvalue s6_q13ee_othbirdvalue s6_q13ff_pigvalue


summ s6_q13aa_cattlevalue s6_q13bb_goatvalue s6_q13cc_sheepvalue s6_q13dd_chickenvalue s6_q13ee_othbirdvalue s6_q13ff_pigvalue

egen h1_1_livestock = rowtotal(s6_q13aa_cattlevalue s6_q13bb_goatvalue s6_q13cc_sheepvalue s6_q13dd_chickenvalue s6_q13ee_othbirdvalue s6_q13ff_pigvalue), m
la var h1_1_livestock "P1.1: Total value of livestock"

wins_top1 h1_1_livestock
summ h1_1_livestock_wins
trim_top1 h1_1_livestock
summ h1_1_livestock_trim

/*** 1.2 TOTAL VALUE OF AGRICULTURAL TOOLS ***/
tab1 s6_q13w_farmtoolsvalue s6_q13x_handcartvalue s6_q13y_wheelbarrowvalue s6_q13z_oxplowvalue

summ s6_q13w_farmtoolsvalue s6_q13x_handcartvalue s6_q13y_wheelbarrowvalue s6_q13z_oxplowvalue
egen h1_2_agtools = rowtotal(s6_q13w_farmtoolsvalue s6_q13x_handcartvalue s6_q13y_wheelbarrowvalue s6_q13z_oxplowvalue), m

la var h1_2_agtools "P1.2: Total value of agricultural tools"

wins_top1 h1_2_agtools
summ h1_2_agtools_wins
trim_top1 h1_2_agtools
summ h1_2_agtools_trim


/*** P1.3 TOTAL VALUE OF FURNITURE ***/
tab1 s6_q13h_bedvalue s6_q13i_mattressvalue s6_q13j_bednetvalue s6_q13k_tablevalue s6_q13l_sofavalue s6_q13m_chairvalue s6_q13n_cupboardsvalue s6_q13o_clock_watchvalue

summ s6_q13h_bedvalue s6_q13i_mattressvalue s6_q13j_bednetvalue s6_q13k_tablevalue s6_q13l_sofavalue s6_q13m_chairvalue s6_q13n_cupboardsvalue s6_q13o_clock_watchvalue

egen h1_3_furniture = rowtotal(s6_q13h_bedvalue s6_q13i_mattressvalue s6_q13j_bednetvalue s6_q13k_tablevalue s6_q13l_sofavalue s6_q13m_chairvalue s6_q13n_cupboardsvalue s6_q13o_clock_watchvalue), m
summ h1_3_furniture

la var h1_3_furniture "P1.3: Total value of furniture"

wins_top1 h1_3_furniture
summ h1_3_furniture_wins
trim_top1 h1_3_furniture
summ h1_3_furniture_trim

/*** 1.4 TOTAL VALUE OF RADIO/CASSETTE PLAYER/CD PLAYER OR TVs ***/
summ s6_q13e_radiovalue s6_q13q_televisionvalue

egen h1_4_radiotv = rowtotal(s6_q13e_radiovalue s6_q13q_televisionvalue), m
summ h1_4_radiotv

la var h1_4_radiotv "P1.4: Total value of radio/cassete and CD players/tv"

wins_top1 h1_4_radiotv
summ h1_4_radiotv_wins
trim_top1 h1_4_radiotv
summ h1_4_radiotv_trim

/*** 1.5 HOUSE HAS NON-MUD FLOOR ***/
tab s6_q0a_floor

* bringing in previously-calculated eligibility info
project, uses("$da/intermediate/GE_HH-BL_frbasics.dta") preserve
merge 1:1 hhid_key using "$da/intermediate/GE_HH-BL_frbasics.dta", keepusing(*_elig)

gen nonmudfloor = (floor_elig==0) if ~mi(floor_elig)

gen h1_5_nonmudfloor = nonmudfloor
la var h1_5_nonmudfloor "P1.5: House has non-mud floor"
tab h1_5_nonmudfloor

/*** 1.6 HOUSE HAS NON-THATCHED ROOF ***/
tab s6_q0b_roof
gen h1_6_nonthatchedroof = (roof_elig == 0) if ~mi(roof_elig)
la var h1_6_nonthatchedroof "P1.6: House has non-thatched roof"
tab h1_6_nonthatchedroof

// same as above

/*** 1.7 HOUSE HAS NON-MUD WALLS ***/

gen h1_7_nonmudwalls = (walls_elig == 0) if ~mi(walls_elig)
la var h1_7_nonmudwalls "P1.7: House has non-mud walls"
tab h1_7_nonmudwalls

// same as above

/*** 1.8 HOUSE HAS ELECTRICITY ***/
tab s6_q1_haselectricity
gen elec = s6_q1_haselectricity
recode elec 2 = 0

gen h1_8_electricity = elec
la var h1_8_electricity "P1.8: House has electricity"
tab h1_8_electricity

*** HOUSE PRIMARILY USES AN IMPROVED  ***
gen improvedtoilet = .
replace improvedtoilet = 1 if s6_q2_toilettype == 3 | s6_q2_toilettype == 5
replace improvedtoilet = 0 if s6_q2_toilettype == 1 | s6_q2_toilettype == 2 | s6_q2_toilettype == 4

gen h1_9_toilet = improvedtoilet
la var h1_9_toilet "P1.9: House primarily uses an improved toilet"
tab h1_9_toilet
drop improvedtoilet

/*** 1.10 COST OF MATERIALS AMD LABOR TO BUILD HOUSE ***/
gen ownshome = s6_q5_homestatus == 1 if ~mi(s6_q5_homestatus)
la var ownshome "Indicator for owning home"
tab ownshome // since following value is conditional, will want to know this

tab s6_q5a_homevalue
recode s6_q5a_homevalue (9999 = .)
gen h1_10_housevalue = s6_q5a_homevalue
la var h1_10_housevalue "P1.10: Cost of materials and labor to build house"
summ h1_10_housevalue
note h1_10_housevalue:  "Conditional on owning own home"

wins_top1 h1_10_housevalue
summ h1_10_housevalue_wins
trim_top1 h1_10_housevalue
summ h1_10_housevalue_trim

/*** TOTAL VALUE OF LAND OWNED BY HOUSEHOLD ***/
tab1 s6_q6_acresowned s6_q6a_acresvalue s6_q6a_acresvaluefx 
recode s6_q6_acresowned -99 = .
recode s6_q6a_acresvalue -99 = .
//gen a new variable for s6_q6a_acresvalue that includes only reports in KSH
list s1_hhid_key s6_q6_acresowned s6_q6a_acresvalue if s6_q6_acresowned > 100 & ~mi(s6_q6_acresowned)


tab s6_q6a_acresvalue
recode s6_q6a_acresvalue (min/-1 99 999 9999 99999 = .), gen(land_price)
la var land_price "Price per acre (KSH)"
wins_top1 land_price

tab s6_q6_acresowned, m
recode s6_q6_acresowned (88 99 9999 = .) // is this the best way to handle? I think so, but could also classify DK amount as meaning that you do own some land, which means we'd want to switch indicator
gen land_acresowned = s6_q6_acresowned
la var land_acresowned "Acres owned"

** generating village-average land price by eligibility status **
bys village_code eligible: egen vill_land_price = mean(land_price)

gen h1_11_landvalue = land_acresowned * vill_land_price
la var h1_11_landvalue "P1.11: Total value of land owned by household"
summ h1_11_landvalue

wins_top1 h1_11_landvalue
summ h1_11_landvalue_wins
trim_top1 h1_11_landvalue
summ h1_11_landvalue_trim

*** TOTAL AMOUNT OF LOANS TAKEN IN THE LAST 12 MONTHS ***
tab s10_q8_lending
tab1 s10_q8b_lendingamt // not sure what to do with the values of 1-3
gen total_lending = s10_q8b_lendingamt
replace total_lending = 0 if s10_q8_lending == 2
tab total_lending
la var total_lending "Total amount of money lent out by HH"

** part 3: generating total borrowing
* rosca loans
tab1 s10_q3c_roscaloan s10_q3d_roscaloanamt
gen rosca_loanamt = s10_q3d_roscaloanamt
replace rosca_loanamt = 0 if s10_q3c_roscaloan == 2
tab rosca_loanamt
la var rosca_loanamt "Amount of ROSCA loans taken"

* bank loans
tab1 s10_q4_bankloan s10_q4a_bankloanamt
gen bank_loanamt = s10_q4a_bankloanamt
replace bank_loanamt = 0 if s10_q4_bankloan == 2
tab bank_loanamt
la var bank_loanamt "Amount of bank loans taken"

* shylock loans
tab1 s10_q5_shylock s10_q5a_shylockamt
gen shylock_loanamt = s10_q5a_shylockamt
replace shylock_loanamt = 0 if s10_q5_shylock == 2
tab shylock_loanamt
la var shylock_loanamt "Amount of shylock / moneylender loans taken"

* Mshwari loans
tab1 s10_q6_mshwari s10_q6a_mshwariamt
gen mshwari_loanamt = s10_q6a_mshwariamt
replace mshwari_loanamt = 0 if s10_q6_mshwari == 2
tab mshwari_loanamt
la var mshwari_loanamt "Amount of M-Shwari loans taken"

* household loans
tab1 s10_q7_hhloan s10_q7b_hhloanamt
gen hh_loanamt = s10_q7b_hhloanamt
replace hh_loanamt = 0 if s10_q7_hhloan == 2
la var hh_loanamt "Amount of household loans taken"

egen totval_loanstaken = rowtotal(rosca_loanamt bank_loanamt shylock_loanamt mshwari_loanamt hh_loanamt), m
summ totval_loanstaken
gen totval_loanstaken_assets = - totval_loanstaken
summ totval_loanstaken_assets

gen h1_12_loans = totval_loanstaken
la var h1_12_loans "P1.12: Total amount of loans taken in the last 12 months"
summ h1_12_loans

wins_top1 h1_12_loans
summ h1_12_loans_wins
trim_top1 h1_12_loans
summ h1_12_loans_trim

*** TOTAL AMOUNT OF LOANS GIVEN IN THE LAST 12 MONTHS ***
tab1 total_lending

gen h1_13_loansgiven = total_lending
la var h1_13_loansgiven "P1.13: Total amount of loans given in the last 12 months"
summ h1_13_loansgiven

wins_top1 h1_13_loansgiven
summ h1_13_loansgiven_wins
trim_top1 h1_13_loansgiven
summ h1_13_loansgiven_trim

/*** SUMMARY MEASURE FOR ASSETS ***/
egen totval_hhassets = rowtotal(s6_q13a_bicyclevalue s6_q13b_motorcyclevalue s6_q13c_carvalue s6_q13d_kerosenevalue s6_q13e_radiovalue s6_q13f_sewingvalue s6_q13g_kerosenelanternvalue s6_q13h_bedvalue s6_q13i_mattressvalue s6_q13j_bednetvalue s6_q13k_tablevalue s6_q13l_sofavalue s6_q13m_chairvalue s6_q13n_cupboardsvalue s6_q13o_clock_watchvalue s6_q13p_elecironvalue s6_q13q_televisionvalue s6_q13r_computervalue s6_q13s_mobilevalue s6_q13t_carbatteryvalue s6_q13u_boatvalue s6_q13v_metalsheetsvalue s6_q13w_farmtoolsvalue s6_q13x_handcartvalue s6_q13y_wheelbarrowvalue s6_q13z_oxplowvalue s6_q13aa_cattlevalue s6_q13bb_goatvalue s6_q13cc_sheepvalue s6_q13dd_chickenvalue s6_q13ee_othbirdvalue s6_q13ff_pigvalue s6_q13gg_solarvalue), m

wins_top1 totval_hhassets

egen net_asset_value = rowtotal(totval_hhassets total_lending totval_loanstaken_assets), m
summ net_asset_value

gen p1_assets = net_asset_value
la var p1_assets "P1: Total non-land, non-home assets, net loans"

wins_top1 p1_assets
summ p1_assets_wins
wins_topbottom1 p1_assets
summ p1_assets_wins2

trim_top1 p1_assets
summ p1_assets_trim
trim_topbottom1 p1_assets
summ p1_assets_trim2

** adding in home value for comparability for GD **
egen net_asset_value_home = rowtotal( net_asset_value h1_10_housevalue), m
gen p1_assets_home = net_asset_value_home

wins_top1 p1_assets_home
summ p1_assets_home_wins
trim_top1 p1_assets_home
summ p1_assets_home_trim




/*** GENERATING PPP VALUES ***/
foreach var of varlist p1_assets* h1_1_livestock* h1_2_agtools* h1_3_furniture* h1_4_radiotv*   h1_10_housevalue* h1_11_landvalue* h1_12_loans* h1_13_loansgiven* totval_hhassets* land_price* {
	loc vl : variable label `var'
	gen `var'_PPP = `var' * $ppprate
	la var `var'_PPP "`vl' (PPP)"
}




/* Productive ag */


local agtools "s6_q13w_farmtoolsvalue s6_q13x_handcartvalue s6_q13y_wheelbarrowvalue s6_q13z_oxplowvalue"
local livestock "s6_q13aa_cattlevalue s6_q13bb_goatvalue s6_q13cc_sheepvalue s6_q13dd_chickenvalue s6_q13ee_othbirdvalue s6_q13ff_pigvalue"

local prod_ag "s6_q13w_farmtoolsvalue s6_q13x_handcartvalue s6_q13y_wheelbarrowvalue s6_q13z_oxplowvalue s6_q13aa_cattlevalue s6_q13bb_goatvalue s6_q13cc_sheepvalue s6_q13dd_chickenvalue s6_q13ee_othbirdvalue s6_q13ff_pigvalue"

/* Productive non-ag */
local prod_nonag "s6_q13a_bicyclevalue s6_q13b_motorcyclevalue s6_q13c_carvalue s6_q13d_kerosenevalue s6_q13f_sewingvalue s6_q13p_elecironvalue s6_q13r_computervalue s6_q13s_mobilevalue s6_q13t_carbatteryvalue s6_q13u_boatvalue s6_q13gg_solarvalue s6_q13hh_generatorvalue"

/* non-productive */
local nonprod "s6_q13e_radiovalue s6_q13g_kerosenelanternvalue s6_q13h_bedvalue s6_q13i_mattressvalue s6_q13j_bednetvalue s6_q13k_tablevalue s6_q13l_sofavalue s6_q13m_chairvalue s6_q13n_cupboardsvalue s6_q13o_clock_watchvalue s6_q13q_televisionvalue s6_q13v_metalsheetsvalue"


foreach type in agtools livestock prod_ag prod_nonag nonprod {
    di "`type'"
  egen assets_`type' = rowtotal(``type''), m
  summ assets_`type', d

  gen assets_`type'_wins = assets_`type'
  replace assets_`type'_wins = r(p99) if assets_`type'_wins > r(p99) & ~mi(assets_`type'_wins)

  gen assets_`type'_wins_PPP = assets_`type'_wins * $ppprate
  gen assets_`type'_PPP = assets_`type' * $ppprate

}


/*
** generate baseline multiplier asset measure. This does not net out loans**
egen totval_hhassets = rowtotal(assets_agtools assets_livestock assets_prod_nonag assets_nonprod), m // note that this was previously not rowtotal. This matters for how individual missing observations are handled.

count if totval_hhassets != totval_hhassets

stop
*/

** saving, dropping survey variables **
drop s6_* s10_*
save "$da/intermediate/GE_HH-BL_assets.dta", replace
project, creates("$da/intermediate/GE_HH-BL_assets.dta")
