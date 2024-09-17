use "$files/code/data/GE_HHLevel_ECMA.dta", clear

*** assets
* overall median
gen tot_asset = p1_assets_wins_PPP_BL + h1_10_housevalue_wins_PPP_BL + h1_11_landvalue_wins_PPP_BL
* non-land non-home net loans + home + land
    * p1_assets is already net of loans; ie. borrowing is a liability, so is subtracted from assets
egen asset_median = median(tot_asset)
gen above_p50_asset = (tot_asset >= asset_median)
gen below_p50_asset = (tot_asset < asset_median)
gen belowXelig = below_p50_asset*eligible

egen asset_p20 = pctile(tot_asset), p(20)
gen above_p20_asset = (tot_asset >= asset_p20)
gen below_p20_asset = (tot_asset < asset_p20)
gen below_p20Xelig = below_p20_asset*eligible

egen asset_quint = cut(tot_asset), group(5)
gen asset_q1 = (asset_quint==0)
gen asset_q2 = (asset_quint==1)
gen asset_q3 = (asset_quint==2)
gen asset_q4 = (asset_quint==3)
gen asset_q5 = (asset_quint==4)

* village-specific median
egen asset_median_vill = median(tot_asset), by(village_code)
gen above_p50_asset_vill = (tot_asset >= asset_median_vill)
gen below_p50_asset_vill = (tot_asset < asset_median_vill)
gen belowXelig_vill = below_p50_asset_vill*eligible

*** business revenue
egen biz_median = median(p4_totrevenue_wins_PPP_BL)
* median is 0, most have no business income
gen above_p50_biz = (p4_totrevenue_wins_PPP_BL > biz_median)
gen below_p50_biz = (p4_totrevenue_wins_PPP_BL <= biz_median)
* 36% are above-median

* note: this is the same as p4_2_nonagrevenue_wins_PPP_BL
    * so is already non-ag business revenue

save "$files/code/data/GE_HHLevel_ECMA.dta", replace