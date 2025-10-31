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
 include "$dir/do/GE_global_setup.do"
 project, original("$dir/do/GE_global_setup.do")

// end preliminaries
/*
 * Filename: ge_hh_femaleempowerment.do
 * Description: This do file constructs the outcomes described in the HH women's empowerment PAP
 *   on violence and attitudes.
 *
 * Authors: Rachel Pizatella-Haswell
 * Date created: 9 February 2018
 * Last modified: 2 May 2018 by Michael Walker, in order to incorporate into GE analysis dataset production.
 */

** loading programs
project, original("$do/programs/run_ge_build_programs.do")
include "$do/programs/run_ge_build_programs.do"

 ** setting up to use intermediate dataset for more modular running
 project, uses("$da/intermediate/GE_HH-EL_setup.dta")

 use "$da/intermediate/GE_HH-EL_setup.dta", clear


 /************************************/
 /* SECTION 18: FEMALE EMPOWERMENT */
 /************************************/

/// Recode missing
recode s18_q2b_satisfied s18_q2c_goodrelationship ///
s18_q2d_wishnorelationship s18_q2e_metexpectations s18_q2f_lovehusband ///
s18_q2g_problemsinrelationship s18_q2h_loyalhusband s18_q2i_familyhusbandgood ///
s13_3_q2a_expressopinion s13_3_q3a_toleratebeating  s13_3_q5a_sontoschool s13_3_q7a_dividehousework ///
s13_3_q6a_womanearnsmoney s13_3_q3b_toleratebeating s13_3_q5b_sontoschool s13_3_q6b_womanearnsmoney ///
s13_3_q7b_dividehousework s13_3_q1b_decisionsmen s13_3_q2b_expressopinion s13_3_q4b_beatwife ///
s13_3_q1a_decisionsmen s13_3_q4a_beatwife s13_3_q6a_womanearnsmoney (-98 = .)

recode s18_q3a_avoidchildren s18_q3b_schooling s18_q3c_sickchild ///
s18_q3d_disciplinechild s18_q3e_haveanotherchild s18_q3f_incomesave (-97 = .)

recode s18_q4a_permissionlarge s18_q4b_permissionsmall ///
s18_q4c_takesavings s18_q4d_nomoneyhousehold s18_q4e_nommoneyyourself ///
s18_q4f_refusehousehold s18_q4g_quitjob s18_q4h_financialdecisions ///
s18_q4i_knowhowyouspend s18_q4j_hidemoney s18_q4k_moneyonhimself ///
s18_q4l_threatennomoney s18_q4m_nomoneywhenangry s18_q5_pregnantnow ///
s18_q7_pregnantlast6 s18_q8_bornalive s18_q9_pregnantnext6 ///
s18_q10_husbandpregnantnext6 s18_q11_planpregnantnext6 ///
s18_q12_usingmethod s18_q13_startmethodnext6 s18_q14_husbandstartmethodnext6 ///
s18_q15_pregnantagain12 s18_q16_husbandpregnantagain12 s18_q17_planpregnantagain12 ///
s18_q18_usemethod12 s18_q19_husbandusemethod12 s18_q20a_jealous ///
s18_q20b_accusedunfaithful s18_q20c_notpermitfriends s18_q20d_limitfamily ///
s18_q20e_notrustmoney s18_q21a_humiliate s18_q21b_threatenhurt ///
s18_q21c_insult s18_q22a_push s18_q22b_slap s18_q22c_twistarm s18_q22d_punch ///
s18_q22e_beat s18_q22f_choke s18_q22g_attackweapon ///
s18_q22h_forcesex s18_q22i_forcesexacts s18_q23c_beatchild (-88 = .)

recode s13_3_q1a_decisionsmen s13_3_q1b_decisionsmen ///
s13_3_q2a_expressopinion s13_3_q2b_expressopinion s13_3_q3a_toleratebeating ///
s13_3_q3b_toleratebeating s13_3_q4a_beatwife s13_3_q4b_beatwife ///
s13_3_q5a_sontoschool s13_3_q5b_sontoschool s13_3_q6a_womanearnsmoney ///
s13_3_q6b_womanearnsmoney s13_3_q7a_dividehousework s13_3_q7b_dividehousework s13_3_q9_numbermenbeatwives (-99 = .)

recode s13_3_q8i_wifegoesout s13_3_q8ii_wifeneglectschild ///
s13_3_q8iii_wifeargues s13_3_q8iv_wiferefusesex s13_3_q8v_wifeburnsfood (998 = .) (999 = .)

