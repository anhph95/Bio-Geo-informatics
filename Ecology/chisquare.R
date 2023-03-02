## Analysis of pigment data using Chi square distance
# Required libraries: vegan, pairwiseAdonis, dplyr, [BiodiversityR]

# Clean workspace
rm(list=ls())
dev.off()

# Load library
library(vegan)
library(pairwiseAdonis)
library(dplyr)
library(readxl)
library(ggplot2)
library(gridExtra)
library(multcompView)
library(tidyr)

# Read file
file = read_excel(choose.files())

# Add DV_Chl_a + DV_Chl_b column
file$`[DV_Chl_a+b]` <- file$`[DV_Chl_a]`+file$`[DV_Chl_b]`

# Filter sampling depth for surface data
file_filter <- filter(file, file$SamplingDepth < 5)

# Get pigment data
pigment <- select(file_filter, '[But fuco]','[Hex fuco]','[Allo]','[Fuco]',
                  '[Perid]','[Zea]','[DV_Chl_a+b]','[TChl]')

# Assign habitat & cruise labels
hbt <- factor(file_filter$Habitat,levels = c("RI","YPC","OPC","WPM","EPM","OPM","MOSW","OSW"),ordered=TRUE)
cruise <- factor(file_filter$Cruise)

# # Function to remove outliers
# outlier <- function(x){
#   x[x %in% boxplot.stats(x)$out] <- NA
#   return(x)
# }
# 
# for (i in colnames(testdata)){
#   testdata[[i]] <- outlier(testdata[[i]])
# }

# Function to replace missing values with zeros or median
myreplace <- function(testcol){
  for (i in levels(hbt)){
    #fill_value <- median(testcol[!is.na(testcol)&hbt==i])
    fill_value <- median(testcol[hbt==i],na.rm=TRUE)
    testcol[is.na(testcol)&hbt==i] <- fill_value
  }
  testcol[is.na(testcol)] <- 0
  return(testcol)
}

# Fill missing values for all columns
for (i in colnames(pigment)){
  pigment[[i]] <- myreplace(pigment[[i]])
}


# # Intergration with depth
# value <- c('[But fuco]','[Hex fuco]','[Allo]','[Fuco]','[Perid]','[Zea]','[DV_Chl_a+b]','[TChl]')
# my_cal <- c(0)
# for (i in unique(pigment$StationEvent)){
#   subdata <- pigment[pigment$StationEvent==i,]
#   for (a in 1:length(value)){
#     my_cal[a] <- integrate(subdata[[value[a]]],subdata$SamplingDepth,from=0,to=10)
#   }
#   print(i)
#   print(my_cal)
# }

# subdata <- pigment[pigment$StationEvent=='3.13',]
# test <- integrate(subdata$`[But fuco]`,subdata$SamplingDepth,from=0,to=10)

# Divide pigment by total chla
pigment <- pigment/pigment[['[TChl]']]
pigment <- select(pigment,!'[TChl]')

# Colnames
colnames(pigment) <- c('19\'BF','19\'HF','ALLO','FUCO','PERI','ZEA','DVCHLA+B')
#rownames(pigment) <- file$ID

# Get habitat defining variable data
#hbt_dv <- select(file,'SST','SSS','MLD','ChlMD','NAI')

## Chi square standardization
# The decostand function standardizes entries (transforms them relative to others)
# Chisquare standardization + Euclidian distance --> Chisquare distance

# First do a log scale
#pigment_log <- decostand(pigment,method="log",na.rm=TRUE)
# pigment_log <- pigment
# pigment_log[,c('19\'BF','19\'HF','ALLO','PERI','ZEA')] <- decostand(pigment_log[,c('19\'BF','19\'HF','ALLO','PERI','ZEA')],method="log",na.rm=TRUE)

# Then do a chisquare scale
pigment_chi <- decostand(pigment,method='chi.square',na.rm=TRUE)

# pigment_chi[,c('19\'BF','19\'HF','ALLO','PERI','ZEA')]<- decostand(pigment_chi[,c('19\'BF','19\'HF','ALLO','PERI','ZEA')],method='chi.square',na.rm=TRUE)
# pigment_chi <- decostand(pigment_chi,method="log")

## Ordination by NMDS
# Permutative technique (resampling) seeking to match plot distances with pairwise distances
# Stress ~ 0.05 = excellent fit
# Stress > 0.3 = does not represent acutual distances
nmds <- metaMDS(pigment_chi,distance ="euclidian")

