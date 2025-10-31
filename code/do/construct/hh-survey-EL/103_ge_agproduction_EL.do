

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

********************************************************************************
*************** GE - PROFIT FROM AGRICULTURAL HOME PRODUCTION ****************
********************************************************************************

* based on work by Nick Li on KLPS-3 data for the Ag Gaps paper
* This is designed to be run after a clean endline dataset is constructed but prior to the
*  do files that construct analysis versions of the dataset, as they pull in data from the
*  created datasets here
* Primarily written by Priscilla - see her folder structure for more details (construct_clean/household_endline/do)



/****************************************************/

project, uses("$da/intermediate/GE_HH-EL_setup.dta")

use "$da/intermediate/GE_HH-EL_setup.dta", clear


* Format the date of interview as in the prices panel


*Keep only the variables and observations needed to reshape the panel
keep s1_hhid_key s1_q2_subcounty survey_yr today survey_mth s7_q15_crop_* s7_q16_amtproduced_* s7_q16_unitsamtproduced_* s7_q16_unitsamtproduced_oth_* s7_q17_soldcrop_* s7_q18i_amtcropsold_* s7_q18i_unitsamtcropsold_* s7_q18i_unitsamtcropsold_oth_* s7_q18ii_valuecropsold_*
desc s7_q16_unitsamtproduced_oth_* s7_q18i_unitsamtcropsold_oth_*

* Reshape the dataset to long

reshape long s7_q15_crop_ s7_q16_amtproduced_ s7_q16_unitsamtproduced_ s7_q16_unitsamtproduced_oth_ s7_q17_soldcrop_ s7_q18i_amtcropsold_ s7_q18i_unitsamtcropsold_ s7_q18i_unitsamtcropsold_oth_ s7_q18ii_valuecropsold_, i(s1_hhid_key) j(crop_num)
desc s7_q15_crop_
//our crop variable is not coded (it is already formatted as str with the crops' names)
drop if missing(s7_q15_crop_)

tab1 s7_q16_amtproduced_ s7_q16_unitsamtproduced_ s7_q16_unitsamtproduced_oth_ s7_q17_soldcrop_ s7_q18i_amtcropsold_ s7_q18i_unitsamtcropsold_ s7_q18i_unitsamtcropsold_oth_ s7_q18ii_valuecropsold_
recode s7_q16_unitsamtproduced_ s7_q18i_unitsamtcropsold_ (777 = 17)
recode s7_q17_soldcrop_ 2 = 0

tab1 s7_q16_amtproduced_ s7_q17_soldcrop_
tab1 s7_q18i_amtcropsold_ s7_q18ii_valuecropsold_ if s7_q17_soldcrop_ != 0, m

//Deal with outliers later
summ s7_q16_amtproduced_ s7_q16_unitsamtproduced_ s7_q16_unitsamtproduced_oth_ s7_q18i_amtcropsold_ s7_q18i_unitsamtcropsold_ s7_q18i_unitsamtcropsold_oth_ s7_q18ii_valuecropsold_
tab s7_q18ii_valuecropsold_ if s7_q18ii_valuecropsold_ <= 1
recode s7_q16_amtproduced_ -75 = .
recode s7_q18i_amtcropsold_ -99 = .
//s7_q18ii_valuecropsold_ = .99 looks like a missing value:
replace s7_q18ii_valuecropsold_ = . if s7_q18ii_valuecropsold_ < 1
summ s7_q16_amtproduced_ s7_q16_unitsamtproduced_ s7_q16_unitsamtproduced_oth_ s7_q18i_amtcropsold_ s7_q18i_unitsamtcropsold_ s7_q18i_unitsamtcropsold_oth_ s7_q18ii_valuecropsold_
/* PO: we'll want to adjust the following to match any outliers in our data
* Clean amounts (99999999999 looks like a missing value)
drop if R3_s9_1_16amt_ > 250000 // Data won't be useful if we don't have a quanitty. These are all missing
replace R3_s9_1_18iphysamt_ = . if R3_s9_1_18iphysamt_ > 250000
replace R3_s9_1_18iphysunit_ = . if R3_s9_1_18iphysamt_ > 250000
replace R3_s9_1_18iirevenue_ = . if R3_s9_1_18iirevenue_  > 250000
replace R3_s9_1_18iphysamt_ = . if R3_s9_1_18iphysunit_ >= 17 // "Other" physical units not in dataset
replace R3_s9_1_18iphysunit_ = . if R3_s9_1_18iphysunit_ >= 17 // "Other" physical units not in dataset
replace R3_s9_1_18iphysamt_ = . if R3_s9_1_18iphysamt_ > 0 & R3_s9_1_18iirevenue_ == 0 // Some people sold something but got no revenue
replace R3_s9_1_18iphysunit_ = . if R3_s9_1_18iphysamt_ > 0 & R3_s9_1_18iirevenue_ == 0 // Some people sold something but got no revenue
replace R3_s9_1_18iirevenue_ = . if R3_s9_1_18iphysamt_ > 0 & R3_s9_1_18iirevenue_ == 0 // Some people sold something but got no revenue
*/




** Fix Units
* replace units for other
/* Here, we want to convert other units to units that we have in our data. We can then do
   standard conversions by units below. First, we replace the amount as needed. Then, we ensure that the units line up. See examples below */
* for instance, one response in our data is - 4bags of 50 gorogoro. Amount is listed as 4. We want to multiply amount by 50, then change units to goro goro (4)

***Crop production
replace s7_q16_unitsamtproduced_oth_ = trim(s7_q16_unitsamtproduced_oth_)

* listing all other units
count if s7_q16_unitsamtproduced_ == 17
list s7_q16_amtproduced_ s7_q16_unitsamtproduced_oth_ if s7_q16_unitsamtproduced_ == 17

*units directly related to kg
replace s7_q16_amtproduced_ = s7_q16_amtproduced_*50 if s7_q16_unitsamtproduced_oth_ =="50 kg gunia" & s7_q16_unitsamtproduced_==17
replace s7_q16_amtproduced_ = s7_q16_amtproduced_*20 if s7_q16_unitsamtproduced_oth_ =="GUNDA 20KG" & s7_q16_unitsamtproduced_==17
replace s7_q16_amtproduced_ = s7_q16_amtproduced_*50 if s7_q16_unitsamtproduced_oth_ =="GUNIA -50KG" & s7_q16_unitsamtproduced_==17
replace s7_q16_amtproduced_ = s7_q16_amtproduced_*40 if s7_q16_unitsamtproduced_oth_ =="GUNIA-40KG" & s7_q16_unitsamtproduced_==17
replace s7_q16_amtproduced_ = s7_q16_amtproduced_*40 if s7_q16_unitsamtproduced_oth_ =="Gunia of 40kg" & s7_q16_unitsamtproduced_==17
replace s7_q16_amtproduced_ = s7_q16_amtproduced_*25 if s7_q16_unitsamtproduced_oth_ =="sack of 25 kg" & s7_q16_unitsamtproduced_==17
replace s7_q16_amtproduced_ = s7_q16_amtproduced_*50 if s7_q16_unitsamtproduced_oth_ =="sack of 50kg" & s7_q16_unitsamtproduced_==17
replace s7_q16_amtproduced_ = s7_q16_amtproduced_*907 if s7_q16_unitsamtproduced_oth_ =="Tone" & s7_q16_unitsamtproduced_==17
replace s7_q16_amtproduced_ = s7_q16_amtproduced_*907 if s7_q16_unitsamtproduced_oth_ =="Tonnes" & s7_q16_unitsamtproduced_==17

replace s7_q16_unitsamtproduced_ = 2 if s7_q16_unitsamtproduced_oth_ =="50 kg gunia" & s7_q16_unitsamtproduced_==17
replace s7_q16_unitsamtproduced_ = 2 if s7_q16_unitsamtproduced_oth_ =="GUNDA 20KG" & s7_q16_unitsamtproduced_==17
replace s7_q16_unitsamtproduced_ = 2 if s7_q16_unitsamtproduced_oth_ =="GUNIA -50KG" & s7_q16_unitsamtproduced_==17
replace s7_q16_unitsamtproduced_ = 2 if s7_q16_unitsamtproduced_oth_ =="GUNIA-40KG" & s7_q16_unitsamtproduced_==17
replace s7_q16_unitsamtproduced_ = 2 if s7_q16_unitsamtproduced_oth_ =="Gunia of 40kg" & s7_q16_unitsamtproduced_==17
replace s7_q16_unitsamtproduced_ = 2 if s7_q16_unitsamtproduced_oth_ =="sack of 25 kg" & s7_q16_unitsamtproduced_==17
replace s7_q16_unitsamtproduced_ = 2 if s7_q16_unitsamtproduced_oth_ =="sack of 50kg" & s7_q16_unitsamtproduced_==17
replace s7_q16_unitsamtproduced_ = 2 if s7_q16_unitsamtproduced_oth_ =="Tone" & s7_q16_unitsamtproduced_==17
replace s7_q16_unitsamtproduced_ = 2 if s7_q16_unitsamtproduced_oth_ =="Tonnes" & s7_q16_unitsamtproduced_==17

*units directly related to gorogoro
list s7_q16_amtproduced_ if s7_q16_unitsamtproduced_oth_ =="2 Sacks of 40  gorogoro" & s7_q16_unitsamtproduced_==17
list s7_q16_amtproduced_ if s7_q16_unitsamtproduced_oth_ =="3Suck of  90  goro goro" & s7_q16_unitsamtproduced_==17
list s7_q16_amtproduced_ if s7_q16_unitsamtproduced_oth_ =="3sucks of fifty  goro gor" & s7_q16_unitsamtproduced_==17
list s7_q16_amtproduced_ if s7_q16_unitsamtproduced_oth_ =="4 sacks of 40 gorogoro" & s7_q16_unitsamtproduced_==17
list s7_q16_amtproduced_ if s7_q16_unitsamtproduced_oth_ =="4bags of 50 gorogoro" & s7_q16_unitsamtproduced_==17

