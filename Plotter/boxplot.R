# Clean workspace
rm(list=ls())
dev.off()

# Load library
library(readxl)
library(ggplot2)
library(tidyr)
library(gridExtra)
library(tidyverse)
library(multcompView)

# Box plot 1 factor
mybox <- function(dataset,x,y){
  p <- ggplot(dataset,aes(.data[[x]],.data[[y]]))
  # Setting base theme
  p <- p + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
               panel.background = element_blank(), axis.line = element_line(colour = "black"))
  # Adding scatter plot with jittered data
  #p <- p + geom_jitter(aes(colour=.data[[x]],fill=.data[[x]],shape=.data[["Cruise"]]),width=0.25,size=2,stroke=0.2)
  p <- p + geom_jitter(aes(colour=.data[["Cruise"]],fill=.data[[x]],shape=.data[["Cruise"]]),width=0.3,size=2,stroke=0.55) 
  #p <- p + geom_jitter(aes(colour=.data[["Habitat"]],fill=.data[["Habitat"]]),width=0.25,size=2,stroke=0.2) 
  # Drawing whisker box
  p <- p + geom_boxplot(outlier.shape = NA,alpha=0,lwd=0.35)
  # Change shape
  p <- p + scale_shape_manual(values=myshape)
  # Change border and fill colors
  p <- p + scale_color_manual(values=testcol)
  #p <- p + scale_color_manual(values=testcol[mydata$Habitat])
  #p <- p + scale_color_manual(values=mycolor)
  p <- p + scale_fill_manual(values=mycolor)
  # Turn off legend
  p <- p + theme(legend.position = "none")
  # Edit text size
  p <- p + theme(axis.text = element_text(size=12),axis.title = element_text(size=14,face="bold")) 
  # Plot margin
  p <- p + theme(plot.margin = margin(0.5,2,0.5,0.5,"cm"))
  return(p)
}

anova_letter <- function(dataset,x,y,rev=T){
  ## Plot anova
  # analysis of variance
  anova <- aov(dataset[[y]]~dataset[[x]])
  # Tukey's test
  tukey <- TukeyHSD(anova)
  # compact letter display
  cld <- multcompLetters4(anova, tukey,reverse=rev)
  # extracting the letter
  cld <- cld$`dataset[[x]]`$Letters
  # use factor groups as x coordinate
  x_cor <- names(cld)
  # Calculate y coordinate
  y_cor <- (max(dataset[[y]])-min(dataset[[y]]))*0.1
  # Put everything in a table
  df <- data.frame(x_cor,y_cor,cld)
  # Set order for x coordinate
  df$x_cor <- as.numeric(factor(df$x_cor,levels=c('RI','YPC','OPC','WPM','EPM','OPM','MOW','OSW'),ordered = TRUE))
  return(df)
}



# Load data
mydata <- read_excel(choose.files())

## Single factor analysis
mydata$Habitat <- factor(mydata$Habitat,levels=c('RI','YPC','OPC','WPM','EPM','OPM','MOW','OSW'),ordered = TRUE)
mydata$Cruise <- factor(mydata$Cruise,levels=c('KN197','MV1110','AT21-04','EN614','EN640','M174'),ordered = TRUE)
mycolor <- c("gray","red","orange","yellow","green","purple","cyan","blue")
myshape <- c(22,23,25,24,21,23)
#myshape <- c(0,5,6,2,1,10)
#myshape <- c(21,21,21,21,21,21)
# Outline color by cruise
testcol=c("gray35","gray35","gray35","gray35","gray35","brown1")
names(testcol) <- levels(mydata$Cruise)
testcol

p1 <- mybox(mydata,'Habitat','MLD')+
  ylab("MLD (m)")+
  scale_y_reverse(breaks=seq(0,200,25))+
  geom_text(data=anova_letter(mydata,'Habitat','MLD'),aes(x=x_cor,y=min(mydata$MLD)-y_cor,label=cld))
p2 <- mybox(mydata,'Habitat','ChlMD')+
  ylab("ChlMD (m)")+
  scale_y_reverse(breaks=seq(0,200,25))+
  geom_text(data=anova_letter(mydata,'Habitat','ChlMD'),aes(x=x_cor,y=min(mydata$ChlMD)-y_cor,label=cld))
p3 <- mybox(mydata,'Habitat','SST')+
  ylab("SST (°C)")+
  scale_y_continuous(limits=c(26,31))+
  geom_text(data=anova_letter(mydata,'Habitat','SST',rev=F),aes(x=x_cor,y=max(mydata$SST)+y_cor,label=cld))
p4 <- mybox(mydata,'Habitat','SSS')+
  ylab("SSS (psu)")+
  scale_y_continuous(limits=c(0,42))+
  geom_text(data=anova_letter(mydata,'Habitat','SSS'),aes(x=x_cor,y=max(mydata$SSS)+y_cor,label=cld))
