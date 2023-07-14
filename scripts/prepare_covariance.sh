#=========================================
#
# File Name : prepare_covariance.sh
# Created By : awright
# Creation Date : 05-04-2023
# Last Modified : Sat 08 Jul 2023 11:29:01 AM CEST
#
#=========================================

#If needed, create the output directory 
if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosebis_cov ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosebis_cov/
fi 

NTOMO=`echo @BV:TOMOLIMS@ | awk '{print NF-1}'`
_write_blockvars "NTOMO" "${NTOMO}"

_write_datablock "cosebis_cov" "Covariance_blind@BV:BLIND@_nMaximum_@BV:NMAXCOSEBIS@_@BV:THETAMINXI@_@BV:THETAMAXXI@_nBins${NTOMO}.ascii"

