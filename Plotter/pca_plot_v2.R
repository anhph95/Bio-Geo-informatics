# Visualize PCA
# Clean workspace
rm(list=ls())
dev.off()


library(readxl)
library(ggplot2)
library(factoextra)

mydata <- read_excel(choose.files())
subdata <- as.data.frame(mydata[c('MLD','ChlMD','SSS','SST','NAI')])
row.names(subdata) <- mydata$StnEvent
subdata_std <- scale(subdata)

data_pca <- prcomp(subdata_std)
summary_pca <- summary(data_pca)

hbt <- factor(mydata$Habitat,levels = c("RI","YPC","OPC","WPM","EPM","OPM","MOSW","OSW"),ordered=TRUE)
cruise <- factor(mydata$Cruise,levels=c('KN197','MV1110','AT21-04','EN614','EN640','M174'),ordered = TRUE)

# Set colors and shapes
co=c('gray','firebrick2','orange','yellow','green','purple','cyan','blue','deeppink','purple','blue','cyan','burlywood4') # Color by habitat order
shape=c(21,21,21,25) # Shape by cruise order
testcol=c("gray35","gray35","gray35","gray35","gray35","brown1")

# Plot & edit PCA 1-2
par(mar = c(5,5,2,2)) # Set plot margin 
par(mfrow=c(1,2))
plot(-data_pca$x[,1],data_pca$x[,2],bg=co[hbt],pch=shape[cruise],cex=2,
     xlim=range(-4,5),ylim=range(-1.5,2),
     xlab=paste0("PCA1 (",round(summary_pca$importance[2,1]*100,1),"%)"),
     ylab=paste0("PCA2 (",round(summary_pca$importance[2,2]*100,1),"%)"),
     cex.lab=1.8,cex.axis=1.8,lwd=2
)
abline(h=0,lty="dotted")
abline(v=0,lty="dotted")
#legend("topright",legend=levels(hbt),col=co,pch=20)


# Calculate Pearson correlation of species scores with ordination axes
corr <- get_pca_var(data_pca)$coord

plot.default(corr,type="n",xlim=range(-1.5,1.5),ylim=range(-1.5,1.5),xaxt='n',yaxt='n',
             xlab=paste0("PCA1 (",round(summary_pca$importance[2,1]*100,1),"%)"),
             ylab=paste0("PCA2 (",round(summary_pca$importance[2,2]*100,1),"%)"),
             cex.lab=1.8,cex.axis=1.8)
axis(1, at = seq(-1,1,by=0.5),cex.axis=1.8)
axis(2, at = seq(-1,1,by=0.5),cex.axis=1.8)
abline(h=0,lty="dotted")
abline(v=0,lty="dotted")
arrows(0,0,-corr[,1],corr[,2],length=0.1,col='red',lwd=3)
#text(-corr[,1],corr[,2],labels=rownames(corr),cex=1.5,col='black')

# Plot & edit PCA 1-3
par(mar = c(5,5,2,2)) # Set plot margin 
par(mfrow=c(1,2))
plot(-data_pca$x[,1],data_pca$x[,3],bg=co[hbt],pch=shape[cruise],col=testcol[cruise],
     xlim=range(-5,5),ylim=range(-2.5,3.5),
     xlab=paste0("PCA1 (",round(summary_pca$importance[2,1]*100,1),"%)"),
     ylab=paste0("PCA3 (",round(summary_pca$importance[2,3]*100,1),"%)"),
     cex.lab=1.8,cex.axis=1.8,cex=2,lwd=2
)
abline(h=0,lty="dotted")
abline(v=0,lty="dotted")
#legend("topright",legend=levels(hbt),col=co,pch=20)
# Calculate Pearson correlation of species scores with ordination axes
corr <- get_pca_var(data_pca)$coord

plot.default(corr,type="n",xlim=range(-1.5,1.5),ylim=range(-1.5,1.5),xaxt='n',yaxt='n',
             xlab=paste0("PCA1 (",round(summary_pca$importance[2,1]*100,1),"%)"),
             ylab=paste0("PCA3 (",round(summary_pca$importance[2,3]*100,1),"%)"),
             cex.lab=1.8,cex.axis=1.8)
axis(1, at = seq(-1,1,by=0.5),cex.axis=1.8)
axis(2, at = seq(-1,1,by=0.5),cex.axis=1.8)
abline(h=0,lty="dotted")
abline(v=0,lty="dotted")
arrows(0,0,-corr[,1],corr[,3],length=0.1,col='red',lwd=3)

plot(NULL ,xaxt='n',yaxt='n',bty='n',ylab='',xlab='', xlim=0:1, ylim=0:1)
legend("topleft", legend=c('KN197','MV1110','AT21-04','EN614','EN640','M174'), pch=shape, pt.cex=2, cex=2, bty='n',
       col=testcol,fill=co)
mtext("Species", at=0.2, cex=2)

# Another way to plot
par(mfrow=c(1,1)) 
plot(-data_pca$x[,1],data_pca$x[,2],
     xlim=range(-4,5),ylim=range(-1.5,2),type='n',
     xlab=paste0("PCA1 (",round(summary_pca$importance[2,1]*100,1),"%)"),
     ylab=paste0("PCA2 (",round(summary_pca$importance[2,2]*100,1),"%)"),
     cex.lab=1.8,cex.axis=1.8,lwd=2
)
abline(h=0,lty="dotted")
abline(v=0,lty="dotted")
arrows(0,0,-corr[,1],corr[,2],length=0.1,col='black',lwd=2)
points(-data_pca$x[,1],data_pca$x[,2],
       bg=co[hbt],pch=shape[cruise],cex=2)