p5 <- mybox(mydata,'Habitat','NAI')+
  ylab("NAI")+
  geom_text(data=anova_letter(mydata,'Habitat','NAI',rev=F),aes(x=x_cor,y=max(mydata$NAI)+y_cor,label=cld))

# Combining plots
grid.arrange(p1,p2,p3,p4,p5,ncol=2)


#--------------------------------------------------------------------------
# Sargassum data
sardata <- read_excel(choose.files())
sardata_temp <- sardata[sardata$Zone=='b',]
sardata_temp <- sardata_temp[!sardata_temp$Habitat=='udw',]
sardata_temp <- sardata_temp[!is.na(sardata_temp$Habitat),]
sardata_filtered <- sardata_temp[!is.na(sardata_temp$Cruise),]

mybox(sardata_filtered,'Habitat','d15N')
mybox(sardata_filtered,'Habitat','d13C')
mybox(sardata_filtered,'Habitat','N:P')


#--------------------------------------------------------------------------
## Double factors analysis
# Box plot 2 factors
mybox_adv <- function(dataset,x,y,z){
  p <- ggplot(dataset,aes(.data[[x]],.data[[y]],fill=.data[[z]]))
  p <- p + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
                 panel.background = element_blank(), axis.line = element_line(colour = "black"))
  p <- p + geom_boxplot(position = position_dodge(preserve='single'))
  p <- p + scale_fill_manual(values=c('red','orange','gold2','chartreuse3','blue'))
  return(p)
}
# Transform wide to long
data_long <- gather(mydata,key='HCA_method',value='Habitat',c('Weber','HCA_3c','HCA_3c_!SST (degree C)','HCA_5c','HCPC','HCA_5c_!SST (degree C)','HCPC_!SST (degree C)'),factor_key = TRUE,na.rm=TRUE)
data_long <- data_long[!data_long$Habitat %in% c('EPC','EPM?','OSW?','WPM?'),]
data_long$Habitat <- factor(data_long$Habitat,levels=c('YPC','OPC','WPM','EPM','OPM','OSW'),ordered = TRUE)


# Compare methods
mybox_adv(data_long,'Habitat','MLD (m)','HCA_method') + scale_y_reverse(breaks=seq(0,150,25))
mybox_adv(data_long,'Habitat','ChlMD (m)','HCA_method') + scale_y_reverse(breaks=seq(0,150,25))
mybox_adv(data_long,'Habitat','SST (degree C)','HCA_method')
mybox_adv(data_long,'Habitat','SSS (psu)','HCA_method') 
mybox_adv(data_long,'Habitat','NAI','HCA_method')

# Two way ANOVA
SST_anova <- aov(SST ~ Cruise*Habitat, data=mydata)
SST_pairwise <- TukeyHSD(SST_anova,which='Cruise:Habitat')
result <- data.frame(na.omit(SST_pairwise[["Cruise:Habitat"]]))
#[,'p adj']
result2 <- result[result$p.adj < 0.05,]
result2 <- result[order(row.names(result)),]
#write.csv(MLD (m)_pairwise[[1]],'test_table.csv')

# Compare cruises
# All methods
mybox_adv(mydata,'Habitat','MLD (m)','Cruise') + scale_y_reverse(breaks=seq(0,200,25))
mybox_adv(mydata,'Habitat','ChlMD (m)','Cruise') + scale_y_reverse(breaks=seq(0,200,25))
mybox_adv(mydata,'Habitat','SST (degree C)','Cruise')
mybox_adv(mydata,'Habitat','SSS (psu)','Cruise')
mybox_adv(mydata,'Habitat','NAI','Cruise')

# Each method
mydata$HCA_5c <- factor(mydata$HCA_5c,levels=c('YPC','OPC','WPM','EPM','OPM','OSW'),ordered = TRUE)
mybox_adv(mydata,'HCA_5c','MLD (m)','Cruise')+ scale_y_reverse(breaks=seq(0,200,25))
mybox_adv(mydata,'HCA_5c','ChlMD (m)','Cruise')+ scale_y_reverse(breaks=seq(0,200,25))
mybox_adv(mydata,'HCA_5c','SST (degree C)','Cruise')
mybox_adv(mydata,'HCA_5c','SSS (psu)','Cruise')
mybox_adv(mydata,'HCA_5c','NAI','Cruise')

# Plot by cruise
mydata$Cruise <- factor(mydata$Cruise,levels=c('M174','EN614','KN197','EN640','AT21-04','MV1110'),ordered = TRUE)
mydata$Year <- factor(mydata$Year,ordered=T)
mycolor2 <- c("gray","red","darkorange","gold","green","purple","cyan","blue")