# Set colors and shapes
co=c('gray','firebrick2','orange','yellow','green','purple','cyan','blue') # Color by habitat order
co2=c('black','black','red')
shape=c(24,21,23) # Shape by cruise order

# Plot & edit ordination
plot(nmds$points, bg=co[hbt],
     pch=shape[cruise], cex=1.2, main = "Pigment NMDS",
     xlab="NMDS1",ylab="NMDS2")
#legend("topright",legend=levels(hbt),col=co,pch=20)

# Connect the point, ordiellipse() or ordispider()
ordiellipse(nmds, group = hbt, label = TRUE)


## Bootstrapping and test for differences between groups (PERMANOVA)
# Create distance matrix
pigment_dist = vegdist(pigment_chi,method="euclidian")

# Test for significance
test <- adonis2(pigment_dist~hbt)
test
capture.output(test,file="HPLC_PERMANOVA.txt",append=F)
# P_value < 0.05 --> There are significant differences in the community structure among habitats
# R2_value --> How much is the variation in the community structure is explained by habitats

# Posthoc test
test <- pairwise.adonis(pigment_dist,hbt)
test
capture.output(test,file="HPLC_PERMANOVA.txt",append=TRUE)
## Another method
## Canonical Analysis of Principal Coordinate (CAP)
pigment_cap <- capscale(pigment_chi~hbt,distance="euclidian",sqrt.dist=TRUE,comm=TRUE)
ev <- as.data.frame(summary(eigenvals(pigment_cap,model="all"))) # Extract eigenvals of unconstrained model
ev_con <- as.data.frame(summary(eigenvals(pigment_cap,model="constrained"))) # Extract eigenvals of constrained model

# Plot & edit CAP
par(mar = c(5,5,2,2)) # Set plot margin 
par(mfrow=c(1,2))
plot(pigment_cap,type="n",scaling=3,correlation=TRUE,
     xlab=bquote("dbRDA1 ("*.(round(ev[2,1]*100,1))*"% of total variation,"~.(round(ev_con[2,1]*100,1))*"% of fitted variation)"),
     ylab=bquote("dbRDA3 ("*.(round(ev[2,3]*100,1))*"% of total variation,"~.(round(ev_con[2,3]*100,1))*"% of fitted variation)"),
     xlim=c(-1.5,1.2),
     ylim=c(-2,1.5),
     cex.lab=1.5,cex.axis=1.5
     )
scrs <- scores(pigment_cap,display="wa",scaling=3,choices=c(1,3))
scrs[,1] <- -scrs[,1]
scrs <- jitter(scrs,factor=2,amount=0.25)
points(scrs,bg=co[hbt],pch=shape[cruise],cex=2.5,col=co2[cruise],lwd=2)
#legend("topright",legend=levels(hbt),col=co,pch=20)


# Calculate Pearson correlation of species scores with ordination axes
corr <- cor(pigment_chi,scores(pigment_cap,choices=c(1,3),display="sites",scaling=3),method="pearson")

plot.default(corr,type="n",xlim=range(-1.5,1.5),ylim=range(-1.5,1.5),xaxt='n',yaxt='n',
             xlab=paste("Correlation with dbRDA1"),
             ylab=paste("Correlation with dbRDA3"),
             cex.lab=1.5,cex.axis=1.5)
axis(1, at = seq(-1,1,by=0.5),cex.axis=1.5)
axis(2, at = seq(-1,1,by=0.5),cex.axis=1.5)
abline(h=0,lty="dotted")
abline(v=0,lty="dotted")
arrows(0,0,-corr[,1],corr[,2],length=0.1,col='black',lwd=2)
lab <- ordiArrowTextXY(corr,rescale=FALSE)
text(-lab[,1],lab[,2],labels=rownames(corr),cex=1.5,col='black')

RsquareAdj(pigment_cap)

# Test for significance
test <- anova.cca(pigment_cap)
test
capture.output(test,file="HPLC_DBRDA.txt",append=F)
# Pairwise anova.cca, will mess up with pairwise.adonis, need to reload R
test <- BiodiversityR::multiconstrained(method="capscale",pigment_chi~hbt,data=as.data.frame(hbt))
test
capture.output(test,file="HPLC_DBRDA.txt",append=TRUE)



