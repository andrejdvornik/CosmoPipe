#=========================================
#
# File Name : cleanfits.R
# Created By : awright
# Creation Date : 09-05-2023
# Last Modified : Mon 15 May 2023 11:11:50 AM CEST
#
#=========================================


#Read the input file name 
input<-commandArgs(T)[1]

#Read the reduced catalogue 
cat<-Rfits::Rfits_read_table(input,verbose=T,nrow=1e3)
#Convert integer64 into integer (not handled by ldac) 
classes<-unlist(lapply(cat,class))
if (any(classes=="integer64")) {
  cat<-Rfits::Rfits_read_table(input,verbose=T)
  for (i in names(classes)[which(classes=='integer64')]) {
    cat[[i]]<-as.integer(cat[[i]])
  }
  include_fields=TRUE
  if (include_fields) {
    #Construct the output file 
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
    Rfits::Rfits_write_table(file=input,cat,verbose=T)
  } 
}
