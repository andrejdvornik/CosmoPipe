#=========================================
#
# File Name : epsf_variance.R
# Created By : awright
# Creation Date : 10-07-2023
# Last Modified : Fri Apr 12 05:55:32 2024
#
#=========================================

#Split a catalogue into N sections

#Read input parameters 
inputs<-commandArgs(TRUE) 

#Interpret the command line options {{{
ID_only<-N_only<-FALSE
badval<- -999
while (length(inputs)!=0) {
  #Check for valid specification {{{
  while (length(inputs)!=0 && inputs[1]=='') { inputs<-inputs[-1] }  
  if (!grepl('^-',inputs[1])) {
    print(inputs)
    stop(paste("Incorrect options provided!"))
  }
  #/*fend*/}}}
  if (inputs[1]=='-i') { 
    #Read the input catalogue /*fold*/ {{{
    inputs<-inputs[-1]
    input.cat<-inputs[1]
    inputs<-inputs[-1]
    #/*fold*/}}}
  } else if (inputs[1]=='-v') { 
    #Read the PSF ellipticity names /*fold*/ {{{
    inputs<-inputs[-1]
    if (any(grepl('^-',inputs))) { 
      psfvars<-inputs[1:(which(grepl('^-',inputs))[1]-1)]
      inputs<-inputs[-(1:(which(grepl('^-',inputs))[1]-1))]
    } else { 
      psfvars<-inputs
      inputs<-NULL
    } 
    #/*fold*/}}}
  } else if (inputs[1]=='-o') { 
    #Read the output catalogue(s) /*fold*/ {{{
    inputs<-inputs[-1]
    output<-inputs[1]
    inputs<-inputs[-1]
    #/*fold*/}}}
  } else {
    stop(paste("Unknown option",inputs[1]))
  }
}
#}}}

#Read the input catalogue for col names {{{
cat<-helpRfuncs::read.file(input.cat,nrow=10)
#}}}

#Check that the x.name varaible is in the catalogue 
psfexpvars<-list()
for (x.name in psfvars) { 
  if (!x.name %in% colnames(cat)) {  
    stop(paste(x.name,"variable is not in provided catalogue!")) 
  }
  psfexpvars[[x.name]]<-colnames(cat)[grepl(paste0(x.name,"_"),colnames(cat))]
}

#Read the input catalogue {{{
cat<-helpRfuncs::read.file(input.cat,cols=unlist(psfexpvars))
#}}}

for (x.name in psfvars) { 
  for (col in psfexpvars[[x.name]]) { 
    cat[[col]][which(cat[[col]]==99)]<-NA
  }
  cat[[paste0(x.name,"_var")]]<-matrixStats::rowVars(as.matrix(cat[,psfexpvars[[x.name]],with=F]),na.rm=T)
}

#Keep only new columns 
cat<-cat[,paste0(psfvars,"_var"),with=F]

#Write the file {{{
helpRfuncs::write.file(file=output,cat)
#}}}
#Finish