replace s7_q16_amtproduced_ = s7_q16_amtproduced_*40 if s7_q16_unitsamtproduced_oth_ =="2 Sacks of 40  gorogoro" & s7_q16_unitsamtproduced_==17
replace s7_q16_amtproduced_ = s7_q16_amtproduced_*90 if s7_q16_unitsamtproduced_oth_ =="3Suck of  90  goro goro" & s7_q16_unitsamtproduced_==17
replace s7_q16_amtproduced_ = s7_q16_amtproduced_*50 if s7_q16_unitsamtproduced_oth_ =="3sucks of fifty  goro goro" & s7_q16_unitsamtproduced_==17
replace s7_q16_amtproduced_ = s7_q16_amtproduced_*40 if s7_q16_unitsamtproduced_oth_ =="4 sacks of 40 gorogoro" & s7_q16_unitsamtproduced_==17
replace s7_q16_amtproduced_ = s7_q16_amtproduced_*40 if s7_q16_unitsamtproduced_oth_ =="40 gorogoro sack" & s7_q16_unitsamtproduced_==17
replace s7_q16_amtproduced_ = s7_q16_amtproduced_*50 if s7_q16_unitsamtproduced_oth_ =="4bags of 50 gorogoro" & s7_q16_unitsamtproduced_==17
replace s7_q16_amtproduced_ = s7_q16_amtproduced_*50 if s7_q16_unitsamtproduced_oth_ =="One Suck of fifty goro goro" & s7_q16_unitsamtproduced_==17
replace s7_q16_amtproduced_ = s7_q16_amtproduced_*50 if s7_q16_unitsamtproduced_oth_ =="One sack of  50 gorogoro" & s7_q16_unitsamtproduced_==17
replace s7_q16_amtproduced_ = s7_q16_amtproduced_*40 if s7_q16_unitsamtproduced_oth_ =="Sack  of  40  gorogoro" & s7_q16_unitsamtproduced_==17
replace s7_q16_amtproduced_ = s7_q16_amtproduced_*42 if s7_q16_unitsamtproduced_oth_ =="Sack of 42 gorogoro" & s7_q16_unitsamtproduced_==17
replace s7_q16_amtproduced_ = s7_q16_amtproduced_*42 if s7_q16_unitsamtproduced_oth_ =="Sacks of 42 gorogoro" & s7_q16_unitsamtproduced_==17
replace s7_q16_amtproduced_ = s7_q16_amtproduced_*40 if s7_q16_unitsamtproduced_oth_ =="Suck of 40 gorogoro" & s7_q16_unitsamtproduced_==17

replace s7_q16_unitsamtproduced_ = 4 if s7_q16_unitsamtproduced_oth_ =="2 Sacks of 40  gorogoro" & s7_q16_unitsamtproduced_==17
replace s7_q16_unitsamtproduced_ = 4 if s7_q16_unitsamtproduced_oth_ =="3Suck of  90  goro goro" & s7_q16_unitsamtproduced_==17
replace s7_q16_unitsamtproduced_ = 4 if s7_q16_unitsamtproduced_oth_ =="3sucks of fifty  goro goro" & s7_q16_unitsamtproduced_==17
replace s7_q16_unitsamtproduced_ = 4 if s7_q16_unitsamtproduced_oth_ =="4 sacks of 40 gorogoro" & s7_q16_unitsamtproduced_==17
replace s7_q16_unitsamtproduced_ = 4 if s7_q16_unitsamtproduced_oth_ =="40 gorogoro sack" & s7_q16_unitsamtproduced_==17
replace s7_q16_unitsamtproduced_ = 4 if s7_q16_unitsamtproduced_oth_ =="4bags of 50 gorogoro" & s7_q16_unitsamtproduced_==17
replace s7_q16_unitsamtproduced_ = 4 if s7_q16_unitsamtproduced_oth_ =="One Suck of fifty goro goro" & s7_q16_unitsamtproduced_==17
replace s7_q16_unitsamtproduced_ = 4 if s7_q16_unitsamtproduced_oth_ =="One sack of  50 gorogoro" & s7_q16_unitsamtproduced_==17
replace s7_q16_unitsamtproduced_ = 4 if s7_q16_unitsamtproduced_oth_ =="Sack  of  40  gorogoro" & s7_q16_unitsamtproduced_==17
replace s7_q16_unitsamtproduced_ = 4 if s7_q16_unitsamtproduced_oth_ =="Sack of 42 gorogoro" & s7_q16_unitsamtproduced_==17
replace s7_q16_unitsamtproduced_ = 4 if s7_q16_unitsamtproduced_oth_ =="Sacks of 42 gorogoro" & s7_q16_unitsamtproduced_==17
replace s7_q16_unitsamtproduced_ = 4 if s7_q16_unitsamtproduced_oth_ =="Suck of 40 gorogoro" & s7_q16_unitsamtproduced_==17

*converting reports on destroyed production to 0kg
replace s7_q16_amtproduced_ = 0 if s7_q16_unitsamtproduced_oth_ =="Cannot be quantified.the kales got spoilt in the farm" & s7_q16_unitsamtproduced_==17
replace s7_q16_amtproduced_ = 0 if s7_q16_unitsamtproduced_oth_ =="Destroyed by drought" & s7_q16_unitsamtproduced_==17
replace s7_q16_amtproduced_ = 0 if s7_q16_unitsamtproduced_oth_ =="Did not get any" & s7_q16_unitsamtproduced_==17
replace s7_q16_amtproduced_ = 0 if s7_q16_unitsamtproduced_oth_ =="Did not get anything becouse of too prolonged druoght" & s7_q16_unitsamtproduced_==17
replace s7_q16_amtproduced_ = 0 if s7_q16_unitsamtproduced_oth_ =="Didn't get any produse of sorghum as it dried up in the farm" & s7_q16_unitsamtproduced_==17
replace s7_q16_amtproduced_ = 0 if s7_q16_unitsamtproduced_oth_ =="Dint get anything" & s7_q16_unitsamtproduced_==17
replace s7_q16_amtproduced_ = 0 if s7_q16_unitsamtproduced_oth_ =="Exes sie sun destroyed  everything" & s7_q16_unitsamtproduced_==17
replace s7_q16_amtproduced_ = 0 if s7_q16_unitsamtproduced_oth_ =="Faced destruction from hippos and flood" & s7_q16_unitsamtproduced_==17
replace s7_q16_amtproduced_ = 0 if s7_q16_unitsamtproduced_oth_ =="Faced destruction from hippos and floods" & s7_q16_unitsamtproduced_==17
replace s7_q16_amtproduced_ = 0 if s7_q16_unitsamtproduced_oth_ =="Is when FR has planted 18 stools of bananas just by boundaries of his farm" & s7_q16_unitsamtproduced_==17
replace s7_q16_amtproduced_ = 0 if s7_q16_unitsamtproduced_oth_ =="It's when fr has planted for the first time" & s7_q16_unitsamtproduced_==17
replace s7_q16_amtproduced_ = 0 if s7_q16_unitsamtproduced_oth_ =="Its when fr has planted crops for the first time  she has never harvested" & s7_q16_unitsamtproduced_==17
replace s7_q16_amtproduced_ = 0 if s7_q16_unitsamtproduced_oth_ =="Just planted not harvested" & s7_q16_unitsamtproduced_==17
replace s7_q16_amtproduced_ = 0 if s7_q16_unitsamtproduced_oth_ =="Just planted this february" & s7_q16_unitsamtproduced_==17
replace s7_q16_amtproduced_ = 0 if s7_q16_unitsamtproduced_oth_ =="Millet was desroyed" & s7_q16_unitsamtproduced_==17
replace s7_q16_amtproduced_ = 0 if s7_q16_unitsamtproduced_oth_ =="No crop cultivated" & s7_q16_unitsamtproduced_==17
replace s7_q16_amtproduced_ = 0 if s7_q16_unitsamtproduced_oth_ =="No harvest" & s7_q16_unitsamtproduced_==17
replace s7_q16_amtproduced_ = 0 if s7_q16_unitsamtproduced_oth_ =="No harvest because of destruction" & s7_q16_unitsamtproduced_==17
replace s7_q16_amtproduced_ = 0 if s7_q16_unitsamtproduced_oth_ =="No maize was destroyed" & s7_q16_unitsamtproduced_==17
replace s7_q16_amtproduced_ = 0 if s7_q16_unitsamtproduced_oth_ =="None" & s7_q16_unitsamtproduced_==17
replace s7_q16_amtproduced_ = 0 if s7_q16_unitsamtproduced_oth_ =="Not harvested" & s7_q16_unitsamtproduced_==17
replace s7_q16_amtproduced_ = 0 if s7_q16_unitsamtproduced_oth_ =="Not yet harvested" & s7_q16_unitsamtproduced_==17
replace s7_q16_amtproduced_ = 0 if s7_q16_unitsamtproduced_oth_ =="Not yet harvested /ready for harvesting" & s7_q16_unitsamtproduced_==17
replace s7_q16_amtproduced_ = 0 if s7_q16_unitsamtproduced_oth_ =="Not yet harvested." & s7_q16_unitsamtproduced_==17
replace s7_q16_amtproduced_ = 0 if s7_q16_unitsamtproduced_oth_ =="Not yet ready" & s7_q16_unitsamtproduced_==17
replace s7_q16_amtproduced_ = 0 if s7_q16_unitsamtproduced_oth_ =="Not yet ready for harvesting" & s7_q16_unitsamtproduced_==17
replace s7_q16_amtproduced_ = 0 if s7_q16_unitsamtproduced_oth_ =="Nothing" & s7_q16_unitsamtproduced_==17
replace s7_q16_amtproduced_ = 0 if s7_q16_unitsamtproduced_oth_ =="Nothing harvested" & s7_q16_unitsamtproduced_==17
replace s7_q16_amtproduced_ = 0 if s7_q16_unitsamtproduced_oth_ =="Nothing was harvested" & s7_q16_unitsamtproduced_==17
replace s7_q16_amtproduced_ = 0 if s7_q16_unitsamtproduced_oth_ =="Planted for the first time not yet grown" & s7_q16_unitsamtproduced_==17
replace s7_q16_amtproduced_ = 0 if s7_q16_unitsamtproduced_oth_ =="Sorghum plantation was destroyed and thus no harvest was brought home" & s7_q16_unitsamtproduced_==17
replace s7_q16_amtproduced_ = 0 if s7_q16_unitsamtproduced_oth_ =="Still not harvested" & s7_q16_unitsamtproduced_==17
replace s7_q16_amtproduced_ = 0 if s7_q16_unitsamtproduced_oth_ =="The maize was desroyed all in farm due to drought" & s7_q16_unitsamtproduced_==17
replace s7_q16_amtproduced_ = 0 if s7_q16_unitsamtproduced_oth_ =="They were destroyed at the farm" & s7_q16_unitsamtproduced_==17
replace s7_q16_amtproduced_ = 0 if s7_q16_unitsamtproduced_oth_ =="Waiting for harvest" & s7_q16_unitsamtproduced_==17
replace s7_q16_amtproduced_ = 0 if s7_q16_unitsamtproduced_oth_ =="not yet harvested" & s7_q16_unitsamtproduced_==17
replace s7_q16_amtproduced_ = 0 if s7_q16_unitsamtproduced_oth_ =="Got spoilt" & s7_q16_unitsamtproduced_==17

