#=========================================
#
# File Name : plot_TPD.R
# Created By : awright
# Creation Date : 18-04-2023
# Last Modified : Wed 19 Apr 2023 08:55:57 AM CEST
#
#=========================================

filename=commandArgs(T)[1]
covmat=commandArgs(T)[2]
tpdfilename=commandArgs(T)[3]
ntomo=as.numeric(commandArgs(T)[4])
ncosebi=as.numeric(commandArgs(T)[5])
sampler=commandArgs(T)[6]

#Read in the data vector 
dat<-helpRfuncs::read.file(file=filename)
cov<-helpRfuncs::read.file(file=covmat)
cov<-as.matrix(cov)

#Read the theory predictive distributions 
tpd<-helpRfuncs::read.chain(file=tpdfilename)
samps<-helpRfuncs::read.chain(file=sub("_list_",paste0("_",sampler,"_"),tpdfilename))
tpdweight<-samps$weight
cols<-colnames(tpd)
cols<-cols[which(grepl("scale_cuts_output",cols,ignore.case=T))]
tpd<-as.matrix(tpd[,cols,with=F])

mat<-matrix(0,nrow=ntomo+1,ncol=ntomo+1)
cumul<-0
for (i in 1:ntomo) { 
  mat[i,i:ntomo+1]<-i:ntomo + cumul
  cumul<-cumul+length(i:ntomo)-1
}
cumul<-cumul+ntomo
for (i in 1:ntomo) {
  mat[i:ntomo+1,i]<-i:ntomo + cumul
  cumul<-cumul+length(i:ntomo)-1
}
layout(mat)
par(mar=c(0,0,0,0),oma=c(5,5,5,5))
ncorr<-sum(seq(ntomo))

mfact<-ceiling(median(log10(abs(dat$V1))))

start=0
ylim=range(c(dat+sqrt(diag(cov))*3,dat-sqrt(diag(cov))*3))/10^mfact
for (i in 1:ntomo) { 
  for (j in i:ntomo) { 
    ind<-start+1:ncosebi
    #Plot the data vector 
    magicaxis::magplot(dat$V1[ind]/10^mfact,xlab='',ylab='',type='n',side=1:4,labels=c(i==j,F,i==1,j==ntomo),
                       ylim=ylim,xlim=c(0.5,ncosebi+0.5),grid=F)
    abline(h=0,lwd=2)
    #poly.x<-c(1:length(dat$V1),rev(1:length(dat$V1)))
    #poly.y<-c(dat$V1+sqrt(diag(cov)),rev(dat$V1-sqrt(diag(cov))))
    #polygon(poly.x,poly.y,col='grey',border=NA)
    #lines(dat$V1,lwd=2)
    points(dat$V1[ind]/10^mfact,pch=20,cex=0.8,lwd=2)
    magicaxis::magerr(x=1:length(ind),dat$V1[ind]/10^mfact,yhi=sqrt(diag(cov)[ind])/10^mfact,ylo=sqrt(diag(cov)[ind])/10^mfact,lwd=2)

    #Add the samples 
    tpdsamp<-tpd[sample(nrow(tpd),prob=tpdweight,size=500),]
    matplot(1:length(ind),t(tpdsamp)[ind,]/10^mfact,add=T,type='l',col=hsv(a=0.1),lty=1)
    #abline(v=seq(0,75,by=5),lty=2,col='blue')
    start=start+ncosebi
  }
}
mtext(side=3,text='COSEBIs n',line=2.5,outer=T)
mtext(side=4,text=bquote(E[n]*"x10"^.(mfact)),line=2.5,outer=T)


start=0
for (i in 1:ntomo) { 
  for (j in i:ntomo) { 
    ind<-start+1:ncosebi
    #Plot the data vector 
    magicaxis::magplot(1:length(ind),xlab='',ylab='',type='n',ylim=c(-4,4),xlim=c(0.5,ncosebi+0.5),side=1:4,labels=c(j==ntomo,i==1,i==j,F),grid=F)
    #poly.x<-c(1:length(ind),rev(1:length(ind)))
    #poly.y<-c(rep(1,length(ind)),rep(-1,length(ind)))
    #polygon(poly.x,poly.y,col='grey',border=NA)
    abline(h=0,lwd=2)
    points(rep(0,length(ind)),pch=20,cex=0.8,lwd=2)
    magicaxis::magerr(x=1:length(ind),rep(0,length(ind)),yhi=rep(1,length(ind)),ylo=rep(-1,length(ind)),lwd=2)
    
    #Add the samples 
    tpdsamp<-tpd[sample(nrow(tpd),prob=tpdweight,size=500),]
    matplot(1:length(ind),(t(tpdsamp)[ind,]-dat$V1[ind])/sqrt(diag(cov)[ind]),add=T,type='l',col=hsv(a=0.1),lty=1)
    #abline(v=seq(0,75,by=5),lty=2,col='blue')
    start=start+ncosebi
  }
}
mtext(side=1,text='COSEBIs n',line=2.5,outer=T)
mtext(side=2,text=expression((E[n]^dat-E[n]^th)/sigma["En,dat"]),line=2.5,outer=T)

