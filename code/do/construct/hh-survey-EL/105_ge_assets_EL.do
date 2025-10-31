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

** programs used as part of this file
project, original("$do/programs/run_ge_build_programs.do")
include "$do/programs/run_ge_build_programs.do"


/*
 * Filename: ge_hh-welfare_assets_EL.do
 * Description: This do file constructs the outcomes described in the HH welfare PAP on assets
 *   This corresponds to primary outcome in family 1 and sections 5.1 of the household welfare PAP.
 *
 *
 * Authors: Michael Walker
 * Last modified: 28 Sep 2018 - adjusting to focus only on assets from ge_hh-welfare_assets_cons_inc_outcomes_v5.do
 *   Adding in PPP calculation as well.
 * Date created: 14 July 2017
 */

/*************************/
/*   FAMILY 1: ASSETS    */
/*************************/

project, uses("$da/intermediate/GE_HH-EL_setup.dta")

use "$da/intermediate/GE_HH-EL_setup.dta", clear

*** SUMMARY MEASURE: NET TOTAL ASSETS ***

** part 1: generating total non-land assets
recode s6_q13a_bicyclevalue (-99 0.9/0.999 = .)
replace s6_q13a_bicyclevalue = 0 if s6_q13a_bicycle == 0
list s6_q13a_bicycle s6_q13a_bicyclevalue if s6_q13a_bicyclevalue < 100 & s6_q13a_bicyclevalue > 0 // these values are low for bicycles - ensure they are not numbers - no evidence that they are, but still seem strange
tab1 s6_q13a_bicycle s6_q13a_bicyclevalue
tab version if mi(s6_q13a_bicyclevalue)

recode s6_q13b_motorcyclevalue (-99 = .)
replace s6_q13b_motorcyclevalue = 0 if s6_q13b_motorcycle == 0
tab1 s6_q13b_motorcycle s6_q13b_motorcyclevalue
tab version if mi(s6_q13b_motorcyclevalue)

recode s6_q13c_carvalue (-99 = .)
replace s6_q13c_carvalue = 0 if s6_q13c_car == 0
tab1 s6_q13c_car s6_q13c_carvalue
tab version if mi(s6_q13c_carvalue)

recode s6_q13d_kerosenevalue (-99 -88 = .)
replace s6_q13d_kerosenevalue = 0 if s6_q13d_kerosene == 0
tab1 s6_q13d_kerosene s6_q13d_kerosenevalue
tab version if mi(s6_q13d_kerosenevalue)

recode s6_q13e_radiovalue (-99 -88 0.87/0.89 = .)
replace s6_q13e_radiovalue = 0 if s6_q13e_radio == 0
list s6_q13e_radio s6_q13e_radiovalue if s6_q13e_radiovalue == 1 // doesn't seem right, unclear how to correct
tab1 s6_q13e_radio s6_q13e_radiovalue
tab version if mi(s6_q13e_radiovalue)

recode s6_q13f_sewingvalue (-99 0.99/0.999 = .) // should change the 0.99 recoding to cleaning files
replace s6_q13f_sewingvalue = 0 if s6_q13f_sewing == 0
tab1 s6_q13f_sewing s6_q13f_sewingvalue
tab version if mi(s6_q13f_sewingvalue)

recode s6_q13g_lanternvalue (-99 -88 0.99 = .)
replace s6_q13g_lanternvalue = 0 if s6_q13g_lantern == 0
tab1 s6_q13g_lantern s6_q13g_lanternvalue
tab version if mi(s6_q13g_lanternvalue)

recode s6_q13h_bedvalue (-99 -88 0.87/0.999 = .)
replace s6_q13h_bedvalue = 0 if s6_q13h_bed == 0
list s6_q13h_bed s6_q13h_bedvalue if s6_q13h_bedvalue ==1 | s6_q13h_bedvalue == 2
tab1 s6_q13h_bed s6_q13h_bedvalue
tab version if mi(s6_q13h_bedvalue)