replace s7_q16_unitsamtproduced_ = 2 if s7_q16_unitsamtproduced_oth_ =="Cannot be quantified.the kales got spoilt in the farm" & s7_q16_unitsamtproduced_==17
replace s7_q16_unitsamtproduced_ = 2 if s7_q16_unitsamtproduced_oth_ =="Destroyed by drought" & s7_q16_unitsamtproduced_==17
replace s7_q16_unitsamtproduced_ = 2 if s7_q16_unitsamtproduced_oth_ =="Did not get any" & s7_q16_unitsamtproduced_==17
replace s7_q16_unitsamtproduced_ = 2 if s7_q16_unitsamtproduced_oth_ =="Did not get anything becouse of too prolonged druoght" & s7_q16_unitsamtproduced_==17
replace s7_q16_unitsamtproduced_ = 2 if s7_q16_unitsamtproduced_oth_ =="Didn't get any produse of sorghum as it dried up in the farm" & s7_q16_unitsamtproduced_==17
replace s7_q16_unitsamtproduced_ = 2 if s7_q16_unitsamtproduced_oth_ =="Dint get anything" & s7_q16_unitsamtproduced_==17
replace s7_q16_unitsamtproduced_ = 2 if s7_q16_unitsamtproduced_oth_ =="Exes sie sun destroyed  everything" & s7_q16_unitsamtproduced_==17
replace s7_q16_unitsamtproduced_ = 2 if s7_q16_unitsamtproduced_oth_ =="Faced destruction from hippos and flood" & s7_q16_unitsamtproduced_==17
replace s7_q16_unitsamtproduced_ = 2 if s7_q16_unitsamtproduced_oth_ =="Faced destruction from hippos and floods" & s7_q16_unitsamtproduced_==17
replace s7_q16_unitsamtproduced_ = 2 if s7_q16_unitsamtproduced_oth_ =="Is when FR has planted 18 stools of bananas just by boundaries of his farm" & s7_q16_unitsamtproduced_==17
replace s7_q16_unitsamtproduced_ = 2 if s7_q16_unitsamtproduced_oth_ =="It's when fr has planted for the first time" & s7_q16_unitsamtproduced_==17
replace s7_q16_unitsamtproduced_ = 2 if s7_q16_unitsamtproduced_oth_ =="Its when fr has planted crops for the first time  she has never harvested" & s7_q16_unitsamtproduced_==17
replace s7_q16_unitsamtproduced_ = 2 if s7_q16_unitsamtproduced_oth_ =="Just planted not harvested" & s7_q16_unitsamtproduced_==17
replace s7_q16_unitsamtproduced_ = 2 if s7_q16_unitsamtproduced_oth_ =="Just planted this february" & s7_q16_unitsamtproduced_==17
replace s7_q16_unitsamtproduced_ = 2 if s7_q16_unitsamtproduced_oth_ =="Millet was desroyed" & s7_q16_unitsamtproduced_==17
replace s7_q16_unitsamtproduced_ = 2 if s7_q16_unitsamtproduced_oth_ =="No crop cultivated" & s7_q16_unitsamtproduced_==17
replace s7_q16_unitsamtproduced_ = 2 if s7_q16_unitsamtproduced_oth_ =="No harvest" & s7_q16_unitsamtproduced_==17
replace s7_q16_unitsamtproduced_ = 2 if s7_q16_unitsamtproduced_oth_ =="No harvest because of destruction" & s7_q16_unitsamtproduced_==17
replace s7_q16_unitsamtproduced_ = 2 if s7_q16_unitsamtproduced_oth_ =="No maize was destroyed" & s7_q16_unitsamtproduced_==17
replace s7_q16_unitsamtproduced_ = 2 if s7_q16_unitsamtproduced_oth_ =="None" & s7_q16_unitsamtproduced_==17
replace s7_q16_unitsamtproduced_ = 2 if s7_q16_unitsamtproduced_oth_ =="Not harvested" & s7_q16_unitsamtproduced_==17
replace s7_q16_unitsamtproduced_ = 2 if s7_q16_unitsamtproduced_oth_ =="Not yet harvested" & s7_q16_unitsamtproduced_==17
replace s7_q16_unitsamtproduced_ = 2 if s7_q16_unitsamtproduced_oth_ =="Not yet harvested /ready for harvesting" & s7_q16_unitsamtproduced_==17
replace s7_q16_unitsamtproduced_ = 2 if s7_q16_unitsamtproduced_oth_ =="Not yet harvested." & s7_q16_unitsamtproduced_==17
replace s7_q16_unitsamtproduced_ = 2 if s7_q16_unitsamtproduced_oth_ =="Not yet ready" & s7_q16_unitsamtproduced_==17
replace s7_q16_unitsamtproduced_ = 2 if s7_q16_unitsamtproduced_oth_ =="Not yet ready for harvesting" & s7_q16_unitsamtproduced_==17
replace s7_q16_unitsamtproduced_ = 2 if s7_q16_unitsamtproduced_oth_ =="Nothing" & s7_q16_unitsamtproduced_==17
replace s7_q16_unitsamtproduced_ = 2 if s7_q16_unitsamtproduced_oth_ =="Nothing harvested" & s7_q16_unitsamtproduced_==17
replace s7_q16_unitsamtproduced_ = 2 if s7_q16_unitsamtproduced_oth_ =="Nothing was harvested" & s7_q16_unitsamtproduced_==17
replace s7_q16_unitsamtproduced_ = 2 if s7_q16_unitsamtproduced_oth_ =="Planted for the first time not yet grown" & s7_q16_unitsamtproduced_==17
replace s7_q16_unitsamtproduced_ = 2 if s7_q16_unitsamtproduced_oth_ =="Sorghum plantation was destroyed and thus no harvest was brought home" & s7_q16_unitsamtproduced_==17
replace s7_q16_unitsamtproduced_ = 2 if s7_q16_unitsamtproduced_oth_ =="Still not harvested" & s7_q16_unitsamtproduced_==17
replace s7_q16_unitsamtproduced_ = 2 if s7_q16_unitsamtproduced_oth_ =="The maize was desroyed all in farm due to drought" & s7_q16_unitsamtproduced_==17
replace s7_q16_unitsamtproduced_ = 2 if s7_q16_unitsamtproduced_oth_ =="They were destroyed at the farm" & s7_q16_unitsamtproduced_==17
replace s7_q16_unitsamtproduced_ = 2 if s7_q16_unitsamtproduced_oth_ =="Waiting for harvest" & s7_q16_unitsamtproduced_==17
replace s7_q16_unitsamtproduced_ = 2 if s7_q16_unitsamtproduced_oth_ =="not yet harvested" & s7_q16_unitsamtproduced_==17
replace s7_q16_unitsamtproduced_ = 2 if s7_q16_unitsamtproduced_oth_ =="Got spoilt" & s7_q16_unitsamtproduced_==17

