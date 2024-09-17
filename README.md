This repository contains Stata .do files for my [reanalysis](https://michaelwiebe.com/assets/cash_spillover/cash_spillover.pdf) of "[General Equilibrium Effects of Cash Transfers: Experimental Evidence From Kenya](https://onlinelibrary.wiley.com/doi/full/10.3982/ECTA17945)", Egger et al. (2022).

To combine my code with the data, first download this repository, then download the original [replication package](https://onlinelibrary.wiley.com/action/downloadSupplement?doi=10.3982%2FECTA17945&file=ecta200500-sup-0002-dataandprograms.zip) (link to zip file) and extract the files to the directory 'data/', so we have 'data/ecta200500-sup-0002-dataandprograms/replication_materials/'. The replication package is available on the article website under 'Supporting Information'; the article is currently open access, so institutional access is not required.

To run the code, you need to create (or add to) a profile.do file. This file should be located in the 'personal/' directory, which you can locate using Stata's `sysdir` command. You need to create a global `ge_dir` with the path of the replication files. Specifically, add the following line to profile.do, filling in the location of the folder that contains this README:
>global ge_dir "[location of this replication archive]/data/ecta200500-sup-0002-dataandprograms/replication_materials"

There are directory path errors in the Egger et al. replication package that you need to correct manually.
- move the directory 'replication_materials/analysisdata/' into 'replication_materials/code', and rename it 'data', so that we have 'replication_materials/code/data/'.
- move the directory 'replication_materials/rawdata/' into 'replication_materials/code', so that we have 'replication_materials/code/rawdata/'.

I include a version of `global_runGPS.do` in 'code/' that instructs Stata to not estimate spatial standard errors, since the GPS data is not publicly available. I also include a version of `GE_global_setup.do` that fixes directory errors. The user does not need to change anything.

Two datasets are missing, which I include in 'data/'. These are 'GE_Market-Survey_EL1_PUBLIC.dta' and 'GE_HH-Survey-EL1_PUBLIC.dta'. You need to unzip and move them into "replication_materials/code/rawdata/".

To rerun the analyses, run the file `run.do` using Stata (version 15). 
Note that you need to set the path in `run.do` on line 2, to define the location of the folder that contains this README.
Required Stata packages are included in 'code/libraries/stata/', so that the user does not have to download anything and the replication can be run offline.
The file `code/_config.do` tells Stata to load packages from this location.

Figures and tables are saved in 'output/'; that directory is created by `code/_config.do`.
It takes approximately 1 hour to run the code using Stata-SE.