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
/* Note: it's unclear if this will actually do anything here, or if it will need to
   be a part of each file */
project, original("$dir/do/GE_global_setup.do")
include "$dir/do/GE_global_setup.do"

// end preliminaries

* dataset dependencies
project, original("$dr/GE_ENT-SampleMaster_PUBLIC.dta")
project, uses("$da/GE_ENT-Census-EL1_Analysis_ECMA.dta")
project, uses("$da/GE_ENT-Survey-EL1_Analysis_ECMA.dta")
project, uses("$da/GE_HH-Survey-EL_AgEnterprises_Analysis_ECMA.dta")
project, uses("$da/GE_HH-ENT_Baseline_Combined.dta")

** Start with the enterprise universe census universe **
********************************************************

use "$dr/GE_ENT-SampleMaster_PUBLIC.dta", clear


** merge with endline census data **
******************************************
merge m:1 entcode_EL using "$da/GE_ENT-Census-EL1_Analysis_ECMA.dta" // all merge
drop _merge // all merge

local ent_cen_list "location_code sublocation_code village_code census_EL_date frtype_1 frtype_2 bl_tracked bl_date bl_fr_id bl_entname bl_ownername bl_frname bl_frname1 bl_frname2 bl_frname3 bl_subcounty bl_location bl_village bl_sublocation bl_operate_from bl_roof bl_walls bl_floors bl_bizcat bl_bizcatsec bl_bizcatter bl_bizcatquar bl_bizcatquint bl_bizcat_cons bl_bizcatsec_cons bl_bizcatter_cons bl_bizcatquar_cons bl_bizcatquint_cons consent operational open open_7d roof walls floors operate_from bizcat bizcat_products bizcat_nonfood bizcatsec bizcatsec_nonfood bizcatter bizcatter_nonfood bizcatquar bizcatquar_nonfood bizcatquint bizcat_cons bizcatsec_cons bizcatter_cons bizcatquar_cons bizcatquint_cons owner_f owner_resident owner_location_code owner_sublocation_code owner_village_code owner_status owner_num d_vill_new_ent n_vill_new_ent n_vill_new_ent_operate n_vill_new_ent_samecat near_mkt_subcounty near_mkt_id near_mkt_id_other d_mkt_new_ent n_mkt_new_ent n_mkt_new_ent_operate n_mkt_new_ent_samecat ent_start_year ent_start_month ent_age"
foreach v of local ent_cen_list {
	local name = substr("ENT_CEN_EL_`v'",1,32)
	cap: rename `v' `name'
}

drop ENT_CEN_EL_bl_*
keep ent_key_universe ent_id_universe ent_id_BL fr_id_BL hhid_key hh_ent_id_BL data_source_BL entcode_BL end_ent_key entcode_EL ent_rank ENT_CEN_EL* ENT_SUR_EL* HH_ENT_BL* HH_AGENT_BL* HH_AGENT_EL*
order ent_key_universe ent_id_universe ent_id_BL fr_id_BL hhid_key hh_ent_id_BL data_source_BL entcode_BL end_ent_key entcode_EL ent_rank ENT_CEN_EL* ENT_SUR_EL* HH_ENT_BL* HH_AGENT_BL* HH_AGENT_EL*

** merge with endline survey data **
************************************
merge m:1 entcode_EL using "$da/GE_ENT-Survey-EL1_Analysis_ECMA.dta"
drop _merge // all merge correctly

