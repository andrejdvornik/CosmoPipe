#=========================================
#
# File Name : add_nz.sh
# Created By : awright
# Creation Date : 22-03-2023
# Last Modified : Tue 02 May 2023 11:51:39 AM CEST
#
#=========================================

#Construct the nz folder, if needed 
if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/nz ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/nz
fi 

#Check that the Nz file(s) exists
if [ -d "@NZPATH@" ]
then 
  #we have a directory {{{
  inputlist=`ls @NZPATH@`
  filelist=""
  #This just makes sure that the files are added correctly
  for file in ${inputlist} 
  do 
    #Construct the output name {{{
    outname=${file##*/}
    #}}}
    #Save the output file to the list {{{
    filelist="$filelist @NZPATH@/$outname"
    #}}}
  done 
  #}}}
elif [ -f "@NZPATH@" ]
then 
  #we have a single file {{{
  filelist=@NZPATH@
  #}}}
else 
  #we have a file list {{{
  filelist=""
  for inp in @NZPATH@
  do 
    if [ ! -f ${inp} ]
    then 
     _message "${RED} - ERROR: Nz file ${inp} does not exist!"
      exit -1 
    fi 
    filelist="${filelist} ${inp}"
  done 
  #}}}
fi 

#Add the Nz file(s) to the datablock 
_add_datablock nz "${filelist}"

