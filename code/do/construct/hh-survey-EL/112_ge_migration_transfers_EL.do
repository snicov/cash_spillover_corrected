

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
/*
 * Filename: ge_hh-welfare_migration_transfers.do
 * Description: This do file creates outcome variables related to migration and transfers (Section 16 of the endline survey).
 *
 * It is set up to be run as part of the endline build (0b_build_hh-endline1_analysis.do)
 */

** running build programs
project, original("$do/programs/run_ge_build_programs.do")
include "$do/programs/run_ge_build_programs.do"

 ** setting up to use intermediate dataset for more modular running
 project, uses("$da/intermediate/GE_HH-EL_setup.dta")

 use "$da/intermediate/GE_HH-EL_setup.dta", clear


// figure out best way to handle this going forward - lots of small datasets that are then merged back together, rather than one super-long build?

//use "$dt/GE_HH-Endline_FR_Roster_basics.dta", clear

/*******************************************/
/*   FAMILY 11: Migration and remittances  */
/*******************************************/


/*********** MIGRATION ****************/

*** 5.11.1 INDICATOR FOR LIVING IN DIFFERENT ADMIN LOCATION ***
// indicator variable 16.1.2
tab s16_q2_frmigrated

gen p11_1_frmigrated = s16_q2_frmigrated
summ p11_1_frmigrated
la var p11_1_frmigrated "P11.1 Respondent lived in different location more than 4 mos since baseline"

** CHECKS
 //Compare sublocation in sections 1, 3 and 16 - for movers, section 1 will be different than 3 and 16
 tab s1_q2b_sublocation
 destring s1_q2b_sublocation, replace

 tab s3_q1f_sublocation
 replace s3_q1f_sublocation = "77" if s3_q1f_sublocation== "NYAWARA" | s3_q1f_sublocation == "OTHER"
 destring s3_q1f_sublocation, replace

 tab s16_q4f_sublocmoved_1
 replace s16_q4f_sublocmoved_1 = "77" if s16_q4f_sublocmoved_1== "ANYIKO" | s16_q4f_sublocmoved_1 == "ASAYI" | ///
 s16_q4f_sublocmoved_1 == "JINA" | s16_q4f_sublocmoved_1 == "NYAWARA" | s16_q4f_sublocmoved_1 == "URIRI" | s16_q4f_sublocmoved_1 == "OTHER" | s16_q4f_sublocmoved_1 == "GOT_REGEA" | s16_q4f_sublocmoved_1 == "KAMBARE" | s16_q4f_sublocmoved_1 == "MARENYO" | s16_q4f_sublocmoved_1 == "NDORI" | s16_q4f_sublocmoved_1 == "URANGA"
 // are we losing information from this?
 destring s16_q4f_sublocmoved_1, replace

 tab s16_q4f_sublocmoved_2
 replace s16_q4f_sublocmoved_2 = "77" if s16_q4f_sublocmoved_2=="OTHER"
 destring s16_q4f_sublocmoved_2, replace

 tab s16_q4f_sublocmoved_3


 gen sublocation_changed = 0 if s16_q2_frmigrated != .
 replace sublocation_changed = 1 if s1_q2b_sublocation != s16_q4f_sublocmoved_1 & s16_q2_frmigrated==1
 replace sublocation_changed = 1 if s1_q2b_sublocation != s16_q4f_sublocmoved_2 & s16_q2_frmigrated==1
 tab sublocation_changed

 //Compare sublocation in section 1 and 3 among non-movers - for movers, section 1 and 3 will be the same
 gen sublocation_nonmovers = 0 if s16_q2_frmigrated != .
 replace sublocation_nonmovers = 1 if s1_q2b_sublocation == s3_q1f_sublocation & s16_q2_frmigrated==2
 tab sublocation_nonmovers

 //Time spent in each new residence based on arrival date
 gen sublocation_1 = 1 if s16_q4f_sublocmoved_1 != . & s16_q4f_sublocmoved_2==.
 gen sublocation_2 = 1 if s16_q4f_sublocmoved_2 != .

 format s1_q9a_timeanddate %td
 tab s1_q9a_timeanddate

 gen survey_date_ym=mofd(today) // update, make sure works
 format survey_date_ym %tm
 tab survey_date_ym

 gen timespent_resid_1 = survey_date_ym - s16_q5_arrivaldate_1 if sublocation_1==1
 replace timespent_resid_1 = s16_q5_arrivaldate_2 - s16_q5_arrivaldate_1 if sublocation_2 == 1
 tab timespent_resid_1
 la var timespent_resid_1 "Months spent in 1st residence moved after baseline"

 gen timespent_resid_2 = survey_date_ym - s16_q5_arrivaldate_2 if sublocation_2 == 1
 tab timespent_resid_2
 la var timespent_resid_2 "Months spent in 2nd residence moved after baseline"


*** 5.11.2 MOVED FOR WORK-RELATED REASONS (THIS IS GOING TO BE A SMALL SHARE) ***

foreach var of varlist s16_q6_whymove_1 s16_q6_whymove_2 {
 gen frmt_`var' = " "+`var'+" "
 }

gen migrate_work  = " 0 "
replace migrate_work  = " 1 " if strpos(frmt_s16_q6_whymove_1," 5 ")
replace migrate_work  = " 1 " if strpos(frmt_s16_q6_whymove_1," 6 ")
replace migrate_work  = " 1 " if strpos(frmt_s16_q6_whymove_1, " 14 ")
replace migrate_work  = " 1 " if strpos(frmt_s16_q6_whymove_2," 5 ")
replace migrate_work  = " 1 " if strpos(frmt_s16_q6_whymove_2, " 6 ")
replace migrate_work  = " 1 " if strpos(frmt_s16_q6_whymove_2, " 14 ")

destring migrate_work, replace
tab migrate_work

gen p11_2_migratework = 0 if s16_q2_frmigrated==1
replace p11_2_migratework = 1 if migrate_work==1
summ p11_2_migratework
la var p11_2_migratework "P11.2 FR migrated for work, conditional on migrating"

*** 5.11.3 RESPONDENT LIVED IN URBAN AREA FOR MORE THAN 4 MONTHS ***
 // indicator variable based on 16.1.4d NOTE: In the PAP it says 16.1.3d, but this is a typo
 // robustness check if respondent lived in Nairobi, Mombasa, Kisumu, Eldoret, Nakuru or Kampala
 forvalues i=1/3 {
 tab s16_q4d_townmoved_`i'
}

 gen p11_3_urbanarea = 0 if s16_q4d_townmoved_1 == .

 forvalues i=1/3 {
 replace p11_3_urbanarea = 1 if s16_q4d_townmoved_`i' == 2 | s16_q4d_townmoved_`i' == 3 | s16_q4d_townmoved_`i' == 4 ///
 | s16_q4d_townmoved_`i' == 5 | s16_q4d_townmoved_`i' == 6
 }

 summ p11_3_urbanarea
 la var p11_3_urbanarea "P11.3 Respondent lived in urban area for more than 4 months"

 ** Checks
 //tab number of people who report living outside Siaya at baseline among households surveyed at bl
 tab s16_q3b_frblcounty
 replace s16_q3b_frblcounty = "77" if s16_q3b_frblcounty== "other"
 destring s16_q3b_frblcounty, replace

 gen liveoutsidesiaya_bl = 0 if s16_q3b_frblcounty!=.
 replace liveoutsidesiaya_bl = 1 if s16_q3b_frblcounty!=10 & s16_q3b_frblcounty !=.
 tab liveoutsidesiaya_bl

 //compare county, sublocation and village in sections 1 and 16 - gen indicator for different values
 tab s1_q2b_sublocation
 tab s1_q2c_village
 destring s1_q2b_sublocation, replace

 tab s16_q3f_frblsubloc

