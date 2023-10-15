#=========================================
#
# File Name : combine_xi_patches.R
# Created By : awright
# Creation Date : 29-03-2023
# Last Modified : Fri 08 Sep 2023 10:02:23 AM UTC
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
    #Read the input catalogue(s) /*fold*/ {{{
    inputs<-inputs[-1]
    if (any(grepl('^-',inputs))) { 
      input.cats<-inputs[1:(which(grepl('^-',inputs))[1]-1)]
      inputs<-inputs[-(1:(which(grepl('^-',inputs))[1]-1))]
    } else { 
      input.cats<-inputs
      inputs<-NULL
    } 
    #/*fold*/}}}
  } else if (inputs[1]=='-o') { 
    # Define the output file name {{{
    inputs<-inputs[-1]
    outputfile<-inputs[1]
    inputs<-inputs[-1]
    #/*fend*/}}}
  } else {
    stop(paste("Unknown option",inputs[1]))
  }
}

colnames<-c('r_nom','meanr','meanlogr','xip','xim','xip_im','xim_im','sigma_xip','sigma_xim', 'npairs', 'weight','npairs_weighted')

for (i in 1:length(input.cats)) { 
  #Read the file 
  tmp<-helpRfuncs::read.file(input.cats[i],data.table=FALSE)
  #Add new values 
  tmp$xim_im_sq <- tmp$xim_im^2
  tmp$var_xip <- tmp$sigma_xip^2
  tmp$var_xim <- tmp$sigma_xim^2
  tmp$npairs_sq <- tmp$npairs^2
  
  #if we have the first file, use this as a template 
  if (i==1) { 
    inter_cols<-c('r_nom','meanr','meanlogr','xip','xim','xip_im','xim_im','xim_im_sq','var_xip','var_xim', 'npairs_sq', 'weight','npairs_weighted')
    #Set up the catalogue, but fill everything with zeros
    out<-tmp[,inter_cols]*0
  } 
  print(summary(out))
  #Otherwise, combine the values
  #Weighted sum of values (weight = npairs_weighted)
  out$r_nom     = (out$r_nom    + tmp$r_nom   * tmp$npairs_weighted)
  out$meanr     = (out$meanr    + tmp$meanr   * tmp$npairs_weighted)
  out$meanlogr  = (out$meanlogr + tmp$meanlogr* tmp$npairs_weighted)
  out$xip       = (out$xip      + tmp$xip     * tmp$npairs_weighted)
  out$xim       = (out$xim      + tmp$xim     * tmp$npairs_weighted)
  out$xip_im    = (out$xip_im   + tmp$xip_im  * tmp$npairs_weighted)
  out$xim_im    = (out$xim_im   + tmp$xim_im  * tmp$npairs_weighted)
  out$xim_im_sq = out$xim_im_sq + tmp$xim_im_sq 
  out$var_xip = out$var_xip+tmp$var_xip 
  out$npairs_sq = out$npairs_sq+tmp$npairs_sq 
  out$weight = out$weight+tmp$weight
  out$npairs_weighted = out$npairs_weighted+tmp$npairs_weighted
}
print(summary(out))
#Construct the output columns 
out$r_nom     = out$r_nom/out$npairs_weighted
out$meanr     = out$meanr/out$npairs_weighted
out$meanlogr  = out$meanlogr/out$npairs_weighted
out$xip       = out$xip/out$npairs_weighted
out$xim       = out$xim/out$npairs_weighted
out$xip_im    = out$xip_im/out$npairs_weighted
out$xim_im    = out$xim_im/out$npairs_weighted
out$xim_im_sq = out$xim_im_sq + tmp$xim_im_sq 
out$sigma_xip = sqrt(out$var_xip)
out$sigma_xim = sqrt(out$var_xim)
out$npairs = sqrt(out$npairs_sq) 
#Remove the intermediate columns and sort into the original order 
out<-data.table::as.data.table(out)
out<-out[,.SD,.SDcols=colnames]
print(summary(out))

#Output the file 
helpRfuncs::write.file(outputfile,out)
