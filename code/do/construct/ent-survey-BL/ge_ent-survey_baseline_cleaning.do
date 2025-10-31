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
project, original("$dr/GE_ENT-Survey-BL_PUBLIC.dta") preserve
use "$dr/GE_ENT-Survey-BL_PUBLIC.dta", clear


************************
** OPERATIONAL CHECKS **
************************


cap ren ent_id ent_id_BL
/*
** Merge in Endline tracking sheet -- this presumably contains the most up to date information
** TO CHECK: Is this true? Why don't all match? Were those deleted later for some reason? Why don't all enterprise ID's match?
preserve
project, original("$dr/GE_Endline_Ent_Census_Tracking_Dataset_2017-01-31.dta") preserve
use "$dr/GE_Endline_Ent_Census_Tracking_Dataset_2017-01-31.dta", clear
keep if data_source == "ENT_Census / ENT_Survey"
keep village_code key_ents ent_id
ren key_ents key
drop if ent_id == .
drop if key == ""
ren ent_id ent_id_new
tempfile temp
save `temp'
restore

merge 1:1 key using `temp'
drop if _merge == 1 // why is this one redundant?

** now make sure the enterprise ID is unique **
egen b = group(village_code ent_id_BL)
codebook b // yes, this is now unique!

drop b ent_id_new _merge
*/
** Clean location identifiers **
********************************
ren s1_q2a_location location_name
ren s1_q2b_sublocation sublocation_name


** Generate survey date **
**************************
ren today ENT_SUR_BL_date

**************************
** Section 1 - Cleaning **
**************************

** Check consent **
rename s1_consent consent

** fix open variables **
gen open = (s1_q4_isopen == 1) if s1_q4_isopen != .
gen open_7d = inlist(s1_q4_isopen,1,2) if s1_q4_isopen != .


** Physical Business Characteristics **
***************************************
rename s1_q3_operatefrom operate_from

label def operate_from 2 "Market stall / kiosk" 3 "own building" 4 "shared building" 5 "no building" 1 "homestead" 77 "other"
label val operate_from operate_from

rename s1_q8a_roof roof
replace roof = "1" if roof == "iron"
replace roof = "2" if roof == "grass1"
replace roof = "3" if roof == "grass2"
replace roof = "4" if roof == "mud"
replace roof = "5" if roof == "tiles"
replace roof = "6" if roof == "palm"
replace roof = "7" if roof == "cement"
replace roof = "12" if roof == "incomplete"
replace roof = "13" if roof == "none"
replace roof = "14" if roof == "canvas"
destring roof, replace

label def materials 1 "Iron/ Metal/ Steel" 2 "Grass thatch (no reeds)" 3 "Grass thatch (with reeds)" 4 "Mud" 5 "Tiles" 6 "Palm leaves/reeds" 7 "Cement" 8 "Brick" 9 "Mixed" 10 "Stone" 11 "Wooden" 12 "Unfinished/incomplete" 13 "None" 14 "Canvas"
label val roof materials
tab roof

rename s1_q8b_walls walls
replace walls = "1" if walls == "iron"
replace walls = "4" if walls == "mud"
replace walls = "5" if walls == "tiles"
replace walls = "7" if walls == "cement"
replace walls = "8" if walls == "brick"
replace walls = "9" if walls == "mixed"
replace walls = "5" if walls == "walls"
replace walls = "6" if walls == "reed"
replace walls = "10" if walls == "stone"
replace walls = "12" if walls == "incomplete"
replace walls = "11" if walls == "wood"
replace walls = "13" if walls == "none"
replace walls = "14" if walls == "canvas"
destring walls, replace

label val walls materials
tab walls

rename s1_q8c_floors floors
replace floors = "1" if floors == "iron"
replace floors = "4" if floors == "mud"
replace floors = "5" if floors == "tiles"
replace floors = "6" if floors == "reed"
replace floors = "7" if floors == "cement"
replace floors = "8" if floors == "brick"
replace floors = "9" if inlist(floors, "mixed", "half")
replace floors = "10" if floors == "stone"
replace floors = "12" if floors == "incomplete"
replace floors = "11" if floors == "wood"
replace floors = "13" if floors == "none"
replace floors = "14" if floors == "canvas"
destring floors, replace

