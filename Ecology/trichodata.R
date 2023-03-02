## Tricho data
# Clean workspace
rm(list=ls())
dev.off()

# Load library
library(vegan)
library(pairwiseAdonis)
library(dplyr)
library(readxl)
library(gridExtra)
library(ggplot2)
library(multcompView)
#library(BAT)

file <- read_excel(choose.files())

# Filter sampling depth for surface data
data <- filter(file, file$Depth < 150)

data <- filter(data, data$Habitat != 'NA')
#data <- filter(data, data$Cruise != 'KN197')

# Get cell counts
mydata <- select(data,
                 'Tricho_in_colony',
                 'Tricho_free',
                 #'Katagynemene',
                 'Richelia_R_clevii',
                 #'Richelia_G_cylindrus',
                 'Richelia_H_haukii',
                 'Richelia_H_membranaceus'
                 )

#' colnames(mydata) <- c('colonial Trichodesmium spp.',
#'                        'free Trichodesmium spp.',
#'                        #'Kata',
#'                        'Richelia-R. clevii',
#'                        #'RGC',
#'                        'Richelia-H. haukii',
#'                        'Richelia-H. membranaceus'
#' )

hbt <- factor(data$Habitat,levels=c('YPC','OPC','WPM','EPM','OSW'),ordered=TRUE)
cruise <- factor(data$Cruise,levels=c('KN197','MV1110','AT21-04'),ordered=TRUE)

# Fill NAs with 0s
mydata[is.na(mydata)] <- 0


# # Function to replace missing values with zeros or median
# myreplace <- function(testcol){
#   for (i in levels(hbt)){
#     #fill_value <- median(testcol[!is.na(testcol)&hbt==i])
#     fill_value <- median(testcol[hbt==i],na.rm=TRUE)
#     testcol[is.na(testcol)&hbt==i] <- fill_value
#   }
#   testcol[is.na(testcol)] <- 0
#   return(testcol)
# }
# 
# # Fill missing values for all columns
# for (i in colnames(mydata)){
#   mydata[[i]] <- myreplace(mydata[[i]])
# }

# mydata_fill_similar <- fill(mydata,method="median")
# mydata_fill_2 <- fill(mydata,method="w_regression",group=hbt,weight=dist(mydata))




# outlier <- function(x){
#   for (i in levels(hbt)){
#     x[x %in% boxplot.stats(x[hbt==i])$out & hbt==i] <- NA
#   }
#   
#   return(x)
# }
# 
# mydata_out <- mydata
# for (i in colnames(mydata_out)){
#   mydata_out[[i]] <- outlier(mydata_out[[i]])
# }
# # Delete rows with all NAs
# index <- rowSums(is.na(mydata_out)) != ncol(mydata_out)
# mydata_out <- mydata_out[index,]
# hbt <- hbt[index]

# # NA to 0
# #mydata <- mydata[rowSums(is.na(mydata)) != ncol(mydata), ]
# mydata[is.na(mydata)] <- 0
# hist(mydata$Richelia_H_membranaceus)

# Transform
data_log <- decostand(mydata,method='log',na.rm=TRUE)
#row.names(data_log) <- paste(data$AN_Number,data$Cruise,data$Station,sep="_")

#' 
#' nmds <- metaMDS(data_chi,distance='bray',k=2)
#' 
# Set colors and shapes
co=c("red","orange","yellow","green","blue") # Color by habitat order
shape=c(22,23,25) # Shape by cruise order
#' 
#' # Create distance matrix
#' data_dist = vegdist(data_chi,method="bray",na.rm=TRUE)
#' 
#' # Test for significance
#' adonis2(data_dist~hbt)
#' pairwise.adonis(data_dist,hbt)
#' 
mydata_cap <- capscale(data_log~hbt,distance="bray",sqrt.dist=TRUE,comm=TRUE)
ev <- as.data.frame(summary(eigenvals(mydata_cap,model="all"))) # Extract eigenvals of unconstrained model
ev_con <- as.data.frame(summary(eigenvals(mydata_cap,model="constrained"))) # Extract eigenvals of constrained model
# 
# # Plot & edit CAP
par(mar = c(5,5,2,2)) # Set plot margin
plot(mydata_cap,type='n',scaling=3,correlation=FALSE,
     xlab=bquote("dbRDA1 ("*{R^2}[constrained]~"="~.(round(ev_con[2,1]*100,1))*"%,"~{R^2}[total]~"="~.(round(ev[2,1]*100,1))*"%)"),
     ylab=bquote("dbRDA2 ("*{R^2}[constrained]~"="~.(round(ev_con[2,2]*100,1))*"%,"~{R^2}[total]~"="~.(round(ev[2,2]*100,1))*"%)"),
     xlim=c(-1.5,1.8),ylim=c(-1.2,2),
     main='Filter by missing values'
     )
