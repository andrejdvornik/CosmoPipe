#=========================================
#
# File Name : prepare_treecorr.sh
# Created By : awright
# Creation Date : 28-03-2023
# Last Modified : Wed Jan 10 05:13:23 2024
#
#=========================================


#Get the input filename 
current=@DB:DATAHEAD@

#Prepare the filenames {{{
appendstr="_tc"
#Define the output file name 
ext=${current##*.}
outputname=${current//.${ext}/${appendstr}.fits}
#Check if the outputname file exists 
if [ -f ${outputname} ] 
then 
  #If it exists, remove it 
  _message " > @BLU@Removing previous catalogue treecorr input catalogue for @RED@${current##*/}@DEF@"
  rm -f ${outputname}
  _message " - @RED@Done!@DEF@\n"
fi 
##Construct the catalogue directory 
#if [ ! -d  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/tc ] 
#then 
#  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/tc
#fi 
#Construct the output tomographic bin 
#}}}

#Construct the treecorr input catalogues {{{
_message " > @BLU@Constructing treecorr input catalogue for @RED@${current##*/}@DEF@"
logfile=${outputname##*/}
logfile=${logfile//.fits/.log}
@PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/prepare_treecorr.py \
  -i ${current} \
  -o ${outputname} \
  --e1name @BV:E1NAME@ \
  --e2name @BV:E2NAME@ \
  --psfe1name @BV:PSFE1NAME@ \
  --psfe2name @BV:PSFE2NAME@ \
  --wname @BV:WEIGHTNAME@ \
  --raname @BV:RANAME@ \
  --decname @BV:DECNAME@ 2>&1 
_message " - @RED@Done!@DEF@\n"
#}}}

#Update the datahead {{{
_replace_datahead "${current}" "${outputname}"
#}}}

##Add the catalogue to the datablock {{{
#tcorr=`_read_datablock tc`
#tcorr=`_blockentry_to_filelist ${tcorr}`
#_write_datablock tc "${tcorr} ${catname}"
##}}}

