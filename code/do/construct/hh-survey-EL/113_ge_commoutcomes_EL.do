

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

*****Additional Outcomes ***********
** setting up to use intermediate dataset for more modular running
project, uses("$da/intermediate/GE_HH-EL_setup.dta")

use "$da/intermediate/GE_HH-EL_setup.dta", clear


** many of these come from local PF stuff, but will want to determine how to better integrate local PF stuff with main household outcomes **

recode s10_q3_rosca (2 = 0), gen(particip_rosca)
tab particip_rosca

*** 8.3 SOCIAL TRUST INDEX ***
tab s13_q11_trust
recode s13_q11_trust (1=1) (2 = 0) (-99 -88 = .), gen(trust_gen)
la var trust_gen "Generally speaking can most people be trusted?"

tab s13_q12a_trusttribe
recode s13_q12a_trusttribe (-99 -88 = .),  gen(trust_owntribe)
la var trust_owntribe "In general, can you trust members of your own tribe?"

tab s13_q12_trustothtribe
recode s13_q12_trustothtribe (-99 -88 = .), gen(trust_othtribe)
la var trust_othtribe "In general, can you trust members of other tribes?"

tab s13_q13a_trustrelig
recode s13_q13a_trustrelig (-99 -88 = .), gen(trust_ownrelig)
la var trust_ownrelig "In general, can you trust people of your church/mosque?"

tab s13_q13b_trustothrelig
recode s13_q13b_trustothrelig (-99 -88 = .), gen(trust_othrelig)
la var trust_othrelig "In general, can you trust people of other churches/mosques?"

tab s13_q14a_trustvill
recode s13_q14a_trustvill (-99 -88 = .), gen(trust_ownvill)
la var trust_ownvill "In general, can you trust people in your own village?"

tab s13_q14b_trustothvill
recode s13_q14b_trustothvill (-99 -88 = .), gen(trust_othvill)
la var trust_othvill "In general, can you trust people in other villages?"

tab1 trust_*

*** 8.5 COMMUNITY INVOLVEMENT INDEX ***
tab1 s10_1_q1a_menwomengrp s10_1_q1b_aggrp s10_1_q1c_youthgrp s10_1_q1d_watergrp s10_1_q1e_religgrp s10_1_q1f_burialgrp s10_1_q1g_schgrp s10_1_q1h_sportsgrp s10_1_q1i_othgrp

la var s10_1_q1a_menwomengrp    "HH member in men's/women's group"
la var s10_1_q1b_aggrp          "HH member in ag group"
la var s10_1_q1c_youthgrp       "HH member in youth group"
la var s10_1_q1d_watergrp       "HH member in water group"
la var s10_1_q1e_religgrp       "HH member in religious group"
la var s10_1_q1f_burialgrp      "HH member in burial group"
la var s10_1_q1g_schgrp         "HH member in school group"
la var s10_1_q1h_sportsgrp      "HH member in sports group"
la var s10_1_q1i_othgrp         "HH member in other group"

egen h85_comminvolve = rowtotal(s10_1_q1a_menwomengrp s10_1_q1b_aggrp s10_1_q1c_youthgrp s10_1_q1d_watergrp s10_1_q1e_religgrp s10_1_q1f_burialgrp s10_1_q1g_schgrp s10_1_q1h_sportsgrp s10_1_q1i_othgrp), m
la var h85_comminvolve "H8.5 Community Involvement (num group types)"

tab h85_comminvolve

*ICW based on group type - different interpretation but perhaps good to check
egen h85_comminvolve_icw = weightave(s10_1_q1a_menwomengrp s10_1_q1b_aggrp s10_1_q1c_youthgrp s10_1_q1d_watergrp s10_1_q1e_religgrp s10_1_q1f_burialgrp s10_1_q1g_schgrp s10_1_q1h_sportsgrp s10_1_q1i_othgrp), normby(elig_control_lowsat)
la var h85_comminvolve_icw "H8.5 Community Involvement (ICW of group types)"

*** 8.6 COMMUNITY GROUP INDICATOR ***
gen h86_incommgroup = (h85_comminvolve > 0) if ~mi(h85_comminvolve)
la var h86_incommgroup "H8.6 Household in a community group"

tab h86_incommgroup



*** SAVING INTERMEDIATE DATASET ***
keep s1_hhid_key h??_* trust_* particip_rosca
save "$da/intermediate/GE_HH-EL_commoutcomes.dta", replace
project, creates("$da/intermediate/GE_HH-EL_commoutcomes.dta")
