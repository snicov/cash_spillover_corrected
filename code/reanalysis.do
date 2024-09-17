* Michael Wiebe: my comments are denoted with 'MiWi', to distinguish from Michael Walker's comments denoted by 'MW'

* Preliminaries
return clear
capture project, doinfo
if (_rc==0 & !mi(r(pname))) global dir `r(pdir)'  // using -project-
else {  // running directly
	if ("${ge_dir}"=="") do `"`c(sysdir_personal)'profile.do"'
	do "${ge_dir}/do/set_environment.do"
}

include "$code/GE_global_setup.do"
include "$code/global_runGPS.do"

include "$code/ge_tables_mw_nonrec_table1.do"
include "$code/ge_tables_mw_nonrec_table1_elig.do"
include "$code/ge_tables_mw_nonrec_table1_rob.do"
include "$code/ge_tables_mw_table1_rf.do"
include "$code/ge_tables_mw_rec_table1.do"
include "$code/ge_tables_mw_rec_table1_rob.do"
include "$code/ge_tables_mw_rec_asset_quint.do"
include "$code/ge_tables_ext_mw_asset_het.do"
include "$code/ge_tables_ext_mw_asset_vill_het.do"
include "$code/ge_tables_ext_mw_asset_split.do"
include "$code/ge_tables_ext_mw_asset_quint.do"
include "$code/ge_tables_ext_mw_biz_split.do"
include "$code/ge_tables_ext_mw_asset_vi_split.do"
include "$code/ge_tables_ext_mw_asset_elig_split.do"
include "$code/ge_tables_ext_mw_p20asset_elig_split.do"
include "$code/ge_tables_ext_mw_asset_vill_elig_split.do"
include "$code/ge_tables_ext_mw_inelig.do"
include "$code/ge_tables_ext_mw_inelig_split.do"
include "$do/programs/ge_tables_coefs.do"

* defining variable list
* MiWi: including loans and biz revenue
local outcomelist "p2_consumption_wins_PPP nondurables_exp_wins_PPP h2_1_foodcons_12mth_wins_PPP h2_3_temptgoods_12_wins_PPP durables_exp_wins_PPP p1_assets_wins_PPP h1_10_housevalue_wins_PPP h1_11_landvalue_wins_PPP p3_totincome_wins_PPP p11_6_nettransfers_wins2_PPP tottaxpaid_all_wins_PPP totprofit_wins_PPP p3_3_wageearnings_wins_PPP h1_12_loans_wins_PPP h1_13_loansgiven_wins_PPP p4_totrevenue_wins_PPP"

* Defining variable labels *
cap program drop ge_label_variables
program define ge_label_variables
	cap la var p2_consumption_wins_PPP "\emph{Panel A: Expenditure} & & & & & \\ Household expenditure, annualized"
	cap la var nondurables_exp_wins_PPP "Non-durable expenditure, annualized"
	cap la var h2_1_foodcons_12mth_wins_PPP "\hspace{1em}Food expenditure, annualized"
	cap la var h2_3_temptgoods_12_wins_PPP "\hspace{1em}Temptation goods expenditure, annualized"
	cap la var durables_exp_wins_PPP "Durable expenditure, annualized"
	cap	la var p1_assets_wins_PPP "\emph{Panel B: Assets} & & & & \\ Assets (non-land, non-house), net borrowing"
	cap la var h1_10_housevalue_wins_PPP "Housing value"
	cap la var h1_11_landvalue_wins_PPP "Land value"
	cap la var p3_totincome_wins_PPP "\emph{Panel C: Household balance sheet} & & & & \\ Household income, annualized"
	cap la var p3_3_wageearnings_wins_PPP "Wage earnings, annualized"
	cap la var tottaxpaid_all_wins_PPP "Tax paid, annualized"
	cap la var p11_6_nettransfers_wins2_PPP "Net value of household transfers received, annualized"
	cap la var totprofit_wins_PPP "Profits (ag \& non-ag), annualized"

	cap la var p4_totrevenue_wins_PPP "Business revenue, annualized"
	
	cap la var h1_12_loans_wins_PPP "Total loan amount"
	cap la var h1_13_loansgiven_wins_PPP "Total loans given"
end

*** recipients
table_main_mw_rec_asset_quint using "$tables/recipient_assets_quintiles.tex", outcomes(`outcomelist') fdr(0) firststage(0)
table_main_mw_rec_table1 using "$tables/recip_table1.tex", outcomes(`outcomelist') fdr(0) firststage(0)
table_main_mw_rec_table1_rob using "$tables/recip_table1_rob.tex", outcomes(`outcomelist') fdr(0) firststage(0)
table_main_mw_table1_rf using "$tables/table1_rf.tex", outcomes(`outcomelist') fdr(0) firststage(0)

*** non-recipient table1
table_main_mw_nonrec_table1 using "$tables/nonrecip_table1.tex", outcomes(`outcomelist') fdr(0) firststage(0)
table_main_mw_nonrec_table1_rob using "$tables/nonrecip_table1_rob.tex", outcomes(`outcomelist') fdr(0) firststage(0)
table_main_mw_nonrec_t1_elig using "$tables/nonrecip_table1_elig.tex", outcomes(`outcomelist') fdr(0) firststage(0)

*** heterogeneity by assets
table_main_ext_mw_asset_split using "$tables/assets_split.tex", outcomes(`outcomelist') fdr(0) firststage(0)
table_main_ext_mw_asset_het using "$tables/assets.tex", outcomes(`outcomelist') fdr(0) firststage(0)
table_main_ext_mw_ass_elig_split using "$tables/assets_elig_split.tex", outcomes(`outcomelist') fdr(0) firststage(0) 
table_main_mw_p20ass_elig_split using "$tables/p20assets_elig_split.tex", outcomes(`outcomelist') fdr(0) firststage(0)
table_main_ext_mw_asset_quint using "$tables/assets_quintiles.tex", outcomes(`outcomelist') fdr(0) firststage(0)
* village-specific median
table_main_ext_mw_asset_vill_het using "$tables/asset_vill.tex", outcomes(`outcomelist') fdr(0) firststage(0)
table_main_ext_mw_asset_vi_split using "$tables/asset_vill_split.tex", outcomes(`outcomelist') fdr(0) firststage(0)
table_main_ext_mw_ass_v_el_split using "$tables/asset_vill_elig_split.tex", outcomes(`outcomelist') fdr(0) firststage(0)

*** heterogeneity by business income
table_main_ext_mw_biz_split using "$tables/biz_split.tex", outcomes(`outcomelist') fdr(0) firststage(0)

*** Table B8
table_main_ext_mw_inelig_split using "$tables/inelig_split.tex", outcomes(`outcomelist') fdr(0) firststage(0)