*units directly related to number
replace s7_q16_unitsamtproduced_ = 14 if s7_q16_unitsamtproduced_oth_ =="Fruit Number" & s7_q16_unitsamtproduced_==17
replace s7_q16_unitsamtproduced_ = 14 if s7_q16_unitsamtproduced_oth_ =="Fruits" & s7_q16_unitsamtproduced_==17
replace s7_q16_unitsamtproduced_ = 14 if s7_q16_unitsamtproduced_oth_ =="Number" & s7_q16_unitsamtproduced_==17
replace s7_q16_unitsamtproduced_ = 14 if s7_q16_unitsamtproduced_oth_ =="Numbers" & s7_q16_unitsamtproduced_==17
replace s7_q16_unitsamtproduced_ = 14 if s7_q16_unitsamtproduced_oth_ =="Pieces" & s7_q16_unitsamtproduced_==17
replace s7_q16_unitsamtproduced_ = 14 if s7_q16_unitsamtproduced_oth_ =="Number of logs/ trees" & s7_q16_unitsamtproduced_==17
replace s7_q16_unitsamtproduced_ = 14 if s7_q16_unitsamtproduced_oth_ =="Number of trees" & s7_q16_unitsamtproduced_==17
replace s7_q16_unitsamtproduced_ = 14 if s7_q16_unitsamtproduced_oth_ =="Trees" & s7_q16_unitsamtproduced_==17

*units in Tanzania shillings
//exchange rate from Tanzazia shillings (TZS) to Kenyan shillings (KES): 0.046 (in 2017)
replace s7_q16_amtproduced_ = s7_q16_amtproduced_*0.046 if s7_q16_unitsamtproduced_oth_ =="Tanzania shillings" & s7_q16_unitsamtproduced_==17
replace s7_q16_unitsamtproduced_ = 1 if s7_q16_unitsamtproduced_oth_ =="Tanzania shillings" & s7_q16_unitsamtproduced_==17

*remaining unclassified categories
tab s7_q16_unitsamtproduced_oth_ if s7_q16_unitsamtproduced_==17
//unifying names
replace s7_q16_unitsamtproduced_oth_ = "Bunch" if s7_q16_unitsamtproduced_oth_ =="Bunches" & s7_q16_unitsamtproduced_==17
replace s7_q16_unitsamtproduced_oth_ = "Crate" if s7_q16_unitsamtproduced_oth_ =="Crates" & s7_q16_unitsamtproduced_==17
tab s7_q16_unitsamtproduced_oth_ if s7_q16_unitsamtproduced_==17
tab2 s7_q16_unitsamtproduced_oth_ s7_q15_crop_ if s7_q16_unitsamtproduced_==17


***Crop sales
replace s7_q18i_unitsamtcropsold_oth_ = trim(s7_q18i_unitsamtcropsold_oth_)
tab s7_q18i_unitsamtcropsold_oth_

list s7_q18i_amtcropsold_ s7_q18i_unitsamtcropsold_oth_ if s7_q18i_unitsamtcropsold_ == 17

*units directly related to kg
replace s7_q18i_amtcropsold_ = s7_q18i_amtcropsold_*90 if s7_q18i_unitsamtcropsold_oth_ =="90kg Sack full of kales" & s7_q18i_unitsamtcropsold_==17
replace s7_q18i_amtcropsold_ = s7_q18i_amtcropsold_*90 if s7_q18i_unitsamtcropsold_oth_ =="GUNIA -90KG" & s7_q18i_unitsamtcropsold_==17
replace s7_q18i_amtcropsold_ = s7_q18i_amtcropsold_*20 if s7_q18i_unitsamtcropsold_oth_ =="GUNIA 20-KG" & s7_q18i_unitsamtcropsold_==17
replace s7_q18i_amtcropsold_ = s7_q18i_amtcropsold_*50 if s7_q18i_unitsamtcropsold_oth_ =="GUNIA-50KG" & s7_q18i_unitsamtcropsold_==17
replace s7_q18i_amtcropsold_ = s7_q18i_amtcropsold_*40 if s7_q18i_unitsamtcropsold_oth_ =="Gunia of 40kg" & s7_q18i_unitsamtcropsold_==17
replace s7_q18i_amtcropsold_ = s7_q18i_amtcropsold_*50 if s7_q18i_unitsamtcropsold_oth_ =="Gunia of 50kgs" & s7_q18i_unitsamtcropsold_==17
replace s7_q18i_amtcropsold_ = s7_q18i_amtcropsold_*50 if s7_q18i_unitsamtcropsold_oth_ =="Gunia-50kg" & s7_q18i_unitsamtcropsold_==17
replace s7_q18i_amtcropsold_ = s7_q18i_amtcropsold_*907 if s7_q18i_unitsamtcropsold_oth_ =="TONNES" & s7_q18i_unitsamtcropsold_==17
replace s7_q18i_amtcropsold_ = s7_q18i_amtcropsold_*907 if s7_q18i_unitsamtcropsold_oth_ =="Tannes" & s7_q18i_unitsamtcropsold_==17
replace s7_q18i_amtcropsold_ = s7_q18i_amtcropsold_*907 if s7_q18i_unitsamtcropsold_oth_ =="Tone" & s7_q18i_unitsamtcropsold_==17
replace s7_q18i_amtcropsold_ = s7_q18i_amtcropsold_*907 if s7_q18i_unitsamtcropsold_oth_ =="Tones" & s7_q18i_unitsamtcropsold_==17
replace s7_q18i_amtcropsold_ = s7_q18i_amtcropsold_*907 if s7_q18i_unitsamtcropsold_oth_ =="Tonnes" & s7_q18i_unitsamtcropsold_==17
replace s7_q18i_amtcropsold_ = s7_q18i_amtcropsold_*40 if s7_q18i_unitsamtcropsold_oth_ =="gunia of 40kg" & s7_q18i_unitsamtcropsold_==17
replace s7_q18i_amtcropsold_ = s7_q18i_amtcropsold_*50 if s7_q18i_unitsamtcropsold_oth_ =="gunia of 50kg" & s7_q18i_unitsamtcropsold_==17
replace s7_q18i_amtcropsold_ = s7_q18i_amtcropsold_*25 if s7_q18i_unitsamtcropsold_oth_ =="sack of 25 kg" & s7_q18i_unitsamtcropsold_==17

replace s7_q18i_unitsamtcropsold_ = 2 if s7_q18i_unitsamtcropsold_oth_ =="90kg Sack full of kales" & s7_q18i_unitsamtcropsold_==17
replace s7_q18i_unitsamtcropsold_ = 2 if s7_q18i_unitsamtcropsold_oth_ =="GUNIA -90KG" & s7_q18i_unitsamtcropsold_==17
replace s7_q18i_unitsamtcropsold_ = 2 if s7_q18i_unitsamtcropsold_oth_ =="GUNIA 20-KG" & s7_q18i_unitsamtcropsold_==17
replace s7_q18i_unitsamtcropsold_ = 2 if s7_q18i_unitsamtcropsold_oth_ =="GUNIA-50KG" & s7_q18i_unitsamtcropsold_==17
replace s7_q18i_unitsamtcropsold_ = 2 if s7_q18i_unitsamtcropsold_oth_ =="Gunia of 40kg" & s7_q18i_unitsamtcropsold_==17
replace s7_q18i_unitsamtcropsold_ = 2 if s7_q18i_unitsamtcropsold_oth_ =="Gunia of 50kgs" & s7_q18i_unitsamtcropsold_==17
replace s7_q18i_unitsamtcropsold_ = 2 if s7_q18i_unitsamtcropsold_oth_ =="Gunia-50kg" & s7_q18i_unitsamtcropsold_==17
replace s7_q18i_unitsamtcropsold_ = 2 if s7_q18i_unitsamtcropsold_oth_ =="TONNES" & s7_q18i_unitsamtcropsold_==17
replace s7_q18i_unitsamtcropsold_ = 2 if s7_q18i_unitsamtcropsold_oth_ =="Tannes" & s7_q18i_unitsamtcropsold_==17
replace s7_q18i_unitsamtcropsold_ = 2 if s7_q18i_unitsamtcropsold_oth_ =="Tone" & s7_q18i_unitsamtcropsold_==17
replace s7_q18i_unitsamtcropsold_ = 2 if s7_q18i_unitsamtcropsold_oth_ =="Tones" & s7_q18i_unitsamtcropsold_==17
replace s7_q18i_unitsamtcropsold_ = 2 if s7_q18i_unitsamtcropsold_oth_ =="Tonnes" & s7_q18i_unitsamtcropsold_==17
replace s7_q18i_unitsamtcropsold_ = 2 if s7_q18i_unitsamtcropsold_oth_ =="gunia of 40kg" & s7_q18i_unitsamtcropsold_==17
replace s7_q18i_unitsamtcropsold_ = 2 if s7_q18i_unitsamtcropsold_oth_ =="gunia of 50kg" & s7_q18i_unitsamtcropsold_==17
replace s7_q18i_unitsamtcropsold_ = 2 if s7_q18i_unitsamtcropsold_oth_ =="sack of 25 kg" & s7_q18i_unitsamtcropsold_==17

*units directly related to gorogoro
list s7_q18i_amtcropsold_ if s7_q18i_unitsamtcropsold_oth_ =="2 suck  of  40  gorogoro" & s7_q18i_unitsamtcropsold_ == 17

replace s7_q18i_amtcropsold_ = s7_q18i_amtcropsold_*40 if s7_q18i_unitsamtcropsold_oth_ =="1  full sack  of  40 gorogoro" & s7_q18i_unitsamtcropsold_==17
replace s7_q18i_amtcropsold_ = s7_q18i_amtcropsold_*40 if s7_q18i_unitsamtcropsold_oth_ =="2 suck  of  40  gorogoro" & s7_q18i_unitsamtcropsold_==17
replace s7_q18i_amtcropsold_ = s7_q18i_amtcropsold_*40 if s7_q18i_unitsamtcropsold_oth_ =="40 gorogoro sack" & s7_q18i_unitsamtcropsold_==17
replace s7_q18i_amtcropsold_ = s7_q18i_amtcropsold_*40 if s7_q18i_unitsamtcropsold_oth_ =="Sack  of  40 gorogoro" & s7_q18i_unitsamtcropsold_==17
replace s7_q18i_amtcropsold_ = s7_q18i_amtcropsold_*40 if s7_q18i_unitsamtcropsold_oth_ =="Sack of 40 goro goros." & s7_q18i_unitsamtcropsold_==17
replace s7_q18i_amtcropsold_ = s7_q18i_amtcropsold_*50 if s7_q18i_unitsamtcropsold_oth_ =="Suck  of  fifty  gorogoro" & s7_q18i_unitsamtcropsold_==17
replace s7_q18i_amtcropsold_ = s7_q18i_amtcropsold_*20 if s7_q18i_unitsamtcropsold_oth_ =="Suck if 20 gorogor" & s7_q18i_unitsamtcropsold_==17

