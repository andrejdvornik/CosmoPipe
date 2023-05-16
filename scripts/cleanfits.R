#=========================================
#
# File Name : cleanfits.R
# Created By : awright
# Creation Date : 09-05-2023
# Last Modified : Tue 16 May 2023 02:32:41 PM CEST
#
#=========================================


#Read the input file name 
input<-commandArgs(T)[1]

#Read the reduced catalogue 
cat<-Rfits::Rfits_read_table(input,verbose=T,nrow=1e3)
#Convert integer64 into integer (not handled by ldac) 
classes<-unlist(lapply(cat,class))
include_fields=TRUE
if (any(classes=="integer64")) {
  cat<-Rfits::Rfits_read_table(input,verbose=T)
  for (i in names(classes)[which(classes=='integer64')]) {
    cat[[i]]<-as.integer(cat[[i]])
  }
  if (include_fields) {
    #Construct the output file 
    cat$FIELD_POS<-1
    fields<-data.frame(OBJECT_POS=as.integer(1),OBJECT_COUNT=nrow(cat),CHANNEL_NR=as.integer(0),CHANNEL_NAME="I",SubNr=as.integer(1))
    attr(cat,'keyvalues')[which(attr(cat,'keynames')=='EXTNAME')]<-"OBJECTS"
    attr(fields,'keynames')<-c("XTENSION","BITPIX","NAXIS","NAXIS1","NAXIS2","PCOUNT","GCOUNT")
    attr(fields,'keyvalues')<-list("BINTABLE","8","2","1","5","0","1")
    attr(fields,'keycomments')<-list("","","","","","","")
    names(attr(fields,'keyvalues'))<-attr(fields,'keynames')
    names(attr(fields,'keycomments'))<-attr(fields,'keynames')
    out<-list(OBJECTS=cat,FIELDS=fields)
    #Write out the cleaned catalogue 
    Rfits::Rfits_write_all(file=input,out)
  } else { 
    Rfits::Rfits_write_table(file=input,cat,verbose=TRUE)
  } 
} else if (include_fields) { 
  cat$FIELD_POS<-1
  fields<-data.frame(OBJECT_POS=as.integer(1),OBJECT_COUNT=nrow(cat),CHANNEL_NR=as.integer(0),CHANNEL_NAME="I",SubNr=as.integer(1))
  extn<-Rfits::Rfits_extnames(filename=input)
  if (all(extn!="OBJECTS",na.rm=T)) { 
    Rfits::Rfits_write_key(file=input,"EXTNAME","OBJECTS","",ext=length(extn))
  } 
  Rfits::Rfits_write_table(file=input,fields,verbose=T,extname="FIELDS",ext=length(extn)+1,
                           overwrite_file=FALSE,create_file=FALSE,verbose=TRUE)
}


