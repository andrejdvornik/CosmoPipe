#=========================================
#
# File Name : fitskeepcols.R
# Created By : awright
# Creation Date : 13-06-2023
# Last Modified : Tue 13 Jun 2023 04:05:13 PM CEST
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
  if (inputs[1]=='-i') { 
    #Read the input catalogue /*fold*/ {{{
    inputs<-inputs[-1]
    input.file<-inputs[1]
    inputs<-inputs[-1]
    #/*fold*/}}}
  } else if (inputs[1]=='-o') { 
    #Read the output catalogue /*fold*/ {{{
    inputs<-inputs[-1]
    output.file<-inputs[1]
    inputs<-inputs[-1]
    #/*fold*/}}}
  } else if (inputs[1]=='-k') { 
    #Read the column match-strings /*fold*/ {{{
    inputs<-inputs[-1]
    if (any(grepl('^-',inputs))) { 
      keepstrings<-inputs[1:(which(grepl('^-',inputs))[1]-1)]
      inputs<-inputs[-(1:(which(grepl('^-',inputs))[1]-1))]
    } else { 
      keepstrings<-inputs
      inputs<-NULL
    } 
    #/*fold*/}}}
  } else {
    stop(paste("Unknown option",inputs[1]))
  }
}

#Check keepstrings 
keepstrings<-helpRfuncs::vecsplit(keepstrings," ")
print(paste0("Strings:\n",keepstrings))

#Read the column names 
colnam<-Rfits::Rfits_read_colnames(input.file)
print(colnam) 
colkeep<-rep(FALSE,length(colnam))
for (keep in keepstrings) { 
  print(keep) 
  colkeep<-colkeep | grepl(keep,colnam,ignore.case=TRUE)
}

if (all(colkeep)) { 
  #We are keeping everything! Skip
  cat("All columns are needed, skipping!\n") 
} else if (any(colkeep)) { 
  colkeep=colnam[which(colkeep)]
  print(colkeep)

  #Read in the catalogue 
  inp<-helpRfuncs::read.file(file=input.file,cols=colkeep)
  
  #Write out the catalogue 
  helpRfuncs::write.file(file=output.file,inp)
} else { 
  stop("ERROR: All columns would be deleted?!")
}