replace s7_q18i_unitsamtcropsold_ = 4 if s7_q18i_unitsamtcropsold_oth_ =="1  full sack  of  40 gorogoro" & s7_q18i_unitsamtcropsold_==17
replace s7_q18i_unitsamtcropsold_ = 4 if s7_q18i_unitsamtcropsold_oth_ =="2 suck  of  40  gorogoro" & s7_q18i_unitsamtcropsold_==17
replace s7_q18i_unitsamtcropsold_ = 4 if s7_q18i_unitsamtcropsold_oth_ =="40 gorogoro sack" & s7_q18i_unitsamtcropsold_==17
replace s7_q18i_unitsamtcropsold_ = 4 if s7_q18i_unitsamtcropsold_oth_ =="Sack  of  40 gorogoro" & s7_q18i_unitsamtcropsold_==17
replace s7_q18i_unitsamtcropsold_ = 4 if s7_q18i_unitsamtcropsold_oth_ =="Sack of 40 goro goros." & s7_q18i_unitsamtcropsold_==17
replace s7_q18i_unitsamtcropsold_ = 4 if s7_q18i_unitsamtcropsold_oth_ =="Suck  of  fifty  gorogoro" & s7_q18i_unitsamtcropsold_==17
replace s7_q18i_unitsamtcropsold_ = 4 if s7_q18i_unitsamtcropsold_oth_ =="Suck if 20 gorogor" & s7_q18i_unitsamtcropsold_==17

*units directly related to KSh
replace s7_q18i_unitsamtcropsold_ = 1 if s7_q18i_unitsamtcropsold_oth_ =="Kenya shillings" & s7_q18i_unitsamtcropsold_==17
replace s7_q18i_unitsamtcropsold_ = 1 if s7_q18i_unitsamtcropsold_oth_ ==" Full  polythene of  (10 shillings )" & s7_q18i_unitsamtcropsold_==17
replace s7_q18i_unitsamtcropsold_ = 1 if s7_q18i_unitsamtcropsold_oth_ =="Sold to local consumers" & s7_q18i_unitsamtcropsold_==17

*units directly related to numbers
replace s7_q18i_amtcropsold_ = s7_q18i_amtcropsold_ * 10 if s7_q18i_unitsamtcropsold_oth_ =="Number of logs / trees" & s7_q18i_unitsamtcropsold_==17

replace s7_q18i_unitsamtcropsold_ = 14 if s7_q18i_unitsamtcropsold_oth_ =="Trees" & s7_q18i_unitsamtcropsold_==17
replace s7_q18i_unitsamtcropsold_ = 14 if s7_q18i_unitsamtcropsold_oth_ =="Number of logs / trees" & s7_q18i_unitsamtcropsold_==17

*remaining unclassified categories
tab s7_q18i_unitsamtcropsold_oth_ if s7_q18i_unitsamtcropsold_==17
list s7_q15_crop_ s7_q18i_unitsamtcropsold_oth_ if s7_q18i_unitsamtcropsold_==17
tab2 s7_q15_crop_ s7_q18i_unitsamtcropsold_oth_ if s7_q18i_unitsamtcropsold_==17
//unifying names
replace s7_q18i_unitsamtcropsold_oth_ = "Bunch" if s7_q18i_unitsamtcropsold_oth_ =="Banch" & s7_q18i_unitsamtcropsold_==17
replace s7_q18i_unitsamtcropsold_oth_ = "Bunch" if s7_q18i_unitsamtcropsold_oth_ =="Bunches" & s7_q18i_unitsamtcropsold_==17
replace s7_q18i_unitsamtcropsold_oth_ = "Crate" if s7_q18i_unitsamtcropsold_oth_ =="Crates" & s7_q18i_unitsamtcropsold_==17
replace s7_q18i_unitsamtcropsold_oth_ = "Crate" if s7_q18i_unitsamtcropsold_oth_ =="Create" & s7_q18i_unitsamtcropsold_==17
replace s7_q18i_unitsamtcropsold_oth_ = "Crate" if s7_q18i_unitsamtcropsold_oth_ =="Creates" & s7_q18i_unitsamtcropsold_==17
list s7_q18i_amtcropsold_ if s7_q18i_unitsamtcropsold_oth_ =="4 lorries" & s7_q18i_unitsamtcropsold_==17
replace s7_q18i_unitsamtcropsold_oth_ = "Lorry" if s7_q18i_unitsamtcropsold_oth_ =="4 lorries" & s7_q18i_unitsamtcropsold_==17
replace s7_q18i_unitsamtcropsold_oth_ = "Lorry" if s7_q18i_unitsamtcropsold_oth_ =="Full  lorry" & s7_q18i_unitsamtcropsold_==17
replace s7_q18i_unitsamtcropsold_oth_ = "Lorry" if s7_q18i_unitsamtcropsold_oth_ =="Lorries" & s7_q18i_unitsamtcropsold_==17
replace s7_q18i_unitsamtcropsold_oth_ = "Lorry" if s7_q18i_unitsamtcropsold_oth_ =="One lorry" & s7_q18i_unitsamtcropsold_==17
replace s7_q18i_unitsamtcropsold_oth_ = "Sack" if s7_q18i_unitsamtcropsold_oth_ =="SACK" & s7_q18i_unitsamtcropsold_==17
replace s7_q18i_unitsamtcropsold_oth_ = "Sack" if s7_q18i_unitsamtcropsold_oth_ =="SUCK" & s7_q18i_unitsamtcropsold_==17
replace s7_q18i_unitsamtcropsold_oth_ = "Sack" if s7_q18i_unitsamtcropsold_oth_ =="Sacks" & s7_q18i_unitsamtcropsold_==17
replace s7_q18i_unitsamtcropsold_oth_ = "Wheelbarrow" if s7_q18i_unitsamtcropsold_oth_ =="Wheelbarrows" & s7_q18i_unitsamtcropsold_==17
tab s7_q18i_unitsamtcropsold_oth_ if s7_q18i_unitsamtcropsold_==17
tab2 s7_q18i_unitsamtcropsold_oth_ s7_q15_crop_ if s7_q18i_unitsamtcropsold_==17


* Generate as much stuff in kilos and liters as possible
gen produce_amt = .
gen produce_unit = .
gen sell_amt = .
gen sell_unit = .

* Replace things measured in weight
replace produce_amt = s7_q16_amtproduced_/1000 if s7_q16_unitsamtproduced_==3 // converting grams to KG
replace produce_amt = s7_q16_amtproduced_*2 if s7_q16_unitsamtproduced_==4 // converting gorogoro (2KG) to KGs
replace produce_amt = s7_q16_amtproduced_*20 if s7_q16_unitsamtproduced_==5 // converting debe (20KG) to KG
replace produce_amt = s7_q16_amtproduced_*90 if s7_q16_unitsamtproduced_==6 // converting gunia (90kg) to KG
replace produce_amt = s7_q16_amtproduced_*1 if s7_q16_unitsamtproduced_==11
replace produce_amt = s7_q16_amtproduced_*2 if s7_q16_unitsamtproduced_==12
replace produce_unit = 2 if inlist(s7_q16_unitsamtproduced_,3,4,5,6,11,12) // replacing unit as KG for changes

* replace things measured in volume
replace produce_amt = s7_q16_amtproduced_*0.3 if s7_q16_unitsamtproduced_==8 // 300ml to liter
//In the GE Endline survey, unit = 8 is 300ml (and not 350ml). Is this correct or it is a typo?
replace produce_amt = s7_q16_amtproduced_*0.5 if s7_q16_unitsamtproduced_==9 // half liter to liter
replace produce_amt = s7_q16_amtproduced_*0.7 if s7_q16_unitsamtproduced_==10 // 700 ml to liter
replace produce_amt = s7_q16_amtproduced_*20 if s7_q16_unitsamtproduced_==13 // jerry can to liter
replace produce_unit = 7 if inlist(s7_q16_unitsamtproduced_,8,9,10,13) // replacing unit as liter

replace produce_amt = s7_q16_amtproduced_ if missing(produce_amt) // filling in for those not converted
replace produce_unit = s7_q16_unitsamtproduced_ if missing(produce_unit)

* Replace things measured in weight
replace sell_amt = s7_q18i_amtcropsold_/1000 if s7_q18i_unitsamtcropsold_==3
replace sell_amt = s7_q18i_amtcropsold_*2 if s7_q18i_unitsamtcropsold_==4
replace sell_amt = s7_q18i_amtcropsold_*20 if s7_q18i_unitsamtcropsold_==5
replace sell_amt = s7_q18i_amtcropsold_*90 if s7_q18i_unitsamtcropsold_==6
replace sell_amt = s7_q18i_amtcropsold_*1 if s7_q18i_unitsamtcropsold_==11
replace sell_amt = s7_q18i_amtcropsold_*2 if s7_q18i_unitsamtcropsold_==12
replace sell_unit = 2 if inlist(s7_q18i_unitsamtcropsold_,3,4,5,6,11,12)