local ent_sur_list "location_code sublocation_code village_code surveyed survey_EL_date censused census_EL_date frtype consent open open_7d operational nonop_capital nonop_loss nonop_death nonop_crime nonop_govt nonop_mech nonop_dissol nonop_neverop nonop_unknown nonop_migrate nonop_divorce nonop_maternity nonop_educ nonop_illness nonop_otherjob nonop_date roof walls floors operate_from loc_moved location_multiple bizcat bizcat_products bizcat_nonfood bizcatsec bizcatsec_nonfood bizcatter bizcatquar bizcat_cons bizcatsec_cons bizcatter_cons bizcatquar_cons ent_start_year ent_start_month ent_age op_jan op_feb op_mar op_apr op_may op_jun op_jul op_aug op_sep op_oct op_nov op_dec op_seasonal op_monperyear op_M op_T op_W op_Th op_F op_Sa op_Su op_daysperweek op_hoursperweek op_hoursperday owner_f owner_age owner_education owner_primary owner_secondary owner_degree owner_ethnicity owner_resident owner_location_code owner_sublocation_code owner_village_code owner_status owner_num p_product p_product_orig p_qty p_unit p_price p_price_1y p_inf_1y cust_perday cust_perweek cust_svillage cust_ssublocation cust_slocation cust_stown cust_sother emp_n_tot emp_n_perm emp_n_temp emp_n_other emp_n_family emp_n_nonfamily emp_n_f emp_n_m emp_n_formal emp_n_informal emp_h_tot emp_h_perm emp_h_temp emp_h_other emp_h_family emp_h_nonfamily emp_h_f emp_h_m emp_h_formal emp_h_informal wage_total wage_h wage_m_pp rev_mon rev_year prof_mon prof_year revprof_incons inv_mon inv_year fundsource_savings fundsource_bizprof fundsource_loan_bank fundsource_loan_mlend fundsource_loan_friends fundsource_loan_relats fundsource_loan_mshwari fundsource_gift_friends fundsource_gift_relats fundsource_mergoroud fundsource_sacco fundsource_inherit fundsource_retirefund fundsource_ngoct inventory c_rent c_security electricity electricity_national electricity_genrator electricity_battery electricity_solar d_licensed d_registered d_llc d_vat t_license t_marketfees t_vat t_county t_national t_chiefs t_other s_producer s_retailer"
/*s_today_bizcon_worse s_today_bizcon_better s_today_bizcon_same s_today_bizcon s_ly_bizcon_worse s_ly_bizcon_better s_ly_bizcon_same s_ly_bizcon s_lm_bizcon_worse s_lm_bizcon_better s_lm_bizcon_same s_lm_bizcon s_fy_bizcon_worse s_fy_bizcon_better s_fy_bizcon_same s_fy_bizcon s_f3m_bizcon_worse s_f3m_bizcon_better s_f3m_bizcon_same s_f3m_bizcon s_ly_cap_lower s_ly_cap_higher s_ly_cap_same s_ly_cap s_lm_cap_lower s_lm_cap_higher s_lm_cap_same s_lm_cap s_fy_cap_lower s_fy_cap_higher s_fy_cap_same s_fy_cap s_f3m_cap_lower s_f3m_cap_higher s_f3m_cap_same s_f3m_cap s_ly_prod_othbiz_higher s_lm_prod_othbiz_higher s_ly_prod_lower s_ly_prod_higher s_ly_prod_same s_ly_prod s_lm_prod_lower s_lm_prod_higher s_lm_prod_same s_lm_prod s_fy_prod_lower s_fy_prod_higher s_fy_prod_same s_fy_prod s_f3m_prod_lower s_f3m_prod_higher s_f3m_prod_same s_f3m_prod s_ly_inventory_lower s_ly_inventory_higher s_ly_inventory_same s_ly_inventory s_lm_inventory_lower s_lm_inventory_higher s_lm_inventory_same s_lm_inventory s_fy_inventory_lower s_fy_inventory_higher s_fy_inventory_same s_fy_inventory s_f3m_inventory_lower s_f3m_inventory_higher s_f3m_inventory_same s_f3m_inventory s_ly_emp_toomany s_ly_emp_toofew s_ly_emp_justright s_ly_emp s_lm_emp_toomany s_lm_emp_toofew s_lm_emp_justright s_lm_emp s_fy_emp_toomany s_fy_emp_toofew s_fy_emp_justright s_fy_emp s_f3m_emp_toomany s_f3m_emp_toofew s_f3m_emp_justright s_f3m_emp s_ly_p_input_lower s_ly_p_input_higher s_ly_p_input_same s_ly_p_input s_lm_p_input_lower s_lm_p_input_higher s_lm_p_input_same s_lm_p_input s_fy_p_input_lower s_fy_p_input_higher s_fy_p_input_same s_fy_p_input s_f3m_p_input_lower s_f3m_p_input_higher s_f3m_p_input_same s_f3m_p_input s_ly_p_output_lower s_ly_p_output_higher s_ly_p_output_same s_ly_p_output s_lm_p_output_lower s_lm_p_output_higher s_lm_p_output_same s_lm_p_output s_fy_p_output_lower s_fy_p_output_higher s_fy_p_output_same s_fy_p_output s_f3m_p_output_lower s_f3m_p_output_higher s_f3m_p_output_same s_f3m_p_output s_ly_p_othbiz_higher s_lm_p_othbiz_higher s_ly_n_othbiz_higher s_lm_n_othbiz_higher s_expansion expfund_savings expfund_bizprof expfund_loan_bank expfund_loan_mlend expfund_loan_friends expfund_loan_relats expfund_loan_mshwari expfund_gift_friends expfund_gift_relats expfund_mergoroud expfund_sacco expfund_inherit expfund_retirefund expfund_ngoct" */
foreach v of local ent_sur_list {
	local name = substr("ENT_SUR_EL_`v'",1,32)
	cap: rename `v' `name'
}

keep ent_key_universe ent_id_universe ent_id_BL fr_id_BL hhid_key hh_ent_id_BL data_source_BL entcode_BL end_ent_key entcode_EL ent_rank ENT_CEN_EL* ENT_SUR_EL* HH_ENT_BL* HH_AGENT_BL* HH_AGENT_EL*
order ent_key_universe ent_id_universe ent_id_BL fr_id_BL hhid_key hh_ent_id_BL data_source_BL entcode_BL end_ent_key entcode_EL ent_rank ENT_CEN_EL* ENT_SUR_EL* HH_ENT_BL* HH_AGENT_BL* HH_AGENT_EL*