# points(mydata_cap,"wa",scaling=3,bg=co[hbt],pch=shape[cruise],cex=1.3)
scrs <- scores(mydata_cap,display = "wa",scaling=3)
# scrs <- jitter(scrs,factor=2,amount=0.2)
points(scrs,bg=co[hbt],pch=shape[cruise],cex=1.3)
# #text(mydata_cap,display='species',scaling=3)
# # Calculate Pearson correlation of species scores with ordination axes
# corr <- cor(data_log,scores(mydata_cap,display="sites",scaling=3),method="pearson")
# par(mar = c(5,7,4,2))
#plot.default(corr,type="n",xlim=range(-1.2,1.2),ylim=range(-1.2,1.2),
#             xlab=paste("Correlation with dbRDA1"),
#             ylab=paste("Correlation with dbRDA2"))
#abline(h=0,lty="dotted")
#abline(v=0,lty="dotted")
arrows(0,0,corr[,1],corr[,2],length=0.05,lwd=1.2,col='black')
lab <- ordiArrowTextXY(corr,rescale=FALSE)
text(lab,labels=rownames(corr),cex=1,col='black')
#' #BiodiversityR::multiconstrained(method="capscale",data_log~hbt,data=as.data.frame(hbt),distance='bray')
#' 
# Filter capscale
scrs <- as.data.frame(scrs)
scrs_filter <- scrs[scrs$CAP2<1.3,]
mydata$Habitat <- factor(data$Habitat,levels=c('YPC','OPC','WPM','EPM','OSW'),ordered=TRUE)
mydata$Cruise <- factor(data$Cruise,levels=c('KN197','MV1110','AT21-04'),ordered=TRUE)
mydata$Depth <- data$Depth
rownames(mydata) <- paste(data$AN_Number,data$Cruise,data$Station,sep="_")
mydata_filter <- merge(mydata,scrs_filter,by=0)
mydata_filter <- mydata_filter[mydata_filter$Depth <= 10,]
#mydata_filter <- mydata_filter[mydata_filter$Cruise=='KN197',]
newdata <- select(mydata_filter,
                  'Tricho_in_colony',
                  'Tricho_free',
                  #'Katagynemene',
                  'Richelia_R_clevii',
                  #'Richelia_G_cylindrus',
                  'Richelia_H_haukii',
                  'Richelia_H_membranaceus'
                  )
colnames(newdata) <- c('colonial Trichodesmium spp.',
                       'free Trichodesmium spp.',
                       'Richelia-R. clevii',
                       'Richelia-H. haukii',
                       'Richelia-H. membranaceus'
                       )
hbt <- mydata_filter$Habitat
cruise <- mydata_filter$Cruise
# newdata <- newdata + 1
newdata <- decostand(newdata,method = 'log')
depth <- mydata_filter$Depth

nmds <- metaMDS(newdata,distance='bray')

# Plot & edit ordination
plot(nmds$points, bg=co[hbt],
     pch=shape[cruise], cex=1.2, main = "CLASS NMDS",
     xlab="NMDS1",ylab="NMDS2")

# Connect the point, ordiellipse() or ordispider()
ordiellipse(nmds, group = hbt, label = TRUE)

## Bootstrapping and test for differences between groups (PERMANOVA)
# Create distance matrix
data_dist = vegdist(mydata,method="bray",na.rm=T)

# Test for significance
# test <- adonis2(data_dist~hbt)
# test
#capture.output(test,file='Stats_cellcounts.txt',append=TRUE)
# P_value < 0.05 --> There are significant differences in the community structure among habitats
# R2_value --> How much is the variation in the community structure is explained by habitats

# Posthoc test
# test <- pairwise.adonis(data_dist,hbt)
# test
#capture.output(test,file='Stats_cellcounts.txt',append=TRUE)

## Capscale
mydata_cap <- capscale(newdata~hbt,distance="bray",sqrt.dist=TRUE)
ev <- as.data.frame(summary(eigenvals(mydata_cap,model="all"))) # Extract eigenvals of unconstrained model
ev_con <- as.data.frame(summary(eigenvals(mydata_cap,model="constrained"))) # Extract eigenvals of constrained model