recode s6_q13i_mattressvalue (-99 -88 0.87/0.999 = .)
replace s6_q13i_mattressvalue = 0 if s6_q13i_mattress == 0
list s6_q13i_mattress s6_q13i_mattressvalue if s6_q13i_mattressvalue > 0 & s6_q13i_mattressvalue < 10
tab1 s6_q13i_mattress s6_q13i_mattressvalue
tab version if mi(s6_q13i_mattressvalue)

recode s6_q13j_bednetvalue (-99 = .)
replace s6_q13j_bednetvalue = 0 if s6_q13j_bednet == 0
list s6_q13j_bednet s6_q13j_bednetvalue if s6_q13j_bednetvalue <10 & s6_q13j_bednetvalue>0
tab1 s6_q13j_bednet s6_q13j_bednetvalue
tab version if mi(s6_q13j_bednetvalue)

recode s6_q13k_tablevalue (-99 -88 0.87/0.999 = .)
replace s6_q13k_tablevalue = 0 if s6_q13k_table == 0
list s6_q13k_table s6_q13k_tablevalue if s6_q13k_tablevalue==1 | s6_q13k_tablevalue==4 | s6_q13k_tablevalue==5
tab1 s6_q13k_table s6_q13k_tablevalue
tab version if mi(s6_q13k_tablevalue)


recode s6_q13l_sofavalue (-99 -88 0.99/0.999 = .)
replace s6_q13l_sofavalue = 0 if s6_q13l_sofa == 0
tab1 s6_q13l_sofa s6_q13l_sofavalue
tab version if mi(s6_q13l_sofavalue)

recode s6_q13m_chairvalue (-99 -88 = .)
replace s6_q13m_chairvalue = 0 if s6_q13m_chair == 0
tab1 s6_q13m_chair s6_q13m_chairvalue
tab version if mi(s6_q13m_chairvalue)

recode s6_q13n_cupboardsvalue (-99 -88 = .)
replace s6_q13n_cupboardsvalue = 0 if s6_q13n_cupboards == 0
tab1 s6_q13n_cupboards s6_q13n_cupboardsvalue
tab version if mi(s6_q13n_cupboardsvalue)


recode s6_q13o_clockvalue (-99 -88 = .)
replace s6_q13o_clockvalue = 0 if s6_q13o_clock == 0
tab1 s6_q13o_clock s6_q13o_clockvalue
tab version if mi(s6_q13o_clockvalue)

recode s6_q13p_elecironvalue (-99 = .)
replace s6_q13p_elecironvalue = 0 if s6_q13p_eleciron == 0
tab1 s6_q13p_eleciron s6_q13p_elecironvalue
tab version if mi(s6_q13p_elecironvalue)

recode s6_q13q_televisionvalue (-99 = .)
replace s6_q13q_televisionvalue = 0 if s6_q13q_television == 0
tab1 s6_q13q_television s6_q13q_televisionvalue
tab version if mi(s6_q13q_televisionvalue)

recode s6_q13r_computervalue (-99 = .)
replace s6_q13r_computervalue = 0 if s6_q13r_computer == 0
tab1 s6_q13r_computer s6_q13r_computervalue
tab version if mi(s6_q13r_computervalue)

recode s6_q13s_mobilevalue (-99 -88 0.87/0.888 = .)
replace s6_q13s_mobilevalue = 0 if s6_q13s_mobile == 0
tab1 s6_q13s_mobile s6_q13s_mobilevalue
tab version if mi(s6_q13s_mobilevalue)

recode s6_q13t_carbatteryvalue (-99 = .)
replace s6_q13t_carbatteryvalue = 0 if s6_q13t_carbattery == 0
tab1 s6_q13t_carbattery s6_q13t_carbatteryvalue
tab version if mi(s6_q13t_carbatteryvalue)

recode s6_q13u_boatvalue (-99 = .)
replace s6_q13u_boatvalue = 0 if s6_q13u_boat == 0
tab1 s6_q13u_boat s6_q13u_boatvalue
tab version if mi(s6_q13u_boatvalue)

