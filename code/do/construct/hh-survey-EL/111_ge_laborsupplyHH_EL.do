

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
 * Filename: ge_hh_laborsupply.do
 * Description: This do file constructs the outcomes described in the HH PAP
 *   on labor supply and time use.
 *
 * Authors: Rachel Pizatella-Haswell, Michael Walker
 * Date created: 31 March 2018
 * Last modified: MW, 3 May 2018 - integrating into construct analysis do file from Rachel's folder,
                                    checking and updating her work
 * RMPH, 31 May 2018
 *
 * 26 June 2018 - MW merged changes from Rachel and MW back together into v3 - everything runs but still needs to be re-checked
 */

 ** setting up to use intermediate dataset for more modular running
 project, uses("$da/intermediate/GE_HH-EL_setup.dta")

 use "$da/intermediate/GE_HH-EL_setup.dta", clear


 /****************************************/
 /* SECTION 10: LABOR SUPPLY AND TIME USE */
 /****************************************/

** setting local for max weekly hours - topcode variables to this value **
/* to do: check with KLPS to make sure we are handling this in a consistent way with their
   survey work */

local max_weekly_hrs = 120

 *** SUMMARY MEASURE - TOTAL HOURS WORKED IN THE LAST 7 DAYS // need to check if any totals are more than the hours in 1 week
 // sum hours worked in agriculture 7.7 + self employment 8.4 when 8.3b==0 + employment 9.8 when 9.2==0
 ** NOTE: PAP says 9.7, but use 9.8 because it counts hours worked

 //sum hours worked in agriculture
 tab s7_q7_hoursworked_1
 **NOTE: 1 observation worked 150 hours in last 7 days
 tab s7_q7_hoursworked_2
 **NOTE: 1 observation worked 168 hours in last 7 days
 tab s7_q7_hoursworked_3
 **NOTE: 1 observation worked 150 hours in last 7 days
 tab s7_q7_hoursworked_4
 tab s7_q7_hoursworked_5

 //recode -99 to missing so -99 does not factor into total hours, topcode total hours per activity
 recode s7_q7_hoursworked_1 s7_q7_hoursworked_2 s7_q7_hoursworked_3 ///
 s7_q7_hoursworked_4 s7_q7_hoursworked_5 (-99 = .) (`max_weekly_hrs' / max = `max_weekly_hrs')


 egen hrsworked_ag_tot = rowtotal(s7_q7_hoursworked_1 s7_q7_hoursworked_2 ///
 s7_q7_hoursworked_3 s7_q7_hoursworked_4 s7_q7_hoursworked_5), m
 replace hrsworked_ag_tot = 0 if s7_q1_selfag==2
 summ hrsworked_ag_tot
 la var hrsworked_ag_tot "FR total hours worked in ag, last 7 days"


/*** SELF EMPLOYMENT ***/

 //tabulating self-employment hours
 tab s8_q4_hrsworked_1
 tab s8_q4_hrsworked_2
 tab s8_q4_hrsworked_3
 tab s8_q4_hrsworked_4
 tab s8_q4_hrsworked_5

 ** for whom are we collecting information? hours worked based on decision-maker **
 tab1 s8_q3b_decisionmakerrosnum_?

 // generating indicators for the FR being a decisionmaker (ie 0's in the decisionmaker choices.)
// first, generating an indicator if FR is listed as a decisonmaker. second, generating an indicator if
// FR is sole decisionmaker
cap tostring s8_q3b_decisionmakerrosnum_?, replace
forval i = 1 / 5 {
    gen decisionmaker_fr`i' = (strpos(s8_q3b_decisionmakerrosnum_`i', "0") > 0 ) if ~mi(s8_q3b_decisionmakerrosnum_`i')
    la var decisionmaker_fr`i' "FR decisionmaker (incl joint) for enterprise `i'"

    gen decisionmaker_fr_nojoint`i' = (s8_q3b_decisionmakerrosnum_`i' == "0") if ~mi(s8_q3b_decisionmakerrosnum_`i')
    la var decisionmaker_fr_nojoint`i' "FR sole decisionmaker for enterprise `i'"

    gen fr_selfemp_hrs`i'           = s8_q4_hrsworked_`i' if decisionmaker_fr`i' == 1
    gen fr_selfemp_hrs_nojoint`i'   = s8_q4_hrsworked_`i' if decisionmaker_fr_nojoint`i' == 1

}

* recoding missing hours and top coding
recode fr_selfemp_hrs? fr_selfemp_hrs_nojoint? (-99 = .) (`max_weekly_hrs'/ max = `max_weekly_hrs')

// generate total hours in self-employment (main measure, including joint decisionmaking)
/* to do: figure out how calculate expression was displaying this for cases of joint decisionmaking - this will determine which measure should be the focus */
 egen hrsworked_self_main = rowtotal(fr_selfemp_hrs?), m

 forvalues i=1/5 {
 replace hrsworked_self_main = 0 if s8_q3b_decisionmakerrosnum_`i'!= " " & hrsworked_self_main==.
 }

 la var hrsworked_self_main "FR hours worked in self-employment, all enterprises (main measure)"
 summ hrsworked_self_main
 **NOTE: Max = 252 with 3 observations > 168, likely because of the few high values noted above

 //-> use this measure to calculate overall hours worked when respondent is sole decision-maker
 egen hrsworked_self_nojoint = rowtotal(fr_selfemp_hrs_nojoint?), m
 la var hrsworked_self_nojoint "FR hours worked in self-employment, all enterprises (sole decision member)"
 summ hrsworked_self_nojoint

/*** employment hours ***/
 //generate total hours worked in employment
 tab s9_q8_hrsworked_1
 **NOTE: 6 obs over 150 hours in last week
 tab s9_q8_hrsworked_2
 **NOTE: 1 obs 150 hours in last week
 tab s9_q8_hrsworked_3
 tab s9_q8_hrsworked_4

//recoding missing values and topcoding at max hours
recode s9_q8_hrsworked_? (-99 = .) (`max_weekly_hrs' / max = `max_weekly_hrs')
summ s9_q8_hrsworked_? // check that topcoding is working properly

 forvalues i = 1/4 {
     gen fr_emp_hrs`i' = s9_q8_hrsworked_`i' if s9_q2_hhmemberemp_`i'==0
 }

 egen hrsworked_emp_main = rowtotal(fr_emp_hrs?), m // Need to recheck?

 forvalues i=1/4 {
 replace  hrsworked_emp_main = 0 if s9_q2_hhmemberemp_`i' != . & hrsworked_emp_main==.
 }

 la var hrsworked_emp_main "FR hours worked in employment, last 7 days"
 summ hrsworked_emp_main
 **NOTE: 3 observations >150 hours likely because of a few high values noted above

// topcoding combined values
summ hrsworked_ag_tot hrsworked_self_main hrsworked_self_nojoint hrsworked_emp_main
recode hrsworked_ag_tot hrsworked_self_main hrsworked_self_nojoint hrsworked_emp_main (`max_weekly_hrs' / max = `max_weekly_hrs')


 //generate total hours worked in employment and self-employment
 egen p10_hrsworked = rowtotal(hrsworked_ag_tot hrsworked_emp_main hrsworked_self_main)
 summ p10_hrsworked
 **NOTE: ~.2 percent above 150 hours in last week, likely because of the high values noted above
 la var p10_hrsworked "P10 Summary Measure - Respondent's total hours worked in last 7 days"


recode p10_hrsworked (`max_weekly_hrs' / max = `max_weekly_hrs')
summ p10_hrsworked // checking topcoding worked fine

// adding topcoding note
foreach var of varlist p10_hrsworked hrsworked_ag_tot hrsworked_self_main hrsworked_self_nojoint hrsworked_emp_main {
    notes : Topcoded at `max_weekly_hrs'
}



 *** 1. NO. OF MONTHS RESPONDENT WORKED IN SELF-EMPLOYMENT OR EMPLOYMENT THE LAST 12 MONTHS
 //sum self employed months worked 8.5 when 8.3b==0 + employed months worked 9.3 when 9.2 == 0 + seasonal months worked 9.7a when 9.2==0

 //generate number of months worked in self employed enterprise
 forval i = 1 / 5 {
    tab s8_q5_monthsworked_`i' if decisionmaker_fr`i' == 1
 }

 /**NOTE: Some variables have values 1 (which is meant to be coded for all months) + other options **/
 /* to do: we want to recode these so they are consistent with section 9, whereby 13 is all months, and then months correspond to numbers */

/* there are two types of problems in these variables:
  i) respondents selected "all of the last 12 months" as well as additional months
  ii) respondents selected some months plus don't know values

  proceed as follows - first, generating easy-to-use variables that are recoded from the split variables.
*/

cap tostring s8_q5_monthsworked_?, replace // need strings for next part to work
forval i = 1 / 5 {
    split s8_q5_monthsworked_`i'
    local nvars = `r(nvars)' // number of new variables
    destring s8_q5_monthsworked_`i'?, replace
    recode s8_q5_monthsworked_`i'? (99 = -99) (1 = 13) ///
            (2 = 1) (3 = 2) (4 = 3) (5 = 4) (6 = 5) (7 = 6) (8 = 7) (9 = 8) ///
            (10 = 9) (11 = 10) (12 = 11) (13 = 12)
    if `nvars' > 9 {
        destring s8_q5_monthsworked_`i'??, replace
        recode s8_q5_monthsworked_`i'?? (99 = -99) (1 = 13) ///
                (2 = 1) (3 = 2) (4 = 3) (5 = 4) (6 = 5) (7 = 6) (8 = 7) (9 = 8) ///
                (10 = 9) (11 = 10) (12 = 11) (13 = 12)
    }
    local j = 1
    foreach mon in jan feb mar apr may jun jul aug sep oct nov dec all dk {
        gen s8_q5_monthsworked_`i'_`mon' = 0 if ~mi(s8_q5_monthsworked_`i')
        local cond "s8_q5_monthsworked_`i'1 == `j'"
        forval k = 2 / `nvars' {
            local cond "`cond' | s8_q5_monthsworked_`i'`k' == `j'"
        }
        replace s8_q5_monthsworked_`i'_`mon' = 1 if `cond'
        local ++j
        if `j' > 13 {
            local j = -99
		tab s8_q5_monthsworked_`i'_`mon'
        }
    }
    drop s8_q5_monthsworked_`i'?
    if `nvars' > 9 {
        drop s8_q5_monthsworked_`i'??
    }
}

forval i=1/5 {
ren s8_q5_monthsworked_`i'_jan s8_q5_monthsworked_`i'_1
ren s8_q5_monthsworked_`i'_feb s8_q5_monthsworked_`i'_2
ren s8_q5_monthsworked_`i'_mar s8_q5_monthsworked_`i'_3
ren s8_q5_monthsworked_`i'_apr s8_q5_monthsworked_`i'_4
ren s8_q5_monthsworked_`i'_may s8_q5_monthsworked_`i'_5
ren s8_q5_monthsworked_`i'_jun s8_q5_monthsworked_`i'_6
ren s8_q5_monthsworked_`i'_jul s8_q5_monthsworked_`i'_7
ren s8_q5_monthsworked_`i'_aug s8_q5_monthsworked_`i'_8
ren s8_q5_monthsworked_`i'_sep s8_q5_monthsworked_`i'_9
ren s8_q5_monthsworked_`i'_oct s8_q5_monthsworked_`i'_10
ren s8_q5_monthsworked_`i'_nov s8_q5_monthsworked_`i'_11
ren s8_q5_monthsworked_`i'_dec s8_q5_monthsworked_`i'_12
}


