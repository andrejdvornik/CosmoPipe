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
  count=0
  while [ ! -d ${pipepath}/${block} ] 
  do 
    count=$((count+1))
    if [ $count -ge 24 ] 
    then
      _message "@RED@ - ERROR! Inheritence pipeline block element ${block} does not exist! I waited for 12 hours and I have had enough!"
      exit 1
    fi
    _message "@RED@ - ERROR! Inheritence pipeline block element ${block} does not exist! Trying again in 30 minutes!@DEF@\n"
    sleep 1800
  done 

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
  filelist=`_read_external_datablock ${pipepath}/block.txt ${block}`
  #Get the files from the block.txt 
  # count=0
  # while [ $filelist=='' ] 
  # do
  #   filelist=`_read_external_datablock ${pipepath}/block.txt ${block}` 
  #   count=$((count+1))
  #   if [ $count -ge 60 ] 
  #   then
  #     _message "@RED@ - ERROR! Filelist in inheritence pipeline block element ${block} does not exist! I waited for two hours and I have had enough!"
  #     exit 1
  #   fi
  #   _message "@RED@ - ERROR! Filelist in inheritence pipeline block element ${block} does not exist! Trying again in 2 minutes!@DEF@\n"
  #   sleep 120
  # done 
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

