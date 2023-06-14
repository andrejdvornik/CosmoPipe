#=========================================
#
# File Name : computs_dz_priors.R
# Created By : awright
# Creation Date : 29-03-2023
# Last Modified : Tue 13 Jun 2023 10:09:08 PM CEST
#
#=========================================

#Get the input files 
inputs<-commandArgs(TRUE) 

#Interpret the command line options 
while (length(inputs)!=0) {
  while (length(inputs)!=0 && inputs[1]=='') { inputs<-inputs[-1] }  
  if (!grepl('^-',inputs[1])) {
    print(inputs)
    stop(paste("Incorrect options provided!"))
  }
  #/*fend*/}}}
  if (inputs[1]=='-c') { 
    #Read the input calibration catalogue(s) /*fold*/ {{{
    inputs<-inputs[-1]
    if (any(grepl('^-',inputs))) { 
      input.calib<-inputs[1:(which(grepl('^-',inputs))[1]-1)]
      inputs<-inputs[-(1:(which(grepl('^-',inputs))[1]-1))]
    } else { 
      input.calib<-inputs
      inputs<-NULL
    } 
    #/*fold*/}}}
  } else if (inputs[1]=='-r') { 
    #Read the input catalogue(s) /*fold*/ {{{
    inputs<-inputs[-1]
    if (any(grepl('^-',inputs))) { 
      input.refr<-inputs[1:(which(grepl('^-',inputs))[1]-1)]
      inputs<-inputs[-(1:(which(grepl('^-',inputs))[1]-1))]
    } else { 
      input.refr<-inputs
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
  } else if (inputs[1]=='--biasout') { 
    #Define the output biases filename /*fold*/ {{{
    inputs<-inputs[-1]
    bias_oname<-inputs[1]
    inputs<-inputs[-1]
    #/*fold*/}}}
  } else if (inputs[1]=='--covout') { 
    #Define the output covariance filename /*fold*/ {{{
    inputs<-inputs[-1]
    cov_oname<-inputs[1]
    inputs<-inputs[-1]
    #/*fold*/}}}
  } else if (inputs[1]=='-g') { 
    #Define the goldclass/weight label /*fold*/ {{{
    inputs<-inputs[-1]
    gold.label<-inputs[1]
    inputs<-inputs[-1]
    #/*fold*/}}}
  } else if (inputs[1]=='-w') { 
    #Define the weight label /*fold*/ {{{
    inputs<-inputs[-1]
    weight.label<-inputs[1]
    inputs<-inputs[-1]
    #/*fold*/}}}
  } else if (inputs[1]=='-z') { 
    #Define the redshift label /*fold*/ {{{
    inputs<-inputs[-1]
    redshift.label<-inputs[1]
    inputs<-inputs[-1]
    #/*fold*/}}}
  } else if (inputs[1]=='--covout') { 
    #Define the output covariance filename /*fold*/ {{{
    inputs<-inputs[-1]
    cov_oname<-inputs[1]
    inputs<-inputs[-1]
    #/*fold*/}}}
  } else {
    stop(paste("Unknown option",inputs[1]))
  }
}

#Number of realisations 
nreal<-length(input.calib)/length(binstrings)
#Make sure it's an integer! 
if ( nreal%%1 != 0 ) { 
  stop("There are a non-integer number of input catalogues per bin?!") 
}
#Initialise the realisation results matrix 
muzcalib<-muzrefr<-bias<-muzrefr_nogold<-bias_nogold<-matrix(NA,ncol=length(binstrings),nrow=length(input.calib)/length(binstrings))

#Setup progress bar 
pb<-txtProgressBar(style=3,min=0,max=length(bias))
count<-0
#For each tomographic bin 
for (bin in 1:length(binstrings)) { 
  #Get the list of calibration and reference catalogues 
  calib_cats<-input.calib[grepl(binstrings[bin],input.calib,fixed=T)]
  refr_cats<-input.refr[grepl(binstrings[bin],input.refr,fixed=T)]
  if (length(calib_cats)!=length(refr_cats)) { 
    stop("Mismatch in the reference and calibration catalogue lists?!") 
  } 
  for (i in 1:length(calib_cats)) { 
    setTxtProgressBar(pb,count)
    count<-count+1
    #Read the calibration file 
    calib<-helpRfuncs::read.file(calib_cats[i],data.table=FALSE,cols=c(redshift.label,gold.label))
    if (any(calib[[redshift.label]]<0)) { 
      cat("WARNING: calibration sources have negative redshift in file",calib_cats[i],"!\n")
      calib[[redshift.label]][which(calib[[redshift.label]]<0)]<-0
    }
    #Read the reference file 
    refr<-helpRfuncs::read.file(refr_cats[i],data.table=FALSE,cols=c(redshift.label,gold.label,weight.label))
    if (any(refr[[redshift.label]]<0)) { 
      #cat("WARNING: reference sources have negative redshift in file",refr_cats[i],"!\n")
      refr[[redshift.label]][which(refr[[redshift.label]]<0)]<-0
    }
    #Compute the bias: z_est - z_true 
    muzcalib[i,bin]<-weighted.mean(calib[[redshift.label]],calib[[gold.label]])
    muzrefr[i,bin]<-weighted.mean(refr[[redshift.label]],(refr[[weight.label]]*refr[[gold.label]]))
    muzrefr_nogold[i,bin]<-weighted.mean(refr[[redshift.label]],refr[[weight.label]])
    bias_nogold[i,bin]<-weighted.mean(calib[[redshift.label]],calib[[gold.label]]) -
                 weighted.mean(refr[[redshift.label]],(refr[[weight.label]]))
    bias[i,bin]<-weighted.mean(calib[[redshift.label]],calib[[gold.label]]) -
                 weighted.mean(refr[[redshift.label]],(refr[[weight.label]]*refr[[gold.label]]))
  }
}
close(pb)

#Compute the mean biases per bin 
final_biases<-colMeans(bias)
#Compute the Nz bias covariance  
final_cov<-cov(bias)
#Output the bias file 
helpRfuncs::write.file(bias_oname,final_biases,col.names=FALSE)
#Output the cov file 
helpRfuncs::write.file(cov_oname,final_cov,col.names=FALSE)

