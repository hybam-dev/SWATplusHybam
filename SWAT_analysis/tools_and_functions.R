##################################################
## Project: SWATplusHybam
## Script purpose: Declare SWAT_Analysis functions here so the notebook stays
## clear and simple.
## Date: 10/14/2020
## Author: Florent Papini, Geoscience Environnement Toulouse, Observatoire Midi-Pyrénnées, 
## (florent.papini@ird.fr)
##################################################

library(tidyr)
library(dplyr)
library(ggplot2)
library(dygraphs)
library(xts)
library(readr)
library(hydroGOF)
library(plotly)
library(lubridate)


## View timeseries:
##################################################
view_timeseries <- function(q_sim, q_obs) 
{
  names(q_obs) <- c("date", "q_obs")
  
  q_xts <- q_sim_day %>% 
    dplyr::left_join(., q_obs, by = "date") %>% 
    xts::xts(x = .[,c(2:ncol(.))], order.by = .$date)
  
  n_sim <- ncol(q_sim) - 1
  
  dygraph(q_xts) %>% dyRangeSelector() %>% 
    dyOptions(colors = c(colorRampPalette(RColorBrewer::brewer.pal(8, "Paired"))(n_sim), "green"))
}


## save sim:
##################################################
save_sim <- function(file_path, sim, test_name) 
{
  names(sim)[names(sim) == "flo_out"] <- test_name
  
  if(file.exists(file_path)) 
  {
    tmp <- read.csv(file_path)
    tmp <- cbind(tmp, test_name = c(sim[2]))
    write.csv(tmp, file_path, row.names = FALSE)
  } else 
  {
    write.csv(sim, file_path, row.names = FALSE)
  }
}


## Plot results: Function to plot easily multiple figures
##################################################
plot_results <- function(simulations, simulation_names, begin_date, end_date, title)
{
  i = 0
  for(sim in simulations) {
    i = i + 1
    if(i == 1) {
      q_obs <- sim[sim[1] >= start_date & sim[1] <= end_date & !is.na(sim[2]),]
      G = plot_ly(x = ~ q_obs[[1]], y = ~ q_obs[[2]], 
                  name = simulation_names[1], type = 'scatter',
                  mode = "line", alpha = 0.6)
    }
    else {
      sim <- sim[sim$date >= start_date & sim$date <= end_date & !is.na(sim$date),]
      if(nrow(sim) == nrow(q_obs)) {
        PBIAS = round(pbias(sim = sim$flo_out, obs = q_obs[[2]]))
        NSE = format(round(NSE(sim = sim$flo_out, obs = q_obs[[2]]), 2), nsmall = 2)
      }
      else {
        PBIAS = NA
        NSE = NA
      }
      G = add_trace(G, data = sim, x = sim$date, y = sim$flo_out, 
                    name = paste(simulation_names[i], "\nPBIAS:",PBIAS,"%, \nNSE:", NSE, ""))
      
    }
  }
  G <- layout(G, title = title,
              xaxis = list(title = "Date", range = c(start_date,end_date)),
              yaxis = list(title = "Q [m3/s]"))
  
  htmlwidgets::saveWidget(G, "Result.html")
  print(G)
}



## Plot results: Function to plot easily multiple figures
##################################################
plot_results <- function(simulations, simulation_names, begin_date, end_date, title)
{
  i = 0
  for(sim in simulations) {
    i = i + 1
    if(i == 1) {
      q_obs <- sim[sim[1] >= start_date & sim[1] <= end_date & !is.na(sim[2]),]
      G = plot_ly(x = ~ q_obs[[1]], y = ~ q_obs[[2]], 
                  name = simulation_names[1], type = 'scatter',
                  mode = "line", alpha = 0.6)
    }
    else {
      sim <- sim[sim$date >= start_date & sim$date <= end_date & !is.na(sim$date),]
      if(nrow(sim) == nrow(q_obs)) {
        PBIAS = round(pbias(sim = sim$flo_out, obs = q_obs[[2]]))
        NSE = format(round(NSE(sim = sim$flo_out, obs = q_obs[[2]]), 2), nsmall = 2)
      }
      else {
        PBIAS = NA
        NSE = NA
      }
      G = add_trace(G, data = sim, x = sim$date, y = sim$flo_out, 
                    name = paste(simulation_names[i], "\nPBIAS:",PBIAS,"%, \nNSE:", NSE, ""))
      
    }
  }
  G <- layout(G, title = title,
              xaxis = list(title = "Date", range = c(start_date,end_date)),
              yaxis = list(title = "Q [m3/s]"))
  
  htmlwidgets::saveWidget(G, "Result.html")
  print(G)
}



