/*
 * Filename: 1_construct_hh-outcomes_EL.do
 * Description: This do file constructs an analysis dataset
 *    of endline household survey outcomes. It also merges in baseline values of these outcomes. This serves as the basis for the spatial treatment dataset that adds in additional treatment variables.
 * Author: Michael Walker
 * Date: 17 Jun 2019 -- building on previous work
 */


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

/*** Household endline data construction process ***/

** generating tracking and attrition dataset **
// come back to this one -- lots of checks here, will need to figure out how we want this to work
project, do("$do/construct/hh-survey-EL/01_build_hh-endline_attrition_tracking.do")

** setting up dataset from rawdata **
project, do("$do/construct/hh-survey-EL/100a_ge_hh-survey-EL_data_setup.do")

** generating basic demographic variables **
project, do("$do/construct/hh-survey-EL/101_ge_frbasics_EL.do")
project, do("$do/construct/hh-survey-EL/102_ge_hhroster_EL.do")

* generating ag production dataset
project, do("$do/construct/hh-survey-EL/103_ge_agproduction_EL.do")

** generate household-level education outcomes. Individual-level education outcomes come later **
project, do("$do/construct/hh-survey-EL/104_ge_educationHH_EL.do")

** generate assets, expenditure and income measures **
project, do("$do/construct/hh-survey-EL/105_ge_assets_EL.do")
project, do("$do/construct/hh-survey-EL/106_ge_consexp_EL.do")
project, do("$do/construct/hh-survey-EL/107_ge_income_revenue_EL.do")

** generate other primary outcomes **
project, do("$do/construct/hh-survey-EL/108_ge_health_psych_asp_EL.do") // this can be split into two files
project, do("$do/construct/hh-survey-EL/109_ge_crimesafety_EL.do")
project, do("$do/construct/hh-survey-EL/110_ge_femaleempowerment_EL.do")
project, do("$do/construct/hh-survey-EL/111_ge_laborsupplyHH_EL.do") // this still needs to be checked
project, do("$do/construct/hh-survey-EL/112_ge_migration_transfers_EL.do") // this can be split into two

** other ad-hoc variables - later, integrate into the rest **
/* These are generally from local PF stuff */
project, do("$do/construct/hh-survey-EL/113_ge_commoutcomes_EL.do")

** list randomization outcomes **
//do "114_ge_listrand_EL.do" - this do file was just basic cleaning. Need to instead move this to analysis versions of the variables
project, do("$do/construct/hh-survey-EL/115_ge_hh-interest_rates_EL.do")

** combining into endline dataset **
project, do("$do/construct/hh-survey-EL/117_ge_combine_for_analysis.do")
