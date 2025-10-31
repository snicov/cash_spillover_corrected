
/** THIS .DO FILE TAKES THE COMPILED LIST OF ALL ENTERPRISES ACROSS ROUNDS AND HH
    SURVEY AND GENERATES WEIGHTS FOR THIS COMBIED DATASET **/
** AUTHOR: Dennis Egger, 20 Feb 2019
/* Preliminaries */
/* do file header */
return clear
capture project, doinfo
if (_rc==0 & !mi(r(pname))) global dir `r(pdir)'  // using -project-
else {  // running directly
    if ("${ge_dir}"=="") do `"`c(sysdir_personal)'profile.do"'
    do "${ge_dir}/do/set_environment.do"
}

* Import config - running globals
project, original("$dir/do/GE_global_setup.do")
include "$dir/do/GE_global_setup.do"

// end preliminaries

** develop enterprise survey weights **


project, uses("$da/GE_ENT-Survey-EL1_Analysis_ECMA.dta")
project, uses("$da/GE_ENT-Census-EL1_Analysis_ECMA.dta")

** setting up enterprise survey data **
***************************************
use "$da/GE_ENT-Survey-EL1_Analysis_ECMA.dta", clear

keep location_code sublocation_code village_code entcode_EL surveyed survey_EL_date censused census_EL_date operate_from bizcat bizcatsec bizcatter bizcatquar bizcatsec_cons bizcat_cons owner_resident

sort entcode_EL

codebook entcode_EL

* renaming to make clear from survey *
foreach var of varlist operate_from bizcat bizcatsec bizcatter bizcatquar bizcatsec_cons bizcat_cons owner_resident  {
    ren `var' `var'_ents
}

* saving tempfile *
tempfile ents
save `ents'


** Calculate village-level enterprise totals from endline census data **
************************************************************************
use "$da/GE_ENT-Census-EL1_Analysis_ECMA.dta", clear

keep if operational == 1 // only want operating enterprises

tab operate_from, m

merge 1:1 entcode_EL using `ents', gen(_ms) force

** how much information are we filling in on operating from? **
count if operate_from == . & ~mi(operate_from_ents)
count if operate_from != operate_from_ents & ~mi(operate_from) & ~mi(operate_from_ents )

gen win_ent = (operate_from == 1) if ~mi(operate_from)
replace win_ent = (operate_from_ents == 1) if mi(operate_from) & ~mi(operate_from_ents)

tab win_ent, m

 gen out_ent = 1 - win_ent // all others considered outside

 codebook village_code if ~mi(win_ent) // was this implemented later?


 gen miss_ent = (mi(win_ent))
  tab miss_ent


  summ win_ent if operate_from == . // using this share to allocate missing across villages
 loc win_miss_share = r(mean)

  tab1 win_ent out_ent miss_ent


  tab owner_resident
  replace owner_resident = owner_resident_ents if mi(owner_resident)

  gen own_nonres = 1 - owner_resident

 ** generating counts of those surveyed by category **
 gen surveyed_win = surveyed * win_ent
 gen surveyed_out = surveyed * out_ent

 tab1 surveyed surveyed_win surveyed_out // how many should be surveyed?

codebook entcode_EL

  /** COLLAPSING TO VILLAGE LEVEL **/
  collapse (sum) n_win_ent = win_ent (sum) n_out_ent = out_ent (sum) n_miss_ent = miss_ent (count) n_nonag_ent = entcode_EL (sum) n_own_resid = owner_resident (sum) n_own_nonresid = own_nonres (sum) surveyed_win (sum) surveyed_out, by(village_code)


 ** augmenting total category count with mean share **
 gen extra_win = n_miss_ent * `win_miss_share'
 gen extra_out = n_miss_ent * (1 - `win_miss_share')

 egen n_win_plus = rowtotal(n_win_ent extra_win), m
 egen n_out_plus = rowtotal(n_out_ent extra_out), m

 summ n_win_plus n_out_plus n_nonag_ent

 gen entweight_win_EL = 1 / (surveyed_win / n_win_plus)
 gen entweight_out_EL = 1 / (surveyed_out / n_out_plus)

 summ entweight_*EL


 ** saving village-level enterprise weights **
 tempfile villlevel_entweights
 save `villlevel_entweights'


 merge 1:n village_code using "$da/GE_ENT-Survey-EL1_Analysis_ECMA.dta", gen(_mw)

 keep entweight* entcode_EL operate_from surveyed

 gen win_ent = (operate_from == 1) if ~mi(operate_from)
 gen out_ent = 1 - win_ent

 gen entweight_EL = entweight_win_EL if win_ent == 1 & surveyed == 1
 replace entweight_EL = entweight_out_EL if out_ent == 1 & surveyed == 1

 duplicates report entcode_EL
 duplicates list entcode_EL
 drop if entcode_EL == .

 keep entcode_EL entweight_EL win_ent out_ent surveyed

 egen a = total(entweight_EL) if surveyed == 1

 summ a // this should match the total number of enterprises we expect to have from the census

// save "$da/Ent_EL_entweights.dta", replace
tempfile entsurvey_weights
save `entsurvey_weights'

