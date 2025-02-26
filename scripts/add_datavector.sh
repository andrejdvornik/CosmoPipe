#=========================================
#
# File Name : add_datavector.sh
# Created By : awright
# Creation Date : 30-03-2023
# Last Modified : Thu 30 Jan 2025 09:27:54 PM CET
#
#=========================================


#If needed, create the output directory 
if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/@BV:DATAVECBLOCK@ ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/@BV:DATAVECBLOCK@/
fi 

file="@BV:DATAVECPATH@"
file=${file##*/}

#Create the uncertainty file 
cp @BV:DATAVECPATH@ @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/@BV:DATAVECBLOCK@/${file}

#Update the datablock contents file 
_write_datablock "@BV:DATAVECBLOCK@" "${file}"