* TK de-identification here
 replace s16_q3f_frblsubloc = "601040507" if s16_q3f_frblsubloc == "ANYIKO"
 replace s16_q3f_frblsubloc = "77" if s16_q3f_frblsubloc == "ASAYI"
 replace s16_q3f_frblsubloc = "77" if s16_q3f_frblsubloc == "NDERE"
 replace s16_q3f_frblsubloc = "77" if s16_q3f_frblsubloc == "RAMULA"
 replace s16_q3f_frblsubloc = "77" if s16_q3f_frblsubloc == "GOT_REGEA"
 replace s16_q3f_frblsubloc = "77" if s16_q3f_frblsubloc == "OTHER"
 replace s16_q3f_frblsubloc = "77" if s16_q3f_frblsubloc == "other"
 destring s16_q3f_frblsubloc, replace

 gen inconsistent_location = 0 if s16_q3f_frblsubloc != .
 replace inconsistent_location = 1 if s1_q2b_sublocation != s16_q3f_frblsubloc & s16_q2_frmigrated==1
 tab inconsistent_location

 //check date moved to new location - compare to survey date
tab s16_q5_arrivaldate_1
tab s16_q5_arrivaldate_2

gen diff_movedate_surveydate = survey_date_ym - s16_q5_arrivaldate_1 if sublocation_1 == 1
replace diff_movedate_surveydate = survey_date_ym - s16_q5_arrivaldate_2 if sublocation_2 == 1
tab diff_movedate_surveydate
la var diff_movedate_surveydate "Difference between move date to most recent residence and survey date"

*** 5.11.4. NET CHANGE IN NUMBER OF HOUSEHOLD MEMBERS ***
 // number of household members currently in house (other than respondent) 4.1 minus number of household members as of baseline 4.2

destring s4_q1_hhmembersbaseline, replace
tab1 s4_q1_hhmembers s4_q1_hhmembersbaseline
gen p11_4_migration_nethhchange = s4_q1_hhmembers - s4_q1_hhmembersbaseline
la var p11_4_migration_nethhchange "P11.4 Net change in number of household members"

forvalues i=1/11 {
gen out_mig_count_`i' = 1 if s4_3_q4_whygone_`i'==1
}

egen out_migration = rowtotal(out_mig_count_1 out_mig_count_2 out_mig_count_3 out_mig_count_4 ///
out_mig_count_5 out_mig_count_6 out_mig_count_7 out_mig_count_8 out_mig_count_9 ///
out_mig_count_10 out_mig_count_11)
replace out_migration = 0 if out_migration==.
summ out_migration
la var out_migration "Migration out of household"

forvalues i=1/15 {
gen in_mig_count_`i' = 1 if s4_1_q2a_memberbl_`i' == 0
}

egen in_migration = rowtotal(in_mig_count_1 in_mig_count_2 in_mig_count_3 in_mig_count_4 ///
in_mig_count_5 in_mig_count_6 in_mig_count_7 in_mig_count_8 in_mig_count_9 in_mig_count_10 ///
in_mig_count_11 in_mig_count_12 in_mig_count_13 in_mig_count_14 in_mig_count_15)
replace in_migration = 0 if in_migration==.
summ in_migration
la var in_migration "Migration into household"


gen totalchange_netmigration_alt = in_migration - out_migration
summ totalchange_netmigration_alt
la var totalchange_netmigration_alt "Net migration"

** CHECK
forvalues i=1/11 {
gen move_count_`i' = 1 if s4_3_q4_whygone_`i'!=.
}

egen moveout = rowtotal(move_count_1 move_count_2 move_count_3 move_count_4 move_count_5 ///
move_count_6 move_count_7 move_count_8 move_count_9 move_count_10 move_count_11)
replace moveout = 0 if moveout==.

gen hhnetchange_alt = in_migration - moveout

gen inconsistent_net_mig = 0
replace inconsistent_net_mig = 0 if hhnetchange_alt == 0 & p11_4_migration_nethhchange==.
replace inconsistent_net_mig = 0 if hhnetchange_alt == . & p11_4_migration_nethhchange==0
replace inconsistent_net_mig = 1 if hhnetchange_alt != p11_4_migration_nethhchange


** Checks
// compare 4.1.2a to outcome - should be the same ** Need to check this
forvalues i=1/15 {
gen hhmembers_bl_`i' = 0 if s4_1_q2a_memberbl_`i' == 0 | s4_1_q2a_memberbl_`i' == .
replace hhmembers_bl_`i' = 1 if s4_1_q2a_memberbl_`i' == 1
destring hhmembers_bl_`i', replace
tab hhmembers_bl_`i'

gen hhmembers_current_`i' = 0 if s4_1_q2a_memberbl_`i' != .
replace hhmembers_current_`i' = 1 if s4_1_q2a_memberbl_`i' == 0 | s4_1_q2a_memberbl_`i' == 1
destring hhmembers_current_`i', replace
tab hhmembers_current_`i'
}

egen hhmembers_bl_total = rowtotal (hhmembers_bl_1 hhmembers_bl_2 hhmembers_bl_3 hhmembers_bl_4 hhmembers_bl_5 hhmembers_bl_6 ///
hhmembers_bl_7 hhmembers_bl_8 hhmembers_bl_9 hhmembers_bl_10 hhmembers_bl_11 hhmembers_bl_12 hhmembers_bl_13 hhmembers_bl_14 hhmembers_bl_15)

gen blhhmembers_inconsistent = 0
replace blhhmembers_inconsistent = 1 if hhmembers_bl_total != s4_q1_hhmembersbaseline
tab blhhmembers_inconsistent
** 30% are inconsistent

gen diff_blmembers = hhmembers_bl_total - s4_q1_hhmembersbaseline if blhhmembers_inconsistent==1
tab diff_blmembers
** About 80% of differences are within 2 hh members

egen hhmembers_current_total = rowtotal(hhmembers_current_1 hhmembers_current_2 hhmembers_current_3 hhmembers_current_4 ///
hhmembers_current_5 hhmembers_current_6 hhmembers_current_7 hhmembers_current_8 hhmembers_current_9 hhmembers_current_10 ///
hhmembers_current_11 hhmembers_current_12 hhmembers_current_13 hhmembers_current_14 hhmembers_current_15)

gen hhmembers_current_inconsistent = 0
replace hhmembers_current_inconsistent = 1 if hhmembers_current_total != s4_q1_hhmembers
tab hhmembers_current_inconsistent
** Only 8 are inconsistent

gen diff_currentmembers = hhmembers_current_total - s4_q1_hhmembers if hhmembers_current_inconsistent==1
tab diff_currentmembers
* Most differences are 1 hh member

*** 5.11.5 ANY BASELINE HH MEMBER MOVES TO URBAN AREA ***
 // indicator based on 4.3.4 being migration and 4.3.7d being in an urban area
forvalues i=1/11 {
tab s4_3_q4_whygone_`i'
tab s4_3_q7d_town_`i'
}

gen p11_5_migrateurban = .

replace p11_5_migrateurban = 0 if p11_1_frmigrated==0
replace p11_5_migrateurban = 1 if p11_1_frmigrated==1

forvalues i=1/11 {
replace p11_5_migrateurban = 0 if s4_3_q4_whygone_`i'!=.
replace p11_5_migrateurban = 1 if s4_3_q4_whygone_`i'==1 & s4_3_q7d_town_`i'!=20
}

summ p11_5_migrateurban
la var p11_5_migrateurban "P11.5 Any baseline HH member migrate to urban area"


/*********** TRANSFERS ****************/


//gen s16_2_q6a_transfersrec_1_ksh = s16_2_q6a_transamtreceived_1
replace s16_2_q6a_transamtreceived_1 = s16_2_q6a_transamtreceived_1 * $ugx_kes if s16_2_q6b_transfers_fx_1 == 2




