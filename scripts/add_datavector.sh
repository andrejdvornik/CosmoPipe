#=========================================
#
# File Name : add_datavector.sh
# Created By : awright
# Creation Date : 30-03-2023
# Last Modified : Tue 02 May 2023 08:58:43 AM CEST
#
#=========================================


#If needed, create the output directory 
if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosebis_vec ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosebis_vec/
fi 

file="@COSEBIDATAVEC@"
file=${file##*/}

#Create the uncertainty file 
cp @COSEBIDATAVEC@ @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosebis_vec/${file}

#Update the datablock contents file 
_write_datablock "cosebis_vec" "${file}"
