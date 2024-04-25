#=========================================
#
# File Name : column_split.R
# Created By : awright
# Creation Date : 10-07-2023
# Last Modified : Thu Apr 11 13:06:57 2024
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
  } else if (inputs[1]=='-o') { 
    #Read the output catalogue(s) /*fold*/ {{{
    inputs<-inputs[-1]
    if (any(grepl('^-',inputs))) { 
      output.cats<-inputs[1:(which(grepl('^-',inputs))[1]-1)]
      inputs<-inputs[-(1:(which(grepl('^-',inputs))[1]-1))]
    } else { 
      output.cats<-inputs
      inputs<-NULL
    } 
    #/*fold*/}}}
  } else if (inputs[1]=='-v') { 
    #Read the spatial column names /*fold*/ {{{
    inputs<-inputs[-1]
    x.name<-inputs[1]
    inputs<-inputs[-1]
    #/*fold*/}}}
  } else if (inputs[1]=='--id_only') { 
    #Read the spatial column names /*fold*/ {{{
    inputs<-inputs[-1]
    ID_only<-TRUE
    #/*fold*/}}}
  } else if (inputs[1]=='--n_only') { 
    #Read the spatial column names /*fold*/ {{{
    inputs<-inputs[-1]
    N_only<-TRUE
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
if (!x.name %in% colnames(cat)) {  
  stop(paste(x.name,"variable is not in provided catalogue!")) 
}

#Read the input catalogue {{{
if (N_only | ID_only) { 
  cat<-helpRfuncs::read.file(input.cat,cols=x.name)
} else { 
  cat<-helpRfuncs::read.file(input.cat)
} 
#}}}

#Set up the cut object (for faster splitting) {{{
tmp<-data.frame(x=factor(cat[[x.name]]))
#}}}

nsplit=length(levels(tmp$x))

if (!N_only) { 
  #Check that length of the output files is correct {{{
  if (!ID_only) { 
    if (length(output.cats)!=nsplit) { 
      stop("Output file list must be of length nsplit") 
    } 
  }
  #}}}
  
  #Create bins {{{
  if (nsplit==1) { 
    #There is only one bin?! {{{
    cat('Only one bin!\n')
    bins<-rep(1,nrow(tmp))
    #}}}
  } else {
    #Bin in x & y {{{
    cat('binning in x\n')
    bins<-with(tmp,tapply(1:nrow(tmp),list(x=cut(as.numeric(x),breaks=0:length(levels(x)),include.lowest=T))))
    #}}}
  }
  #}}}
  
  cat('bin occupation:\n')
  print(table(bins))
  
  #For each split, output the catalogue {{{
  if (ID_only) { 
    out<-cat
    out$splitvar<-bins
    #Write the file {{{
    helpRfuncs::write.file(file=output.cats[1],out)
    #}}}
  } else { 
    written<-FALSE
    for (i in seq(1,nsplit)) { 
      #Select the relevant sources {{{
      out<-cat[which(bins==i),]
      #}}}
      cat(paste('bin',i,x.name,'stats:\n'))
      print(summary(out[[x.name]]))
    
      if (nrow(out)==0) { 
        cat(paste("WARNING: split",i,"contains no sources?!\n"))
      } else { 
        #Write the file {{{
        helpRfuncs::write.file(file=output.cats[i],out)
        #}}}
        written<-TRUE
      }
    } 
    if (!written) { 
      stop("Nothing was written to disk?!") 
    }
  }
  #}}}
} else { 
  cat(nsplit)
}
#Finish

