#=========================================
#
# File Name : neff_sigmae.sh
# Created By : awright
# Creation Date : 28-03-2023
# Last Modified : Fri 07 Jul 2023 08:07:49 PM CEST
#
#=========================================

#If doesn't exist, make the output folder
if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cov_input ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cov_input
fi 
#If doesn't exist, make the neff folder
if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/neff ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/neff
fi 
#If doesn't exist, make the output folder
if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/sigmae ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/sigmae
fi 

#Get the survey area 
SurveyArea=@SURVEYAREA@
_message "> @BLU@Use effective area for survey: @RED@${SurveyArea} square arcmin@DEF@\n"

catname=@DB:DATAHEAD@
catname=${catname##*/}
catbase=${catname%.*}

_message "> @BLU@Computing sigma_e and n_effective for catalogue:@DEF@ ${catname}" 
#Prepare the neff & ellipticity dispersion file
@PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/neff_sigmae.py \
  -i @DB:DATAHEAD@ \
  --e1name @BV:E1NAME@ \
  --e2name @BV:E2NAME@ \
  --wname @BV:WEIGHTNAME@ \
  --area ${SurveyArea} > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cov_input/${catbase}_neff_sigmae.txt 
_message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"

NTOMO=`echo @BV:TOMOLIMS@ | awk '{print NF-1}'`

tail -n +2 @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cov_input/${catbase}_neff_sigmae.txt \
  | head -n ${NTOMO} | awk '{ printf $2" " }' >  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/neff/${catbase}_neff.txt 
tail -n +2 @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cov_input/${catbase}_neff_sigmae.txt \
  | head -n ${NTOMO} | awk '{ printf $7" " }' > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/sigmae/${catbase}_sigmae.txt 

#Add the new file to the datablock 
neffblock=`_read_datablock neff`
_write_datablock neff "`_blockentry_to_filelist ${neffblock}` ${catbase}_neff.txt"
sigeblock=`_read_datablock sigmae`
_write_datablock sigmae "`_blockentry_to_filelist ${sigeblock}` ${catbase}_sigmae.txt"