// to start - ignore conflicts with DK, use all in case of month conflicts
gen monthsworked_selfemp = 12   if  s8_q5_monthsworked_1_all == 1 | ///
                                    s8_q5_monthsworked_2_all == 1 | ///
                                    s8_q5_monthsworked_3_all == 1 | ///
                                    s8_q5_monthsworked_4_all == 1 | ///
                                    s8_q5_monthsworked_5_all == 1

 //ensure months are only counted once for self-employment enterprises -- is that what we're doing here?
forval i = 1/12 {
    gen selfemp_mthsworked_`i' = 1       if  s8_q5_monthsworked_1_`i' == 1 | ///
                                                s8_q5_monthsworked_2_`i' == 1 | ///
                                                s8_q5_monthsworked_3_`i' == 1 | ///
                                                s8_q5_monthsworked_4_`i' == 1 | ///
                                                s8_q5_monthsworked_5_`i' == 1
}

egen tmp_selfemp_mthsworked = rowtotal(selfemp_mthsworked_? selfemp_mthsworked_??), m
replace monthsworked_selfemp = tmp_selfemp_mthsworked if mi(monthsworked_selfemp)


egen fr_selfemp_decision_any = rowmax(decisionmaker_fr?)

tab monthsworked_selfemp if fr_selfemp_decision_any == 1, m // these look generally reasonable

 //Option 2 - ignore "all months" responses when conflicts with selected months
 gen monthsworked_selfemp_v2 = tmp_selfemp_mthsworked
 replace monthsworked_selfemp_v2 = 12 if mi(monthsworked_selfemp_v2) & (s8_q5_monthsworked_1_all == 1 | ///
                                     s8_q5_monthsworked_2_all == 1 | ///
                                     s8_q5_monthsworked_3_all == 1 | ///
                                     s8_q5_monthsworked_4_all == 1 | ///
                                     s8_q5_monthsworked_5_all == 1)

// option 3:  set any DK response to missing
gen monthsworked_selfemp_v3 = monthsworked_selfemp
replace monthsworked_selfemp_v3 = .     if  s8_q5_monthsworked_1_dk == 1 | ///
                                            s8_q5_monthsworked_2_dk == 1 | ///
                                            s8_q5_monthsworked_3_dk == 1 | ///
                                            s8_q5_monthsworked_4_dk == 1 | ///
                                            s8_q5_monthsworked_5_dk == 1

