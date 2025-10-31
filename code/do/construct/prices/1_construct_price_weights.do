* Filename: 1_construct_price_weights.do
* Description: This pulls from GE_RawData/ (which includes code to develop KLPS shares) and
*    adapts R code from Tilman in GE_Analysis/do/construct/prices to create a central
*    file that a) constructs GE weights from consumption expenditure data, b) takes KLPS weights
*    as given, and c) combines these together and ensures they are ready to merge with price data.


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


/********************************************/
/*    COMBINING WITH KLPS SHARES            */
/********************************************/

use "$dr/KLPS3_Expenditure_Shares_GEsample.dta", clear



* Drop unnecessary categories

keep product ge_share shares_All

* Drop categories that will not be used, then reweight

drop if inlist(product,"Bicycle (Local)", "Mosquito Net", "Milk Powder", "Duck", "Piglet")
drop if inlist(product, "Turkey", "Donkey")

egen denom = total(ge_share)

gen cons_weight = ge_share/denom
gen cons_weight_shares = shares_All
label var cons_weight "Overall weight of consumption basket"
drop ge_share denom

replace product = "Goat (Meat)" if product == "Goat (meat)"

* Generate variables for product subindices



gen prod_cat = ""
*FOOD
replace prod_cat = "food" if inlist(product, "Cassava", "Irish potato", "Maize", "Millet", "Plantains", "Rice")
replace prod_cat = "food" if inlist(product, "Sorghum", "Sweet potato", "Beans", "Cabbage", "Cowpea leaves")
replace prod_cat = "food" if inlist(product, "Green grams", "Groundnuts", "Kales", "Onions", "Saka (Local Vegetable)")
replace prod_cat = "food" if inlist(product, "Tomatoes", "Avocado", "Banana-sweet", "Mango", "Orange", "Papaya")
replace prod_cat = "food" if inlist(product, "Pineapple", "Water Melon", "Jackfruit", "Passion", "Beef", "Fish (Tilapia)")
replace prod_cat = "food" if inlist(product, "Goat (meat)", "Pork", "Egg", "Milk (Fresh)", "Biscuits", "Bread", "Cake")
replace prod_cat = "food" if inlist(product, "Maize Flour", "Wheat Flour", "Milk (Fermented)")
replace prod_cat = "food" if inlist(product, "Milk powder", "Soda", "Sugar", "Tea Leaves", "Goat (Meat)")

*NON-FOOD NON-DURABLES
replace prod_cat = "nondurable" if inlist(product, "Bar Soap", "Toothpaste", "Vaseline", "Washing Powder", "Bleach")
replace prod_cat = "nondurable" if inlist(product, "Panadol", "Cooking Fat", "Batteries (3 volt)", "Firewood", "Kerosene")
replace prod_cat = "nondurable" if inlist(product, "Charcoal", "Leso", "Small Sufuria", "Slippers (Umoja)", "Fertilizer", "Improved Seeds (Maize)")

*LIVESTOCK:
replace prod_cat = "livestock" if inlist(product, "Bull (local)", "Calf (local)", "Chicken (hen)", "Goat", "Sheep")

*"DURABLES"
replace prod_cat = "durable" if inlist(product, "1 Iron sheet (32 gauge)", "Cement", "Large Padlock", "Nails (3 inch)", "Roofing Nails")
replace prod_cat = "durable" if inlist(product, "Timber (2x2)", "Water Paint", "20L Jerry Can", "Thermos Flask", "3 1/2 X 6 Mattress", "Bicycle (local)", "Mosquito Net")

*TEMPTATION GOODS
replace prod_cat = "temptation" if inlist(product, "Cigarettes", "Alcohol")

sort prod_cat product

* Generate subindex weights

gen food_weight = 0
replace food_weight = cons_weight if prod_cat == "food"
egen denom_food = total(food_weight)
replace food_weight = food_weight/denom_food
label var food_weight "Weight for food"

gen nondur_weight = 0
replace nondur_weight = cons_weight if prod_cat == "nondurable"
egen denom_nondur = total(nondur_weight)
replace nondur_weight = nondur_weight/denom_nondur
label var nondur_weight "Weight for non-food non-durable goods"

gen live_weight = 0
replace live_weight = cons_weight if prod_cat == "livestock"
egen denom_live = total(live_weight)
replace live_weight = live_weight/denom_live
label var live_weight "Weight for livestock"

gen dur_weight = 0
replace dur_weight = cons_weight if prod_cat == "durable"
egen denom_dur = total(dur_weight)
replace dur_weight = dur_weight/denom_dur
label var dur_weight "Weight for durable goods"

