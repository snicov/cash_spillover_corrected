/*
 * Filename: 0_build_hh-impacts_BL_analysis.do
 * Description: This do file creates an analysis dataset of household
 *   baseline data, in line with pre-specified outcomes in the GE HH Welfare PAP. This differs from the 0_build_hhbaseline_analysis.do file in that it focuses only on creating outcomes included as part of the PAP, and only on households surveyed at endline, rather than overall. The primary goal is to create outcomes that can be used in balance tests and ANCOVA specifications, as well as
 *   control variables for use in heterogeneity. *
 * Inputs:
 *   - clean hh baseline survey data (note: still need to finalize cleaning)
 *   - treatment status dataset
 *   - tracking and attrition dataset (listing of households surveyed at endline)
 *
 *
 *
 * Author: Michael Walker
 *
 * Date: 19 Sep 2018: adapting from 0_build_hhbaseline_analysis.do
 * 27 May 2019 -- trying to get new version up and running with better version control
 *
 */

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


project, original("$do/programs/run_ge_build_programs.do")
include "$do/programs/run_ge_build_programs.do"


*** Setting up analysis dataset from clean data ***
project, do("$do/construct/hh-survey-BL/0a_ge_hhb_setup.do")

/* Variable construction is divided into a number of do files.
Read-me and beginning of each do file outline what is contained in each, though titles try to be self-explanatory.  */

* FR age, gender, marital status, years of education, etc.
project, do("$do/construct/hh-survey-BL/01_ge_hhb_vars_frbasics.do")

* HH roster variables: household size, number of children, household-level demographics
project, do("$do/construct/hh-survey-BL/02_ge_hhb_vars_hhroster.do")

* assets, income, hours worked - most of sections 6-9, financial assets from s10
project, do("$do/construct/hh-survey-BL/03_ge_hhb_vars_assets_BL.do")

/* come back to this part
** estimating ag production **
project, do("$do/construct/hh-survey-BL/estimating_baseline_agprofits_2017-10-26.do") // figure out when we use this -- may not always want to include
*/


** income and revenue **
project, do("$do/construct/hh-survey-BL/04_ge_hhb_vars_income_revenue_BL.do")
project, do("$do/construct/hh-survey-BL/04a_ge_hhb_vars_laborsupply_BL.do")

* aspirations and psych variables
project, do("$do/construct/hh-survey-BL/05_ge_hh-welfare_psych_BL.do")

project, do("$do/construct/hh-survey-BL/06_ge_hh-welfare_health_foodsec_BL.do")

* additional outcomes
project, do("$do/construct/hh-survey-BL/07_ge_hh-welfare_othoutcomes_BL.do")


** bring in local PF stuff here? should at least make sure we have a basic version so that we can use taxes as a baseline covariate for ones included as part of this paper **
project, do("$do/construct/hh-survey-BL/ge_hhb_vars_localpf.do")

/* combining datasets into one baseline dataset */
project, do("$do/construct/hh-survey-BL/09_ge_hhb_vars_combine_for_analysisdata.do")