recode s6_q13v_sheetsvalue (-99 = .)
replace s6_q13v_sheetsvalue = 0 if s6_q13v_sheets == 0
tab1 s6_q13v_sheets s6_q13v_sheetsvalue
tab version if mi(s6_q13v_sheetsvalue)

recode s6_q13w_farmtoolsvalue (-99 -88 0.88/0.888 = .)
replace s6_q13w_farmtoolsvalue = 0 if s6_q13w_farmtools == 0
list s6_q13w_farmtools s6_q13w_farmtoolsvalue if s6_q13w_farmtoolsvalue >0 & s6_q13w_farmtoolsvalue <10
tab1 s6_q13w_farmtools s6_q13w_farmtoolsvalue
tab version if mi(s6_q13w_farmtoolsvalue)

recode s6_q13x_handcartvalue (-99 = .)
replace s6_q13x_handcartvalue = 0 if s6_q13x_handcart == 0
tab1 s6_q13x_handcart s6_q13x_handcartvalue
tab version if mi(s6_q13x_handcartvalue)

recode s6_q13y_wbarrowvalue (-99 = .)
replace s6_q13y_wbarrowvalue = 0 if s6_q13y_wbarrow == 0
tab1 s6_q13y_wbarrow s6_q13y_wbarrowvalue
tab version if mi(s6_q13y_wbarrowvalue)

recode s6_q13z_oxplowvalue (-99 = .)
replace s6_q13z_oxplowvalue = 0 if s6_q13z_oxplow == 0
tab1 s6_q13z_oxplow s6_q13z_oxplowvalue
tab version if mi(s6_q13z_oxplowvalue)

recode s6_q13aa_cattlevalue (-99 = .)
replace s6_q13aa_cattlevalue = 0 if s6_q13aa_cattle == 0
list s6_q13aa_cattle s6_q13aa_cattlevalue if s6_q13aa_cattlevalue < 1000 & s6_q13aa_cattlevalue > 0 // these don't look right - way too cheap for cattle. What could be going on here?
tab1 s6_q13aa_cattle s6_q13aa_cattlevalue
tab version if mi(s6_q13aa_cattlevalue)

recode s6_q13bb_goatvalue (-99 = .)
replace s6_q13bb_goatvalue = 0 if s6_q13bb_goat == 0
tab1 s6_q13bb_goat s6_q13bb_goatvalue
tab version if mi(s6_q13bb_goatvalue)

recode s6_q13cc_sheepvalue (-99 = .)
replace s6_q13cc_sheepvalue = 0 if s6_q13cc_sheep == 0
tab1 s6_q13cc_sheep s6_q13cc_sheepvalue
tab version if mi(s6_q13cc_sheepvalue)

recode s6_q13dd_chickenvalue (-99 = .)
replace s6_q13dd_chickenvalue = 0 if s6_q13dd_chicken == 0
tab1 s6_q13dd_chicken s6_q13dd_chickenvalue
tab version if mi(s6_q13dd_chickenvalue)

recode s6_q13ee_othbirdvalue (-99 = .)
replace s6_q13ee_othbirdvalue = 0 if s6_q13ee_othbird == 0
tab1 s6_q13ee_othbird s6_q13ee_othbirdvalue
tab version if mi(s6_q13ee_othbirdvalue)

recode s6_q13ff_pigvalue (-99 = .)
replace s6_q13ff_pigvalue = 0 if s6_q13ff_pig == 0
tab1 s6_q13ff_pig s6_q13ff_pigvalue
tab version if mi(s6_q13ff_pigvalue)

recode s6_q13gg_solarvalue (-99 -88 0.99/0.999 = .)
replace s6_q13gg_solarvalue = 0 if s6_q13gg_solar == 0
tab1 s6_q13gg_solar s6_q13gg_solarvalue // what to make of solar value of 8? set to missing?
tab version if mi(s6_q13gg_solarvalue)

recode s6_q13hh_generatorvalue (-99 = .)
replace s6_q13hh_generatorvalue = 0 if s6_q13hh_generator == 0
tab1 s6_q13hh_generator s6_q13hh_generatorvalue // waht to make of outlier generator values?
tab version if mi(s6_q13hh_generatorvalue)

