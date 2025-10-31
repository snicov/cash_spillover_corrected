
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
project, original("$dr/GE_ENT-Survey-EL1_PUBLIC.dta")
use "$dr/GE_ENT-Survey-EL1_PUBLIC.dta", clear


*******************************
******** CLEAN VARIABLES ******
*******************************

gen open = (s1_q8_isopen == 1)
gen open_7d = inlist(s1_q8_isopen,1,2)

ren s1_q7_stilloperates operational
replace operational = (2 - operational)

gen frtype = s1_q9_frtype

*****************************************************
** Clean up basic enterprise variables - section 2 **
*****************************************************

** Physical Business Characteristics **
***************************************
browse s2_q2a_operatefrom s2_q2a_operatefrom_other
replace s2_q2a_operatefrom_other = "" if s2_q2a_operatefrom_other == "."
gen operate_from = s2_q2a_operatefrom
replace operate_from = s1_q2a_operatefromclose if operate_from == . & s2_q2a_operatefrom_other == ""

replace operate_from = 2 if entcode_EL == 29503 // rack = market-stall
replace operate_from = 5 if entcode_EL == 21241 // piki shade = no building
replace operate_from = 5 if entcode_EL == 30976 // school gate = no building
replace operate_from = 1 if entcode_EL == 25002 // fo comments say both home and market

browse if operate_from == . // these are all those that did not consent
label def operate_from 2 "Market stall / kiosk" 3 "own building" 4 "shared building" 5 "no building" 1 "homestead" 77 "other"
label val operate_from operate_from
tab operate_from

rename s2_q2b_roof roof
replace roof = "1" if roof == "iron"
replace roof = "2" if roof == "grass1"
replace roof = "3" if roof == "grass2"
replace roof = "4" if roof == "mud"
replace roof = "6" if roof == "palm"
replace roof = "13" if roof == "none"
destring roof, replace

label def materials 1 "Iron/ Metal/ Steel" 2 "Grass thatch (no reeds)" 3 "Grass thatch (with reeds)" 4 "Mud" 5 "Tiles" 6 "Palm leaves/reeds" 7 "Cement" 8 "Brick" 9 "Mixed" 10 "Stone" 11 "Wooden" 12 "Unfinished/incomplete" 13 "None"
label val roof materials
tab roof


rename s2_q2c_walls walls
replace walls = "1" if walls == "iron"
replace walls = "4" if walls == "mud"
replace walls = "7" if walls == "cement"
replace walls = "8" if walls == "brick"
replace walls = "9" if walls == "mixed"
replace walls = "6" if walls == "reed"
replace walls = "12" if walls == "incomplete"
replace walls = "11" if walls == "wood"
replace walls = "13" if walls == "none"
destring walls, replace

label val walls materials
tab walls


rename s2_q2d_floors floors
replace floors = "1" if floors == "iron"
replace floors = "4" if floors == "mud"
replace floors = "5" if floors == "tiles"
replace floors = "7" if floors == "cement"
replace floors = "8" if floors == "brick"
replace floors = "9" if floors == "mixed"
replace floors = "10" if floors == "stone"
replace floors = "12" if floors == "incomplete"
replace floors = "11" if floors == "wood"
replace floors = "13" if floors == "none"
destring floors, replace

label val floors materials
tab floors


rename s2_q2e_primarylocmoved loc_moved
replace loc_moved = 2 - loc_moved


** Business Categories **
*************************
rename s2_q3_bizcat bizcat

replace s2_q3a_bizcatother = strlower(s2_q3a_bizcatother)
tab s2_q3a_bizcatother
replace bizcat = "foodstall" if inlist(s2_q3a_bizcatother,"dairy shop", "cuddled milk", "milk vendor", "sells milk")
replace bizcat = "butcher" if s2_q3a_bizcatother == "pork butcher"
replace bizcat = "chemist" if s2_q3a_bizcatother == "herbal medicine"

replace bizcat = "nfproducer" if inlist(s2_q3a_bizcatother, "tree seedlings", "tree nursery", "gold mine", "gold mill")
replace s2_q3c_bizcatnonfood = "gold" if inlist(s2_q3a_bizcatother, "gold mine", "gold mill")
replace s2_q3c_bizcatnonfood = "wood" if inlist(s2_q3a_bizcatother, "tree seedlings", "tree nursery")

replace bizcat = "nfvendor" if inlist(s2_q3a_bizcatother,"tents and chairs for hire", "liquid soap", "boutique")
replace s2_q3c_bizcatnonfood = "other" if inlist(s2_q3a_bizcatother, "tents and chairs for hire")
replace s2_q3c_bizcatnonfood = "craft" if s2_q3a_bizcatother == "liquid soap"
replace s2_q3c_bizcatnonfood = "clothes" if s2_q3a_bizcatother == "boutique"

replace bizcat = "sretail" if inlist(s2_q3a_bizcatother,"cigaretts", "sugarcane")
replace s2_q3b_bizcatproducts = "other" if s2_q3a_bizcatother == "cigaretts"
replace s2_q3b_bizcatproducts = "grocery" if s2_q3a_bizcatother == "sugarcane"

replace bizcat = "animal" if s2_q3a_bizcatother == "dairy farming"
replace bizcat = "chemist" if s2_q3a_bizcatother == "chemist"
replace bizcat = "tailor" if s2_q3a_bizcatother == "embroidery"
drop s2_q3a_bizcatother

replace bizcat = "1" if bizcat == "tbc"
replace bizcat = "2" if bizcat == "sretail"
replace bizcat = "3" if bizcat == "mpesa"
replace bizcat = "4" if bizcat == "mobilecharge"
replace bizcat = "5" if bizcat == "bank"
replace bizcat = "6" if bizcat == "lretail"
replace bizcat = "7" if bizcat == "resto"
replace bizcat = "8" if bizcat == "bar"
replace bizcat = "9" if bizcat == "hardware"
replace bizcat = "10" if bizcat == "barber"
replace bizcat = "11" if bizcat == "salon"
replace bizcat = "12" if bizcat == "butcher"
replace bizcat = "13" if bizcat == "football"
replace bizcat = "14" if bizcat == "cyber"
replace bizcat = "15" if bizcat == "tailor"
replace bizcat = "16" if bizcat == "bookshop"
replace bizcat = "17" if bizcat == "posho"
replace bizcat = "18" if bizcat == "welding"
replace bizcat = "19" if bizcat == "carpenter"
replace bizcat = "20" if bizcat == "guesthouse"
replace bizcat = "21" if bizcat == "food"
replace bizcat = "22" if bizcat == "foodstall"
replace bizcat = "23" if bizcat == "chemist"
replace bizcat = "24" if bizcat == "mechanic"
replace bizcat = "25" if bizcat == "motorcycle_repair"
replace bizcat = "26" if bizcat == "bike_repair"
replace bizcat = "27" if bizcat == "petrol"
replace bizcat = "28" if bizcat == "piki"
replace bizcat = "29" if bizcat == "boda"
replace bizcat = "30" if bizcat == "alcohol"
replace bizcat = "31" if bizcat == "animal"
replace bizcat = "32" if bizcat == "plough"
replace bizcat = "33" if bizcat == "fishing"
replace bizcat = "34" if bizcat == "fish"
replace bizcat = "35" if bizcat == "cereal"
replace bizcat = "36" if bizcat == "agrovet"
replace bizcat = "37" if bizcat == "photostudio"
replace bizcat = "38" if bizcat == "jaggery"
replace bizcat = "39" if bizcat == "nfvendor"
replace bizcat = "40" if bizcat == "nfproducer"
replace bizcat = "41" if bizcat == "other"
replace bizcat = "42" if bizcat == "none"
destring bizcat, replace

label def bizcat 1 "Tea buying centre" 2 "Small retail" 3 "M-Pesa" 4 "Mobile charging" 5 "Bank agent" 6 "Large retail" 7 "Restaurant" 8 "Bar" 9 "Hardware store" 10 "Barber shop" 11 "Beauty shop / Salon" 12 "Butcher" 13 "Video Room/Football hall" 14 "Cyber café" 15 "Tailor" 16 "Bookshop" 17 "Posho mill" 18 "Welding / metalwork" 19 "Carpenter" 20 "Guesthouse/ Hotel" ///
21 "Food stand / Prepared food vendor" 22 "Food stall / Raw food and fruits vendor" 23 "Chemist" 24 "Motor Vehicles Mechanic" 25 "Motorcycle Repair / Shop" 26 "Bicycle repair / mechanic shop" 27 "Petrol station" 28 "Piki driver" 29 "Boda driver" 30 "Sale or brewing of homemade alcohol / liquor" 31 "Livestock / Animal (Products) / Poultry Sale" 32 "Oxen / donkey / tractor plouging" 33 "Fishing" 34 "Fish Sale / Mongering" 35 "Cereals" 36 "Agrovet" 37 "Photo studio" 38 "Jaggery" 39 "Non-Food Vendor" 40 "Non-Food Producer" ///
41 "Other (specify)" 42 "None", replace
label val bizcat bizcat
tab bizcat

rename s2_q3b_bizcatproducts bizcat_products
replace bizcat_products = "1" if bizcat_products == "grocery"
replace bizcat_products = "2" if bizcat_products == "household"
replace bizcat_products = "3" if bizcat_products == "other"
destring bizcat_products, replace

label def bizcat_products 1 "Groceries" 2 "Household goods" 3 "All other retail"
label val bizcat_products bizcat_products
tab bizcat_products

