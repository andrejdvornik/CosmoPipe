#=========================================
#
# File Name : inherit.sh
# Created By : awright
# Creation Date : 20-08-2023
# Last Modified : Tue 27 Feb 2024 04:57:02 PM CET
#
#=========================================

#Get the inheritance pipeline name 
pipename="@BV:INHERIT_PIPE@"

#Get the inheritance pipeline block element 
blocklist="@BV:INHERIT_BLOCK@"

#Construct the inheritance path 
pipepath="@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/"
pipepath=${pipepath/@PIPELINE@/${pipename}}

#For each block requested 
for block in ${blocklist}
do 
  echo ${block} 
  #Test that the item exists 
  if [ ! -d ${pipepath}/${block} ] 
  then 
    _message "@RED@ - ERROR! Inheritance pipeline block element does not exist!"
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
  _message " > @BLU@Inheriting block item @DEF@${block}@BLU@ from pipeline @DEF@${pipename}"
  
  #Make the new block element 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${block}
  
  #Loop through the new files 
  #filelist=''
  filelist=`_read_external_datablock ${pipepath}/block.txt ${block}`
  filelist=`_blockentry_to_filelist ${filelist}`
  for file in ${filelist}
  do 
    #Add the new file to the filelist 
    #filelist="${filelist} ${file##*/}"
    #echo ${file##*/}
    #Inherit! 
    rsync -atqL ${pipepath}/${block}/${file##*/} @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${block}/${file##*/}
  done 
  
  #Update the datablock 
  _write_datablock "${block}" "${filelist}"

  #Notify 
  _message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"
done 

