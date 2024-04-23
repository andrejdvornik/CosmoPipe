#=========================================
#
# File Name : inflate_covariances.R
# Created By : awright
# Creation Date : 22-03-2024
# Last Modified : Thu Apr 11 08:29:59 2024
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
  if (inputs[1]=='--input') { 
    #Read the input catalogue(s) /*fold*/ {{{
    inputs<-inputs[-1]
    file<-inputs[1]
    inputs<-inputs[-1]
    #/*fold*/}}}
  } else if (inputs[1]=='--factor') { 
    # Define the output file name {{{
    inputs<-inputs[-1]
    factor<-as.numeric(inputs[1])
    inputs<-inputs[-1]
    #/*fend*/}}}
  } else if (inputs[1]=='--output') { 
    # Define the output file name {{{
    inputs<-inputs[-1]
    output<-inputs[1]
    inputs<-inputs[-1]
    #/*fend*/}}}
  } else {
    stop(paste("Unknown option",inputs[1]))
  }
}

cov<-as.matrix(data.table::fread(file=file))
cov<-cov*factor
data.table::fwrite(file=output,as.data.frame(cov),sep=' ',col.names=FALSE)

