#=========================================
#
# File Name : plot_HC_nz.R
# Created By : awright
# Creation Date : 23-03-2023
# Last Modified : Wed 07 Jun 2023 12:49:32 PM CEST
#
#=========================================

#Get the filelist from input
inputs<-commandArgs(TRUE) 

#Interpret the command line options 
while (length(inputs)!=0) {
  while (length(inputs)!=0 && inputs[1]=='') { inputs<-inputs[-1] }  
  if (!grepl('^-',inputs[1])) {
    print(inputs)
    stop(paste("Incorrect options provided!"))
  }
  #/*fend*/}}}
  if (inputs[1]=='-i') { 
    #Read the input file(s) /*fold*/ {{{
    inputs<-inputs[-1]
    if (any(grepl('^-',inputs))) { 
      filelist<-inputs[1:(which(grepl('^-',inputs))[1]-1)]
      inputs<-inputs[-(1:(which(grepl('^-',inputs))[1]-1))]
    } else { 
      filelist<-inputs
      inputs<-NULL
    } 
    #/*fold*/}}}
  } else if (inputs[1]=='--binstrings') { 
    #Read the input catalogue(s) /*fold*/ {{{
    inputs<-inputs[-1]
    if (any(grepl('^-',inputs))) { 
      binstrings<-inputs[1:(which(grepl('^-',inputs))[1]-1)]
      inputs<-inputs[-(1:(which(grepl('^-',inputs))[1]-1))]
    } else { 
      binstrings<-inputs
      inputs<-NULL
    } 
    #/*fold*/}}}
  } else {
    stop(paste("Unknown option",inputs[1]))
  }
}
outputbase<-helpRfuncs::vecsplit(filelist[1],by='/')
outputbase<-paste(outputbase[-length(outputbase)],collapse='/')
#Setup the layout image
npanel<-ceiling(length(binstrings)/3)*3
cat(paste("using",npanel,"panels\n"))
#Define the colors used 
col<-RColorBrewer::brewer.pal(8,"Set2")[c(1:3,6)]

#Output the valid Nz plot {{{
cat("Plotting HC Hz\n")
png(file=paste0(outputbase,"_HCoptim_validNz.png"),height=2.5*(npanel/3)*220,width=10*220,res=220)
#set up panels 
layout(matrix(1:npanel,ncol=3,byrow=T))
par(mar=c(0,0,0,0),oma=c(4,4,1,1))
#Do we need an in-panel legend?
inplot=(npanel==length(binstrings))
#initialise the progressbar 
pb<-txtProgressBar(style=3,min=0,max=length(filelist))
count<-0
#loop over the inputs 
for (tomo in 1:length(binstrings)) {
  #Get the files in this bin 
  binfiles<-which(grepl(binstrings[tomo],filelist,fixed=T))
  #Set up the plot panel
  magicaxis::magplot(1,xlim=c(0,1.6),ylim=c(0,7),type='n',xlab='',ylab='',side=1:4,labels=c(tomo>length(binstrings)-3,tomo%%3==1,F,F))
  if (length(binfiles)==0) { next }
  #Define the alpha
  alpha<-1/min(20,length(binfiles))
  for (file in binfiles) {
    #Update progress bar 
    count=count+1
    setTxtProgressBar(pb,count)
    #load the dataset 
    load(filelist[file])
    #With the dataset:
    with(HCoptim,{
      #Compute the possibly valid HCs
      poss.index<-which(abs(muz-rev(muz)[1])<=0.01)
      #Remove any gaps 
      gap<-which(diff(poss.index)!=1)
      if (length(gap)>0) {
        poss.index<-poss.index[max(gap):length(poss.index)]
      }
      #Loop over the valid HCs
      for (i in poss.index) {
        #Draw the non-QC'd Nz approximation
        lines(helpRfuncs::densityf(muz.train[i,],weight=(ct.train*wt.final)[i,]/sum((ct.train*wt.final)[i,],na.rm=T),bw=0.1/sqrt(12),kern='rect',from=0,to=1.5,na.rm=T),col=seqinr::col2alpha(col[1],a=alpha),lwd=2)
      }
      for (i in poss.index) {
        #Draw the QC'd Nz approximation
        lines(helpRfuncs::densityf(muz.train[i,],weight=(ct.train*qc.vals*wt.final)[i,]/sum((ct.train*qc.vals*wt.final)[i,],na.rm=T),bw=0.1/sqrt(12),kern='rect',from=0,to=1.5,na.rm=T),col=seqinr::col2alpha(col[2],a=alpha),lwd=2)
      }
      #If we want an in-panel legend, draw it
      if (inplot & tomo==1) {
        legend('topright',legend=c("without QC","with QC"),title='valid HC Nz:',lwd=2,col=c(col[1],col[2]),lty=1,bty='n',inset=0.1)
      }
    })
  }
}
close(pb)
#if we want a stand-alone legend, draw it 
if (!inplot) {
  plot(1,axes=F,xlab='',ylab='',labels=F,type='n')
  legend('center',legend=c("without QC","with QC"),title='valid HC Nz:',lwd=2,col=col[1:2],lty=1,bty='n',cex=1.5)
}
#Add the axes labels 
mtext(side=1,outer=T,text="redshift",line=3)
mtext(side=2,outer=T,text="PDF",line=2.5)
dev.off()
#}}}

