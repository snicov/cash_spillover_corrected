

# Set working directory to current file location -- all paths are relative #
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

# Figure 1 - Run code for main multiplier figure ##
source("do/analysis/multiplier/Figure1_Multiplier.R")

# Figure B4 - Price Effects by Product ##
source("do/analysis/main/FigureB4_PriceEffects_ByProduct.R")
