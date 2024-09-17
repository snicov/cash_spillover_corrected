* set path: uncomment the following line and set the filepath for the folder containing this run.do file
*global root "[location of replication archive]"
global root "/home/michael/Dropbox/replications/cash_spillover"
global data "$root/data"
global code "$root/code"
global files "$data/ecta200500-sup-0002-dataandprograms/replication_materials"
global tables "$root/output/tables"
global figures "$root/output/figures"

do "$code/_config.do"

do "$code/clean.do"
do "$code/stats.do"
do "$code/reanalysis.do"