#Output the change-in-mean-z plot {{{
cat("Plotting HC mean z\n")
png(file=paste0(outputbase,"_HCoptim_muz.png"),height=2.5*(npanel/3)*220,width=10*220,res=220)
#set up panels 
layout(matrix(1:npanel,ncol=3,byrow=T))
par(mar=c(0,0,0,0),oma=c(4,4,1,1))
#Do we need an in-panel legend?
inplot=(npanel==length(binstrings))
#initialise the progressbar 
pb<-txtProgressBar(style=3,min=0,max=length(filelist))
count<-0
#loop over the inputs 
for (tomo in 1:length(binstrings)) {
  #Get the files in this bin 
  binfiles<-which(grepl(binstrings[tomo],filelist,fixed=T))
  if (length(binfiles)==0) { 
    plot(1,xlim=c(1,10),ylim=c(-0.1,0.1),type='n',xlab='',ylab='',axes=F,labels=F)
    magicaxis::magaxis(xlab='',ylab='',side=1:4,labels=c(tomo>length(binstrings)-3,tomo%%3==1,F,F))
    next 
  }
  #Define the alpha
  alpha<-1/min(20,length(binfiles))
  #Set up the plot panel
  load(filelist[binfiles[1]])
  plot(1,xlim=c(1,max(HCoptim$HC.steps)),ylim=c(-0.1,0.1),type='n',xlab='',ylab='',axes=F,labels=F)
  #Show the "good" region
  rect(xl=-10,xr=max(HCoptim$HC.steps)*1.1,yb=-0.01,yt=0.01,col='grey',border=NA)
  for (file in binfiles) {
    #Update progress bar 
    count=count+1
    setTxtProgressBar(pb,count)
    #load the dataset 
    load(filelist[file])
    #With the dataset:
    with(HCoptim,{
      #Compute the possibly valid HCs
      poss.index<-which(abs(muz-rev(muz)[1])<=0.01)
      #Remove any gaps 
      gap<-which(diff(poss.index)!=1)
      if (length(gap)>0) {
        poss.index<-poss.index[max(gap):length(poss.index)]
      }
      #Plot the mean z's vs HC
      vals<-rowSums(muz.train*ct.train,na.rm=T)/rowSums(ct.train,na.rm=T)
      lines(HC.steps,vals-rev(vals)[1],col=seqinr::col2alpha(col[1],a=alpha),lwd=2,lty=3)
      vals<-rowSums(muz.train*ct.train*wt.final,na.rm=T)/rowSums(ct.train*wt.final,na.rm=T)
      lines(HC.steps,vals-rev(vals)[1],col=seqinr::col2alpha(col[2],a=alpha),lwd=2)
      vals<-rowSums(muz.train*ct.train*qc.vals*wt.final,na.rm=T)/rowSums(ct.train*qc.vals*wt.final,na.rm=T)
      lines(HC.steps,vals-rev(vals)[1],col=seqinr::col2alpha(col[3],a=alpha),lwd=2)
      if (exists("muz.true")) { 
        lines(HC.steps,vals-muz.true,col=seqinr::col2alpha(col[4],a=alpha),lwd=2)
      } 
      #If we want an inpanel legend, draw it
      if (inplot & tomo==1) {
        legend('topright',legend=c("without QC","with QC","of training sample"),title='Change in reconstructed mean z:',lwd=2,col=col[1:3],lty=c(1,1,3),bty='n',inset=0.1,cex=1.3)
        if (exists("muz.true")) {
          legend('right',legend=c("Bias"),lwd=2,col=col[4],lty=c(1),bty='n',inset=0.1,cex=1.3)
        }
      }
    })
  }
  #Add the axes 
  magicaxis::magaxis(xlab='',ylab='',side=1:4,labels=c(tomo>length(binstrings)-3,tomo%%3==1,F,F))
}
close(pb)
#if we want a stand-alone legend, draw it 
if (!inplot) {
  plot(1,axes=F,xlab='',ylab='',labels=F,type='n')
  legend('center',legend=c("without QC","with QC","of training sample"),title='Change in reconstructed mean z:',lwd=2,col=col[1:3],lty=c(1,1,3),bty='n',cex=1.3)
  if (length(HCoptim$muz.true)>0) {
    legend('bottom',legend=c("Bias"),lwd=2,col=col[4],lty=c(1),bty='n',inset=0.1,cex=1.3)
  }
}
#Add the axes labels 
mtext(side=1,outer=T,text="Number of clusters",line=3)
mtext(side=2,outer=T,text=expression(mu[z]-mu["z,maxHC"]),line=2.5)
dev.off()
#}}}

