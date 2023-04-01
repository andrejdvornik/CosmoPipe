#=========================================
#
# File Name : add_nzbias.sh
# Created By : awright
# Creation Date : 30-03-2023
# Last Modified : Fri 31 Mar 2023 03:27:22 PM CEST
#
#=========================================


if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/nzbias ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/nzbias
fi 

#Create the bias file 
echo @NZBIAS@ > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/nzbias/nz_bias.txt 

#Update the datablock contents file 
_write_datablock nzbias "nz_bias.txt"