recode s13_3_q9_numbermenbeatwives (-88 = .)

*** Indicators for section 18 intended and surveyed ***
destring s2_q3_gender, replace
destring s1_fo_gender, replace
destring s18_q0_present, replace
destring s5_q12_maritalstatus, replace
gen sec18_intended = .
replace sec18_intended = 1 if s2_q3_gender==2 & s1_fo_gender==2 & s18_q0_present==0 & s5_q12_maritalstatus!=1 //Why is "No" value 0?
count if sec18_intended==1

gen sec18_surveyed = .
replace sec18_surveyed = 1 if s18_q0_present==0 & s18_q1_yearscohabit !=.
count if sec18_surveyed==1

*** If answered "no" to activity, code as zero times ***
replace s18_q22aB_timespush = 0 if s18_q22a_push == 0
replace s18_q22bB_timesslap = 0 if s18_q22b_slap == 0
replace s18_q22cB_timestwistarm = 0 if s18_q22c_twistarm == 0
replace s18_q22dB_timespunch = 0 if s18_q22d_punch == 0
replace s18_q22eB_timesbeat = 0 if s18_q22e_beat == 0
replace s18_q22fB_timeschoke = 0 if s18_q22f_choke == 0
replace s18_q22gB_timesattackweapon = 0 if s18_q22g_attackweapon == 0
replace s18_q21aB_timeshumiliate = 0 if s18_q21a_humiliate == 0
replace s18_q21bB_timesthreatenhurt = 0 if s18_q21b_threatenhurt == 0
replace s18_q21cB_timesinsult = 0 if s18_q21c_insult == 0
replace s18_q22hB_timesforcesex = 0 if s18_q22h_forcesex == 0
replace s18_q22iB_timesforcesexacts = 0 if s18_q22i_forcesexacts == 0
replace s18_q20aB_timesjealous = 0 if s18_q20a_jealous == 0
replace s18_q20bB_timesaccusedunfaithful = 0 if s18_q20b_accusedunfaithful == 0
replace s18_q20cB_timesnotpermitfriends = 0 if s18_q20c_notpermitfriends == 0
replace s18_q20dB_timeslimitfamily = 0 if s18_q20d_limitfamily == 0
replace s18_q20eB_timesnotrustmoney = 0 if s18_q20e_notrustmoney == 0

/*s13_3_q1a_decisionsmen ///
s13_3_q2a_expressopinion s13_3_q3a_toleratebeating s13_3_q4a_beatwife s13_3_q5a_sontoschool ///
s13_3_q6a_womanearnsmoney s13_3_q7a_dividehousework s13_3_q8i_wifegoesout ///
s13_3_q8ii_wifeneglectschild s13_3_q8iii_wifeargues ///
s13_3_q8iv_wiferefusesex s13_3_q8v_wifeburnsfood s13_3_q1b_decisionsmen ///
s13_3_q2b_expressopinion s13_3_q3b_toleratebeating ///
s13_3_q4b_beatwife s13_3_q5b_sontoschool s13_3_q6b_womanearnsmoney s13_3_q7b_dividehousework*/


*** 3. SPOUSE PUSHED, TWISTED ARM, PUNCHED, KICKED, CHOKED, USED WEAPON ON RESPONDENT LAST 6 MONTHS ***
// at least 1 positive value 18.22 a-g
tab s18_q22a_push
tab s18_q22b_slap
tab s18_q22c_twistarm
tab s18_q22d_punch
tab s18_q22e_beat
tab s18_q22f_choke
tab s18_q22g_attackweapon
gen p8_3_harmorweapon = (s18_q22a_push==1 | s18_q22b_slap==1 | s18_q22c_twistarm==1 | ///
s18_q22d_punch==1 | s18_q22e_beat==1 | s18_q22f_choke==1 | s18_q22g_attackweapon==1) if sec18_surveyed==1
summ p8_3_harmorweapon
la var p8_3_harmorweapon "P8.3 Spouse push, twist arm, punch, kick, choke, use weapon last 6 months"

*** 4. FREQUENCY OF PHYSICAL VIOLENCE IN LAST 6 MONTHS ***
// sum 18.22 a - g (B)
tab s18_q22aB_timespush
tab s18_q22bB_timesslap
tab s18_q22cB_timestwistarm
tab s18_q22dB_timespunch
tab s18_q22eB_timesbeat
tab s18_q22fB_timeschoke
tab s18_q22gB_timesattackweapon