** Start with full census universe **
*************************************
project, uses("$da/intermediate/GE_ENT_BL_EL_Allcompiled.dta")
use "$da/intermediate/GE_ENT_BL_EL_Allcompiled.dta", replace
cap drop entweight_EL entweight_BL

** merge in endline enterprise weights **
merge m:1 entcode_EL using `entsurvey_weights'  // all merge
order ent_key_universe ent_id_universe ent_id_BL fr_id_BL hhid_key hh_ent_id_BL data_source_BL entcode_BL end_ent_key entcode_EL entweight_EL ent_rank
drop _merge


** merge in endline household weights for farm enterprises **
preserve
project, uses("$da/GE_HH-Analysis_AllHHs.dta") preserve
use "$da/GE_HH-Analysis_AllHHs.dta", clear

** add weights ***
drop if hhid_key == ""
project, uses("$da/GE_HH-Survey_Tracking_Attrition.dta") preserve
merge 1:1 hhid_key using "$da/GE_HH-Survey_Tracking_Attrition.dta", keep(1 3)
drop if _merge == 2

keep hhid_key hhweight_EL
gen HH_AGENT_EL = 1
tempfile temp
save `temp'
restore

merge m:1 HH_AGENT_EL hhid_key using `temp'
drop if _merge == 2
drop _merge

sum hhweight_EL
return list // the weights sum to 65145 -- the number of households
// we multiply this weight by 0.964, since not quite all households have an own-farm enterprise

replace entweight_EL = hhweight_EL * 0.964 if HH_AGENT_EL == 1 & hhweight_EL != .
sum entweight_EL
return list // the weights sum to 76660 -- the total number of enterprises


** Generate baseline weights for enterprises outside the household **
*********************************************************************
gen b = 1 if data_source_BL == "ENT_Census / ENT_Survey"
gen c = 1 if ENT_SUR_BL_date != .

bys HH_ENT_BL_village_code: egen n_ent = sum(b), missing
bys HH_ENT_BL_village_code: egen n_samp = sum(c), missing

count if n_samp > n_ent & n_samp != . // this is consistent

gen entweight_BL = n_ent / n_samp if ENT_SUR_BL_date != .
sum entweight_BL // mean weight of about 1.7 which makes sense, given we sampled 2000 / 3000


** Generate baseline weights for non-ag enterprises **
******************************************************

** This is tricky, since we don't include all information from the baseline HH survey
** In fact, we only have information on 349 enterprises -- since the others did not end up in the sampling frame
** Moreover, for revenue and profits, we also use information from the census, so the sampling probability is 1 for all enterprises
** For simplicity, set weights = 1
** This will be correct for revenue and profits, but not for information from the survey only **
replace entweight_BL = 1 if data_source_BL == "HH_Census"


** Generate baseline weights for agricultural enterprises **
************************************************************
replace entweight_BL = entweight_EL if HH_AGENT_BL == 1 & hhweight_EL != .



** Order and Save **
********************
order ent_key_universe ent_id_universe ent_id_BL fr_id_BL hhid_key hh_ent_id_BL data_source_BL entcode_BL entweight_BL end_ent_key entcode_EL entweight_EL ent_rank
drop surveyed win_ent out_ent a hhweight_EL b c n_ent n_samp

sleep 3000
save "$da/intermediate/GE_ENT_BL_EL_Allcompiled_weights.dta", replace
project, creates("$da/intermediate/GE_ENT_BL_EL_Allcompiled_weights.dta")
