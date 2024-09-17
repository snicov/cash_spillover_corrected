/*
 * Filename: GE_global_setup.do
 * Description: This do file loads conversion factors and other
 *     variables that are used across the project. In cases where this requires calculations, clearly notes where these are coming from.
 * Author: Michael Walker
 * Note: file created in May 2019, still need to ensure that some of these calculations and numbers are consolidated into this do file.
 */

global USDKES = 97

glo ppprate = 1/46.49 // World Bank PPP conversion factor for private consumption, accessed Sep 28 2018
global ugx_kes = 0.0309 /*UGX to KES exchange rate, 18 Aug 2014 to 31 Aug 2015 from oanda.com */

glo trans_amt = 87000*$ppprate

glo adult_age = 18 // setting age at which we consider people adults -- this matters for household roster, and some education-related outcomes

** Stata options
set more off
set matsize 1000
//set maxvar 32000

** directory structure (off of project dir)
/* project, doinfo */
** MiWi: not using project

/* global dir=r(pdir) */
global dir="$ge_dir"
**MW: try this for now
glo ado="$dir/ado"
glo do="$dir/do"
glo dl="$dir/logs"
glo dr="$dir/rawdata"
glo da="$dir/data"
glo dt="$dir/temp"
glo dtab="$dir/results/tables"
glo dfig="$dir/results/figures"