#Output the change-in-neff plot {{{
cat("Plotting HC neff\n")
png(file=paste0(outputbase,"_HCoptim_neff.png"),height=2.5*(npanel/3)*220,width=10*220,res=220)
#set up panels 
layout(matrix(1:npanel,ncol=3,byrow=T))
par(mar=c(0,0,0,0),oma=c(4,4,1,1))
#Do we need an in-panel legend?
inplot=(npanel==length(binstrings))
#initialise the progressbar 
pb<-txtProgressBar(style=3,min=0,max=length(filelist))
count<-0
#loop over the inputs 
for (tomo in 1:length(binstrings)) {
  #Get the files in this bin 
  binfiles<-which(grepl(binstrings[tomo],filelist,fixed=T))
  if (length(binfiles)==0) { 
    magicaxis::magplot(1,xlim=c(1,1e3),ylim=c(0.4,1.0),type='n',xlab='',ylab='',side=1:4,labels=c(tomo>length(binstrings)-3,tomo%%3==1,F,F))
    next 
  }
  #Define the alpha
  alpha<-1/min(20,length(binfiles))
  #Set up the plot panel
  load(filelist[binfiles[1]])
  magicaxis::magplot(1,xlim=c(1,max(HCoptim$HC.steps)),ylim=c(0.4,1.0),type='n',xlab='',ylab='',side=1:4,labels=c(tomo>length(binstrings)-3,tomo%%3==1,F,F))
  for (file in binfiles) {
    #Update progress bar 
    count=count+1
    setTxtProgressBar(pb,count)
    #load the dataset 
    load(filelist[file])
    #With the dataset:
    with(HCoptim,{
      #Compute the possibly valid HCs
      poss.index<-which(abs(muz-rev(muz)[1])<=0.01)
      #Remove any gaps 
      gap<-which(diff(poss.index)!=1)
      if (length(gap)>0) {
        poss.index<-poss.index[max(gap):length(poss.index)]
      }
      #Plot the neff vs HC
      rawneff<-rowSums(ct.refr,na.rm=T)^2/rowSums(ctsq.refr,na.rm=T)
      vals<-rowSums(ct.refr*ifelse(wt.final>0,1,0),na.rm=T)^2/rowSums(ctsq.refr*ifelse(wt.final>0,1,0),na.rm=T)
      lines(HC.steps,vals/rawneff,col=seqinr::col2alpha(col[1],a=alpha),lwd=2,lty=3)
      vals<-rowSums(ct.refr*qc.vals*ifelse(wt.final>0,1,0),na.rm=T)^2/rowSums(ctsq.refr*qc.vals*ifelse(wt.final>0,1,0),na.rm=T)
      lines(HC.steps,vals/rawneff,col=seqinr::col2alpha(col[2],a=alpha),lwd=2,lty=3)
      #If we want an inpanel legend, draw it
      if (inplot & tomo==1) {
        legend('topright',legend=c("without QC","with QC"),title='Change in n_eff:',lwd=2,col=col[1:2],lty=c(1,1),bty='n',inset=0.1,cex=1.3)
      }
    })
  }
}
close(pb)
#if we want a stand-alone legend, draw it 
if (!inplot) {
  plot(1,axes=F,xlab='',ylab='',labels=F,type='n')
  legend('center',legend=c("without QC","with QC"),title='Change in n_eff:',lwd=2,col=col[1:2],lty=c(1,1),bty='n',inset=0.1,cex=1.3)
}
#Add the axes labels 
mtext(side=1,outer=T,text="Number of clusters",line=3)
mtext(side=2,outer=T,text=expression(n[eff]^gold/n[eff]),line=2.5)
dev.off()
#}}}

