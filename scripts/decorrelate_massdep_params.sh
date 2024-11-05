#=========================================
#
# File Name : decorrelate_nzbias.sh
# Created By : awright
# Creation Date : 31-03-2023
# Last Modified : Fri 31 Mar 2023 04:13:20 PM CEST
#
#=========================================

if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/massdep_params_uncorr ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/massdep_params_uncorr
fi 
#Decorrelated the Nz bias values 
@PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/decorrelate_params.py \
  --means @BV:MASSDEP_MEANS@ \
  --cov @BV:MASSDEP_COVARIANCE@ \
  --output '@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/massdep_params_uncorr/massdep_params_uncorr.txt' 2>&1

#Update the datablock contents file 
_write_datablock massdep_params_uncorr "massdep_params_uncorr.txt"

