#=========================================
#
# File Name : convert_to_ldac.R
# Created By : awright
# Creation Date : 09-05-2023
# Last Modified : Sat 03 Jun 2023 04:48:21 PM CEST
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

#Check the extension names 
extn<-Rfits::Rfits_extnames(filename=input)
extn[which(is.na(extn))]<-""
#Save the original extensions for output 
oextn<-extn
#Check if we have an OBJECTS extension 
if (all(extn!="OBJECTS")) { 
  #If we have multiple extensions 
  if (length(extn)>1) { 
    #Read the extensions and find the one that is OBJECTS
    for (i in 1:length(extn)) { 
      cat<-try(Rfits::Rfits_read_table(input,verbose=T,nrow=1e3,ext=i))
      if (class(cat)[1]=='try-error'){ 
        #This looks like a primary extension 
        extn[i]<-'primary'
      } else if (any(grepl('CHANNEL_',colnames(cat))) & any(grepl("OBJECT_POS",colnames(cat)))) { 
        #This looks like FIELDS
        extn[i]<-'FIELDS'
      } else { 
        #Assume it's OBJECTS
        extn[i]<-'OBJECTS'
      }
    } 
  } else { 
    extn<-"OBJECTS"
  }
} 
cat("Original Extensions:\n")
print(oextn)
cat("Inferred Extensions:\n")
print(extn)
#If there is no OBJECTS extension?!
if (all(extn!='OBJECTS')) { 
  stop(paste0("ERROR: There is no extension that looks like OBJECTS in the input file?!\n",input))
}
#Read the reduced catalogue 
cat(paste("Reading sample of input catalogue:",input,'\n'))
cat<-Rfits::Rfits_read_table(input,verbose=T,nrow=1e3,ext=which(extn=='OBJECTS'))
#Convert integer64 into integer (not handled by ldac) 
cat(paste("Checking catalogue classes for int64\n"))
classes<-unlist(lapply(cat,class))
#Check if there are any int64 cols, or if there is no FIELD_POS/SeqNr
if (any(classes=="integer64") | !any(colnames(cat)=="FIELD_POS") | !any(colnames(cat)=="SeqNr")) {
  cat(paste("Catalogue contains int64, or is missing FIELD_POS or SeqNr columns\n"))
  cat(paste("Reading full catalogue\n"))
  cat<-Rfits::Rfits_read_table(input,verbose=T,ext=which(extn=='OBJECTS'))
  for (i in names(classes)[which(classes=='integer64')]) {
    cat(paste("Converting column",i,"from int64\n"))
    cat[[i]]<-as.integer(cat[[i]])
  }
  #Construct the output file 
  #Add the field pos column
  if (!any(colnames(cat)=="SeqNr")) {
    cat(paste("Adding SeqNr column\n"))
    cat$SeqNr<-as.integer(1:nrow(cat))
  }
  #Add the field pos column
  if (!any(colnames(cat)=="FIELD_POS")) {
    cat(paste("Adding FIELD_POS column\n"))
    cat$FIELD_POS<-as.integer(1)
  }
  #Get the column types 
  cattypes<-get_types(cat)
  #use short int for the FIELD_POS
  cattypes[which(colnames(cat)=='FIELD_POS')]<-'1I'
  #Read or make the FIELDS extension 
  if (any(extn=='FIELDS')) { 
    #Read the existing FIELDS table  
    cat(paste("Reading existing FIELDS table\n"))
    fields<-Rfits::Rfits_read_table(input,verbose=T,ext=which(extn=='FIELDS'))
  } else {
    cat(paste("Constructing new FIELDS table\n"))
    fields<-data.frame(OBJECT_POS=as.integer(1),OBJECT_COUNT=nrow(cat),CHANNEL_NR=as.integer(0),CHANNEL_NAME="I",SubNr=as.integer(1))
  } 
  #Update the OBJECTS extension 
  if (any(oextn=='OBJECTS')) { 
    #Write out the cleaned catalogue 
    cat(paste("Writing OBJECTS catalogue to existing OBJECTS extension:",which(oextn=='OBJECTS'),"\n"))
    Rfits::Rfits_write_table(file=input,cat,tforms=cattypes,verbose=TRUE,extname="OBJECTS",
                             ext=which(oextn=='OBJECTS'),overwrite_file=FALSE,create_file=FALSE,create_ext=FALSE)
  } else {
    cat(paste("Writing OBJECTS catalogue to clean file\n"))
    Rfits::Rfits_write_table(file=input,cat,tforms=cattypes,verbose=TRUE,extname="OBJECTS")
  } 
  #Construct the fields extension comments 
  fcomms<-list(TCOMM1  = 'Starting position of field', TCOMM2  = 'Number of objects in field', TCOMM3  = 'Channel numbers', TCOMM4  = 'Channel name', TCOMM5  = 'Subset Number')

  #Get the data types
  cattypes<-get_types(fields)
  cattypes[which(colnames(fields)=="CHANNEL_NAME")]<-"16A"
  #Write FIELDS 
  if (any(extn=='FIELDS')) { 
    #Write out the cleaned catalogue 
    cat(paste("Writing FIELDS catalogue to existing FIELDS extension:",which(extn=='FIELDS'),"\n"))
    Rfits::Rfits_write_table(file=input,fields,tforms=cattypes,verbose=TRUE,extname="FIELDS",ext=which(extn=='FIELDS'),overwrite_file=FALSE,create_file=FALSE,tadd=fcomms,create_ext=FALSE)
  } else {
    extn<-Rfits::Rfits_extnames(filename=input)
    extn[which(is.na(extn))]<-""
    cat(paste("Writing FIELDS catalogue to new extension:",length(extn)+1,"\n"))
    Rfits::Rfits_write_table(file=input,fields,extname="FIELDS",ext=length(extn)+1,tforms=cattypes,tadd=fcomms,
                           overwrite_file=FALSE,create_file=FALSE,verbose=TRUE,create_ext=TRUE)
  } 
} else if (all(oextn!="OBJECTS",na.rm=T) | all(oextn!="FIELDS",na.rm=T)) { 
  #If needed, rename OBJECTS
  if (all(oextn!="OBJECTS",na.rm=T)) { 
    #Rename this extension OBJECTS
    cat(paste("Renaming Extension",which(extn=='OBJECTS'),'from',oextn[which(extn=='OBJECTS')],"to OBJECTS\n"))
    Rfits::Rfits_write_key(file=input,"EXTNAME","OBJECTS","",ext=which(extn=='OBJECTS'))
  } 
  #If needed, write FIELDS
  if (all(oextn!="FIELDS",na.rm=T)) { 
    if (any(extn=="FIELDS",na.rm=T)) { 
      #Rename this extension FIELDS
      cat(paste("Renaming Extension",which(extn=='FIELDS'),'from',oextn[which(extn=='FIELDS')],"to FIELDS\n"))
      Rfits::Rfits_write_key(file=input,"EXTNAME","FIELDS","",ext=which(extn=='FIELDS'))
    } else { 
      #Construct the fields extension 
      cat(paste("Writing FIELDS catalogue to new extension:",length(extn)+1,"\n"))
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
}