## Monthly average:
##################################################
monthly_average <- function(df, var) 
{
  df$month = format(df$date, format = "%m")
  df$year = format(df$date, format = "%Y")
  
  
  Agg = aggregate(flo_out ~ month + year, data = df, mean)
  print(Agg)
  
  # eval(parse(text = "x"))
  
  Agg$date = paste(Agg$year, Agg$month, 16, sep = "-")
  Agg$date = as.Date(Agg$date, format = "%Y-%m-%d")
  return(Agg)
}

## Load channel_sd_day:
##################################################
load_channel_sd_day <- function(path) 
{
  
}



## Write input files:
##################################################
setup_input_files <- function(path, files) 
{
  # clear previous input files
  my_file<-file(paste(path,"/file.cio", sep=""))
  
  # clean the old file input infos
  my_new_file = readLines(paste(path,"/file.cio", sep=""))
  my_new_file = my_new_file[-(32:36)]
  write(my_new_file, file=paste(path,"/file.cio", sep=""))
  
  # create new lines
  hyd = c("hydro    null")
  wl = c("wl    null")
  sands = c("sands    null")
  da = c("da    null")
  
  for(file in files) {
    
    # check type
    file_info = strsplit(file, ";")[[1]]
    
    # add new input files to the list
    if(file_info[2] == "hyd") {
      # Cases where it is the first file of this type
      if(hyd == c("hydro    null")) {
        hyd = paste("hydro", file, sep="    ")
      }
      else {
      hyd = paste(hyd, file, sep="    ")
      }
    }
    
    if(file_info[2] == "wl") {
      if(wl == c("wl    null")) {
        wl = paste("wl", file, sep="    ")
      }
      else {
      wl = paste(wl, file, sep="    ")
      }
    }
    
    if(file_info[2] == "sands") {
      if(sands == c("sands    null")) {
        sands = paste("sands", file, sep="    ")
      }
      else {
      sands = paste(sands, file, sep="    ")
      }
    }
    
    if(file_info[2] == "da") {
      if(da == c("da    null")) {
        da = paste("da", file, sep="    ")
      }
      else {
      da = paste(da, file, sep="    ")
      }
    }
    
  }
  files = c(hyd, wl, sands, da)
  
  write(files, file=paste(path,"/file.cio", sep=""), append=TRUE)
  
  close(my_file)
  
  # faire une liste et tout append a la fin
}

## Write new parameter bounds:
##################################################
setup_par_bounds <- function(path) 
{
  # clear previous input files
  my_file<-file(paste(path,"/file.cio", sep=""))
  
  # clean the old file input infos
  my_new_file = readLines(paste(path,"/cal_parms.cal", sep=""))
  my_new_file = my_new_file[-(187:191)]
  write(my_new_file, file=paste(path,"/cal_parms.cal", sep=""))
  
  # create new lines
  bounds = c("no_rte                         bsn       0.00000      10.00000              null
fpgeom                         bsn       0.00000      10.00000              null
theta_fp                       bsn       0.00000      10.00000              null
alpha_f                        bsn       0.00000      10.00000              null")
  
  write(bounds, file=paste(path,"/cal_parms.cal", sep=""), append=TRUE)
  
  close(my_file)
}




























