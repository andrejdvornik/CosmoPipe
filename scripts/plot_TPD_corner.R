#=========================================
#
# File Name : plot_TPD.R
# Created By : awright
# Creation Date : 18-04-2023
# Last Modified : Tue 07 Jan 2025 02:05:38 PM CET
#
#=========================================

library(argparser)

#Create the argument parser 
p <- arg_parser("Plot theory predictive distributions for a chain file")
# Add a positional argument
p <- add_argument(p, "--datavec", help="Observed data vector")
# Add a positional argument
p <- add_argument(p, "--covariance", help="Estimated covariance")
# Add a positional argument
p <- add_argument(p, "--tpds", help="Theory predictive distributions")
# Add an optional argument
p <- add_argument(p, "--ntomo", help="Number of tomographic bins",type='integer')
# Add an optional argument
p <- add_argument(p, "--sampler", help="Sampler used for the chain")
# Add an optional argument
p <- add_argument(p, "--output", help="output pdf", default="plot_TPD.pdf")
# Add an optional argument
p <- add_argument(p, "--xlabel", help="x-axis variable name")
# Add an optional argument
p <- add_argument(p, "--ylabel", help="y-axis variable name")
# Add an optional argument
p <- add_argument(p, "--title", help="Plot title", default="Chain")
## Add a flag
#p <- add_argument(p, "--append", help="append to file", flag=TRUE)

#Read the arguments 
args<-parse_args(p)

#Get the number of correlations 
ncorr<-sum(seq(args$ntomo))

#Check for incorrect calling syntax
if (is.na(args$datavec)) { 
  stop(cat(print(p))) 
} 


#Read in the data vector 
dat<-helpRfuncs::read.file(file=args$datavec)
#Get the number of data elements 

#Remove the B-modes/xim 
dat<-dat[1:(nrow(dat)/2),]
ndata<-nrow(dat)/ncorr

#Read the covariance matrix 
cov<-helpRfuncs::read.file(file=args$covariance,type='text')
cov<-as.matrix(cov)
#Remove the B-modes/xim 
cov<-cov[1:nrow(dat),1:nrow(dat)]

#Read the theory predictive distributions 
tpd<-helpRfuncs::read.chain(file=args$tpds)
#Read the samples for each theory prediction 
samps<-helpRfuncs::read.chain(file=sub("_list_","_",args$tpds))
#Assign the weights to the theory predictions 
tpdweight<-samps$weight
if (length(tpdweight)==0) { 
  tpdweight<-exp(samps$log_weight)
}
if (length(tpdweight)==0) { 
  tpdweight<-samps$post
  tpdweight[which(tpdweight<quantile(tpdweight,prob=0.01))]<-quantile(tpdweight,prob=0.01)
  tpdweight<-tpdweight/min(tpdweight,na.rm=T)
}
#Check sizes match 
if (length(tpdweight)!=nrow(tpd)) { 
  stop(paste("TPD sample weights are not of the same length as the sample?!\n",length(tpdweight),"!=",nrow(tpd)))
}
#Select only the theory predictions, and convert to matrix format 
cols<-colnames(tpd)
cols<-cols[which(grepl("scale_cuts_output",cols,ignore.case=T))]
tpd<-as.matrix(tpd[,cols,with=F])


#Define the layout matrix for the figure 
#upper triangle 
mat<-matrix(0,nrow=args$ntomo+1,ncol=args$ntomo+1)
cumul<-0
for (i in 1:args$ntomo) { 
  mat[i,i:args$ntomo+1]<-i:args$ntomo + cumul
  cumul<-cumul+length(i:args$ntomo)-1
}
#lower triangle 
cumul<-cumul+args$ntomo
for (i in 1:args$ntomo) {
  mat[i:args$ntomo+1,i]<-i:args$ntomo + cumul
  cumul<-cumul+length(i:args$ntomo)-1
}

#open the plot device 
pdf(file=args$output)
#set the layout 
layout(mat)
#set the margins 
par(mar=c(0,0,0,0),oma=c(5,5,5,5))

#Define the scaling factor for the y-labels 
mfact<-ceiling(median(log10(abs(dat$V1))))

#Plot data vector with theory samples 
start=0
#Define the ylimits of each panel 
ylim=range(c(dat+sqrt(diag(cov))*3,dat-sqrt(diag(cov))*3))/10^mfact
for (i in 1:args$ntomo) { 
  for (j in i:args$ntomo) { 
    ind<-start+1:ndata
    #Plot the data vector 
    magicaxis::magplot(dat$V1[ind]/10^mfact,xlab='',ylab='',type='n',side=1:4,labels=c(i==j,F,i==1,j==args$ntomo),
                       #ylim=ylim,xlim=c(0.5,ndata+0.5),grid=F)
                       ylim=ylim,xlim=c(0.5,6+0.5),grid=F)
    #Zero line 
    abline(h=0,lwd=2)
    #Data points
    points(dat$V1[ind]/10^mfact,pch=20,cex=0.8,lwd=2)
    magicaxis::magerr(x=1:length(ind),dat$V1[ind]/10^mfact,yhi=sqrt(diag(cov)[ind])/10^mfact,ylo=sqrt(diag(cov)[ind])/10^mfact,lwd=2)

    #Add the samples 
    tpdsamp<-tpd[sample(nrow(tpd),prob=tpdweight,size=500),]
    matplot(1:length(ind),t(tpdsamp)[ind,]/10^mfact,add=T,type='l',col=hsv(a=0.1),lty=1)
    start=start+ndata
  }
}
#Annotate axes 
mtext(side=3,text=args$xlabel,line=2.5,outer=T)
mtext(side=4,text=bquote(.(parse(text=args$ylabel)[[1]])*" x10"^.(mfact)),line=2.5,outer=T)

#Sigma residuals of model w.r.t. data 
start=0
for (i in 1:args$ntomo) { 
  for (j in i:args$ntomo) { 
    ind<-start+1:ndata
    #Plot the data vector 
    #magicaxis::magplot(1:length(ind),xlab='',ylab='',type='n',ylim=c(-4,4),xlim=c(0.5,ndata+0.5),side=1:4,labels=c(j==args$ntomo,i==1,i==j,F),grid=F)
    magicaxis::magplot(1:length(ind),xlab='',ylab='',type='n',ylim=c(-4,4),xlim=c(0.5,6+0.5),side=1:4,labels=c(j==args$ntomo,i==1,i==j,F),grid=F)
    #Zero lone 
    abline(h=0,lwd=2)
    #Data 
    points(rep(0,length(ind)),pch=20,cex=0.8,lwd=2)
    magicaxis::magerr(x=1:length(ind),rep(0,length(ind)),yhi=rep(1,length(ind)),ylo=rep(-1,length(ind)),lwd=2)
    
    #Add the samples 
    tpdsamp<-tpd[sample(nrow(tpd),prob=tpdweight,size=500),]
    matplot(1:length(ind),(t(tpdsamp)[ind,]-dat$V1[ind])/sqrt(diag(cov)[ind]),add=T,type='l',col=hsv(a=0.1),lty=1)
    start=start+ndata
  }
}
#Annotate axes 
mtext(side=1,text=args$xlabel,line=2.5,outer=T)
mtext(side=2,text=bquote((.(parse(text=args$ylabel)[[1]])^dat-
                          .(parse(text=args$ylabel)[[1]])^th)/
                          sigma[.(parse(text=args$ylabel)[[1]])*",dat"]),line=2.5,outer=T)

dev.off()

print('Done!')