*** NET VALUE OF REMITTANCES AND GOODS SENT IN THE LAST 12 MONTHS ***
* received any transfer
tab s16_2_q1_receivedtransfer
gen any_transrec = s16_2_q1_receivedtransfer
la var any_transrec "HH received transfer from outside household" // this is designed to exclude government, we want this to exclude GD as well -- will later try to strip this out, need to replace this variable below

/* Note on survey flow: we first collect information on the 4 most recent transfer relationships. If there are more than 4, then we get information on total number and total amount received at the end. */
* how many households report 4 or fewer transfer relationships?
tab any_transrec // 85.5% have received any transfers
ren s16_2_nmbtransfersreceived s16_2_q1a_numtransrec4
la var s16_2_q1a_numtransrec4 "Number of transfer relationships (up to 4)"
tab s16_2_q1a_numtransrec4 // Of those receiving transfers, 88% have received 1-3 transfers
gen numtransrec_fewer4 = s16_2_q1a_numtransrec4 < 4

** generating total transfer received amounts over the first 4 transfers
* first, tabulating values
tab1 s16_2_q6a_transamtreceived_1 s16_2_q6a_transamtreceived_2 s16_2_q6a_transamtreceived_3 s16_2_q6a_transamtreceived_4

* recoding missing values
recode s16_2_q6a_transamtreceived_1 s16_2_q6a_transamtreceived_2 s16_2_q6a_transamtreceived_3 s16_2_q6a_transamtreceived_4 ( -99 = . )

** comparing with most recent transfer
forval i = 1 / 4 {
    tab1 s16_2_q3a_cashvalue_`i' s16_2_q3c_goodsvalue_`i'
}
recode s16_2_q3a_cashvalue_? s16_2_q3c_goodsvalue_? (-99 = .)

egen amttransrec_mostrecent = rowtotal(s16_2_q3a_cashvalue_? s16_2_q3c_goodsvalue_?), m


* item by item
forval i = 1 / 4 {
    egen transamt_mostrec`i' = rowtotal(s16_2_q3a_cashvalue_`i' s16_2_q3c_goodsvalue_`i')
    gen check`i' = transamt_mostrec`i' <= s16_2_q6a_transamtreceived_`i' if ~mi(s16_2_q6a_transamtreceived_`i')
}
summ check?
tab1 check?



** for each transfer relationship, setting to max of most recent transfer or total transfer amount to deal with the small % of cases where these disagree. As above, over 98% of obs consistent for each case
forval i = 1 / 4 {
    gen transamt_rel`i' = max(transamt_mostrec`i', s16_2_q6a_transamtreceived_`i')
}

* generating total of first 4 transfers
egen amttransrec_f4 = rowtotal(transamt_rel1 transamt_rel2 transamt_rel3 transamt_rel4), m

* check - total amount > most recent
gen check0 = amttransrec_f4 >= amttransrec_mostrecent if ~mi(amttransrec_f4) & ~mi(amttransrec_mostrecent)

tab check0 // now looking good
drop check?


/*
Wrinkle - for some earlier versions we collected last questions for everyone, regardless of how many transfers. How well do these agree?
tab version if ~mi(s16_2_q8_numtransrec) &  s16_2_q1a_numtransrec4 < 4

   version |      Freq.     Percent        Cum.
------------+-----------------------------------
         2 |         23        2.18        2.18
         3 |         28        2.65        4.83
         4 |         29        2.75        7.58
         5 |        162       15.36       22.94
         7 |         18        1.71       24.64
         8 |        537       50.90       75.55
         9 |        258       24.45      100.00
------------+-----------------------------------
     Total |      1,055      100.00
*/

count if s16_2_q1a_numtransrec4 != s16_2_q8_numtransrec & version <= 9
tab s16_2_q1a_numtransrec4 s16_2_q8_numtransrec if s16_2_q1a_numtransrec4 != s16_2_q8_numtransrec & version <= 9
gen numtransrec_diff = s16_2_q8_numtransrec - s16_2_q1a_numtransrec4 if version <= 9
gen amtransrec_diff = s16_2_q9_totamttransrec - amttransrec_f4 if version <= 9

/*

These we need to look into how to handle. 75% of these cases agree, but some large differences and unclear why that would be. Constructing in a consistent manner with the later surveys (ie ignoring these values in cases where there were fewer than 4 transfer relationships)
. summ amtransrec_diff if s16_2_q1a_numtransrec4 < 4

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
amtransrec~f |      1,056    714.3314    13407.64    -200000     242700

*/

* for those with 4 transfers, we then ask questions 8 and 9 to capture their additional amounts
count if s16_2_q1a_numtransrec4 == 4 // how many obs should we have for the next questions?
tab1 s16_2_q8_numtransrec s16_2_q9_totamttransrec if s16_2_q1a_numtransrec4 == 4
* still have (conditional on 4 in first quetion) 6% of households here reporting fewer than 4 transfer relationships. Concern is that this was interpreted as "in addition to those already listed". This matters for how treating the following parts, but for now just taking maximum.


** are amounts reported in q9 question greater than those from more detail in first 4 transfer relationships?
count if s16_2_q9_totamttransrec < amttransrec_f4 & s16_2_q1a_numtransrec4 == 4  // in general, seems reasonable to take max of totals from before


** Now, setting up total transfers received
gen amttransrec = amttransrec_f4
replace amttransrec = s16_2_q9_totamttransrec if s16_2_q1a_numtransrec4 == 4 & s16_2_q9_totamttransrec > amttransrec_f4 & ~mi(s16_2_q9_totamttransrec)
replace amttransrec = 0 if s16_2_q1_receivedtransfer == 0


* note -- this amount still needs to be corrected by removing GD and gov't transfers, as these were not intended to be included here. we do this below

* create measure that strips out GD transfers, and one that includes only transfers from other households.

tab1 s16_2_q2_relsender_?
tab1 s16_2_q2_relsender_oth_?

replace  s16_2_q2_relsender_1 = 15 if  s16_2_q2_relsender_oth_1 == "GRANDCHILDREN"
replace s16_2_q2_relsender_1 = 26 if s16_2_q2_relsender_oth_1 == "NIECE"
replace s16_2_q2_relsender_1 = 23 if s16_2_q2_relsender_oth_1 == "STEP SON"
replace s16_2_q2_relsender_1 = 23 if s16_2_q2_relsender_oth_1 == "RELATIVES DURING FUNERAL"
replace s16_2_q2_relsender_1 = 29 if inlist(s16_2_q2_relsender_oth_1 , "BABY SHOWER FRIENDS", "EMPLOYER'S  FAMILY  MEMBERS", "FORMER EMPLOYER", "FRIEND TO THE EMPLOYER")


replace s16_2_q2_relsender_2 = 9 if s16_2_q2_relsender_oth_2 == "FR IS THE SISTER"
replace s16_2_q2_relsender_2 = 24 if s16_2_q2_relsender_oth_2 == "FR'S NEIGHBOURS"
replace s16_2_q2_relsender_2 = 29 if s16_2_q2_relsender_oth_2 == "FRIENDS BABY SHOWER"
replace s16_2_q2_relsender_2 = 23 if s16_2_q2_relsender_oth_2 == "GREATGRANDMOTHER"
replace s16_2_q2_relsender_2 = 23 if s16_2_q2_relsender_oth_2 == "GROUP OF CLOSE RELATIVES"
replace s16_2_q2_relsender_2 = 23 if s16_2_q2_relsender_oth_2 == "STEP DAUGHTER" | s16_2_q2_relsender_oth_2 == "STEP SON"
replace s16_2_q2_relsender_2 = 23 if s16_2_q2_relsender_oth_2 == "STEP GRANDMOTHER"
replace s16_2_q2_relsender_2 = 29 if s16_2_q2_relsender_oth_2 == "PEOPLE WHO CAME TO HER SPOUSE BURIAL" | s16_2_q2_relsender_oth_2 == "VILLAGE  AND  FAMILY  MEMBER"

replace s16_2_q2_relsender_3 = 23 if s16_2_q2_relsender_oth_3 == "STEP DAUGHTER"
replace s16_2_q2_relsender_3 = 26 if s16_2_q2_relsender_oth_3 == "NICE"
replace s16_2_q2_relsender_3 = 29 if s16_2_q2_relsender_oth_3 == "EMPLOYER'S GRANDSON"

replace s16_2_q2_relsender_4 = 29 if s16_2_q2_relsender_oth_4 == "VILLAGE MEMBERS"

forval i=1/4 {
    replace s16_2_q2_relsender_oth_`i' = "" if s16_2_q2_relsender_oth_`i' == "."
    replace s16_2_q2_relsender_oth_`i' = trim(upper(s16_2_q2_relsender_oth_`i'))
    replace s16_2_q2_relsender_oth_`i' = "CHURCH" if strpos(s16_2_q2_relsender_oth_`i', "CHURCH")>0
    replace s16_2_q2_relsender_oth_`i' = "GIVEDIRECTLY" if inlist(s16_2_q2_relsender_oth_`i', "GIVE DIRECT", "GD", "GIVE DIRECTLY", "GIVE DIRECT (NGO)", "GIVEN DIRECT", "GIVE DIRECT ORGANISATION", "GIVE", "GIVE  DIRECT", " GIVE  DIRECTLY")
    replace s16_2_q2_relsender_oth_`i' = "GIVEDIRECTLY" if inlist(s16_2_q2_relsender_oth_`i', "NGO, GIVE DIRECTLY", "RESPONDENT ..GIVE DIRECTLY", "GIVE DIRECT ORGANISATION.", "NGO CASH TRANSFER (GIVE DIRECT)", "NGO GIVE DIRECTLY", "GIVEDIRECT", "GIVEN DIRECT", "NGO (GIVE DIRECT )", "GIVE  DIRECTLY")
    //replace s16_2_q2_relsender_oth_`i' = "GIVEDIRECTLY" if s16_2_q2_relsender_oth_`i' = "NGO" &
    replace s16_2_q2_relsender_oth_`i' = "GIVEDIRECTLY" if s16_2_q2_relsender_oth_`i' == "WHITE  SPONSORS . FR  DOESN'T  KNOW  THEM  BY  TITLE ."  | s16_2_q2_relsender_oth_`i' == "GIVE DIRECT NGO" | s16_2_q2_relsender_oth_`i' == "NGO" // all the NGO amounts I saw looked large and consistent with GD transfers

    tab1 s16_2_q2_relsender_`i' s16_2_q2_relsender_oth_`i'

    gen transrecGD_`i' = 0 if ~mi(s16_2_q2_relsender_`i')
    replace transrecGD_`i' = 1 if s16_2_q2_relsender_oth_`i' == "GIVEDIRECTLY"
    gen transrecamtGD_`i' = s16_2_q6a_transamtreceived_`i'    if transrecGD_`i' == 1
    gen transrecamtnoGD_`i' =  s16_2_q6a_transamtreceived_`i' if transrecGD_`i' == 0
    gen transrecHH_`i' = 0 if ~mi(s16_2_q2_relsender_`i')
    replace transrecHH_`i' = 1 if s16_2_q2_relsender_`i' < 39  // not counting group of people or other
    gen transrecamtHH_`i' = s16_2_q6a_transamtreceived_`i' if transrecHH_`i' == 1
}


