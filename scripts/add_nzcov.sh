#=========================================
#
# File Name : add_nzcov.sh
# Created By : awright
# Creation Date : 30-03-2023
# Last Modified : Mon 18 Mar 2024 04:14:08 AM CET
#
#=========================================


if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/nzcov ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/nzcov
fi 

#Create the uncertainty file 
cp @BV:NZCOVFILE@ @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/nzcov/nz_covariance.txt 

#Update the datablock contents file 
_write_datablock nzcov "nz_covariance.txt"
