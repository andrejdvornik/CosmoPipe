#=========================================
#
# File Name : add_rpr_weights.R
# Created By : awright
# Creation Date : 12-09-2023
# Last Modified : Thu May 16 18:16:19 2024
#
#=========================================

#Loop through the command arguments /*fold*/ {{{
id_only<-FALSE
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
  if (inputs[1]=='-i') {
    #Read the input reference catalogue(s) /*fold*/ {{{
    inputs<-inputs[-1]
    input.file<-inputs[1]
    inputs<-inputs[-1]
    #/*fold*/}}}
  } else if (inputs[1]=='--id_only') {
    #output id's only? /*fold*/ {{{
    inputs<-inputs[-1]
    id_only<-TRUE
    #/*fold*/}}}
  } else if (inputs[1]=='-l') {
    #Read the output filename /*fold*/ {{{
    inputs<-inputs[-1]
    limits.file<-inputs[1]
    inputs<-inputs[-1]
    #/*fold*/}}}
  } else if (inputs[1]=='-o') {
    #Read the output filename /*fold*/ {{{
    inputs<-inputs[-1]
    output.file<-inputs[1]
    inputs<-inputs[-1]
    #/*fold*/}}}
  } else {
    stop(paste("Unknown option",inputs[1]))
  }
}
#}}}

cat(paste0("Starting Input Read [",Sys.time(),"]\n"))

#load the input catalogue {{{
if (id_only) { 
  cat<-helpRfuncs::read.file(input.file,verbose=T,cols=c("RAJ2000","DECJ2000"))
} else { 
  cat<-helpRfuncs::read.file(input.file,verbose=T)
} 
#}}}

#load the limits catalogue {{{
lims<-helpRfuncs::read.file(limits.file,verbose=FALSE)
lims<-as.data.frame(lims)
#}}}

ra<-cat$RAJ2000
dec<-cat$DECJ2000
ra[which(ra>300)]<-ra[which(ra>300)]-360
lims[which(lims[,2]>300),2]<- lims[which(lims[,2]>300),2]-360
lims[which(lims[,3]>300),3]<- lims[which(lims[,3]>300),3]-360

#Select sources {{{
keep<-rep(TRUE,nrow(cat))
for (i in 1:nrow(lims)) { 
  ind<-(ra>=lims[i,2] & 
        ra<=lims[i,3] & 
        dec>=lims[i,4] & 
        dec<=lims[i,5])
  keep[ind]<-FALSE
}
if (!id_only) { 
  cat<-cat[which(keep),]
} else { 
  cat$fieldsel<-ifelse(keep,1,0)
} 
#}}}

cat(paste0("Removing ",length(which(!keep))," of ",length(keep)," sources (",round(digits=2,length(which(keep))/length(keep)*100),"% remain)\n"))

#Output the weighted catalogues {{{
cat(paste0("Outputting selection sources [",Sys.time(),"]\n"))
helpRfuncs::write.file(file=output.file,cat,verbose=T)
#}}}

cat(paste0("Finished [",Sys.time(),"]\n"))