egen gdtrans = rowmax( transrecGD_?)
tab gdtrans
tab gdtrans if eligible == 0
tab gdtrans if treat == 0

*Received any transfers from the gov't -- THESE WERE NOT SUPPOSED TO BE INCLUDED AS PART OF SVY INSTRUCTIONS. For consistency stripping these out from all households

forval i=1/4 {
    tab1 s16_2_q2_relsender_`i' s16_2_q2_relsender_oth_`i'
	gen transrecgovt_`i' = 0 if ~mi(s16_2_q2_relsender_`i')
    replace transrecgovt_`i' = 1 if s16_2_q2_relsender_oth_`i' == "AREA CDF"
    replace transrecgovt_`i' = 1 if s16_2_q2_relsender_oth_`i' == "C.D.F"
    replace transrecgovt_`i' = 1 if s16_2_q2_relsender_oth_`i' == "CDF"
    replace transrecgovt_`i' = 1 if s16_2_q2_relsender_oth_`i' == "CHILDREN FUND"
    replace transrecgovt_`i' = 1 if s16_2_q2_relsender_oth_`i' == "COMMUNITY WELFARE GROUP"
    replace transrecgovt_`i' = 1 if s16_2_q2_relsender_oth_`i' == "CONSTITUENCY DEVELOPMENT FUND FOR SCHOOL FEES"
    replace transrecgovt_`i' = 1 if s16_2_q2_relsender_oth_`i' == "COUNTY GOVERNMENT"
    replace transrecgovt_`i' = 1 if s16_2_q2_relsender_oth_`i' == "COUNTY GOVERNMENT  OF SIAYA"
    *replace transrecgovt_`i' = 1 if s16_2_q2_relsender_oth_`i' == "CURRENT MCA"
    replace transrecgovt_`i' = 1 if s16_2_q2_relsender_oth_`i' == "GOVERNMENT"
    replace transrecgovt_`i' = 1 if s16_2_q2_relsender_oth_`i' == "GOVERNMENT BURSARY"
    replace transrecgovt_`i' = 1 if s16_2_q2_relsender_oth_`i' == "GOVERNMENT INITIATIVES"
    replace transrecgovt_`i' = 1 if s16_2_q2_relsender_oth_`i' == "GOVERNMENT PROGRAMME FOR THE PHISICALLY DISADVANTAGED"
    replace transrecgovt_`i' = 1 if s16_2_q2_relsender_oth_`i' == "GOVERNOR"
    replace transrecgovt_`i' = 1 if s16_2_q2_relsender_oth_`i' == "ORPHANS AND VULNERABLE  CHILDREN FUND"
    replace transrecgovt_`i' = 1 if s16_2_q2_relsender_oth_`i' == "ORPHANS AND VULNERABLE CHILDREN'S AID"
    replace transrecgovt_`i' = 1 if s16_2_q2_relsender_oth_`i' == "UGENYA CDF"
    replace transrecgovt_`i' = 1 if s16_2_q2_relsender_oth_`i' == "CDTF"
    replace transrecgovt_`i' = 1 if s16_2_q2_relsender_oth_`i' == "CENTRAL ALEGO BURSARY KITTY"
    replace transrecgovt_`i' = 1 if s16_2_q2_relsender_oth_`i' == "GOVERNMENT  PROJECT FOR OPHARNS"
    gen transrecamtgovt_`i' = s16_2_q6a_transamtreceived_`i' if transrecgovt_`i' == 1
}
egen transrec_govt = rowmax(transrecgovt_1 transrecgovt_2 transrecgovt_3 transrecgovt_4)
replace transrec_govt = 0 if s16_2_q1_receivedtransfer == 0
la var transrec_govt "Received any transfers from the government in the last 12 months (first 4)"

egen transrecamt_govt = rowtotal(transrecamtgovt_1 transrecamtgovt_2 transrecamtgovt_3 transrecamtgovt_4), m

summ trans*_govt

egen amttransrec_noGD_translist = rowtotal(transrecamtnoGD_?), m
egen amttransrec_HH = rowtotal(transrecamtHH_?), m
egen amttransrec_GD  = rowtotal(transrecamtGD_?), m

foreach var of varlist amttransrec_noGD_translist  amttransrec_GD amttransrec_HH transrecamt_govt {
    replace `var' = 0 if `var' == . & ~mi(amttransrec)
}

* how much do we have in "bad" transfers
egen badtransfers = rowtotal(amttransrec_GD transrecamt_govt), m