# Box plot
mybox <- function(dataset,x,y){
        p <- ggplot(dataset,aes(.data[[x]],.data[[y]]))
        # Setting base theme
        p <- p + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
                       panel.background = element_blank(), axis.line = element_line(colour = "black"))
        # Adding scatter plot with jittered data
        p <- p + geom_jitter(aes(colour=.data[["Habitat"]],fill=.data[["Habitat"]],shape=.data[["Cruise"]]),width=0.25,size=2,stroke=0.2) 
        # Drawing whisker box
        p <- p + geom_boxplot(outlier.shape = NA,alpha=0,lwd=0.35)
        # Change shape
        p <- p + scale_shape_manual(values=myshape)
        # Change border and fill colors
        p <- p + scale_color_manual(values=c("gray35","gray35","gray35","gray35","gray35","gray35","gray35","gray35"))
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

anova_letter <- function(dataset,x,y){
  ## Plot anova
  # analysis of variance
  anova <- aov(dataset[[y]]~dataset[[x]])
  # Tukey's test
  tukey <- TukeyHSD(anova)
  # compact letter display
  cld <- multcompLetters4(anova, tukey,reverse=T)
  cld <- cld$`dataset[[x]]`$Letters
  x_cor <- names(cld)
  y_cor <- (max(dataset[[y]])-min(dataset[[y]]))*0.1
  df <- data.frame(x_cor,y_cor,cld)
  df$x_cor <- as.numeric(factor(df$x_cor,levels = c("RI","YPC","OPC","WPM","EPM","OPM","MOSW","OSW"),ordered = TRUE))
  return(df)
}

temp <- pigment_chi
temp$Habitat <- hbt
temp$Cruise <- cruise
mycolor <- c('gray','red','orange','yellow','green','purple','cyan','blue')
myshape <- c(24,21,23)

p6 <- mybox(temp,'Habitat','19\'BF')+
  geom_text(data=anova_letter(temp,'Habitat','19\'BF'),aes(x=x_cor,y=max(temp$`19'BF`)+y_cor,label=cld))
p7 <- mybox(temp,'Habitat','19\'HF')+
  geom_text(data=anova_letter(temp,'Habitat','19\'HF'),aes(x=x_cor,y=max(temp$`19'HF`)+y_cor,label=cld))
p3 <- mybox(temp,'Habitat','ALLO')+
  geom_text(data=anova_letter(temp,'Habitat','ALLO'),aes(x=x_cor,y=max(temp$`ALLO`)+y_cor,label=cld))
p2 <- mybox(temp,'Habitat','FUCO')+
  geom_text(data=anova_letter(temp,'Habitat','FUCO'),aes(x=x_cor,y=max(temp$`FUCO`)+y_cor,label=cld))
p4 <- mybox(temp,'Habitat','PERI')+
  geom_text(data=anova_letter(temp,'Habitat','PERI'),aes(x=x_cor,y=max(temp$`PERI`)+y_cor,label=cld))
p5 <- mybox(temp,'Habitat','ZEA')+
  geom_text(data=anova_letter(temp,'Habitat','ZEA'),aes(x=x_cor,y=max(temp$`ZEA`)+y_cor,label=cld))
p1 <- mybox(temp,'Habitat','DVCHLA+B')+
  geom_text(data=anova_letter(temp,'Habitat','DVCHLA+B'),aes(x=x_cor,y=max(temp$`DVCHLA+B`)+y_cor,label=cld))
grid.arrange(p1,p2,p3,p4,p5,p6,p7,ncol=2,top="Raw")

test <- file[file$Habitat=='OPM',]
depth <- 100
plot(file$`[DV_Chl_a+b]`,file$SamplingDepth,col='green',ylim=rev(range(0:depth)))
abline(lm(file$SamplingDepth ~ file$`[DV_Chl_a+b]`), col = "green")
par(new=T)
plot(file$`[But fuco]`,file$SamplingDepth,col='red',ylim=rev(range(0:depth)),xaxt='n',yaxt='n',xlab='',ylab='')
par(new=T)
plot(file$`[Hex fuco]`,file$SamplingDepth,col='orange',ylim=rev(range(0:depth)),xaxt='n',yaxt='n',xlab='',ylab='')
par(new=T)
plot(file$`[Zea]`,file$SamplingDepth,col='blue',ylim=rev(range(0:depth)),xaxt='n',yaxt='n',xlab='',ylab='')
par(new=T)
plot(file$`[Perid]`,file$SamplingDepth,col='purple',ylim=rev(range(0:depth)),xaxt='n',yaxt='n',xlab='',ylab='')
par(new=T)
plot(file$`[Allo]`,file$SamplingDepth,col='black',ylim=rev(range(0:depth)),xaxt='n',yaxt='n',xlab='',ylab='')