summ s18_q22aB_timespush s18_q22bB_timesslap s18_q22cB_timestwistarm ///
s18_q22dB_timespunch s18_q22eB_timesbeat s18_q22fB_timeschoke s18_q22gB_timesattackweapon if sec18_surveyed==1

egen freq_physicalviolence = rowtotal(s18_q22aB_timespush s18_q22bB_timesslap s18_q22cB_timestwistarm ///
s18_q22dB_timespunch s18_q22eB_timesbeat s18_q22fB_timeschoke s18_q22gB_timesattackweapon) if sec18_surveyed == 1, m
summ freq_physicalviolence

gen p8_4_freqviolence = freq_physicalviolence
la var p8_4_freqviolence "P8.4 Frequency of physical violence in the last 6 months"

*** 5. SPOUSE HUMILIATE, THREATENED HARM, INSULTED, MADE FEEL BAD ABOUT YOURSELF IN LAST 6 MONTHS ***
// at least 1 positive value 18.21a-c
tab s18_q21a_humiliate
tab s18_q21b_threatenhurt
tab s18_q21c_insult

gen p8_5_threatinsult = (s18_q21a_humiliate==1 | s18_q21b_threatenhurt==1 | s18_q21c_insult==1 & sec18_surveyed==1) if sec18_surveyed==1
summ p8_5_threatinsult
la var p8_5_threatinsult "P8.5 Spouse humiliate, threaten, insult, made feel bad last 6 months"

*** 6. FREQUENCY OF EMOTIONAL VIOLENCE LAST 6 MONTHS ***
// sum 18.21a-c (B)
tab s18_q21aB_timeshumiliate
tab s18_q21bB_timesthreatenhurt
tab s18_q21cB_timesinsult

summ s18_q21aB_timeshumiliate s18_q21bB_timesthreatenhurt s18_q21cB_timesinsult if sec18_surveyed==1

egen freq_emotviolence = rowtotal(s18_q21aB_timeshumiliate s18_q21bB_timesthreatenhurt s18_q21cB_timesinsult) if sec18_surveyed==1, m
summ freq_emotviolence

gen p8_6_freqemotviolence = freq_emotviolence
la var p8_6_freqemotviolence "P8.6 Frequency of emotional violence in the last 6 months"

*** 7. SPOUSE RAPED OR PERFORMED NON-CONSENSUAL SEXUAL ACTS ON RESPONDENT ***
// at least 1 positive value 18.22h-i
tab s18_q22h_forcesex
tab s18_q22i_forcesexacts

gen p8_7_rapeforcedsex = (s18_q22h_forcesex==1 | s18_q22i_forcesexacts==1 & sec18_surveyed==1) if sec18_surveyed==1
summ p8_7_rapeforcedsex
la var p8_7_rapeforcedsex "P8.7 Spouse raped or performed non-consensual sexual acts on respondent"

*** 8. FREQUENCY OF SEXUAL VIOLENCE IN LAST 6 MONTHS ***
//sum 18.22h-i (B)
tab s18_q22hB_timesforcesex
tab  s18_q22iB_timesforcesexacts

summ s18_q22hB_timesforcesex s18_q22iB_timesforcesexacts if sec18_surveyed==1

egen freq_sexualviolence = rowtotal(s18_q22hB_timesforcesex s18_q22iB_timesforcesexacts) if sec18_surveyed==1, m
summ freq_sexualviolence

gen p8_8_freqsexviolence = freq_sexualviolence
la var p8_8_freqsexviolence "P8.8 Frequency of sexual violence in last 6 months"

*** 9. MARITAL CONTROL ***
//sum 18.20a-e(B)
tab s18_q20aB_timesjealous
tab s18_q20bB_timesaccusedunfaithful
tab s18_q20cB_timesnotpermitfriends
tab s18_q20dB_timeslimitfamily
tab s18_q20eB_timesnotrustmoney

summ s18_q20aB_timesjealous s18_q20bB_timesaccusedunfaithful s18_q20cB_timesnotpermitfriends ///
s18_q20dB_timeslimitfamily s18_q20eB_timesnotrustmoney if sec18_surveyed==1

egen maritalcontrol = rowtotal (s18_q20aB_timesjealous s18_q20bB_timesaccusedunfaithful s18_q20cB_timesnotpermitfriends ///
s18_q20dB_timeslimitfamily s18_q20eB_timesnotrustmoney) if sec18_surveyed==1, m
summ maritalcontrol

