
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
project, original("$dr/GE_ENT-Census-BL_PUBLIC.dta") preserve
use "$dr/GE_ENT-Census-BL_PUBLIC.dta", clear


** Some procedural checks **
****************************
ren today ENT_CEN_BL_date


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
//browse s1_q3_operatefrom s1_q3_operatefrom_other
tab s1_q3_operatefrom_other
codebook s1_q3_operatefrom

replace s1_q3_operatefrom = 2 if inlist(s1_q3_operatefrom_other, "Foodstall", "Home stall")
replace s1_q3_operatefrom = 4 if inlist(s1_q3_operatefrom_other, "His business is on the verander of a building", "At AGIP COMM.'s shop verandah", "On  a varender of a single building", "On an hotel varander", "On varender of a poshomill", "On varender of a shared building", "On varender of certain building", "Varander on shared building", "Varender under a building")
replace s1_q3_operatefrom = 5 if inlist(s1_q3_operatefrom_other, "Under atree", "Open air", "Shade", "Shed")
replace s1_q3_operatefrom = . if s1_q3_operatefrom == 99
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
destring floors, replace

label val floors materials
tab floors


** Business Categories **
*************************
rename s1_q6_bizcat bizcat

replace s1_q6_bizcatother = strlower(s1_q6_bizcatother)
tab s1_q6_bizcatother

replace bizcat = "bike_repair" if inlist(s1_q6_bizcatother, "bicycle repair")
replace bizcat = "cereal" if inlist(s1_q6_bizcatother, "sells cereals and charcoal")
replace bizcat = "bookshop" if inlist(s1_q6_bizcatother, "bookshop" )
replace bizcat = "foodstall" if inlist(s1_q6_bizcatother, "sells chapati", "stall")
replace bizcat = "foodstall" if inlist(s1_q6a_bizcatnonfood, "bakery")
replace bizcat = "foodstall" if inlist(s1_q6_bizcatother, "juggery seller", "sells jaggery/sukari nguru")
replace bizcat = "tailor" if inlist(s1_q6_bizcatother, "drycleaning")
replace bizcat = "carpenter" if inlist(s1_q6_bizcatother, "furniture making")
replace bizcat = "motorcycle_repair" if inlist(s1_q6_bizcatother, "motor bike spair parts shop", "motor bike spare parts", "motor cycle/ spare parts" )
replace bizcat = "photostudio" if inlist(s1_q6_bizcatother, "photo studio" )
replace bizcat = "bar" if inlist(s1_q6_bizcatother, "pool", "pool table" )
replace bizcat = "mpesa" if inlist(s1_q6a_bizcatproducts, "mpesa")
replace bizcat = "mobilecharge" if inlist(s1_q6a_bizcatproducts, "mobilecharge")

replace bizcat = "nfvendor" if inlist(s1_q6_bizcatother,"ready made mutumba sales")
replace bizcat = "nfvendor" if inlist(s1_q6_bizcatother,"electrical shop", "electricals and mobile phone accessories", "electronics and mobile repairs", "electronics(radio repair)")
replace bizcat = "nfvendor" if inlist(s1_q6_bizcatother, "foot wear and clothings", "sells cloths", "selling plastic")

replace s1_q6a_bizcatnonfood = "clothes" if inlist(s1_q6_bizcatother, "foot wear and clothings", "sells cloths", "ready made mutumba sales")
replace s1_q6a_bizcatnonfood = "electric" if inlist(s1_q6_bizcatother, "electrical shop", "electricals and mobile phone accessories", "electronics and mobile repairs", "electronics(radio repair)")
replace s1_q6a_bizcatnonfood = "other" if inlist(s1_q6_bizcatother, "selling plastic")

replace bizcat = "sretail" if inlist(s1_q6_bizcatother,"kiosk")
replace s1_q6a_bizcatproducts = "other" if inlist(s1_q6_bizcatother,"kiosk")
drop s1_q6_bizcatother

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
replace bizcat = "29" if bizcat == "carpenter"
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

