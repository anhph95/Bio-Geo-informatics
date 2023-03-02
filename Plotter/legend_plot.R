
mycolor <- c("gray","red","orange","yellow","green","purple","cyan","blue")
myshape <- c(22,23,25,24,21,23)
testcol=c("gray35","gray35","gray35","gray35","gray35","brown1")
par(mfrow=c(2,1))
par(mar=c(0.5,0.5,0.5,0.5))
plot(NULL ,xaxt='n',yaxt='n',bty='n',ylab='',xlab='', xlim=0:1, ylim=0:1)
legend("center", legend=c('KN197','MV1110','AT21-04','EN614','EN640','M174'), pch=myshape, pt.cex=3, cex=2, bty='n',
       col=testcol,pt.lwd=3)
mtext("Cruise", cex=2,side=3,line=-2)

plot(NULL ,xaxt='n',yaxt='n',bty='n',ylab='',xlab='', xlim=0:1, ylim=0:1)
legend("center", legend=c('RI','YPC','OPC','WPM','EPM','OPM','MOW','OSW'), pt.cex=3, cex=2, bty='n',
       fill=mycolor,pt.lwd=3)
mtext("Habitat", cex=2,side=3)

