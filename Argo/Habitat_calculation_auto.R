# Clean workspace
rm(list=ls())
dev.off()

# Libraries
require(oce)
require(ggpmisc)
require(dplyr)
require(writexl)
library(hydroTSM)
library(lubridate)

# Define function
hbt <- function(mydata,n2.smooth=T,n2.local.max=1,chla.smooth=T,chla.local.max=1,nai.bound=2,plot=F,zmax=300){
  
  #==========Description===========
  # Function to calculate habitat defining variable of a single float cycle from BGC-ARGO
  # Input:
  # - mydata: input BGC-ARGO data download by argo_download.py
  # - n2.smooth: option to apply smoothing function on buoyancy frequency (N2), will affect local maxima
  # - n2.local.max: select n-th local maximum from surface, set to FALSE for global maximum
  # - chla.smooth: option to apply smoothing function on chl a, will affect local maxima
  # - chla.local.max: select n-th local maximum from surface, set to FALSE for global maximum
  # - nai.bound: boundary for NAI calculation, default is 2 uM as in Weber et al. 2019
  # - plot: option to plot N2, Chla, and [NO3] profiles
  # - zmax: depth limit plot, set to FALSE for profile bottom depth
  
  #========== Float basic info ==========
  Float <- mydata[["PLATFORM_NUMBER"]][1]
  Cycle <- mydata[["PROF_NUM"]][1]
  Float_Cycle <- paste('Float',Float,"Cycle",Cycle,sep='_')
  Date <- mydata[["JULD"]][1]
  lat <- mydata[["LATITUDE"]][1]
  lon <- mydata[["LONGITUDE"]][1]
  season <- time2season(as.Date(Date))
  Time <- ifelse( hour(Date)<6 | 18<hour(Date), "Night","Day" )
  
  #========== Calculate MLD ==========
  # Calculate depth from pressure
  d_full <- swDepth(mydata[["PRES_ADJUSTED"]])
  t <- mydata[["TEMP_ADJUSTED"]]
  s <- mydata[["PSAL_ADJUSTED"]]
  # Calculate potential density from temperature, salinity, and pressure
  sig <- swSigmaTheta(mydata[["PSAL_ADJUSTED"]],temperature=mydata[["TEMP_ADJUSTED"]],pressure=mydata[["PRES_ADJUSTED"]])
  # Calculate squared buoyancy frequency from potential density, apply smoothing function if prompted
  if (n2.smooth){
    n2 <- swN2(mydata[["PRES_ADJUSTED"]],sigmaTheta=sig,derivs='smoothing')
  } else {
    n2 <- swN2(mydata[["PRES_ADJUSTED"]],sigmaTheta=sig,derivs='simple')
  }
  # Find all depth of local maxima for buoyancy
  MLD_list <- d_full[ggpmisc:::find_peaks(n2,ignore_threshold=0.2)]
  s_peaks <- d_full[ggpmisc:::find_peaks(s)]
  # Extract local/global maximum for buoyancy
  if (n2.local.max==F){
    MLD <- d_full[which.max(n2)]
  }else{
    MLD <- MLD_list[n2.local.max]
  }
  
  #========== Calculate SST, SSS ==========
  # Extract sea surface temperature, salinty
  SST <- t[!is.na(t)][which.min(d_full[!is.na(t)])]
  SSS <- s[!is.na(s)][which.min(d_full[!is.na(s)])]
  
  #========== Filter data for Chla and NO3 ==========
  
  
  #========== Calculate ChlMD ==========
  # Adjust data scan
  if (all(is.na(mydata[["CHLA_ADJUSTED"]]))==TRUE){
    chlacol = "CHLA"
  } else {
    chlacol = "CHLA_ADJUSTED"
  }
  # Filter NAs
  data_chla <- mydata[!is.na(mydata[[chlacol]]),]
  # Extract depth for calculation
  d_chla <- swDepth(data_chla[["PRES_ADJUSTED"]])
  # Extract Chl a
  if (chla.smooth){
    chla <- smooth.spline(data_chla[[chlacol]])$y
  } else {
    chla <-data_chla[[chlacol]]
  }
  # Surface Chla
  SCHL <- chla[which.min(d_chla)]
  # Find all depth of local maxima for chl a
  ChlMD_list <- d_chla[ggpmisc:::find_peaks(chla)]
  # Extract local/global maximum for chl a
  if (chla.local.max==F){
    ChlMD <- d_chla[which.max(chla)]
  }else{
    ChlMD <- ChlMD_list[chla.local.max]
  }
  
  #========== Calculate NAI ===========
  # Adjust data scan
  if (all(is.na(mydata[["NITRATE_ADJUSTED"]]))==TRUE){
    nacol = "NITRATE"
  } else {
    nacol = "NITRATE_ADJUSTED"
  }
  # Filter NAs
  data_nitrate <- mydata[!is.na(mydata[[nacol]]),]
  # Extract depth for calculation
  d_nitrate <- swDepth(data_nitrate[["PRES_ADJUSTED"]])
  n <- data_nitrate[[nacol]]
  # If surface [NO3] >= boundary then NAI = surface [NO3]
  # If surface [NO3] <= boundary and bottom [NO3] >= boundary then integrate depth for [NO3]=boundary
  # If bottom [NO3] <= boundary then NAI = minus bottom depth
  if (n[which.min(d_nitrate)]>=nai.bound){
    nai <- n[which.min(d_nitrate)] 
  } else if ((n[which.min(d_nitrate)]<nai.bound)&(max(n)>nai.bound)) {
    i <- which(n >= nai.bound)[1] # nearest larger value index
    k <- i-1
    nai <- -(d_nitrate[k]+(nai.bound-n[k])*(d_nitrate[i]-d_nitrate[k])/(n[i]-n[k]))
  } else {
    nai <- -d_nitrate[which.max(d_nitrate)]
  }
  
  #========== Plot ==========
  if (plot){
    if(zmax==FALSE){zmax=max(d_full)}
    # Plot outline
    par(mar=c(9,5,5,1))
    par(mfrow=c(1,2))
    # First plot
    # Plot N2
    #plot(n2,d_full,type="l",lwd=2,col="black",ylab="Depth [m]",xlab="",ylim=c(zmax,0),xaxt='n')
    plot(sig,d_full,type="l",lwd=2,col="black",ylab="Depth [m]",xlab="",ylim=c(zmax,0),xaxt='n')
    axis(at=pretty(n2),side=1,col="black",col.axis="black",line=0)
    #mtext(expression("N"^"2"*" [rad"^"2"*" s"^"-2"*"]"), side=1, col="black",line=3)
    mtext("SigmaTheta", side=1, col="black",line=3)
    abline(h=MLD,lwd=2,lty="dashed",col="black")
    # Plot Chl a
    par(new=T)
    plot(chla,d_chla,type="l",lwd=2,col="darkgreen",axes=F,ylab="",xlab="",ylim=c(zmax,0))
    axis(at=pretty(chla),side=3,col="darkgreen",col.axis="darkgreen")
    abline(h=ChlMD,lwd=2,lty="dashed",col="darkgreen")
    mtext(expression("Chl a [mg m"^"-3"*']'), side=3, col="darkgreen",line=2)
    # Add info
    mtext(paste0("MLD = ",round(MLD,2),' m'),line=5,side=1)
    mtext(paste0("ChlMD = ",round(ChlMD,2),' m'),line=6,side=1)
    mtext(paste0("NAI = ",round(nai,2)),line=7,side=1)
    # Second plot
    # Find plotting range
    t_temp <- t[d_full<zmax]
    s_temp <- s[d_full<zmax]
    n_temp <- n[d_nitrate<zmax]
    t_range <- c(floor(min(t_temp,na.rm=T))-0.5,ceiling(max(t_temp,na.rm=T))+0.5)
    s_range <- c(floor(min(s_temp,na.rm=T))-0.5,ceiling(max(s_temp,na.rm=T))+0.5)
    n_range <- c(floor(min(n_temp,na.rm=T))-1,ceiling(max(n_temp,na.rm=T))+1)
    # Plot temperature
    plot(t,d_full,type="l",lwd=2,col="red",ylab="Depth [m]",xlab="",ylim=c(zmax,0),xaxt='n',xlim=t_range)
    axis(at=pretty(t_range),side=1,col="red",col.axis="red",line=0)
    mtext("Temperature [°C]", side=1, col="red",line=3)
    # Plot salinity
    par(new=T)
    plot(s,d_full,type="l",lwd=2,col="darkgoldenrod",axes=F,ylab="",xlab="",ylim=c(zmax,0),xlim=s_range)
    axis(at=pretty(s_range),side=3,col="darkgoldenrod",col.axis="darkgoldenrod")
    mtext("Salinity [psu]", side=3, col="darkgoldenrod",line=2)
    # Plot NO3
    par(new=T)
    plot(n,d_nitrate,type="l",lwd=2,col="blue",axes=F,ylab="",xlab="",ylim=c(zmax,0),xlim=n_range)
    #abline(v=nai.bound,lwd=2,lty="dashed",col="blue")
    abline(h=abs(nai),lwd=2,lty="dashed",col="blue")
    axis(at=pretty(n_range),side=1,col="blue",col.axis="blue",line=5)
    mtext(expression("NO"[3]*" [µM]"),side=1,col="blue",line=7)
    # Add title
    mtext(Float_Cycle,side=3,outer=T,line=-1,font=2,cex=1.2)
  }
  
  #========== Export result ==========
  temp <- c(Float,Cycle,Float_Cycle,Date,season,Time,lat,lon,MLD,ChlMD,SST,SSS,abs(nai),SCHL)
  result <- data.frame(matrix(ncol=11,nrow=0))
  result <- rbind(result,temp)
  colnames(result) <- c('Float','Cycle','Float_cycle','Date','Season','Time','Lat','Lon','MLD','ChlMD','SST','SSS','DNC','SCHL')
  return(result)
}

