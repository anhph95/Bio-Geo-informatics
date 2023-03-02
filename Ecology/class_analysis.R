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
library(pairwiseAdonis)
library(BiodiversityR)

# Read file
data <- read_excel(choose.files())

# Filter surface data
data_surface <- filter(data,data$DepSM<5)

# Extract class data
data_class <- select(data_surface,'Chl_G','Fpe1/Fchl','Fpe2/Fchl','Fpe3/Fchl','Fv/Fm_G')
colnames(data_class) <- c('Chl a','PE-1','PE-2','PE-3','Fv/Fm')
#rownames(data_class) <- data_surface$ID


# Factor
hbt <- factor(data_surface$Habitat,levels=c('YPC','OPC','WPM','OPM','OSW'),ordered=T)
cruise <- factor(data_surface$Cruise,levels=c('EN614','EN640'),ordered=TRUE)

## Chi square standardization
# The decostand function standardizes entries (transforms them relative to others)
# Chisquare standardization + Euclidian distance --> Chisquare distance
class_chi <- decostand(data_class,method='chi.square',na.rm=TRUE)

## Ordination by NMDS
# Permutative technique (resampling) seeking to match plot distances with pairwise distances
# Stress ~ 0.05 = excellent fit
# Stress > 0.3 = does not represent acutual distances
nmds <- metaMDS(class_chi,distance ="euclidian")

# Set colors and shapes
co=c("red","orange","yellow","purple","blue") # Color by habitat order
shape=c(24,21) # Shape by cruise order

# Plot & edit ordination
plot(nmds$points, bg=co[hbt],
     pch=shape[cruise], cex=1.2, main = "CLASS NMDS",
     xlab="NMDS1",ylab="NMDS2")

# Connect the point, ordiellipse() or ordispider()
ordiellipse(nmds, group = hbt, label = TRUE)

## Bootstrapping and test for differences between groups (PERMANOVA)
# Create distance matrix
class_dist = vegdist(class_chi,method="euclidian")

# Test for significance
test <- adonis2(class_dist~hbt)
capture.output(test,file='ALF_stats.txt',append=F)
# P_value < 0.05 --> There are significant differences in the community structure among habitats
# R2_value --> How much is the variation in the community structure is explained by habitats


# Posthoc test
test <- pairwise.adonis(class_dist,hbt,perm=999)
capture.output(test,file='ALF_stats.txt',append=TRUE)
## Another method
## Canonical Analysis of Principal Coordinate (CAP)
class_cap <- capscale(class_chi~hbt,distance="euclidian",sqrt.dist=TRUE,comm=TRUE)
ev <- as.data.frame(summary(eigenvals(class_cap,model="all"))) # Extract eigenvals of unconstrained model
ev_con <- as.data.frame(summary(eigenvals(class_cap,model="constrained"))) # Extract eigenvals of constrained model

# Plot & edit CAP

par(mar = c(5,5,2,2)) # Set plot margin
par(mfrow=c(1,2))
plot(class_cap,type='n',scaling=3,correlation=TRUE,
     xlab=bquote("dbRDA1 ("*.(round(ev[2,1]*100,1))*"% of total variation,"~.(round(ev_con[2,1]*100,1))*"% of fitted variation)"),
     ylab=bquote("dbRDA2 ("*.(round(ev[2,3]*100,1))*"% of total variation,"~.(round(ev_con[2,3]*100,1))*"% of fitted variation)"),
     xlim=c(-1.5,1.2),ylim=c(-1,2),
     cex.lab=1.5,cex.axis=1.5
     )
#points(class_cap,"wa",scaling=3,bg=co[hbt],pch=shape[cruise],cex=1.3)
scrs <- scores(class_cap,display = "wa",scaling=3,choices=c(1,3))
scrs[,1] <- -scrs[,1]
scrs <- jitter(scrs,factor=2,amount=0.25)
points(scrs,bg=co[hbt],pch=shape[cruise],cex=2.5,lwd=2)
# Calculate Pearson correlation of species scores with ordination axes
corr <- cor(class_chi,scores(class_cap,display="sites",scaling=3,choices=c(1,3)),method="pearson")
# par(mar = c(5,7,4,2))
plot.default(corr,type="n",xlim=range(-1.5,1.5),ylim=range(-1.5,1.5),xaxt='n',yaxt='n',
             xlab=paste("Correlation with dbRDA1"),
             ylab=paste("Correlation with dbRDA2"),
             cex.lab=1.5,cex.axis=1.5)
