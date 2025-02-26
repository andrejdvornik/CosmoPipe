#=========================================
#
# File Name : add_nzbias.sh
# Created By : awright
# Creation Date : 30-03-2023
# Last Modified : Wed Feb 26 10:09:54 2025
#
#=========================================


if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/nzbias_uncorr ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/nzbias_uncorr
fi 

#Create the bias file 
echo @BV:NZBIAS_UNCORR@ > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/nzbias_uncorr/nz_bias_uncorr.txt 

#Update the datablock contents file 
_write_datablock nzbias_uncorr "nz_bias_uncorr.txt"