ren amttransrec amttransrec_svy // this is now an uncorrected version
la var amttransrec_svy "Transfers receieved (uncorrected)"

gen amttransrec = amttransrec_svy - badtransfers // this includes any others, whereas just using the transaction list total would not. Taking off both GD & gov't

summ amttransrec_svy amttransrec amttransrec_noGD_translist amttransrec_HH amttransrec_GD // note that the latter are conditional on
la var amttransrec "Total amount of transfers received"

** winsorizing
wins_top1 amttransrec
summ amttransrec amttransrec_wins

// now - checking indicator
tab amttransrec if any_transrec == 1
replace any_transrec = 0 if amttransrec == 0



/**********************************************/
*Transfers sent

* received any transfer
tab s16_2_q10_senttransfer
gen any_transsent = s16_2_q10_senttransfer
la var any_transsent "HH sent transfer to outside household" // this is designed to exclude government, we want this to exclude GD as well -- will later try to strip this out, need to replace this variable below

/* Note on survey flow: we first collect information on the 4 most recent transfer relationships. If there are more than 4, then we get information on total number and total amount received at the end. */
* how many households report 4 or fewer transfer relationships?
tab any_transsent // 85.5% have received any transfers
ren s16_2_nmbtransferssent s16_2_q10a_numtranssent4
la var s16_2_q10a_numtranssent4 "Number of transfer sending relationships (up to 4)"
tab s16_2_q10a_numtranssent4 // Of those receiving transfers, 88% have received 1-3 transfers
gen numtranssent_fewer4 = s16_2_q10a_numtranssent4 < 4

** generating total transfer received amounts over the first 4 transfers
* first, tabulating values
tab1 s16_2_q15a_amtsent_1 s16_2_q15a_amtsent_2 s16_2_q15a_amtsent_3 s16_2_q15a_amtsent_4

* recoding missing values
recode s16_2_q15a_amtsent_1 s16_2_q15a_amtsent_2 s16_2_q15a_amtsent_3 s16_2_q15a_amtsent_4 ( -99 = . )

** comparing with most recent transfer
forval i = 1 / 4 {
    tab1 s16_2_q12a_cashvalue_`i' s16_2_q12c_goodsvalue_`i'
}
recode s16_2_q12a_cashvalue_? s16_2_q12c_goodsvalue_? (-99 = .)

egen amttranssent_mostrecent = rowtotal(s16_2_q12a_cashvalue_? s16_2_q12c_goodsvalue_?), m


* item by item
forval i = 1 / 4 {
    egen transsent_mostrec`i' = rowtotal(s16_2_q12a_cashvalue_`i' s16_2_q12c_goodsvalue_`i')
    gen check`i' = transsent_mostrec`i' <= s16_2_q15a_amtsent_`i' if ~mi(s16_2_q6a_transamtreceived_`i')
}
summ check?
tab1 check?



** for each transfer relationship, setting to max of most recent transfer or total transfer amount to deal with the small % of cases where these disagree. As above, over 98% of obs consistent for each case
forval i = 1 / 4 {
    gen transamtsent_rel`i' = max(transsent_mostrec`i', s16_2_q15a_amtsent_`i')
}

* generating total of first 4 transfers
egen amttranssent_f4 = rowtotal(transamtsent_rel1 transamtsent_rel2 transamtsent_rel3 transamtsent_rel4), m

* check - total amount > most recent
gen check0 = amttranssent_f4 >= amttranssent_mostrecent if ~mi(amttranssent_f4) & ~mi(amttranssent_mostrecent)

tab check0 // now looking good
drop check?



/*
Wrinkle - for some earlier versions we collected last questions for everyone, regardless of how many transfers. Will need to consider agreement and what to do about this (whatever we do, handle in same way as transfers received)
*/

count if s16_2_q10a_numtranssent4 != s16_2_q17_nmbtransferssent & version <= 9
tab s16_2_q10a_numtranssent4 s16_2_q17_nmbtransferssent if s16_2_q10a_numtranssent4 != s16_2_q17_nmbtransferssent & version <= 9
gen numtranssent_diff = s16_2_q17_nmbtransferssent - s16_2_q10a_numtranssent4 if version <= 9
gen amtranssent_diff = s16_2_q18_transferssent - amttranssent_f4 if version <= 9

summ amtranssent_diff if s16_2_q1a_numtransrec4 < 4

/*

These we need to look into how to handle, same as for received

. summ amtranssent_diff if s16_2_q1a_numtransrec4 < 4

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
amtranssen~f |        552    362.4257    4816.926     -94200      50400


*/

* for those with 4 transfers, we then ask questions 8 and 9 to capture their additional amounts
count if s16_2_q10a_numtranssent4 == 4 // how many obs should we have for the next questions?
tab1 s16_2_q17_nmbtransferssent s16_2_q18_transferssent if s16_2_q10a_numtranssent4 == 4

replace s16_2_q18_transferssent = s16_2_q17_nmbtransferssent if s16_2_q17_nmbtransferssent == 1200
replace s16_2_q17_nmbtransferssent = . if s16_2_q17_nmbtransferssent == 1200
* still have (conditional on 4 in first quetion) 6% of households here reporting fewer than 4 transfer relationships. Concern is that this was interpreted as "in addition to those already listed". This matters for how treating the following parts, but for now just taking maximum.


** are amounts reported in q9 question greater than those from more detail in first 4 transfer relationships?
count if s16_2_q18_transferssent < amttranssent_f4 & s16_2_q10a_numtranssent4 == 4  // in general, seems reasonable to take max of totals from before


** Now, setting up total transfers received
gen amttranssent_svy = amttranssent_f4
replace amttranssent_svy = s16_2_q18_transferssent if s16_2_q10a_numtranssent4 == 4 & s16_2_q18_transferssent > amttranssent_f4 & ~mi(s16_2_q18_transferssent)
replace amttranssent_svy = 0 if s16_2_q10_senttransfer == 0


* note -- this amount still needs to be corrected by removing GD and gov't transfers, as these were not intended to be included here

* create measure that strips out GD transfers, and one that includes only transfers from other households.

tab1 s16_2_q11_relreceiver_?
tab1 s16_2_q11_relreceiver_oth_?

forval i = 1 / 4 {
    replace s16_2_q11_relreceiver_oth_`i' = "" if s16_2_q11_relreceiver_oth_`i' == ""
}

replace s16_2_q11_relreceiver_oth_1 = "One Acre Fund" if inlist(s16_2_q11_relreceiver_oth_1, "1 acre fund ", "One  acre  fund", "One acre fund", "One hectare fund")

tab transamtsent_rel1 if s16_2_q11_relreceiver_oth_1 == "One Acre Fund"

gen badtransfers_sent = 0 if ~mi(amttranssent_svy)
replace badtransfers_sent = transamtsent_rel1 if s16_2_q11_relreceiver_oth_1 == "Give Directly" |  s16_2_q11_relreceiver_oth_1 == "One Acre Fund" // GD should be on receiving, not sending side. One Acre seems like business transaction



tab1 s16_2_q15b_transfers_fx_1 s16_2_q15b_transfers_fx_2 s16_2_q15b_transfers_fx_3 s16_2_q15b_transfers_fx_4 // these are plausibly KSH - ignoring
//using only the values reported in KSh (only 2 obs in other currencies)
list s16_2_q15a_amtsent_1 if s16_2_q15b_transfers_fx_1 == 2 // seem very KES - not changing

gen amttranssent = amttranssent_svy - badtransfers_sent
gen transferssent_neg = - amttranssent

wins_top1 amttranssent


/*** GENERATING NET TRANSFER MEASURE ***/



egen p11_6_nettransfers = rowtotal(amttransrec transferssent_neg), m
la var p11_6_nettransfers "P11.6: Net value of remittances and goods received in the last 12 months"
summ p11_6_nettransfers

