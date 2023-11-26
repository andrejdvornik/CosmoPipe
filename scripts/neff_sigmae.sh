#=========================================
#
# File Name : neff_sigmae.sh
# Created By : awright
# Creation Date : 28-03-2023
# Last Modified : Mon 20 Nov 2023 04:42:35 PM CET
#
#=========================================

catname=@DB:DATAHEAD@
catname=${catname##*/}
catbase=${catname%.*}

#Define the patch for this file {{{
found="FALSE"
for patch in @PATCHLIST@ @ALLPATCH@ @ALLPATCH@comb
do 
  #Find files with matching patch strings
  if [[ "${catname}" =~ .*"_${patch}_".* ]]
  then
    found='TRUE'
    break 
  fi
done 
#If the file doesn't match any patch, error {{{
if [ "${found}" == "FALSE" ] 
then 
  _message "@RED@ - ERROR! DATAHEAD file ${catname} doesn't match any patch?!@DEF@\n"
  exit 1 
fi 
#}}}

_message " ->@BLU@ Patch @RED@${patch}@DEF@"

#If doesn't exist, make the output folder
if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cov_input ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cov_input
fi 
#If doesn't exist, make the neff folder
if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/neff_${patch} ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/neff_${patch}
fi 
#If doesn't exist, make the output folder
if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/sigmae_${patch} ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/sigmae_${patch}
fi 

#Get the survey area 
SurveyArea=@SURVEYAREA@
_message "> @BLU@Use effective area for survey: @RED@${SurveyArea} square arcmin@DEF@\n"

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
  | head -n ${NTOMO} | awk '{ printf $2" " }' >  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/neff_${patch}/${catbase}_neff.txt 
tail -n +2 @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cov_input/${catbase}_neff_sigmae.txt \
  | head -n ${NTOMO} | awk '{ printf $7" " }' > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/sigmae_${patch}/${catbase}_sigmae.txt 

#Add the new file to the datablock 
neffblock=`_read_datablock neff_${patch}`
_write_datablock neff_${patch} "`_blockentry_to_filelist ${neffblock}` ${catbase}_neff.txt"
sigeblock=`_read_datablock sigmae_${patch}`
_write_datablock sigmae_${patch} "`_blockentry_to_filelist ${sigeblock}` ${catbase}_sigmae.txt"