rename s2_q3c_bizcatnonfood bizcat_nonfood
replace bizcat_nonfood = "1" if bizcat_nonfood == "charcoal"
replace bizcat_nonfood = "2" if bizcat_nonfood == "clothes"
replace bizcat_nonfood = "3" if bizcat_nonfood == "electric"
replace bizcat_nonfood = "4" if bizcat_nonfood == "parafiin"
replace bizcat_nonfood = "5" if bizcat_nonfood == "wood"
replace bizcat_nonfood = "6" if bizcat_nonfood == "shoes"
replace bizcat_nonfood = "7" if bizcat_nonfood == "craft"
replace bizcat_nonfood = "8" if bizcat_nonfood == "sand"
replace bizcat_nonfood = "9" if bizcat_nonfood == "kerosene"
replace bizcat_nonfood = "10" if bizcat_nonfood == "brick"
replace bizcat_nonfood = "11" if bizcat_nonfood == "stone"
replace bizcat_nonfood = "12" if bizcat_nonfood == "water"
replace bizcat_nonfood = "13" if bizcat_nonfood == "gold"
replace bizcat_nonfood = "14" if bizcat_nonfood == "other"
destring bizcat_nonfood, replace

label def bizcat_nonfood 1 "Charcoal sale / burning" 2 "Clothes / Mtumba / Boutique" 3 "Electric accesory/repair" 4 "Paraffin" 5 "Timber / Firewood" 6 "Shoes / Cobbler" 7 "Craftwork" 8 "Sand Sale / Harvesting" 9 "Kerosene" 10 "Brick Sale / Production" 11 "Stone / Ballast Sale or Production" 12 "Water Vendor" 13 "Gold" 14 "Other"
label val bizcat_nonfood bizcat_nonfood
tab bizcat_nonfood


** Secondary **
rename s2_q4_bizcatsec bizcatsec

replace s2_q4a_bizcatsecother = strlower(s2_q4a_bizcatsecother)
tab s2_q4a_bizcatsecother

replace bizcatsec = "alcohol" if inlist(s2_q4a_bizcatsecother, "alcohol")
replace bizcatsec = "mobilecharge" if inlist(s2_q4a_bizcatsecother, "mobile charging")

replace bizcatsec = "nfvendor" if inlist(s2_q4a_bizcatsecother,"chairs for hire", "owns a public address system aswel")
replace s2_q4c_bizcatsecnonfood = "other" if inlist(s2_q4a_bizcatsecother, "chairs for hire", "owns a public address system aswel")

replace bizcatsec = "nfproducer" if inlist(s2_q4a_bizcatsecother, "tree nursery")
replace s2_q4c_bizcatsecnonfood = "wood" if inlist(s2_q4a_bizcatsecother, "tree nursery")

replace bizcatsec = "sretail" if inlist(s2_q4a_bizcatsecother, "selling jikos", "selling sodas", "sugar")
replace s2_q4b_bizcatsecproducts = "household" if s2_q4a_bizcatsecother == "selling jikos"
replace s2_q4b_bizcatsecproducts = "grocery" if inlist(s2_q4a_bizcatsecother, "selling sodas", "sugar")
drop s2_q4b_bizcatsecproducts

replace bizcatsec = regexr(bizcatsec, " none", "")
replace bizcatsec = "" if bizcatsec == "none"
tab bizcatsec

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
	replace `v' = "42" if `v' == "none"
	destring `v', replace

	label val `v' bizcat
}

tab bizcatsec
tab bizcatter
tab bizcatquar

rename s2_q4c_bizcatsecnonfood bizcatsec_nonfood
replace bizcatsec_nonfood = "charcoal" if bizcatsec_nonfood == "charcoal parafiin"
replace bizcatsec_nonfood = "1" if bizcatsec_nonfood == "charcoal"
replace bizcatsec_nonfood = "2" if bizcatsec_nonfood == "clothes"
replace bizcatsec_nonfood = "3" if bizcatsec_nonfood == "electric"
replace bizcatsec_nonfood = "4" if bizcatsec_nonfood == "parafiin"
replace bizcatsec_nonfood = "5" if bizcatsec_nonfood == "wood"
replace bizcatsec_nonfood = "6" if bizcatsec_nonfood == "shoes"
replace bizcatsec_nonfood = "7" if bizcatsec_nonfood == "craft"
replace bizcatsec_nonfood = "8" if bizcatsec_nonfood == "sand"
replace bizcatsec_nonfood = "9" if bizcatsec_nonfood == "kerosene"
replace bizcatsec_nonfood = "10" if bizcatsec_nonfood == "brick"
replace bizcatsec_nonfood = "11" if bizcatsec_nonfood == "stone"
replace bizcatsec_nonfood = "12" if bizcatsec_nonfood == "water"
replace bizcatsec_nonfood = "13" if bizcatsec_nonfood == "gold"
replace bizcatsec_nonfood = "14" if bizcatsec_nonfood == "other"
destring bizcatsec_nonfood, replace

label val bizcatsec_nonfood bizcat_nonfood
tab bizcatsec_nonfood

replace bizcat_nonfood = 2 if entcode_EL == 26690 // from FO comments



** generate aggregated business categories **
*********************************************
label define bizcat_cons 1 "Food" 2 "Transport" 3 "Food Processing" 4 "Retail" 5 "Personal Services" 6 "Manufacturing" 7 "Hospitality" 8 "Other"

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
replace bizcat_cons = 5 if bizcat == 40 & inlist(bizcat_nonfood, 2, 6)
replace bizcat_cons = 6 if bizcat == 40 & inlist(bizcat_nonfood, 1, 3, 4, 5, 7, 8, 9, 10, 11, 13)
replace bizcat_cons = 4 if bizcat == 40 & inlist(bizcat_nonfood, 12)
replace bizcat_cons = 6 if bizcat == 40 & inlist(bizcat_nonfood, 14)

foreach v in bizcatsec bizcatter bizcatquar {
	replace `v'_cons = 5 if bizcat == 40 & inlist(bizcatsec_nonfood, 2, 6)
	replace `v'_cons = 6 if bizcat == 40 & inlist(bizcatsec_nonfood, 1, 3, 4, 5, 7, 8, 9, 10, 11, 13)
	replace `v'_cons = 4 if bizcat == 40 & inlist(bizcatsec_nonfood, 12)
	replace `v'_cons = 6 if bizcat == 40 & inlist(bizcatsec_nonfood, 14)
}

drop s1_* s2_*


***********************************************
** Clean up enterprise variables - section 3 **
***********************************************

** Ownership information **
***************************
browse if s3_ownercheck1 != . // there seems to have been some confusion, the FR is the owner, but is listed as employee
replace frtype = 1 if entcode_EL == 23327
replace frtype = . if s3_ownercheck2 != . // we do not know what frtype is for those, since they did not have to fill out what their relation to the owner is. Thus, set missing.

gen owner_f = (s3_q3a_ownergender == 2) if s3_q3a_ownergender != .
gen owner_age = s3_q3b_ownerage
replace owner_age = . if inlist(owner_age,-99, -96)

** owner education **
gen owner_education = .
gen owner_primary = .
gen owner_secondary = .
gen owner_degree = .

replace owner_education = 0 if s3_q3ca_edusystem == 2
replace owner_primary = 0 if s3_q3ca_edusystem == 2
replace owner_secondary = 0 if s3_q3ca_edusystem == 2
replace owner_degree = 0 if s3_q3ca_edusystem == 2

replace owner_education = s3_q3cb_owneredu - 100 if s3_q3ca_edusystem == 1 & inrange(s3_q3cb_owneredu,100,112)
replace owner_education = 12 + 2 if s3_q3ca_edusystem == 1 & inlist(s3_q3cb_owneredu,115,117,119)
replace owner_education = 12 + 4 if s3_q3ca_edusystem == 1 & inlist(s3_q3cb_owneredu,116,118,120)
replace owner_education = 12 + 6 if s3_q3ca_edusystem == 1 & s3_q3cb_owneredu == 121

replace owner_primary = 1 if s3_q3ca_edusystem == 1 & inrange(s3_q3cb_owneredu,108,121)
replace owner_secondary = 1 if s3_q3ca_edusystem == 1 & inrange(s3_q3cb_owneredu,112,121)
replace owner_degree = 1 if s3_q3ca_edusystem == 1 & inlist(s3_q3cb_owneredu,116,118,120,121)


replace owner_education = s3_q3cb_owneredu - 200 if s3_q3ca_edusystem == 3 & inrange(s3_q3cb_owneredu,200,214)
replace owner_education = 13 + 2 if s3_q3ca_edusystem == 3 & inlist(s3_q3cb_owneredu,215,217,219)
replace owner_education = 13 + 4 if s3_q3ca_edusystem == 3 & inlist(s3_q3cb_owneredu,216,218,220)
replace owner_education = 13 + 6 if s3_q3ca_edusystem == 3 & s3_q3cb_owneredu == 221

replace owner_primary = 1 if s3_q3ca_edusystem == 3 & inrange(s3_q3cb_owneredu,207,221)
replace owner_secondary = 1 if s3_q3ca_edusystem == 3 & inrange(s3_q3cb_owneredu,212,221)
replace owner_degree = 1 if s3_q3ca_edusystem == 3 & inlist(s3_q3cb_owneredu,216,218,220,221)


replace owner_education = 0 if owner_education == . & s3_q3cc_owneredu == 888
replace owner_education = s3_q3cc_owneredu - 200 if owner_education == . & inrange(s3_q3cc_owneredu,201,208)
replace owner_education = s3_q3cc_owneredu - 201 if owner_education == . & inrange(s3_q3cc_owneredu,209,214)
replace owner_education = 13 + 2 if owner_education == .  & inlist(s3_q3cc_owneredu,215,217,219)
replace owner_education = 13 + 4 if owner_education == .  & inlist(s3_q3cc_owneredu,216,218,220)
replace owner_education = 13 + 6 if owner_education == .  & s3_q3cc_owneredu == 221