tab s6_q13_valuefx
//all values of asset variables 6.13.a-z and 6.13.aa-hh already in KSH

egen totval_hhassets = rowtotal(s6_q13a_bicyclevalue s6_q13b_motorcyclevalue s6_q13c_carvalue s6_q13d_kerosenevalue s6_q13e_radiovalue s6_q13f_sewingvalue s6_q13g_lanternvalue s6_q13h_bedvalue s6_q13i_mattressvalue s6_q13j_bednetvalue s6_q13k_tablevalue s6_q13l_sofavalue s6_q13m_chairvalue s6_q13n_cupboardsvalue s6_q13o_clockvalue s6_q13p_elecironvalue s6_q13q_televisionvalue s6_q13r_computervalue s6_q13s_mobilevalue s6_q13t_carbatteryvalue s6_q13u_boatvalue s6_q13v_sheetsvalue s6_q13w_farmtoolsvalue s6_q13x_handcartvalue s6_q13y_wbarrowvalue s6_q13z_oxplowvalue s6_q13aa_cattlevalue s6_q13bb_goatvalue s6_q13cc_sheepvalue s6_q13dd_chickenvalue s6_q13ee_othbirdvalue s6_q13ff_pigvalue s6_q13gg_solarvalue), m

egen assetlist_nonmiss = rownonmiss(s6_q13a_bicyclevalue s6_q13b_motorcyclevalue s6_q13c_carvalue s6_q13d_kerosenevalue s6_q13e_radiovalue s6_q13f_sewingvalue s6_q13g_lanternvalue s6_q13h_bedvalue s6_q13i_mattressvalue s6_q13j_bednetvalue s6_q13k_tablevalue s6_q13l_sofavalue s6_q13m_chairvalue s6_q13n_cupboardsvalue s6_q13o_clockvalue s6_q13p_elecironvalue s6_q13q_televisionvalue s6_q13r_computervalue s6_q13s_mobilevalue s6_q13t_carbatteryvalue s6_q13u_boatvalue s6_q13v_sheetsvalue s6_q13w_farmtoolsvalue s6_q13x_handcartvalue s6_q13y_wbarrowvalue s6_q13z_oxplowvalue s6_q13aa_cattlevalue s6_q13bb_goatvalue s6_q13cc_sheepvalue s6_q13dd_chickenvalue s6_q13ee_othbirdvalue s6_q13ff_pigvalue s6_q13gg_solarvalue)

tab assetlist_nonmiss

replace totval_hhassets = . if assetlist_nonmiss < 3

summ totval_hhassets
wins_top1 totval_hhassets

egen multiplier_assets = rowtotal(s6_q13a_bicyclevalue s6_q13b_motorcyclevalue s6_q13c_carvalue s6_q13d_kerosenevalue s6_q13e_radiovalue s6_q13p_elecironvalue s6_q13q_televisionvalue s6_q13r_computervalue s6_q13s_mobilevalue s6_q13t_carbatteryvalue s6_q13u_boatvalue s6_q13v_sheetsvalue s6_q13w_farmtoolsvalue s6_q13x_handcartvalue s6_q13y_wbarrowvalue s6_q13z_oxplowvalue s6_q13aa_cattlevalue s6_q13bb_goatvalue s6_q13cc_sheepvalue s6_q13dd_chickenvalue s6_q13ee_othbirdvalue s6_q13ff_pigvalue s6_q13gg_solarvalue), m

replace multiplier_assets = . if assetlist_nonmiss < 3

wins_top1 multiplier_assets


** part 2: generating total lending
tab s10_q8_lentmoney
tab1 s10_q8b_amt // not sure what to do with the values of 1-3
gen total_lending = s10_q8b_amt
replace total_lending = 0 if s10_q8_lentmoney == 2
tab total_lending
la var total_lending "Total amount of money lent out by HH"

