# Clean workspace
rm(list=ls())
dev.off()

library(readxl)
library(ggplot2)
library(factoextra)
library(FactoMineR)
library(pvclust)

mydata <- read_excel(choose.files())
subdata <- as.data.frame(mydata[c('MLD','ChlMD','SSS','SST','NAI')])
row.names(subdata) <- mydata$StnEvent
test <- t(scale(subdata))
fit <- pvclust(test,method.hclust = 'ward.D',parallel =T)
plot(fit)
pvrect(fit,alpha=0.5)
## HCPC
# PCA
subdata_std <- scale(subdata)
data.pca <- PCA(subdata_std,ncp=3)
# Variance explained
fviz_screeplot(data.pca, addlabels = TRUE) 
# Contribution of variable to PCs
fviz_contrib(data.pca, choice = "var", axes = 1)
fviz_contrib(data.pca, choice = "var", axes = 2)
fviz_contrib(data.pca, choice = "var", axes = 3)

fviz_nbclust(subdata_std, hcut, method = "gap_stat",nboot=100)
fviz_nbclust(subdata_std, hcut, method = "silhouette",nboot=100)
fviz_nbclust(subdata_std, hcut, method = "wss",nboot=100)

hbt <- factor(mydata$Habitat,levels=c('RI','YPC','OPC','WPM','EPM','OPM','DW','OSW'),ordered = TRUE)
mycolor <- c("gray","red","orange","yellow","green","purple","cyan","blue")
test <- prcomp(subdata_std)
pca3d(test,group=hbt,col=mycolor[hbt],biplot=T,shape='sphere',axes.color="black",show.axes=T)
snapshotPCA3d("testfile.png")
# HCA
data.hca <- HCPC(data.pca,method='ward',nb.clust=8,metric="euclidean",description=TRUE)


fviz_dend(data.hca,cex = 0.7,palette= c("red","orange","cyan3","gold2","chartreuse3","purple","blue"), k = 7, color_labels_by_k = TRUE)
cluster.df <- data.frame(data.hca$data.clust)
cluster.df$habitat <- factor(cluster.df$clust,labels=c("YPC","OPC","WPM","WPM?","OPM","EPM?","EPM","OSW"))
write.csv(cluster.df, "hcpc_!SST.csv", row.names = TRUE, col.names = TRUE)

fviz_cluster(data.hca, geom = "point")
?fviz_cluster

#sigclust
suppressPackageStartupMessages(library("sigclust2"))
test <- shc(subdata_std,alpha=0.05)
tail(test$p_norm,10)
?pvclust
