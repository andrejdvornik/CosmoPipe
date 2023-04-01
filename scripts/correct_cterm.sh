#
# Correct the constant shear bias term for all files in DATAHEAD 
#

#Get the input filename 
current=@DB:DATAHEAD@

#Correct the constant shear term {{{
appendstr="_ccorr"
#Define the output file name 
outputname=${current//.cat/${appendstr}.cat}
#Construct the output catalogue filename 
catname=${outputname//.cat/.txt}
catname=${catname##*/}
#Check if the outputname file exists 
if [ -f ${outputname} ] 
then 
  #If it exists, remove it 
  _message " > @BLU@Removing previous catalogue c-corrected catalogue for @RED@${current##*/}@DEF@"
  rm -f ${outputname}
  _message " - @RED@Done!@DEF@\n"
fi 
#Construct the catalogue directory 
if [ ! -d  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cterm ] 
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cterm
fi 
#Construct the output tomographic bin 
_message " > @BLU@Constructing c-corrected catalogue for @RED@${current##*/}@DEF@"
@PYTHON3BIN@/python3 @RUNROOT@/@SCRIPTPATH@/correct_cterm.py \
  -i ${current} \
  -o ${outputname} > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cterm/${catname}
_message " - @RED@Done!@DEF@\n"
#}}}

#Update the datahead {{{
_replace_datahead ${current##*/} ${outputname##*/}
#}}}

#Add the cterm catalogue to the datablock {{{
cterm=`_read_datablock cterm`
cterm=`_blockentry_to_filelist ${cterm}`
_write_datablock cterm "${cterm} ${catname}"
#}}}
