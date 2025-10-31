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

/****** LOADING DATASET *******/
project, original("$dr/GE_ENT-Census-EL1_PUBLIC.dta") preserve
use "$dr/GE_ENT-Census-EL1_PUBLIC.dta", clear


**************************
** Section 1 - Cleaning **
**************************
gen bl_tracked = (s1_q4_trackingsheet == 1)

tab s1_q7_stilloperates bl_tracked // 361/4898 are no longer operating
list if s1_q7_stilloperates == . & bl_tracked // 20 are missing. But 18/20 say they were open. And the other 2 answered the survey, so I set them as operational
replace s1_q7_stilloperates = 1 if s1_q7_stilloperates == . & bl_tracked

count if bl_tracked == 0 & s1_q7_stilloperates != . // New enterprises did not answer this question
rename s1_q7_stilloperates operational
replace operational = (2 - operational)
replace operational = 1 if bl_tracked == 0 // assume all enterprises newly added are operational at endline

count if s1_q8_isopen == . // no missings
tab operational s1_q8_isopen // there are 9 non-operational businesses that are open / were open during the last 7 days
list if operational == 0 & s1_q8_isopen < 3 // they answered all questions, so set as operational
replace operational = 1 if operational == 0 & s1_q8_isopen < 3  // those answered all questions, so are operational


** Check consent **
gen entcode_BL = end_entcode
list entcode_BL end_ent_key entcode_EL s1_q10b_declinewhy if consent == 2
replace operational = 0 if consent == 2 & inlist(entcode_BL,118607, 112200,113444,113575,116164,118252) // comments say businesses closed down


** fix open variables **
gen open = (s1_q8_isopen == 1)
gen open_7d = inlist(s1_q8_isopen,1,2)

tab open_7d operational
list if operational == 0 & open_7d == 1
list if operational == 1 & open_7d == 0 // not clear what is happening here, simply accept they were not open for a week

order location_code sublocation_code village_code entcode_BL end_ent_key entcode_EL ent_rank cen_date bl_tracked bl_date bl_* open open_7d operational consent



**************************
** Section 2 - Cleaning **
**************************

** Physical Business Characteristics **
***************************************
replace s2_q2a_operatefrom = 2 if inlist(s2_q2a_operatefrom_other, "A stall", "Market", "Stand")
replace s2_q2a_operatefrom = 5 if inlist(s2_q2a_operatefrom_other, "Has no shelter", "On shore of river Nzoia at uhumo", "Outside a shop", "Plot", "Under tree")

rename s2_q2a_operatefrom operate_from

replace operate_from = 1 if operate_from == 6
label val operate_from operate_from
tab operate_from

rename s2_q2b_roof roof
tab roof

rename s2_q2c_walls walls
tab walls

rename s2_q2d_floors floors
tab floors


** Business Categories **
*************************
rename s2_q3_bizcat bizcat

tab bizcat


** Owner residence information **
*********************************
gen owner_resident = (s3_q6_ownerresident == 1) if !inlist(s3_q6_ownerresident, ., -99)
gen double owner_location_code = location_code if owner_resident == 1
gen double owner_sublocation_code = sublocation_code if owner_resident == 1
gen double owner_village_code = village_code if owner_resident == 1

replace owner_location_code = s3_q8b_ownlocation if owner_resident == 0 & s3_q8b_ownlocation != .
replace owner_sublocation_code = s3_q8c_ownsublocation if owner_resident == 0 & s3_q8c_ownsublocation != .
destring s3_q8d_ownvillage, replace
replace owner_village_code = s3_q8d_ownvillage if owner_resident == 0 & s3_q8d_ownvillage != .

format *_code %13.0f

ren location_code a
ren sublocation_code b
ren village_code c

ren owner_location_code location_code
ren owner_sublocation_code sublocation_code
ren owner_village_code village_code

project, original("$dr/CleanGeography_PUBLIC.dta") preserve
merge m:1 village_code using "$dr/CleanGeography_PUBLIC.dta"
tab village_code if _merge == 1
drop if _merge == 2
drop _merge

ren subcounty owner_subcounty
ren location_code owner_location_code
ren sublocation_code owner_sublocation_code
ren village_code owner_village_code

ren a location_code
ren b sublocation_code
ren c village_code

** Deal with 'other' locations/sublocations/villages **
** TK come back to this part
list s3_q8* if s3_q8a_countyoth != .
gen owner_county = "Busia" if s3_q8a_countyoth == 1
replace owner_county = "Bungoma" if s3_q8a_countyoth == 2
replace owner_county = "Kakamega" if s3_q8a_countyoth == 3
replace owner_county = "Kisumu" if s3_q8a_countyoth == 7
replace owner_county = "Mombasa" if s3_q8a_countyoth == 19
replace owner_county = "Nairobi" if s3_q8a_countyoth == 30
replace owner_county = "Uasin Gishu" if s3_q8a_countyoth == 46
replace owner_county = "Siaya" if owner_location_code != 77 & inrange(round(owner_location_code/10000,1),601,603)
replace owner_county = "Italy" if s3_q8a_ownsubcountyoth == "Italy"

** Ownership status **
gen owner_status = 1 if s3_q1_isowner == 1
replace owner_status = 1 if s3_q1_isowner == 3 & s3_q9_ownstatus == 1

replace owner_status = 2 if s3_q1_isowner == 2
replace owner_status = 2 if s3_q1_isowner == 3 & s3_q9_ownstatus == 2

label def ownstatus 1 "single ownership" 2 "joint ownership"
label val owner_status ownstatus

gen owner_num = 1 if owner_status == 1
replace owner_num = s3_q10_numowners if owner_status == 2

drop s3_*

*** De-identify the dataset **
save "$da/GE_ENT-Census-EL1_Analysis_ECMA.dta", replace
project, creates("$da/GE_ENT-Census-EL1_Analysis_ECMA.dta")