replace owner_primary = 1 if owner_primary == . & inrange(s3_q3cc_owneredu,207,221)
replace owner_secondary = 1 if owner_secondary == . & inrange(s3_q3cc_owneredu,212,221)
replace owner_degree = 1 if owner_degree == . & inlist(s3_q3cc_owneredu,216,218,220,221)

replace owner_primary = 0 if owner_primary == . & owner_education != .
replace owner_secondary = 0 if owner_secondary == . & owner_education != .
replace owner_degree = 0 if owner_degree == . & owner_education != .



** merge in owner residence information here **
preserve
project, uses("$da/GE_ENT-Census-EL1_Analysis_ECMA.dta") preserve
use "$da/GE_ENT-Census-EL1_Analysis_ECMA.dta", clear
keep entcode_EL owner_resident owner_*code owner_*county owner*location_code owner_village_code
foreach v of var owner_* {
	ren `v' `v'_cen
}
tempfile temp
save `temp'
restore

merge 1:1 entcode_EL using `temp'
drop if _merge == 2
drop _merge

gen owner_resident = (s3_q6_ownerresident == 1) if s3_q6_ownerresident != .
tab owner_resident owner_resident_cen // most agree, but trust survey where possible
replace owner_resident = owner_resident_cen if owner_resident == .

** TK revisit these around de-identification
gen double owner_location_code = location_code if owner_resident == 1
gen double owner_sublocation_code = sublocation_code if owner_resident == 1
gen double owner_village_code = village_code if owner_resident == 1

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

gen owner_county = "SIAYA" if subcounty != .
ren subcounty owner_subcounty
ren location_code owner_location_code
ren sublocation_code owner_sublocation_code
ren village_code owner_village_code

ren a location_code
ren b sublocation_code
ren c village_code

codebook s3_q8a_countyoth s3_q8a_ownsubcountyoth s3_q8b_ownlocationoth s3_q8c_ownsublocationoth s3_q8d_ownvillageoth

replace owner_county = owner_county_cen if owner_county == ""
replace owner_subcounty = owner_subcounty_cen if owner_subcounty == .
replace owner_location_code = owner_location_code_cen if owner_location_code == .
replace owner_sublocation_code = owner_sublocation_code_cen if owner_sublocation_code == .
replace owner_village_code = owner_village_code_cen if owner_village_code == .
drop owner_resident_cen owner_*_cen
format *_code %13.0f


** Deal with 'other' locations/sublocations/villages **
** Those are all from the census, use from there **

** Ownership status **
gen owner_status = 1 if s3_q1_isowner == 1
replace owner_status = 1 if s3_q1_isowner == 3 & s3_q9_ownstatus == 1

replace owner_status = 2 if s3_q1_isowner == 2
replace owner_status = 2 if s3_q1_isowner == 3 & s3_q9_ownstatus == 2

label def ownstatus 1 "single ownership" 2 "joint ownership"
label val owner_status ownstatus

gen owner_num = 1 if owner_status == 1
replace owner_num = s3_q10_numowners if owner_status == 2

** TK not using section 4 here -- drop in public data

******************************************
** Clean up enterprise data - section 5 **
******************************************
replace s5_q1_busstartyr = . if s5_q1_busstartyr == -99
replace s5_q1_busstartmon = . if s5_q1_busstartmon == -99

gen ent_age = (year(end_sur_date) - s5_q1_busstartyr)*12 + month(end_sur_date) - s5_q1_busstartmon if s5_q1_busstartyr != . &  s5_q1_busstartmon != .
replace ent_age = max(1,(year(end_sur_date) - s5_q1_busstartyr)*12) if s5_q1_busstartyr != . & s5_q1_busstartmon == .
replace ent_age = 0 if ent_age < 0 // two enterprises have age less than zero: replace with zero.

gen ent_start_year = s5_q1_busstartyr if !inlist(s5_q1_busstartyr,.,-99)
gen ent_start_month = s5_q1_busstartmon if !inlist(s5_q1_busstartmon,.,-99)

** Set operational missing before business start date **
** generate last non-operational month **
gen startmo = "dec" + substr(string(s5_q1_busstartyr-1),3,2) if month(dofm(ym(s5_q1_busstartyr, s5_q1_busstartmon))) == 1 & s5_q1_busstartyr != -99 & s5_q1_busstartmon != -99
replace startmo = "jan" + substr(string(s5_q1_busstartyr),3,2) if month(dofm(ym(s5_q1_busstartyr, s5_q1_busstartmon))) == 2 & s5_q1_busstartyr != -99 & s5_q1_busstartmon != -99
replace startmo = "feb" + substr(string(s5_q1_busstartyr),3,2) if month(dofm(ym(s5_q1_busstartyr, s5_q1_busstartmon))) == 3 & s5_q1_busstartyr != -99 & s5_q1_busstartmon != -99
replace startmo = "mar" + substr(string(s5_q1_busstartyr),3,2) if month(dofm(ym(s5_q1_busstartyr, s5_q1_busstartmon))) == 4 & s5_q1_busstartyr != -99 & s5_q1_busstartmon != -99
replace startmo = "apr" + substr(string(s5_q1_busstartyr),3,2) if month(dofm(ym(s5_q1_busstartyr, s5_q1_busstartmon))) == 5 & s5_q1_busstartyr != -99 & s5_q1_busstartmon != -99
replace startmo = "may" + substr(string(s5_q1_busstartyr),3,2) if month(dofm(ym(s5_q1_busstartyr, s5_q1_busstartmon))) == 6 & s5_q1_busstartyr != -99 & s5_q1_busstartmon != -99
replace startmo = "jun" + substr(string(s5_q1_busstartyr),3,2) if month(dofm(ym(s5_q1_busstartyr, s5_q1_busstartmon))) == 7 & s5_q1_busstartyr != -99 & s5_q1_busstartmon != -99
replace startmo = "jul" + substr(string(s5_q1_busstartyr),3,2) if month(dofm(ym(s5_q1_busstartyr, s5_q1_busstartmon))) == 8 & s5_q1_busstartyr != -99 & s5_q1_busstartmon != -99
replace startmo = "aug" + substr(string(s5_q1_busstartyr),3,2) if month(dofm(ym(s5_q1_busstartyr, s5_q1_busstartmon))) == 9 & s5_q1_busstartyr != -99 & s5_q1_busstartmon != -99
replace startmo = "sep" + substr(string(s5_q1_busstartyr),3,2) if month(dofm(ym(s5_q1_busstartyr, s5_q1_busstartmon))) == 10 & s5_q1_busstartyr != -99 & s5_q1_busstartmon != -99
replace startmo = "oct" + substr(string(s5_q1_busstartyr),3,2) if month(dofm(ym(s5_q1_busstartyr, s5_q1_busstartmon))) == 11 & s5_q1_busstartyr != -99 & s5_q1_busstartmon != -99
replace startmo = "nov" + substr(string(s5_q1_busstartyr),3,2) if month(dofm(ym(s5_q1_busstartyr, s5_q1_busstartmon))) == 12 & s5_q1_busstartyr != -99 & s5_q1_busstartmon != -99

foreach m in jan17 dec16 nov16 oct16 sep16 aug16 jul16 jun16 may16 apr16 mar16 feb16 jan16 dec15 nov15 oct15 sep15 aug15 {
	replace s5_q2_op`m' = . if startmo == "`m'"
}

foreach m in jan17 dec16 nov16 oct16 sep16 aug16 jul16 jun16 may16 apr16 mar16 feb16 jan16 dec15 nov15 oct15 sep15 aug15 {
	foreach v of var s5_q2_op`m'-s5_q2_opaug15 {
		replace `v' = . if startmo == "`m'"
	}
}

drop startmo