gen p8_9_maritalcont = maritalcontrol
la var p8_9_maritalcont "P8.9 Marital control"

*** 10. MALE-ORIENTED ATTITUDES (RESPONDENT) ***

* convert to indicators - agreement with statement == 1, disagreement with statements == 0
recode s13_3_q1a_decisionsmen s13_3_q2a_expressopinion s13_3_q3a_toleratebeating ///
s13_3_q4a_beatwife s13_3_q5a_sontoschool s13_3_q6a_womanearnsmoney s13_3_q7a_dividehousework (2=0)

//reverse code 13.3.2 - this is wife should express opinion - here, disagreement corresponds to greater male-oriented attitudes
recode s13_3_q2a_expressopinion (0 = 1) (1 = 0), gen (expressopinion_neg)
recode s13_3_q7a_dividehousework (0 = 1) (1 =0), gen (dividehousework_neg)

//sum 13.3.1-7(a)
tab s13_3_q1a_decisionsmen
tab expressopinion_neg
tab s13_3_q3a_toleratebeating
tab s13_3_q4a_beatwife
tab s13_3_q5a_sontoschool
tab s13_3_q6a_womanearnsmoney
tab s13_3_q7a_dividehousework

summ s13_3_q1a_decisionsmen expressopinion_neg s13_3_q3a_toleratebeating ///
s13_3_q4a_beatwife s13_3_q5a_sontoschool s13_3_q6a_womanearnsmoney dividehousework_neg

egen maleoriented_respond = rowtotal(s13_3_q1a_decisionsmen expressopinion_neg s13_3_q3a_toleratebeating ///
s13_3_q4a_beatwife s13_3_q5a_sontoschool s13_3_q6a_womanearnsmoney dividehousework_neg), m
summ maleoriented_respond

gen p8_10_maleorientrespond = maleoriented_respond
la var p8_10_maleorientrespond "P8.10 Male-oriented attitudes (respondent)"

*** 11. JUSTIFIABILITY OF DOMESTIC VIOLENCE (RESPONDENT) ***
recode s13_3_q8i_wifegoesout s13_3_q8ii_wifeneglectschild s13_3_q8iii_wifeargues ///
s13_3_q8iv_wiferefusesex s13_3_q8v_wifeburnsfood (2=0)

//sum 13.3.8i-v
tab s13_3_q8i_wifegoesout
tab s13_3_q8ii_wifeneglectschild
tab s13_3_q8iii_wifeargues
tab s13_3_q8iv_wiferefusesex
tab s13_3_q8v_wifeburnsfood

summ s13_3_q8i_wifegoesout s13_3_q8ii_wifeneglectschild s13_3_q8iii_wifeargues ///
s13_3_q8iv_wiferefusesex s13_3_q8v_wifeburnsfood

egen domviolenceok = rowtotal (s13_3_q8i_wifegoesout s13_3_q8ii_wifeneglectschild s13_3_q8iii_wifeargues ///
s13_3_q8iv_wiferefusesex s13_3_q8v_wifeburnsfood), m
summ domviolenceok

gen p8_11_domviolence = domviolenceok
la var p8_11_domviolence "P8.11 Justifiability of domestic violence (respondent)"

*** 12. MALE-ORIENTED ATTITUDES (COMMUNITY) ***
recode s13_3_q1b_decisionsmen s13_3_q2b_expressopinion s13_3_q3b_toleratebeating ///
s13_3_q4b_beatwife s13_3_q5b_sontoschool s13_3_q6b_womanearnsmoney s13_3_q7b_dividehousework (2=0)

//reverse code 13.3.2
recode s13_3_q2b_expressopinion (1 = 0) (0 = 1), gen (commexpressopinion_neg)
recode s13_3_q7b_dividehousework (0 = 1) (1 =0), gen (commdividehousework_neg)

//sum 13.3.1-7(b)
tab s13_3_q1b_decisionsmen
tab commexpressopinion_neg
tab s13_3_q3b_toleratebeating
tab s13_3_q4b_beatwife
tab s13_3_q5b_sontoschool
tab s13_3_q6b_womanearnsmoney
tab s13_3_q7b_dividehousework

summ s13_3_q1b_decisionsmen commexpressopinion_neg s13_3_q3b_toleratebeating ///
s13_3_q4b_beatwife s13_3_q5b_sontoschool s13_3_q6b_womanearnsmoney commdividehousework_neg