** part 3: generating total borrowing
tab1 s10_q3d_roscaloanamtfx s10_q4a_bankloanamtfx s10_q5a_shylockamtfx s10_q6a_mshwariamtfx s10_q7b_hhloanamtfx
* other values (including other values in section 10) reported in KSH - amount makes sense for KSH. Changing currency
replace s10_q3d_roscaloanamtfx = 1 if s10_q3d_roscaloanamtfx == 2

* rosca loans
tab1 s10_q3c_roscaloan s10_q3d_roscaloanamt
list s10_q3*_rosca* if s10_q3d_roscaloanamt > 0 & s10_q3d_roscaloanamt < 4 // these values still don't make sense - how to reconcile these with interest?
gen rosca_loanamt = s10_q3d_roscaloanamt
replace rosca_loanamt = 0 if s10_q3c_roscaloan == 2
tab rosca_loanamt
tab version if mi(rosca_loanamt)
la var rosca_loanamt "Amount of ROSCA loans taken"

* bank loans
tab1 s10_q4_bankloan s10_q4a_bankloanamt
gen bank_loanamt = s10_q4a_bankloanamt
replace bank_loanamt = 0 if s10_q4_bankloan == 2
tab bank_loanamt
tab version if mi(bank_loanamt)
la var bank_loanamt "Amount of bank loans taken"

* shylock loans
tab1 s10_q5_shylock s10_q5a_shylockamt
gen shylock_loanamt = s10_q5a_shylockamt
replace shylock_loanamt = 0 if s10_q5_shylock == 2
tab shylock_loanamt
tab version if mi(shylock_loanamt)
la var shylock_loanamt "Amount of shylock / moneylender loans taken"

* Mshwari loans
tab1 s10_q6_mshwari s10_q6a_mshwariamt
gen mshwari_loanamt = s10_q6a_mshwariamt
replace mshwari_loanamt = 0 if s10_q6_mshwari == 2
tab mshwari_loanamt
tab version if mi(mshwari_loanamt)
la var mshwari_loanamt "Amount of M-Shwari loans taken"

* household loans
tab1 s10_q7_hhloan s10_q7b_hhloanamt
gen hh_loanamt = s10_q7b_hhloanamt
replace hh_loanamt = 0 if s10_q7_hhloan == 2
tab version if mi(hh_loanamt)
la var hh_loanamt "Amount of household loans taken"

egen totval_loanstaken = rowtotal(rosca_loanamt bank_loanamt shylock_loanamt mshwari_loanamt hh_loanamt), m
summ totval_loanstaken
gen totval_loanstaken_assets = - totval_loanstaken
summ totval_loanstaken_assets

** combining into net assets measure

egen net_asset_value = rowtotal(totval_hhassets total_lending totval_loanstaken_assets), m
replace net_asset_value = . if assetlist_nonmiss < 3
summ net_asset_value
tab version if mi(net_asset_value)

gen p1_assets = net_asset_value
la var p1_assets "P1: Total non-land, non-house assets, net lending"

wins_top1 p1_assets
summ p1_assets_wins
wins_topbottom1 p1_assets
summ p1_assets_wins2

trim_top1 p1_assets
summ p1_assets_trim
trim_topbottom1 p1_assets
summ p1_assets_trim2

/*** 1.1 TOTAL VALUE OF LIVESTOCK ***/
summ s6_q13aa_cattlevalue s6_q13bb_goatvalue s6_q13cc_sheepvalue s6_q13dd_chickenvalue s6_q13ee_othbirdvalue s6_q13ff_pigvalue

egen h1_1_livestock = rowtotal(s6_q13aa_cattlevalue s6_q13bb_goatvalue s6_q13cc_sheepvalue s6_q13dd_chickenvalue s6_q13ee_othbirdvalue s6_q13ff_pigvalue), m

summ h1_1_livestock
la var h1_1_livestock "P1.1: Total value of livestock"

wins_top1 h1_1_livestock
summ h1_1_livestock_wins
trim_top1 h1_1_livestock
summ h1_1_livestock_trim

