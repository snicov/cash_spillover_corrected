
** THIS .DO FILE CREATES A UNIVERSE OF ALL ENTERPRISES AT BASELINE / MIDLINE / ENDLINE **
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
/* Note: it's unclear if this will actually do anything here, or if it will need to
   be a part of each file */
project, original("$dir/do/GE_global_setup.do")
include "$dir/do/GE_global_setup.do"

// end preliminaries

** Start with full census universe **
*************************************
project, original("$dr/GE_ENT-OwnerMatches_FINAL.dta")
use "$dr/GE_ENT-OwnerMatches_FINAL.dta", clear
// TK This will be changed to public version, though full(er) version may be useful for sorting out a few of the merge issues below.


ren  match ownerm_match
ren end_entcode entcode_EL
ren eligible ownerm_eligible
ren treat ownerm_treat
ren hh_sublocationcode ownerm_sublocation_code
ren hh_villagecode ownerm_village_code
ren hhid_key ownerm_hhid_key

keep entcode_EL ownerm_*
tempfile temp
save `temp'

project, uses("$da/intermediate/GE_ENT_BL_EL_Allcompiled_weights.dta") preserve
use "$da/intermediate/GE_ENT_BL_EL_Allcompiled_weights.dta", clear
keep if entcode_EL != .
merge 1:1 entcode_EL using `temp' // some don't match. Probably, the matchin ran on an older enterprise universe that didn't include enterprises only in the survey.
drop _merge
** TODO: Fix this **
tempfile temp1
save `temp1'

use "$da/intermediate/GE_ENT_BL_EL_Allcompiled_weights", clear
drop if entcode_EL != .
append using `temp1'

replace ownerm_sublocation_code = HH_AGENT_EL_ownerm_subloc_code if ownerm_sublocation_code == .
replace ownerm_village_code = HH_AGENT_EL_ownerm_village_code if ownerm_village_code == .
replace ownerm_eligible = HH_AGENT_EL_ownerm_eligible if ownerm_eligible == .
replace ownerm_treat = HH_AGENT_EL_ownerm_treat if ownerm_treat == .
replace ownerm_match = HH_AGENT_EL_ownerm_match if ownerm_match == .
replace ownerm_hhid_key = hhid_key if HH_AGENT_EL == 1

drop HH_AGENT_EL_ownerm_*
sleep 3000
save "$da/GE_ENT_BL_EL_AllCombined.dta", replace
project, creates("$da/GE_ENT_BL_EL_AllCombined.dta")
