#=========================================
#
# File Name : inherit.sh
# Created By : awright
# Creation Date : 20-08-2023
# Last Modified : Thu Sep 21 19:56:18 2023
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
      if [ "$item" == "VARS:" ] 
      then 
        head=1
        continue
      fi 
      #If we're still in the HEAD, go to the next line 
      if [ "${head}" == 1 ]
      then 
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
    #Inherit! 
    rsync -atvL ${pipepath}/${block}/${file##*/} @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${block}/${file##*/}
  done 
  
  #Update the datablock 
  _write_datablock "${block}" "${filelist}"

  #Notify 
  _message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"
done 

