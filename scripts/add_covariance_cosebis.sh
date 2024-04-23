#=========================================
#
# File Name : add_covariance_cosebis.sh
# Created By : awright
# Creation Date : 30-03-2023
# Last Modified : Tue 07 Nov 2023 08:08:34 PM CET
#
#=========================================


if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_cosebis ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_cosebis
fi 

file="@COSEBICOVFILE@"
file=${file##*/}

#Create the uncertainty file 
cp @COSEBICOVFILE@ @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_cosebis/${file}

#Update the datablock contents file 
_write_datablock "covariance_cosebis" "${file}"