# time stamps
space <- c(1,2,3.4,4.5,6.1,10.1)
cruise <- c('M174','EN614','KN197','EN640','AT21-04','MV1110')
month <- seq(as.Date("2020/1/1"), by = "month", length.out = 12)
mydata$Timestamp <- as.Date("2000/01/01")
mydata$Timestamp[mydata$Cruise == "M174"] <- as.Date("2000/05/02")
mydata$Timestamp[mydata$Cruise == "EN614"] <- as.Date("2000/05/18")
mydata$Timestamp[mydata$Cruise == "KN197"] <- as.Date("2000/06/08")
mydata$Timestamp[mydata$Cruise == "EN640"] <- as.Date("2000/06/26")
mydata$Timestamp[mydata$Cruise == "AT21-04"] <- as.Date("2000/07/20")
mydata$Timestamp[mydata$Cruise == "MV1110"] <- as.Date("2000/09/20")
mydata$Timestamp
mybreak <- as.Date(c("2000/05/02","2000/05/18","2000/06/08","2000/06/26","2000/07/20","2000/09/20"))
mylim <- as.Date(c("2000/04/15","2000/10/15"))
minorbreak <- as.Date(c("2000/05/01","2000/06/01","2000/07/01","2000/08/01","2000/09/01","2000/10/01"))
p1 <- ggplot(mydata, aes(y = MLD, x = Timestamp, colour = Habitat, group = Habitat))+
  ylab("MLD (m)")+
  xlab("")+
  scale_y_reverse(breaks=seq(0,200,25))+
  scale_x_date(limit=mylim,breaks=mybreak,minor_breaks=minorbreak,labels=cruise,sec.axis = sec_axis(~.))+
  stat_summary(fun = mean,position=position_dodge(width=10),
               fun.min = function(x){mean(x)-sd(x)},
               fun.max = function(x) {mean(x)+sd(x)},
               geom = "pointrange",size=0.7,aes(fill=Habitat),shape=21,color="black",linewidth=0.35,stroke=0.5)+
  scale_fill_manual(values=mycolor2)+
  scale_color_manual(values=mycolor2)+
  theme(panel.grid.minor.x = element_line(color='gray',linewidth=0.2),
        panel.grid.major.y = element_line(color='gray',linewidth=0.2),
        #panel.grid.minor = element_blank(),
        panel.background = element_blank(), axis.line = element_line(colour = "black"),
        axis.text = element_text(size=10),axis.title = element_text(size=12,face="bold"),
        legend.position = "none",plot.margin = margin(0,0.5,0,0.1,"cm"),
        panel.border=element_rect(color="black",fill=NA,size=0.5),axis.text.x.bottom=element_text(size=10,angle=35,vjust=1,hjust=1))

p2 <- ggplot(mydata, aes(y = ChlMD, x = Timestamp, colour = Habitat, group = Habitat))+
  ylab("ChlMD (m)")+
  xlab("")+
  scale_y_reverse(breaks=seq(0,200,25))+
  scale_x_date(limit=mylim,breaks=mybreak,minor_breaks=minorbreak,labels=cruise,sec.axis = sec_axis(~.))+
  stat_summary(fun = mean,position=position_dodge(width=10),
               fun.min = function(x){mean(x)-sd(x)},
               fun.max = function(x) {mean(x)+sd(x)},
               geom = "pointrange",size=0.7,aes(fill=Habitat),shape=21,color="black",linewidth=0.35,stroke=0.5)+
  scale_fill_manual(values=mycolor2)+
  scale_color_manual(values=mycolor2)+
  theme(panel.grid.minor.x = element_line(color='gray',linewidth=0.2),
        panel.grid.major.y = element_line(color='gray',linewidth=0.2),
        panel.background = element_blank(), axis.line = element_line(colour = "black"),
        axis.text = element_text(size=10),axis.title = element_text(size=12,face="bold"),
        legend.position = "none",plot.margin = margin(0,0.5,0,0.1,"cm"),
        panel.border=element_rect(color="black",fill=NA,size=0.5),axis.text.x.bottom=element_text(size=10,angle=35,vjust=1,hjust=1))


p3 <- ggplot(mydata, aes(y = SST, x = Timestamp, colour = Habitat, group = Habitat))+
  ylab("SST (°C)")+
  xlab("")+
  scale_y_continuous(limits=c(26,30))+
  scale_x_date(limit=mylim,breaks=mybreak,minor_breaks=minorbreak,labels=cruise,sec.axis = sec_axis(~.))+
  stat_summary(fun = mean,position=position_dodge(width=10),
               fun.min = function(x){mean(x)-sd(x)},
               fun.max = function(x) {mean(x)+sd(x)},
               geom = "pointrange",size=0.7,aes(fill=Habitat),shape=21,color="black",linewidth=0.35,stroke=0.5)+
  scale_fill_manual(values=mycolor2)+
  scale_color_manual(values=mycolor2)+
  theme(panel.grid.minor.x = element_line(color='gray',linewidth=0.2),
        panel.grid.major.y = element_line(color='gray',linewidth=0.2),
        panel.background = element_blank(), axis.line = element_line(colour = "black"),
        axis.text = element_text(size=10),axis.title = element_text(size=12,face="bold"),
        legend.position = "none",plot.margin = margin(0,0.5,0,0.1,"cm"),
        panel.border=element_rect(color="black",fill=NA,size=0.5),axis.text.x.bottom=element_text(size=10,angle=35,vjust=1,hjust=1))