*** employment months worked ***
forval i = 1 / 4 {
    gen fr_job`i' = (s9_q2_hhmemberemp_`i' == 0) if ~mi(s9_q2_hhmemberemp_`i')
    la var fr_job`i' "FR working job `i'"
    tab fr_job`i'
}

egen fr_workingpay = rowmax(fr_job?)
la var fr_workingpay "FR employed / working for pay, cond hh emp"


 //generate number of months worked as survey date - 9.3 for full-time or part-time
 tab s9_q3_datestart_1
 gen s9_q3_datestart_1_num = date(s9_q3_datestart_1, "MDY")
 format s9_q3_datestart_1_num %td

 tab s9_q3_datestart_2
 gen s9_q3_datestart_2_num = date(s9_q3_datestart_2, "MDY")
 format s9_q3_datestart_2_num %td

 tab s9_q3_datestart_3
 gen s9_q3_datestart_3_num = date(s9_q3_datestart_3, "MDY")
 format s9_q3_datestart_3_num %td

 tab s9_q3_datestart_4
 gen s9_q3_datestart_4_num = date(s9_q3_datestart_4, "MDY")
 format s9_q3_datestart_4_num %td

 tab s1_q9a_timeanddate
 gen s1_q8_date = s1_q9a_timeanddate
 format s1_q8_date %td

 //generate indicator variables for which months worked in employment
 gen workmonths_emp_m_11 = 1 if s9_q3_datestart_1_num<= td(01jan2016) & s1_q8_date>= td(01jan2016)
 replace workmonths_emp_m_11 = 1 if s9_q3_datestart_1_num<= td(01jan2017) & s1_q8_date>= td(01jan2017)
 replace workmonths_emp_m_11 = 1 if s9_q3_datestart_1_num<= td(01jan2018) & s1_q8_date>= td(01jan2018)
 gen workmonths_emp_m_12 = 1 if s9_q3_datestart_1_num<= td(01feb2016) & s1_q8_date>= td(01feb2016)
 replace workmonths_emp_m_12 = 1 if s9_q3_datestart_1_num<= td(01feb2017) & s1_q8_date>= td(01feb2017)
 replace workmonths_emp_m_12 = 1 if s9_q3_datestart_1_num<= td(01feb2018) & s1_q8_date>= td(01feb2018)
 gen workmonths_emp_m_13 = 1 if s9_q3_datestart_1_num<= td(01mar2016) & s1_q8_date>= td(01mar2016)
 replace workmonths_emp_m_13 = 1 if s9_q3_datestart_1_num<= td(01mar2017) & s1_q8_date>= td(01mar2017)
 replace workmonths_emp_m_13 = 1 if s9_q3_datestart_1_num<= td(01mar2018) & s1_q8_date>= td(01mar2018)
 gen workmonths_emp_m_14 = 1 if s9_q3_datestart_1_num<= td(01apr2016) & s1_q8_date>= td(01apr2016)
 replace workmonths_emp_m_14 = 1 if s9_q3_datestart_1_num<= td(01apr2017) & s1_q8_date>= td(01apr2017)
 gen workmonths_emp_m_15 = 1 if s9_q3_datestart_1_num<= td(01may2016) & s1_q8_date>= td(01may2016)
 replace workmonths_emp_m_15 = 1 if s9_q3_datestart_1_num<= td(01may2017) & s1_q8_date>= td(01may2017)
 gen workmonths_emp_m_16 = 1 if s9_q3_datestart_1_num<= td(01jun2016) & s1_q8_date>= td(01jun2016)
 replace workmonths_emp_m_16 = 1 if s9_q3_datestart_1_num<= td(01jun2017) & s1_q8_date>= td(01jun2017)
 gen workmonths_emp_m_17 = 1 if s9_q3_datestart_1_num<= td(01jul2016) & s1_q8_date>= td(01jul2016)
 replace workmonths_emp_m_17 = 1 if s9_q3_datestart_1_num<= td(01jul2017) & s1_q8_date>= td(01jul2017)
 gen workmonths_emp_m_18 = 1 if s9_q3_datestart_1_num<= td(01aug2016) & s1_q8_date>= td(01aug2016)
 replace workmonths_emp_m_18 = 1 if s9_q3_datestart_1_num<= td(01aug2017) & s1_q8_date>= td(01aug2017)
 gen workmonths_emp_m_19 = 1 if s9_q3_datestart_1_num<= td(01sep2016) & s1_q8_date>= td(01sep2016)
 replace workmonths_emp_m_19 = 1 if s9_q3_datestart_1_num<= td(01sep2017) & s1_q8_date>= td(01sep2017)
 gen workmonths_emp_m_110 = 1 if s9_q3_datestart_1_num<= td(01oct2016) & s1_q8_date>= td(01oct2016)
 replace workmonths_emp_m_110 = 1 if s9_q3_datestart_1_num<= td(01oct2017) & s1_q8_date>= td(01oct2017)
 gen workmonths_emp_m_111 = 1 if s9_q3_datestart_1_num<= td(01nov2016) & s1_q8_date>= td(01nov2016)
 replace workmonths_emp_m_111 = 1 if s9_q3_datestart_1_num<= td(01nov2017) & s1_q8_date>= td(01nov2017)
 gen workmonths_emp_m_112 = 1 if s9_q3_datestart_1_num<= td(01dec2016) & s1_q8_date>= td(01dec2016)
 replace workmonths_emp_m_112 = 1 if s9_q3_datestart_1_num<= td(01dec2017) & s1_q8_date>= td(01dec2017)

 gen workmonths_emp_m_21 = 1 if s9_q3_datestart_2_num<= td(01jan2016) & s1_q8_date>= td(01jan2016)
 replace workmonths_emp_m_21 = 1 if s9_q3_datestart_2_num<= td(01jan2017) & s1_q8_date>= td(01jan2017)
 replace workmonths_emp_m_21 = 1 if s9_q3_datestart_2_num<= td(01jan2018) & s1_q8_date>= td(01jan2018)
 gen workmonths_emp_m_22 = 1 if s9_q3_datestart_2_num<= td(01feb2016) & s1_q8_date>= td(01feb2016)
 replace workmonths_emp_m_22 = 1 if s9_q3_datestart_2_num<= td(01feb2017) & s1_q8_date>= td(01feb2017)
 replace workmonths_emp_m_22 = 1 if s9_q3_datestart_2_num<= td(01feb2018) & s1_q8_date>= td(01feb2018)
 gen workmonths_emp_m_23 = 1 if s9_q3_datestart_2_num<= td(01mar2016) & s1_q8_date>= td(01mar2016)
 replace workmonths_emp_m_23 = 1 if s9_q3_datestart_2_num<= td(01mar2017) & s1_q8_date>= td(01mar2017)
 replace workmonths_emp_m_23 = 1 if s9_q3_datestart_2_num<= td(01mar2018) & s1_q8_date>= td(01mar2018)
 gen workmonths_emp_m_24 = 1 if s9_q3_datestart_2_num<= td(01apr2016) & s1_q8_date>= td(01apr2016)
 replace workmonths_emp_m_24 = 1 if s9_q3_datestart_2_num<= td(01apr2017) & s1_q8_date>= td(01apr2017)
 gen workmonths_emp_m_25 = 1 if s9_q3_datestart_2_num<= td(01may2016) & s1_q8_date>= td(01may2016)
 replace workmonths_emp_m_25 = 1 if s9_q3_datestart_2_num<= td(01may2017) & s1_q8_date>= td(01may2017)
 gen workmonths_emp_m_26 = 1 if s9_q3_datestart_2_num<= td(01jun2016) & s1_q8_date>= td(01jun2016)
 replace workmonths_emp_m_26 = 1 if s9_q3_datestart_2_num<= td(01jun2017) & s1_q8_date>= td(01jun2017)
 gen workmonths_emp_m_27 = 1 if s9_q3_datestart_2_num<= td(01jul2016) & s1_q8_date>= td(01jul2016)
 replace workmonths_emp_m_27 = 1 if s9_q3_datestart_2_num<= td(01jul2017) & s1_q8_date>= td(01jul2017)
 gen workmonths_emp_m_28 = 1 if s9_q3_datestart_2_num<= td(01aug2016) & s1_q8_date>= td(01aug2016)
 replace workmonths_emp_m_28 = 1 if s9_q3_datestart_2_num<= td(01aug2017) & s1_q8_date>= td(01aug2017)
 gen workmonths_emp_m_29 = 1 if s9_q3_datestart_2_num<= td(01sep2016) & s1_q8_date>= td(01sep2016)
 replace workmonths_emp_m_29 = 1 if s9_q3_datestart_2_num<= td(01sep2017) & s1_q8_date>= td(01sep2017)
 gen workmonths_emp_m_210 = 1 if s9_q3_datestart_2_num<= td(01oct2016) & s1_q8_date>= td(01oct2016)
 replace workmonths_emp_m_210 = 1 if s9_q3_datestart_2_num<= td(01oct2017) & s1_q8_date>= td(01oct2017)
 gen workmonths_emp_m_211 = 1 if s9_q3_datestart_2_num<= td(01nov2016) & s1_q8_date>= td(01nov2016)
 replace workmonths_emp_m_211 = 1 if s9_q3_datestart_2_num<= td(01nov2017) & s1_q8_date>= td(01nov2017)
 gen workmonths_emp_m_212 = 1 if s9_q3_datestart_2_num<= td(01dec2016) & s1_q8_date>= td(01dec2016)
 replace workmonths_emp_m_212 = 1 if s9_q3_datestart_2_num<= td(01dec2017) & s1_q8_date>= td(01dec2017)

  gen workmonths_emp_m_31 = 1 if s9_q3_datestart_3_num<= td(01jan2016) & s1_q8_date>= td(01jan2016)
 replace workmonths_emp_m_31 = 1 if s9_q3_datestart_3_num<= td(01jan2017) & s1_q8_date>= td(01jan2017)
 replace workmonths_emp_m_31 = 1 if s9_q3_datestart_3_num<= td(01jan2018) & s1_q8_date>= td(01jan2018)
 gen workmonths_emp_m_32 = 1 if s9_q3_datestart_3_num<= td(01feb2016) & s1_q8_date>= td(01feb2016)
 replace workmonths_emp_m_32 = 1 if s9_q3_datestart_3_num<= td(01feb2017) & s1_q8_date>= td(01feb2017)
 replace workmonths_emp_m_32 = 1 if s9_q3_datestart_3_num<= td(01feb2018) & s1_q8_date>= td(01feb2018)
 gen workmonths_emp_m_33 = 1 if s9_q3_datestart_3_num<= td(01mar2016) & s1_q8_date>= td(01mar2016)
 replace workmonths_emp_m_33 = 1 if s9_q3_datestart_3_num<= td(01mar2017) & s1_q8_date>= td(01mar2017)
 replace workmonths_emp_m_33 = 1 if s9_q3_datestart_3_num<= td(01mar2018) & s1_q8_date>= td(01mar2018)
 gen workmonths_emp_m_34 = 1 if s9_q3_datestart_3_num<= td(01apr2016) & s1_q8_date>= td(01apr2016)
 replace workmonths_emp_m_34 = 1 if s9_q3_datestart_3_num<= td(01apr2017) & s1_q8_date>= td(01apr2017)
 gen workmonths_emp_m_35 = 1 if s9_q3_datestart_3_num<= td(01may2016) & s1_q8_date>= td(01may2016)
 replace workmonths_emp_m_35 = 1 if s9_q3_datestart_3_num<= td(01may2017) & s1_q8_date>= td(01may2017)
 gen workmonths_emp_m_36 = 1 if s9_q3_datestart_3_num<= td(01jun2016) & s1_q8_date>= td(01jun2016)
 replace workmonths_emp_m_36 = 1 if s9_q3_datestart_3_num<= td(01jun2017) & s1_q8_date>= td(01jun2017)
 gen workmonths_emp_m_37 = 1 if s9_q3_datestart_3_num<= td(01jul2016) & s1_q8_date>= td(01jul2016)
 replace workmonths_emp_m_37 = 1 if s9_q3_datestart_3_num<= td(01jul2017) & s1_q8_date>= td(01jul2017)
 gen workmonths_emp_m_38 = 1 if s9_q3_datestart_3_num<= td(01aug2016) & s1_q8_date>= td(01aug2016)
 replace workmonths_emp_m_38 = 1 if s9_q3_datestart_3_num<= td(01aug2017) & s1_q8_date>= td(01aug2017)
 gen workmonths_emp_m_39 = 1 if s9_q3_datestart_3_num<= td(01sep2016) & s1_q8_date>= td(01sep2016)
 replace workmonths_emp_m_39 = 1 if s9_q3_datestart_3_num<= td(01sep2017) & s1_q8_date>= td(01sep2017)
 gen workmonths_emp_m_310 = 1 if s9_q3_datestart_3_num<= td(01oct2016) & s1_q8_date>= td(01oct2016)
 replace workmonths_emp_m_310 = 1 if s9_q3_datestart_3_num<= td(01oct2017) & s1_q8_date>= td(01oct2017)
 gen workmonths_emp_m_311 = 1 if s9_q3_datestart_3_num<= td(01nov2016) & s1_q8_date>= td(01nov2016)
 replace workmonths_emp_m_311 = 1 if s9_q3_datestart_3_num<= td(01nov2017) & s1_q8_date>= td(01nov2017)
 gen workmonths_emp_m_312 = 1 if s9_q3_datestart_3_num<= td(01dec2016) & s1_q8_date>= td(01dec2016)
 replace workmonths_emp_m_312 = 1 if s9_q3_datestart_3_num<= td(01dec2017) & s1_q8_date>= td(01dec2017)

  gen workmonths_emp_m_41 = 1 if s9_q3_datestart_4_num<= td(01jan2016) & s1_q8_date>= td(01jan2016)
 replace workmonths_emp_m_41 = 1 if s9_q3_datestart_4_num<= td(01jan2017) & s1_q8_date>= td(01jan2017)
 replace workmonths_emp_m_41 = 1 if s9_q3_datestart_4_num<= td(01jan2018) & s1_q8_date>= td(01jan2018)
 gen workmonths_emp_m_42 = 1 if s9_q3_datestart_4_num<= td(01feb2016) & s1_q8_date>= td(01feb2016)
 replace workmonths_emp_m_42 = 1 if s9_q3_datestart_4_num<= td(01feb2017) & s1_q8_date>= td(01feb2017)
 replace workmonths_emp_m_42 = 1 if s9_q3_datestart_4_num<= td(01feb2018) & s1_q8_date>= td(01feb2018)
 gen workmonths_emp_m_43 = 1 if s9_q3_datestart_4_num<= td(01mar2016) & s1_q8_date>= td(01mar2016)
 replace workmonths_emp_m_43 = 1 if s9_q3_datestart_4_num<= td(01mar2017) & s1_q8_date>= td(01mar2017)
 replace workmonths_emp_m_43 = 1 if s9_q3_datestart_4_num<= td(01mar2018) & s1_q8_date>= td(01mar2018)
 gen workmonths_emp_m_44 = 1 if s9_q3_datestart_4_num<= td(01apr2016) & s1_q8_date>= td(01apr2016)
 replace workmonths_emp_m_44 = 1 if s9_q3_datestart_4_num<= td(01apr2017) & s1_q8_date>= td(01apr2017)
 gen workmonths_emp_m_45 = 1 if s9_q3_datestart_4_num<= td(01may2016) & s1_q8_date>= td(01may2016)
 replace workmonths_emp_m_45 = 1 if s9_q3_datestart_4_num<= td(01may2017) & s1_q8_date>= td(01may2017)
 gen workmonths_emp_m_46 = 1 if s9_q3_datestart_4_num<= td(01jun2016) & s1_q8_date>= td(01jun2016)
 replace workmonths_emp_m_46 = 1 if s9_q3_datestart_4_num<= td(01jun2017) & s1_q8_date>= td(01jun2017)
 gen workmonths_emp_m_47 = 1 if s9_q3_datestart_4_num<= td(01jul2016) & s1_q8_date>= td(01jul2016)
 replace workmonths_emp_m_47 = 1 if s9_q3_datestart_4_num<= td(01jul2017) & s1_q8_date>= td(01jul2017)
 gen workmonths_emp_m_48 = 1 if s9_q3_datestart_4_num<= td(01aug2016) & s1_q8_date>= td(01aug2016)
 replace workmonths_emp_m_48 = 1 if s9_q3_datestart_4_num<= td(01aug2017) & s1_q8_date>= td(01aug2017)
 gen workmonths_emp_m_49 = 1 if s9_q3_datestart_4_num<= td(01sep2016) & s1_q8_date>= td(01sep2016)
 replace workmonths_emp_m_49 = 1 if s9_q3_datestart_4_num<= td(01sep2017) & s1_q8_date>= td(01sep2017)
 gen workmonths_emp_m_410 = 1 if s9_q3_datestart_4_num<= td(01oct2016) & s1_q8_date>= td(01oct2016)
 replace workmonths_emp_m_410 = 1 if s9_q3_datestart_4_num<= td(01oct2017) & s1_q8_date>= td(01oct2017)
 gen workmonths_emp_m_411 = 1 if s9_q3_datestart_4_num<= td(01nov2016) & s1_q8_date>= td(01nov2016)
 replace workmonths_emp_m_411 = 1 if s9_q3_datestart_4_num<= td(01nov2017) & s1_q8_date>= td(01nov2017)
 gen workmonths_emp_m_412 = 1 if s9_q3_datestart_4_num<= td(01dec2016) & s1_q8_date>= td(01dec2016)
 replace workmonths_emp_m_412 = 1 if s9_q3_datestart_4_num<= td(01dec2017) & s1_q8_date>= td(01dec2017)

 //ensure employment enterprise months are not double counted AND employment and self employment months are not double counted
 forvalues month=1/12 {
 gen monthsworked_emp_`month' = 1 if workmonths_emp_m_1`month'==1 | ///
 workmonths_emp_m_2`month'==1 | workmonths_emp_m_3`month'==1 ///
 | workmonths_emp_m_4`month'==1

 replace monthsworked_emp_`month' = . if selfemp_mthsworked_`month'==1 | monthsworked_selfemp==12
 tab monthsworked_emp_`month'
 }

 egen monthsemployed_total = rowtotal(monthsworked_emp_1 monthsworked_emp_2 monthsworked_emp_3 ///
 monthsworked_emp_4 monthsworked_emp_5 monthsworked_emp_6 monthsworked_emp_7 monthsworked_emp_8 ///
 monthsworked_emp_9 monthsworked_emp_10 monthsworked_emp_11 monthsworked_emp_12)


//generate number of months worked for seasonal employees
 **NOTE: No conflicting responses as in section 8 above
 tab s9_q7a_workmonths_1
 tab s9_q7a_workmonths_2
 tab s9_q7a_workmonths_3
 tab s9_q7a_workmonths_4

 foreach var of varlist s9_q7a_workmonths_1 s9_q7a_workmonths_2 s9_q7a_workmonths_3 s9_q7a_workmonths_4 {
 gen frmt_`var' = " "+`var'+" "
 }

 forvalues i=1/13 {
 gen s9_q7a_workmonths_m_1`i' = 1 if strpos(frmt_s9_q7a_workmonths_1," `i' ") & s9_q2_hhmemberemp_1==0
 gen s9_q7a_workmonths_m_2`i' = 1 if strpos(frmt_s9_q7a_workmonths_2," `i' ") & s9_q2_hhmemberemp_2==0
 gen s9_q7a_workmonths_m_3`i' = 1 if strpos(frmt_s9_q7a_workmonths_3," `i' ") & s9_q2_hhmemberemp_3==0
 gen s9_q7a_workmonths_m_4`i' = 1 if strpos(frmt_s9_q7a_workmonths_4," `i' ") & s9_q2_hhmemberemp_4==0
 //gen s9_q7a_workmonths_m_5`i' = 1 if strpos(frmt_s9_q7a_workmonths_5," `i' ") & s9_q2_hhmemberemp_5==0 -- make sure no 5
}

 //ensure no months for seasonal employment enterprises are double counted
