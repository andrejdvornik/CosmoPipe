#=========================================
#
# File Name : inherit.sh
# Created By : awright
# Creation Date : 20-08-2023
# Last Modified : Wed 06 Dec 2023 03:40:49 PM CET
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

  #Read the external datablock {{{
  function _read_externalblock { 
    #Read the data block entries 
    head=1
    _req=${1}
    _outblock=''
    while read item
    do 
      #Check if we have reached the BLOCK yet
      if [ "$item" == "BLOCK:" ] 
      then 
        head=0
        continue
      fi 
      if [ "${_req}" == "" ] 
      then 
        #Add the contents to the output block 
        _outblock="${_outblock} ${item}"
      elif [ "${item%%=*}" == "${_req}" ]
      then 
        #Add the contents to the output block 
        _outblock="${_outblock} ${item}"
      fi 
    done < ${pipepath}/block.txt
    _outblock=`echo ${_outblock} | sed 's/ /\n/g' | xargs echo`
    echo ${_outblock}
  }
  #}}}
  
  #Loop through the new files 
  filelist=''
    #_message "#${_outblock}#"
  inputlist=`_read_externalblock ${block}`
  inputlist=`_blockentry_to_filelist ${inputlist}`
  for file in ${inputlist}
  do 
    #Add the new file to the filelist 
    filelist="${filelist} ${file##*/}"
    echo ${file##*/}
    #Inherit! 
    rsync -atqL ${pipepath}/${block}/${file##*/} @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${block}/${file##*/}
  done 
  
  #Update the datablock 
  _write_datablock "${block}" "${filelist}"

  #Notify 
  _message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"
done 