** merge with endline household agriculture enterprise data **
**************************************************************
ren HH_AGENT_EL HH_AGENT_SUR_EL
merge m:1 HH_AGENT_SUR_EL hhid_key using "$da/GE_HH-Survey-EL_AgEnterprises_Analysis_ECMA.dta"
drop if _merge == 2 // I don't understand why those do not merge. Perhaps a change in the hhid_key later.
ren HH_AGENT_SUR_EL HH_AGENT_EL
gen HH_AGENT_SUR_EL = (_merge == 3)
drop _merge

foreach v of var consent bizcat bizcat_cons op_hoursperweek owner_f owner_age owner_education owner_primary owner_secondary owner_degree owner_resident emp_n_tot emp_n_family wage_total rev_year prof_year revprof_incons c_total c_tools c_animalmed c_fertilizer c_irrigation c_seeds c_insurance {
	local name = substr("HH_AGENT_SUR_EL_`v'",1,32)
	cap: rename `v' `name'
}

keep ent_key_universe ent_id_universe ent_id_BL fr_id_BL hhid_key hh_ent_id_BL data_source_BL entcode_BL end_ent_key entcode_EL ent_rank ENT_CEN_EL* ENT_SUR_EL* HH_AGENT_EL* HH_AGENT_SUR_EL* HH_ENT_BL* HH_AGENT_BL*
order ent_key_universe ent_id_universe ent_id_BL fr_id_BL hhid_key hh_ent_id_BL data_source_BL entcode_BL end_ent_key entcode_EL ent_rank ENT_CEN_EL* ENT_SUR_EL* HH_AGENT_EL* HH_AGENT_SUR_EL* HH_ENT_BL* HH_AGENT_BL*


** merge with baseline data **
******************************

** non - agricultural businesses **
preserve
use "$da/GE_HH-ENT_Baseline_Combined.dta", clear
drop if HH_AGENT_CEN_BL == 1
drop HH_AGENT*
tempfile temp
save `temp'
restore

preserve
drop if HH_AGENT_BL == 1
ren HH_ENT_BL_village_code village_code
merge m:1 village_code ent_id_BL hh_ent_id_BL using `temp'
drop _merge // all match as they should
tempfile temp2
save `temp2'
restore

** agricultural businesses **
preserve
use "$da/GE_HH-ENT_Baseline_Combined.dta", clear
keep if HH_AGENT_CEN_BL == 1
keep location_code location sublocation_code sublocation village_code village ent_id_BL fr_id_BL hhid_key hh_key_BL hh_ent_id_BL data_source subcounty eligible treat hi_sat HH_AGENT_SUR*
tempfile temp3
save `temp3'
restore

preserve
keep if HH_AGENT_BL == 1
merge 1:1 hhid_key using `temp3'
drop _merge // all match as they should
tempfile temp4
save `temp4'
restore

use `temp2', clear
append using `temp4'


** Check if location changed over time **
*count if village_code != ENT_CEN_EL_village_code & ENT_CEN_EL_village_code != . // these are all in the same village
*count if village_code != ENT_SUR_EL_village_code & ENT_SUR_EL_village_code != . // some changed village. What is going on here?
** TODO: Check why villages don't match up.

keep ent_key_universe ent_id_universe ent_id_BL fr_id_BL hhid_key hh_ent_id_BL data_source_BL entcode_BL end_ent_key entcode_EL ent_rank ENT_CEN_EL* ENT_SUR_EL* HH_AGENT_EL* HH_AGENT_SUR_EL* HH_ENT_BL* ENT_CEN_BL* HH_ENT_CEN_BL* ENT_SUR_BL* HH_ENT_SUR_BL* HH_AGENT_BL* HH_AGENT_SUR_BL*
order ent_key_universe ent_id_universe ent_id_BL fr_id_BL hhid_key hh_ent_id_BL data_source_BL entcode_BL end_ent_key entcode_EL ent_rank ENT_CEN_EL* ENT_SUR_EL* HH_AGENT_EL* HH_AGENT_SUR_EL* HH_ENT_BL* ENT_CEN_BL* HH_ENT_CEN_BL* ENT_SUR_BL* HH_ENT_SUR_BL* HH_AGENT_BL* HH_AGENT_SUR_BL*

** saving dataset **
/* This dataset contains a listing of all the enterprises, but outcomes and weights still need to be added */
save "$da/intermediate/GE_ENT_BL_EL_Allcompiled.dta", replace
project, creates("$da/intermediate/GE_ENT_BL_EL_Allcompiled.dta")