forvalues month=1/13 {
 gen s9_q7a_workmonths_1`month' = 1 if s9_q7a_workmonths_m_1`month'==1 | ///
 s9_q7a_workmonths_m_2`month'==1 | s9_q7a_workmonths_m_3`month'==1 ///
 | s9_q7a_workmonths_m_4`month'==1
 }

 recode s9_q7a_workmonths_113 (1=12)

//ensure seasonal and self AND seasonal and employment are not double counted
gen monthsworked_emp_13 = 1 if monthsworked_emp_1==1 & monthsworked_emp_2==1 & monthsworked_emp_3==1 & ///
 monthsworked_emp_4==1 & monthsworked_emp_5==1 & monthsworked_emp_6==1 & monthsworked_emp_7==1 & monthsworked_emp_8==1 & ///
 monthsworked_emp_9==1 & monthsworked_emp_10==1 & monthsworked_emp_11==1 & monthsworked_emp_12==1

 forvalues month=1/13 {
 replace s9_q7a_workmonths_1`month' = . if monthsworked_emp_`month'==1 | monthsworked_emp_13==1 | monthsworked_selfemp==12
 }

 forvalues month=1/12 {
 replace s9_q7a_workmonths_1`month' = . if selfemp_mthsworked_`month'==1 | monthsworked_selfemp==12
 }

 egen monthsemployed_seas_tot = rowtotal (s9_q7a_workmonths_11 s9_q7a_workmonths_12 s9_q7a_workmonths_13 s9_q7a_workmonths_14 ///
 s9_q7a_workmonths_15 s9_q7a_workmonths_16 s9_q7a_workmonths_17 s9_q7a_workmonths_18 ///
 s9_q7a_workmonths_19 s9_q7a_workmonths_110 s9_q7a_workmonths_111 s9_q7a_workmonths_112) if s9_q7_workpattern_1==3
 summ monthsemployed_seas_tot

 //sum months worked for self employed individuals, employed individuals and seasonal individuals
 egen p10_1_monthsworked = rowtotal (monthsworked_selfemp monthsemployed_total monthsemployed_seas_tot)
 la var p10_1_monthsworked "P10.1 No of mos wrked last 12 mos - Opt 1 (ignore DK conflicts, use all in case of mo conflicts)"

 egen p10_1_monthsworked_v2 = rowtotal (monthsworked_selfemp_v2 monthsemployed_total monthsemployed_seas_tot)
 la var p10_1_monthsworked_v2 "P10.1 No of mos wrked last 12 mos - Opt 2 (ignore all mos responses when conflicts w/ select mos)"