# Plot & edit CAP
par(mar = c(5,5,2,2)) # Set plot margin 
par(mfrow=c(1,2))
plot(mydata_cap,type='n',scaling=3,correlation=TRUE,
     xlab=bquote("dbRDA1 ("*.(round(ev[2,1]*100,1))*"% of total variation,"~.(round(ev_con[2,1]*100,1))*"% of fitted variation)"),
     ylab=bquote("dbRDA2 ("*.(round(ev[2,2]*100,1))*"% of total variation,"~.(round(ev_con[2,2]*100,1))*"% of fitted variation)"),
     xlim=c(-2,1.2),ylim=c(-1.5,2),
     cex.lab=1.5,cex.axis=1.5
)
#points(mydata_cap,"wa",scaling=3,bg=co[hbt],pch=shape[cruise],cex=1.3)
scrs <- scores(mydata_cap,display = "wa",scaling=3)
scrs <- jitter(scrs,factor=2,amount=0.25)
points(scrs,bg=co[hbt],pch=shape[cruise],cex=2.5,lwd=2)
#text(mydata_cap,display='species',scaling=3)
# Calculate Pearson correlation of species scores with ordination axes
corr <- cor(newdata,scores(mydata_cap,display="sites",scaling=3),method="pearson")
# par(mar = c(5,7,4,2))
plot.default(corr,type="n",xlim=range(-1.5,1.5),ylim=range(-1.5,1.5),xaxt='n',yaxt='n',
             xlab=paste("Correlation with dbRDA1"),
             ylab=paste("Correlation with dbRDA2")
             ,cex.lab=1.5,cex.axis=1.5)
axis(1, at = seq(-1,1,by=0.5),cex.axis=1.5)
axis(2, at = seq(-1,1,by=0.5),cex.axis=1.5)
abline(h=0,lty="dotted")
abline(v=0,lty="dotted")
arrows(0,0,corr[,1],corr[,2],length=0.1,lwd=2,col='black')
lab <- ordiArrowTextXY(corr,rescale=FALSE)
text(lab,labels=rownames(corr),cex=1.5,col='black',font=3)

RsquareAdj(mydata_cap)

test <- anova.cca(mydata_cap)
#capture.output(test,file='Stats_cellcounts.txt',append=TRUE)

#test <- BiodiversityR::multiconstrained(method="capscale",newdata~hbt,data=as.data.frame(hbt),distance='bray')
capture.output(test,file='Stats_cellcounts.txt',append=TRUE)

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
        p <- p + theme(plot.margin = margin(0.5,0.5,0.5,2,"cm"))
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
  df$x_cor <- as.numeric(factor(df$x_cor,levels=c('YPC','OPC','WPM','EPM','OSW'),ordered = TRUE))
  return(df)
}


temp <- newdata
temp$Habitat <- hbt
temp$Cruise <- cruise
mycolor <- c("red","orange","yellow","green","blue")
myshape <- c(22,23,25)
p1 <- mybox(temp,'Habitat','colonial Trichodesmium spp.')+
  geom_text(data=anova_letter(temp,'Habitat','colonial Trichodesmium spp.'),aes(x=x_cor,y=max(temp$`colonial Trichodesmium spp.`)+y_cor,label=cld))
p2 <- mybox(temp,'Habitat','free Trichodesmium spp.')+
  geom_text(data=anova_letter(temp,'Habitat','free Trichodesmium spp.'),aes(x=x_cor,y=max(temp$`free Trichodesmium spp.`)+y_cor,label=cld))
p3 <- mybox(temp,'Habitat','Richelia-R. clevii')+
  geom_text(data=anova_letter(temp,'Habitat','Richelia-R. clevii'),aes(x=x_cor,y=max(temp$`Richelia-R. clevii`)+y_cor,label=cld))
p4 <- mybox(temp,'Habitat','Richelia-H. haukii')+
  geom_text(data=anova_letter(temp,'Habitat','Richelia-H. haukii'),aes(x=x_cor,y=max(temp$`Richelia-H. haukii`)+y_cor,label=cld))
p5 <- mybox(temp,'Habitat','Richelia-H. membranaceus')+
  geom_text(data=anova_letter(temp,'Habitat','Richelia-H. membranaceus'),aes(x=x_cor,y=max(temp$`Richelia-H. membranaceus`)+y_cor,label=cld))
#p6 <- mybox(temp,'Habitat','RGC')+
#  geom_text(data=anova_letter(temp,'Habitat','RGC'),aes(x=x_cor,y=max(temp$RGC)+y_cor,label=cld))
#p7 <- mybox(temp,'Habitat','Kata')+
#  geom_text(data=anova_letter(temp,'Habitat','Kata'),aes(x=x_cor,y=max(temp$Kata)+y_cor,label=cld))
grid.arrange(p1,p2,p3,p4,p5,ncol=2,top="fill")
#grid.arrange(p1,p2,p3,p4,p5,p7,ncol=2,top="fill")
mean(temp$`colonial Trichodesmium spp.`[temp$Habitat=="OSW"])
mean(temp$`colonial Trichodesmium spp.`[temp$Habitat=="EPM"])

mean((mydata[hbt==levels(hbt)[1],1]),na.rm=TRUE)
x<-mydata[hbt==levels(hbt)[1],1]
x
mydata
