#=========================================
#
# File Name : add_head.sh
# Created By : awright
# Creation Date : 30-03-2023
# Last Modified : Fri Jul 19 03:16:27 2024
#
#=========================================


#If needed, create the output directory 
if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/DATAHEAD/ ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/DATAHEAD/
fi 

#Create the uncertainty file 
outlist=""
if [ -f @BV:INPUTS@ ]
then 
  file="@BV:INPUTS@"
  file=${file##*/}
  cp @BV:INPUTS@ @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/DATAHEAD/${file}
  outlist=${file}
elif [ -d @BV:INPUTS@ ]
then 
  filelist=`ls @BV:INPUTS@/*`
  for file in ${filelist} 
  do 
    cp ${file} @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/DATAHEAD/${file##*/}
    outlist="${outlist} ${file##*/}"
  done 
else 
  _message "@RED@- ERROR! Input INPUTS variable is neither a file nor a directory"
  exit 1 
fi 

#Update the datablock contents file 
_writelist_datahead "${outlist}"
