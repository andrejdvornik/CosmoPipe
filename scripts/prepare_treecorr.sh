#=========================================
#
# File Name : prepare_treecorr.sh
# Created By : awright
# Creation Date : 28-03-2023
# Last Modified : Tue 28 Mar 2023 07:44:02 PM CEST
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
@PYTHON3BIN@/python3 @RUNROOT@/@SCRIPTPATH@/prepare_treecorr.py \
  -i ${current} \
  -o ${outputname} > @RUNROOT@/@LOGPATH@/${logfile} 2>&1
_message " - @RED@Done!@DEF@\n"
#}}}

#Update the datahead {{{
_replace_datahead "${current##*/}" "${outputname##*/}"
#}}}

##Add the catalogue to the datablock {{{
#tcorr=`_read_datablock tc`
#tcorr=`_blockentry_to_filelist ${tcorr}`
#_write_datablock tc "${tcorr} ${catname}"
##}}}

