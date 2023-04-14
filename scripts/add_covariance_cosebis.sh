#=========================================
#
# File Name : add_nzcov.sh
# Created By : awright
# Creation Date : 30-03-2023
# Last Modified : Tue 11 Apr 2023 06:36:20 AM UTC
#
#=========================================


if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosebis_cov ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosebis_cov
fi 

file="@COSEBICOVFILE@"
file=${file##*/}

#Create the uncertainty file 
cp @COSEBICOVFILE@ @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosebis_cov/${file}

#Update the datablock contents file 
_write_datablock "cosebis_cov" "${file}"