label val floors materials
tab floors


** Business Categories **
*************************
rename s1_q6_bizcat bizcat
rename s1_q6a_bizcatproducts bizcat_products

** Secondary **
rename s1_q7_bizcatsecondary bizcatsec

split bizcatsec, gen(a_)
replace bizcatsec = a_1
gen bizcatter = a_2
gen bizcatquar = a_3
drop a_*

tab bizcatsec
tab bizcatter
tab bizcatquar

foreach v of var bizcatsec bizcatter bizcatquar {
	replace `v' = "1" if `v' == "tbc"
	replace `v' = "2" if `v' == "sretail"
	replace `v' = "3" if `v' == "mpesa"
	replace `v' = "4" if `v' == "mobilecharge"
	replace `v' = "5" if `v' == "bank"
	replace `v' = "6" if `v' == "lretail"
	replace `v' = "7" if `v' == "resto"
	replace `v' = "8" if `v' == "bar"
	replace `v' = "9" if `v' == "hardware"
	replace `v' = "10" if `v' == "barber"
	replace `v' = "11" if `v' == "salon"
	replace `v' = "12" if `v' == "butcher"
	replace `v' = "13" if `v' == "football"
	replace `v' = "14" if `v' == "cyber"
	replace `v' = "15" if `v' == "tailor"
	replace `v' = "16" if `v' == "bookshop"
	replace `v' = "17" if `v' == "posho"
	replace `v' = "18" if `v' == "welding"
	replace `v' = "29" if `v' == "carpenter"
	replace `v' = "20" if `v' == "guesthouse"
	replace `v' = "21" if `v' == "food"
	replace `v' = "22" if `v' == "foodstall"
	replace `v' = "23" if `v' == "chemist"
	replace `v' = "24" if `v' == "mechanic"
	replace `v' = "25" if `v' == "motorcycle_repair"
	replace `v' = "26" if `v' == "bike_repair"
	replace `v' = "27" if `v' == "petrol"
	replace `v' = "28" if `v' == "piki"
	replace `v' = "29" if `v' == "boda"
	replace `v' = "30" if `v' == "alcohol"
	replace `v' = "31" if `v' == "animal"
	replace `v' = "32" if `v' == "plough"
	replace `v' = "33" if `v' == "fishing"
	replace `v' = "34" if `v' == "fish"
	replace `v' = "35" if `v' == "cereal"
	replace `v' = "36" if `v' == "agrovet"
	replace `v' = "37" if `v' == "photostudio"
	replace `v' = "38" if `v' == "jaggery"
	replace `v' = "39" if `v' == "nfvendor"
	replace `v' = "40" if `v' == "nfproducer"
	replace `v' = "41" if `v' == "other"
	replace `v' = "42" if inlist(`v', "dk", "none")
	replace `v' = "51" if `v' == "nonfood"
	destring `v', replace

	label val `v' bizcat
}

tab bizcatsec
tab bizcatter
tab bizcatquar

rename s1_q7a_bizcatsecnonfood bizcatsec_nonfood

