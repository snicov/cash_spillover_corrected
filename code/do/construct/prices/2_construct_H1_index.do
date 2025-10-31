/*
 * Filename: H1_index.do
 * Description: Creates market price index for H1
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

// end preliminaries

* load commands
project, original("$do/programs/run_ge_build_programs.do")
include "$do/programs/run_ge_build_programs.do"

project, original("$dr/GE_Market-Survey_EL1_PUBLIC.dta")
use "$dr/GE_Market-Survey_EL1_PUBLIC.dta",clear

*==============================================================================*


** Reshape dataset: Now each observation is a market-product **
***************************************************************
egen type_pnum = concat(price_type pnum), p(_)
drop price_type pnum prod_* zs double_checked flag_zs4plus

foreach v of var flag_* {
	bysort market_id product month: egen temp = max(`v')
	replace `v' = temp
	drop temp
}

rename price p_

reshape wide p_, i(market_id product month) j(type_pnum) string
order district location sublocation market_id product unit month
sort district location sublocation market_id product unit month

* Get median and minimum price
egen med_price = rowmedian(p_*)
egen min_price = rowmin(p_*)

* Drop individual price variables
drop *high* *low* *initialhigh* *initiallow* *regular*


** Merge in expenditure weights **
**********************************
project, original("$dr/expenditure_weights.dta") preserve
merge m:1 product using "$dr/expenditure_weights.dta"
drop if _merge == 2 // alcohol data is added later

* The following drop gets rid of the products we remove from consideration because
* they are missing at high frequencies
drop if _merge == 1
drop _merge


** Now, we have two ways to create indices. One imputes missing prices using average price in other markets in that month **
** The other leaves missing prices out and creates a price index by reweighting the non-missing prices each period.


*******************************************************
** A) Replacing missing prices with monthly averages **
*******************************************************

* According to the PAP, for missing prices, we impute using the mean product price for
* villages for that month

gen flag_med_imputed = 1 if med_price == .
replace flag_med_imputed = 0 if flag_med_imputed == .
gen flag_min_imputed = 1 if min_price == .
replace flag_min_imputed = 0 if flag_min_imputed == .

* Generate the mean product month price
bysort product month: egen med_mean_price = mean(med_price)
bysort product month: egen min_mean_price = mean(min_price)


replace med_price = med_mean_price if med_price == .
replace min_price = min_mean_price if min_price == .



*==============================================================================*

foreach tp in med min {
	* Between August and November 2014, no markets have "Bull (local)", so I can't compute an average over it
	* Impute the price for these months as the average price in December 2014

	summ `tp'_price if product == "Bull (local)" & month == tm(2014m12)
	local bull_mean_dec14 = `r(mean)'
	replace `tp'_price = `bull_mean_dec14' if product == "Bull (local)" & month < tm(2014m12)

	* For September/October 2015, no markets have "Goat (Meat)", so I can't compute an average over it
	* Impute the price for these months as the average price in August 2015

	summ `tp'_price if product == "Goat (Meat)" & month == tm(2015m8)
	local goat_mean_aug15 = `r(mean)'
	replace `tp'_price = `goat_mean_aug15' if product == "Goat (Meat)" & inrange(month,tm(2015m09),tm(2015m10))
}

drop *mean_price

*==============================================================================*

****************************************
** Save Product - Level Price Dataset **
****************************************

** clean dataset **
keep district location sublocation market_id product unit month med_price min_price cons_weight* prod_cat food_weight* nondur_weight* live_weight* dur_weight* tempt_weight* durall_weight* nondurall_weight* flag_med_zs4plus flag_med_zs3plus flag_med_zs2plus  flag_med_imputed flag_min_imputed trade_status trade_weight* nontrade_weight* shares_*
order district location sublocation market_id product unit month med_price min_price cons_weight* prod_cat food_weight* nondur_weight* live_weight* dur_weight* tempt_weight* durall_weight* nondurall_weight* flag_med_zs4plus flag_med_zs3plus flag_med_zs2plus  flag_med_imputed flag_min_imputed shares_*

label var med_price "Median price of the product in a given market and month"
label var min_price "Minimum price of the product in a given market and month"

label var prod_cat "Product category"

label var flag_med_zs4plus "Median product price has z-score > 4 when compared to all markets this month"
label var flag_med_zs3plus "Median product price has z-score > 3 when compared to all markets this month"
label var flag_med_zs2plus "Median product price has z-score > 2 when compared to all markets this month"

label var flag_med_imputed "Median product price set to monthly average across markets, bc was missing"
label var flag_min_imputed "Minimum product price set to monthly average across markets, bc was missing"

format location  %-20s
save "$da/intermediate/GE_Market_Survey_ProductLevel_FINAL.dta", replace
project, creates("$da/intermediate/GE_Market_Survey_ProductLevel_FINAL.dta") preserve

********************************************
** A) Generate log-index (geometric mean) **
********************************************
preserve
sort market_id month product

foreach shares in "" "_shares" {
foreach tp in med min {
	foreach cat in cons food nondur live dur tempt durall nondurall trade nontrade {

		** generate total weight **
		bys product: egen a = min(`cat'_weight`shares')
		bys product: replace a = . if _n > 1
		egen sumweight = sum(a)

		** aggregate **
		gen pidx_`cat'_`tp'`shares' = ln(`tp'_price)*`cat'_weight`shares'/sumweight
		drop a sumweight
	}
}
}
bys market_id month: gen sumweight = sum(cons_weight)

collapse (first) district location sublocation shares_* (sum) pidx_*, by(market_id month)

project, original("$dr/MarketDataMaster_PUBLIC.dta") preserve
merge m:1 market_id using "$dr/MarketDataMaster_PUBLIC.dta"

foreach p of var pidx* {
	replace `p' = . if month < first_month_data
}

keep district  location_code  sublocation_code market_id  latitude longitude market_size subloc_in_sample hi_sat month pidx* shares_*
order district  location_code  sublocation_code market_id  latitude longitude market_size subloc_in_sample hi_sat month pidx* shares_*

xtset market_id month

rename pidx_* pidx_wKLPS_*
rename pidx_wKLPS_*_shares pidx_wGE_*

foreach weights in GE KLPS {
rename pidx_w`weights'_cons_med pidx_w`weights'_med
rename pidx_w`weights'_cons_min pidx_w`weights'_min

label var pidx_w`weights'_med "Overall price index (median, `weights' weights)"
label var pidx_w`weights'_food_med "Food price subindex (median, `weights' weights)"
label var pidx_w`weights'_nondur_med "Non-food non-durable price subindex (median, `weights' weights)"
label var pidx_w`weights'_live_med "Livestock price subindex (median, `weights' weights)"
label var pidx_w`weights'_dur_med "Durable price subindex (median, `weights' weights)"
label var pidx_w`weights'_tempt_med "Temptation price subindex (cigarettes) (median, `weights' weights)"
label var pidx_w`weights'_durall_med "Durable and livestock price subindex (median, `weights' weights)"
label var pidx_w`weights'_nondurall_med "Food and non-food non-durable price subindex (median, `weights' weights)"
label var pidx_w`weights'_trade_med "Traded (durables and non-food durables) goods price subindex (median, `weights' weights)"
label var pidx_w`weights'_nontrade_med "Non-Traded (food and livestock) goods price subindex (median, `weights' weights)"

label var pidx_w`weights'_min "Overall price index (minimum, `weights' weights)"
label var pidx_w`weights'_food_min "Food price subindex (minimum, `weights' weights)"
label var pidx_w`weights'_nondur_min "Non-food non-durable price subindex (minimum, `weights' weights)"
label var pidx_w`weights'_live_min "Livestock price subindex (minimum, `weights' weights)"
label var pidx_w`weights'_dur_min "Durable price subindex (minimum, `weights' weights)"
label var pidx_w`weights'_tempt_min "Temptation price subindex (cigarettes) (minimum, `weights' weights)"
label var pidx_w`weights'_durall_min "Durable and livestock price subindex (minimum, `weights' weights)"
label var pidx_w`weights'_nondurall_min "Food and non-food non-durable price subindex (minimum, `weights' weights)"
label var pidx_w`weights'_trade_min "Traded (durables and non-food durables) goods price subindex (minimum, `weights' weights)"
label var pidx_w`weights'_nontrade_min "Non-Traded (food and livestock) goods price subindex (minimum, `weights' weights)"
}

save "$dt/H1_idx.dta", replace
restore


******************************************************************
** B) Creating a price index based solely on non-missing values **
******************************************************************

sort market_id product month

levelsof market_id, local(markets)
levelsof month if month != tm(2014m8), local(months)

foreach shares in "" "_shares" {
	foreach tp in med min {
		bysort market_id product: gen dl_`tp'_price`shares' = ln(`tp'_price)-ln(`tp'_price[_n-1])

		foreach cat in cons food nondur live dur tempt durall nondurall trade nontrade {
			gen pidx2_`cat'_`tp'`shares' = ln(100) if month == tm(2014m8)

			foreach market in `markets' {
				foreach month in `months' {
					quietly: sum dl_`tp'_price [w=`cat'_weight`shares'] if market_id == `market' & month == `month'

					capture: replace pidx2_`cat'_`tp'`shares' = pidx2_`cat'_`tp'[_n-1] + `r(mean)' if market_id == `market' & month == `month'

					** If we cannot calculate inflation for a particular market in a particular month there is a mistake, and we set inflation to zero **
					** This occurs never unless we drop outliers**
					if _rc == 111{
						replace pidx2_`cat'_`tp'`shares' = pidx2_`cat'_`tp'[_n-1] if market_id == `market' & month == `month'
					}
				}
			}
		}
	}
}

collapse (first) district location sublocation pidx2_*, by(market_id month)

project, original("$dr/MarketDataMaster_PUBLIC.dta") preserve
merge m:1 market_id using "$dr/MarketDataMaster_PUBLIC.dta"

foreach p of var pidx2* {
	replace `p' = . if month < first_month_data
}

keep district location location_code sublocation sublocation_code market_id latitude longitude market_size subloc_in_sample hi_sat month pidx2*
order district location location_code sublocation sublocation_code market_id latitude longitude market_size subloc_in_sample hi_sat month pidx2*

xtset market_id month

rename pidx2_* pidx2_wKLPS_*
rename pidx2_wKLPS_*_shares pidx2_wGE_*

foreach weights in GE KLPS {
	rename pidx2_w`weights'_cons_med pidx2_w`weights'_med
	rename pidx2_w`weights'_cons_min pidx2_w`weights'_min

	label var pidx2_w`weights'_med "Overall price index (median, `weights' weights), Tornqvist"
	label var pidx2_w`weights'_food_med "Food price subindex (median, `weights' weights), Tornqvist"
	label var pidx2_w`weights'_nondur_med "Non-food non-durable price subindex (median, `weights' weights), Tornqvist"
	label var pidx2_w`weights'_live_med "Livestock price subindex (median, `weights' weights), Tornqvist"
	label var pidx2_w`weights'_dur_med "Durable price subindex (median, `weights' weights), Tornqvist"
	label var pidx2_w`weights'_tempt_med "Temptation price subindex (median, `weights' weights), Tornqvist"
	label var pidx2_w`weights'_durall_med "Durable and livestock price subindex (median, `weights' weights), Tornqvist"
	label var pidx2_w`weights'_nondurall_med "Food and non-food non-durable price subindex (median, `weights' weights), Tornqvist"
	label var pidx2_w`weights'_trade_med "Traded (durables and non-food durables) goods price subindex (median, `weights' weights)"
	label var pidx2_w`weights'_nontrade_med "Non-Traded (food and livestock) goods price subindex (median, `weights' weights)"


	label var pidx2_w`weights'_min "Overall price index (minimum, `weights' weights), Tornqvist"
	label var pidx2_w`weights'_food_min "Food price subindex (minimum, `weights' weights), Tornqvist"
	label var pidx2_w`weights'_nondur_min "Non-food non-durable price subindex (minimum, `weights' weights), Tornqvist"
	label var pidx2_w`weights'_live_min "Livestock price subindex (minimum, `weights' weights), Tornqvist"
	label var pidx2_w`weights'_dur_min "Durable price subindex (minimum, `weights' weights), Tornqvist"
	label var pidx2_w`weights'_tempt_min "Temptation price subindex (minimum, `weights' weights), Tornqvist"
	label var pidx2_w`weights'_durall_min "Durable and livestock price subindex (minimum, `weights' weights), Tornqvist"
	label var pidx2_w`weights'_nondurall_min "Food and non-food non-durable price subindex (minimum, `weights' weights), Tornqvist"
	label var pidx2_w`weights'_trade_min "Traded (durables and non-food durables) goods price subindex (minimum, `weights' weights)"
	label var pidx2_w`weights'_nontrade_min "Non-Traded (food and livestock) goods price subindex (minimum, `weights' weights)"
}


****************************************
** C) MERGE THE TWO DIFFERENT INDICES **
****************************************
merge 1:1 market_id month using "$dt/H1_idx.dta"
drop _merge
drop if market_id == .
keep district location location_code sublocation sublocation_code market_id latitude longitude market_size subloc_in_sample hi_sat month pidx_* pidx2*
order district location location_code sublocation sublocation_code market_id latitude longitude market_size subloc_in_sample hi_sat month pidx_* pidx2*
save "$dt/H1_idx.dta", replace
project, creates("$dt/H1_idx.dta") preserve
