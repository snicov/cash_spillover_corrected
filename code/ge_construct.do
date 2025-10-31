/*
 * Project: ge_construct.do
 * Description: This runs the data analysis build pipeline
      for the GE project. This does not include the generation
      of raw datasets from csv files, as this involves PII and we
      seek to keep these separate.
      (will need to make sure that this is fully ture and that we move other matching work to be separate)
 */

** Stata options
clear all
set varabbrev off

set more off
set matsize 1000
set maxvar 32000


project, doinfo
local pdir=r(pdir)
adopath ++ "`pdir'/ado/ado_ssc"
adopath ++ "`pdir'/ado"


*** Load dependencies into project ***
project, relies_on("`pdir'/do/set_environment.do")

* Import config - running globals
project, original(do/GE_global_setup.do)
include "do/GE_global_setup.do"

** creating intermediate data folder if not already there
cap mkdir data/intermediate


*** RUN HOUSEHOLD CONSTRUCTION ***
project, do("do/construct/construct_household_analysisdata.do")

*** RUN ENTERPRISE CONSTRUCTION ***
project, do("do/construct/construct_enterprise_analysisdata.do")

project, do("do/construct/treatment/GE_experimental_treatment_timing_new.do")

** Construct per capita GDP numbers -- nominal **
project, do("do/construct/treatment/construct_ppGDP.do")

** generating treatment datasets **
project, do("do/construct/treatment/markets_Create_SpatialPopulation.do")
project, do("do/construct/treatment/markets_Create_SpatialTreatment.do")
project, do("do/construct/treatment/villages_Create_SpatialPopulation.do")
project, do("do/construct/treatment/villages_Create_SpatialTreatment.do")

** Generate price outcomes **
//project, do("do/construct/prices/1_construct_price_weights.do")
project, do("do/construct/prices/2_construct_H1_index.do")
project, do("do/construct/prices/PrepareData.do") // main price indices
project, do("do/construct/prices/PrepareData_ByProduct.do") // main price indices
project, do("do/construct/prices/build_deflator.do") // price deflator
project, do("do/construct/treatment/deflate_villagetreatment.do")

** Construct per capita GDP numbers -- real **
project, do("do/construct/treatment/construct_ppGDP_r.do")

** RUN SPATIAL DATASETS CONSTRUCTION ***
 project, do("do/construct/construct_spatial_analysisdata.do")

** COMBINE HOUSEHOLD AND ENTERPRISE FOR MULTIPLIER ***
 project, do("do/construct/multiplier/build_hh_ent_multiplier_dataset.do")

** BUILD TIMING DATASET **
project, do("do/construct/build_timing_dataset.do")
