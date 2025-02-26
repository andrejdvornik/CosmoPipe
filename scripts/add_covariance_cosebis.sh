#=========================================
#
# File Name : add_covariance_cosebis.sh
# Created By : awright
# Creation Date : 30-03-2023
# Last Modified : Thu 30 Jan 2025 09:29:07 PM CET
#
#=========================================


if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_cosebis ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_cosebis
fi 

file="@BV:COSEBICOVFILE@"
file=${file##*/}

#Create the uncertainty file 
cp @BV:COSEBICOVFILE@ @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_cosebis/${file}

#Update the datablock contents file 
_write_datablock "covariance_cosebis" "${file}"


