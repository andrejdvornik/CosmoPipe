#=========================================
#
# File Name : correct_2D_cterm.R
# Created By : awright
# Creation Date : 10-07-2023
# Last Modified : Thu 25 Apr 2024 09:58:03 AM CEST
#
#=========================================

#Read input parameters 
inputs<-commandArgs(TRUE) 

#Interpret the command line options {{{
seed<-666
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
  } else if (inputs[1]=='-o') { 
    #Read the output catalogue(s) /*fold*/ {{{
    inputs<-inputs[-1]
    output<-inputs[1]
    inputs<-inputs[-1]
    #/*fold*/}}}
  } else if (inputs[1]=='-s') { 
    #Read the random seed /*fold*/ {{{
    inputs<-inputs[-1]
    seed<-inputs[1]
    inputs<-inputs[-1]
    #/*fold*/}}}
  } else {
    stop(paste("Unknown option",inputs[1]))
  }
}
#}}}

#Read the input catalogue for col names {{{
cat<-helpRfuncs::read.file(input.cat,nrow=10)
cols<-colnames(cat)
#}}}

cat<-helpRfuncs::read.file(input.cat,cols=cols[1])

set.seed(seed)
cat$sparse_var<-runif(nrow(cat))

#Write the file {{{
helpRfuncs::write.file(file=output,cat)
#}}}
#Finish

