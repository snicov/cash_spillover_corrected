
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

project, uses("$dt/pp_GDP_calculated_nominal.dta")
use "$dt/pp_GDP_calculated_nominal.dta", clear
global pp_GDP = pp_GDP[1]
clear

// end preliminaries

project, original("$do/programs/run_ge_build_programs.do")
include "$do/programs/run_ge_build_programs.do"


*************************
** 0. Data Preparation **
*************************
project, uses("$da/intermediate/GE_Market_Survey_ProductLevel_FINAL.dta")
use "$da/intermediate/GE_Market_Survey_ProductLevel_FINAL.dta", clear
sort market_id product month

codebook product

** replace prices with logs **
replace med_price = ln(med_price)
replace min_price = ln(min_price)

** Collpase to market-month dataset **
gen prod = ""
replace prod = "ironsheet" if product == "1 Iron sheet (32 gauge)"
replace prod = "jerrycan" if product == "20L Jerry Can"
replace prod = "mattress" if product == "3 1/2 X 6 Mattress"
replace prod = "avocado" if product == "Avocado"
replace prod = "banana" if product == "Banana-sweet"
replace prod = "soap" if product == "Bar Soap"
replace prod = "battery" if product == "Batteries (3 volt)"
replace prod = "beans" if product == "Beans"
replace prod = "beef" if product == "Beef"
replace prod = "biscuit" if product == "Biscuits"
replace prod = "bleach" if product == "Bleach"
replace prod = "bread" if product == "Bread"
replace prod = "bull" if product == "Bull (local)"
replace prod = "cabbage" if product == "Cabbage"
replace prod = "cake" if product == "Cake"
replace prod = "calf" if product == "Calf (local)"
replace prod = "cassava" if product == "Cassava"
replace prod = "cement" if product == "Cement"
replace prod = "charcoal" if product == "Charcoal"
replace prod = "chicken" if product == "Chicken (hen)"
replace prod = "cigarettes" if product == "Cigarettes"
replace prod = "fat" if product == "Cooking Fat"
replace prod = "cowpea" if product == "Cowpea leaves"
replace prod = "egg" if product == "Egg"
replace prod = "fertilizer" if product == "Fertilizer"
replace prod = "firewood" if product == "Firewood"
replace prod = "fish" if product == "Fish (Tilapia)"
replace prod = "goat" if product == "Goat"
replace prod = "goatmeat" if product == "Goat (Meat)"
replace prod = "greengrams" if product == "Green grams"
replace prod = "groundnuts" if product == "Groundnuts"
replace prod = "seeds" if product == "Improved Seeds (Maize)"
replace prod = "potatoes" if product == "Irish potato"
replace prod = "jackfruit" if product == "Jackfruit"
replace prod = "kale" if product == "Kales"
replace prod = "kerosene" if product == "Kerosene"
replace prod = "padlock" if product == "Large Padlock"
replace prod = "leso" if product == "Leso"
replace prod = "lamb" if product == "Lamb"
replace prod = "maize" if product == "Maize"
replace prod = "maizeflour" if product == "Maize Flour"
replace prod = "mango" if product == "Mango"
replace prod = "milkferment" if product == "Milk (Fermented)"
replace prod = "milk" if product == "Milk (Fresh)"
replace prod = "millet" if product == "Millet"
replace prod = "nails" if product == "Nails (3 inch)"
replace prod = "onions" if product == "Onions"
replace prod = "orange" if product == "Orange"
replace prod = "panadol" if product == "Panadol"
replace prod = "papaya" if product == "Papaya"
replace prod = "passion" if product == "Passion"
replace prod = "pineapple" if product == "Pineapple"
replace prod = "plantains" if product == "Plantains"
replace prod = "pork" if product == "Pork"
replace prod = "rice" if product == "Rice"
replace prod = "roofnails" if product == "Roofing Nails"
replace prod = "saka" if product == "Saka (Local Vegetable)"
replace prod = "sheep" if product == "Sheep"
replace prod = "slippers" if product == "Slippers (Umoja)"
replace prod = "sufuria" if product == "Small Sufuria"
replace prod = "soda" if product == "Soda"
replace prod = "sorghum" if product == "Sorghum"
replace prod = "sugar" if product == "Sugar"
replace prod = "sweetpotato" if product == "Sweet potato"
replace prod = "tealeaves" if product == "Tea Leaves"
replace prod = "thermos" if product == "Thermos Flask"
replace prod = "timber" if product == "Timber (2x2)"
replace prod = "tomatoes" if product == "Tomatoes"
replace prod = "toothpaste" if product == "Toothpaste"
replace prod = "vaseline" if product == "Vaseline"
replace prod = "washingpowder" if product == "Washing Powder"
replace prod = "watermelon" if product == "Water Melon"
replace prod = "paint" if product == "Water Paint"
replace prod = "wheatflour" if product == "Wheat Flour"

