#=========================================
#
# File Name : correct_2D_cterm.R
# Created By : awright
# Creation Date : 10-07-2023
# Last Modified : Fri Apr 12 13:37:14 2024
#
#=========================================

#Read input parameters 
inputs<-commandArgs(TRUE) 

#Interpret the command line options {{{
badval<- -999
nbins<- 25
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
  } else if (inputs[1]=='-v') { 
    #Read the spatial column names /*fold*/ {{{
    inputs<-inputs[-1]
    x.name<-inputs[1]
    y.name<-inputs[2]
    inputs<-inputs[-1:-2]
    #/*fold*/}}}
  } else if (inputs[1]=='-e') { 
    #Read the spatial column names /*fold*/ {{{
    inputs<-inputs[-1]
    e1.name<-inputs[1]
    e2.name<-inputs[2]
    inputs<-inputs[-1:-2]
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
#Check that the x.name varaible is in the catalogue 
if (!y.name %in% colnames(cat)) {  
  stop(paste(y.name,"variable is not in provided catalogue!")) 
}
#Check that the e1.name varaible is in the catalogue 
if (!e1.name %in% colnames(cat)) {  
  stop(paste(e1.name,"variable is not in provided catalogue!")) 
}
#Check that the e2.name varaible is in the catalogue 
if (!e2.name %in% colnames(cat)) {  
  stop(paste(e2.name,"variable is not in provided catalogue!")) 
}

cat<-helpRfuncs::read.file(input.cat,cols=c(x.name,y.name,e1.name,e2.name))

#Set up the cut object (for faster splitting) {{{
tmp<-data.frame(x=cat[[x.name]],y=cat[[y.name]],e1=cat[[e1.name]],e2=cat[[e2.name]])
#}}}

#Compute c terms {{{
cat('computing bins\n')
x.bin<-seq(min(tmp$x,na.rm=T),max(tmp$x,na.rm=T),length=nbins+1)
y.bin<-seq(min(tmp$y,na.rm=T),max(tmp$y,na.rm=T),length=nbins+1)
bins<-with(tmp,tapply(e1,list(x=cut(x, breaks=x.bin, include.lowest=T),
                              y=cut(y, breaks=y.bin, include.lowest=T))))
cat('computing 2D c1\n')
c1mean<-with(tmp,tapply(e1,list(x=cut(x, breaks=x.bin, include.lowest=T),
                                y=cut(y, breaks=y.bin, include.lowest=T)),mean))
cat('computing 2D c1\n')
c2mean<-with(tmp,tapply(e2,list(x=cut(x, breaks=x.bin, include.lowest=T),
                                y=cut(y, breaks=y.bin, include.lowest=T)),mean))
#}}}

#Remove c terms {{{
cat[[e1.name]]<-cat[[e1.name]]-c1mean[bins]
cat[[e2.name]]<-cat[[e2.name]]-c2mean[bins]
cat<-cat[,c(e1.name,e2.name),with=F]
cat[["c1_2D_mean"]]<-c1mean[bins]
cat[["c2_2D_mean"]]<-c2mean[bins]
#}}}

#Write the file {{{
helpRfuncs::write.file(file=output,cat)
#}}}
#Finish

