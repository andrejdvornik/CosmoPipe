#=========================================
#
# File Name : add_rpr_weights.R
# Created By : awright
# Creation Date : 12-09-2023
# Last Modified : Fri 22 Sep 2023 10:35:27 AM CEST
#
#=========================================

#Default parameters 
weight.name<-'SOMweight'

#Loop through the command arguments /*fold*/ {{{
inputs<-commandArgs(TRUE)
while (length(inputs)!=0) {
  #Check the options syntax /*fold*/ {{{
  while (length(inputs)!=0 && inputs[1]=='') { inputs<-inputs[-1] }
  if (!grepl('^-',inputs[1])) {
    print(inputs)
    stop(paste("Incorrect options provided!",
               "Check the lengths for each option!\n",
               "Only -i and -k parameters can have more than 1 item"))
  }
  #/*fend*/}}}
  if (inputs[1]=='-p') {
    #Read the input target catalogue /*fold*/ {{{
    inputs<-inputs[-1]
    if (any(grepl('^-',inputs[-1]))) {
      key.ids<-1:(which(grepl('^-',inputs[-1]))[1])
    } else {
      key.ids<-1:length(inputs)
    }
    class.files<-inputs[key.ids]
    inputs<-inputs[-(key.ids)]
    #/*fold*/}}}
  } else if (inputs[1]=='-o') {
    #Read the output filename /*fold*/ {{{
    inputs<-inputs[-1]
    output.file<-inputs[1]
    inputs<-inputs[-1]
    #/*fold*/}}}
  } else if (inputs[1]=='-w') {
    #Read the input catalogue /*fold*/ {{{
    inputs<-inputs[-1]
    weight.name<-inputs[1]
    inputs<-inputs[-1]
    #/*fold*/}}}
  } else {
    stop(paste("Unknown option",inputs[1]))
  }
}
#}}}

#Loop over weight files, reading only the weight {{{
for (file in class.files) { 
  cat(paste0("Starting Gold Class File Read [",Sys.time(),"]\n"))

  #load the reference catalogue (what will receive weights) {{{
  tmp.weight<-helpRfuncs::read.file(file,verbose=T,cols=weight.name)
  #}}}

  if (file == class.files[1]) { 
    #Initialise the output file 
    input.catalogue<-tmp.weight
  } else { 
    #Add the weight to the vector
    if (nrow(tmp.weight)!=nrow(input.catalogue)) { 
      stop("class file and input file have different lengths?!")
    } 
    #Increment the weights 
    input.catalogue[[weight.name]]<-input.catalogue[[weight.name]]+tmp.weight[[weight.name]]
  }
}

#Normalise weight 
input.catalogue[[weight.name]]<-input.catalogue[[weight.name]]/length(class.files)

#Output the weighted catalogues {{{
cat(paste0("Outputting Gold Weight Catalogue [",Sys.time(),"]\n"))
helpRfuncs::write.file(file=output.file,input.catalogue)
#}}}

cat(paste0("Finished [",Sys.time(),"]\n"))

