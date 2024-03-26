#=========================================
#
# File Name : combine_covariances.R
# Created By : awright
# Creation Date : 22-03-2024
# Last Modified : Mon 25 Mar 2024 09:34:34 PM CET
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
  if (inputs[1]=='--inputs') { 
    #Read the input catalogue(s) /*fold*/ {{{
    inputs<-inputs[-1]
    if (any(grepl('^-',inputs))) { 
      files<-inputs[1:(which(grepl('^-',inputs))[1]-1)]
      inputs<-inputs[-(1:(which(grepl('^-',inputs))[1]-1))]
    } else { 
      files<-inputs
      inputs<-NULL
    } 
    #/*fold*/}}}
  } else if (inputs[1]=='--patchlist') { 
    #Read the bin strings /*fold*/ {{{
    inputs<-inputs[-1]
    if (any(grepl('^-',inputs))) { 
      patchlist<-inputs[1:(which(grepl('^-',inputs))[1]-1)]
      inputs<-inputs[-(1:(which(grepl('^-',inputs))[1]-1))]
    } else { 
      patchlist<-inputs
      inputs<-NULL
    } 
    #/*fold*/}}}
  } else if (inputs[1]=='--binstrings') { 
    #Read the bin strings /*fold*/ {{{
    inputs<-inputs[-1]
    if (any(grepl('^-',inputs))) { 
      binstrings<-inputs[1:(which(grepl('^-',inputs))[1]-1)]
      inputs<-inputs[-(1:(which(grepl('^-',inputs))[1]-1))]
    } else { 
      binstrings<-inputs
      inputs<-NULL
    } 
    #/*fold*/}}}
  } else if (inputs[1]=='--allpatch') { 
    # Define the output file name {{{
    inputs<-inputs[-1]
    allpatch<-inputs[1]
    inputs<-inputs[-1]
    #/*fend*/}}}
  } else if (inputs[1]=='--ntheta') { 
    # Define the output file name {{{
    inputs<-inputs[-1]
    ntheta<-as.numeric(inputs[1])
    inputs<-inputs[-1]
    #/*fend*/}}}
  } else if (inputs[1]=='--outputbase') { 
    # Define the output file name {{{
    inputs<-inputs[-1]
    outputbase<-inputs[1]
    inputs<-inputs[-1]
    #/*fend*/}}}
  } else {
    stop(paste("Unknown option",inputs[1]))
  }
}

ntomo<-length(binstrings)
ndata<-(ntomo*(ntomo+1))/2

for (patch in c(patchlist,allpatch)) { 
  if (length(which(grepl(paste0("_",patch,"_"),files)))==0) { 
    next
  }
  fullcov<-matrix(0,ncol=(ntheta*ndata*2),nrow=(ntheta*ndata*2))
  n<-0
  for (i in 1:length(binstrings)) { 
    for (j in i:length(binstrings)) { 
      n<-n+1
      filestr<-paste0(binstrings[i],binstrings[j])
      print(filestr)
      inpfile<-which(grepl(filestr,files) & grepl(paste0("_",patch,"_"),files))
      cov<-as.matrix(helpRfuncs::read.file(files[inpfile],type='asc'))
      
      #xip xip 
      indx<-((n-1)*ntheta+1):((n)*ntheta)
      indy<-((n-1)*ntheta+1):((n)*ntheta)
      print(c(range(indx),range(indy)))
      fullcov[indx, indy] = cov[1:ntheta,1:ntheta]
  
      #xip xim 
      indx<-((n-1)*ntheta+1):((n)*ntheta)
      indy<-((n-1)*ntheta + ndata*ntheta+1):((n)*ntheta + ndata*ntheta)
      print(c(range(indx),range(indy)))
      fullcov[indx,indy] = cov[1:ntheta,1:ntheta+ntheta]
  
      #xim xim 
      indx<-((n-1)*ntheta + ndata*ntheta+1):((n)*ntheta + ndata*ntheta)
      indy<-((n-1)*ntheta + ndata*ntheta+1):((n)*ntheta + ndata*ntheta)
      print(c(range(indx),range(indy)))
      fullcov[indx,indy] = cov[1:ntheta+ntheta,1:ntheta+ntheta]
    }
  }
  assign(paste0('fullcov_',patch),fullcov)
}
fullcov<-0
count<-0
for (patch in patchlist) { 
  fullcov<-(fullcov+get(paste0("fullcov_",patch)))
  count<-count+1
} 
cat(paste("Full covariance is the combination of",count,"patches"))
fullcov<-fullcov/count^2
data.table::fwrite(file=paste0(outputbase,"/",allpatch,"comb_fullcovariance.txt"),
                   as.data.frame(fullcov),sep=' ',col.names=FALSE)
for (patch in patchlist) { 
  data.table::fwrite(file=paste0(outputbase,"/",patch,"_fullcovariance.txt"),
                     as.data.frame(get(paste0('fullcov_',patch))),sep=' ',col.names=FALSE)
}