gen tempt_weight = 0
replace tempt_weight = cons_weight if prod_cat == "temptation"
egen denom_tempt = total(tempt_weight)
replace tempt_weight = tempt_weight/denom_tempt
label var tempt_weight "Weight for temptation goods (cigarettes)"

gen durall_weight = 0
replace durall_weight = cons_weight if prod_cat == "durable" | prod_cat == "livestock"
egen denom_durall = total(durall_weight)
replace durall_weight = durall_weight/denom_durall
label var durall_weight "Weight for durable and livestock goods"

gen nondurall_weight = 0
replace nondurall_weight = cons_weight if prod_cat == "food" | prod_cat == "nondurable"
egen denom_nondurall = total(nondurall_weight)
replace nondurall_weight = nondurall_weight/denom_nondurall
label var nondurall_weight "Weight for food and non-food non-durable goods"

drop denom_*


* Generate subcategory expenditure shares

gen food_weight_shares = 0
replace food_weight_shares = shares_All if prod_cat == "food"
egen denom_food_shares = total(food_weight_shares)
replace food_weight_shares = food_weight_shares/denom_food_shares
label var food_weight_shares "Weight for food"

gen nondur_weight_shares = 0
replace nondur_weight_shares = shares_All if prod_cat == "nondurable"
egen denom_nondur_shares = total(nondur_weight_shares)
replace nondur_weight_shares = nondur_weight_shares/denom_nondur_shares
label var nondur_weight_shares "Weight for non-food non-durable goods, Exp Shares"

gen live_weight_shares = 0
replace live_weight_shares = shares_All if prod_cat == "livestock"
egen denom_live_shares = total(live_weight_shares)
replace live_weight_shares = live_weight_shares/denom_live_shares
label var live_weight_shares "Weight for livestock, Exp Shares"

gen dur_weight_shares = 0
replace dur_weight_shares = shares_All if prod_cat == "durable"
egen denom_dur_shares = total(dur_weight_shares)
replace dur_weight_shares = dur_weight_shares/denom_dur_shares
label var dur_weight_shares "Weight for durable goods, Exp Shares"

gen tempt_weight_shares = 0
replace tempt_weight_shares = shares_All if prod_cat == "temptation"
egen denom_tempt_shares = total(tempt_weight_shares)
replace tempt_weight_shares = tempt_weight_shares/denom_tempt_shares
label var tempt_weight_shares "Weight for temptation goods (cigarettes), Exp Shares"

gen durall_weight_shares = 0
replace durall_weight_shares = shares_All if prod_cat == "durable" | prod_cat == "livestock"
egen denom_durall_shares = total(durall_weight_shares)
replace durall_weight_shares = durall_weight_shares/denom_durall_shares
label var durall_weight_shares "Weight for durable and livestock goods, Exp Shares"

gen nondurall_weight_shares = 0
replace nondurall_weight_shares = shares_All if prod_cat == "food" | prod_cat == "nondurable"
egen denom_nondurall_shares = total(nondurall_weight_shares)
replace nondurall_weight_shares = nondurall_weight_shares/denom_nondurall_shares
label var nondurall_weight_shares "Weight for food and non-food non-durable goods, Exp Shares"

drop denom_*




* create index for goods based on trade_status

gen trade_status = .

replace trade_status = 1 if inlist(prod_cat, "durable", "nondurable")
replace trade_status = 0 if inlist(prod_cat, "food", "livestock")

gen trade_weight = 0
replace trade_weight = cons_weight if trade_status == 1
egen denom_trade = total(trade_weight)
replace trade_weight = trade_weight/denom_trade
label var trade_weight "Weight for traded goods"

gen nontrade_weight = 0
replace nontrade_weight = cons_weight if trade_status == 0
egen denom_nontrade = total(nontrade_weight)
replace nontrade_weight = nontrade_weight/denom_nontrade
label var nontrade_weight "Weight for non-traded goods"

drop denom_*


* same with exp shares

gen trade_weight_shares = 0
replace trade_weight_shares = cons_weight_shares if trade_status == 1
egen denom_trade_shares = total(trade_weight_shares)
replace trade_weight_shares = trade_weight_shares/denom_trade_shares
label var trade_weight_shares "Weight for traded goods, Exp Shares"

gen nontrade_weight_shares = 0
replace nontrade_weight_shares = cons_weight_shares if trade_status == 0
egen denom_nontrade_shares = total(nontrade_weight_shares)
replace nontrade_weight_shares = nontrade_weight_shares/denom_nontrade_shares
label var nontrade_weight_shares "Weight for non-traded goods, Exp Shares"

drop denom_*


sort product

save "$dt/expenditure_weights.dta", replace