* replace things measured in volume
replace sell_amt = s7_q18i_amtcropsold_*0.3 if s7_q18i_unitsamtcropsold_==8
//In the GE Endline survey, unit = 8 is 300ml (and not 350ml). Is this correct or it is a typo?
replace sell_amt = s7_q18i_amtcropsold_*0.5 if s7_q18i_unitsamtcropsold_==9
replace sell_amt = s7_q18i_amtcropsold_*0.7 if s7_q18i_unitsamtcropsold_==10
replace sell_amt = s7_q18i_amtcropsold_*20 if s7_q18i_unitsamtcropsold_==13
replace sell_unit = 7 if inlist(s7_q18i_unitsamtcropsold_,8,9,10,13)

replace sell_amt = s7_q18i_amtcropsold_ if missing(sell_amt)
replace sell_unit = s7_q18i_unitsamtcropsold_ if missing(sell_unit)

//replace sell_amt if the hh did not sell anything
tab sell_amt if s7_q17_soldcrop_ == 0, m
replace sell_amt = 0 if s7_q17_soldcrop_ == 0


* Merge with the price data
*Rename relevant variables according to price dataset
rename survey_mth month
rename s7_q15_crop_ product
rename s1_q2_subcounty subcounty
replace product = "Tomatoes" if product == "Tomato"
replace product = "Onions" if product == "Onion"
replace product = "Kales" if product == "Kale"
//replace product = "Sugar" if product == "Sugar cane" - no longer doing this, use local estimated prices where possible - I don' tthink sugar and sugarcane are comparable enough to justify

//We have "Banana/plaintain" in the hh data, but "Banana-sweet" and "Plaintains" in the mkt price data. combining into a single product in the market data


//Merge with market prices data, using the average price in 2016
project, original("$dr/GE_MktPrices_AgProduction_2017-10-10_avgsubcounty_2016.dta") preserve
merge m:1 product subcounty using "$dr/GE_MktPrices_AgProduction_2017-10-10_avgsubcounty_2016.dta", keep(master match)
tab product if _merge == 1
tab month if _merge == 1
rename avg_med_price_2016 avg_med_price



/*
//Merge with market prices data, using the average monthly price
merge m:1 month product subcounty using "C:\Users\priscila\Documents\RA_GE\HH_data\cleaning\data\GE_MktPrices_AgProduction_2017-09-14_avgsubcounty.dta", keep(master match)
tab product if _merge == 1
tab month if _merge == 1
//the mkt price goes only until 2017m1
*tab if date is before 2017m1
tab product if _merge == 1 & month < 685
*tab if date is after 2017m1
tab product if _merge == 1 & month >= 685
drop _merge


**Impute the last available price (2017m1) if date is after 2017m1
merge m:1 product subcounty using "C:\Users\priscila\Documents\RA_GE\HH_data\cleaning\data\GE_MktPrices_AgProduction_2017-09-14_avgsubcounty_2017m1.dta", keep(master match)
tab product if _merge == 1
tab month if _merge == 1
replace unit = unit2 if month >= 685
replace avg_med_price = avg_med_price_2017m1 if month >= 685
tab product if missing(avg_med_price)
*/


** Work with the units of measurement for each crop

*conversion will be used for production and conversion2 for sales
gen conversion=.
label var conversion "Conversion rate between average price and report (production)"
gen conversion2=.
label var conversion2 "Conversion rate between average price and report (sales)"

* Maize, Millet, Sorghum, Cassava, Groundnuts, Beans and Green Grams are measured in ksh per 2 kilos
** NL: Modified to use crop string
tab produce_unit if product=="Maize"
tab s7_q16_unitsamtproduced_oth_ if product=="Maize" & produce_unit == 17
tab produce_unit if product=="Millet"
tab s7_q16_unitsamtproduced_oth_ if product=="Millet" & produce_unit == 17
tab produce_unit if product=="Sorghum"
tab s7_q16_unitsamtproduced_oth_ if product=="Sorghum" & produce_unit == 17
tab produce_unit if product=="Cassava"
tab s7_q16_unitsamtproduced_oth_ if product=="Cassava" & produce_unit == 17
tab produce_unit if product=="Beans"
tab s7_q16_unitsamtproduced_oth_ if product=="Beans" & produce_unit == 17

tab sell_unit if product=="Maize"
tab s7_q18i_unitsamtcropsold_oth_ if product=="Maize" & sell_unit == 17
tab sell_unit if product=="Millet"
tab s7_q18i_unitsamtcropsold_oth_ if product=="Millet" & sell_unit == 17
tab sell_unit if product=="Sorghum"
tab s7_q18i_unitsamtcropsold_oth_ if product=="Sorghum" & sell_unit == 17
tab sell_unit if product=="Cassava"
tab s7_q18i_unitsamtcropsold_oth_ if product=="Cassava" & sell_unit == 17
tab sell_unit if product=="Beans"
tab s7_q18i_unitsamtcropsold_oth_ if product=="Beans" & sell_unit == 17

replace conversion=2 if (product=="Maize" | product=="Sorghum" | product=="Millet" | product=="Cassava" | product=="Groundnuts" | product=="Beans" | product=="Green grams") & produce_unit==2	// If unit reported is kilo or "Kaulu-1KG", divide by 2
replace conversion2=2 if (product=="Maize" | product=="Sorghum" | product=="Millet" | product=="Cassava" | product=="Groundnuts" | product=="Beans" | product=="Green grams") & sell_unit==2	// If unit reported is kilo or "Kaulu-1KG", divide by 2
* If measured in liters:
replace conversion=2.63 if product=="Maize" & produce_unit==7
replace conversion=2.56 if product=="Millet" & produce_unit==7
replace conversion=2.47 if product=="Sorghum" & produce_unit==7
replace conversion=2.30 if product=="Cassava" & produce_unit==7
replace conversion=3.45 if product=="Beans" & produce_unit==7
replace conversion2=2.63 if product=="Maize" & sell_unit==7
replace conversion2=2.56 if product=="Millet" & sell_unit==7
replace conversion2=2.47 if product=="Sorghum" & sell_unit==7
replace conversion2=2.30 if product=="Cassava" & sell_unit==7
replace conversion2=3.45 if product=="Beans" & sell_unit==7

//Millet: grannery
//Maize: number
//Cassava: wheelbarrow, bundle, pieces, sacks
//Beans: number, Pack/Packet


********************************************************************************
* dropping sugar from this
* Rice and sugar are measured in 1 kilo
tab produce_unit if product=="Rice"
tab s7_q16_unitsamtproduced_oth_ if product=="Rice" & produce_unit == 17

tab sell_unit if product=="Rice"
tab s7_q18i_unitsamtcropsold_oth_ if product=="Rice" & sell_unit == 17

replace conversion=1 if product=="Rice" & produce_unit==2 						// If unit reported is kilo or "Kaulu-1KG", divide by 1
replace conversion2=1 if product=="Rice" & sell_unit==2 					// If unit reported is kilo or "Kaulu-1KG", divide by 1

//Sugar: number, lorry, bundle

********************************************************************************

/* Cowpeas are measured by "small bunch". It seems like a cup (almost 250ml) weigh 171 grams. To make things easier I will take just 150 grams, which seems a small enough quantity
We only have cowpea leaves in the mkt prices dataset

replace conversion=0.15 if product=="Cowpeas" & produce_unit==2

*/
********************************************************************************

* Sweet potatoes are measured by six. A google search and measurement at home indicate that is approximately 1Kg, so I will take 1Kg as the unit of measurement in the market
tab produce_unit if product=="Sweet potato"
tab s7_q16_unitsamtproduced_oth_ if product=="Sweet potato" & produce_unit == 17
tab sell_unit if product=="Sweet potato"
tab s7_q18i_unitsamtcropsold_oth_ if product=="Sweet potato" & sell_unit == 17

replace conversion=1 if product=="Sweet potato" & produce_unit==2																																		// If unit reported is kilo or "Kaulu-1KG", divide by 1
replace conversion=1.08 if product=="Sweet potato" & produce_unit==7																																							// 1 liter of sweet potatoes is 1.08 Kgs, so if unit reported is liter, divide by 1.08
replace conversion=6 if product=="Sweet potato" & produce_unit==14																																		// If unit reported is number, divide by 6
replace conversion2=1 if product=="Sweet potato" & sell_unit==2																																		// If unit reported is kilo or "Kaulu-1KG", divide by 1
replace conversion2=1.08 if product=="Sweet potato" & sell_unit==7																																							// 1 liter of sweet potatoes is 1.08 Kgs, so if unit reported is liter, divide by 1.08
replace conversion2=6 if product=="Sweet potato" & sell_unit==14																																		// If unit reported is number, divide by 6
//Sweet potato: pack, bundle, wheelbarrow

********************************************************************************

* Potatoes are measured by five. A google search indicates that is approximately 0.75Kg, so I will take that as the unit of measurement in the market
tab produce_unit if product=="Irish potato"
tab s7_q16_unitsamtproduced_oth_ if product=="Irish potato" & produce_unit == 17
tab sell_unit if product=="Irish potato"
tab s7_q18i_unitsamtcropsold_oth_ if product=="Irish potato" & sell_unit == 17

replace conversion=0.75 if product=="Irish potato" & produce_unit==2																																	// If unit reported is kilo or "Kaulu-1KG", divide by 0.75
replace conversion=0.97 if product=="Irish potato" & produce_unit==7																																									// 1 liter of potatoes is 0.77 Kgs, so if unit reported is liter, divide by 0.97 (aprox)

********************************************************************************

