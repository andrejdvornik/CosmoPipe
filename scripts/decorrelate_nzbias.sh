#=========================================
#
# File Name : decorrelate_nzbias.sh
# Created By : awright
# Creation Date : 31-03-2023
# Last Modified : Fri 31 Mar 2023 04:13:20 PM CEST
#
#=========================================

if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/nzbias_uncorr ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/nzbias_uncorr
fi 
#Decorrelated the Nz bias values 
@PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/decorrelate_nzbias.py \
  --zbias @DB:nzbias@ \
  --zcov @DB:nzcov@ \
  --output '@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/nzbias_uncorr/nz_bias_uncorr.txt' 2>&1

#Update the datablock contents file 
_write_datablock nzbias_uncorr "nz_bias_uncorr.txt"