** generate seasonality profile for each business **
foreach mon in jan feb mar apr may jun jul aug sep oct nov dec {
	egen op_`mon' = anycount(s5_q2_op`mon'*), v(1)
	egen b = anycount(s5_q2_op`mon'*), v(2)
	replace op_`mon' = op_`mon'/(op_`mon' + b)
	drop b
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
egen a = anycount(s5_q2_op*), v(1)
egen b = anycount(s5_q2_op*), v(2)

gen op_monperyear = round(a/(a+b)*12,1) if a > 0
drop a b

** operational days per week **
foreach day in M T W Th F Sa Su {
	egen op_`day' = noccur(s5_q3_daysoperating) if s5_q3_daysoperating != "", s("`day'")
	replace op_`day' = 1 if s5_q3_daysoperating == "all"
}
replace op_T = op_T - op_Th if s5_q3_daysoperating != "all"

egen op_daysperweek = rowtotal(op_M op_T op_W op_Th op_F op_Sa op_Su) if s5_q3_daysoperating != ""

** operational hours per week/day **
gen op_hoursperweek = s5_q3b_bizhrswk
replace op_hoursperweek = . if op_hoursperweek == -99
tab op_hoursperweek
browse op_hours* s5_q3* if op_hoursperweek > op_daysperweek*24
** some of those are inconsistent: they may have answered them in general, rather than about last week in particular

browse if op_hoursperweek > 7*24 & op_hoursperweek != .
replace op_hoursperweek = . if op_hoursperweek > 7*24 & op_hoursperweek != .


gen op_hoursperday = s5_q3a_bizhrsday
replace op_hoursperday = . if op_hoursperday == -99
browse if op_hoursperday > 24 & op_hoursperday != . // most of those are the same as hours per week - replace by dividing through number of open days

replace op_hoursperday = op_hoursperday / op_daysperweek if op_hoursperday == op_hoursperweek
replace op_hoursperday = . if op_hoursperday > 24

** check consistency **
browse op_hours* s5_q3* if op_hoursperday > op_hoursperweek

** leave inconsistencies for now - it was often not clear whether the answers apply in general, or over the last 7 days...

** Customer information **
**************************
gen cust_perday = s5_q3_custyesterday
gen cust_perweek = s5_q4_custlastweek

replace cust_perday = . if cust_perday == -99
replace cust_perweek = . if cust_perweek == -99

browse if cust_perweek < cust_perday // all seem consistent

gen cust_svillage = s5_q5a_custvillage
gen cust_ssublocation = s5_q5b_custsublocation
gen cust_slocation = s5_q5c_custlocation
gen cust_stown = s5_q5d_custtown
gen cust_sother = s5_q5e_custother

browse cust_* if s5_q5_sumcheck != 100 & s5_q5_sumcheck != . // most are enterprises with no customers, some are typos
foreach v of var cust_s* {
	replace `v' = . if cust_perweek == 0
	replace `v' = 100 if `v' == 1000
}
egen a = rowtotal(cust_s*) if s5_q5_sumcheck != . & cust_perweek != 0
browse a cust_* if a != 100 & a != . // reallocate the remainder proportionally
foreach v of var cust_s* {
	replace `v' = round(`v'/a,0.01)*100 if a != 100 & a != .
}
drop a


** Employee information **
**************************
gen emp_n = s5_q6_numemployees

** Only 8 enterprises had more than 5 employees **
gen emp_n_perm = s5_q8i_empperm
gen emp_n_temp = s5_q8ii_emptemp
gen emp_n_family = s5_q8iii_empfam

count if emp_n_perm > emp_n & emp_n_perm != .
count if emp_n_temp > emp_n & emp_n_perm != .
count if emp_n_family > emp_n & emp_n_perm != .
** all zero, so should work **

** employee list **
gen emp_nl_tot = 0

gen emp_nl_perm = 0
gen emp_nl_temp = 0
gen emp_nl_other = 0

gen emp_nl_family = 0
gen emp_nl_nonfamily = 0

gen emp_nl_f = 0
gen emp_nl_m = 0

gen emp_nl_formal = 0
gen emp_nl_informal = 0


gen emp_h_tot = 0

gen emp_h_perm = 0
gen emp_h_temp = 0
gen emp_h_other = 0

gen emp_h_family = 0
gen emp_h_nonfamily = 0

gen emp_h_f = 0
gen emp_h_m = 0

gen emp_h_formal = 0
gen emp_h_informal = 0

forval i = 1/5 {
	replace emp_nl_tot = emp_nl_tot + 1 if ~mi(s5_empisfr_`i')
	replace emp_nl_f = emp_nl_f + 1 if s5_q6_sex_`i' == 1
	replace emp_nl_m = emp_nl_m + 1 if s5_q6_sex_`i' == 2

	replace emp_nl_f = emp_nl_f + 1 if s5_empisfr_`i' == 1 & frtype == 1 & owner_f == 1
	replace emp_nl_m = emp_nl_m + 1 if s5_empisfr_`i' == 1 & frtype == 1 & owner_f == 0

	replace emp_nl_f = emp_nl_f + 1 if s5_empisfr_`i' == 1 & frtype == 2 & s3_q2_empgender == 1
	replace emp_nl_m = emp_nl_m + 1 if s5_empisfr_`i' == 1 & frtype == 2 & s3_q2_empgender == 2

	replace emp_nl_formal = emp_nl_formal + 1 if inlist(s5_q9_empstatus_`i',1,4)
	replace emp_nl_informal = emp_nl_informal + 1 if !inlist(s5_q9_empstatus_`i',1,4,.)

	replace emp_nl_perm = emp_nl_perm + 1 if inlist(s5_q9_empstatus_`i',1,2,3)
	replace emp_nl_temp = emp_nl_temp + 1 if inlist(s5_q9_empstatus_`i',4,5,6,7,10)
	replace emp_nl_other = emp_nl_other + 1 if inlist(s5_q9_empstatus_`i',8,9)

	replace emp_nl_family = emp_nl_family + 1 if !inlist(s5_q6_relationship_`i',24,25,27,28,29,30,31,32,33,34,35,.)
	replace emp_nl_nonfamily = emp_nl_nonfamily + 1 if inlist(s5_q6_relationship_`i',24,25,27,28,29,30,31,32,33,34,35)

	replace emp_h_tot = emp_h_tot + s5_q6_work_`i' if ~mi(s5_empisfr_`i') & s5_q6_work_`i' != -99
	replace emp_h_f = emp_h_f + s5_q6_work_`i' if s5_q6_sex_`i' == 1 & s5_q6_work_`i' != -99
	replace emp_h_m = emp_h_m + s5_q6_work_`i' if s5_q6_sex_`i' == 2 & s5_q6_work_`i' != -99

	replace emp_h_formal = emp_h_formal + s5_q6_work_`i' if inlist(s5_q9_empstatus_`i',1,4) & s5_q6_work_`i' != -99
	replace emp_h_informal = emp_h_informal + s5_q6_work_`i' if !inlist(s5_q9_empstatus_`i',1,4,.) & s5_q6_work_`i' != -99

	replace emp_h_perm = emp_h_perm + s5_q6_work_`i' if inlist(s5_q9_empstatus_`i',1,2,3) & s5_q6_work_`i' != -99
	replace emp_h_temp = emp_h_temp + s5_q6_work_`i' if inlist(s5_q9_empstatus_`i',4,5,6,7,10) & s5_q6_work_`i' != -99
	replace emp_h_other = emp_h_other + s5_q6_work_`i' if inlist(s5_q9_empstatus_`i',8,9) & s5_q6_work_`i' != -99

	replace emp_h_family = emp_h_family + s5_q6_work_`i' if !inlist(s5_q6_relationship_`i',24,25,27,28,29,30,31,32,33,34,35,.) & s5_q6_work_`i' != -99
	replace emp_h_nonfamily = emp_h_nonfamily + s5_q6_work_`i' if inlist(s5_q6_relationship_`i',24,25,27,28,29,30,31,32,33,34,35) & s5_q6_work_`i' != -99
}

foreach v of var emp_nl_* emp_h_* {
	replace `v' = . if emp_n == . & inlist(emp_nl_tot,0,.)
}

browse if emp_nl_tot != emp_n

** Reconcile the info from the roster and questions **
replace emp_nl_tot = emp_n if emp_n > 5
replace emp_nl_perm = emp_n_perm if emp_n > 5
replace emp_nl_temp = emp_n_temp if emp_n > 5
replace emp_nl_family = emp_n_family if emp_n > 5

foreach v of var emp_h_* emp_nl_f emp_nl_m emp_nl_formal emp_nl_informal {
	replace `v' = . if emp_n > 5
}

drop emp_n emp_n_* // for the remaining 7 discrepancies, believe the roster. It seems that the owner was not counted as an employee for those enterprises, but the information later given.
rename emp_nl_* emp_n_*

** some consistency checks **
egen a = rowtotal(emp_n_f emp_n_m)
count if a != emp_n_tot & a != 0 // for those respondents, we did not know their gender

egen b = rowtotal(emp_n_formal emp_n_informal)
count if b != emp_n_tot & b != 0

egen c = rowtotal(emp_n_perm emp_n_temp emp_n_other)
count if c != emp_n_tot & c != 0

egen d = rowtotal(emp_n_family emp_n_nonfamily)
count if d != emp_n_tot & d != 0

** Those do not always match up, as there are missings. Keep as-is
drop a b c d



** Clean Enterprise Financial Information **
********************************************

** Costs **
gen wage_total = s5_q7_wagebill
replace wage_total = . if inlist(s5_q7_wagebill,-99,-98)

gen wage_h = wage_total/(emp_h_tot*52/12) // these seem really low compared to the 36000 average per person annual consumption expenditure
gen wage_m_pp = wage_total/emp_n_tot // these seem really low compared to the 36000 average per person annual consumption expenditure

** TODO: The problem is that we also count owners, and unpaid workers **

gen c_rent= s5_q11a_rent
replace c_rent = 0 if s5_q11_ownpremises == 1
replace c_rent = . if s5_q11a_rent == -99

gen c_security = s5_q17_security


** Revenues and profits **
gen rev_mon = s5_q8a_revenuesmth
replace rev_mon = . if inlist(s5_q8a_revenuesmth,-98,-99)

gen rev_year = s5_q8b_reveneues12mth*12/min(12,ent_age)
replace rev_year = . if inlist(s5_q8b_reveneues12mth,-98,-99)

gen prof_mon = s5_q9a_profitmth
replace prof_mon = . if inlist(s5_q9a_profitmth,-88,-98,-99,99)

gen prof_year = s5_q9b_profit12mth*12/min(12,ent_age)
replace prof_year = . if inlist(s5_q9b_profit12mth,-88,-98,-99,99)


** Flag inconsistencies **
gen revprof_incons = 0
replace revprof_incons = 1 if rev_mon > rev_year & rev_mon != .
replace revprof_incons = 1 if prof_mon > rev_mon & prof_mon != .
replace revprof_incons = 1 if prof_year > rev_year & prof_year != .
replace revprof_incons = 1 if prof_year == prof_mon & prof_year != .
replace revprof_incons = 1 if rev_year == rev_mon & prof_year != .

** Investment **
gen inv_mon = s5_q19a_investmth
replace inv_mon = . if s5_q19a_investmth == -99
replace inv_mon = 0 if s5_q17_hasinvest == 2

gen inv_year = s5_q19b_invest12mth
replace inv_year = . if s5_q19b_invest12mth == -99
replace inv_year = 0 if s5_q17_hasinvest == 2

** Funding sources **
split s5_q24_fundsources, gen(fundsource_)

gen fundsource_savings = (fundsource_1 == "1" | fundsource_2 == "1" | fundsource_3 == "1") if fundsource_1 != ""
gen fundsource_bizprof = (fundsource_1 == "2" | fundsource_2 == "2" | fundsource_3 == "2") if fundsource_1 != ""
gen fundsource_loan_bank = (fundsource_1 == "3" | fundsource_2 == "3" | fundsource_3 == "3") if fundsource_1 != ""
gen fundsource_loan_mlend = (fundsource_1 == "4" | fundsource_2 == "4" | fundsource_3 == "4") if fundsource_1 != ""
gen fundsource_loan_friends = (fundsource_1 == "5" | fundsource_2 == "5" | fundsource_3 == "5") if fundsource_1 != ""
gen fundsource_loan_relats = (fundsource_1 == "6" | fundsource_2 == "6" | fundsource_3 == "6") if fundsource_1 != ""
gen fundsource_loan_mshwari = (fundsource_1 == "7" | fundsource_2 == "7" | fundsource_3 == "7") if fundsource_1 != ""
gen fundsource_gift_friends = (fundsource_1 == "8" | fundsource_2 == "8" | fundsource_3 == "8") if fundsource_1 != ""
gen fundsource_gift_relats = (fundsource_1 == "9" | fundsource_2 == "9" | fundsource_3 == "9") if fundsource_1 != ""
gen fundsource_mergoroud = (fundsource_1 == "10" | fundsource_2 == "10" | fundsource_3 == "10") if fundsource_1 != ""
gen fundsource_sacco = (fundsource_1 == "11" | fundsource_2 == "11" | fundsource_3 == "11") if fundsource_1 != ""
gen fundsource_inherit = (fundsource_1 == "12" | fundsource_2 == "12" | fundsource_3 == "12") if fundsource_1 != ""
gen fundsource_retirefund = (fundsource_1 == "13" | fundsource_2 == "13" | fundsource_3 == "13") if fundsource_1 != ""
gen fundsource_ngoct = (fundsource_1 == "14" | fundsource_2 == "14" | fundsource_3 == "14") if fundsource_1 != ""

browse if !inlist(s5_q24_fundsourcesoth,".","")
replace fundsource_savings = 1 if s5_q24_fundsourcesoth == "Rent"
replace fundsource_savings = 1 if s5_q24_fundsourcesoth == "Sold trees cut from home"
replace fundsource_savings = 1 if s5_q24_fundsourcesoth == "Husband's money."
replace fundsource_ngoct = 1 if s5_q24_fundsourcesoth == "Gift from NGO"
replace fundsource_savings = 1 if s5_q24_fundsourcesoth == "Sold own animal to get money"
replace fundsource_bizprof = 1 if s5_q24_fundsourcesoth == "Maize"
replace fundsource_bizprof = 1 if s5_q24_fundsourcesoth == "Money from poultry sale"
replace fundsource_savings = 1 if s5_q24_fundsourcesoth == "Working in farms and doing other short chores."
replace fundsource_bizprof = 1 if s5_q24_fundsourcesoth == "Cash from selling farm produce."
drop fundsource_?

** Inventory **
gen inventory = s5_q26_inventoryamt
replace inventory = 0 if s5_q25_hasinventory == 2

** Electricity **
rename s5_q12_haselectricity electricity
replace electricity = 2 - electricity

split s5_q12a_electricsource, gen(esource_)
gen electricity_national = (esource_1 == "1" | esource_2 == "1") if esource_1 != ""
gen electricity_genrator = (esource_1 == "2" | esource_2 == "2") if esource_1 != ""
gen electricity_battery = (esource_1 == "3" | esource_2 == "3") if esource_1 != ""
gen electricity_solar = (esource_1 == "4" | esource_2 == "4") if esource_1 != ""
drop esource_*

** Taxes and Fees **
gen d_licensed = 2 - s5_q13_islicensed if !inlist(s5_q13_islicensed, -99, -88)

gen t_license = s5_q13a_licensecost
replace t_license = 0 if d_licensed == 0
replace t_license = . if inlist(s5_q13a_licensecost,-99,99)

gen t_marketfees = s5_q14_marketfees

gen d_registered = 2 - s5_q16_isregistered if !inlist(s5_q16_isregistered, -99)
gen d_llc = 2 - s5_q16a_llc if !inlist(s5_q16a_llc, -99)

gen d_vat = 2 - s5_q16b_vat if !inlist(s5_q16b_vat, -99)

gen t_vat = s5_q14b_vatamt
replace t_vat = 0 if d_vat == 0
replace t_vat = . if s5_q14b_vatamt == 99

gen t_county = s5_q15a_taxescounty
gen t_national = s5_q15b_taxesnational
gen t_chiefs = s5_q15c_taxeslocal
gen t_other = s5_q15d_taxesother


*****************************************************************
** Clean up enterprise data - section 6 - Business environment **
*****************************************************************
rename s6_producer s_producer
rename s6_retailer s_retailer

** productive capacity **
gen s_ly_cap_lower= (s6_e1a == 1) if inlist(s6_e1a,1,2,3)
gen s_ly_cap_higher= (s6_e1a == 3) if inlist(s6_e1a,1,2,3)
gen s_ly_cap_same= (s6_e1a == 2) if inlist(s6_e1a,1,2,3)
gen s_ly_cap = s6_e1a - 2  if inlist(s6_e1a,1,2,3)

gen s_lm_cap_lower= (s6_e1b == 1) if inlist(s6_e1b,1,2,3)
gen s_lm_cap_higher= (s6_e1b == 3) if inlist(s6_e1b,1,2,3)
gen s_lm_cap_same= (s6_e1b == 2) if inlist(s6_e1b,1,2,3)
gen s_lm_cap = s6_e1b - 2 if inlist(s6_e1b,1,2,3)

gen s_fy_cap_lower= (s6_e1c == 1) if inlist(s6_e1c,1,2,3)
gen s_fy_cap_higher= (s6_e1c == 3) if inlist(s6_e1c,1,2,3)
gen s_fy_cap_same= (s6_e1c == 2) if inlist(s6_e1c,1,2,3)
gen s_fy_cap = s6_e1c - 2 if inlist(s6_e1c,1,2,3)

gen s_f3m_cap_lower= (s6_e1d == 1) if inlist(s6_e1d,1,2,3)
gen s_f3m_cap_higher= (s6_e1d == 3) if inlist(s6_e1d,1,2,3)
gen s_f3m_cap_same= (s6_e1d == 2) if inlist(s6_e1d,1,2,3)
gen s_f3m_cap = s6_e1d - 2 if inlist(s6_e1d,1,2,3)

** production **
gen s_ly_prod_lower = (s6_e2a == 1) if inlist(s6_e2a,1,2,3)
gen s_ly_prod_higher = (s6_e2a == 3) if inlist(s6_e2a,1,2,3)
gen s_ly_prod_same = (s6_e2a == 2) if inlist(s6_e2a,1,2,3)
gen s_ly_prod = s6_e2a - 2 if inlist(s6_e2a,1,2,3)

gen s_lm_prod_lower = (s6_e2b == 1) if inlist(s6_e2b,1,2,3)
gen s_lm_prod_higher = (s6_e2b == 3) if inlist(s6_e2b,1,2,3)
gen s_lm_prod_same = (s6_e2b == 2) if inlist(s6_e2b,1,2,3)
gen s_lm_prod = s6_e2b - 2 if inlist(s6_e2b,1,2,3)

gen s_fy_prod_lower = (s6_e2c == 1) if inlist(s6_e2c,1,2,3)
gen s_fy_prod_higher = (s6_e2c == 3) if inlist(s6_e2c,1,2,3)
gen s_fy_prod_same = (s6_e2c == 2) if inlist(s6_e2c,1,2,3)
gen s_fy_prod = s6_e2c - 2 if inlist(s6_e2c,1,2,3)

gen s_f3m_prod_lower = (s6_e2d == 1) if inlist(s6_e2d,1,2,3)
gen s_f3m_prod_higher = (s6_e2d == 3) if inlist(s6_e2d,1,2,3)
gen s_f3m_prod_same = (s6_e2d == 2) if inlist(s6_e2d,1,2,3)
gen s_f3m_prod = s6_e2d - 2 if inlist(s6_e2d,1,2,3)

** inventories **
gen s_ly_inventory_lower = (s6_e10a == 1) if inlist(s6_e10a,1,2,3)
gen s_ly_inventory_higher = (s6_e10a == 3) if inlist(s6_e10a,1,2,3)
gen s_ly_inventory_same = (s6_e10a == 2) if inlist(s6_e10a,1,2,3)
gen s_ly_inventory = s6_e10a - 2 if inlist(s6_e10a,1,2,3)

gen s_lm_inventory_lower = (s6_e10b == 1) if inlist(s6_e10b,1,2,3)
gen s_lm_inventory_higher = (s6_e10b == 3) if inlist(s6_e10b,1,2,3)
gen s_lm_inventory_same = (s6_e10b == 2) if inlist(s6_e10b,1,2,3)
gen s_lm_inventory = s6_e10b - 2 if inlist(s6_e10b,1,2,3)

gen s_fy_inventory_lower = (s6_e10c == 1) if inlist(s6_e10c,1,2,3)
gen s_fy_inventory_higher = (s6_e10c == 3) if inlist(s6_e10c,1,2,3)
gen s_fy_inventory_same = (s6_e10c == 2) if inlist(s6_e10c,1,2,3)
gen s_fy_inventory = s6_e10c - 2 if inlist(s6_e10c,1,2,3)

gen s_f3m_inventory_lower = (s6_e10d == 1) if inlist(s6_e10d,1,2,3)
gen s_f3m_inventory_higher = (s6_e10d == 3) if inlist(s6_e10d,1,2,3)
gen s_f3m_inventory_same = (s6_e10d == 2) if inlist(s6_e10d,1,2,3)
gen s_f3m_inventory = s6_e10d - 2 if inlist(s6_e10d,1,2,3)

** employment **
gen s_ly_emp_toomany = (s6_e3a == 1) if inlist(s6_e3a,1,2,3)
gen s_ly_emp_toofew = (s6_e3a == 3) if inlist(s6_e3a,1,2,3)
gen s_ly_emp_justright = (s6_e3a == 2) if inlist(s6_e3a,1,2,3)
gen s_ly_emp = s6_e3a - 2 if inlist(s6_e3a,1,2,3)

gen s_lm_emp_toomany = (s6_e3b == 1) if inlist(s6_e3b,1,2,3)
gen s_lm_emp_toofew = (s6_e3b == 3) if inlist(s6_e3b,1,2,3)
gen s_lm_emp_justright = (s6_e3b == 2) if inlist(s6_e3b,1,2,3)
gen s_lm_emp = s6_e3b - 2 if inlist(s6_e3b,1,2,3)

gen s_fy_emp_toomany = (s6_e3c == 1) if inlist(s6_e3c,1,2,3)
gen s_fy_emp_toofew = (s6_e3c == 3) if inlist(s6_e3c,1,2,3)
gen s_fy_emp_justright = (s6_e3c == 2) if inlist(s6_e3c,1,2,3)
gen s_fy_emp = s6_e3c - 2 if inlist(s6_e3c,1,2,3)

gen s_f3m_emp_toomany = (s6_e3d == 1) if inlist(s6_e3d,1,2,3)
gen s_f3m_emp_toofew = (s6_e3d == 3) if inlist(s6_e3d,1,2,3)
gen s_f3m_emp_justright = (s6_e3d == 2) if inlist(s6_e3d,1,2,3)
gen s_f3m_emp = s6_e3d - 2 if inlist(s6_e3d,1,2,3)

** input prices **
gen s_ly_p_input_lower = (s6_e4a == 1) if inlist(s6_e4a,1,2,3)
gen s_ly_p_input_higher = (s6_e4a == 3) if inlist(s6_e4a,1,2,3)
gen s_ly_p_input_same = (s6_e4a == 2) if inlist(s6_e4a,1,2,3)
gen s_ly_p_input = s6_e4a - 2 if inlist(s6_e4a,1,2,3)

gen s_lm_p_input_lower = (s6_e4b == 1) if inlist(s6_e4b,1,2,3)
gen s_lm_p_input_higher = (s6_e4b == 3) if inlist(s6_e4b,1,2,3)
gen s_lm_p_input_same = (s6_e4b == 2) if inlist(s6_e4b,1,2,3)
gen s_lm_p_input = s6_e4b - 2 if inlist(s6_e4b,1,2,3)

gen s_fy_p_input_lower = (s6_e4c == 1) if inlist(s6_e4c,1,2,3)
gen s_fy_p_input_higher = (s6_e4c == 3) if inlist(s6_e4c,1,2,3)
gen s_fy_p_input_same = (s6_e4c == 2) if inlist(s6_e4c,1,2,3)
gen s_fy_p_input = s6_e4c - 2 if inlist(s6_e4c,1,2,3)

gen s_f3m_p_input_lower = (s6_e4d == 1) if inlist(s6_e4d,1,2,3)
gen s_f3m_p_input_higher = (s6_e4d == 3) if inlist(s6_e4d,1,2,3)
gen s_f3m_p_input_same = (s6_e4d == 2) if inlist(s6_e4d,1,2,3)
gen s_f3m_p_input = s6_e4d - 2 if inlist(s6_e4d,1,2,3)

** output prices **
gen s_ly_p_output_lower = (s6_e5a == 1) if inlist(s6_e5a,1,2,3)
gen s_ly_p_output_higher = (s6_e5a == 3) if inlist(s6_e5a,1,2,3)
gen s_ly_p_output_same = (s6_e5a == 2) if inlist(s6_e5a,1,2,3)
gen s_ly_p_output = s6_e5a - 2 if inlist(s6_e5a,1,2,3)

gen s_lm_p_output_lower = (s6_e5b == 1) if inlist(s6_e5b,1,2,3)
gen s_lm_p_output_higher = (s6_e5b == 3) if inlist(s6_e5b,1,2,3)
gen s_lm_p_output_same = (s6_e5b == 2) if inlist(s6_e5b,1,2,3)
gen s_lm_p_output = s6_e5b - 2 if inlist(s6_e5b,1,2,3)

gen s_fy_p_output_lower = (s6_e5c == 1) if inlist(s6_e5c,1,2,3)
gen s_fy_p_output_higher = (s6_e5c == 3) if inlist(s6_e5c,1,2,3)
gen s_fy_p_output_same = (s6_e5c == 2) if inlist(s6_e5c,1,2,3)
gen s_fy_p_output = s6_e5c - 2 if inlist(s6_e5c,1,2,3)

gen s_f3m_p_output_lower = (s6_e5d == 1) if inlist(s6_e5d,1,2,3)
gen s_f3m_p_output_higher = (s6_e5d == 3) if inlist(s6_e5d,1,2,3)
gen s_f3m_p_output_same = (s6_e5d == 2) if inlist(s6_e5d,1,2,3)
gen s_f3m_p_output = s6_e5d - 2 if inlist(s6_e5d,1,2,3)

** business conditions **
gen s_today_bizcon_worse = (s6_q1_currentconditions == 1) if inlist(s6_q1_currentconditions,1,2,3)
gen s_today_bizcon_better = (s6_q1_currentconditions == 3) if inlist(s6_q1_currentconditions,1,2,3)
gen s_today_bizcon_same = (s6_q1_currentconditions == 2) if inlist(s6_q1_currentconditions,1,2,3)
gen s_today_bizcon = s6_q1_currentconditions - 2 if inlist(s6_q1_currentconditions,1,2,3)

gen s_ly_bizcon_worse = (s6_e6a == 1) if inlist(s6_e6a,1,2,3)
gen s_ly_bizcon_better = (s6_e6a == 3) if inlist(s6_e6a,1,2,3)
gen s_ly_bizcon_same = (s6_e6a == 2) if inlist(s6_e6a,1,2,3)
gen s_ly_bizcon = s6_e6a - 2 if inlist(s6_e6a,1,2,3)

gen s_lm_bizcon_worse = (s6_e6b == 1) if inlist(s6_e6b,1,2,3)
gen s_lm_bizcon_better = (s6_e6b == 3) if inlist(s6_e6b,1,2,3)
gen s_lm_bizcon_same = (s6_e6b == 2) if inlist(s6_e6b,1,2,3)
gen s_lm_bizcon = s6_e6b - 2 if inlist(s6_e6b,1,2,3)

gen s_fy_bizcon_worse = (s6_e6c == 1) if inlist(s6_e6c,1,2,3)
gen s_fy_bizcon_better = (s6_e6c == 3) if inlist(s6_e6c,1,2,3)
gen s_fy_bizcon_same = (s6_e6c == 2) if inlist(s6_e6c,1,2,3)
gen s_fy_bizcon = s6_e6c - 2 if inlist(s6_e6c,1,2,3)

gen s_f3m_bizcon_worse = (s6_e6d == 1) if inlist(s6_e6d,1,2,3)
gen s_f3m_bizcon_better = (s6_e6d == 3) if inlist(s6_e6d,1,2,3)
gen s_f3m_bizcon_same = (s6_e6d == 2) if inlist(s6_e6d,1,2,3)
gen s_f3m_bizcon = s6_e6d - 2 if inlist(s6_e6d,1,2,3)


** other enterprises **
rename s6_e7a s_ly_p_othbiz_higher
replace s_ly_p_othbiz_higher = . if s_ly_p_othbiz_higher == -99
replace s_ly_p_othbiz_higher = 2 - s_ly_p_othbiz_higher

rename s6_e7b s_lm_p_othbiz_higher
replace s_lm_p_othbiz_higher = . if s_lm_p_othbiz_higher == -99
replace s_lm_p_othbiz_higher = 2 - s_lm_p_othbiz_higher


rename s6_e8a s_ly_prod_othbiz_higher
replace s_ly_prod_othbiz_higher = . if s_ly_prod_othbiz_higher == -99
replace s_ly_prod_othbiz_higher = 2 - s_ly_prod_othbiz_higher

rename s6_e8b s_lm_prod_othbiz_higher
replace s_lm_prod_othbiz_higher = . if s_lm_prod_othbiz_higher == -99
replace s_lm_prod_othbiz_higher = 2 - s_lm_prod_othbiz_higher


rename s6_e9a s_ly_n_othbiz_higher
replace s_ly_n_othbiz_higher = . if s_ly_n_othbiz_higher == -99
replace s_ly_n_othbiz_higher = 2 - s_ly_n_othbiz_higher

rename s6_e9b s_lm_n_othbiz_higher
replace s_lm_n_othbiz_higher = . if s_lm_n_othbiz_higher == -99
replace s_lm_n_othbiz_higher = 2 - s_lm_n_othbiz_higher


** Expansion plans **
rename s6_expansion s_expansion
replace s_expansion = . if s_expansion == -99
replace s_expansion = 2 - s_expansion

split s6_expansionfunds, gen(expfund_)

gen expfund_savings = (expfund_1 == "1" | expfund_2 == "1" | expfund_3 == "1" | expfund_4 == "1" | expfund_5 == "1" | expfund_6 == "1" | expfund_7 == "1") if expfund_1 != ""
gen expfund_bizprof = (expfund_1 == "2" | expfund_2 == "2" | expfund_3 == "2" | expfund_4 == "2" | expfund_5 == "2" | expfund_6 == "2" | expfund_7 == "2") if expfund_1 != ""
gen expfund_loan_bank = (expfund_1 == "3" | expfund_2 == "3" | expfund_3 == "3" | expfund_4 == "3" | expfund_5 == "3" | expfund_6 == "3" | expfund_7 == "3") if expfund_1 != ""
gen expfund_loan_mlend = (expfund_1 == "4" | expfund_2 == "4" | expfund_3 == "4" | expfund_4 == "4" | expfund_5 == "4" | expfund_6 == "4" | expfund_7 == "4") if expfund_1 != ""
gen expfund_loan_friends = (expfund_1 == "5" | expfund_2 == "5" | expfund_3 == "5" | expfund_4 == "5" | expfund_5 == "5" | expfund_6 == "5" | expfund_7 == "5") if expfund_1 != ""
gen expfund_loan_relats = (expfund_1 == "6" | expfund_2 == "6" | expfund_3 == "6" | expfund_4 == "6" | expfund_5 == "6" | expfund_6 == "6" | expfund_7 == "6") if expfund_1 != ""
gen expfund_loan_mshwari = (expfund_1 == "7" | expfund_2 == "7" | expfund_3 == "7" | expfund_4 == "7" | expfund_5 == "7" | expfund_6 == "7" | expfund_7 == "7") if expfund_1 != ""
gen expfund_gift_friends = (expfund_1 == "8" | expfund_2 == "8" | expfund_3 == "8" | expfund_4 == "8" | expfund_5 == "8" | expfund_6 == "8" | expfund_7 == "8") if expfund_1 != ""
gen expfund_gift_relats = (expfund_1 == "9" | expfund_2 == "9" | expfund_3 == "9" | expfund_4 == "9" | expfund_5 == "9" | expfund_6 == "9" | expfund_7 == "9") if expfund_1 != ""
gen expfund_mergoroud = (expfund_1 == "10" | expfund_2 == "10" | expfund_3 == "10" | expfund_4 == "10" | expfund_5 == "10" | expfund_6 == "10" | expfund_7 == "10") if expfund_1 != ""
gen expfund_sacco = (expfund_1 == "11" | expfund_2 == "11" | expfund_3 == "11" | expfund_4 == "11" | expfund_5 == "11" | expfund_6 == "11" | expfund_7 == "11") if expfund_1 != ""
gen expfund_inherit = (expfund_1 == "12" | expfund_2 == "12" | expfund_3 == "12" | expfund_4 == "12" | expfund_5 == "12" | expfund_6 == "12" | expfund_7 == "12") if expfund_1 != ""
gen expfund_retirefund = (expfund_1 == "13" | expfund_2 == "13" | expfund_3 == "13" | expfund_4 == "13" | expfund_5 == "13" | expfund_6 == "13" | expfund_7 == "13") if expfund_1 != ""
gen expfund_ngoct = (expfund_1 == "14" | expfund_2 == "14" | expfund_3 == "14" | expfund_4 == "14" | expfund_5 == "14" | expfund_6 == "14" | expfund_7 == "14") if expfund_1 != ""
drop expfund_?

************************
/*** SAVING DATASET ***/
************************
ren end_cen_date census_date
drop s?_*
foreach var of varlist instanceid formdef_version key version {
  cap desc `var'
  if _rc == 0 {
    di "`var'"
    drop `var'
  }
}
ren census_date census_EL_date
ren end_sur_date survey_EL_date

** add location information **
merge m:1 village_code using "$dr/CleanGeography_PUBLIC.dta"
drop if _merge == 2
drop _merge

** Label variables **
label var entcode_EL "Endline enterprise code"
label var surveyed "Enterprise was surveyed"
label var survey_EL_date "Date of the enterprise survey"
label var censused "Enterprise was censused"
label var census_EL_date "Date of the enterprise census"
label var frtype "Respondent type"
label var consent "Respondent consents to survey"
label var open "Enterprise is open"
label var open_7d "Enterprise was open in the last 7 days"
label var operational "Enterprise is operational / was open in the last 30 days"
label var roof "Roof material"
label var walls "Wall material"
label var floors "Floor material"
label var operate_from "Business operates from"

label var loc_moved "Location of the business moved since census"
label var location_multiple "Operates in multiple locations"
label var bizcat "Business category"
label var bizcat_products "Business category - main products"
label var bizcat_nonfood "Non-food business category"
label var bizcatsec "Secondary business category"
label var bizcatsec_nonfood "Secondary non-food business category"
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
label var op_hoursperday"Number of hours open per day"

label var owner_age "Age of the owner"
label var owner_education "Owner - years of education"
label var owner_primary "Owner - completed primary school"
label var owner_secondary "Owner - completed secondary school"
label var owner_degree  "Owner - has a degree"
label var owner_resident "Owner - resident in the same village"
label var owner_county "Owner - subcounty of residence"
label var owner_subcounty "Owner - subcounty of residence"
label var owner_location_code "Owner - location code of residence"
label var owner_sublocation_code "Owner - sublocation code of residence"
label var owner_village_code "Owner - village code of residence"
label var owner_status "Ownership structure"
label var owner_num "Number of owners"

label var cust_perday "Number of customers per day"
label var cust_perweek "Number of customers per week"
label var cust_svillage "Share of customers - from same village"
label var cust_ssublocation "Share of customers - from other villages in the same sublocation"
label var cust_slocation "Share of customers - from other sublocations in the same location"
label var cust_stown "Share of customers - from towns"
label var cust_sother "Share of customers - from other places"

label var emp_n_tot "Total number of employees"
label var emp_n_perm "Number of permanent employees"
label var emp_n_temp "Number of temporary employees"
label var emp_n_other "Number of other employees"
label var emp_n_family "Number of family employees"
label var emp_n_nonfamily "Number of non-family employees"
label var emp_n_f "Number of female employees"
label var emp_n_m "Number of male employees"
label var emp_n_formal "Number of formal employees"
label var emp_n_informal "Number of informal employees"
label var emp_h_tot "Hours worked last week - total"
label var emp_h_perm "Hours worked last week - permanent employees"
label var emp_h_temp "Hours worked last week - temporary employees"
label var emp_h_other "Hours worked last week - other employees"
label var emp_h_family "Hours worked last week - family employees"
label var emp_h_nonfamily "Hours worked last week - non-family employees"
label var emp_h_f "Hours worked last week - female employees"
label var emp_h_m "Hours worked last week - male employees"
label var emp_h_formal "Hours worked last week - formal employees"
label var emp_h_informal "Hours worked last week - informal employees"
label var wage_total "Total wage bill last month"
label var wage_h "Implied average hourly wage"
label var wage_m_pp "Implied monthly wage per employee"

label var rev_mon "Revenues last month (in KES)"
label var rev_year "Revenues last year (in KES)"
label var prof_mon "Profits last month (in KES)"
label var prof_year "Profits last year (in KES)"
label var revprof_incons "Profits/Revenues flagged inconsistent"
label var inv_mon "Business investment last month (in KES)"
label var inv_year "Business investment last year (in KES)"
label var fundsource_savings "Business had funding from - savings"
label var fundsource_bizprof "Business had funding from - retained earnings"
label var fundsource_loan_bank "Business had funding from - bank loan"
label var fundsource_loan_mlend "Business had funding from - moneylender"
label var fundsource_loan_friends "Business had funding from - loan from friends"
label var fundsource_loan_relats "Business had funding from - loan from relatives"
label var fundsource_loan_mshwari "Business had funding from - M-Shwari loan"
label var fundsource_gift_friends "Business had funding from - gift from friends"
label var fundsource_gift_relats "Business had funding from - gift from relatives"
label var fundsource_mergoroud "Business had funding from - merry-go-round"
label var fundsource_sacco "Business had funding from - SACCO"
label var fundsource_inherit "Business had funding from - inheritance"
label var fundsource_retirefund "Business had funding from - retirement fund"
label var fundsource_ngoct "Business had funding from - NGO cash transfer"
label var inventory "Value of current inventory (in KES)"
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
label var d_llc "Business is registered as an LLC"
label var d_vat "Business is registered to pay VAT"
label var t_vat "VAT paid last year"
label var t_county "County taxes paid last year"
label var t_national "National taxes paid last year"
label var t_chiefs "Taxes paid to chiefs / assitant chiefs / village elders"
label var t_other "Other taxes paid"

label var s_producer "Sentiment - Enterprise is a producer"
label var s_retailer "Sentiment - Enterprise is a retailer"

label var s_ly_cap_lower "Sentiment - Productive capacity lower than last year"
label var s_ly_cap_higher "Sentiment - Productive capacity higher than last year"
label var s_ly_cap_same "Sentiment - Productive capacity the same as last year"
label var s_ly_cap "Sentiment - Productive capacity compared to last year"
label var s_lm_cap_lower "Sentiment - Productive capacity lower than last month"
label var s_lm_cap_higher "Sentiment - Productive capacity higher than last month"
label var s_lm_cap_same "Sentiment - Productive capacity the same as last month"
label var s_lm_cap "Sentiment - Productive capacity compared to last month"
label var s_fy_cap_lower "Sentiment - Productive capacity lower in a year"
label var s_fy_cap_higher "Sentiment - Productive capacity higher in a year"
label var s_fy_cap_same "Sentiment - Productive capacity the same in a year"
label var s_fy_cap "Sentiment - Productive capacity in a year from now"
label var s_f3m_cap_lower "Sentiment - Productive capacity lower in a month"
label var s_f3m_cap_higher "Sentiment - Productive capacity higher in a month"
label var s_f3m_cap_same "Sentiment - Productive capacity the same in a month"
label var s_f3m_cap "Sentiment - Productive capacity in a month from now"

label var s_ly_prod_lower "Sentiment - Production lower than last year"
label var s_ly_prod_higher "Sentiment - Production higher than last year"
label var s_ly_prod_same "Sentiment - Production the same as last year"
label var s_ly_prod "Sentiment - Production compared to last year"
label var s_lm_prod_lower "Sentiment - Production lower than last month"
label var s_lm_prod_higher "Sentiment - Production higher than last month"
label var s_lm_prod_same "Sentiment - Production the same as last month"
label var s_lm_prod "Sentiment - Production compared to last month"
label var s_fy_prod_lower "Sentiment - Production lower in a year"
label var s_fy_prod_higher "Sentiment - Production higher in a year"
label var s_fy_prod_same "Sentiment - Production the same in a year"
label var s_fy_prod "Sentiment - Production in a year from now"
label var s_f3m_prod_lower "Sentiment - Production lower in a month"
label var s_f3m_prod_higher "Sentiment - Production higher in a month"
label var s_f3m_prod_same "Sentiment - Production the same in a month"
label var s_f3m_prod "Sentiment - Production in a month from now"

label var s_ly_inventory_lower "Sentiment - Inventory lower than last year"
label var s_ly_inventory_higher "Sentiment - Inventory higher than last year"
label var s_ly_inventory_same "Sentiment - Inventory the same as last year"
label var s_ly_inventory "Sentiment - Inventory compared to last year"
label var s_lm_inventory_lower "Sentiment - Inventory lower than last month"
label var s_lm_inventory_higher "Sentiment - Inventory higher than last month"
label var s_lm_inventory_same "Sentiment - Inventory the same as last month"
label var s_lm_inventory "Sentiment - Inventory compared to last month"
label var s_fy_inventory_lower "Sentiment - Inventory lower in a year"
label var s_fy_inventory_higher "Sentiment - Inventory higher in a year"
label var s_fy_inventory_same "Sentiment - Inventory the same in a year"
label var s_fy_inventory "Sentiment - Inventory in a year from now"
label var s_f3m_inventory_lower "Sentiment - Inventory lower in a month"
label var s_f3m_inventory_higher "Sentiment - Inventory higher in a month"
label var s_f3m_inventory_same "Sentiment - Inventory the same in a month"
label var s_f3m_inventory "Sentiment - Inventory in a month from now"

label var s_ly_emp_toomany "Sentiment - Employment too high last year"
label var s_ly_emp_toofew "Sentiment - Employment too low last year"
label var s_ly_emp_justright "Sentiment - Employment just right last year"
label var s_ly_emp "Sentiment - Employment compared to last year"
label var s_lm_emp_toomany "Sentiment - Employment too high last month"
label var s_lm_emp_toofew "Sentiment - Employment too low last month"
label var s_lm_emp_justright "Sentiment - Employment just right last month"
label var s_lm_emp "Sentiment - Employment compared to last month"
label var s_fy_emp_toomany "Sentiment - Employment lower in a year"
label var s_fy_emp_toofew "Sentiment - Employment higher in a year"
label var s_fy_emp_justright "Sentiment - Employment just right in a year"
label var s_fy_emp "Sentiment - Employment in a year from now"
label var s_f3m_emp_toomany "Sentiment - Employment lower in a month"
label var s_f3m_emp_toofew "Sentiment - Employment higher in a month"
label var s_f3m_emp_justright "Sentiment - Employment just right in a month"
label var s_f3m_emp "Sentiment - Employment in a month from now"

label var s_ly_p_input_lower "Sentiment - Input prices lower than last year"
label var s_ly_p_input_higher "Sentiment - Input prices higher than last year"
label var s_ly_p_input_same "Sentiment - Input prices the same as last year"
label var s_ly_p_input "Sentiment - Input prices compared to last year"
label var s_lm_p_input_lower "Sentiment - Input prices lower than last month"
label var s_lm_p_input_higher "Sentiment - Input prices higher than last month"
label var s_lm_p_input_same "Sentiment - Input prices the same as last month"
label var s_lm_p_input "Sentiment - Input prices compared to last month"
label var s_fy_p_input_lower "Sentiment - Input prices lower in a year"
label var s_fy_p_input_higher "Sentiment - Input prices higher in a year"
label var s_fy_p_input_same "Sentiment - Input prices the same in a year"
label var s_fy_p_input "Sentiment - Input prices in a year from now"
label var s_f3m_p_input_lower "Sentiment - Input prices lower in a month"
label var s_f3m_p_input_higher "Sentiment - Input prices higher in a month"
label var s_f3m_p_input_same "Sentiment - Input prices the same in a month"
label var s_f3m_p_input "Sentiment - Input prices in a month from now"

label var s_ly_p_output_lower "Sentiment - Output prices lower than last year"
label var s_ly_p_output_higher "Sentiment - Output prices higher than last year"
label var s_ly_p_output_same "Sentiment - Output prices the same as last year"
label var s_ly_p_output "Sentiment - Output prices compared to last year"
label var s_lm_p_output_lower "Sentiment - Output prices lower than last month"
label var s_lm_p_output_higher "Sentiment - Output prices higher than last month"
label var s_lm_p_output_same "Sentiment - Output prices the same as last month"
label var s_lm_p_output "Sentiment - Output prices compared to last month"
label var s_fy_p_output_lower "Sentiment - Output prices lower in a year"
label var s_fy_p_output_higher "Sentiment - Output prices higher in a year"
label var s_fy_p_output_same "Sentiment - Output prices the same in a year"
label var s_fy_p_output "Sentiment - Output prices in a year from now"
label var s_f3m_p_output_lower "Sentiment - Output prices lower in a month"
label var s_f3m_p_output_higher "Sentiment - Output prices higher in a month"
label var s_f3m_p_output_same "Sentiment - Output prices the same in a month"
label var s_f3m_p_output "Sentiment - Output prices in a month from now"

label var s_today_bizcon_worse "Sentiment - Overall business conditions worsening"
label var s_today_bizcon_better "Sentiment - Overall business conditions improving"
label var s_today_bizcon_same "Sentiment - Overall business conditions staying the same"
label var s_today_bizcon "Sentiment - Overall business conditions"

label var s_ly_bizcon_worse "Sentiment - Overall business conditions worse than last year"
label var s_ly_bizcon_better "Sentiment - Overall business conditions better than last year"
label var s_ly_bizcon_same "Sentiment - Overall business conditions the same as last year"
label var s_ly_bizcon "Sentiment - Overall business conditions compared to last year"
label var s_lm_bizcon_worse "Sentiment - Overall business conditions worse than last month"
label var s_lm_bizcon_better "Sentiment - Overall business conditions better than last month"
label var s_lm_bizcon_same "Sentiment - Overall business conditions the same as last month"
label var s_lm_bizcon "Sentiment - Overall business conditions compared to last month"
label var s_fy_bizcon_worse "Sentiment - Overall business conditions worse in a year"
label var s_fy_bizcon_better "Sentiment - Overall business conditions better in a year"
label var s_fy_bizcon_same "Sentiment - Overall business conditions the same in a year"
label var s_fy_bizcon "Sentiment - Overall business conditions in a year from now"
label var s_f3m_bizcon_worse "Sentiment - Overall business conditions worse in a month"
label var s_f3m_bizcon_better "Sentiment - Overall business conditions better in a month"
label var s_f3m_bizcon_same "Sentiment - Overall business conditions the same in a month"
label var s_f3m_bizcon "Sentiment - Overall business conditions in a month from now"

label var s_ly_p_othbiz_higher "Sentiment - Other businesses increased prices last year"
label var s_lm_p_othbiz_higher "Sentiment - Other businesses increased prices last month"
label var s_ly_prod_othbiz_higher "Sentiment - Other businesses doing better last year"
label var s_lm_prod_othbiz_higher "Sentiment - Other businesses doing better last month"
label var s_ly_n_othbiz_higher "Sentiment - There were more businesses than usual last year"
label var s_lm_n_othbiz_higher "Sentiment - There were more businesses than usual last month"

label var s_expansion "Has expansion plans"
label var expfund_savings "Expansion funding - savings"
label var expfund_bizprof "Expansion funding - retained earnings"
label var expfund_loan_bank "Expansion funding - bank loan"
label var expfund_loan_mlend "Expansion funding - moneylender"
label var expfund_loan_friends "Expansion funding - loan from friends"
label var expfund_loan_relats "Expansion funding - loan from relatives"
label var expfund_loan_mshwari "Expansion funding - M-Shwari loan"
label var expfund_gift_friends "Expansion funding - gift from friends"
label var expfund_gift_relats "Expansion funding - gift from relatives"
label var expfund_mergoroud "Expansion funding - Merry-go-round"
label var expfund_sacco "Expansion funding - SACCO"
label var expfund_inherit "Expansion funding - Inheritance"
label var expfund_retirefund "Expansion funding - Retirement fund"
label var expfund_ngoct "Expansion funding - NGO cash transfer"

order location_code sublocation_code village_code entcode_EL surveyed survey_EL_date censused census_EL_date frtype consent censused open open_7d operational ///
  roof walls floors operate_from loc_moved location_multiple bizcat* ent_start_year ent_start_month ent_age ///
  op_* cust_* emp_* wage_* rev_* prof_* revprof_incons inv_* fundsource_* inventory c_* electricity* ///
  d_licensed d_registered d_llc d_vat t_license t_marketfees t_vat t_county t_national t_chiefs t_other ///
  s_producer s_retailer s_today_* s_*_bizcon* s_*_cap* s_*_prod* s_*_inventory* s_*_emp* s_*_p_input* s_*_p_output* s_*_othbiz* s_expansion expfund_*


save "$da/GE_ENT-Survey-EL1_Analysis_ECMA.dta", replace
project, creates("$da/GE_ENT-Survey-EL1_Analysis_ECMA.dta")
