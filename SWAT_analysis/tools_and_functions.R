##################################################
## Project: SWATplusHybam
## Script purpose: Declare SWAT_Analysis functions here so the notebook stays
## clear and simple.
## Date: 10/14/2020
## Author: Florent Papini, Geoscience Environnement Toulouse, Observatoire Midi-Pyrénnées, 
## (florent.papini@ird.fr)
##################################################


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
flow_monthly_average <- function(df) 
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



## Write input files:
##################################################
setup_input_files <- function(path, files) 
{
  files = list(files)
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
  my_new_file = my_new_file[-(187:195)]
  my_new_file[2] = "195"
  write(my_new_file, file=paste(path,"/cal_parms.cal", sep=""))
  
  # create new lines
  bounds = c("no_rte                         bsn       0.00000      10.00000              null
fpgeom                         bsn       0.00000      10.00000              null
theta_fp                       bsn       0.00000      10.00000              rad
alpha_f                        bsn       0.00000      10.00000              null
cnfp                           bsn       0.00000      10.00000              null
mkkco1                         bsn       0.00000      10.00000              null
mkkco2                         bsn       0.00000      10.00000              null
mkkco3                         bsn       0.00000      10.00000              null
mkkx                           bsn       0.00000      10.00000              null")
  
  write(bounds, file=paste(path,"/cal_parms.cal", sep=""), append=TRUE)
  
  close(my_file)
}


## Write input files:
##################################################
setup_new_ch_parm <- function(path) 
{
  my_file<-file(paste(path,"/hyd-sed-lte.cha", sep=""))
  
  my_new_file = readLines(paste(path,"/hyd-sed-lte.cha", sep=""))
  
  # New header
  my_new_file[2] = paste(substr(my_new_file[2], 1, 328), "           kfp   description", sep="")
  
  n = 3
  # Adding new parameters
  for (line in my_new_file) {
    if(line == my_new_file[1] | line == my_new_file[2])
      next
    line = paste(substr(line, 1, 328), "       5.00000", sep="")
    # Replacing with the new line
    my_new_file[n] = line
    n = n + 1
  }
  
  writeLines(my_new_file, my_file)
  
  close(my_file)
}


