replace bizcat = "42" if bizcat == "dk"
replace bizcat = "51" if inlist(bizcat, "39", "40", "nonfood", "crafts", "charcoal") // non-food producers and vendors were not distinguished at baseline.

destring bizcat, replace

label def bizcat 1 "Tea buying centre" 2 "Small retail" 3 "M-Pesa" 4 "Mobile charging" 5 "Bank agent" 6 "Large retail" 7 "Restaurant" 8 "Bar" 9 "Hardware store" 10 "Barber shop" 11 "Beauty shop / Salon" 12 "Butcher" 13 "Video Room/Football hall" 14 "Cyber café" 15 "Tailor" 16 "Bookshop" 17 "Posho mill" 18 "Welding / metalwork" 19 "Carpenter" 20 "Guesthouse/ Hotel" ///
21 "Food stand / Prepared food vendor" 22 "Food stall / Raw food and fruits vendor" 23 "Chemist" 24 "Motor Vehicles Mechanic" 25 "Motorcycle Repair / Shop" 26 "Bicycle repair / mechanic shop" 27 "Petrol station" 28 "Piki driver" 29 "Boda driver" 30 "Sale or brewing of homemade alcohol / liquor" 31 "Livestock / Animal (Products) / Poultry Sale" 32 "Oxen / donkey / tractor plouging" 33 "Fishing" 34 "Fish Sale / Mongering" 35 "Cereals" 36 "Agrovet" 37 "Photo studio" 38 "Jaggery" 39 "Non-Food Vendor" 40 "Non-Food Producer" ///
41 "Other (specify)" 42 "None" 51 "Nonfood vendor or producer", replace

label val bizcat bizcat
tab bizcat

rename s1_q6a_bizcatproducts bizcat_products
replace bizcat_products = "1" if bizcat_products == "grocery"
replace bizcat_products = "2" if bizcat_products == "household"
replace bizcat_products = "3" if inlist(bizcat_products, "dk", "other")
replace bizcat_products = "" if inlist(bizcat_products, "mobilecharge", "mpesa")
destring bizcat_products, replace

label def bizcat_products 1 "Groceries" 2 "Household goods" 3 "All other retail"
label val bizcat_products bizcat_products
tab bizcat_products

rename s1_q6a_bizcatnonfood bizcat_nonfood
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
replace bizcat_nonfood = "" if bizcat_nonfood == "bakery"
destring bizcat_nonfood, replace

label def bizcat_nonfood 1 "Charcoal sale / burning" 2 "Clothes / Mtumba / Boutique" 3 "Electric accesory/repair" 4 "Paraffin" 5 "Timber / Firewood" 6 "Shoes / Cobbler" 7 "Craftwork" 8 "Sand Sale / Harvesting" 9 "Kerosene" 10 "Brick Sale / Production" 11 "Stone / Ballast Sale or Production" 12 "Water Vendor" 13 "Gold" 14 "Other"
label val bizcat_nonfood bizcat_nonfood
tab bizcat_nonfood


** Secondary **
rename s1_q7_bizcatsecondary bizcatsec
split bizcatsec, gen(a_)
replace bizcatsec = a_1
gen bizcatter = a_2
gen bizcatquar = a_3
gen bizcatquint = a_4
drop a_*

tab bizcatsec
tab bizcatter
tab bizcatquar
tab bizcatquint

