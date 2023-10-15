#=========================================
#
# File Name : add_rpr_weights.R
# Created By : awright
# Creation Date : 12-09-2023
# Last Modified : Fri 15 Sep 2023 11:12:40 AM CEST
#
#=========================================

#Require parallel packages 
require(foreach)
require(doParallel) 

#Loop through the command arguments /*fold*/ {{{
ncores<-128
data.missing<- -99
data.threshold<-c(0,40)
missing.value<-28
do.target.matches<-FALSE
original.weight<-""

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
  if (inputs[1]=='-r') {
    #Read the input reference catalogue(s) /*fold*/ {{{
    inputs<-inputs[-1]
    reference.file<-inputs[1]
    inputs<-inputs[-1]
    #/*fold*/}}}
  } else if (inputs[1]=='-t') {
    #Read the input target catalogue /*fold*/ {{{
    inputs<-inputs[-1]
    target.file<-inputs[1]
    inputs<-inputs[-1]
    #/*fold*/}}}
  } else if (inputs[1]=='-o') {
    #Read the output filename /*fold*/ {{{
    inputs<-inputs[-1]
    output.file<-inputs[1]
    inputs<-inputs[-1]
    #/*fold*/}}}
  } else if (inputs[1]=='-f') {
    #Read the matching features {{{
    if (any(grepl('^-',inputs[-1]))) {
      key.ids<-1:(which(grepl('^-',inputs[-1]))[1])
    } else {
      key.ids<-1:length(inputs)
    }
    features<-inputs[key.ids[c(-1)]]
    target.features<-features[seq(1,length(features),by=2)]
    reference.features<-features[seq(2,length(features),by=2)]
    inputs<-inputs[-(key.ids)]
    #}}}
  } else if (inputs[1]=='-st') {
    #Read the subsetting variables {{{
    inputs<-inputs[-1]
    subvar.target<-inputs[1]
    inputs<-inputs[-1]
    #}}}
  } else if (inputs[1]=='-sr') {
    #Read the subsetting variables {{{
    inputs<-inputs[-1]
    subvar.reference<-inputs[1]
    inputs<-inputs[-1]
    #}}}
  } else if (inputs[1]=='--cores'|inputs[1]=='-c') {
    #Define the number of cores /*fold*/ {{{
    inputs<-inputs[-1]
    ncores<-as.numeric(inputs[1])
    inputs<-inputs[-1]
    #/*fend*/}}}
  } else if (inputs[1]=='--data.missing') {
    #Define the value for missing data /*fold*/ {{{
    inputs<-inputs[-1]
    data.missing<-as.numeric(inputs[1])
    inputs<-inputs[-1]
    #/*fend*/}}}
  } else if (inputs[1]=='--data.threshold') {
    #Define the data threshold for features /*fold*/ {{{
    inputs<-inputs[-1]
    data.threshold<-as.numeric(inputs[1:2])
    inputs<-inputs[-2:-1]
    if (any(is.na(data.threshold))) { stop("data.threshold parameters are NA. For no thresholding, set --data.threshold -Inf Inf") }
    #/*fend*/}}}
  } else if (inputs[1]=='--missing.value') {
    #Define the value for missing data /*fold*/ {{{
    inputs<-inputs[-1]
    missing.value<-as.numeric(inputs[1])
    inputs<-inputs[-1]
    #/*fend*/}}}
  } else if (inputs[1]=='--weightname') {
    #Define the pre-existing weight column /*fold*/ {{{
    inputs<-inputs[-1]
    original.weight<-inputs[1]
    inputs<-inputs[-1]
    #/*fend*/}}}
  } else {
    stop(paste("Unknown option",inputs[1]))
  }
}
#}}}

cat(paste0("Starting Target Read [",Sys.time(),"]\n"))

#load the target catalogue {{{
columns<-unique(helpRfuncs::vecsplit(target.features,"[+/-]|\\*",fixed=FALSE))
columns<-c(columns,subvar.target)
#load the target catalogue (what we want to reproduce)
target.catalogue<-helpRfuncs::read.file(target.file,verbose=T,cols=columns)
#}}}

cat(paste0("Starting Reference Read [",Sys.time(),"]\n"))

#load the reference catalogue (what will receive weights) {{{
columns<-unique(helpRfuncs::vecsplit(reference.features,"[+/-]|\\*",fixed=FALSE))
columns<-c(columns,subvar.reference)
if (original.weight!="") { columns<-c(columns,original.weight) } 
reference.catalogue<-helpRfuncs::read.file(reference.file,verbose=T,cols=columns)
#}}}

cat(paste0("Whitening Target Data [",Sys.time(),"]\n"))