p4 <- ggplot(mydata, aes(y = SSS, x = Timestamp, colour = Habitat, group = Habitat))+
  ylab("SSS (psu)")+
  xlab("")+
  scale_y_continuous(limits=c(0,40))+
  scale_x_date(limit=mylim,breaks=mybreak,minor_breaks=minorbreak,labels=cruise,sec.axis = sec_axis(~.))+
  stat_summary(fun = mean,position=position_dodge(width=10),
               fun.min = function(x){mean(x)-sd(x)},
               fun.max = function(x) {mean(x)+sd(x)},
               geom = "pointrange",size=0.7,aes(fill=Habitat),shape=21,color="black",linewidth=0.35,stroke=0.5)+
  scale_fill_manual(values=mycolor2)+
  scale_color_manual(values=mycolor2)+
  theme(panel.grid.minor.x = element_line(color='gray',linewidth=0.2),
        panel.grid.major.y = element_line(color='gray',linewidth=0.2),
        panel.background = element_blank(), axis.line = element_line(colour = "black"),
        axis.text = element_text(size=10),axis.title = element_text(size=12,face="bold"),
        legend.position = "none",plot.margin = margin(0,0.5,0,0.1,"cm"),
        panel.border=element_rect(color="black",fill=NA,size=0.5),axis.text.x.bottom=element_text(size=10,angle=35,vjust=1,hjust=1))

p5 <- ggplot(mydata, aes(y = NAI, x = Timestamp, colour = Habitat, group = Habitat))+
  ylab("NAI")+
  xlab("")+
  scale_x_date(limit=mylim,breaks=mybreak,minor_breaks=minorbreak,labels=cruise,sec.axis = sec_axis(~.))+
  stat_summary(fun = mean,position=position_dodge(width=10),
               fun.min = function(x){mean(x)-sd(x)},
               fun.max = function(x){mean(x)+sd(x)},
               geom = "pointrange",
               size=0.7,aes(fill=Habitat),shape=21,color="black",linewidth=0.35,stroke=0.5)+
  scale_fill_manual(values=mycolor2)+
  scale_color_manual(values=mycolor2)+
  theme(panel.grid.minor.x = element_line(color='gray',linewidth=0.2),
        panel.grid.major.y = element_line(color='gray',linewidth=0.2),
        panel.background = element_blank(), axis.line = element_line(colour = "black"),
        axis.text = element_text(size=10),axis.title = element_text(size=12,face="bold"),
        legend.position = "none",plot.margin = margin(0,0.5,0,0.1,"cm"),
        panel.border=element_rect(color="black",fill=NA,size=0.5),axis.text.x.bottom=element_text(size=10,angle=35,vjust=1,hjust=1))
p5
# Combining plots
grid.arrange(p1,p2,p3,p4,p5,p6,ncol=2)

col1 <- rbind(ggplotGrob(p1),ggplotGrob(p3),ggplotGrob(p5),size='last')
col2 <- rbind(ggplotGrob(p2),ggplotGrob(p4),ggplotGrob(p6),size='last')
matrix_plots <- arrangeGrob(cbind(col1, col2, size = "last"))
library(grid)
grid.newpage()
grid.draw(matrix_plots)

habitat_anova <- aov(MLD~Cruise*Habitat,data=mydata)
summary(habitat_anova)
test <- TukeyHSD(habitat_anova)
result <- as.data.frame(test$`Cruise:Habitat`)
result <- na.omit(result)
result <- result[result$`p adj` < 0.05,]
result<- result[order(row.names(result)),]
capture.output(result,file="MLD_ANOVA.txt")

filename = "NAI_ANOVA.txt"
for (i in c('RI','YPC','OPC','WPM','EPM','OPM','OSW')){
  capture.output(paste("ANOVA for",i),file=filename,append=T)
  subdata <- mydata[mydata$Habitat==i,]
  test <- aov(NAI~Cruise,data=subdata)
  capture.output(summary(test),file=filename,append=T)
  if (summary(test)[[1]][["Pr(>F)"]][1] <= 0.05){
    test_pairwise <- TukeyHSD(test)
    capture.output(test_pairwise,file=filename,append=T)
  }
}