egen p10_1_monthsworked_v3 = rowtotal (monthsworked_selfemp_v3 monthsemployed_total monthsemployed_seas_tot)
 la var p10_1_monthsworked_v3 "P10.1 No of mos wrked last 12 mos - Opt 3 (DK to missing)"

 //generate number of months worked in now-sold businesses
 tab s8_q19_closed

 tab s8_q28_startmth_1
 tab s8_q28_startyr_1
 tab s8_q28_startmth_2
 tab s8_q28_startyr_2


 *** 2. RESPONDENT CURRENTLY SELF-EMPLOYED OR EMPLOYED/WORKING FOR PAY

 gen p10_2_workingforpay = (fr_selfemp_decision_any == 1 | fr_workingpay == 1) if ~mi(s8_q1_selfemployed) & ~mi(s9_q1_employed)
 summ p10_2_workingforpay
 la var p10_2_workingforpay "P10.2 Respondent currently self-employed or employed for pay"

 gen workingforpay_emp = (fr_workingpay == 1) if ~mi(s9_q1_employed)
 summ workingforpay_emp
 la var workingforpay_emp "Respondent currently employed for pay"

 gen workingforpay_self = (fr_selfemp_decision_any == 1) if ~mi(s8_q1_selfemployed)
 summ workingforpay_self
 la var workingforpay_self "Respondent currently self-employed"


 *** 3. RESPONDENT'S TOTAL HOURS WORKED IN EMPLOYMENT OR SELF-EMPLOYMENT IN LAST 7 DAYS
  // sum hours worked employment 9.7 when 9.2=0 + hours worked in self-employment 8.4 when 8.3b=0

 //generate total hours worked in employment and self-employment
 egen p10_3_hrsworked = rowtotal(hrsworked_emp_main hrsworked_self_main), m
 summ p10_3_hrsworked
 la var p10_3_hrsworked "P10.3 Respondent's total hours worked in emp, self-emp last 7 days"

 summ hrsworked_emp_main

 summ hrsworked_self_main

 gen fr_ag_emp = 0 if s9_q2_hhmemberemp_1==0 | s9_q2_hhmemberemp_2==0 | s9_q2_hhmemberemp_3==0 | s9_q2_hhmemberemp_4==0
 forvalues i = 1/4 {
     replace fr_ag_emp = 1 if s9_q4_occupation_`i'==2 & s9_q2_hhmemberemp_`i'==0
 }
 tab fr_ag_emp
 la var fr_ag_emp "Indicator for respondent employed as agricultural laborer conditional on being employed"

 gen hrsworked_emp_ag = 0 if fr_ag_emp==0
 replace hrsworked_emp_ag = hrsworked_emp_main if fr_ag_emp==1
 summ hrsworked_emp_ag
 la var hrsworked_emp_ag "Hours worked as agricultural laborer"

 **NOTE: As in summary measure, 7 observations worked more than 150 hours in last 7 days

 *** 4. PROPORTION OF WORKING-AGE ADULT HOUSEHOLD MEMBERS WORKING IN SELF-EMPLOYMENT OR EMPLOYMENT
 // adults who are working 4.1.8 divided by total number of adults 18-65 in household

 // generate indicator for if the household member is an adult
 local age s2_q4a_age s4_1_q5_age_1 s4_1_q5_age_2 s4_1_q5_age_3 s4_1_q5_age_4 s4_1_q5_age_5 ///
 s4_1_q5_age_6 s4_1_q5_age_7 s4_1_q5_age_8 s4_1_q5_age_9 s4_1_q5_age_10 s4_1_q5_age_11 ///
 s4_1_q5_age_12 s4_1_q5_age_13 s4_1_q5_age_14 s4_1_q5_age_15

 foreach var of local age {
     gen `var'_wrkageadult = 0 if ~mi(`var')
     replace `var'_wrkageadult = 1 if `var'>17 & `var'<66
     tab `var'_wrkageadult
 }

 **NOTE: Measure can be constructed either from section 4 or sections 8 and 9; constructing outcome from section 4

 //generate indicator variable for each employed household member
 ren s4_1_q8_occup_1 s4_1_q8_occup_0 //so the new variable names work (i.e. there's already s4_1_q8_occup_11, s4_1_q8_occup_12
 split s4_1_q8_occup_0 //1,2
 split s4_1_q8_occup_2 //1,2
 split s4_1_q8_occup_3 //1,2
 split s4_1_q8_occup_4 //1,2
 split s4_1_q8_occup_5 //1,2
 split s4_1_q8_occup_6 //1,2
 split s4_1_q8_occup_7 //1,2
 split s4_1_q8_occup_8 //1
 split s4_1_q8_occup_9 //1
 split s4_1_q8_occup_10 //1
 split s4_1_q8_occup_11 //1
 split s4_1_q8_occup_12 //1
 split s4_1_q8_occup_13 //1
 split s4_1_q8_occup_14 //1
 //split s4_1_q8_occup_15 //no obs

 local occupations s4_1_q8_occup_01 s4_1_q8_occup_02 s4_1_q8_occup_03 s4_1_q8_occup_04 ///
 s4_1_q8_occup_05 s4_1_q8_occup_21 s4_1_q8_occup_22 s4_1_q8_occup_31 ///
 s4_1_q8_occup_32 s4_1_q8_occup_41 s4_1_q8_occup_42 s4_1_q8_occup_51 s4_1_q8_occup_52 ///
 s4_1_q8_occup_61 s4_1_q8_occup_62 s4_1_q8_occup_71 s4_1_q8_occup_72 s4_1_q8_occup_81 ///
 s4_1_q8_occup_91 s4_1_q8_occup_101 s4_1_q8_occup_111 s4_1_q8_occup_121 s4_1_q8_occup_131 s4_1_q8_occup_141

 foreach var of varlist s4_1_q8_occup_01 s4_1_q8_occup_02 s4_1_q8_occup_03 s4_1_q8_occup_04 ///
 s4_1_q8_occup_05 s4_1_q8_occup_21 s4_1_q8_occup_22 s4_1_q8_occup_31 ///
 s4_1_q8_occup_32 s4_1_q8_occup_41 s4_1_q8_occup_42 s4_1_q8_occup_51 s4_1_q8_occup_52 ///
 s4_1_q8_occup_61 s4_1_q8_occup_62 s4_1_q8_occup_71 s4_1_q8_occup_72 s4_1_q8_occup_81 ///
 s4_1_q8_occup_91 s4_1_q8_occup_101 s4_1_q8_occup_111 s4_1_q8_occup_121 s4_1_q8_occup_131 s4_1_q8_occup_141 {
     destring `var', replace
     gen `var'_working = 0
     replace `var'_working = 1 if `var'==2 |`var'==5 |`var'==6 |`var'==7 |`var'==8 | `var'==9 | `var'==10 ///
                             | `var'==11 |`var'==12 |`var'==13 |`var'==14 |`var'==17 | `var'==18 | `var'==19 ///
                             | `var'==20 |`var'==21 |`var'==23 |`var'==24 |`var'==25 | `var'==26 | `var'==27 ///
                             | `var'==28 |`var'==29 |`var'==30 |`var'==31 |`var'==32 | `var'==71 | `var'==72 ///
                             | `var'==73 |`var'==74 |`var'==75 |`var'==77 |`var'==78 | `var'==79 | `var'==80 ///
                             | `var'==81 |`var'==82 |`var'==83 |`var'==100 |`var'==101 | `var'==102
     tab `var'_working
 }


 //generate count of adults working
 gen wrkadlt_0 = p10_2_workingforpay if s2_q4a_age_wrkageadult==1

 egen wrkadlt_1 = rowmax(s4_1_q8_occup_01_working s4_1_q8_occup_02_working ///
 s4_1_q8_occup_03_working s4_1_q8_occup_04_working s4_1_q8_occup_05_working) if s4_1_q5_age_1_wrkageadult==1

 forval i = 2 / 7 {
     egen wrkadlt_`i' = rowmax(s4_1_q8_occup_`i'1_working s4_1_q8_occup_`i'2_working) if s4_1_q5_age_`i'_wrkageadult==1
 }

