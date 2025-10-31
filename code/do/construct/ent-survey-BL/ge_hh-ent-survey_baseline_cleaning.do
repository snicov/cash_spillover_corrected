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
project, original("$dr/GE_HH-Survey-BL_PUBLIC.dta")
use "$dr/GE_HH-Survey-BL_PUBLIC.dta", clear

*** SECTION 8 CONTAINS THE INFORMATION ON NON-AG ENTERPRISES **
tab s8_q1_selfemployed
keep if s8_q1_selfemployed == 1
tab s8_q1a_numbusinesses // almost all households have only one business -- makes it easier to match to HH Census

drop s4_* s6_* s7_* s9_* s10_* s11_* s12_* s13_* s14_*

** Convert to long dataset **
expand 2 if s8_q2_industry2 != "", gen(dupl)
destring s8_q*fx?, replace
foreach v in s8_q2_industry s8_q2_industry_other s8_q3_withinvillage s8_q4_hrsworked s8_q5_monthsworked s8_q6_numemployees s8_q6a_hhemployees s8_q6b_wagebill s8_q6bfx s8_q7a_earningslastmth s8_q7b_earningslastyr s8_q7fx s8_q8_islicensed s8_q8a_licenseamount s8_q8b_licensevalid s8_q9_isregistered s8_q10_islimitedco s8_q11a_profitlastmth s8_q11b_profitlastyr s8_q11fx s8_q12_bizstartdate s8_q13_startamount s8_q13fx  s8_q15_ownpremises s8_q15a_rentamount s8_q15afx s8_q16a_elecwater s8_q16b_insurance s8_q16c_interest s8_q16d_goodsresale s8_q16e_inputs s8_q16f_repairs s8_q16g_security s8_q16h_othercosts s8_q16fx  s8_q17a_healthinsurance s8_q17b_marketfees s8_q17d_countytaxes s8_q17e_nationaltaxes s8_q17f_localtaxes s8_q17g_bribes s8_q17fx s8_q18_vandalism s8_q18_vandalismdetails s8_q18_vandalismamount s8_q18fx {
	disp "`v'"
	replace `v'1 = `v'2 if dupl == 1
	drop `v'2
}

expand 2 if s8_q2_industry3 != "" & dupl == 1, gen(dupl2)
foreach v in s8_q2_industry s8_q2_industry_other s8_q3_withinvillage s8_q4_hrsworked s8_q5_monthsworked s8_q6_numemployees s8_q6a_hhemployees s8_q6b_wagebill s8_q6bfx s8_q7a_earningslastmth s8_q7b_earningslastyr s8_q7fx s8_q8_islicensed s8_q8a_licenseamount s8_q8b_licensevalid s8_q9_isregistered s8_q10_islimitedco s8_q11a_profitlastmth s8_q11b_profitlastyr s8_q11fx s8_q12_bizstartdate s8_q13_startamount s8_q13fx  s8_q15_ownpremises s8_q15a_rentamount s8_q15afx s8_q16a_elecwater s8_q16b_insurance s8_q16c_interest s8_q16d_goodsresale s8_q16e_inputs s8_q16f_repairs s8_q16g_security s8_q16h_othercosts s8_q16fx  s8_q17a_healthinsurance s8_q17b_marketfees s8_q17d_countytaxes s8_q17e_nationaltaxes s8_q17f_localtaxes s8_q17g_bribes s8_q17fx s8_q18_vandalism s8_q18_vandalismdetails s8_q18_vandalismamount s8_q18fx  {
	disp "`v'"
	replace `v'1 = `v'3 if dupl2 == 1
	drop `v'3
}

rename s8_*1 s8_*


************************
** OPERATIONAL CHECKS **
************************

** Clean location identifiers **
********************************
tab s8_q3_withinvillage
** Problem: We don't know where enterprises are that are not within the village **
** Those outside the village should be covered in the enterprise survey
** So for creating the baseline enterprise survey / universe, we can drop them
drop if s8_q3_withinvillage == 2

** for the remainder, we know where they are located **
ren s1_q2a_location location_name
ren s1_q2b_sublocation sublocation_name
ren s1_q2c_village village_name

** clean identifiers **
ren s1_q4_respid fr_id_BL
destring fr_id_BL, replace force


** Generate survey date **
**************************
ren today HH_ENT_SUR_BL_date


**************************
** Section 1 - Cleaning **
**************************

** Check consent **
rename s1_consent consent


** Business Categories **
*************************
** Those industries are different from what we used in the enterprise census
** Try match here as much as possible
replace s8_q2_industry = "777" if s8_q2_industry == "other"
destring s8_q2_industry, replace
gen bizcat = ""
replace bizcat = "tbc" if inlist(s8_q2_industry,3210)
replace bizcat = "sretail" if inlist(s8_q2_industry,3134,3140,6211,6214,6224,6225,6231)
replace bizcat = "mpesa" if inlist(s8_q2_industry,8103,8201)
replace bizcat = "lretail" if inlist(s8_q2_industry,6121,6110,6113,6120)
replace bizcat = "resto" if inlist(s8_q2_industry,6310)
replace bizcat = "hardware" if inlist(s8_q2_industry,6113,6215)
replace bizcat = "salon" if inlist(s8_q2_industry,9591)
replace bizcat = "butcher" if inlist(s8_q2_industry,6212)
replace bizcat = "cyber" if inlist(s8_q2_industry,7200)
replace bizcat = "carpenter" if inlist(s8_q2_industry,5104,5201)
replace bizcat = "posho" if inlist(s8_q2_industry,1,2)
replace bizcat = "foodstall" if inlist(s8_q2_industry,3132)
replace bizcat = "chemist" if inlist(s8_q2_industry,6216,9331)
replace bizcat = "petrol" if inlist(s8_q2_industry,6213)
replace bizcat = "boda" if inlist(s8_q2_industry,7112,7113)
replace bizcat = "alcohol" if inlist(s8_q2_industry,3133)
replace bizcat = "animal" if inlist(s8_q2_industry,6119,6218)
replace bizcat = "nonfood" if inlist(s8_q2_industry,3313,3411,3529,3693,3903)
replace bizcat = "other" if inlist(s8_q2_industry,777,4104,4200,5101,5102,5103,5105,5202,8311,8321,8322,8323,8324,8325,8320,9101,9391,9399,9530)
replace bizcat = ""	if inlist(s8_q2_industry,9999)

replace s8_q2_industry_other = lower(s8_q2_industry_other)
tab s8_q2_industry_other

replace bizcat = "sretail" if inlist(s8_q2_industry_other, "small business (selling sugar, tea leaves and match box)","small scale enterprise.")
replace bizcat = "mpesa" if inlist(s8_q2_industry_other,"taking tender of weedind for payment")
replace bizcat = "mobilecharge" if inlist(s8_q2_industry_other,"phone charging")
replace bizcat = "bar" if inlist(s8_q2_industry_other,"entertainment/disco")
replace bizcat = "tailor" if inlist(s8_q2_industry_other,"garment making","tailor","tailoring")
replace bizcat = "posho" if inlist(s8_q2_industry_other,"operates poshomill", "posho mill")
replace bizcat = "carpenter" if inlist(s8_q2_industry_other,"capentry", "carpenter", "carpentry")
replace bizcat = "guesthouse" if inlist(s8_q2_industry_other,"hotel")
replace bizcat = "food"  if inlist(s8_q2_industry_other,"makes nguru/black sugar","sells agricultural produce","supplying milk")
replace bizcat = "foodstall" if inlist(s8_q2_industry_other,"food staffs","she sells fingerlings(omena)")
replace bizcat = "chemist" if inlist(s8_q2_industry_other,"herbalist")
replace bizcat = "motorcycle_repair" if inlist(s8_q2_industry_other,"repairs motocycles")
replace bizcat = "bike_repair" if inlist(s8_q2_industry_other,"bicycle repair")
replace bizcat = "petrol" if inlist(s8_q2_industry_other,"fuel")
replace bizcat = "piki" if inlist(s8_q2_industry_other,"piki driver")
replace bizcat = "boda" if inlist(s8_q2_industry_other,"boda boda operator")
replace bizcat = "alcohol"  if inlist(s8_q2_industry_other,"brewing local alcohol", "local alcohol brewing", "local brew","local brew selling","local brewer, chang'aa","selling illicit brew(chang'aa)")
replace bizcat = "animal"  if inlist(s8_q2_industry_other,"poultry", "rearing chicken", "selling ducks","selling quails")
replace bizcat = "fish" if inlist(s8_q2_industry_other,"fish","fish selling","fishing")
replace bizcat = "cereal" if inlist(s8_q2_industry_other,"sells cerials")
replace bizcat = "nonfood" if inlist(s8_q2_industry_other,"timber", "tinsmith", "weaving", "weaving and craft", "weaving basketry", "weaving busket", "stone mining", "sugar cane selling", "sisal making")
replace bizcat = "nonfood" if inlist(s8_q2_industry_other,"sisal sewing", "sisal weaving", "selling kerosene", "selling of refined sisal", "selling paraffin", "selling firewood", "reed harvest and sell", "rope making", "rope weaving")
replace bizcat = "nonfood" if inlist(s8_q2_industry_other,"sale of firewood", "sale reeds", "sales papyrus reeds", "sand collecting", "quarry", "pot making", "paraffine selling","making basket","making bracelate with beads")
replace bizcat = "nonfood" if inlist(s8_q2_industry_other,"making mats", "making ropes","making ropes from sisal fibre to sell..","manufacture of reeds","mat making", "mat weaving", "mats weaginv", "handcraft", "firewood production")
replace bizcat = "nonfood" if inlist(s8_q2_industry_other,"charcoal manufacturer/seller", "charcol vender", "craft work", "crafting n weaving of brooms","craftswork.", "carpet weaving", "broom making and selling", "handcraft", "arts baskets")
replace bizcat = "nonfood" if inlist(s8_q2_industry_other, "charcoal burning", "basket and broom weaving", "basket making", "basket weaving", "basketry", "basket weaver")
replace bizcat = "other" if inlist(s8_q2_industry_other,"fixing of plastics like basins, pails..", "batter trade","beekeper","chair renting", "public address system services","making local mats","making mats,")

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
replace bizcat = "51" if inlist(bizcat, "nonfood") // non-food producers and vendors were not distinguished at baseline.

destring bizcat, replace

label def bizcat 1 "Tea buying centre" 2 "Small retail" 3 "M-Pesa" 4 "Mobile charging" 5 "Bank agent" 6 "Large retail" 7 "Restaurant" 8 "Bar" 9 "Hardware store" 10 "Barber shop" 11 "Beauty shop / Salon" 12 "Butcher" 13 "Video Room/Football hall" 14 "Cyber café" 15 "Tailor" 16 "Bookshop" 17 "Posho mill" 18 "Welding / metalwork" 19 "Carpenter" 20 "Guesthouse/ Hotel" ///
21 "Food stand / Prepared food vendor" 22 "Food stall / Raw food and fruits vendor" 23 "Chemist" 24 "Motor Vehicles Mechanic" 25 "Motorcycle Repair / Shop" 26 "Bicycle repair / mechanic shop" 27 "Petrol station" 28 "Piki driver" 29 "Boda driver" 30 "Sale or brewing of homemade alcohol / liquor" 31 "Livestock / Animal (Products) / Poultry Sale" 32 "Oxen / donkey / tractor plouging" 33 "Fishing" 34 "Fish Sale / Mongering" 35 "Cereals" 36 "Agrovet" 37 "Photo studio" 38 "Jaggery" 39 "Non-Food Vendor" 40 "Non-Food Producer" ///
41 "Other (specify)" 42 "None" 51 "Nonfood vendor or producer", replace

label val bizcat bizcat
tab bizcat

gen bizcat_products = ""
replace bizcat_products = "grocery" if inlist(s8_q2_industry,3134,3140,6110,6211)
replace bizcat_products = "household" if inlist(s8_q2_industry,6214,6224,6225,6113,6120)
replace bizcat_products = "other" if inlist(s8_q2_industry,6231,6121)

replace bizcat_products = "grocery" if inlist(s8_q2_industry_other,"small business (selling sugar, tea leaves and match box)")

replace bizcat_products = "1" if bizcat_products == "grocery"
replace bizcat_products = "2" if bizcat_products == "household"
replace bizcat_products = "3" if inlist(bizcat_products, "dk", "other")
replace bizcat_products = "" if inlist(bizcat_products, "mobilecharge", "mpesa")
destring bizcat_products, replace

label def bizcat_products 1 "Groceries" 2 "Household goods" 3 "All other retail"
label val bizcat_products bizcat_products
tab bizcat_products

gen bizcat_nonfood = ""
replace bizcat_nonfood = "charcoal" if inlist(s8_q2_industry,3313)
replace bizcat_nonfood = "other" if inlist(s8_q2_industry,3411,3529,3903)
replace bizcat_nonfood = "brick" if inlist(s8_q2_industry,3693)

replace bizcat_nonfood = "charcoal" if inlist(s8_q2_industry_other, "charcoal burning", "charcoal manufacturer/seller", "charcol vender")
replace bizcat_nonfood = "other" if inlist(s8_q2_industry_other,"timber","selling firewood", "sale of firewood","sugar cane selling","sale reeds", "sales papyrus reeds", "manufacture of reeds", "firewood production")
replace bizcat_nonfood = "craft" if inlist(s8_q2_industry_other,"tinsmith", "weaving", "weaving and craft", "weaving basketry", "weaving busket","sisal making","sisal sewing", "sisal weaving","selling of refined sisal")
replace bizcat_nonfood = "craft" if inlist(s8_q2_industry_other,"reed harvest and sell", "rope making", "rope weaving","pot making","making basket","making bracelate with beads""making mats", "making ropes","making ropes from sisal fibre to sell..")
replace bizcat_nonfood = "craft" if inlist(s8_q2_industry_other,"mats weaving", "handcraft", "craft work", "crafting n weaving of brooms","craftswork.", "carpet weaving", "broom making and selling","handcraft", "arts baskets")
replace bizcat_nonfood = "craft" if inlist(s8_q2_industry_other,"mat making","mat weaving","basket and broom weaving", "basket making", "basket weaving", "basketry", "basket weaver")
replace bizcat_nonfood = "stone" if inlist(s8_q2_industry_other,"stone mining","quarry")
replace bizcat_nonfood = "kerosene" if inlist(s8_q2_industry_other,"selling kerosene")
replace bizcat_nonfood = "parafiin" if inlist(s8_q2_industry_other,"selling paraffin","paraffine selling")
replace bizcat_nonfood = "sand" if inlist(s8_q2_industry_other,"sand collecting")

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

** generate aggregated business categories **
*********************************************
foreach v in bizcat {
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
foreach v in bizcat {
	replace `v'_cons = 5 if `v' == 51 & inlist(`v'_nonfood, 2, 6)
	replace `v'_cons = 6 if `v' == 51 & inlist(`v'_nonfood, 1, 3, 4, 5, 7, 8, 9, 10, 11, 13)
	replace `v'_cons = 4 if `v' == 51 & inlist(`v'_nonfood, 12)
	replace `v'_cons = 6 if `v' == 51 & inlist(`v'_nonfood, 14)
}

order location_name sublocation_name village_code village_name hhid_key fr_id_BL HH_ENT_SUR_BL_date consent bizcat bizcat_products bizcat_nonfood bizcat_cons
drop submissiondate tabletid start end survey_id form_name key parent_key isvalidated text_audit

***********************************************
** Clean up enterprise variables - section 2 **
***********************************************

** Ownership information **
***************************
gen owner_f = (s1_q7_ressex == 1) if s1_q7_ressex != .
gen owner_age = s2_q4a_age

** owner education **
gen owner_education = .
gen owner_primary = .
gen owner_secondary = .
gen owner_degree = .

replace owner_education = 0 if s5_q1_system == "noschooling"
replace owner_primary = 0 if s5_q1_system == "noschooling"
replace owner_secondary = 0 if s5_q1_system == "noschooling"
replace owner_degree = 0 if s5_q1_system == "noschooling"

destring s5_q1a_highestedu, replace
replace owner_education = s5_q1a_highestedu - 100 if s5_q1_system == "current" & inrange(s5_q1a_highestedu,100,112)
replace owner_education = 12 + 2 if s5_q1_system == "current" & inlist(s5_q1a_highestedu,115,117,119)
replace owner_education = 12 + 4 if s5_q1_system == "current" & inlist(s5_q1a_highestedu,116,118,120)
replace owner_education = 12 + 6 if s5_q1_system == "current" & s5_q1a_highestedu == 121

replace owner_primary = 1 if s5_q1_system == "current" & inrange(s5_q1a_highestedu,108,121)
replace owner_secondary = 1 if s5_q1_system == "current" & inrange(s5_q1a_highestedu,112,121)
replace owner_degree = 1 if s5_q1_system == "current" & inlist(s5_q1a_highestedu,116,118,120,121)

replace owner_education = s5_q1a_highestedu - 200 if s5_q1_system == "previous" & inrange(s5_q1a_highestedu,200,214)
replace owner_education = 13 + 2 if s5_q1_system == "previous" & inlist(s5_q1a_highestedu,215,217,219)
replace owner_education = 13 + 4 if s5_q1_system == "previous" & inlist(s5_q1a_highestedu,216,218,220)
replace owner_education = 13 + 6 if s5_q1_system == "previous" & s5_q1a_highestedu == 221

replace owner_primary = 1 if s5_q1_system == "previous" & inrange(s5_q1a_highestedu,207,221)
replace owner_secondary = 1 if s5_q1_system == "previous" & inrange(s5_q1a_highestedu,212,221)
replace owner_degree = 1 if s5_q1_system == "previous" & inlist(s5_q1a_highestedu,216,218,220,221)

replace owner_education = 0 if owner_education == . & inlist(s5_q1a_highestedu,100,130,230)
replace owner_primary = 0 if owner_primary == . & inlist(s5_q1a_highestedu,100,130,230)
replace owner_secondary = 0 if owner_secondary == . & inlist(s5_q1a_highestedu,100,130,230)
replace owner_degree = 0 if owner_degree == . & inlist(s5_q1a_highestedu,100,130,230)


** Owner residence information **
*********************************
gen owner_resident = 1 // we are only looking at enterprises within the village here


******************************************
** Clean up enterprise data - section 4 **
******************************************
replace s8_q12_bizstartdate = . if year(s8_q12_bizstartdate) == 1900

gen ent_start_year = year(s8_q12_bizstartdate) if s8_q12_bizstartdate != .
gen ent_start_month = month(s8_q12_bizstartdate) if s8_q12_bizstartdate != .

gen ent_age = mofd(HH_ENT_SUR_BL_date) - mofd(s8_q12_bizstartdate)
replace ent_age = 0 if ent_age < 0 // two enterprises have age less than zero: replace with zero.

** generate seasonality profile for each business **
foreach mon in jan feb mar apr may jun jul aug sep oct nov dec {
	gen op_`mon' = 1 if regexm(s8_q5_monthsworked,"`mon'") | regexm(s8_q5_monthsworked,"all")
	replace op_`mon' = 0 if op_`mon' == . & s8_q5_monthsworked != ""
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

** operational hours per week/day **
gen op_hoursperweek = s8_q4_hrsworked // assume FR hours correspond to business hours
tab op_hoursperweek


** Employee information **
**************************
gen emp_n_tot = s8_q6_numemployees
gen emp_n_family = s8_q6a_hhemployees


** Clean Enterprise Financial Information **
********************************************

** Costs **
gen wage_total = s8_q6b_wagebill
replace wage_total = . if inlist(s8_q6b_wagebill,-99,-98,9999,999)
replace wage_total = 0 if emp_n_tot == 0

gen c_rent = s8_q15a_rentamount if !inlist(s8_q15a_rentamount,-99,99)
replace c_rent = 0 if inlist(s8_q15_ownpremises,1,3)

gen c_utilities = s8_q16a_elecwater if !inlist(s8_q16a_elecwater,-9999,99,-88,88)
gen c_repairs = s8_q16f_repairs if !inlist(s8_q16f_repairs,-9999,99,-88)
gen c_healthinsurance = s8_q17a_healthinsurance if !inlist(s8_q17a_healthinsurance,-9999)
gen c_vandalism = s8_q18_vandalismamount if !inlist(s8_q18_vandalismamount,-9999)
replace c_vandalism = 0 if c_vandalism == .

** Revenues and profits **
gen rev_mon = s8_q7a_earningslastmth if !inlist(s8_q7a_earningslastmth,-88,-98,-99,99,999,9999)
gen rev_year = s8_q7b_earningslastyr*12/min(12,ent_age) if !inlist(s8_q7b_earningslastyr,-88,-98,-99,99,999,9999)

gen prof_mon = s8_q11a_profitlastmth if !inlist(s8_q11a_profitlastmth,-88,-98,-99,99,999,9999)
gen prof_year = s8_q11b_profitlastyr*12/min(12,ent_age) if !inlist(s8_q11b_profitlastyr,-88,-98,-99,99,999,9999)

** Flag inconsistencies **
gen revprof_incons = 0
replace revprof_incons = 1 if rev_mon > rev_year & rev_mon != .
replace revprof_incons = 1 if prof_mon > rev_mon & prof_mon != .
replace revprof_incons = 1 if prof_year > rev_year & prof_year != .
replace revprof_incons = 1 if prof_year == prof_mon & prof_year != .
replace revprof_incons = 1 if rev_year == rev_mon & prof_year != .

** Taxes and Fees **
gen d_licensed = 2 - s8_q8_islicensed if !inlist(s8_q8_islicensed, 3, -99, -88)
gen d_registered = 2 - s8_q9_isregistered if !inlist(s8_q9_isregistered, 3, -99, -88)

gen t_license = s8_q8a_licenseamount
replace t_license = 0 if d_licensed == 0
replace t_license = . if inlist(s8_q8a_licenseamount,-99,88,99)

gen t_marketfees = s8_q17b_marketfees if !inlist(s8_q17b_marketfees, -98,99)

gen t_county = s8_q17d_countytaxes if !inlist(s8_q17d_countytaxes,9999,999,99,-98,-99)
gen t_national = s8_q17e_nationaltaxes if !inlist(s8_q17e_nationaltaxes,9999,999,99,-98,-99)
gen t_chiefs = s8_q17f_localtaxes if !inlist(s8_q17f_localtaxes,9999,999,99,-98,-99)
gen t_other = s8_q17g_bribes if !inlist(s8_q17g_bribes,9999,999,99,-98,-99)


************************
/*** SAVING DATASET ***/
************************
keep location_name sublocation_name village_code village_name hhid_key fr_id_BL HH_ENT_SUR_BL_date consent bizcat bizcat_products bizcat_nonfood bizcat_cons owner_f owner_age owner_education owner_primary owner_secondary owner_degree owner_resident ent_start_year ent_start_month ent_age op_jan op_feb op_mar op_apr op_may op_jun op_jul op_aug op_sep op_oct op_nov op_dec op_seasonal op_monperyear op_hoursperweek emp_n_tot emp_n_family wage_total c_rent c_utilities c_repairs c_healthinsurance c_vandalism rev_mon rev_year prof_mon prof_year revprof_incons d_licensed d_registered t_license t_marketfees t_county t_national t_chiefs t_other

** Label variables **
label var hhid_key "Baseline household ID (unique with village_code)"
label var fr_id_BL "Baseline FR ID (unique with village_code)"
label var bizcat "Business category"
label var bizcat_products "Business category - main products"
label var bizcat_nonfood "Non-food business category"
label var bizcat_cons "Business category (consolidated)"

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
label var op_hoursperweek "Number of hours open per day"

label var owner_f "Owner is female"
label var owner_education "Owner - years of education"
label var owner_primary "Owner - completed primary school"
label var owner_secondary "Owner - completed secondary school"
label var owner_degree  "Owner - has a degree"
label var owner_resident "Owner - resident in the same village"

label var emp_n_tot "Total number of employees"
label var emp_n_family "Number of family employees"
label var wage_total "Total wage bill last month"

label var rev_mon "Revenues last month (in KES)"
label var rev_year "Revenues last year (in KES)"
label var prof_mon "Profits last month (in KES)"
label var prof_year "Profits last year (in KES)"
label var revprof_incons "Profits/Revenues flagged inconsistent"
label var c_rent "KES spent on rent"
label var c_utilities "KES spent on utilities"
label var c_repairs "KES spent on repairs"
label var c_healthinsurance "KES spent on health insurance"
label var c_vandalism "KES spent on vandalism"

label var d_licensed "Business is licensed with county government"
label var t_license "Spending on business license last year"
label var t_marketfees "Market fees last year"
label var d_registered "Business is registered with the government"
label var t_county "County taxes paid last year"
label var t_national "National taxes paid last year"
label var t_chiefs "Taxes paid to chiefs / assitant chiefs / village elders"
label var t_other "Other taxes paid"

order location_name sublocation_name village_code village_name hhid_key fr_id_BL HH_ENT_SUR_BL_date consent ///
bizcat* ent_start_year ent_start_month ent_age op_* owner_* emp_* wage_* rev_* prof_* revprof_incons c_* ///
d_licensed d_registered t_license t_marketfees t_county t_national t_chiefs t_other ///

save "$da/intermediate/GE_HH-ENT-Survey_Baseline_CLEAN_FINAL.dta", replace
project, creates("$da/intermediate/GE_HH-ENT-Survey_Baseline_CLEAN_FINAL.dta")