* Tomatoes are measured by four. A google search indicates that is approximately 0.60Kg, so I will take that as the unit of measurement in the market
tab produce_unit if product=="Tomatoes"
tab s7_q16_unitsamtproduced_oth_ if product=="Tomatoes" & produce_unit == 17
tab sell_unit if product=="Tomatoes"
tab s7_q18i_unitsamtcropsold_oth_ if product=="Tomatoes" & sell_unit == 17

replace conversion=0.60 if product=="Tomatoes" & produce_unit==2																																	// If unit reported is kilo or "Kaulu-1KG", divide by 0.60
replace conversion=15/19 if product=="Tomatoes" & produce_unit==7																																						// 1 liter of tomatoes is 0.750 Kgs, so if unit reported is liter, divide by 15/19
replace conversion=4 if product=="Tomatoes" & produce_unit==14																																	// If unit reported is kilo or "Kaulu-1KG", divide by 0.60
replace conversion2=0.60 if product=="Tomatoes" & sell_unit==2																																	// If unit reported is kilo or "Kaulu-1KG", divide by 0.60
replace conversion2=15/19 if product=="Tomatoes" & sell_unit==7																																						// 1 liter of tomatoes is 0.750 Kgs, so if unit reported is liter, divide by 15/19
replace conversion2=4 if product=="Tomatoes" & sell_unit==14																																	// If unit reported is kilo or "Kaulu-1KG", divide by 0.60
//Tomatoes: crate, crate for bread, sanduku, pack, bundle

********************************************************************************

* Onions are measured by four. A google search indicates that is approximately 0.90Kg, so I will take that as the unit of measurement in the market
tab produce_unit if product=="Onions"
tab s7_q16_unitsamtproduced_oth_ if product=="Onions" & produce_unit == 17
tab sell_unit if product=="Onions"
tab s7_q18i_unitsamtcropsold_oth_ if product=="Onions" & sell_unit == 17

replace conversion=0.90 if product=="Onions" & produce_unit==2																																	// If unit reported is kilo or "Kaulu-1KG", divide by 0.90
replace conversion2=0.90 if product=="Onions" & sell_unit==2																																	// If unit reported is kilo or "Kaulu-1KG", divide by 0.90
//Onions: bundle

********************************************************************************

* Cabbage is measured by "head". A google search indicates that is approximately 1Kg, so I will take that as the unit of measurement in the market
tab produce_unit if product=="Cabbage"
tab s7_q16_unitsamtproduced_oth_ if product=="Cabbage" & produce_unit == 17
tab sell_unit if product=="Cabbage"
tab s7_q18i_unitsamtcropsold_oth_ if product=="Cabbage" & sell_unit == 17

replace conversion=1 if product=="Cabbage" & produce_unit==2																																							// If unit reported is "Gunia-90KG" divide by 1/90
replace conversion2=1 if product=="Cabbage" & sell_unit==2																																							// If unit reported is "Gunia-90KG" divide by 1/90

********************************************************************************

* Kale is priced per "bag", but the most commonly reported measure by individuals is "Gunia-90KG", so I cannot convert that
* Lets say each bag of kale is 500g
tab produce_unit if product=="Kales"
tab s7_q16_unitsamtproduced_oth_ if product=="Kales" & produce_unit == 17
tab sell_unit if product=="Kales"
tab s7_q18i_unitsamtcropsold_oth_ if product=="Kales" & sell_unit == 17

replace conversion=1/2 if product =="Kales" & produce_unit==2
replace conversion2=1/2 if product =="Kales" & sell_unit==2
//Kales: liter, number, pack, bundle, basket, crate

********************************************************************************

* Papaya is priced per unit
tab produce_unit if product=="Papaya"
tab s7_q16_unitsamtproduced_oth_ if product=="Papaya" & produce_unit == 17
tab sell_unit if product=="Papaya"
tab s7_q18i_unitsamtcropsold_oth_ if product=="Papaya" & sell_unit == 17

replace conversion=1 if product=="Papaya" & produce_unit==14
replace conversion2=1 if product=="Papaya" & sell_unit==14
//Papaya: kilo, liter

********************************************************************************

* Plantains and bananas are together in the individual database, but separate in the prices dataset. Plantains are measured by four (approx. 1Kg), and bananas are measured by bunch (unknown weight). So, I will take the plantains weight as the unit of measure in the market
//check this later
tab produce_unit if product=="Banana/plantain"
tab s7_q16_unitsamtproduced_oth_ if product=="Banana/plantain" & produce_unit == 17
tab sell_unit if product=="Banana/plantain"
tab s7_q18i_unitsamtcropsold_oth_ if product=="Banana/plantain" & sell_unit == 17

replace conversion=1 if product=="Banana/plantain" & produce_unit==2	| produce_unit==16

********************************************************************************

* Pineapple is measured by unit
tab produce_unit if product=="Pineapple"
tab s7_q16_unitsamtproduced_oth_ if product=="Pineapple" & produce_unit == 17
tab sell_unit if product=="Pineapple"
tab s7_q18i_unitsamtcropsold_oth_ if product=="Pineapple" & sell_unit == 17

replace conversion=1 if product=="Pineapple" & produce_unit==14

********************************************************************************

* Avocado is priced per unit, but there are only two observations in the individual database, and none of them report the unit of measure.
tab produce_unit if product=="Avocado"
tab s7_q16_unitsamtproduced_oth_ if product=="Avocado" & produce_unit == 17
tab sell_unit if product=="Avocado"
tab s7_q18i_unitsamtcropsold_oth_ if product=="Avocado" & sell_unit == 17

replace conversion=1 if product=="Avocado" & produce_unit==14
replace conversion2=1 if product=="Avocado" & sell_unit==14
//Avocado: kilo, bundle, crate

********************************************************************************

* Mango is priced per ten units. A google search indicates that is approximately 2Kg., so I will take that as the unit of measurement in the market.
tab produce_unit if product=="Mango"
tab s7_q16_unitsamtproduced_oth_ if product=="Mango" & produce_unit == 17
tab sell_unit if product=="Mango"
tab s7_q18i_unitsamtcropsold_oth_ if product=="Mango" & sell_unit == 17

replace conversion=2 if product=="Mango" & produce_unit==2																																					// If unit reported is kilo or "Kaulu-1KG", divide by 2
replace conversion=10 if product=="Mango" & produce_unit==14																																					// If unit reported is kilo or "Kaulu-1KG", divide by 2
replace conversion2=2 if product=="Mango" & sell_unit==2																																					// If unit reported is kilo or "Kaulu-1KG", divide by 2
replace conversion2=10 if product=="Mango" & sell_unit==14																																					// If unit reported is kilo or "Kaulu-1KG", divide by 2
//Mango: bundle, sack

********************************************************************************

* Green grams is priced by 2kg
tab produce_unit if product=="Green grams"
tab s7_q16_unitsamtproduced_oth_ if product=="Green grams" & produce_unit == 17
tab sell_unit if product=="Green grams"
tab s7_q18i_unitsamtcropsold_oth_ if product=="Green grams" & sell_unit == 17

replace conversion=2 if product=="Green grams" & produce_unit==2																																					// If unit reported is kilo or "Kaulu-1KG", divide by 2
replace conversion2=2 if product=="Green grams" & sell_unit==2																																					// If unit reported is kilo or "Kaulu-1KG", divide by 2

********************************************************************************

* Groundnuts is priced by 2kg
tab produce_unit if product=="Groundnuts"
tab s7_q16_unitsamtproduced_oth_ if product=="Groundnuts" & produce_unit == 17
tab sell_unit if product=="Groundnuts"
tab s7_q18i_unitsamtcropsold_oth_ if product=="Groundnuts" & sell_unit == 17

replace conversion=2 if product=="Groundnuts" & produce_unit==2																																					// If unit reported is kilo or "Kaulu-1KG", divide by 2
replace conversion2=2 if product=="Groundnuts" & sell_unit==2																																					// If unit reported is kilo or "Kaulu-1KG", divide by 2
//Groundnuts: basins

********************************************************************************

* We don't have soy beans in the mkt prices dataset

********************************************************************************



* Other cleaning
* Exclude if sold is measured in shillings and doesn't correspond to revenue
//I don't thing we should do this, as most of the mismatch (839 out of 840) is due to missing values for s7_q18ii_valuecropsold_
tab sell_amt if sell_amt != s7_q18ii_valuecropsold_ & sell_unit==1
tab sell_amt if sell_amt != s7_q18ii_valuecropsold_ & sell_unit==1 & missing(s7_q18ii_valuecropsold_)
tab1 sell_amt s7_q18ii_valuecropsold_ if sell_amt != s7_q18ii_valuecropsold_ & sell_unit==1 & ~missing(s7_q18ii_valuecropsold_)

//I suggest that we drop only if there is mismatch and both variables are non-missing:
replace sell_amt = . if sell_amt != s7_q18ii_valuecropsold_ & sell_unit==1 & ~missing(s7_q18ii_valuecropsold_)
replace s7_q18ii_valuecropsold_ = . if sell_amt != s7_q18ii_valuecropsold_ & sell_unit==1 & ~missing(sell_amt)