#Compute the target features with whitening {{{
kohwhiten.output<-kohonen::kohwhiten(data=target.catalogue,
                                     train.expr=target.features,
                                     data.missing=data.missing,data.threshold=data.threshold)
target<-kohwhiten.output$data.white
whiten.param<-kohwhiten.output$whiten.param
target[which(is.na(target))]<-missing.value
#}}}

cat(paste0("Whitening Reference Data [",Sys.time(),"]\n"))

#Compute the reference features with whitening {{{
kohwhiten.output<-kohonen::kohwhiten(data=reference.catalogue,
                                     train.expr=reference.features,whiten.param=whiten.param,
                                     data.missing=data.missing,data.threshold=data.threshold)
reference<-kohwhiten.output$data.white
whiten.param<-kohwhiten.output$whiten.param
reference[which(is.na(reference))]<-missing.value
#}}}

#Determine if the subvar is discrete {{{
if (length(which(duplicated(target.catalogue[[subvar.target]])))/nrow(target)>0.5){ 
  #Variable is discrete
  target.bins=as.numeric(cut(target.catalogue[[subvar.target]],breaks=sort(unique(target.catalogue[[subvar.target]])),include.lowest=TRUE))
  reference.bins=as.numeric(cut(reference.catalogue[[subvar.reference]],breaks=sort(unique(target.catalogue[[subvar.target]])),include.lowest=TRUE))
  nbreaks<-max(target.bins)
} else { 
  stop("non-discrete subsample variables are unimplemented") 
}
#}}}

#Register parallel threads 
registerDoParallel(cores=ncores)

cat(paste0("Determining Reference Matches [",Sys.time(),"]\n"))

#Get the binned matches between the target and reference samples {{{
matches.reference<-foreach(i=1:nbreaks,.combine='cbind')%dopar%{ 
  #Get the target and reference sources in this subset 
  ind.target<-which(target.bins==i)
  ind.reference<-which(reference.bins==i)
  nmatch.reference<-rep(0,nrow(reference))
  if (length(ind.reference)>0 & length(ind.target)>0) { 
    #Match target to reference sample 
    match.reference<-RANN::nn2(reference[ind.reference,,drop=FALSE],target[ind.target,,drop=FALSE],searchtype='priority',k=max(1,floor(length(ind.reference)/length(ind.target))))
    #Compute the number of matches 
    nmatch.reference[ind.reference]<-ifelse(as.numeric(table(factor(match.reference$nn.idx,levels=seq(length(ind.reference)))))>0,1,0)
  }
  #Return the number of matches 
  return(nmatch.reference)
}

#Sum over subsets to get the number of total matches per source 
nmatch.reference.all<-rowSums(matches.reference)
#}}}

#Add the frequency weights {{{
reference.catalogue$repr_weight<-nmatch.reference.all
#}}}

#Apply frequency weights to existing weight column {{{ 
if (original.weight!="") { 
  reference.catalogue[[original.weight]]<-reference.catalogue[[original.weight]]*nmatch.reference.all
} 
#}}}

#Output the weighted catalogues {{{
cat(paste0("Outputting Reference Matches [",Sys.time(),"]\n"))
helpRfuncs::write.file(file=output.file,reference.catalogue)
#}}}

#Match target sample sources {{{
if (do.target.matches) { 
  cat(paste0("Determining Target Matches [",Sys.time(),"]\n"))

  #Get the binned matches between the target and reference samples {{{
  matches.target<-foreach(i=1:nbreaks,.combine='cbind')%dopar%{ 
    #Get the target and reference sources in this subset 
    ind.target<-which(target.bins==i)
    ind.reference<-which(reference.bins==i)
    nmatch.target<-rep(0,nrow(target))
    if (length(ind.reference)>0 & length(ind.target)>0) { 
      #Match target to reference sample 
      match.target<-RANN::nn2(target[ind.target,,drop=FALSE],reference[ind.reference,,drop=FALSE],
                              searchtype='priority',
                              k=max(1,floor(length(ind.target)/length(ind.reference))))
      #Compute the number of matches 
      nmatch.target[ind.target]<-ifelse(as.numeric(table(factor(match.target$nn.idx,levels=seq(length(ind.target)))))>0,1,0)
    }
    #Return the number of matches 
    return(nmatch.target)
  }
  
  #Sum over subsets to get the number of total matches per source 
  nmatch.target.all<-rowSums(matches.target)
  #}}}
  
  target.catalogue$repr_weight<-nmatch.target.all
  
  cat(paste0("Outputting Target Matches [",Sys.time(),"]\n"))
  helpRfuncs::write.file(file=target.file,target.catalogue)
  
} 
#}}}

cat(paste0("Finished [",Sys.time(),"]\n"))