foreach v of var bizcatsec bizcatter bizcatquar bizcatquint {
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
tab bizcatquint

rename s1_q7a_bizcatsecnonfood bizcatsec_nonfood
split bizcatsec_nonfood, gen (a_)
replace bizcatsec_nonfood = a_1
gen bizcatter_nonfood = a_2
gen bizcatquar_nonfood = a_3
drop a_*

foreach v of var bizcatsec_nonfood bizcatter_nonfood bizcatquar_nonfood {
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
label val bizcatter_nonfood bizcat_nonfood
label val bizcatquar_nonfood bizcat_nonfood

tab bizcatsec_nonfood
tab bizcatter_nonfood
tab bizcatquar_nonfood

ren s1_q7a_bizcatsecproducts bizcatsec_products


** generate aggregated business categories **
*********************************************
foreach v in bizcat bizcatsec bizcatter bizcatquar bizcatquint{
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
foreach v in bizcat bizcatsec bizcatter bizcatquar {
	replace `v'_cons = 5 if `v' == 51 & inlist(`v'_nonfood, 2, 6)
	replace `v'_cons = 6 if `v' == 51 & inlist(`v'_nonfood, 1, 3, 4, 5, 7, 8, 9, 10, 11, 13)
	replace `v'_cons = 4 if `v' == 51 & inlist(`v'_nonfood, 12)
	replace `v'_cons = 6 if `v' == 51 & inlist(`v'_nonfood, 14)
}



***********************************************
** Clean up enterprise variables - section 2 **
***********************************************

** Ownership information **
***************************
gen owner_f = (s2_q2_gender == "F") if inlist(s1_q9_isowner,1,2)

** Owner residence information **
*********************************
gen owner_resident = (s2_q5_resident == 1) if inlist(s1_q9_isowner,1,2)
replace owner_resident = (s2_q11_ownerresident == 1) if inlist(s2_q11_ownerresident,3)

** Location information **
**************************
drop s1_* s2_*
keep entcode* location_code sublocation_code village_code ent_id_BL  ENT_CEN_BL_date consent open open_7d roof walls floors operate_from bizcat bizcat_products bizcat_nonfood bizcatsec bizcatsec_products bizcatsec_nonfood bizcatter bizcatter_nonfood bizcatquar bizcatquar_nonfood bizcatquint bizcat_cons bizcatsec_cons bizcatter_cons bizcatquar_cons bizcatquint_cons owner_* openM openT openW openTh openF openSa openSu hours_open
order entcode* location_code sublocation_code village_code ent_id_BL  ENT_CEN_BL_date consent open open_7d roof walls floors operate_from bizcat bizcat_products bizcat_nonfood bizcatsec bizcatsec_products bizcatsec_nonfood bizcatter bizcatter_nonfood bizcatquar bizcatquar_nonfood bizcatquint bizcat_cons bizcatsec_cons bizcatter_cons bizcatquar_cons bizcatquint_cons owner_* openM openT openW openTh openF openSa openSu hours_open

***********************
** Clean up and save **
***********************

** Labelling variables **
label var ent_id_BL "Baseline enterprise id (unique with village_code)"
label var ENT_CEN_BL_date "Date of the baseline enterprise census"

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
label var bizcatter "Tertiary business category"
label var bizcatter_nonfood "Tertiary non-food business category"
label var bizcatquar "Quaternary business category"
label var bizcatquar_nonfood "Quaternary non-food business category"
label var bizcatquint "Quinary business category"
label var bizcat_cons "Business category (consolidated)"
label var bizcatsec_cons "Secondary business category (consolidated)"
label var bizcatter_cons "Tertiary business category (consolidated)"
label var bizcatquar_cons "Quaternary business category (consolidated)"
label var bizcatquint_cons "Quinary business category (consolidated)"

label var owner_f "Owner is female"
label var owner_resident "Owner - resident in the same village"

label var openM "Business usually open on Monday"
label var openT "Business usually open on Tuesday"
label var openW "Business usually open on Wednesday"
label var openTh "Business usually open on Thursday"
label var openF "Business usually open on Friday"
label var openSa "Business usually open on Saturday"
label var openSu "Business usually open on Sunday"

label var hours_open "Business usually open during those hours"

/*** SAVING DATASET ***/
save "$da/intermediate/GE_ENT-Census_Baseline_noHHEnt.dta", replace
project, creates("$da/intermediate/GE_ENT-Census_Baseline_noHHEnt.dta")