wins_top1 p11_6_nettransfers
summ p11_6_nettransfers_wins
trim_top1 p11_6_nettransfers
summ p11_6_nettransfers_trim

wins_topbottom1 p11_6_nettransfers
summ p11_6_nettransfers_wins2
trim_topbottom1 p11_6_nettransfers
summ p11_6_nettransfers_trim2


** ADDITIONAL TRANSFERS BREAKDOWN **
**Total (using only the first 4 transfers reported)
egen transfersrecnoGD_f4 = rowtotal(transrecamtnoGD_1 transrecamtnoGD_2 transrecamtnoGD_3 transrecamtnoGD_4), m
replace transfersrecnoGD_f4 = 0 if s16_2_q1_receivedtransfer == 0
replace transfersrecnoGD_f4 = 0 if transfersrecnoGD_f4 == . & ~mi(amttransrec)
la var transfersrecnoGD_f4 "Transfers received in the last 12 months (first 4 transfers)"

egen transferssent_f4 = rowtotal(s16_2_q15a_amtsent_1 s16_2_q15a_amtsent_2 s16_2_q15a_amtsent_3 s16_2_q15a_amtsent_4), m
replace transferssent_f4 = 0 if s16_2_q10_senttransfer == 0
gen transferssent_f4_neg = - transferssent_f4
la var transferssent_f4 "Transfers sent in the last 12 months (first 4 transfers)"

egen nettransfersnoGD_f4 = rowtotal(transfersrecnoGD_f4 transferssent_f4_neg), m
la var nettransfersnoGD_f4 "Net transfers in the last 12 months (first 4 transfers)"

**To/from other households
gen amttransrecHH_f4 = amttransrec_HH
la var amttransrecHH_f4 "Transfers received from households in the last 12 months (first 4 transfers)"

forval i=1/4 {
    tab1 s16_2_q11_relreceiver_`i' s16_2_q11_relreceiver_oth_`i'
    gen transsentHH_`i' = 0 if ~mi(s16_2_q11_relreceiver_`i')
    replace transsentHH_`i' = 1 if s16_2_q11_relreceiver_`i' < 39  // not counting group of people or other
    replace transsentHH_`i' = 1 if s16_2_q11_relreceiver_oth_`i' == "Classmates"
    replace transsentHH_`i' = 1 if s16_2_q11_relreceiver_oth_`i' == "Fiancy"
    replace transsentHH_`i' = 1 if s16_2_q11_relreceiver_oth_`i' == "Friend"
    replace transsentHH_`i' = 1 if s16_2_q11_relreceiver_oth_`i' == "New born children"
    replace transsentHH_`i' = 1 if s16_2_q11_relreceiver_oth_`i' == "Step son"
    replace transsentHH_`i' = 1 if s16_2_q11_relreceiver_oth_`i' == "Greatgrandma"
    replace transsentHH_`i' = 1 if s16_2_q11_relreceiver_oth_`i' == "Mp's wife"
    replace transsentHH_`i' = 1 if s16_2_q11_relreceiver_oth_`i' == "Step Daughter"
    replace transsentHH_`i' = 1 if s16_2_q11_relreceiver_oth_`i' == "Other relatives"
    gen transsentamtHH_`i' = s16_2_q15a_amtsent_`i' if transsentHH_`i' == 1
}
egen amttranssentHH_f4 = rowtotal(transsentamtHH_1 transsentamtHH_2 transsentamtHH_3 transsentamtHH_4), m
replace amttranssentHH_f4 = 0 if s16_2_q10_senttransfer == 0
replace amttranssentHH_f4 = 0 if transsentHH_1 == 0 & transsentHH_2 == 0 & transsentHH_3 == 0 & transsentHH_4 == 0
gen amttranssentHH_f4_neg = - amttranssentHH_f4
la var amttranssentHH_f4 "Transfers sent to households in the last 12 months (first 4 transfers)"

egen nettransfersHH_f4 = rowtotal(amttransrecHH_f4 amttranssentHH_f4_neg), m
la var nettransfersHH_f4 "Net transfers to households in the last 12 months (first 4 transfers)"

**To/from other households within the same village
forval i=1/4 {
    ren s16_2_q4e_recsubcounty_`i' s16_2_q13e_recsubcounty_`i'
    ren s16_2_q4e_recsubcounty_oth_`i' s16_2_q13e_recsubcounty_oth_`i'
    ren s16_2_q4f_reclocation_`i' s16_2_q13f_reclocation_`i'
    ren s16_2_q4f_reclocation_oth_`i' s16_2_q13f_reclocation_oth_`i'
    ren s16_2_q4g_recsubloc_`i' s16_2_q13g_recsubloc_`i'
    ren s16_2_q4g_recsubloc_oth_`i' s16_2_q13g_recsubloc_oth_`i'
    ren s16_2_q4h_recvillage_`i' s16_2_q13h_recvillage_`i'
    ren s16_2_q4h_recvillage_oth_`i' s16_2_q13h_recvillage_oth_`i'
}