axis(1, at = seq(-1,1,by=0.5),cex.axis=1.5)
axis(2, at = seq(-1,1,by=0.5),cex.axis=1.5)
abline(h=0,lty="dotted")
abline(v=0,lty="dotted")
arrows(0,0,-corr[,1],corr[,2],length=0.1,lwd=2,col='black')
corr[,1] <- -corr[,1]
lab <- ordiArrowTextXY(corr,rescale=FALSE)
text(lab,labels=rownames(corr),cex=1.5,col='black')

RsquareAdj(class_cap)

# Test for significance
test <- anova.cca(class_cap)
capture.output(test,file='class_dbrda.txt',append=F)
# Pairwise anova.cca, will mess up with pairwise.adonis, need to reload R
test <- BiodiversityR::multiconstrained(method="capscale",class_chi~hbt,data=as.data.frame(hbt))
capture.output(test,file='class_dbrda.txt',append=TRUE)

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
  df$x_cor <- as.numeric(factor(df$x_cor,levels=c('YPC','OPC','WPM','OPM','OSW'),ordered = TRUE))
  return(df)
}

temp <- data_class
temp$Habitat <- hbt
temp$Cruise <- cruise
mycolor <- c("red","orange","yellow","purple","blue")
myshape <- c(24,21)
p1 <- mybox(temp,'Habitat','PE-1')+
  geom_text(data=anova_letter(temp,'Habitat','PE-1'),aes(x=x_cor,y=max(temp$`PE-1`)+y_cor,label=cld))
p2 <- mybox(temp,'Habitat','PE-2')+
  geom_text(data=anova_letter(temp,'Habitat','PE-2'),aes(x=x_cor,y=max(temp$`PE-2`)+y_cor,label=cld))
p3 <- mybox(temp,'Habitat','PE-3')+
  geom_text(data=anova_letter(temp,'Habitat','PE-3'),aes(x=x_cor,y=max(temp$`PE-1`)+y_cor,label=cld))
p4 <- mybox(temp,'Habitat','Chl a')+
  geom_text(data=anova_letter(temp,'Habitat','Chl a'),aes(x=x_cor,y=max(temp$`Chl a`)+y_cor,label=cld))
p5 <- mybox(temp,'Habitat','Fv/Fm')+
  geom_text(data=anova_letter(temp,'Habitat','Fv/Fm'),aes(x=x_cor,y=max(temp$`Fv/Fm`)+y_cor,label=cld))
grid.arrange(p1,p2,p3,p4,p5,ncol=2)
# 
# par(mfrow=c(1,1))
# test.hbt <- as.data.frame(hbt)
# test.model <- CAPdiscrim(class_chi~hbt,dist="euclidian",data=test.hbt)
# test.model
# plot1 <- ordiplot(test.model,choices=c(1,2),scaling="species")
# 
# 
# test.clust <- pvclust::pvclust(t(class_chi),method.hclust = "ward.D",method.dist="euclidian")
# plot(test.clust)
# pvclust::pvrect(test.clust,alpha=0.7,pv="au")
# ordicluster(test.plot,cluster=as.hclust(test.clust$hclust))
# test.plot <- ordiplot(class_cap,scaling=3,correlation=T,type="n")
# test.den <- as.dendrogram(as.hclust(test.clust$hclust))
# plot(test.den)
# 
# library(ggplot2)
# library(ggdendro)
# 
# ddata_x <- dendro_data(test.den)
# p2 <- ggplot(segment(ddata_x)) +
#   geom_segment(aes(x=x, y=y, xend=xend, yend=yend))
# p2
# labs <- label(ddata_x)
# labs
# labs$group <- hbt
# labs
# p2 + geom_text(data=label(ddata_x),
#                aes(label=data_surface$ID, x=x, y=0, colour=labs$group),angle=90,hjust=1,c)+
#   scale_colour_manual(values=co)

test <- subset(data_surface,data_surface$Habitat %in% c("YPC","OPC"))
test
mean(test$Chl_G)
sd(test$Chl_G)/(sqrt(length(test$Chl_G)))
sd(test$Chl_G)/sqrt(length((test$Chl_G)))
plot(test$Chl_G)
test$Chl_G
se(test$Chl_G)