# Load data
data <- read.csv(choose.files(),header=T)

# Automized calculations
# Create blank dataframe
result_table <- data.frame(matrix(ncol=14,nrow=0))
colnames(result_table) <- c('Float','Cycle','Float_cycle','Date','Season','Time','Lat','Lon','MLD','ChlMD','SST','SSS','DNC','SCHL')
result_table <- result_table %>% as_tibble %>% mutate_all(as.character)
# Calculate all float cycle
for (i in unique(data$PROF_NUM)){
  mycal <- hbt(data[data$PROF_NUM==i,],chla.local.max=F,n2.local.max = F,plot=T,nai.bound=mean(data[data$PROF_NUM==i,]$NITRATE_ADJUSTED[data[data$PROF_NUM==i,]$PRES_ADJUSTED<=50],na.rm=T)+1)
  result_table <- rows_upsert(result_table,mycal,by="Float_cycle")
}


# Load data
files <- list.files(path=choose.dir(),pattern="*.csv",full.names = T)

for (myfile in files){
  data <- read.csv(myfile,header=T,check.names=F)
  
  # Automized calculations
  # Create blank dataframe
  result_table <- data.frame(matrix(ncol=14,nrow=0))
  colnames(result_table) <- c('Float','Cycle','Float_cycle','Date','Season','Time','Lat','Lon','MLD','ChlMD','SST','SSS','DNC','SCHL')
  result_table <- result_table %>% as_tibble %>% mutate_all(as.character)
  # Calculate all float cycle
  for (i in unique(data$PROF_NUM)){
    #try(mycal <- hbt(data[data$PROF_NUM==i,],chla.local.max=F,n2.local.max = 1,plot=T,nai.bound=median(data[data$PROF_NUM==i,]$NITRATE_ADJUSTED[data[data$PROF_NUM==i,]$PRES_ADJUSTED<=75],na.rm=T)+1))
    try(mycal <- hbt(data[data$PROF_NUM==i,],chla.local.max=F,n2.local.max = 1,plot=T,nai.bound=1.5))
    try(result_table <- rows_upsert(result_table,mycal,by="Float_cycle"))
  }
  
  # Format
  result_table$Date <- as.Date(result_table$Date)
  result_table[,7:14] <- sapply(result_table[,7:14],as.numeric)
  result_table[,7:14] <- sapply(result_table[,7:14],function(x) round(x,digits=2))
  
  
  # Save final calculations
  write_xlsx(result_table,paste0('atlantic/',result_table$Float[1],'_hdv.xlsx'))
}
  

  
  
  
# Manual inspection
subdata <- data[data$PROF_NUM == 383,]
myresult <- hbt(subdata,plot=T,chla.local.max = F,n2.local.max = 1,zmax=300)

# Update manual inspection to result table
result_table <- rows_upsert(result_table,myresult,by="Float_cycle")