#=========================================
#
# File Name : plot_HC_nz.R
# Created By : awright
# Creation Date : 23-03-2023
# Last Modified : Thu 23 Mar 2023 10:18:37 AM CET
#
#=========================================

#Get the filelist from input
inputs<-commandArgs(T)
filelist<-inputs
outputbase<-helpRfuncs::vecsplit(filelist[1],by='/')
outputbase<-paste(outputbase[-length(outputbase)],collapse='/')
#Setup the layout image
npanel<-ceiling(length(filelist)/3)*3

#Output the valid Nz plot {{{
png(file=paste0(outputbase,"_HCoptim_validNz.png"),height=2.5*(npanel/3)*220,width=10*220,res=220)
#set up panels 
layout(matrix(1:npanel,ncol=3,byrow=T))
par(mar=c(0,0,0,0),oma=c(4,4,1,1))
#Do we need an in-panel legend?
inplot=(npanel==length(filelist))
#loop over the inputs 
for (tomo in 1:length(filelist)) {
  #load the dataset 
  load(filelist[tomo])
  #With the dataset:
  with(HCoptim,{
    #Compute the possibly valid HCs
    poss.index<-which(abs(muz-rev(muz)[1])<=0.01)
    #Remove any gaps 
    gap<-which(diff(poss.index)!=1)
    if (length(gap)>0) {
      poss.index<-poss.index[max(gap):length(poss.index)]
    }
    #Set up the plot panel
    magicaxis::magplot(1,xlim=c(0,1.6),ylim=c(0,7),type='n',xlab='',ylab='',side=1:4,labels=c(tomo>length(filelist)-3,tomo%%3==1,F,F))
    #Loop over the valid HCs
    for (i in poss.index) {
      #Draw the non-QC'd Nz approximation
      lines(helpRfuncs::densityf(muz.train[i,],weight=(ct.train*wt.final)[i,]/sum((ct.train*wt.final)[i,],na.rm=T),bw=0.1/sqrt(12),kern='rect',from=0,to=1.5,na.rm=T),col=hsv(v=0,a=0.1),lwd=2)
    }
    for (i in poss.index) {
      #Draw the QC'd Nz approximation
      lines(helpRfuncs::densityf(muz.train[i,],weight=(ct.train*qc.vals*wt.final)[i,]/sum((ct.train*qc.vals*wt.final)[i,],na.rm=T),bw=0.1/sqrt(12),kern='rect',from=0,to=1.5,na.rm=T),col=hsv(v=1,a=0.1),lwd=2)
    }
    #If we want an inpanel legend, draw it
    if (inplot & tomo==1) {
      legend('topright',legend=c("without QC","with QC"),title='valid HC Nz:',lwd=2,col=c('black','red'),lty=1,bty='n',inset=0.1)
    }
})
}
#if we want a stand-alone legend, draw it 
if (!inplot) {
  plot(1,axes=F,xlab='',ylab='',labels=F,type='n')
  legend('center',legend=c("without QC","with QC"),title='valid HC Nz:',lwd=2,col=c('black','red'),lty=1,bty='n',cex=1.5)
}
#Add the axes labels 
mtext(side=1,outer=T,text="redshift",line=3)
mtext(side=2,outer=T,text="PDF",line=2.5)
#}}}

