#=========================================
#
# File Name : add_nzbias.sh
# Created By : awright
# Creation Date : 30-03-2023
# Last Modified : Fri 03 Nov 2023 12:01:35 PM CET
#
#=========================================


if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/nzbias ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/nzbias
fi 

#Create the bias file 
echo @BV:NZBIAS@ > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/nzbias/nz_bias.txt 

#Update the datablock contents file 
_write_datablock nzbias "nz_bias.txt"