egen maleoriented_comm = rowtotal (s13_3_q1b_decisionsmen commexpressopinion_neg s13_3_q3b_toleratebeating ///
s13_3_q4b_beatwife s13_3_q5b_sontoschool s13_3_q6b_womanearnsmoney commdividehousework_neg), m
summ maleoriented_comm

gen p8_12_maleorientcomm = maleoriented_comm
la var p8_12_maleorientcomm "P8.12 Male-oriented attitudes (community)"


*** 1. VIOLENCE INDEX ***
// weighted avg. of Frequency variables

tab p8_4_freqviolence
tab p8_6_freqemotviolence
tab p8_8_freqsexviolence

gen_index_vers p8_4_freqviolence p8_6_freqemotviolence p8_8_freqsexviolence, prefix(p8_1_violence_index) label("Violence index")
/*
egen p8_1_violence_index = weightave(p8_4_freqviolence p8_6_freqemotviolence p8_8_freqsexviolence), normby(elig_control_lowsat)
la var p8_1_violence_index "Violence index (std by elig, control, low-sat)"

egen p8_1_violence_index_i = weightave(p8_4_freqviolence p8_6_freqemotviolence p8_8_freqsexviolence), normby(inelig_control_lowsat)
la var p8_1_violence_index_i "Violence index (std by inelig, control, low sat)"

egen p8_1_violence_index_ec = weightave(p8_4_freqviolence p8_6_freqemotviolence p8_8_freqsexviolence), normby(eligible_control)
la var p8_1_violence_index_ec "Violence index (std by elig, control)"
*/


*** 2. ATTITUDES INDEX *** //USE when running regressions and sum stats on all observations
// weighted avg. 10, 11
tab p8_10_maleorientrespond
tab p8_11_domviolence

gen_index_vers p8_10_maleorientrespond p8_11_domviolence, prefix(p8_2_attitude_index) label("Attitudes index")
/*
egen p8_2_attitude_index = weightave(p8_10_maleorientrespond p8_11_domviolence), normby(elig_control_lowsat)
la var p8_2_attitude_index "Attitudes index (std by elig, control, low sat)"

egen p8_2_attitude_index_i = weightave(p8_10_maleorientrespond p8_11_domviolence), normby(inelig_control_lowsat)
la var p8_2_attitude_index_i "Attitudes index (std by inelig, control, low sat)"


egen p8_2_attitude_index_ec = weightave(p8_10_maleorientrespond p8_11_domviolence), normby(eligible_control)
la var p8_2_attitude_index_ec "Attitudes index (std by elig, control)"
*/


* Alternate version- only among those surveyed in section 18 // USE when running regressions and sum stats on sec 18
gen p8_10_maleorientrespond_s18 = maleoriented_respond if sec18_surveyed==1
la var p8_10_maleorientrespond_s18 "P8.10 Male-oriented attitudes (respondent), surveyed s18"

gen p8_11_domviolence_s18 = domviolenceok if sec18_surveyed==1
la var p8_11_domviolence_s18 "P8.11 Justifiability of domestic violence (respondent), surveyed s18"

gen p8_12_maleorientcomm_s18 = p8_12_maleorientcomm if sec18_surveyed == 1
la var p8_12_maleorientcomm_s18 "P8.12 Male-oriented attitudes (community), surveyed s18"

gen_index_vers p8_10_maleorientrespond_s18 p8_11_domviolence_s18, prefix(p8_2_attitude_index_s18) label("Attitudes index, surveyed s18")

/*
egen p8_2_attitude_index_s18 = weightave(p8_10_maleorientrespond_s18 p8_11_domviolence_s18), normby(elig_control_lowsat)
la var p8_2_attitude_index_s18 "Attitudes index (std by elig, control, low sat), surveyed s18"
*/

* Alternate version // USE when running regressions and sum stats on men only
gen p8_10_maleorientrespond_men = maleoriented_respond if s2_q3_gender==1
la var p8_10_maleorientrespond_men "P8.10 Male-oriented attitudes (respondent), men"

gen p8_11_domviolence_men = domviolenceok if s2_q3_gender==1
la var p8_11_domviolence_men "P8.11 Justifiability of domestic violence (respondent), men"

