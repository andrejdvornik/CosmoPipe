#=========================================
#
# File Name : add_nzcov.sh
# Created By : awright
# Creation Date : 30-03-2023
# Last Modified : Thu 30 Mar 2023 07:36:27 PM CEST
#
#=========================================


if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/nzcov ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/nzcov
fi 

#Create the uncertainty file 
cp @NZCOVFILE@ @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/nzcov/nz_covariance.txt 

#Update the datablock contents file 
_write_datablock nzcov "nz_covariance.txt"
