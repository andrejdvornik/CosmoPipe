#=========================================
#
# File Name : cleanfits.R
# Created By : awright
# Creation Date : 09-05-2023
# Last Modified : Fri 19 May 2023 08:14:40 PM CEST
#
#=========================================


#Get types function 
get_types<-function(table) { 
  ttypes = colnames(table)
  check.logical = sapply(table, is.logical)
  check.int = sapply(table, is.integer)
  check.integer64 = sapply(table, bit64::is.integer64)
  check.double = sapply(table, is.numeric) & (!check.int) & (!check.integer64)
  check.char = sapply(table, is.character)
  tforms = character(ncol(table))
  tforms[check.logical] = "1J"
  tforms[check.int] = "1J"
  tforms[check.integer64] = "1K"
  tforms[check.double] = "1D"
  if (data.table::is.data.table(table)) { 
    tforms[check.char] = paste(sapply(table[, ..check.char,drop = FALSE], function(x) max(nchar(x)) + 1),"A", sep = "")
  } else { 
    tforms[check.char] = paste(sapply(table[, check.char,drop = FALSE], function(x) max(nchar(x)) + 1),"A", sep = "")
  } 
  return=tforms
}


#Read the input file name 
input<-commandArgs(T)[1]

#Read the reduced catalogue 
cat<-Rfits::Rfits_read_table(input,verbose=T,nrow=1e3)
#Convert integer64 into integer (not handled by ldac) 
classes<-unlist(lapply(cat,class))
#Check the extension names 
extn<-Rfits::Rfits_extnames(filename=input)
extn[which(is.na(extn))]<-""
#Check if there are any int64 cols, or if there is no FIELD_POS
if (any(classes=="integer64") | !any(colnames(cat)=="FIELD_POS") | !any(colnames(cat)=="SeqNr")) {
  cat<-Rfits::Rfits_read_table(input,verbose=T)
  for (i in names(classes)[which(classes=='integer64')]) {
    cat[[i]]<-as.integer(cat[[i]])
  }
  #Construct the output file 
  #Add the field pos column
  if (!any(colnames(cat)=="SeqNr")) {
    cat$SeqNr<-as.integer(1:nrow(cat))
  }
  #Add the field pos column
  if (!any(colnames(cat)=="FIELD_POS")) {
    cat$FIELD_POS<-as.integer(1)
  }
  #Get the column types 
  cattypes<-get_types(cat)
  #use short int for the FIELD_POS
  cattypes[which(colnames(cat)=='FIELD_POS')]<-'1I'
  #Update the OBJECTS extension 
  if (any(extn=='OBJECTS')) { 
    #Write out the cleaned catalogue 
    Rfits::Rfits_write_table(file=input,cat,tforms=cattypes,verbose=TRUE,extname="OBJECTS",ext=which(extn=='OBJECTS'),overwrite_file=FALSE,create_file=FALSE)
  } else {
    Rfits::Rfits_write_table(file=input,cat,tforms=cattypes,verbose=TRUE,extname="OBJECTS")
  } 
  #Construct the fields extension 
  fields<-data.frame(OBJECT_POS=as.integer(1),OBJECT_COUNT=nrow(cat),CHANNEL_NR=as.integer(0),CHANNEL_NAME="I",SubNr=as.integer(1))
  fcomms<-list(TCOMM1  = 'Starting position of field', TCOMM2  = 'Number of objects in field', TCOMM3  = 'Channel numbers', TCOMM4  = 'Channel name', TCOMM5  = 'Subset Number')

  #Get the data types
  cattypes<-get_types(fields)
  cattypes[which(colnames(fields)=="CHANNEL_NAME")]<-"16A"
  #Write FIELDS 
  if (any(extn=='FIELDS')) { 
    #Write out the cleaned catalogue 
    Rfits::Rfits_write_table(file=input,fields,tforms=cattypes,verbose=TRUE,extname="FIELDS",ext=which(extn=='FIELDS'),overwrite_file=FALSE,create_file=FALSE,tadd=fcomms)
  } else {
    extn<-Rfits::Rfits_extnames(filename=input)
    extn[which(is.na(extn))]<-""
    Rfits::Rfits_write_table(file=input,fields,extname="FIELDS",ext=length(extn)+1,tforms=cattypes,tadd=fcomms,
                           overwrite_file=FALSE,create_file=FALSE,verbose=TRUE)
  } 
} else if (all(extn!="OBJECTS",na.rm=T) | all(extn!="FIELDS",na.rm=T)) { 
  #If needed, rename OBJECTS
  if (all(extn!="OBJECTS",na.rm=T)) { 
    Rfits::Rfits_write_key(file=input,"EXTNAME","OBJECTS","",ext=length(extn))
  } 
  #If needed, write FIELDS
  if (all(extn!="FIELDS",na.rm=T)) { 
    #Construct the fields extension 
    fields<-data.frame(OBJECT_POS=as.integer(1),OBJECT_COUNT=nrow(cat),CHANNEL_NR=as.integer(0),CHANNEL_NAME="I",SubNr=as.integer(1))
    fcomms<-list(TCOMM1  = 'Starting position of field', TCOMM2  = 'Number of objects in field', TCOMM3  = 'Channel numbers', TCOMM4  = 'Channel name', TCOMM5  = 'Subset Number')
    #Get the data types
    cattypes<-get_types(fields)
    cattypes[which(colnames(fields)=="CHANNEL_NAME")]<-"16A"
    #Write FIELDS 
    Rfits::Rfits_write_table(file=input,fields,extname="FIELDS",ext=length(extn)+1,tforms=cattypes,tadd=fcomms,
                           overwrite_file=FALSE,create_file=FALSE,verbose=TRUE)
  }
}


