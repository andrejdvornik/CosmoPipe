#=========================================
#
# File Name : inherit.sh
# Created By : awright
# Creation Date : 20-08-2023
# Last Modified : Tue 29 Aug 2023 03:44:05 PM CEST
#
#=========================================

#Get the inheritence pipeline name 
pipename="@BV:INHERIT_PIPE@"

#Get the inheritence pipeline block element 
blocklist="@BV:INHERIT_BLOCK@"

#Construct the inheritence path 
pipepath="@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/"
pipepath=${pipepath/@PIPELINE@/${pipename}}

#For each block requested 
for block in ${blocklist}
do 
  #Test that the item exists 
  if [ ! -d ${pipepath}/${block} ] 
  then 
    _message "@RED@ - ERROR! Inheritence pipeline block element does not exist!"
    exit 1 
  fi 

  #Test that the target item does not exist
  if [  -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${block} ] 
  then 
    _message "@RED@ - ERROR! Inheritence would overwrite existing block element!" 
    exit 1 
  fi 

  #Notify
  _message " > @BLU@Inheriting block item @DEF@${block}@BLU@ from pipeline @DEF@${pipename}"
  
  #Make the new block element 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${block}
  
  #Loop through the new files 
  filelist=''
  for file in `ls ${pipepath}/${block}` 
  do 
    #Add the new file to the filelist 
    filelist="${filelist} ${file##*/}"
    #Inherit! 
    rsync -atvL ${pipepath}/${block}/${file##*/} @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${block}/${file##*/}
  done 
  
  #Update the datablock 
  _write_datablock "${block}" "${filelist}"

  #Notify 
  _message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"
done 