#Output the change-in-mean-z plot {{{
png(file=paste0(outputbase,"_HCoptim_muz.png"),height=2.5*(npanel/3)*220,width=10*220,res=220)
#set up panels 
layout(matrix(1:npanel,ncol=3,byrow=T))
par(mar=c(0,0,0,0),oma=c(4,4,1,1))
#Do we need an in-panel legend?
inplot=(npanel==length(filelist))
#loop over the inputs 
for (tomo in 1:length(filelist)) {
  #load the dataset 
  load(filelist[tomo])
  #With the dataset:
  with(HCoptim,{
    #Compute the possibly valid HCs
    poss.index<-which(abs(muz-rev(muz)[1])<=0.01)
    #Remove any gaps 
    gap<-which(diff(poss.index)!=1)
    if (length(gap)>0) {
      poss.index<-poss.index[max(gap):length(poss.index)]
    }
    #Set up the plot panel
    plot(1,xlim=c(1,max(HC.steps)),ylim=c(-0.1,0.1),type='n',xlab='',ylab='',axes=F,labels=F)
    #Show the "good" region
    rect(xl=-10,xr=max(HC.steps)*1.1,yb=-0.01,yt=0.01,col='grey',border=NA)
    #Add the axes 
    magicaxis::magaxis(xlab='',ylab='',side=1:4,labels=c(tomo>length(filelist)-3,tomo%%3==1,F,F))
    #Plot the mean z's vs HC
    vals<-rowSums(muz.train*ct.train,na.rm=T)/rowSums(ct.train,na.rm=T)
    lines(HC.steps,vals-rev(vals)[1],col=hsv(v=0,a=1),lwd=2,lty=3)
    vals<-rowSums(muz.train*ct.train*wt.final,na.rm=T)/rowSums(ct.train*wt.final,na.rm=T)
    lines(HC.steps,vals-rev(vals)[1],col=hsv(v=0,a=1),lwd=2)
    vals<-rowSums(muz.train*ct.train*qc.vals*wt.final,na.rm=T)/rowSums(ct.train*qc.vals*wt.final,na.rm=T)
    lines(HC.steps,vals-rev(vals)[1],col=hsv(v=1,a=1),lwd=2)
    #If we want an inpanel legend, draw it
    if (inplot & tomo==1) {
      legend('topright',legend=c("without QC","with QC","of training sample"),title='Change in reconstructed mean z:',lwd=2,col=c('black','red','black'),lty=c(1,1,3),bty='n',inset=0.1,cex=1.3)
    }
})
}
#if we want a stand-alone legend, draw it 
if (!inplot) {
  plot(1,axes=F,xlab='',ylab='',labels=F,type='n')
  legend('center',legend=c("without QC","with QC","of training sample"),title='Change in reconstructed mean z:',lwd=2,col=c('black','red','black'),lty=c(1,1,3),bty='n',cex=1.3)
}
#Add the axes labels 
mtext(side=1,outer=T,text="Number of clusters",line=3)
mtext(side=2,outer=T,text=expression(mu[z]-mu["z,maxHC"]),line=2.5)
#}}}

#Output the change-in-neff plot {{{
png(file=paste0(outputbase,"_HCoptim_neff.png"),height=2.5*(npanel/3)*220,width=10*220,res=220)
#set up panels 
layout(matrix(1:npanel,ncol=3,byrow=T))
par(mar=c(0,0,0,0),oma=c(4,4,1,1))
#Do we need an in-panel legend?
inplot=(npanel==length(filelist))
#loop over the inputs 
for (tomo in 1:length(filelist)) {
  #load the dataset 
  load(filelist[tomo])
  #With the dataset:
  with(HCoptim,{
    #Compute the possibly valid HCs
    poss.index<-which(abs(muz-rev(muz)[1])<=0.01)
    #Remove any gaps 
    gap<-which(diff(poss.index)!=1)
    if (length(gap)>0) {
      poss.index<-poss.index[max(gap):length(poss.index)]
    }
    #Set up the plot panel
    magicaxis::magplot(1,xlim=c(1,max(HC.steps)),ylim=c(0.4,1.0),type='n',xlab='',ylab='',side=1:4,labels=c(tomo>length(filelist)-3,tomo%%3==1,F,F))
    #Plot the neff vs HC
    rawneff<-rowSums(ct.refr,na.rm=T)^2/rowSums(ctsq.refr,na.rm=T)
    vals<-rowSums(ct.refr*ifelse(wt.final>0,1,0),na.rm=T)^2/rowSums(ctsq.refr*ifelse(wt.final>0,1,0),na.rm=T)
    lines(HC.steps,vals/rawneff,col=hsv(v=0,a=1),lwd=2,lty=3)
    vals<-rowSums(ct.refr*qc.vals*ifelse(wt.final>0,1,0),na.rm=T)^2/rowSums(ctsq.refr*qc.vals*ifelse(wt.final>0,1,0),na.rm=T)
    lines(HC.steps,vals/rawneff,col=hsv(v=1,a=1),lwd=2,lty=3)
    #If we want an inpanel legend, draw it
    if (inplot & tomo==1) {
      legend('topright',legend=c("without QC","with QC"),title='Change in n_eff:',lwd=2,col=c('black','red'),lty=c(1,1),bty='n',inset=0.1,cex=1.3)
    }
})
}
#if we want a stand-alone legend, draw it 
if (!inplot) {
  plot(1,axes=F,xlab='',ylab='',labels=F,type='n')
  legend('center',legend=c("without QC","with QC"),title='Change in n_eff:',lwd=2,col=c('black','red'),lty=c(1,1),bty='n',inset=0.1,cex=1.3)
}
#Add the axes labels 
mtext(side=1,outer=T,text="Number of clusters",line=3)
mtext(side=2,outer=T,text=expression(n[eff]^gold/n[eff]),line=2.5)
#}}}