codebook prod


keep district location sublocation market_id month med_price min_price flag_med_zs3plus flag_med_imputed flag_min_imputed prod

ren *_price *_p_
ren flag_med_zs3plus flag_med_zs3plus_
ren *_imputed *_imputed_

reshape wide med_p_ min_p_ flag_*, i(market_id month) j(prod) string
order district location sublocation market_id month

*** Merge with market-level treatment info ***
**********************************************
preserve
project, uses("$da/GE_MarketData_Panel_ECMA.dta") preserve
use "$da/GE_MarketData_Panel_ECMA.dta", clear

drop pidx_wKLPS_med pidx_wKLPS_food_med pidx_wKLPS_nondur_med pidx_wKLPS_live_med pidx_wKLPS_dur_med pidx_wKLPS_tempt_med pidx_wKLPS_durall_med pidx_wKLPS_ndall_med pidx_wKLPS_trade_med pidx_wKLPS_nontrade_med pidx_wKLPS_min pidx_wKLPS_food_min pidx_wKLPS_nondur_min pidx_wKLPS_live_min pidx_wKLPS_dur_min pidx_wKLPS_tempt_min pidx_wKLPS_durall_min pidx_wKLPS_ndall_min pidx_wKLPS_trade_min pidx_wKLPS_nontrade_min pidx_wGE_med pidx_wGE_food_med pidx_wGE_nondur_med pidx_wGE_live_med pidx_wGE_dur_med pidx_wGE_tempt_med pidx_wGE_durall_med pidx_wGE_ndall_med pidx_wGE_trade_med pidx_wGE_nontrade_med pidx_wGE_min pidx_wGE_food_min pidx_wGE_nondur_min pidx_wGE_live_min pidx_wGE_dur_min pidx_wGE_tempt_min pidx_wGE_durall_min pidx_wGE_ndall_min pidx_wGE_trade_min pidx_wGE_nontrade_min
drop pidx2_wKLPS_med pidx2_wKLPS_food_med pidx2_wKLPS_nondur_med pidx2_wKLPS_live_med pidx2_wKLPS_dur_med pidx2_wKLPS_tempt_med pidx2_wKLPS_durall_med pidx2_wKLPS_ndall_med pidx2_wKLPS_trade_med pidx2_wKLPS_nontrade_med pidx2_wKLPS_min pidx2_wKLPS_food_min pidx2_wKLPS_nondur_min pidx2_wKLPS_live_min pidx2_wKLPS_dur_min pidx2_wKLPS_tempt_min pidx2_wKLPS_durall_min pidx2_wKLPS_ndall_min pidx2_wKLPS_trade_min pidx2_wKLPS_nontrade_min pidx2_wGE_med pidx2_wGE_food_med pidx2_wGE_nondur_med pidx2_wGE_live_med pidx2_wGE_dur_med pidx2_wGE_tempt_med pidx2_wGE_durall_med pidx2_wGE_ndall_med pidx2_wGE_trade_med pidx2_wGE_nontrade_med pidx2_wGE_min pidx2_wGE_food_min pidx2_wGE_nondur_min pidx2_wGE_live_min pidx2_wGE_dur_min pidx2_wGE_tempt_min pidx2_wGE_durall_min pidx2_wGE_ndall_min pidx2_wGE_trade_min pidx2_wGE_nontrade_min

tempfile mkt_treat
save `mkt_treat'

restore
merge 1:1 market_id month using `mkt_treat'

save "$da/GE_MarketData_Panel_ProductLevel_ECMA.dta", replace
project, creates("$da/GE_MarketData_Panel_ProductLevel_ECMA.dta")
