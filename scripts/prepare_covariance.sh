#=========================================
#
# File Name : prepare_covariance.sh
# Created By : awright
# Creation Date : 05-04-2023
# Last Modified : Tue 07 Nov 2023 08:11:46 PM CET
#
#=========================================

#If needed, create the output directory 
if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_cosebis ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_cosebis/
fi 

NTOMO=`echo @BV:TOMOLIMS@ | awk '{print NF-1}'`

_write_datablock "covariance_cosebis" "Covariance_blind@BV:BLIND@_nMaximum_@BV:NMAXCOSEBIS@_@BV:THETAMINXI@_@BV:THETAMAXXI@_nBins${NTOMO}.ascii"

