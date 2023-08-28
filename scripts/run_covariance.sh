#=========================================
#
# File Name : run_chain.sh
# Created By : awright
# Creation Date : 14-04-2023
# Last Modified : Sat 08 Jul 2023 01:36:57 PM CEST
#
#=========================================

#Create the covariance output directory
if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_@BV:STATISTIC@ ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_@BV:STATISTIC@/
fi 

#Run cosmosis for a constructed ini file 
_message " >@BLU@ Running covariance!\n   Start time:@DEF@ `date +'%a %H:%M'`@BLU@)\n@DEF@"
MKL_NUM_THREADS=1 NUMEXPR_NUM_THREADS=1 OMP_NUM_THREADS=32 @PYTHON3BIN@ @RUNROOT@/INSTALL/OneCovariance/onecov/covariance.py @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs/@BV:STATISTIC@_@SURVEY@_CosmoPipe_constructed.ini 2>&1 
_message " >@RED@ Done! (`date +'%a %H:%M'`)@DEF@\n"

_write_datablock "covariance_@BV:STATISTIC@" "covariance_matrix.mat"
