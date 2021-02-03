# SWATplusHybam <img src="./img/Hybam.jpg" align="right" />
`SWATplusHybam` is a model used to simulate water and sediments routing. It is a modified version of the [SWAT+](https://swat.tamu.edu/software/plus/) model aiming to enhance precision on simulations for large sized basins (such as the Amazon basin). It is meant to be handled from a simple R program based on the [SWATplusR](https://github.com/chrisschuerz/SWATplusR) package.

SWATplusHybam is a new model and haven't been tested on many devices yet, keep in mind that it will be updated at some point and unknown errors might occur. Feed back and suggestions are highly appreciated, please don't hesitate to [Contact](#Contact) us.

## Table of content
* [Introduction](#Introduction)
* [Installation](#Installation)
* [Getting started](#Getting started)
* [Contact](#Contact)

## Introduction
The `SWATplusHybam` package is divided in two parts : The modified Fortran program (SWATplusHybam.exe) based on the SWAT+ model and the R notebook (SWAT_analysis) which is a tools to link SWAT+ models with your modeling workflows in R.

The `SWATplusHybam` model is meant to replace the SWAT+ model, it provides the same functionalities but add new methods regarding routing and flexibility on the input parameters. These new algorithms regarding hydrological and sediment routing were developed by William Santini (william.santini@ird.fr) and are detailed in his PhD (Santini et al. 2019). Before running your model you can chose between multiple routing methods : kinetic wave, differential wave based on water height or discharge, you can also chose the type of floodplain for your model. On the other side, code maintenance and translation (from SWAT2012 to SWAT+) were done by Florent Papini (florent.papini@ird.fr).

 `SWATplusHybam` also provides a R notebook, SWAT_analysis, which purpose is to simplify the use of `SWATplusHybam` model by providing functions and tools to initialize and run your project. There are also some functions allowing an easy analysis of results. This notebook is mainly based on the SWATplusR package developed by Christoph Schuerz (christoph.schuerz@boku.ac.at).

## Installation
### Install the main package
Download the good SWATplusHybam repository depending on your system OS (SWATplusHybam_64 for windows 64...). Extract the SWATplus.exe executable and the .dll files in your project working directory (your_project/scenarios/Default/TxtInOut/).

`SWATplusHybam` is meant to be piloted from a R program, so it is highly recommended to download the SWAT_analysis repository containing a R notebook showing the basics to run the model and a R file containing some helpful functions.

### Install SWATplusR
Last thing you need to do is to go on your R IDE and install [SWATplusR](https://github.com/chrisschuerz/SWATplusR)
```r
# If you do not have the package devtools installed
install.packages("devtools")

devtools::install_github("chrisschuerz/SWATplusR")
```
If you encounter any issue during this step, please refer to the [SWATplusR](https://github.com/chrisschuerz/SWATplusR) page.

## Getting started
In order to use the SWATplusHybam model you need to set up your project through QGIS with the QSWAT+ plugin. You can find great videos tutorials on the [SWAT+](https://swat.tamu.edu/software/plus/) website. Then initialize weather data and modify parameters if needed, you can go back to this step at any time if you want. The import point is the step "write input files" as once it's done you can close QGIS and SWATplusEditor they will not be needed for running the model and analyze data. You can go through the step "Run SWAT+" on SWATplusEditor but it's not going to run the new model `SWATplusHybam`.

### Perform your first model
If you went successfully through the set up you can now go on the R notebook `SWAT_analysis` and try to perform a first run. There are no currently demo data, you will have to use one of your QSWAT+ project.

```r
# Load your libraries
library(SWATplusR)
source("tools_and_functions.R")

# Put the path to your TxtInOut file here
project_path <- "your_path/your_project/Scenarios/Default/TxtInOut"
```

```r
q_sim_day <- run_swatplus(project_path = project_path,
                         output = define_output(file = "channel_sd",
                                                 variable = "flo_out",
                                                 unit = 1))
```

[SWATplusR](https://github.com/chrisschuerz/SWATplusR)

### Analyze the model output
The following code is a simple plot example you can do with the functions included in the SWAT_analysis package.
```r
start_date = '2002-01-01'
end_date = '2014-07-31'
title = 'Lagarto'

# Always start with observed or your reference data!
simulations = list(q_obs, sim_csv, sim_month)
simulation_names = list("q_obs", "sim1", "sim1_monthly_average")

# Function to plot easily multiple figures of a same format
plot_results(simulations, simulation_names, start_date, end_date, title)
```
<img src="img/Result.png" title="plot" alt="plot" width="60%" style="display: block; margin: auto;" />

Other simple ways to plot your data are shown on the [SWATplusR](https://chrisschuerz.github.io/SWATplusR/articles/04_vis_example.html) Git page.

### Input parameters and input files
`SWATplusHybam` offers the possibility to chose among multiple water routing methods. Each of these Fortran routines are described in Santini & al.
```Fortran
if (no_rte == 1)   call sd_ch_rt_ck_wave
if (no_rte == 2)   call sd_rt_ck_wave_LF
if (no_rte == 3)   call sd_rt_ck_wave_tri
if (no_rte == 4)   call sd_rt_ck_wave_2FP
if (no_rte == 5)   call sd_ch_rt_diff_wave
if (no_rte == 6)   call sd_rt_diff_wave_h
if (no_rte == 7)   call sd_rt_inrtial_wave
if (no_rte == 8)   call sd_rtmuskKvar
```
Parameter changes in a R notebook is already available thanks to parameter sets as described in [SWATplusR](https://github.com/chrisschuerz/SWATplusR). So here we are using the same trick to chose the water routing algorithm.
```r
par_single = c("no_rte.bsn|change = abschg" = 5)
```
A new feature from `SWATplusHybam` is the ability to handle observed data, in order to use them as limit conditions or to do data assimilation for example. This observed data has to come as a .txt file and has it's type has to be specified in the functions Below.
```r
setup_input_files(project_path, list("htam.txt;hyd;1", "Qsf_lag.txt;sands;1"))
```
Only three types are available for now but some might be added later. You can currently provide a water, sand or wash load limit condition file or files for data assimilation (in progress).
```r
q_sim_day <- run_swatplus(project_path = project_path,
                         output = define_output(file = "channel_sd",
                                                 variable = "flo_out",
                                                 unit = 1),
                         start_date = "2013-1-1",
                         end_date = "2018-1-1",
                         years_skip = 2)
                         parameter = par_single)
```

## Contact
Created by William Santini (william.santini@ird.fr) and Florent Papini (florent.papini@ird.fr)
