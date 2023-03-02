#hydrigraphic data 

library(readxl)
rm(list=ls())
dev.off()

hydrodata=read_excel(file.choose(),sheet=1)

# Filter NAs
hydrodata <- hydrodata[!is.na(hydrodata$Habitat),]

# Convert habitat to factor
hydrodata$Habitat <- factor(hydrodata$Habitat,levels=c('EPC','OPM','OSW'),ordered=TRUE)
# Create color vector for habitat
mycolor <- c('blue','red','orange')

# Filter by size fraction
data_200 <- hydrodata[hydrodata$Sizefraction=='200',]

# MLD
par(mar=c(5,7,4,4))
plot(data_200$MLD...10,data_200$d15N...13, las=1, cex.axis=1.3,ylim=c(0,10),xlim=c(0,125),
     cex.main=2,main=expression(" δ" ^15 * "N (‰)"),
     xlab="Mixed Layer Depth (m)",cex.lab=2,
     ylab=expression("200 (µm) δ"^15*"N (‰)"), pch=19,cex=1.3,col=mycolor[data_200$Habitat])

abline(lm(data_200$d15N...13~data_200$MLD...10))