foreach v of var bizcatsec_nonfood { //bizcatter_nonfood bizcatquar_nonfood {
	replace `v' = "1" if `v' == "charcoal"
	replace `v' = "2" if `v' == "clothes"
	replace `v' = "3" if `v' == "electric"
	replace `v' = "4" if `v' == "parafiin"
	replace `v' = "5" if `v' == "wood"
	replace `v' = "6" if `v' == "shoes"
	replace `v' = "7" if `v' == "craft"
	replace `v' = "8" if `v' == "sand"
	replace `v' = "9" if `v' == "kerosene"
	replace `v' = "10" if `v' == "brick"
	replace `v' = "11" if `v' == "stone"
	replace `v' = "12" if `v' == "water"
	replace `v' = "13" if `v' == "gold"
	replace `v' = "14" if `v' == "other"
	destring `v', replace
}

label val bizcatsec_nonfood bizcat_nonfood
tab bizcatsec_nonfood

ren s1_q7a_bizcatsecproducts bizcatsec_products


** generate aggregated business categories **
*********************************************
foreach v in bizcat bizcatsec bizcatter bizcatquar {
	gen `v'_cons = .
	replace `v'_cons = 1 if inlist(`v', 21, 22, 12, 34)
	replace `v'_cons = 2 if inlist(`v', 28, 29, 27)
	replace `v'_cons = 3 if inlist(`v', 17, 1, 35, 38, 31, 36, 33, 32)
	replace `v'_cons = 4 if inlist(`v', 30, 2, 6, 23, 16, 9, 39)
	replace `v'_cons = 5 if inlist(`v', 10, 11, 15, 37, 3, 4, 5)
	replace `v'_cons = 6 if inlist(`v', 24, 18, 19, 26, 25)
	replace `v'_cons = 7 if inlist(`v', 7, 8, 13, 14, 20)
	replace `v'_cons = 8 if inlist(`v', 41, 42)

	label val `v'_cons bizcat_cons
}

** deal with non-food producers **
foreach v in bizcat bizcatsec {
	replace `v'_cons = 5 if `v' == 51 & inlist(`v'_nonfood, 2, 6)
	replace `v'_cons = 6 if `v' == 51 & inlist(`v'_nonfood, 1, 3, 4, 5, 7, 8, 9, 10, 11, 13)
	replace `v'_cons = 4 if `v' == 51 & inlist(`v'_nonfood, 12)
	replace `v'_cons = 6 if `v' == 51 & inlist(`v'_nonfood, 14)
}

order location_code sublocation_code village_code ent_id_BL ENT_SUR_BL_date consent open open_7d roof walls floors operate_from bizcat bizcat_products bizcat_nonfood bizcatsec bizcatsec_products bizcatsec_nonfood bizcatter bizcatquar bizcat_cons bizcatsec_cons bizcatter_cons bizcatquar_cons


***********************************************
** Clean up enterprise variables - section 2 **
***********************************************

** Ownership information **
***************************
gen owner_f = (s2_q2_gender == "F") if inlist(s1_q9_isowner,1,2)

** owner education **
gen owner_education = .
gen owner_primary = .
gen owner_secondary = .
gen owner_degree = .

replace owner_education = 0 if s2_q12_schsystem == "noschl"
replace owner_primary = 0 if s2_q12_schsystem == "noschl"
replace owner_secondary = 0 if s2_q12_schsystem == "noschl"
replace owner_degree = 0 if s2_q12_schsystem == "noschl"

destring s2_q12_highested, replace
replace owner_education = s2_q12_highested - 100 if s2_q12_schsystem == "current" & inrange(s2_q12_highested,100,112)
replace owner_education = 12 + 2 if s2_q12_schsystem == "current" & inlist(s2_q12_highested,115,117,119)
replace owner_education = 12 + 4 if s2_q12_schsystem == "current" & inlist(s2_q12_highested,116,118,120)
replace owner_education = 12 + 6 if s2_q12_schsystem == "current" & s2_q12_highested == 121

replace owner_primary = 1 if s2_q12_schsystem == "current" & inrange(s2_q12_highested,108,121)
replace owner_secondary = 1 if s2_q12_schsystem == "current" & inrange(s2_q12_highested,112,121)
replace owner_degree = 1 if s2_q12_schsystem == "current" & inlist(s2_q12_highested,116,118,120,121)

replace owner_education = s2_q12_highested - 200 if s2_q12_schsystem == "previous" & inrange(s2_q12_highested,200,214)
replace owner_education = 13 + 2 if s2_q12_schsystem == "previous" & inlist(s2_q12_highested,215,217,219)
replace owner_education = 13 + 4 if s2_q12_schsystem == "previous" & inlist(s2_q12_highested,216,218,220)
replace owner_education = 13 + 6 if s2_q12_schsystem == "previous" & s2_q12_highested == 221

replace owner_primary = 1 if s2_q12_schsystem == "previous" & inrange(s2_q12_highested,207,221)
replace owner_secondary = 1 if s2_q12_schsystem == "previous" & inrange(s2_q12_highested,212,221)
replace owner_degree = 1 if s2_q12_schsystem == "previous" & inlist(s2_q12_highested,216,218,220,221)

replace owner_education = 0 if owner_education == . & inlist(s2_q12_highested,100,130,230)
replace owner_primary = 0 if owner_primary == . & inlist(s2_q12_highested,100,130,230)
replace owner_secondary = 0 if owner_secondary == . & inlist(s2_q12_highested,100,130,230)
replace owner_degree = 0 if owner_degree == . & inlist(s2_q12_highested,100,130,230)


** Owner residence information **
*********************************
gen owner_resident = (s2_q5_resident == 1) if inlist(s1_q9_isowner,1,2)
replace owner_resident = (s2_q11_ownerresident == 1) if inlist(s2_q11_ownerresident,3)



** Location information **
**************************
order subcounty location_code  sublocation_code village_code  ent_id_BL  ENT_SUR_BL_date consent open open_7d roof walls floors operate_from bizcat bizcat_products bizcat_nonfood bizcatsec bizcatsec_products bizcatsec_nonfood bizcatter bizcatquar bizcat_cons bizcatsec_cons bizcatter_cons bizcatquar_cons owner_*
drop s1_* s2_*


******************************************
** Clean up enterprise data - section 4 **
******************************************
replace s4_q10_busstart = . if year(s4_q10_busstart) == 1900

gen ent_start_year = year(s4_q10_busstart) if s4_q10_busstart != .
gen ent_start_month = month(s4_q10_busstart) if s4_q10_busstart != .

gen ent_age = mofd(ENT_SUR_BL_date) - mofd(s4_q10_busstart)
replace ent_age = 0 if ent_age < 0 // two enterprises have age less than zero: replace with zero.

** generate seasonality profile for each business **
foreach mon in jan feb mar apr may jun jul aug sep oct nov dec {
	gen op_`mon' = 1 if regexm(s4_q2_monthsworked,"`mon'") | regexm(s4_q2_monthsworked,"all")
	replace op_`mon' = 0 if op_`mon' == . & s4_q2_monthsworked != ""
}

** Seasonal indicator for any business that is closed in a given month of the year in all operational years **
gen a = 0
gen b = 0
foreach v of var op_* {
	replace a = a + 1 if `v' == 0
	replace b = b + 1 if `v' == .
}
gen op_seasonal = (a > 0)
replace op_seasonal = . if b == 12
drop a b

** generate operational months per year **
egen op_monperyear = rowtotal(op_jan op_feb op_mar op_apr op_may op_jun op_jul op_aug op_sep op_oct op_nov op_dec)

** operational days per week **
foreach day in M T W Th F Sa Su {
	egen op_`day' = noccur(s4_q1a_daysoperating) if s4_q1a_daysoperating != "", s("`day'")
	replace op_`day' = 1 if regexm(s4_q1a_daysoperating, "all")
}
replace op_T = op_T - op_Th if !regexm(s4_q1a_daysoperating, "all")

egen op_daysperweek = rowtotal(op_M op_T op_W op_Th op_F op_Sa op_Su) if s4_q1a_daysoperating != ""

** operational hours per week/day **
gen op_hoursperweek = s4_q1d_hrsopen
tab op_hoursperweek
list op_hours* s4_q1* if op_hoursperweek > op_daysperweek*24
list if op_hoursperweek > 7*24 & op_hoursperweek != .
replace op_hoursperweek = . if op_hoursperweek > 7*24 & op_hoursperweek != . // replacing impossible values as missing


** Customer information **
**************************
gen cust_perday = s4_q3_custyesterday
gen cust_perweek = s4_q4_custlastweek

replace cust_perday = . if inlist(cust_perday, 9999,99)
replace cust_perweek = . if inlist(cust_perweek, 9999,99)

list if cust_perweek < cust_perday // all seem consistent

gen cust_svillage = s4_q5a_custvillage if !inlist(s4_q5a_custvillage,-99,99,9999,88)
gen cust_ssublocation = s4_q5b_custsublocation if !inlist(s4_q5b_custsublocation,-99,99,9999,88)
gen cust_slocation = s4_q5c_custlocation if !inlist(s4_q5c_custlocation,-99,99,9999,88)
gen cust_stown = s4_q5d_custtown if !inlist(s4_q5d_custtown,-99,99,9999,88)
gen cust_sother = s4_q5e_custother if !inlist(s4_q5e_custother,-99,99,9999,88)

egen sumcheck = rowtotal(cust_s*), missing

foreach v of var cust_s* {
	replace `v' = . if cust_perweek == 0
	replace `v' = . if sumcheck == 0
	replace `v' = 100 if `v' == 1 & sumcheck == 1
}

list  sumcheck cust_* if sumcheck != 100 & sumcheck != . // most are enterprises with no customers, some are typos
list sumcheck cust_* if sumcheck == cust_perweek & sumcheck != 100 & sumcheck != . // those distributed customers instead of percentages
foreach v of var cust_s* {
	replace `v' = round(`v'/cust_perweek,0.01)*100 if sumcheck == cust_perweek & sumcheck != 100 & sumcheck != . // those distributed customers instead of percentages
}

list sumcheck cust_* if sumcheck != 100 & sumcheck != . & sumcheck != cust_perweek // most are enterprises with no customers, some are typos

egen a = rowtotal(cust_s*) if sumcheck != . & cust_perweek != 0
list a sumcheck cust_* if a != 100 & a != . // reallocate the remainder proportionally, they are all nearly 100
foreach v of var cust_s* {
	replace `v' = round(`v'/a,0.01)*100 if `v' != . & a != 100 & a != .
}
drop a


** Employee information **
**************************
gen emp_n = s4_q6_numemployees

** employee list **
gen emp_nl_tot = 0

gen emp_nl_family = 0
gen emp_nl_nonfamily = 0

gen emp_nl_f = 0
gen emp_nl_m = 0

gen emp_h_tot = 0

gen emp_h_family = 0
gen emp_h_nonfamily = 0

gen emp_h_f = 0
gen emp_h_m = 0

forval i = 1/5 {
	replace emp_nl_tot = emp_nl_tot + 1 if s4_q6_sex`i' != .
	replace emp_nl_f = emp_nl_f + 1 if s4_q6_sex`i' == 1
	replace emp_nl_m = emp_nl_m + 1 if s4_q6_sex`i' == 2

	replace emp_nl_family = emp_nl_family + 1 if !inlist(s4_q6_relationship`i',24,25,27,28,29,30,31,32,33,34,35,.)
	replace emp_nl_nonfamily = emp_nl_nonfamily + 1 if inlist(s4_q6_relationship`i',24,25,27,28,29,30,31,32,33,34,35)

	replace emp_h_tot = emp_h_tot + s4_q6_work`i' if s4_q6_sex`i' != . & s4_q6_work`i' != -99
	replace emp_h_f = emp_h_f + s4_q6_work`i' if s4_q6_sex`i' == 1 & s4_q6_work`i' != -99
	replace emp_h_m = emp_h_m + s4_q6_work`i' if s4_q6_sex`i' == 2 & s4_q6_work`i' != -99

	replace emp_h_family = emp_h_family + s4_q6_work`i' if !inlist(s4_q6_relationship`i',24,25,27,28,29,30,31,32,33,34,35,.) & s4_q6_work`i' != -99
	replace emp_h_nonfamily = emp_h_nonfamily + s4_q6_work`i' if inlist(s4_q6_relationship`i',24,25,27,28,29,30,31,32,33,34,35) & s4_q6_work`i' != -99
}

foreach v of var emp_nl_* emp_h_* {
	replace `v' = . if emp_n == . & inlist(emp_nl_tot,0,.)
}

** Reconcile the info from the roster and questions **
list emp_* if emp_nl_tot != emp_n // these seem to not have filled out the roster -- set missing

foreach v of var emp_h_* emp_nl_* {
	replace `v' = . if emp_nl_tot != emp_n
}

drop emp_nl_tot
rename emp_n emp_n_tot
rename emp_nl_* emp_n_*


** some consistency checks **
egen a = rowtotal(emp_n_f emp_n_m)
count if a != emp_n_tot & a != 0 // for those respondents, we did not know their gender

egen d = rowtotal(emp_n_family emp_n_nonfamily)
count if d != emp_n_tot & d != 0

** Those do not always match up, as there are missings. Leave those discrepancies for now **
drop a d


** Clean Enterprise Financial Information **
********************************************

** Costs **
gen wage_total = s4_q7_wagebill
replace wage_total = . if inlist(s4_q7_wagebill,-99,-98)

gen wage_h = wage_total/(emp_h_tot*52/12) // TK these seem really low compared to the 36000 average per person annual consumption expenditure
gen wage_m_pp = wage_total/emp_n_tot // TK these seem really low compared to the 36000 average per person annual consumption expenditure

** TODO: The problem is that we also count owners, and unpaid workers **

gen c_rent = s4_q11a_rent if !inlist(s4_q11a_rent,-99,99)
replace c_rent = 0 if s4_q11_ownpremises == 1

gen c_security = s4_q17_security if !inlist(s4_q17_security,-99,99)


** Revenues and profits **
gen rev_mon = s4_q8a_revenuesmth if !inlist(s4_q8a_revenuesmth,-88,-98,-99,99,999,9999)
gen rev_year = s4_q8b_reveneues12mth*12/min(12,ent_age) if !inlist(s4_q8b_reveneues12mth,-88,-98,-99,99,999,9999)

gen prof_mon = s4_q9a_profitmth if !inlist(s4_q9a_profitmth,-88,-98,-99,99,999,9999)
gen prof_year = s4_q9b_profit12mth*12/min(12,ent_age) if !inlist(s4_q9b_profit12mth,-88,-98,-99,99,999,9999)

** Flag inconsistencies **
gen revprof_incons = 0
replace revprof_incons = 1 if rev_mon > rev_year & rev_mon != .
replace revprof_incons = 1 if prof_mon > rev_mon & prof_mon != .
replace revprof_incons = 1 if prof_year > rev_year & prof_year != .
replace revprof_incons = 1 if prof_year == prof_mon & prof_year != .
replace revprof_incons = 1 if rev_year == rev_mon & prof_year != .


** Electricity **
rename s4_q12_haselectricity electricity
replace electricity = 2 - electricity

split s4_q12a_electricsource, gen(esource_)
gen electricity_national = (esource_1 == "1" | esource_2 == "1") if esource_1 != ""
gen electricity_genrator = (esource_1 == "2" | esource_2 == "2") if esource_1 != ""
gen electricity_battery = (esource_1 == "3" | esource_2 == "3") if esource_1 != ""
gen electricity_solar = (esource_1 == "4" | esource_2 == "4") if esource_1 != ""
drop esource_*

** Taxes and Fees **
gen d_licensed = 2 - s4_q13_islicensed if !inlist(s4_q13_islicensed, 3, -99, -88)
gen d_registered = 2 - s4_q16_isregistered if !inlist(s4_q13_islicensed, 3, -99, -88)

gen t_license = s4_q13a_licensecost
replace t_license = 0 if d_licensed == 0
replace t_license = . if inlist(s4_q13a_licensecost,-99,88,99)

gen t_marketfees = s4_q14_marketfees if !inlist(s4_q14_marketfees, -98,99)

gen t_county = s4_q15a_taxescounty if !inlist(s4_q15a_taxescounty,9999,999,99,-98,-99)
gen t_national = s4_q15b_taxesnational if !inlist(s4_q15b_taxesnational,9999,999,99,-98,-99)
gen t_chiefs = s4_q15c_taxeslocal if !inlist(s4_q15c_taxeslocal,9999,999,99,-98,-99)
gen t_other = s4_q15d_taxesother if !inlist(s4_q15d_taxesother,9999,999,99,-98,-99)


************************
/*** SAVING DATASET ***/
************************
drop s?_* sumcheck

** Label variables **
label var ent_id_BL "Baseline enterprise ID (unique with village_code)"
label var consent "Respondent consents to survey"
label var open "Enterprise is open"
label var open_7d "Enterprise was open in the last 7 days"
label var roof "Roof material"
label var walls "Wall material"
label var floors "Floor material"
label var operate_from "Business operates from"
label var bizcat "Business category"
label var bizcat_products "Business category - main products"
label var bizcat_nonfood "Non-food business category"
label var bizcatsec "Secondary business category"
label var bizcatsec_nonfood "Secondary non-food business category"
label var bizcatsec_products "Secondary - main products"
label var bizcatter "Tertiary business category"
label var bizcatquar "Quaternary business category"
label var bizcat_cons "Business category (consolidated)"
label var bizcatsec_cons "Secondary business category (consolidated)"
label var bizcatter_cons "Tertiary business category (consolidated)"
label var bizcatquar_cons "Quaternary business category (consolidated)"

label var ent_start_year "Enterprise founding year"
label var ent_start_month "Enterprise founding month"
label var ent_age "Enterprise age in months"
label var op_jan "Was operational last January"
label var op_feb "Was operational last February"
label var op_mar "Was operational last March"
label var op_apr "Was operational last April"
label var op_may "Was operational last May"
label var op_jun "Was operational last June"
label var op_jul "Was operational last July"
label var op_aug "Was operational last August"
label var op_sep "Was operational last September"
label var op_oct "Was operational last October"
label var op_nov "Was operational last November"
label var op_dec "Was operational last December"
label var op_seasonal "Is a seasonal business"
label var op_monperyear "Months over the last year in which business was operational"
label var op_M "Was open last Monday"
label var op_T "Was open last Tuesday"
label var op_W "Was open last Wednesday"
label var op_Th "Was open last Thursday"
label var op_F "Was open last Friday"
label var op_Sa "Was open last Saturday"
label var op_Su "Was open last Sunday"
label var op_daysperweek "Days last week in which business was open"
label var op_hoursperweek "Number of hours open per week"

label var owner_f "Owner is female"
label var owner_education "Owner - years of education"
label var owner_primary "Owner - completed primary school"
label var owner_secondary "Owner - completed secondary school"
label var owner_degree  "Owner - has a degree"
label var owner_resident "Owner - resident in the same village"

label var cust_perday "Number of customers per day"
label var cust_perweek "Number of customers per week"
label var cust_svillage "Share of customers - from same village"
label var cust_ssublocation "Share of customers - from other villages in the same sublocation"
label var cust_slocation "Share of customers - from other sublocations in the same location"
label var cust_stown "Share of customers - from towns"
label var cust_sother "Share of customers - from other places"

label var emp_n_tot "Total number of employees"
label var emp_n_family "Number of family employees"
label var emp_n_nonfamily "Number of non-family employees"
label var emp_n_f "Number of female employees"
label var emp_n_m "Number of male employees"
label var emp_h_tot "Hours worked last week - total"
label var emp_h_family "Hours worked last week - family employees"
label var emp_h_nonfamily "Hours worked last week - non-family employees"
label var emp_h_f "Hours worked last week - female employees"
label var emp_h_m "Hours worked last week - male employees"
label var wage_total "Total wage bill last month"
label var wage_h "Implied average hourly wage"
label var wage_m_pp "Implied monthly wage per employee"

label var rev_mon "Revenues last month (in KES)"
label var rev_year "Revenues last year (in KES)"
label var prof_mon "Profits last month (in KES)"
label var prof_year "Profits last year (in KES)"
label var revprof_incons "Profits/Revenues flagged inconsistent"
label var c_rent "KES spent on rent"
label var c_security "KES spent on security"
label var electricity "Enterprise has electricity"
label var electricity_national "Business has electricity from national grid"
label var electricity_genrator "Business has electricity from a generator"
label var electricity_battery "Business has electricity from a battery"
label var electricity_solar "Business has electricity from solar panels"

label var d_licensed "Business is licensed with county government"
label var t_license "Spending on business license last year"
label var t_marketfees "Market fees last year"
label var d_registered "Business is registered with the government"
label var t_county "County taxes paid last year"
label var t_national "National taxes paid last year"
label var t_chiefs "Taxes paid to chiefs / assitant chiefs / village elders"
label var t_other "Other taxes paid"

order subcounty location_code location_name sublocation_code sublocation_name village_code ent_id_BL  ENT_SUR_BL_date consent open open_7d ///
roof walls floors operate_from bizcat* ///
ent_start_year ent_start_month ent_age op_* owner_* cust_* emp_* wage_* rev_* prof_* revprof_incons c_* electricity* ///
d_licensed d_registered t_license t_marketfees t_county t_national t_chiefs t_other

save "$da/GE_ENT-Survey-BL_Analysis_ECMA.dta", replace
project, creates("$da/GE_ENT-Survey-BL_Analysis_ECMA.dta")
