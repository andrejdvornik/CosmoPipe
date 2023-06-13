#=========================================
#
# File Name : computs_m_priors.R
# Created By : awright
# Creation Date : 12-06-2023
# Last Modified : Mon 12 Jun 2023 11:00:25 PM CEST
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
  if (inputs[1]=='-i') { 
    #Read the input mbias catalogue(s) /*fold*/ {{{
    inputs<-inputs[-1]
    if (any(grepl('^-',inputs))) { 
      input.files<-inputs[1:(which(grepl('^-',inputs))[1]-1)]
      inputs<-inputs[-(1:(which(grepl('^-',inputs))[1]-1))]
    } else { 
      input.files<-inputs
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
  } else if (inputs[1]=='--corr') { 
    #Define the correlation factor for mbias uncertainties /*fold*/ {{{
    inputs<-inputs[-1]
    corr<-inputs[1]
    inputs<-inputs[-1]
    #/*fold*/}}}
  } else {
    stop(paste("Unknown option",inputs[1]))
  }
}

#Number of realisations 
nreal<-length(input.files)/length(binstrings)
#Make sure it's an integer! 
if ( nreal%%1 != 0 ) { 
  stop("There are a non-integer number of input catalogues per bin?!") 
}
#Initialise the realisation results matrix 
m_mat<-matrix(NA,ncol=length(binstrings),nrow=length(input.files)/length(binstrings))

#Setup progress bar 
pb<-txtProgressBar(style=3,min=0,max=length(bias))
count<-0
#For each tomographic bin 
for (bin in 1:length(binstrings)) { 
  #Get the list of calibration and reference catalogues 
  mcats<-input.files[grepl(binstrings[bin],input.files,fixed=T)]
  for (i in 1:length(mcats)) { 
    setTxtProgressBar(pb,count)
    count<-count+1
    #Read the calibration file 
    mdf<-helpRfuncs::read.file(mcats[i],data.table=FALSE,cols=c(redshift.label,gold.label))
    #record the m value 
    m_mat[i,bin]<-mdf$m
    #record the dm value 
    dm_mat[i,bin]<-mdf$m_err
  }
}
close(pb)

#Compute the mean m per bin 
final_m<-colMeans(m_mat)
##Compute the uncertainty on the mean per bin 
#final_dm<-sqrt(matrixStats::colSums(dm_mat))
#Compute the typical fit uncertainty per bin 
final_dm<-colMeans(dm_mat)
#Compute the m-gold covariance  
gold_cov<-cov(m_mat)
#Compute the systematic m covariance  
sys_cov<-diag(final_dm^2)
for (i in 1:ncol(sys_cov)) { 
  for (j in 1:ncol(sys_cov)) { 
    if (i!=j) {
      sys_cov[i,j]<-final_dm[i]*final_dm[j]*corr
    }
  }
}

#Compute the full covariance  
final_cov<-gold_cov+sys_cov
#Output the m file 
helpRfuncs::write.file(bias_oname,final_m,colnames=FALSE)
#Output the cov file 
helpRfuncs::write.file(cov_oname,final_cov,colnames=FALSE)