/*** 1.2 TOTAL VALUE OF AGRICULTURAL TOOLS ***/
summ s6_q13w_farmtoolsvalue s6_q13x_handcartvalue s6_q13y_wbarrowvalue s6_q13z_oxplowvalue
egen h1_2_agtools = rowtotal(s6_q13w_farmtoolsvalue s6_q13x_handcartvalue s6_q13y_wbarrowvalue s6_q13z_oxplowvalue), m
summ h1_2_agtools

la var h1_2_agtools "P1.2: Total value of agricultural tools"

wins_top1 h1_2_agtools
summ h1_2_agtools_wins
trim_top1 h1_2_agtools
summ h1_2_agtools_trim

/*** 1.3 TOTAL VALUE OF FURNITURE ***/
summ s6_q13h_bedvalue s6_q13i_mattressvalue s6_q13j_bednetvalue s6_q13k_tablevalue s6_q13l_sofavalue s6_q13m_chairvalue s6_q13n_cupboardsvalue s6_q13o_clockvalue

egen h1_3_furniture = rowtotal(s6_q13h_bedvalue s6_q13i_mattressvalue s6_q13j_bednetvalue s6_q13k_tablevalue s6_q13l_sofavalue s6_q13m_chairvalue s6_q13n_cupboardsvalue s6_q13o_clockvalue), m
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
replace s6_q0a_floor_oth = "" if s6_q0a_floor_oth == "."
tab s6_q0a_floor_oth

gen nonmudfloor = .
replace nonmudfloor = 0 if s6_q0a_floor == 2
replace nonmudfloor = 1 if s6_q0a_floor == 1 | s6_q0a_floor == 3 | s6_q0a_floor == 4
replace nonmudfloor = 1 if inlist(s6_q0a_floor_oth, "Mixture of stones and cement", "Stones")  // classifying part cement, part mud as non-mud. If other but not specified, keeping as missing (5 obs)

gen h1_5_nonmudfloor = nonmudfloor
la var h1_5_nonmudfloor "P1.5: House has non-mud floor"
tab h1_5_nonmudfloor

/*** 1/6 HOUSE HAS NON-THATCHED ROOF ***/
tab s6_q0b_roof
tab s6_q0b_roof_oth
gen nonthatchedroof = .
replace nonthatchedroof = 0 if s6_q0b_roof == 1 | s6_q0b_roof == 2
replace nonthatchedroof = 1 if s6_q0b_roof == 3 | s6_q0b_roof == 4 | s6_q0b_roof == 5
replace nonthatchedroof = 1 if inlist(s6_q0b_roof_oth, "Grass and iron") // how to handle this?
count if s6_q0b_roof == 6 & s6_q0b_roof_oth == ""
//how to classify "others" when the description is missing?

gen h1_6_nonthatchedroof = nonthatchedroof
la var h1_6_nonthatchedroof "P1.6: House has non-thatched roof"
tab h1_6_nonthatchedroof

/*** 1.7 HOUSE HAS NON-MUD WALLS ***/
replace s6_q0c_walls_oth = "" if s6_q0c_walls_oth == "."
tab1 s6_q0c_walls s6_q0c_walls_oth

gen nonmudwalls = .
replace nonmudwalls = 0 if s6_q0c_walls == 2 // classifying part mud part cement as non-mud - can reconsider
replace nonmudwalls = 1 if s6_q0c_walls == 1 | s6_q0c_walls == 3 | s6_q0c_walls == 4 | s6_q0c_walls == 5
replace nonmudwalls = 1 if inlist(s6_q0c_walls_oth, "Wooden", "Blocks")
replace nonmudwalls = 0 if inlist(s6_q0c_walls_oth, "Walls are still incomplete with standby poles", "NILONE  PAPER")
count if s6_q0c_walls == 6 & s6_q0c_walls_oth == ""
//how to classify "others" when the description is missing?

gen h1_7_nonmudwalls = nonmudwalls
la var h1_7_nonmudwalls "P1.7: House has non-mud walls"
tab h1_7_nonmudwalls

*** HOUSE HAS ELECTRICITY ***
tab s6_q1_haselectricity
gen elec = s6_q1_haselectricity
recode elec 2 = 0

