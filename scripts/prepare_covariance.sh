#=========================================
#
# File Name : prepare_covariance.sh
# Created By : awright
# Creation Date : 05-04-2023
# Last Modified : Wed Apr  5 11:27:44 2023
#
#=========================================

#If needed, create the output directory 
if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosebis_cov ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosebis_cov/
fi 

_write_datablock "cosebis_cov" "Covariance_blind@BLIND@_nMaximum_@NMAXCOSEBIS@_@THETAMINXI@_@THETAMAXXI@_nBins@DB:NTOMO@.ascii"