forval i=1/4 {
	gen sendervillage_`i' = s16_2_q4h_sendervillage_`i'
	replace sendervillage_`i' = "999999999999" if sendervillage_`i' == "OTHER"
	destring sendervillage_`i', replace
	gen transrecHHvill_`i' = 0 if ~mi(s16_2_q2_relsender_`i') // this is basically always filled in - setting to zero for all cases that had an i-th transfer, then setting to 1 if sender from same village
	replace transrecHHvill_`i' = 1 if sendervillage_`i' == village_code & transrecHH_`i' == 1
	//replace transrecHHvill_`i' = 0 if s16_2_q4a_sendercountry_`i' >= 2 & s16_2_q4a_sendercountry_`i' <= 4
    //replace transrecHHvill_`i' = 0 if s16_2_q4d_sendertown_`i' >= 2 & s16_2_q4d_sendertown_`i' <= 8
    gen transrecamtHHvill_`i' = s16_2_q6a_transamtreceived_`i' if transrecHHvill_`i' == 1 & transrecHH_`i' == 1
    replace transrecamtHHvill_`i' = 0 if transrecHHvill_`i' == 0 & transrecHH_`i' == 1
}
egen transrecHHvill_f4 = rowtotal(transrecamtHHvill_1 transrecamtHHvill_2 transrecamtHHvill_3 transrecamtHHvill_4), m
replace transrecHHvill_f4 = 0 if s16_2_q1_receivedtransfer == 0
replace transrecHHvill_f4 = 0 if transrecHHvill_1 == 0 & transrecHHvill_2 == 0 & transrecHHvill_3 == 0 & transrecHHvill_4 == 0
la var transrecHHvill_f4 "Transfers received from hh within village in the last 12 months (first 4)"


forval i=1/4 {
	gen recvillage_`i' = s16_2_q13h_recvillage_`i'
	replace recvillage_`i' = "999999999999" if recvillage_`i' == "OTHER"
	destring recvillage_`i', replace
	gen transsentHHvill_`i' = 0 if ~mi(s16_2_q11_relreceiver_`i')
	replace transsentHHvill_`i' = 1 if recvillage_`i' == village_code & transsentHH_`i' == 1
	//replace transsentHHvill_`i' = 0 if s16_2_q13a_reccountry_`i' >= 2 & s16_2_q13a_reccountry_`i' <= 4
    //replace transsentHHvill_`i' = 0 if s16_2_q13d_rectown_`i' >= 2 & s16_2_q13d_rectown_`i' <= 8
    gen transsentamtHHvill_`i' = s16_2_q15a_amtsent_`i' if transsentHHvill_`i' == 1 & transsentHH_`i' == 1
    replace transsentamtHHvill_`i' = 0 if transsentHHvill_`i' == 0 & transrecHH_`i' == 1
}
egen transsentHHvill_f4 = rowtotal(transsentamtHHvill_1 transsentamtHHvill_2 transsentamtHHvill_3 transsentamtHHvill_4), m
replace transsentHHvill_f4 = 0 if s16_2_q10_senttransfer == 0
replace transsentHHvill_f4 = 0 if transsentHHvill_1 == 0 & transsentHHvill_2 == 0 & transsentHHvill_3 == 0 & transsentHHvill_4 == 0
gen transsentHHvill_f4_neg = - transsentHHvill_f4
la var transsentHHvill_f4 "Transfers sent from hh within village in the last 12 months (first 4)"

egen nettransfersHHvill_f4 = rowtotal(transrecHHvill_f4 transsentHHvill_f4_neg), m
la var nettransfersHHvill_f4 "Net transfers to hh within village in the last 12 months (first 4 transfers)"

**To/from related households
forval i=1/4 {
    tab1 s16_2_q2_relsender_`i' s16_2_q2_relsender_oth_`i'
	gen transrecfamily_`i' = 0 if ~mi(s16_2_q2_relsender_`i')
    replace transrecfamily_`i' = 1 if s16_2_q2_relsender_`i' <= 23 | s16_2_q2_relsender_`i' == 35 | s16_2_q2_relsender_`i' == 36 | s16_2_q2_relsender_`i' == 38  // not counting group of people or other
    replace transrecfamily_`i' = 1 if s16_2_q2_relsender_oth_`i' == "FIVE BROTHERS"
    replace transrecfamily_`i' = 1 if s16_2_q2_relsender_oth_`i' == "GRANDCHILDREN"
    replace transrecfamily_`i' = 1 if s16_2_q2_relsender_oth_`i' == "NIECE"
    replace transrecfamily_`i' = 1 if s16_2_q2_relsender_oth_`i' == "RELATIVES DURING FUNERAL"
    replace transrecfamily_`i' = 1 if s16_2_q2_relsender_oth_`i' == "STEP SON"
    replace transrecfamily_`i' = 1 if s16_2_q2_relsender_oth_`i' == "FR IS THE SISTER"
    replace transrecfamily_`i' = 1 if s16_2_q2_relsender_oth_`i' == "GREATGRANDMOTHER"
    replace transrecfamily_`i' = 1 if s16_2_q2_relsender_oth_`i' == "GROUP OF CLOSE RELATIVES"
    replace transrecfamily_`i' = 1 if s16_2_q2_relsender_oth_`i' == "STEP DAUGHTER"
    replace transrecfamily_`i' = 1 if s16_2_q2_relsender_oth_`i' == "STEP GRANDMOTHER"
    gen transrecamtfamily_`i' = s16_2_q6a_transamtreceived_`i' if transrecfamily_`i' == 1
}
egen transrecfamily_f4 = rowtotal(transrecamtfamily_1 transrecamtfamily_2 transrecamtfamily_3 transrecamtfamily_4), m
replace transrecfamily_f4 = 0 if s16_2_q1_receivedtransfer == 0
replace transrecfamily_f4 = 0 if transrecfamily_1 == 0 & transrecfamily_2 == 0 & transrecfamily_3 == 0 & transrecfamily_4 == 0
la var transrecfamily_f4 "Transfers received to related households in the last 12 months (first 4 transfers)"

forval i=1/4 {
    tab1 s16_2_q11_relreceiver_`i' s16_2_q11_relreceiver_oth_`i'
    gen transsentfamily_`i' = 0 if ~mi(s16_2_q11_relreceiver_`i')
    replace transsentfamily_`i' = 1 if s16_2_q11_relreceiver_`i' <= 23 | s16_2_q11_relreceiver_`i' == 35 | s16_2_q11_relreceiver_`i' == 36 | s16_2_q11_relreceiver_`i' == 38  // not counting group of people or other
    replace transsentfamily_`i' = 1 if s16_2_q11_relreceiver_oth_`i' == "Step son"
    replace transsentfamily_`i' = 1 if s16_2_q11_relreceiver_oth_`i' == "Greatgrandma"
*    replace transsentfamily_`i' = 1 if s16_2_q11_relreceiver_oth_`i' == "Mp's wife" //not exactly sure what "Mp's wife" stands for
    replace transsentfamily_`i' = 1 if s16_2_q11_relreceiver_oth_`i' == "Step Daughter"
    replace transsentfamily_`i' = 1 if s16_2_q11_relreceiver_oth_`i' == "Other relatives"
    gen transsentamtfamily_`i' = s16_2_q15a_amtsent_`i' if transsentfamily_`i' == 1
}
egen transsentfamily_f4 = rowtotal(transsentamtfamily_1 transsentamtfamily_2 transsentamtfamily_3 transsentamtfamily_4), m
replace transsentfamily_f4 = 0 if s16_2_q10_senttransfer == 0
replace transsentfamily_f4 = 0 if transsentfamily_1 == 0 & transsentfamily_2 == 0 & transsentfamily_3 == 0 & transsentfamily_4 == 0
gen transsentfamily_f4_neg = - transsentfamily_f4
la var transsentfamily_f4 "Transfers sent to related households in the last 12 months (first 4 transfers)"

egen nettransfersfamily_f4 = rowtotal(transrecfamily_f4 transsentfamily_f4_neg), m
la var nettransfersfamily_f4 "Net transfers to related households in the last 12 months (first 4 transfers)"


**Checking how many households reported receiving/sending more than 4 transfers
tab s16_2_q8_numtransrec if s16_2_q8_numtransrec > 4
tab s16_2_q1_receivedtransfer

tab s16_2_q17_nmbtransferssent if s16_2_q17_nmbtransferssent > 4
tab s16_2_q10_senttransfer


**Other transfers

*Received any transfers from another country
forval i=1/4 {
	gen transrec_othcountry_`i' = 0 if ~mi(s16_2_q4a_sendercountry_`i')
	replace transrec_othcountry_`i' = 1 if s16_2_q4a_sendercountry_`i' >= 2 & s16_2_q4a_sendercountry_`i' <= 4
    gen transrecamt_othcountry_`i' = s16_2_q6a_transamtreceived_`i' if transrec_othcountry_`i' == 1
}
egen transrec_othcountry_f4 = rowtotal(transrecamt_othcountry_1 transrecamt_othcountry_2 transrecamt_othcountry_3 transrecamt_othcountry_4), m
replace transrec_othcountry_f4 = 0 if s16_2_q1_receivedtransfer == 0
replace transrec_othcountry_f4 = 0 if transrec_othcountry_1 == 0 & transrec_othcountry_2 == 0 & transrec_othcountry_3 == 0 & transrec_othcountry_4 == 0
la var transrec_othcountry_f4 "Transfers received from another country in the last 12 months (first 4)"

egen transrec_othcountry = rowtotal(transrec_othcountry_1 transrec_othcountry_2 transrec_othcountry_3 transrec_othcountry_4), m
replace transrec_othcountry = 1 if transrec_othcountry >= 1 & transrec_othcountry <= 4
replace transrec_othcountry = 0 if s16_2_q1_receivedtransfer == 0
la var transrec_othcountry "Received any transfers from another country in the last 12 months (first 4)"

*Received any transfers from a Kenyan city (Nairobi, Kisumu, etc)
forval i=1/4 {
	gen transrec_city_`i' = 0 if ~mi(s16_2_q4d_sendertown_`i')
	replace transrec_city_`i' = 1 if s16_2_q4d_sendertown_`i' >= 2 & s16_2_q4d_sendertown_`i' <= 8
}
egen transrec_city = rowtotal(transrec_city_1 transrec_city_2 transrec_city_3 transrec_city_4), m
replace transrec_city = 1 if transrec_city >= 1 & transrec_city <= 4
replace transrec_city = 0 if s16_2_q1_receivedtransfer == 0
la var transrec_city "Received any transfers from a Kenyan city in the last 12 months (first 4)"