gen h1_8_electricity = elec
la var h1_8_electricity "P1.8: House has electricity"
tab h1_8_electricity

*** HOUSE PRIMARILY USES AN IMPROVED TOILET ***
replace s6_q2_toilettype_oth = "" if s6_q2_toilettype_oth == "."
tab1 s6_q2_toilettype s6_q2_toilettype_oth
gen improvedtoilet = .
replace improvedtoilet = 1 if s6_q2_toilettype == 3 | s6_q2_toilettype == 5
replace improvedtoilet = 0 if s6_q2_toilettype == 1 | s6_q2_toilettype == 2 | s6_q2_toilettype == 4

gen h1_9_toilet = improvedtoilet
la var h1_9_toilet "P1.9: House primarily uses an improved toilet"
tab h1_9_toilet
drop improvedtoilet

*** COST OF MATERIALS AMD LABOR TO BUILD HOUSE ***

replace s6_q5_homestatus_oth = "" if s6_q5_homestatus_oth == "."
tab s6_q5_homestatus_oth // may need to re-code some of these
tab1 s6_q5_homestatus s6_q5_homestatus_oth s6_q5a_homevalue
recode s6_q5a_homevalue -99 -88 = .

gen housevalue = s6_q5a_homevalue if s6_q5_homestatus == 1
replace housevalue = 0 if s6_q5_homestatus == 2 | s6_q5_homestatus == 3 | s6_q5_homestatus == 4 | s6_q5_homestatus == 5 // for those that do not own home, setting this to zero

tab version if mi(housevalue)
gen h1_10_housevalue = housevalue
la var h1_10_housevalue "P1.10: Cost of materials and labor to build house"
summ h1_10_housevalue

wins_top1 h1_10_housevalue
summ h1_10_housevalue_wins
trim_top1 h1_10_housevalue
summ h1_10_housevalue_trim

*** TOTAL VALUE OF LAND OWNED BY HOUSEHOLD ***
* sertting very large land value outliers to missing - not sure what was going on with these, seem more like values
replace s6_q6_acresowned = . if s6_q6_acresowned == 25000 | s6_q6_acresowned == 30000

tab1 s6_q6_acresowned s6_q6a_acrevalue s6_q6a_acrevaluefx s6_q6a_acrevaluefx_oth
recode s6_q6_acresowned -99 = .
recode s6_q6a_acrevalue -99 = .
//gen a new variable for s6_q6a_acrevalue that includes only reports in KSH
list s1_hhid_key s6_q6_acresowned s6_q6a_acrevalue if s6_q6_acresowned > 100 & ~mi(s6_q6_acresowned)
list s1_hhid_key s6_q6_acresowned s6_q6a_acrevalue if s6_q6a_acrevalue < 1000

replace s6_q6_acresowned = 0.25     if s1_hhid_key == "601040402005-034"
replace s6_q6a_acrevalue = 100000  if s1_hhid_key == "601040402005-034"

* come back to this - values below 1000 don't make much sense - were these from different questions that got pulled in by some mistake?
tab version if s6_q6a_acrevalue < 1000 & s6_q6a_acrevalue > 0 // this looks like variation - just FOs not entering properly?
replace s6_q6a_acrevalue = . if s6_q6a_acrevalue < 1000  // just setting these to missing for now.


tab s6_q6a_acrevalue
recode s6_q6a_acrevalue (min/-1 99 999 9999 99999 = .), gen(land_price)
la var land_price "Price per acre (KSH)"

wins_top1 land_price

** generating village-level average price - need to look into this more **
bys village_code eligible: egen vill_land_price = mean(land_price_wins)


//replace s6_q6a_acrevalue_ksh = . if s6_q6a_acresvaluefx == 2 | s6_q6a_acresvaluefx == 3 // most of the shilling values seem reasonable, in the other categories of section 6 there are also values reported in shillings
gen landvalue = .
replace landvalue = s6_q6_acresowned * vill_land_price if  ~missing(s6_q6_acresowned)
count if s6_q6a_acrevalue == . & s6_q6_acresowned > 0 & ~mi(s6_q6_acresowned) // 13 households - can come back and do some sort of imputation for these at some point in time
replace landvalue = 0 if s6_q6_acresowned == 0

