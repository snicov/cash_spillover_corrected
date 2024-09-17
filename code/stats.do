* summary statistics

use "$files/code/data/GE_HHLevel_ECMA.dta", clear

*** relationship between assets and eligiblity 
corr tot_asset eligible
* -0.31

table eligible, c(mean below_p50_asset)
* elig: 61% below-median assets
* inelig: 71% above-median, 29% below-median

table below_p50_asset, c(mean eligible)
* above-med: 51% elig
* below-med: 80% elig

*** are assets correlated with baseline business revenue?
table below_p50_asset, c(mean p4_totrevenue_wins_PPP_BL)
* yes: below-median has lower business revenue
corr tot_asset p4_totrevenue_wins_PPP_BL
* 0.1


*** outliers in own-village cash
*bro if pp_actamt_ownvill > 0.5
* three villages have total cash transfer larger than 50% of local per-capita GDP
su pp_actamt_ownvill
* avg is 0.12

*** total cash by own- vs other-village
su pp_actamt_ownvill pp_actamt_ov_0to2km if treat,d
* treated villages
* own: 0.23
* other: 0.09

* do treatment-ineligibles have more other-village cash within 0-2km than control-ineligibles?
su pp_actamt_ov_0to2km hi_sat if treat==1 & eligible==0,d
* 0.088
su pp_actamt_ov_0to2km hi_sat if treat==0 & eligible==0,d
* 0.084
ttest pp_actamt_ov_0to2km if eligible==0, by(treat)
ttest hi_sat if eligible==0, by(treat)
* treated HHs have P(hi_sat)=0.65, control HHs have P(hi_sat)=0.34
    * by construction: 
        * ~50-50 hi vs low saturation
        * 2/3 of hi-sat villages are treated
        * 1/3 of low-sat villages are treated
        * P(hi-sat|treated) = P(treated|hi-sat)*P(hi-sat)/P(treated) = 0.66*0.5 / 0.5 = 0.66
        * P(hi-sat|control) = P(control|hi-sat)*P(hi-sat)/p(control) = 0.33*0.5 / 0.5 = 0.33

*** is there more total cash in other villages within 2km than in own-village?
* use raw amounts, not share
    * MiWi: unsure about units here
su pp_actamt_ownvill_rsa pp_actamt_0to2km_rsa pp_actamt_ov_0to2km_rsa if treat==1 & eligible==0,d
* higher in own village than total; but shouldn't 0-2km include both own and other?
    * normalizing per capita?
    * what is rsa? seems to be deflated

preserve
collapse pp_actamt_ownvill_rsa pp_actamt_0to2km_rsa pp_actamt_ov_0to2km_rsa, by(village_code)
su pp_actamt_ownvill_rsa pp_actamt_0to2km_rsa pp_actamt_ov_0to2km_rsa,d
* still bigger; not some weird sample composition effect
restore 