* Drop if quantity sold is greater than quantity produced
tab s7_q18i_amtcropsold_ if s7_q18i_amtcropsold_ > s7_q16_amtproduced_ & !missing(s7_q18i_amtcropsold_)
tab1 s7_q18i_amtcropsold_ s7_q16_amtproduced_ if s7_q18i_amtcropsold_ > s7_q16_amtproduced_ & ~missing(s7_q18i_amtcropsold_) & ~missing(s7_q16_amtproduced_) & s7_q16_unitsamtproduced_ == s7_q18i_unitsamtcropsold_
//List if the units for sales and products are the same
list s7_q18i_amtcropsold_ s7_q16_amtproduced_ produce_unit sell_unit if s7_q18i_amtcropsold_ > s7_q16_amtproduced_ & ~missing(s7_q18i_amtcropsold_) & ~missing(s7_q16_amtproduced_) & s7_q16_unitsamtproduced_ == s7_q18i_unitsamtcropsold_
//List if the units for sales and products are different
list s7_q18i_amtcropsold_ s7_q16_amtproduced_ produce_unit sell_unit if s7_q18i_amtcropsold_ > s7_q16_amtproduced_ & ~missing(s7_q18i_amtcropsold_) & ~missing(s7_q16_amtproduced_) & s7_q16_unitsamtproduced_ != s7_q18i_unitsamtcropsold_
//List if production is missing, but sales is not
list s7_q18i_amtcropsold_ s7_q16_amtproduced_ produce_unit sell_unit if s7_q18i_amtcropsold_ > s7_q16_amtproduced_ & ~missing(s7_q18i_amtcropsold_) & missing(s7_q16_amtproduced_)

*I guess we could be more careful here and drop only if there is a mismatch in the amount and the units are the same
*drop if s7_q18i_amtcropsold_ > s7_q16_amtproduced_ & !missing(s7_q18i_amtcropsold_)
drop if s7_q18i_amtcropsold_ > s7_q16_amtproduced_ & ~missing(s7_q18i_amtcropsold_) & ~missing(s7_q16_amtproduced_) & s7_q16_unitsamtproduced_ == s7_q18i_unitsamtcropsold_

*tab R3_s9_2_1selfemp if R3_s9_1_18iirevenue >= 40000 & !missing(R3_s9_1_18iirevenue) // given tab, looks likely that this is a coding mistake
* these guys will all be in self employment anyway
//drop if R3_s9_1_18iirevenue_ >= 40000 & !missing(R3_s9_1_18iirevenue_)

* Drop if missing production units
tab produce_unit, m
tab sell_unit, m
tab sell_unit if ~missing(sell_amt), m
drop if produce_unit > 17

tab conversion if ~missing(produce_unit) & ~missing(produce_amt) & produce_unit != 1, m
tab conversion2 if ~missing(sell_unit) & ~missing(sell_amt) & sell_unit != 1, m

********************************************************************************
summ produce_amt if produce_unit == 1

** Now that the conversion factors are created, I can calculate the production price

gen revenue=(produce_amt/conversion)*avg_med_price

* If the unit of measurement reported is KSh, copy that value into the revenue

replace revenue=produce_amt if produce_unit==1

** For items that are not in the price survey, back out the price using revenue obtained over quantities sold
  gen temp = s7_q18ii_valuecropsold_ / sell_amt

	* clean these guys
	* Drop people who report different amount of units and revenue when reporting units in KSh
	replace temp = . if temp != 1 & s7_q16_unitsamtproduced_==1
	replace temp = . if sell_unit != produce_unit

	* Mean and median price within subcounty (for consistency with subcounty averages for price data), production unit
	egen price_imp_mean = mean(temp), by(subcounty product produce_unit)
	egen price_imp_med = median(temp), by(subcounty product produce_unit)
	drop temp

    /* MW note: I think this is a nice touch, but less consistent with current subcounty-level approach. going for consistency now. How many cases does this apply to?
	* If I report selling something, use own implied price price
	replace revenue = s7_q18ii_valuecropsold_ / s7_q18i_amtcropsold_ * s7_q16_amtproduced_ if s7_q16_unitsamtproduced_ == s7_q18i_unitsamtcropsold_ & s7_q16_unitsamtproduced_ > 1 & missing(revenue) & product != "Other"
    */
    count if s7_q16_unitsamtproduced_ == s7_q18i_unitsamtcropsold_ & s7_q16_unitsamtproduced_ > 1 & missing(revenue) & product != "Other" & ~mi(s7_q18ii_valuecropsold_) & ~mi(s7_q18i_amtcropsold_) & ~mi(s7_q16_amtproduced_)
    count if mi(revenue) & ~mi(produce_amt) // how we'll replace this later

	* Otherwise, use the implied median price from the people who did actually sell
	replace revenue = price_imp_med * produce_amt if missing(revenue) & product != "Other"


sum revenue,d
tab product if missing(revenue)
tab2 produce_unit product if missing(revenue)

/* I've replaced this with my own code

* Carrot: only one observation, so take that as revenue

replace revenue=R3_s9_1_18iirevenue_ if R3_s9_1_4crop1_==19

* Soya beans: Only 17 observations filled, all measures of weight. Put all in kilogram

replace R3_s9_1_18iphysamt_=R3_s9_1_18iphysamt_*2 if R3_s9_1_4crop1_==20 & R3_s9_1_18iphysunit_==4
replace R3_s9_1_18iphysamt_=R3_s9_1_18iphysamt_*90 if R3_s9_1_4crop1_==20 & R3_s9_1_18iphysunit_==6

replace R3_s9_1_18iirevenue_=R3_s9_1_18iirevenue_/R3_s9_1_18iphysamt_ if R3_s9_1_4crop1_==20 & (R3_s9_1_18iphysunit_==2 | R3_s9_1_18iphysunit_==4 | R3_s9_1_18iphysunit_==6)
replace R3_s9_1_18iirevenue_=. if R3_s9_1_18iirevenue_>=99999 & R3_s9_1_4crop1_==20

egen price_soybean=mean(R3_s9_1_18iirevenue_) if R3_s9_1_4crop1_==20 & (R3_s9_1_18iphysunit_==2 | R3_s9_1_18iphysunit_==4 | R3_s9_1_18iphysunit_==6)
replace revenue=R3_s9_1_18iphysamt_*price_soybean if R3_s9_1_4crop1_==20 & (R3_s9_1_18iphysunit_==2 | R3_s9_1_18iphysunit_==4 | R3_s9_1_18iphysunit_==6)

drop price_soybean

* Tobacco: Only two observations filled. One is in "other" measure, but the other is in kilogram, so just put revenue for that observation

replace revenue=R3_s9_1_18iirevenue_ if R3_s9_1_4crop1_==23 & R3_s9_1_18iphysunit_==2

* Cotton: Only two observations, measured in the same unit, so take the average price and calculate the revenue

replace R3_s9_1_18iirevenue_=R3_s9_1_18iirevenue_/R3_s9_1_18iphysamt_ if R3_s9_1_4crop1_==25 & (R3_s9_1_18iphysunit_==2 | R3_s9_1_18iphysunit_==4 | R3_s9_1_18iphysunit_==6)
egen price_cotton=mean(R3_s9_1_18iirevenue_) if R3_s9_1_4crop1_==25 & (R3_s9_1_18iphysunit_==2 | R3_s9_1_18iphysunit_==4 | R3_s9_1_18iphysunit_==6)
replace revenue=R3_s9_1_18iphysamt_*price_cotton if R3_s9_1_4crop1_==25 & (R3_s9_1_18iphysunit_==2 | R3_s9_1_18iphysunit_==4 | R3_s9_1_18iphysunit_==6)

drop price_cotton

*/

********************************************************************************


** Now that the conversion factors are created, I can calculate the sales price

gen sales=(sell_amt/conversion2)*avg_med_price

* If the unit of measurement reported is KSh, copy that value into the revenue

replace sales=sell_amt if sell_unit==1

** For items that are not in the price survey, back out the price using revenue obtained over quantities sold
	* Use the implied median price from the people who did actually sell
	replace sales = price_imp_med * sell_amt if missing(sales) & product != "Other"

replace sales=0 if sell_amt == 0

sum sales, d
tab product if missing(sales)
tab2 sell_unit product if missing(sales)




***TABLES
tab2 s7_q16_unitsamtproduced_oth_ product if s7_q16_unitsamtproduced_==17
tab2 s7_q18i_unitsamtcropsold_oth_ product if s7_q18i_unitsamtcropsold_==17
tab2 sell_unit product if missing(sales)
tab2 produce_unit product if missing(revenue)


** dropping as outliers anything with over KSH 500,000 in revenue - should be very few.
replace revenue = . if revenue > 500000
replace sales = . if sales > 500000

** saving long version **
compress
notes: Dataset created at TS
save "$da/GE_HH-Endline_agproduction_long.dta", replace


* Keep only s1_hhid_key, crop, time, sales and revenue to reshape the panel

keep s1_hhid_key crop_num product today revenue sales
rename product s7_q15_crop_
replace s7_q15_crop_ = "Tomato" if s7_q15_crop_ == "Tomatoes"
replace s7_q15_crop_ = "Onion" if s7_q15_crop_ == "Onions"
replace s7_q15_crop_ = "Kale" if s7_q15_crop_ == "Kales"
//replace s7_q15_crop_ = "Sugar cane" if s7_q15_crop_ == "Sugar"

* Added by NL for comparison
/*
rename crop_num cropnum
keep pupid cropnum revenue
save "$dir/tempforcomp.dta", replace
*/

rename revenue crop_revenue_
rename sales crop_sales_
reshape wide s7_q15_crop_ crop_revenue_ crop_sales_, i(s1_hhid_key) j(crop_num)

order s1_hhid_key today

forvalues i=1/5{
	la var crop_revenue_`i' "Revenue from crop `i'"
	la var crop_sales_`i' "Sales from crop `i'"
}

** saving wide version **
compress

save "$da/intermediate/GE_HH-EL_agproduction_wide.dta", replace
project, creates("$da/intermediate/GE_HH-EL_agproduction_wide.dta")
