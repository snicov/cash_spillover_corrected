/*
 * Filename: build_ge_hh-welfare_indivoutcomes.do
 * Description: This do file creates individual-level outcomes from household survey data. Note that care needs to be taken when looking
 * at individual subscripts across different sections, as
 * it may not always be same person. Need to confirm roster ID for each section. (It may be good to try to re-construct this in a different way, so that we have a full dataset for each household roster member)
 *
 *
 */

** still need to bring in FR to this **

/* Preliminaries */
clear
clear matrix
clear mata
cap log close

log using "$dl/build_ge_hh-welfare_indivoutcomes_`c(current_date)'.log", replace text

/***************************************/
/*  INDIVIDUAL-LEVEL DEMOGRAPHICS      */
/***************************************/
project, do("$do/construct/hh-survey-EL/201_ge_indiv_demog_EL.do")



/***************************************/
/*  INDIVIDUAL-LEVEL wage and profit earnings      */
/***************************************/
project, do("$do/construct/hh-survey-EL/202_ge_indiv_wageprofits_EL.do")
