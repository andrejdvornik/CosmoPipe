#=========================================
#
# File Name : plot_TPD.R
# Created By : awright
# Creation Date : 18-04-2023
# Last Modified : Fri 01 Mar 2024 09:40:33 AM CET
#
#=========================================

library(argparser)

commandArgs<-function(C) helpRfuncs::vecsplit('--xipmvec work_LegacyNoSims_OldBins/CosmoPipe_DataBlock/xipm_binned/xipm_binned_BLINDSHAPES_KIDS_Legacy_NScomb_shear_noSG_noWeiCut_newCut_A1_rmcol_filt_PSF_RAD_calc_filt_goldwt_comb_A2_ZB0p1t0p3_ZB0p1t0p3_xipm_binned.asc--xigpsfvec work_LegacyNoSims_OldBins/CosmoPipe_DataBlock/xigpsf_binned/xipm_binned_BLINDSHAPES_KIDS_Legacy_NScomb_shear_noSG_noWeiCut_newCut_A1_rmcol_filt_PSF_RAD_calc_filt_goldwt_comb_A2_ZB0p1t0p3_ZB0p1t0p3_xigpsf_binned.asc--xipsfvec work_LegacyNoSims_OldBins/CosmoPipe_DataBlock/xipsf_binned/xipm_binned_BLINDSHAPES_KIDS_Legacy_NScomb_shear_noSG_noWeiCut_newCut_A1_rmcol_filt_PSF_RAD_calc_filt_goldwt_comb_A2_ZB0p1t0p3_ZB0p1t0p3_xipsf_binned.asc--xipm_tpd work_LegacyNoSims_OldBins/MCMC/output/KiDS_BlindC/COSMOPOWER_COSMOSIS_HM2015_S8/xipm/chain/output_list_nautilus_C.txt --covariance ${covariance} --ntomo 5 --output text.pdf',sep=' ')

#Create the argument parser 
p <- arg_parser("Plot theory predictive distributions for a chain file")
# Add a positional argument
p <- add_argument(p, "--xipmvec", help="Observed xipm data vector")
# Add a positional argument
p <- add_argument(p, "--xipm_tpd", help="xipm data vector TPDs")
# Add a positional argument
p <- add_argument(p, "--xipsfvec", help="Observed PSF correlation function data vector")
# Add a positional argument
p <- add_argument(p, "--xigpsfvec", help="Observed PSF-shear cross correlation data vector")
# Add a positional argument
p <- add_argument(p, "--covariance", help="Estimated covariance")
# Add an optional argument
p <- add_argument(p, "--nmax", help="Number of modes/datapoints",type='integer',default=NA)
# Add an optional argument
p <- add_argument(p, "--ntomo", help="Number of tomographic bins",type='integer')
# Add an optional argument
p <- add_argument(p, "--output", help="output pdf", default="plot_TPD.pdf")
# Add an optional argument
p <- add_argument(p, "--title", help="Plot title", default="Chain")
# Add an optional argument
p <- add_argument(p, "--type", help="Upper or Lower half of the data vector", default="upper")
## Add a flag
#p <- add_argument(p, "--append", help="append to file", flag=TRUE)
## Add an optional argument
#p <- add_argument(p, "--xlabel", help="x-axis variable name",default='Radius (arcmin)')
## Add an optional argument
#p <- add_argument(p, "--ylabel", help="y-axis variable name",default=expression(xi^[sys]/xi^paste(Lambda*"CDM"))

#Read the arguments 
args<-parse_args(p)

#Get the number of correlations 
ncorr<-sum(seq(args$ntomo))

#Check for incorrect calling syntax
if (is.na(args$xipmvec)) { 
  stop(cat(print(p))) 
} 


#Read in the data vector 
dat<-helpRfuncs::read.file(file=args$xipmvec)
if (ncol(dat)>2) { 
  print(colnames(dat))
  radius<-c(dat$meanr,dat$meanr)
  dat<-data.frame(V1=c(dat$xip,dat$xim))
} else { 
  radius<-rep(1:nrow(dat),2)
}
#Get the number of data elements 
ndata<-nrow(dat)/ncorr/2
#Read in the data vector 
psf<-helpRfuncs::read.file(file=args$xipsfvec)
if (ncol(psf)>2) { 
  psf<-data.frame(V1=c(psf$xip,psf$xim))
}
#Read in the data vector 
gpsf<-helpRfuncs::read.file(file=args$xigpsfvec)
if (ncol(gpsf)>2) { 
  print(colnames(gpsf))
  gpsf<-data.frame(V1=c(gpsf$xip,gpsf$xim))
}

dat<-gpsf/psf
#dat<-psf*sqrt(radius)

#Read the covariance matrix 
cov<-data.table::fread(file=args$covariance)
cov<-as.matrix(cov)

#Read the theory predictive distributions 
tpd<-helpRfuncs::read.chain(file=args$xipm_tpd)
#Read the samples for each theory prediction 
samps<-helpRfuncs::read.chain(file=sub("_list_","_",args$xipm_tpd))
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
for (uplo in 1:2) { 
  for (i in 1:args$ntomo) { 
    for (j in i:args$ntomo) { 
      ind<-start+1:ndata
      #Plot the data vector 
      magicaxis::magplot(radius[ind],dat$V1[ind]/10^mfact,xlab='',ylab='',type='n',side=1:4,labels=c(i==j,F,i==1,j==args$ntomo),
                         ylim=ylim,log='x',grid=F)
      #Zero line 
      abline(h=0,lwd=2)
      #Data points
      points(radius[ind],dat$V1[ind]/10^mfact,pch=20,cex=0.8,lwd=2)
      magicaxis::magerr(x=radius[ind],dat$V1[ind]/10^mfact,yhi=sqrt(diag(cov)[ind])/10^mfact,ylo=sqrt(diag(cov)[ind])/10^mfact,lwd=2)
  
      start=start+ndata
    }
  }
}
#Annotate axes 
mtext(side=1,text=args$xlabel,line=2.5,outer=T)
mtext(side=3,text=args$xlabel,line=2.5,outer=T)
mtext(side=2,text=bquote(.(parse(text="xi['-']^'sys'/xi['-']^paste(Lambda,'CDM')")[[1]])*" x10"^.(mfact)),line=2.5,outer=T)
mtext(side=4,text=bquote(.(parse(text="xi['+']^'sys'/xi['+']^paste(Lambda,'CDM')")[[1]])*" x10"^.(mfact)),line=2.5,outer=T)

dev.off()