forval i = 8 / 14 {
    gen wrkadlt_`i' = s4_1_q8_occup_`i'1_working == 1 if s4_1_q5_age_`i'_wrkageadult==1
}

 //add total employed adults in the household
 egen totalworkingadults = rowtotal(wrkadlt_0 wrkadlt_1 wrkadlt_2 wrkadlt_3 wrkadlt_4 ///
 wrkadlt_5 wrkadlt_6 wrkadlt_7 wrkadlt_8 wrkadlt_9 wrkadlt_10 wrkadlt_11 ///
 wrkadlt_12 wrkadlt_13 wrkadlt_14), m
 summ totalworkingadults

 // add total adults in the household
 egen totalwrkageadults = rowtotal(s2_q4a_age_wrkageadult s4_1_q5_age_1_wrkageadult s4_1_q5_age_2_wrkageadult s4_1_q5_age_3_wrkageadult ///
 s4_1_q5_age_4_wrkageadult s4_1_q5_age_5_wrkageadult s4_1_q5_age_6_wrkageadult s4_1_q5_age_7_wrkageadult ///
 s4_1_q5_age_8_wrkageadult s4_1_q5_age_9_wrkageadult s4_1_q5_age_10_wrkageadult s4_1_q5_age_11_wrkageadult ///
 s4_1_q5_age_12_wrkageadult s4_1_q5_age_13_wrkageadult s4_1_q5_age_14_wrkageadult s4_1_q5_age_15_wrkageadult), m
 summ totalwrkageadults

 gen p10_4_propworkingadults = (totalworkingadults)/totalwrkageadults
 summ p10_4_propworkingadults
 la var p10_4_propworkingadults "P10.4 Proportion of working adults"

 egen any_workageadult = rowmax(s2_q4a_age_wrkageadult s4_1_q5_age_1_wrkageadult s4_1_q5_age_2_wrkageadult s4_1_q5_age_3_wrkageadult ///
 s4_1_q5_age_4_wrkageadult s4_1_q5_age_5_wrkageadult s4_1_q5_age_6_wrkageadult s4_1_q5_age_7_wrkageadult ///
 s4_1_q5_age_8_wrkageadult s4_1_q5_age_9_wrkageadult s4_1_q5_age_10_wrkageadult s4_1_q5_age_11_wrkageadult ///
 s4_1_q5_age_12_wrkageadult s4_1_q5_age_13_wrkageadult s4_1_q5_age_14_wrkageadult s4_1_q5_age_15_wrkageadult)


 *** 5. HOURS HOUSEHOLD SPENT ACTIVELY SEARCHING FOR JOBS, APPLYING FOR JOBS OR INTERVIEWS IN THE LAST 7 DAYS
 // 9.21
 tab s9_q21_hrsjobsearch

 tab s9_q19_jobsearch

 gen p10_5_hoursjobsearch = s9_q21_hrsjobsearch
 replace p10_5_hoursjobsearch = 0 if s9_q19_jobsearch==2
 summ p10_5_hoursjobsearch
 la var p10_5_hoursjobsearch "P10.5 Hours household spent actively searching for jobs in last 7 days"

 gen hoursjobsearch_pc = (p10_5_hoursjobsearch)/totalwrkageadults
 summ hoursjobsearch_pc
 la var hoursjobsearch_pc "Hours per working age adult spent actively searching for jobs in last 7 days"

 *** 6. RESPONDENT'S HOURS SPENT ON HOUSEHOLD CHORES IN LAST 7 DAYS
 // 6.14
 tab s6_q14_choresselfhrs

 gen p10_6_hourschores = s6_q14_choresselfhrs
 summ p10_6_hourschores
 **NOTE: 1 observation above 150
 la var p10_6_hourschores "P10.6 Hours spent on household chores in last 7 days"

 *** 7. RESPONDENT'S HOURS SPENT PERFORMING LEISURELY ACTIVITIES IN THE LAST 24 HOURS // Need to figure out how to code 0, which is the same as the prior half hour
 // calculate total hours in 17.1 spent on 1, 2, 3, 4-5, 6, 13, 14, 17, 18

 //replace 0 values with previous value
 **NOTE: s17_q1_activity600 = 0 which indicates previous activity (this cannot be correct since it is the first activity)
 //Option 1: recode s17_q1_activity600 = 0 as missing
 gen s17_q1_activity600_v1 = s17_q1_activity600
 recode s17_q1_activity600_v1 (0 = .)
 replace s17_q2_activity630 = s17_q1_activity600_v1 if s17_q2_activity630==0
 replace s17_q3_activity700 = s17_q2_activity630 if s17_q3_activity700==0
 replace s17_q4_activity730 = s17_q3_activity700 if s17_q4_activity730==0
 replace s17_q5_activity800 = s17_q4_activity730 if s17_q5_activity800==0
 replace s17_q6_activity830 = s17_q5_activity800 if s17_q6_activity830==0
 replace s17_q7_activity900 = s17_q6_activity830 if s17_q7_activity900==0
 replace s17_q8_activity930 = s17_q7_activity900 if s17_q8_activity930==0
 replace s17_q9_activity1000 = s17_q8_activity930 if s17_q9_activity1000==0
 replace s17_q10_activity1030 = s17_q9_activity1000 if s17_q10_activity1030==0
 replace s17_q11_activity1100 = s17_q10_activity1030 if s17_q11_activity1100==0
 replace s17_q12_activity1130 = s17_q11_activity1100 if s17_q12_activity1130==0
 replace s17_q13_activity1200 = s17_q12_activity1130 if s17_q13_activity1200==0
 replace s17_q14_activity1230 = s17_q13_activity1200 if s17_q14_activity1230==0
 replace s17_q15_activity1300 = s17_q14_activity1230 if s17_q15_activity1300==0
 replace s17_q16_activity1330 = s17_q15_activity1300 if s17_q16_activity1330==0
 replace s17_q17_activity1400 = s17_q16_activity1330 if s17_q17_activity1400==0
 replace s17_q18_activity1430 = s17_q17_activity1400 if s17_q18_activity1430==0
 replace s17_q19_activity1500 = s17_q18_activity1430 if s17_q19_activity1500==0
 replace s17_q20_activity1530 = s17_q19_activity1500 if s17_q20_activity1530==0
 replace s17_q21_activity1600 = s17_q20_activity1530 if s17_q21_activity1600==0
 replace s17_q22_activity1630 = s17_q21_activity1600 if s17_q22_activity1630==0
 replace s17_q23_activity1700 = s17_q22_activity1630 if s17_q23_activity1700==0
 replace s17_q24_activity1730 = s17_q23_activity1700 if s17_q24_activity1730==0
 replace s17_q25_activity1800 = s17_q24_activity1730 if s17_q25_activity1800==0
 replace s17_q26_activity1830 = s17_q25_activity1800 if s17_q26_activity1830==0
 replace s17_q27_activity1900 = s17_q26_activity1830 if s17_q27_activity1900==0
 replace s17_q28_activity1930 = s17_q27_activity1900 if s17_q28_activity1930==0
 replace s17_q29_activity2000 = s17_q28_activity1930 if s17_q29_activity2000==0
 replace s17_q30_activity2030 = s17_q29_activity2000 if s17_q30_activity2030==0
 replace s17_q31_activity2100 = s17_q30_activity2030 if s17_q31_activity2100==0
 replace s17_q32_activity2130 = s17_q31_activity2100 if s17_q32_activity2130==0
 replace s17_q33_activity2200 = s17_q32_activity2130 if s17_q33_activity2200==0
 replace s17_q34_activity2230 = s17_q33_activity2200 if s17_q34_activity2230==0
 replace s17_q35_activity2300 = s17_q34_activity2230 if s17_q35_activity2300==0
 replace s17_q36_activity2330 = s17_q35_activity2300 if s17_q36_activity2330==0
 replace s17_q37_activity0000 = s17_q36_activity2330 if s17_q37_activity0000==0
 replace s17_q38_activity0030 = s17_q37_activity0000 if s17_q38_activity0030==0
 replace s17_q39_activity100 = s17_q38_activity0030 if s17_q39_activity100==0
 replace s17_q40_activity130 = s17_q39_activity100 if s17_q40_activity130==0
 replace s17_q41_activity200 = s17_q40_activity130 if s17_q41_activity200==0
 replace s17_q42_activity230 = s17_q41_activity200 if s17_q42_activity230==0
 replace s17_q43_activity300 = s17_q42_activity230 if s17_q43_activity300==0
 replace s17_q44_activity330 = s17_q43_activity300 if s17_q44_activity330==0
 replace s17_q45_activity400 = s17_q44_activity330 if s17_q45_activity400==0
 replace s17_q46_activity430 = s17_q45_activity400 if s17_q46_activity430==0
 replace s17_q47_activity500 = s17_q46_activity430 if s17_q47_activity500==0
 replace s17_q48_activity530 = s17_q47_activity500 if s17_q48_activity530==0

 //generate indicator for leisure activities
 local sec17 s17_q1_activity600_v1 s17_q2_activity630 s17_q3_activity700 s17_q4_activity730 ///
 s17_q5_activity800 s17_q6_activity830 s17_q7_activity900 s17_q8_activity930 ///
 s17_q9_activity1000 s17_q10_activity1030 s17_q11_activity1100 s17_q12_activity1130 ///
 s17_q13_activity1200 s17_q14_activity1230 s17_q15_activity1300 s17_q16_activity1330 ///
 s17_q17_activity1400 s17_q18_activity1430 s17_q19_activity1500 s17_q20_activity1530 ///
 s17_q21_activity1600 s17_q22_activity1630 s17_q23_activity1700 s17_q24_activity1730 ///
 s17_q25_activity1800 s17_q26_activity1830 s17_q27_activity1900 s17_q28_activity1930 ///
 s17_q29_activity2000 s17_q30_activity2030 s17_q31_activity2100 s17_q32_activity2130 ///
 s17_q33_activity2200 s17_q34_activity2230 s17_q35_activity2300 s17_q36_activity2330 ///
 s17_q37_activity0000 s17_q38_activity0030 s17_q39_activity100 s17_q40_activity130 ///
 s17_q41_activity200 s17_q42_activity230 s17_q43_activity300 s17_q44_activity330 ///
 s17_q45_activity400 s17_q46_activity430 s17_q47_activity500 s17_q48_activity530


 foreach var of local sec17 {
 gen cnt_`var' = 1 if `var'== 1 | `var'==2 | `var'==3 | `var'==4 | `var'==5 | `var'==6 ///
 | `var'==13 | `var'==14 | `var'==17 | `var'==18
 tab cnt_`var'
 }

 //sum total leisure half hours. divide by 2 to convert to hours
 egen leisurehalfhours = rowtotal(cnt_s17_q1_activity600_v1 cnt_s17_q2_activity630 ///
 cnt_s17_q3_activity700 cnt_s17_q4_activity730 cnt_s17_q5_activity800 ///
 cnt_s17_q6_activity830 cnt_s17_q7_activity900 cnt_s17_q8_activity930 ///
 cnt_s17_q9_activity1000 cnt_s17_q10_activity1030 cnt_s17_q11_activity1100 ///
 cnt_s17_q12_activity1130 cnt_s17_q13_activity1200 cnt_s17_q14_activity1230 ///
 cnt_s17_q15_activity1300 cnt_s17_q16_activity1330 cnt_s17_q17_activity1400 ///
 cnt_s17_q18_activity1430 cnt_s17_q19_activity1500 cnt_s17_q20_activity1530 ///
 cnt_s17_q21_activity1600 cnt_s17_q22_activity1630 cnt_s17_q23_activity1700 ///
 cnt_s17_q24_activity1730 cnt_s17_q25_activity1800 cnt_s17_q26_activity1830 ///
 cnt_s17_q27_activity1900 cnt_s17_q28_activity1930 cnt_s17_q29_activity2000 ///
 cnt_s17_q30_activity2030 cnt_s17_q31_activity2100 cnt_s17_q32_activity2130 ///
 cnt_s17_q33_activity2200 cnt_s17_q34_activity2230 cnt_s17_q35_activity2300 ///
 cnt_s17_q36_activity2330 cnt_s17_q37_activity0000 cnt_s17_q38_activity0030 ///
 cnt_s17_q39_activity100 cnt_s17_q40_activity130 cnt_s17_q41_activity200 ///
 cnt_s17_q42_activity230 cnt_s17_q43_activity300 cnt_s17_q44_activity330 ///
 cnt_s17_q45_activity400 cnt_s17_q46_activity430 cnt_s17_q47_activity500 cnt_s17_q48_activity530), m
 summ leisurehalfhours

 //Option 2: recode s17_q1_activity600 = 0 as 1
 gen s17_q1_activity600_v2 = s17_q1_activity600
 recode s17_q1_activity600_v2 (0 = 1)
 gen s17_q2_activity630_v2 = s17_q2_activity630
 replace s17_q2_activity630_v2 = s17_q1_activity600_v2 if s17_q2_activity630==0
 gen s17_q3_activity700_v2 = s17_q3_activity700
 replace s17_q3_activity700_v2 = s17_q2_activity630_v2 if s17_q3_activity700==0
 gen s17_q4_activity730_v2 = s17_q4_activity730
 replace s17_q4_activity730_v2 = s17_q3_activity700_v2 if s17_q4_activity730==0
 gen s17_q5_activity800_v2 = s17_q5_activity800
 replace s17_q5_activity800_v2 = s17_q4_activity730_v2 if s17_q5_activity800==0
 gen s17_q6_activity830_v2 = s17_q6_activity830
 replace s17_q6_activity830_v2 = s17_q5_activity800_v2 if s17_q6_activity830==0
 gen s17_q7_activity900_v2 = s17_q7_activity900
 replace s17_q7_activity900_v2 = s17_q6_activity830_v2 if s17_q7_activity900==0
 gen s17_q8_activity930_v2 = s17_q8_activity930
 replace s17_q8_activity930_v2 = s17_q7_activity900_v2 if s17_q8_activity930==0
 gen s17_q9_activity1000_v2 = s17_q9_activity1000
 replace s17_q9_activity1000_v2 = s17_q8_activity930_v2 if s17_q9_activity1000==0
 gen s17_q10_activity1030_v2 = s17_q10_activity1030
 replace s17_q10_activity1030_v2 = s17_q9_activity1000_v2 if s17_q10_activity1030==0
 gen s17_q11_activity1100_v2 = s17_q11_activity1100
 replace s17_q11_activity1100_v2 = s17_q10_activity1030_v2 if s17_q11_activity1100==0
 gen s17_q12_activity1130_v2 = s17_q12_activity1130
 replace s17_q12_activity1130_v2 = s17_q11_activity1100_v2 if s17_q12_activity1130==0
 gen s17_q13_activity1200_v2 = s17_q13_activity1200
 replace s17_q13_activity1200_v2 = s17_q12_activity1130_v2 if s17_q13_activity1200==0
 gen s17_q14_activity1230_v2 = s17_q14_activity1230
 replace s17_q14_activity1230_v2 = s17_q13_activity1200_v2 if s17_q14_activity1230==0
 gen s17_q15_activity1300_v2 = s17_q15_activity1300
 replace s17_q15_activity1300_v2 = s17_q14_activity1230_v2 if s17_q15_activity1300==0
 gen s17_q16_activity1330_v2 = s17_q16_activity1330
 replace s17_q16_activity1330_v2 = s17_q15_activity1300_v2 if s17_q16_activity1330==0
 gen s17_q17_activity1400_v2 = s17_q17_activity1400
 replace s17_q17_activity1400_v2 = s17_q16_activity1330_v2 if s17_q17_activity1400==0
 gen s17_q18_activity1430_v2 = s17_q18_activity1430
 replace s17_q18_activity1430_v2 = s17_q17_activity1400_v2 if s17_q18_activity1430==0
 gen s17_q19_activity1500_v2 = s17_q19_activity1500
 replace s17_q19_activity1500_v2 = s17_q18_activity1430_v2 if s17_q19_activity1500==0
 gen s17_q20_activity1530_v2 = s17_q20_activity1530
 replace s17_q20_activity1530_v2 = s17_q19_activity1500_v2 if s17_q20_activity1530==0
 gen s17_q21_activity1600_v2 = s17_q21_activity1600
 replace s17_q21_activity1600_v2 = s17_q20_activity1530_v2 if s17_q21_activity1600==0
 gen s17_q22_activity1630_v2 = s17_q22_activity1630
 replace s17_q22_activity1630_v2 = s17_q21_activity1600_v2 if s17_q22_activity1630==0
 gen s17_q23_activity1700_v2 = s17_q23_activity1700
 replace s17_q23_activity1700_v2 = s17_q22_activity1630_v2 if s17_q23_activity1700==0
 gen s17_q24_activity1730_v2 = s17_q24_activity1730
 replace s17_q24_activity1730_v2 = s17_q23_activity1700_v2 if s17_q24_activity1730==0
 gen s17_q25_activity1800_v2 = s17_q25_activity1800
 replace s17_q25_activity1800_v2 = s17_q24_activity1730_v2 if s17_q25_activity1800==0
 gen s17_q26_activity1830_v2 = s17_q26_activity1830
 replace s17_q26_activity1830_v2 = s17_q25_activity1800_v2 if s17_q26_activity1830==0
 gen s17_q27_activity1900_v2 = s17_q27_activity1900
 replace s17_q27_activity1900_v2 = s17_q26_activity1830_v2 if s17_q27_activity1900==0
 gen s17_q28_activity1930_v2 = s17_q28_activity1930
 replace s17_q28_activity1930_v2 = s17_q27_activity1900_v2 if s17_q28_activity1930==0
 gen s17_q29_activity2000_v2 = s17_q29_activity2000
 replace s17_q29_activity2000_v2 = s17_q28_activity1930_v2 if s17_q29_activity2000==0
 gen s17_q30_activity2030_v2 = s17_q30_activity2030
 replace s17_q30_activity2030_v2 = s17_q29_activity2000_v2 if s17_q30_activity2030==0
 gen s17_q31_activity2100_v2 = s17_q31_activity2100
 replace s17_q31_activity2100_v2 = s17_q30_activity2030_v2 if s17_q31_activity2100==0
 gen s17_q32_activity2130_v2 = s17_q32_activity2130
 replace s17_q32_activity2130_v2 = s17_q31_activity2100_v2 if s17_q32_activity2130==0
 gen s17_q33_activity2200_v2 = s17_q33_activity2200
 replace s17_q33_activity2200_v2 = s17_q32_activity2130_v2 if s17_q33_activity2200==0
 gen s17_q34_activity2230_v2 = s17_q34_activity2230
 replace s17_q34_activity2230_v2 = s17_q33_activity2200_v2 if s17_q34_activity2230==0
 gen s17_q35_activity2300_v2 = s17_q35_activity2300
 replace s17_q35_activity2300_v2 = s17_q34_activity2230_v2 if s17_q35_activity2300==0
 gen s17_q36_activity2330_v2 = s17_q36_activity2330
 replace s17_q36_activity2330_v2 = s17_q35_activity2300_v2 if s17_q36_activity2330==0
 gen s17_q37_activity0000_v2 = s17_q37_activity0000
 replace s17_q37_activity0000_v2 = s17_q36_activity2330_v2 if s17_q37_activity0000==0
 gen s17_q38_activity0030_v2 = s17_q38_activity0030
 replace s17_q38_activity0030_v2 = s17_q37_activity0000_v2 if s17_q38_activity0030==0
 gen s17_q39_activity100_v2 = s17_q39_activity100
 replace s17_q39_activity100_v2 = s17_q38_activity0030_v2 if s17_q39_activity100==0
 gen s17_q40_activity130_v2 = s17_q40_activity130
 replace s17_q40_activity130_v2 = s17_q39_activity100_v2 if s17_q40_activity130==0
 gen s17_q41_activity200_v2 = s17_q41_activity200
 replace s17_q41_activity200_v2 = s17_q40_activity130_v2 if s17_q41_activity200==0
 gen s17_q42_activity230_v2 = s17_q42_activity230
 replace s17_q42_activity230_v2 = s17_q41_activity200_v2 if s17_q42_activity230==0
 gen s17_q43_activity300_v2 = s17_q43_activity300
 replace s17_q43_activity300_v2 = s17_q42_activity230_v2 if s17_q43_activity300==0
 gen s17_q44_activity330_v2 = s17_q44_activity330
 replace s17_q44_activity330_v2 = s17_q43_activity300_v2 if s17_q44_activity330==0
 gen s17_q45_activity400_v2 = s17_q45_activity400
 replace s17_q45_activity400_v2 = s17_q44_activity330_v2 if s17_q45_activity400==0
 gen s17_q46_activity430_v2 = s17_q46_activity430
 replace s17_q46_activity430_v2 = s17_q45_activity400_v2 if s17_q46_activity430==0
 gen s17_q47_activity500_v2 = s17_q47_activity500
 replace s17_q47_activity500_v2 = s17_q46_activity430_v2 if s17_q47_activity500==0
 gen s17_q48_activity530_v2 = s17_q48_activity530
 replace s17_q48_activity530_v2 = s17_q47_activity500_v2 if s17_q48_activity530==0

 //generate indicator for leisure activities
 local sec17_v2 s17_q1_activity600_v2 s17_q2_activity630_v2 s17_q3_activity700_v2 s17_q4_activity730_v2 ///
 s17_q5_activity800_v2 s17_q6_activity830_v2 s17_q7_activity900_v2 s17_q8_activity930_v2 ///
 s17_q9_activity1000_v2 s17_q10_activity1030_v2 s17_q11_activity1100_v2 s17_q12_activity1130_v2 ///
 s17_q13_activity1200_v2 s17_q14_activity1230_v2 s17_q15_activity1300_v2 s17_q16_activity1330_v2 ///
 s17_q17_activity1400_v2 s17_q18_activity1430_v2 s17_q19_activity1500_v2 s17_q20_activity1530_v2 ///
 s17_q21_activity1600_v2 s17_q22_activity1630_v2 s17_q23_activity1700_v2 s17_q24_activity1730_v2 ///
 s17_q25_activity1800_v2 s17_q26_activity1830_v2 s17_q27_activity1900_v2 s17_q28_activity1930_v2 ///
 s17_q29_activity2000_v2 s17_q30_activity2030_v2 s17_q31_activity2100_v2 s17_q32_activity2130_v2 ///
 s17_q33_activity2200_v2 s17_q34_activity2230_v2 s17_q35_activity2300_v2 s17_q36_activity2330_v2 ///
 s17_q37_activity0000_v2 s17_q38_activity0030_v2 s17_q39_activity100_v2 s17_q40_activity130_v2 ///
 s17_q41_activity200_v2 s17_q42_activity230_v2 s17_q43_activity300_v2 s17_q44_activity330_v2 ///
 s17_q45_activity400_v2 s17_q46_activity430_v2 s17_q47_activity500_v2 s17_q48_activity530_v2


 foreach var of local sec17_v2 {
 gen cnt_`var' = 1 if `var'== 1 | `var'==2 | `var'==3 | `var'==4 | `var'==5 | `var'==6 ///
 | `var'==13 | `var'==14 | `var'==17 | `var'==18
 tab cnt_`var'
 }

 //sum total leisure half hours. divide by 2 to convert to hours
 egen leisurehalfhours_v2 = rowtotal(cnt_s17_q1_activity600_v2 cnt_s17_q2_activity630_v2 ///
 cnt_s17_q3_activity700_v2 cnt_s17_q4_activity730_v2 cnt_s17_q5_activity800_v2 ///
 cnt_s17_q6_activity830_v2 cnt_s17_q7_activity900_v2 cnt_s17_q8_activity930_v2 ///
 cnt_s17_q9_activity1000_v2 cnt_s17_q10_activity1030_v2 cnt_s17_q11_activity1100_v2 ///
 cnt_s17_q12_activity1130_v2 cnt_s17_q13_activity1200_v2 cnt_s17_q14_activity1230_v2 ///
 cnt_s17_q15_activity1300_v2 cnt_s17_q16_activity1330_v2 cnt_s17_q17_activity1400_v2 ///
 cnt_s17_q18_activity1430_v2 cnt_s17_q19_activity1500_v2 cnt_s17_q20_activity1530_v2 ///
 cnt_s17_q21_activity1600_v2 cnt_s17_q22_activity1630_v2 cnt_s17_q23_activity1700_v2 ///
 cnt_s17_q24_activity1730_v2 cnt_s17_q25_activity1800_v2 cnt_s17_q26_activity1830_v2 ///
 cnt_s17_q27_activity1900_v2 cnt_s17_q28_activity1930_v2 cnt_s17_q29_activity2000_v2 ///
 cnt_s17_q30_activity2030_v2 cnt_s17_q31_activity2100_v2 cnt_s17_q32_activity2130_v2 ///
 cnt_s17_q33_activity2200_v2 cnt_s17_q34_activity2230_v2 cnt_s17_q35_activity2300_v2 ///
 cnt_s17_q36_activity2330_v2 cnt_s17_q37_activity0000_v2 cnt_s17_q38_activity0030_v2 ///
 cnt_s17_q39_activity100_v2 cnt_s17_q40_activity130_v2 cnt_s17_q41_activity200_v2 ///
 cnt_s17_q42_activity230_v2 cnt_s17_q43_activity300_v2 cnt_s17_q44_activity330_v2 ///
 cnt_s17_q45_activity400_v2 cnt_s17_q46_activity430_v2 cnt_s17_q47_activity500_v2 cnt_s17_q48_activity530_v2), m
 summ leisurehalfhours_v2

 gen p10_7_leisurehours = (leisurehalfhours)/2
 la var p10_7_leisurehours "P10.7 Hrs spent performing leisure activities in past 24 hrs - Opt 1 (Change 0 to missing)"

 gen p10_7_leisurehours_v2 = (leisurehalfhours_v2)/2
 la var p10_7_leisurehours_v2 "P10.7 Hrs spent performing leisurely activities in past 24 hrs - Opt 2 (Change 0 to 1/sleeping)"



*** SAVING INTERMEDIATE DATASET ***
keep s1_hhid_key p10_* *hrs*  s17_q*_activity*_v2 s7_q7_hoursworked_* s8_q4_hrsworked_* s9_q8_hrsworked_* // these added in through labor supply
save "$da/intermediate/GE_HH-EL_hhlaborsupply.dta", replace
project, creates("$da/intermediate/GE_HH-EL_hhlaborsupply.dta")
