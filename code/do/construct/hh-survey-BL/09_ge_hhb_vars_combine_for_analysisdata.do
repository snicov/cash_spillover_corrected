/*** combining baseline intermediate datasets into master baseline dataset ***/

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

/**** looping through datasets to combine ****/
project, uses("$da/intermediate/GE_HH-BL_setup.dta") preserve
use "$da/intermediate/GE_HH-BL_setup.dta"

isid hhid_key

* come back to make this more restrictive, but right now preparedata file uses some of these variables
keep hhid_key treat eligible s1_* today s1_hhid_key village_code  
//drop s4_1_*

local i = 1
foreach stub in frbasics hhroster assets  income_revenue health_foodsec ///
            psych othoutcomes localpf laborsupply {

             project, uses("$da/intermediate/GE_HH-BL_`stub'.dta") preserve
             di "`stub'"
              merge 1:1 hhid_key using "$da/intermediate/GE_HH-BL_`stub'.dta", gen(_m`i') update replace
              local ++i
}

tab1 _m*


** keeping only needed variables
destring s1_q2c_village, replace

ren today svydate_BL

sort s1_hhid_key

gen baselined = 1

* fixing some isues for merging
destring s1_q2b_sublocation, replace

/* to do: still need to figure out what we want to keep here. Everything seems like to much, restriction below seems like too little. Erring on side of keeping more for now, but go back through KLPS files and see if I can get some inspiration. */

ren land_price* landprice*
ren land_acresowned own_land_acres
ren land_acresrentedout rentout_land_acres
ren  land_acresrented rent_land_acres
ren aglanduse aglanduse


** the following are PAP controls **
local controls "floor_elig roof_elig walls_elig eligible_baseline eligible_all_BL fr_birthday age age6 age18 age25 age40 age60 agegrp born_siaya born_city born_samevill male female single married poly widowed yearsedu yearsedu2 noschool stdschool someformschool formschool hhsize1 numworkers numadults numchildren numchild1 numchild3 numchild6 numschage hhsize2 numstudents max_age max_edu spouse_age spouse_edu num_spouse fr_under18 fr_over18 fr_selfagworker fr_worker has_children num_children num_child_school has_child_sch haschildhh highpsych age25up selfemp emp"
loc psych_ancova "a*std selfeff*" // locus of control still needs work to update - s15_5_q1_loc_15 s15_5_q2_loc_5  s15_5_q3_loc_9 s15_5_q4_loc_3  s15_5_q5_loc_10"
local assets "assets_*PPP totval*assets* agland* rent* land* own_land_acres"
local income "totprofit_*PPP child_foodsec"
local tax "tottaxpaid_all_wins_PPP"
local laborsupply "hh_hrs_ag hrsworked_ag_tot hrsworked_self_main hrsworked_emp_main"
local treat_status "treat* control* hi_sat* low_sat*"
local ident "svydate_BL s1_hhid_key s1_q2a_location s1_q2b_sublocation s1_q2c_village village_code s1_q4_respid s1_consent baselined"



** previous longer list of variables **
/*
foreach var of varlist haslatrine numrooms ownshome homevalue homevalue_trim homevalue_all homerent_mth land_ownland  land_acresowned land_agacresowned land_mthsrentedout land_rentout land_rentoutrev land_acresrented land_price land_rent land_value land_agvalue total_assets_s6 total_assets_s6_trim total_assets_s6_imp total_assets_s6_imp_trim lend_amount lend_amount_trim total_credit total_credit_trim net_asset_value  fin_mpesa fin_banking fin_sacco fin_rosca haselec floor_elig roof_elig walls_elig ag_profit ag_profit_pos selfemp_earnings selfemp_costs selfemp_profit selfemp_profit_calc selfemp_profit_comb emp_income emp_cashsal emp_earnings emp_benefits emp_hasearnings emp_hasincome total_selfemp_emp_income total_nonag_income total_income ag_nonwage_spend selfemp agsaleamt agsaleamt_trim cropsaleamt cropsaleamt_trim agspentamt agspentamt_trim cropspentamt1 cropspentamt2_trim cropspentamt cropspentamt_trim cropinputcosts aglandrentalcost aglandrentalcost_trim ag_wage_bill sellamt_poultry  sellamt_livestock  cesd_score cesd_score_z wvs_fate wvs_fate_z fatemedian wvs_trust wvs_trust_z wvs_happiness wvs_happiness_z wvs_satisfaction wvs_satisfaction_z selfeff_score selfeff_score_z semedian  loc_intscore loc_fatescore loc_othersscore a_girledu a_boyedu a_edu a_social a_income a_assets psy_index psy_index_c a_index health_self num_child_school school_supplies_allchildren avg_school_supplies_perchild schsupplies_prim_allchildren schcontrib_childsch avg_schcontrib_perchild schcontrib_childschdev schcontrib_allchild schcontrib_all total_edu_expenses_all avg_ttl_edu_exp_perchild edu_index edu_index_c yearsedu yearsedu2 noschool has_child_sch school_fees_allchildren school_fees_nonmiss avg_school_fees_perchild schfees_prim_allchildren  school_supplies_nonmiss total_edu_expenses single poly widowed  stdschool someformschool formschool  hhsize1 hhsize2 numadults numworkers numchildren numschage numstudents numchild6 numchild3 numchild1 max_age max_edu spouse_age spouse_edu num_spouse haschildhh has_children num_children sellcrops sellsag food_index_c  food_index num_meals_yest num_meals_yest_protein time_aghrs time_selfemphrs time_emphrs time_totalworked emp s6_q14_choresselfhrs fr_worker agriculture_any farm farmlivestock  any_poultry any_livestock fr_selfagworker taxrate_strictprog taxrate_weakprog taxrate_prop taxrate_weakreg taxrate_strictreg h81_supportredist{
	rename `var' `var'_BL
}
*/


** RENAMING OUTCOME & CONTROL VARIABLES **

foreach var of varlist p1* h1* p3* p4* p5* h5* p9* h9* `psych_ancova' `controls' `assets' `income' `tax' `laborsupply' {
	ren `var' `var'_BL
}


** additional edits to match with names in endline dateset **
ren h1_12_loans_wins_PPP_BL tot_loanamt_wins_PPP_BL

/*
/** come back to check and integrate these into other files **/
** land values **
wins_top1 land_price
gen landprice_wins_PPP_BL = land_price_wins * $ppprate

wins_top1 aglandrentalcost
gen aglandcost_wins_PPP_BL = aglandrentalcost_wins * $ppprate
*/





/**************************/
/*  SAVING                */
/**************************/

/* also need to figure out strategy of how baseline interacts with the rest -- keep all households and then merge? generate separate attriion dataset with a smaller number of variables that we will use for those analyseses? */

save "$da/GE_HH-Survey-BL_Analysis_AllHHs.dta", replace
project, creates("$da/GE_HH-Survey-BL_Analysis_AllHHs.dta")