gen_index_vers p8_10_maleorientrespond_men p8_11_domviolence_men, prefix(p8_2_attites_index_men) label("Attitudes index among men")
/*
egen p8_2_attitude_index_men = weightave(p8_10_maleorientrespond_men p8_11_domviolence_men), normby(elig_control_lowsat)
la var p8_2_attitude_index_men "Attitudes index (std by elig, control, low sat), men"
*/

/*** PRIMARY OUTCOME: FEMALE EMPOWERMENT INDEX ***/ // USE when running regressions and sum stats on all observations
// weighted avg. 1, 2
* re-signing index variables so that higher values represent female empowerment
foreach var of varlist p8_1_violence_index_e p8_1_violence_index_ie  p8_1_violence_index ///
p8_2_attitude_index_e p8_2_attitude_index_ie p8_2_attitude_index  ///
p8_2_attitude_index_s18_e p8_2_attitude_index_s18_ie  p8_2_attitude_index_s18 {
    gen `var'_n = - `var'
}

tab1 p8_1_violence_index_*_n
tab1 p8_2_attitude_index_*_n

foreach suf in "e" "ie" {

    if "`suf'" == "e" local cond "if eligible == 1"
    if "`suf'" == "ie" local cond "if eligible == 0"

    di "`cond'"

    egen p8_femaleempower_index_`suf' = weightave(p8_1_violence_index_`suf'_n p8_2_attitude_index_`suf'_n) `cond', normby(control_lowsat)

    la var p8_femaleempower_index_`suf' "Female Empowerment index (std by control, low-sat)"

    egen p8_femaleempower_index_s18_`suf' = weightave(p8_1_violence_index_`suf'_n p8_2_attitude_index_s18_`suf'_n) `cond', normby(control_lowsat)

    la var p8_femaleempower_index_s18_`suf' "Female Empowerment index (std by control, low-sat), surveyed s18"

}
replace p8_femaleempower_index_e = . if eligible != 1
replace p8_femaleempower_index_ie = . if eligible != 0

gen     p8_femaleempower_index = p8_femaleempower_index_e if eligible == 1
replace p8_femaleempower_index = p8_femaleempower_index_ie if eligible == 0
la var p8_femaleempower_index "Female Empowerment index (std by control, low-sat)"

replace p8_femaleempower_index_s18_e = . if eligible != 1
replace p8_femaleempower_index_s18_ie = . if eligible != 0

gen     p8_femaleempower_index_s18 = p8_femaleempower_index_s18_e if eligible == 1
replace p8_femaleempower_index_s18 = p8_femaleempower_index_s18_ie if eligible == 0
la var p8_femaleempower_index_s18 "Female Empowerment index (std by control, low-sat), surveyed s18"


**** robustness check - winsorizing frequency variables and re-constructing violence index ****
foreach var of varlist p8_4_freqviolence p8_6_freqemotviolence p8_8_freqsexviolence {
    wins_top1 `var'
    summ `var'_wins
    trim_top1 `var'
    summ `var'_trim
}

egen p8_1_violence_index_wins = weightave(p8_4_freqviolence_wins p8_6_freqemotviolence_wins p8_8_freqsexviolence_wins), normby(control_lowsat)
la var p8_1_violence_index_wins "Violence index (winsorized values), std by low-sat, control"

egen p8_1_violence_index_trim = weightave(p8_4_freqviolence_trim p8_6_freqemotviolence_trim p8_8_freqsexviolence_trim), normby(control_lowsat)
la var p8_1_violence_index_trim "Violence index (trimmed values), std by low-sat, control"

foreach var of varlist p8_1_violence_index_wins p8_1_violence_index_trim {
    gen `var'_neg = - `var'
}

foreach stem in wins trim {
    egen p8_femaleempower_index_`stem' = weightave(p8_1_violence_index_`stem'_neg p8_2_attitude_index_n), normby(control_lowsat)

    la var p8_femaleempower_index_`stem' "Female Empowerment index (std by low-sat, control), `stem' violence"

    egen p8_femaleempower_index_s18_`stem' = weightave(p8_1_violence_index_`stem'_neg p8_2_attitude_index_s18_n), normby(control_lowsat)

    la var p8_femaleempower_index_s18_`stem' "Female Empowerment index (std by low-sat, control), surveyed s18, `stem' violence"
}



 *** SAVING INTERMEDIATE DATASET ***
 keep s1_hhid_key p8_* freq_*
 compress
 save "$da/intermediate/GE_HH-EL_femempower.dta", replace
 project, creates("$da/intermediate/GE_HH-EL_femempower.dta")