* in general, should come back and create a measure of this where we use average values or something - want to make sure it's not just crazy values that are generating any differences. Check for differences in land ownership too - if total ownership isn't changing, no effect on values then less interesting to look into

gen h1_11_landvalue = landvalue
la var h1_11_landvalue "P1.11: Total value of land owned by household"
summ h1_11_landvalue

wins_top1 h1_11_landvalue
summ h1_11_landvalue_wins
trim_top1 h1_11_landvalue
summ h1_11_landvalue_trim

*** TOTAL AMOUNT OF LOANS TAKEN IN THE LAST 12 MONTHS ***
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


*** SUMMARY MEASURE: NET TOTAL ASSETS ***
egen net_asset_value_home = rowtotal(p1_assets h1_10_housevalue), m
replace net_asset_value_home = . if assetlist_nonmiss < 3

la var net_asset_value_home "Total non-land assets (incl home value)"
wins_top1 net_asset_value_home
trim_top1 net_asset_value_home



/*** GENERATING PPP VALUES ***/
foreach var of varlist p1_assets* h1_1_livestock* h1_2_agtools* h1_3_furniture* h1_4_radiotv*   h1_10_housevalue* h1_11_landvalue* h1_12_loans* h1_13_loansgiven* multiplier_assets* totval_hhassets* {
	loc vl : variable label `var'
	gen `var'_PPP = `var' * $ppprate
	la var `var'_PPP "`vl' (PPP)"
}

/* Next, we classify assets into categories based on whether they are potentially productive for agriculture or non-ag enterprise activity (in which case they could be considered investment) or not */


/* Productive ag */


local agtools "s6_q13w_farmtoolsvalue s6_q13x_handcartvalue s6_q13y_wbarrowvalue s6_q13z_oxplowvalue"

/** potentially productive **/

local livestock "s6_q13aa_cattlevalue s6_q13bb_goatvalue s6_q13cc_sheepvalue s6_q13dd_chickenvalue s6_q13ee_othbirdvalue s6_q13ff_pigvalue"

/* Productive non-ag */
local prod_nonag "s6_q13a_bicyclevalue s6_q13b_motorcyclevalue s6_q13c_carvalue s6_q13d_kerosenevalue s6_q13f_sewingvalue s6_q13p_elecironvalue s6_q13r_computervalue s6_q13s_mobilevalue s6_q13t_carbatteryvalue s6_q13u_boatvalue s6_q13gg_solarvalue s6_q13hh_generatorvalue"

local pot_prod "`livestock' `prod_nonag'"


/* non-productive */
local nonprod "s6_q13e_radiovalue s6_q13g_lanternvalue s6_q13h_bedvalue s6_q13i_mattressvalue s6_q13j_bednetvalue s6_q13k_tablevalue s6_q13l_sofavalue s6_q13m_chairvalue s6_q13n_cupboardsvalue s6_q13o_clockvalue s6_q13q_televisionvalue s6_q13v_sheetsvalue"


foreach type in agtools livestock prod_nonag pot_prod nonprod {
    di "`type'"
  egen assets_`type' = rowtotal(``type''), m
  replace assets_`type' = . if assetlist_nonmiss < 3
  summ assets_`type', d

  gen assets_`type'_wins = assets_`type'
  replace assets_`type'_wins = r(p99) if assets_`type'_wins > r(p99) & ~mi(assets_`type'_wins)

  gen assets_`type'_wins_PPP = assets_`type'_wins * $ppprate
  gen assets_`type'_PPP = assets_`type' * $ppprate

}

*** SAVING INTERMEDIATE DATASET ***
keep s1_hhid_key p1_* h1_* assets_* hh_loanamt* total_lending totval_* *_loanamt multiplier_assets* land_price s6_*
save "$da/intermediate/GE_HH-EL_hhassets.dta", replace
project, creates("$da/intermediate/GE_HH-EL_hhassets.dta")
