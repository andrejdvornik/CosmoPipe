#=========================================
#
# File Name : prepare_covariance.sh
# Created By : awright
# Creation Date : 05-04-2023
# Last Modified : Fri 05 May 2023 10:46:52 AM CEST
#
#=========================================

#If needed, create the output directory 
if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosebis_cov ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosebis_cov/
fi 

_write_datablock "cosebis_cov" "Covariance_blind@BV:BLIND@_nMaximum_@BV:NMAXCOSEBIS@_@BV:THETAMINXI@_@BV:THETAMAXXI@_nBins@BV:NTOMO@.ascii"

