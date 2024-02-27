#=========================================
#
# File Name : inherit_external.sh
# Created By : awright
# Creation Date : 20-08-2023
# Last Modified : Tue 27 Feb 2024 04:49:24 PM CET
#
#=========================================

#Get the inheritence pipeline name 
pipepath="@BV:INHERIT_EXTPATH@"

#Check that the external path exists
if [ ! -d ${pipepath} ] 
then 
  _message "@RED@ - ERROR! External inheritence path does not exist!"
  exit 1 
fi 

#Get the inheritence pipeline block element 
blocklist="@BV:INHERIT_BLOCK@"

#For each block requested 
for block in ${blocklist}
do 
  #Test that the item exists 
  if [ ! -d ${pipepath}/${block} ] 
  then 
    _message "@RED@ - ERROR! Inheritence pipeline block element ${block} does not exist!"
    exit 1 
  fi 

  #Test that the target item does not exist
  if [  -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${block} ] && [ "@BV:INHERIT_OVERWRITE@" != "TRUE" ]
  then 
    _message "@RED@ - ERROR! Inheritance would overwrite existing block element!" 
    exit 1 
  elif [ -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${block} ] 
  then 
    _message " > @BLU@Erasing existing block item @DEF@${block}@BLU@ "
    rm -fr @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${block}
    #Notify 
    _message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"
  fi 

  #Notify
  _message " > @BLU@Inheriting block item @DEF@${block}@BLU@ from @RED@external@BLU@ pipeline @DEF@${pipename}"
  
  #Make the new block element 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${block}
  
  #Loop through the new files 
  filelist=''
  #Get the files from the block.txt 
  filelist=`_read_external_datablock ${pipepath}/block.txt ${block}`
  filelist=`_blockentry_to_filelist ${filelist}`
  for file in ${filelist}  
  do 
    #Add the new file to the filelist 
    #filelist="${filelist} ${file##*/}"
    #Inherit! 
    rsync -atvL ${pipepath}/${block}/${file##*/} @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${block}/${file##*/}
  done 
  
  #Update the datablock 
  _write_datablock "${block}" "${filelist}"

  #Notify 
  _message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"
done 