*Received any transfers from a group (church, welfare group, etc - again, just a first pass)
forval i=1/4 {
    tab1 s16_2_q2_relsender_`i' s16_2_q2_relsender_oth_`i'
	gen transrecgroup_`i' = 0 if ~mi(s16_2_q2_relsender_`i')
    replace transrecgroup_`i' = 1 if s16_2_q2_relsender_`i' == 39
    replace transrecgroup_`i' = 1 if s16_2_q2_relsender_oth_`i' == "BABY SHOWER FRIENDS"
    replace transrecgroup_`i' = 1 if s16_2_q2_relsender_oth_`i' == "EMPLOYER'S  FAMILY  MEMBERS"
    replace transrecgroup_`i' = 1 if s16_2_q2_relsender_oth_`i' == "JUDEA WOMEN GROUP"
    replace transrecgroup_`i' = 1 if s16_2_q2_relsender_oth_`i' == "MARIWA SELF GROUP"
    replace transrecgroup_`i' = 1 if s16_2_q2_relsender_oth_`i' == "MOTORISTS GROUP"
    replace transrecgroup_`i' = 1 if s16_2_q2_relsender_oth_`i' == "NYALENYA JIKAZA WOMEN GROUP"
    replace transrecgroup_`i' = 1 if s16_2_q2_relsender_oth_`i' == "NYALO WOMEN GROUP"
    replace transrecgroup_`i' = 1 if s16_2_q2_relsender_oth_`i' == "ORPHANS SUPPORT GROUP"
    replace transrecgroup_`i' = 1 if s16_2_q2_relsender_oth_`i' == "PAP GORI WOMEN ASSOCIATION"
    replace transrecgroup_`i' = 1 if s16_2_q2_relsender_oth_`i' == "RELATIVES DURING FUNERAL"
    replace transrecgroup_`i' = 1 if s16_2_q2_relsender_oth_`i' == "ARISE AND SHINE SELF HELP GROUP"
    replace transrecgroup_`i' = 1 if s16_2_q2_relsender_oth_`i' == "FR'S NEIGHBOURS"
    replace transrecgroup_`i' = 1 if s16_2_q2_relsender_oth_`i' == "FRIENDS BABY SHOWER"
    replace transrecgroup_`i' = 1 if s16_2_q2_relsender_oth_`i' == "GROUP OF CLOSE RELATIVES"
    replace transrecgroup_`i' = 1 if s16_2_q2_relsender_oth_`i' == "KENYA WOMEN"
    replace transrecgroup_`i' = 1 if s16_2_q2_relsender_oth_`i' == "KOTWENG WOMEN GROUP"
    replace transrecgroup_`i' = 1 if s16_2_q2_relsender_oth_`i' == "LIFUNGA WOMEN GROUP"
    replace transrecgroup_`i' = 1 if s16_2_q2_relsender_oth_`i' == "MOD LIETE WOMEN GROUP"
    replace transrecgroup_`i' = 1 if s16_2_q2_relsender_oth_`i' == "NYIKASDEK WOMEN GROUP"
    replace transrecgroup_`i' = 1 if s16_2_q2_relsender_oth_`i' == "PATIENTS"
    replace transrecgroup_`i' = 1 if s16_2_q2_relsender_oth_`i' == "PEOPLE WHO CAME TO HER SPOUSE BURIAL"
    replace transrecgroup_`i' = 1 if s16_2_q2_relsender_oth_`i' == "KANG'O  WOMEN  GROUP"
    replace transrecgroup_`i' = 1 if s16_2_q2_relsender_oth_`i' == "KUTETU ACK GROUP"
    replace transrecgroup_`i' = 1 if s16_2_q2_relsender_oth_`i' == "KENYA WOMEN TRUST"
    replace transrecgroup_`i' = 1 if s16_2_q2_relsender_oth_`i' == "WENGA BODABODA YOUTH GROUP"
    replace transrecgroup_`i' = 1 if s16_2_q2_relsender_oth_`i' == "DEJE WOMEN GROU"
    replace transrecgroup_`i' = 1 if s16_2_q2_relsender_oth_`i' == "OCHUNI WOMEN GROUP"
    replace transrecgroup_`i' = 1 if s16_2_q2_relsender_oth_`i' == "VILLAGE MEMBERS"
    replace transrecgroup_`i' = 1 if s16_2_q2_relsender_oth_`i' == "WOMEN GRUOP"
    replace transrecgroup_`i' = 1 if s16_2_q2_relsender_oth_`i' == "CHURCH"
    replace transrecgroup_`i' = 1 if s16_2_q2_relsender_oth_`i' == "UKWALA HEALTH CENTRE"
    replace transrecgroup_`i' = 1 if s16_2_q2_relsender_oth_`i' == "WESTERN KENYA COMMUNITY DEVELOPMENT"
    replace transrecgroup_`i' = 1 if s16_2_q2_relsender_oth_`i' == "TB GROUP"
    replace transrecgroup_`i' = 1 if s16_2_q2_relsender_oth_`i' == "CONGREGATION"
    replace transrecgroup_`i' = 1 if s16_2_q2_relsender_oth_`i' == "VILLAGE WELFARE GROUP"
    replace transrecgroup_`i' = 1 if s16_2_q2_relsender_oth_`i' == "WASAI SELF HELP GROUP"
    replace transrecgroup_`i' = 1 if s16_2_q2_relsender_oth_`i' == "WIDOWS HELP GROUP"
    replace transrecgroup_`i' = 1 if s16_2_q2_relsender_oth_`i' == "BRIDGE ACADEMY"
    replace transrecgroup_`i' = 1 if s16_2_q2_relsender_oth_`i' == "COMMUNITY WELFARE GROUP"
    replace transrecgroup_`i' = 1 if s16_2_q2_relsender_oth_`i' == "REPENTANCE AND HIS HOLINESS"
    replace transrecgroup_`i' = 1 if s16_2_q2_relsender_oth_`i' == "WALEFARE GROUP"
    replace transrecgroup_`i' = 1 if s16_2_q2_relsender_oth_`i' == "WELFARE GROUP"
    gen transrecamtgroup_`i' = s16_2_q6a_transamtreceived_`i' if transrecgroup_`i' == 1
}

egen transrec_group = rowtotal(transrecgroup_1 transrecgroup_2 transrecgroup_3 transrecgroup_4), m
replace transrec_group = 1 if transrec_group >= 1 & transrec_group <= 4
replace transrec_group = 0 if s16_2_q1_receivedtransfer == 0
la var transrec_group "Received any transfers from a group in the last 12 months (first 4)"



foreach var of varlist /*amttransrec_noGD transferssent1 nettransfersnoGD_f4*/ nettransfersHH_f4 nettransfersHHvill_f4 nettransfersfamily_f4 transfersrecnoGD_f4 transferssent_f4 amttransrecHH_f4 amttranssentHH_f4 transrecHHvill_f4 transsentHHvill_f4 transrecfamily_f4 transsentfamily_f4 {
	wins_top1 `var'
	summ `var'_wins
}

foreach var of varlist nettransfersnoGD_f4 nettransfersHH_f4 nettransfersHHvill_f4 nettransfersfamily_f4 {
	wins_topbottom1 `var'
	summ `var'_wins2
}



/*** GENERATING PPP VALUES FOR MONETARY OUTCOMES ***/
foreach var of varlist p11_6_nettransfers* amttransrec* amttranssent* nettransfersHHvill_f4* nettransfersfamily_f4* {
    loc vl : var label `var'
    gen `var'_PPP = `var' * $ppprate
    la var `var'_PPP "`vl' (PPP)"
}


*** SAVING INTERMEDIATE DATASET ***
keep s1_hhid_key p11_* amttransrec* amttranssent* nettrans* *migrat*
save "$da/intermediate/GE_HH-EL_migration_transfers.dta", replace
project, creates("$da/intermediate/GE_HH-EL_migration_transfers.dta")
