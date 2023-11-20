
#Initialisation function {{{ 
function _initialise { 
  _callname=${0##*/} 
  if [ ! -f @RUNROOT@/@MANUALPATH@/${_callname//.sh/.man.sh} ] 
  then 
    _message "${RED} - ERROR! Manual file does not exist!"
    exit 1
  fi 
  #Check that we are in the correct conda environment {{{
  if [ "$CONDA_DEFAULT_ENV" != "cosmopipe" ]
  then 
    echo "ERROR! Configuration and Pipeline must be run from within the 'cosmopipe' conda environment!"
  fi 
  #}}}
  #Documentation file 
  source @RUNROOT@/@MANUALPATH@/${_callname//.sh/.man.sh}
  #Startup prompt 
  _prompt ${VERBOSE}
  #Starting time 
  _message "@BLU@Start time: @DEF@`date +'%a %H:%M'`\n"
}
#}}}

#Finalisation function {{{
function _finalise {
  #Concluding time 
  _message "@BLU@End time: @DEF@`date +'%a %H:%M'`\n"
  #Unset functions
  _unset_functions
  #Mark this step as completed
  echo ${0##*/} >> @PIPELINE@_status.sh
  trap : 0 
}
#}}}

# Unset Function command {{{ 
function _unset_functions { 
  #Remove these functions from the environment
  unset -f _prompt _description _inp_data _inp_var _abort _outputs _runcommand _unset_functions
} 
#}}}

#Message function {{{ 
function _message { 
  if [ "$VERBOSE" != "0" ] 
  then 
    >&2 echo -en "$1"
  fi 
} 
#}}}

# Variable Check {{{ 
function _varcheck { 
  #Loop through the input functions to the script 
  _varlist=`_inp_var`
  _err=0
  _runerr=0
  _missing=''
  _runmissing=''
  _undefined=''
  for var in $_varlist
  do 
    if [ "${var:0:3}" == "BV:" ]
    then 
      #Check that block variables are defined 
      _res=`_check_blockvar ${var:3}`
      if [ "${_res}" == "0" ] 
      then 
        #If not, add to missing
        _runerr=$((_err+1))
        _runmissing="$_runmissing ${var:3}"
      fi 
    elif [ "${!var}" == "" ] 
    then 
      _err=$((_err+1))
      _missing="$_missing $var"
    elif [ "${!var}" == "@${var^^}@" ]
    then 
      _err=$((_err+1))
      _undefined="$_undefined $var"
    fi 
  done  
  if [ "${_err}" == "1" ]
  then 
    if [ "${_undefined}" != "" ]
    then 
      >&2 echo "ERROR: Input variable$_undefined, required by the mode ${1##*/}, is still set to a placeholder value!"
    else
      >&2 echo "ERROR: Input variable$_missing, required by the mode ${1##*/}, is missing entirely (not in the variables file)!"
    fi 
    exit 1 
  elif [ "${_err}" != "0" ]
  then 
    if [ "${_undefined}" != "" ]
    then 
      >&2 echo "ERROR: Input variables$_undefined, required by the mode ${1##*/}, are still set to their placeholder values!"
    fi
    if [ "${_missing}" != "" ]
    then
      >&2 echo "ERROR: Input variables$_missing, required by the mode ${1##*/}, are missing entirely (not in the variables file)!"
    fi
    exit 1 
  fi 
  if [ "${_runerr}" != "0" ]
  then 
    _runmissing=`echo ${_runmissing} | sed 's/ /\n/g' | sort | uniq | sed 's/\n/ /g'` 
    #>&2 echo ${_runmissing}
    echo ${_runmissing}
  fi 
} 
#}}}

#Sanitize variable before vector formatting {{{
function _clean_variable { 
  _VAR=${1}
  _TMP=${_VAR//  / }
  while [ "${_VAR}" != "${_TMP}" ] 
  do
    _VAR=${_TMP} 
    _TMP=${_VAR//  / } 
  done 
  _VAR=${_TMP// /,} 
  echo "${_VAR}"
}
#}}}

#Get option list {{{
function _get_optlist { 
  cat $1 | grep -v "^#" | grep "=" | awk -F= '{print $1}' 
}
#}}}

#Datablock Functions {{{ 

# Add Default Variables {{{ 
function _add_default_vars { 
  #Loop through the input functions to the script 
  _undefined=''
  source @RUNROOT@/@PIPELINE@_defaults.sh
  while read line 
  do 
    if [ "${line}" == "" ] || [ "${line:0:1}" == "#" ]
    then 
      continue
    fi 
    varbase=${line%%=*}
    varval=${line#*=}
    varval=${varval//\"/}
    varval=${varval//\'/}
    if [ "${varval^^}" != "@${varbase^^}@" ]
    then 
      #_write_blockvars ${varbase^^} "${varval}"
      _write_blockvars ${varbase^^} "${!varbase}"
    fi 
  done < @RUNROOT@/@PIPELINE@_defaults.sh
} 
#}}}

#Initialise the datablock {{{
function _initialise_datablock { 
  #Make the datablock directory, if needed
  if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/DATAHEAD ]
  then 
    mkdir -p @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/DATAHEAD
  fi 
  if [ ! -f @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/block.txt ]
  then 
    #Initialise the datablock txt file 
    echo "HEAD: " > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/head.txt
    echo "BLOCK: " > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/block.txt
    echo "VARS: " > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/vars.txt
    if [ -f @PIPELINE@_defaults.sh ]
    then 
      _add_default_vars 
    fi 
  fi 
}
#}}}

#Read the datablock {{{
function _read_datablock { 
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
  done < @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/block.txt
  #_message "#${_outblock}#"
  #_outblock=`echo ${_outblock} | sed 's/ /\n/g' | sort | uniq | xargs echo`
  #_outblock=`echo ${_outblock} | sed 's/ /\n/g' | xargs echo`
  _outblock=`echo ${_outblock} | sed 's/ /\n/g'`
  #_message "#${_outblock}#"
  echo ${_outblock}
}
#}}}

#Write the datablock {{{
function _write_datablock { 
  #Get the files in this data
  _block=`_read_datablock`
  #Update the BLOCK items 
  echo "BLOCK:" > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/block.txt
  #Add what we want to write
  _filelist="{${2// /,}}"
  echo "${1}=${_filelist}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/block.txt
  #For each block row:
  for _file in ${_block} 
  do 
    #If the item isn't what we want to add/write
    if [ "${_file%%=*}" != "${1%%=*}" ]
    then 
      #Write it 
      _file=`echo $_file`
      echo "${_file}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/block.txt
    fi
  done
}
#}}}

#Rename a datablock element {{{
function _rename_blockitem { 
  _head=`_read_datahead`
  #Get the files in this data
  _block=`_read_datablock`
  #Get the variables
  _vars=`_read_blockvars`
  _seen=0
  for _file in ${_block} 
  do 
    #If the item isn't what we want to add/write
    if [ "${_file%%=*}" == "${1%%=*}" ]
    then 
      _seen=1
    fi 
  done 
  if [ "${_seen}" != 1 ]
  then 
    _message "@RED@ - ERROR! The requested data block to rename (${1}) does not exist in the data block!@DEF@\n"
    exit 1 
  fi 
  #Update the BLOCK items 
  echo "BLOCK:" > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/block.txt
  #For each block row:
  for _file in ${_block} 
  do 
    #If the item isn't what we want to add/write
    if [ "${_file%%=*}" == "${1%%=*}" ]
    then 
      #Write it the item with a new name 
      _fileend=${_file##*=}
      echo "${2%%=*}=${_fileend}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/block.txt
    else 
      #Write it 
      _file=`echo $_file`
      echo "${_file}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/block.txt
    fi
  done
  if [ "$3" == "" ]
  then 
    if [ -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${1%%=*} ]
    then 
      if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${2%%=*} ] 
      then 
        mv -f @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${1%%=*} @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${2%%=*}
      else 
        #rm -f  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${2%%=*}/*
        find @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${2%%=*}/ -mindepth 1 -maxdepth 1 -print0 | xargs -0 rm -f 2> /dev/null || echo "Ignoring attempted directory removal"
        mv -f  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${1%%=*}/* @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${2%%=*}/
        rmdir  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${1%%=*}
      fi 
    fi 
  fi 
}
#}}}

#Export a datablock element {{{
function _export_blockitem { 
  _head=`_read_datahead`
  #Get the files in this data
  _block=`_read_datablock`
  #Get the variables
  _vars=`_read_blockvars`
  _seen=0
  for _file in ${_block} 
  do 
    #If the item is what we want to export 
    if [ "${_file%%=*}" == "${1%%=*}" ]
    then 
      _seen=1
    fi 
  done 
  if [ "${_seen}" != 1 ]
  then 
    _message "@RED@ - ERROR! The requested data block to export (${1}) does not exist in the data block?!@DEF@\n"
    exit 1 
  fi 
  #If this is not a test 
  if [ "$3" == "" ]
  then 
    if [ -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${1%%=*} ]
    then 
      if [ ! -d @RUNROOT@/@STORAGEPATH@/${2%%=*} ] 
      then 
        rsync -atvL @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${1%%=*} @RUNROOT@/@STORAGEPATH@/${2%%=*} 2>&1 
      else 
        #Try to add a number to the end of the folder name... 
        copied=FALSE
        for i in `seq 100`
        do 
          if [ ! -d @RUNROOT@/@STORAGEPATH@/${2%%=*}_${i} ] 
          then 
            rsync -atvL @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${1%%=*} @RUNROOT@/@STORAGEPATH@/${2%%=*}_${i} 2>&1 
            copied=TRUE
            break
          fi 
        done 
        if [ "${copied}" == "FALSE" ]
        then 
          _message "@RED@ - ERROR! The requested data block to export (@DEF@${1%%=*}@RED@) could not be exported because the requested folder (@DEF@${2%%=*}@RED@) could not be created (even with 100 attempts at unique endings)?!@DEF@\n"
           exit 1 
        fi 
      fi 
    fi 
  fi 
}
#}}}

#Delete a datablock element {{{
function _delete_blockitem { 
  _head=`_read_datahead`
  #Get the files in this data
  _block=`_read_datablock`
  #Get the variables
  _vars=`_read_blockvars`
  _seen=0
  for _file in ${_block} 
  do 
    #If the item isn't what we want to add/write
    if [ "${_file%%=*}" == "${1%%=*}" ]
    then 
      _seen=1
    fi 
  done 
  if [ "${_seen}" != 1 ]
  then 
    _message "@RED@ - ERROR! The requested data block to delete (${1}) does not exist in the data block!@DEF@\n"
    exit 1 
  fi 
  #Update the BLOCK items 
  echo "BLOCK:" > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/block.txt
  #For each block row:
  for _file in ${_block} 
  do 
    #If the item is't what we want to delete
    if [ "${_file%%=*}" != "${1%%=*}" ]
    then 
      #Write it 
      _file=`echo $_file`
      echo "${_file}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/block.txt
    fi
  done
  #If this isn't a test, delete the folder 
  if [ "$2" == "" ]
  then 
    if [ -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${1%%=*} ]
    then 
      find @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${1%%=*}/ -mindepth 1 -maxdepth 1 -print0 | xargs -0 rm -f 2> /dev/null || echo "Ignoring attempted directory removal"
      rmdir  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${1%%=*}
    fi 
  fi 
}
#}}}

#Read the datahead {{{
function _read_datahead { 
  #Read the data head entries 
  _outhead=''
  while read item contents 
  do 
    #Check if we have reached the BLOCK yet
    if [ "$item" == "BLOCK:" ] 
    then 
      break
    fi 
    #If we're still in the HEAD, go to the next line 
    if [ "${item}" == "HEAD:" ]
    then 
      continue 
    fi 
    #Add the contents to the output block 
    _outhead="${_outhead} ${item} ${contents}"
  done < @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/head.txt
  #_message "#${_outhead}#"
  #_outhead=`echo ${_outhead} | sed 's/ /\n/g' | sort | uniq | xargs echo`
  #_outhead=`echo ${_outhead} | sed 's/ /\n/g' | xargs echo`
  _outhead=`echo ${_outhead} | sed 's/ /\n/g' `
  #_message "#${_outhead}#"
  echo ${_outhead}
}
#}}}

#Write the datahead {{{
#function _add_datahead { 
function _add_datahead { 
  _block=`_read_datablock`
  _vars=`_read_blockvars`
  #If the request is for nothing
  if [ "${1}" == "" ] 
  then 
    #Clear the datahead {{{
    echo "HEAD:" > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/head.txt
    #Remove any datahead files 
    #rm -f @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/DATAHEAD/*
    find @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/DATAHEAD/ -mindepth 1 -maxdepth 1 -print0 | xargs -0 rm -f 2> /dev/null || echo "Ignoring attempted directory removal"
    #}}}
  else 
    #Copy the requested data to the datahead {{{
    if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${1}/ ] 
    then 
      _message "@RED@ - ERROR! The requested data block component ${1} does not have a folder in the data block?!"
      exit 1 
    fi 
    #If the directory is empty {{{
    if [ ! "$(ls -A @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${1})" ]
    then 
      _message "@RED@ - ERROR! The requested data block component ${1} is empty?!"
      exit 1 
    fi 
    #}}}
    #Get the files in this data{{{
    _files=`_read_datablock ${1}`
    _files=`_blockentry_to_filelist ${_files}`
    #}}}
    #remove the data in the datahead that we aren't going to use {{{
    if [ -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/DATAHEAD ]
    then 
      _headfiles=`_read_datahead`
      #For each file in the DATAHEAD {{{
      for hfile in ${_headfiles}
      do 
        #Check for a matching file in the block object 
        found="FALSE"
        for file in ${_files}
        do 
          #If there is a matching file 
          if [ "${hfile}" == "${file}" ]
          then 
            #If there is a matching file, log and break 
            found="TRUE"
            break 
          fi 
        done 
        #If not found, delete
        if [ "${found}" == "FALSE" ] 
        then 
          #Delete the file 
          rm -f @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/DATAHEAD/${hfile}
        fi 
      done 
      #}}}
      ## Old method: delete everything! {{{
      #dir=`pwd`
      #cd @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/DATAHEAD
      #rm -fr ./*.*
      #cd $dir
      #}}}
    fi 
    #}}}
    #Copy the requested data to the datahead, if the directory contains anything {{{
    if [ "$(ls -A @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${1})" ] 
    then 
      _message " @BLU@>@DEF@ ${1} @BLU@-->@DEF@ DATAHEAD:\n"
      #Copy the files one-by-one (to ensure that there isn't accidental use of datablock waste...)
      #For each file in the block element {{{
      count=0
      nfiles=`echo ${_files} | awk '{print NF}'`
      _printstr=''
      for file in ${_files}
      do 
        count=$((count+1))
        #Notify 
        _message "\r${_printstr//?/ }\r"
        _printstr=" @RED@  (`date +'%a %H:%M'`)@BLU@ -->@DEF@ ${file##*/}@BLU@ (${count}/${nfiles})"
        _message "${_printstr}"
        #Copy the file (will skip if file exists and is unchanged)
        rsync -atv @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${1}/${file} @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/DATAHEAD/ 2>&1 
      done 
      #}}}
      _message "\n @BLU@>@DEF@ ${1} @BLU@-->@DEF@ DATAHEAD@BLU@ Done!@DEF@\n"
    fi 
    #Update the datablock txt file 
    echo "HEAD:" > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/head.txt
    for _file in ${_files} 
    do 
      echo "${_file}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/head.txt
    done 
    #}}}
    #}}}
  fi 
}
#}}}

#Replace an item in the datahead {{{
function _replace_datahead { 
  #Current block
  _block=`_read_datablock`
  #Current vars
  _vars=`_read_blockvars`
  #Current head 
  _head=`_read_datahead`
  #Update the datablock txt file 
  echo "HEAD:" > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/head.txt
  for _file in ${_head} 
  do 
    #If this is the file we want to update 
    if [ "${_file}" == "${1##*/}" ] 
    then 
      #Make sure we don't delete what we want to keep 
      _delete=TRUE
      #Loop over new files 
      for _newfile in ${2} 
      do 
        #Is the old file in the new file list?
        if [ "${_file}" == "${_newfile##*/}" ]
        then 
          #Don't delete the new file!
          _delete=FALSE
        fi 
      done 
      if [ "${_delete}" == "FALSE" ]
      then 
        #Don't delete the new file!
        >&2 echo "name unchanged ${1##*/} -> ${_newfile##*/}"
      elif [ "${_delete}" == "TRUE" ] 
      then 
        #Replace this file in the datahead
        >&2 echo "replace ${1##*/} -> ${_newfile##*/}"
        #Remove the old file(s)
        rm -f ${1} 
      else 
        >&2 echo "_delete variable in _replace_datahead has invalid value: ${_delete}?!"
        exit 1
      fi 
      #Loop over new files 
      for _newfile in ${2} 
      do 
        #Add new file to the data block 
        echo "${_newfile##*/}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/head.txt
      done 
    else 
      #Otherwise keep going
      echo "${_file}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/head.txt
    fi
  done 
}
#}}}
#
##Write item to the datahead {{{
#function _write_datahead { 
#  #Current block
#  _block=`_read_datablock`
#  #Current vars
#  _vars=`_read_blockvars`
#  #Current head 
#  _head=`_read_datahead`
#  #Check if the requested item exists in the datablock
#  _found=0
#  for _file in ${_block} 
#  do 
#    if [ "${_file%%=*}" == "${1}" ]
#    then 
#      _found=1
#    fi 
#  done
#  if [ "${_found}" != "1" ]
#  then 
#    _message "@RED@ - ERROR! The requested data block component ${1} does not have a folder in the data block?!"
#    exit 1 
#  fi 
#  #Update the datablock txt file 
#  echo "HEAD:" > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/block.txt
#  for _file in ${_head} 
#  do 
#    #Print the existing datahead items 
#    echo "${_file}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/block.txt
#  done 
#  #Add the new item 
#  echo "${2}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/block.txt
#  #Write out the block 
#  echo "BLOCK:" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/block.txt
#  for _file in ${_block} 
#  do 
#    echo "${_file}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/block.txt
#  done
#  #Write out the vars 
#  echo "VARS:" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/block.txt
#  for _file in ${_vars} 
#  do 
#    echo "${_file}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/block.txt
#  done
#}
##}}}
#
#Write an item (including NULL/clear) to the datahead {{{
function _write_datahead { 
  #Current block
  _block=`_read_datablock`
  #Current vars
  _vars=`_read_blockvars`
  #Current head 
  _head=`_read_datahead`
  if [ "${1}" == "" ] 
  then 
    #Clear the datahead 
    echo "HEAD:" > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/head.txt
    #Remove any datahead files 
    find @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/DATAHEAD -maxdepth 1 -print0 | xargs -0 rm -f 2> /dev/null || echo "Ignoring attempted directory removal"
  else 
    #Check if the requested item exists in the datablock
    _found=0
    for _file in ${_block} 
    do 
      if [ "${_file%%=*}" == "${1}" ]
      then 
        _found=1
      fi 
    done
    if [ "${_found}" != "1" ]
    then 
      _message "@RED@ - ERROR! The requested data block component ${1} does not have a folder in the data block?!"
      exit 1 
    fi 
    #Update the datablock txt file 
    echo "HEAD:" > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/head.txt
    for _file in ${_head} 
    do 
      #Print the existing datahead items 
      echo "${_file}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/head.txt
    done 
    #Add the new item 
    echo "${2}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/head.txt
  fi 
}
#}}}

#Write a list of items to the datahead {{{
function _writelist_datahead { 
  _head="${1}"
  _block=`_read_datablock`
  _vars=`_read_blockvars`
  #Update the datablock txt file 
  echo "HEAD:" > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/head.txt
  for _file in ${_head} 
  do 
    #Print the existing datahead items 
    echo "${_file}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/head.txt
  done 
}
#}}}

#Add item to datablock {{{
function _add_datablock { 
  #Read the current datablock 
  _datablock=`_read_datablock`
  #Add the folder to the datablock 
  if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${1}/ ] 
  then 
    mkdir -p @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${1}/
  fi 
  #Get the file designation 
  _filelist=""
  for _file in $2
  do 
    _file=${_file##*/}
    _filelist="$_filelist $_file"
  done 
  #Copy the data to the block 
  if [ "$_filelist" != "" ] 
  then 
    count=0
    nfiles=`echo $2 | awk '{print NF}'`
    _printstr=''
    for _file in $2
    do 
      count=$((count+1))
      if [ -e "$_file" ]
      then 
        #_message " @BLU@>@DEF@ ${_file##*/} @BLU@-->@DEF@ ${1}"
        _message "\r${_printstr//?/ }\r"
        _printstr=" @RED@  (`date +'%a %H:%M'`)@BLU@ -->@DEF@ ${_file##*/}@BLU@ (${count}/${nfiles})"
        _message "${_printstr}"
        rsync -atv $_file @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${1}/${_file##*/} 2>&1 
        #_message "@BLU@ - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"
      fi 
    done 
    _message "\n @BLU@>@DEF@ DATAHEAD @BLU@-->@DEF@ ${1}@BLU@ Done!@DEF@\n"
  fi 
  #Add item to datablock list 
  #_datablock=`echo "$_datablock $1=${_file}"`
  _write_datablock $1 "`echo ${_filelist}`"
}
#}}}

# Write the datahead to a new block entry {{{ 
function _add_head_to_block {
  #Get the requested block name 
  _name=${1}
  #Get the current datahead 
  _head=`_read_datahead` 
  _itemlist=""
  #Append the full path to head entries 
  for item in ${_head}
  do 
    _itemlist="${_itemlist} @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/DATAHEAD/${item}"
  done 
  #>&2 echo ${_itemlist}
  #Add the datahead entries to the block 
  _add_datablock ${1} "${_itemlist}"
}
#}}}

#Read the blockvars {{{
function _read_blockvars { 
  #Read the data block variables
  vars=0
  _req=${1}
  _outvars=''
  while read item
  do 
    #Check if we have reached the VARS yet
    if [ "$item" == "VARS:" ] 
    then 
      vars=1
      continue
    fi 
    #If we're still in the HEAD or BLOCK, go to the next line 
    if [ "${vars}" == 0 ]
    then 
      continue 
    fi 
    if [ "${_req}" == "" ] 
    then 
      #Add the contents to the output 
      _outvars="${_outvars} ${item}"
    elif [ "${item%%=*}" == "${_req}" ]
    then 
      #Add the contents to the output 
      _outvars="${_outvars} ${item}"
    fi 
  done < @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/vars.txt
  echo ${_outvars}
}
#}}}

#Parse a block variable in a string {{{
function _parse_blockvars {
  _outputlist=''
  while [ $# -ge 1 ]
  do 
    string=$1
    #If this string contains a block variable reference 
    count=0
    while [[ ${string} =~ "@BV:".*."@" ]]
    do 
      #Pull out the block variable
      _var=${string#*@BV:}
      _var=${_var%%@*}
      #The variable assignment is a reference: assign the referred value 
      _filelist=`_read_blockvars ${_var}`
      #Remove variable name and brackets 
      _filelist=${_filelist#*=}
      _prompt=${_filelist#\{}
      _prompt=${_prompt%\}}
      _prompt=${_prompt//,/ }
      if [ "${_prompt}" == "" ] 
      then 
        _filelist="@BV:${_var}@"
      else 
        _filelist=${_prompt}
        ##Prompt about the update
        #>&2 echo "${_var} -> ${_prompt}" 
      fi 
      string=${string/@BV:${_var}@/${_filelist}}
      count=$((count+1))
      if [ ${count} -gt 100 ]
      then 
        >&2 echo "ERROR: SOMETHING WRONG IN VARIABLE PARSE"
        exit 1 
      fi 
    done 
    outlist="${outlist} ${string}"
    shift 
  done 
  echo ${outlist}
}
#}}}

#Write the blockvars {{{
function _write_blockvars { 
  _head=`_read_datahead`
  #Get the files in this data
  _block=`_read_datablock`
  #Get the variables 
  _vars=`_read_blockvars`
  if [ "${2:0:4}" == "@BV:" ] 
  then 
    #The variable assignment is a reference: assign the referred value 
    _target=${2:4}
    _target=${_target%@}
    _filelist=`_read_blockvars ${_target}`
    #Remove variable name and brackets 
    _filelist=${_filelist#*=}
    _prompt=${_filelist#\{}
    _prompt=${_prompt%\}}
    _prompt=${_prompt//,/ }
    if [ "${_prompt}" == "" ] || [ "${_prompt}" == "@BV:${target}@" ]
    then 
      _filelist="{${2// /,}}"
    else 
      #Prompt about the update
      echo -n " -> #${_prompt}#"
    fi 
  else  
    #Add what we want to write
    _filelist="{${2// /,}}"
  fi 
  #Update the VARS items 
  echo "VARS:" > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/vars.txt
  echo "${1}=${_filelist}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/vars.txt
  #For each var row:
  for _file in ${_vars} 
  do 
    #If the item isn't what we want to add/write
    if [ "${_file%%=*}" != "${1%%=*}" ]
    then 
      #Write it 
      _file=`echo $_file`
      echo "${_file}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/vars.txt
    fi
  done
}
#}}}

# Check whether item 1 is in the blockvars {{{
function _check_blockvar { 
  #Item to check 
  _data=$1
  #Blockvars
  _block=`_read_blockvars`
  #Check whether the requested data object is in the datablock 
  #echo " ${_block} " | grep -c " ${_data}=" | xargs echo || echo 
  present=`echo " ${_block} " | grep -c " ${_data}=" || echo` 
  if [ "${present}" == 1 ] 
  then 
    #>&2 echo -n "Check if ${_data}={@BV:${_data}@}"
    _default=`echo " ${_block} " | grep -c " ${_data}={@BV:${_data}@}" || echo`
    if [ "${_default}" == 1 ]
    then 
      #>&2 echo " - YES!"
      present=0
    #else 
    #  >&2 echo " - No"
    fi 
  fi 
  #>&2 echo "${_data} : ${present} : ${default}"
  echo ${present}
}
#}}}

# Check whether item 1 is in the datablock {{{
function _inblock { 
  #Item to check 
  _data=$1
  if [ "${_data}" == "DATAHEAD" ] || [ "${_data}" == "ALLHEAD" ]
  then 
    #Current datahead
    _head=`_read_datahead`
    if [ "${_head}" == "" ]
    then 
      #Datahead isn't defined: Error 
      echo 0
    else 
      echo 1
    fi 
  else
    #Current datablock 
    _block=`_read_datablock`
    #Check whether the requested data object is in the datablock 
    #echo " ${_block} " | grep -c " ${_data}=" | xargs echo || echo 
    echo " ${_block} " | grep -c " ${_data}="  || echo 
  fi 
}
#}}}

# Check whether the script uses the datahead {{{
function _uses_datahead { 
  #Item to check 
  _inputs=`_inp_data`
  _uses_datahead=""
  for _inp in ${_inputs}
  do 
    if [ "${_inp}" == "DATAHEAD" ]
    then 
      _uses_datahead="USES_DATAHEAD"
    elif [ "${_inp}" == "ALLHEAD" ]
    then 
      _uses_datahead="USES_ALLHEAD"
    fi 
  done
  echo ${_uses_datahead}
}
#}}}

#Convert a block entry into a filelist {{{
function _blockentry_to_filelist { 
  _term=${1##*=}
  _term=${_term//\{/}
  _term=${_term//\}/}
  _term=${_term//,/ }
  echo ${_term}
}
#}}}

# incorporate the current datablock/head into a script {{{ 
function _incorporate_datablock { 
  #Read the current datahead
  _head=`_read_datahead`
  #Read the current datablock 
  _block=`_read_datablock`
  #Read the current blockvars
  _vars=`_read_blockvars`
  ext=${1##*.}
  #If needed, back up the original file 
  if [ ! -f ${1//.${ext}/_noblock.${ext}} ]
  then 
    cp ${1} ${1//.${ext}/_noblock.${ext}}
  fi 

  #Reset the file to the pre-block state 
  #(for cases where someone runs the pipeline twice in a row)
  cp ${1//.${ext}/_noblock.${ext}} ${1//.${ext}/_prehead.${ext}}

  #Update the script to include the datablock {{{
  #nloop=0
  #while [ "`grep -c @DB: ${1//.${ext}/_prehead.${ext}} || echo`" != "0" ]
  #do 
    for item in ${_block}
    do 
      #Extract the name of the item
      base=${item%%=*}
      #Remove leading and trailing braces
      item=${item/\{,/\{}
      item=${item/\{/}
      item=${item%\}}
      #Add spaces
      item=${item//,/ }
      #Loop through entries 
      _itemlist=''
      for _file in ${item}
      do 
        #2>&1 echo -n "${#_itemlist}    \r "
        #Add full file paths 
        _itemfile=@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${base}/${_file#*=}
        _itemlist="${_itemlist} ${_itemfile}"
      done 
      #_itemlist=`echo ${_itemlist}`
      _nchunk=50000
      if [ ${#_itemlist} -gt ${_nchunk} ] 
      then 
        #>&2 echo -n "In chunks:"
        _ccount=0
        while [ ${_ccount} -lt ${#_itemlist} ]
        do 
          #>&2 echo -n '.'
          @P_SED_INPLACE@ "s#\\@DB:${item%%=*}\\@#${_itemlist:${_ccount}:${_nchunk}}\\@DB:${item%%=*}\\@#g" ${1//.${ext}/_prehead.${ext}}
          _ccount=$((_ccount+_nchunk))
        done 
        @P_SED_INPLACE@ "s#\\@DB:${item%%=*}\\@##g" ${1//.${ext}/_prehead.${ext}}
        #>&2 echo ' - Done'
      else 
        #>&2 echo "All at once"
        @P_SED_INPLACE@ "s#\\@DB:${item%%=*}\\@#${_itemlist:1}#g" ${1//.${ext}/_prehead.${ext}}
      fi 
    done 
    #((nloop+=1))
    #if [ ${nloop} -gt 100 ]
    #then 
    #  _message "@RED@ - ERROR! Infinite loop in block incorporation! A @DB:*@ variable is recursive?!@DEF@\n"
    #  exit 1 
    #fi 
  #done 
  #}}}

  #Update the script to include the blockvars {{{
  nloop=0
  while [ "`grep -v "^#" ${1//.${ext}/_prehead.${ext}} | grep -c @BV: || echo`" != "0" ]
  do 
    for item in ${_vars}
    do 
      #Extract the name of the item
      base=${item%%=*}
      #Remove leading and trailing braces
      item=${item/\{,/\{}
      item=${item/\{/}
      item=${item%\}}
      #Add spaces
      item=${item//,/ }
      #Loop through entries 
      _itemlist=''
      for _file in ${item}
      do 
        #Return variable 
        _itemfile="${_file#*=}"
        _itemfile="${_itemfile//&/\\&}"
        _itemlist="${_itemlist} ${_itemfile}"
      done 
      #_itemlist=`echo ${_itemlist}`
      @P_SED_INPLACE@ "s#\\@BV:${item%%=*}\\@#${_itemlist:1}#g" ${1//.${ext}/_prehead.${ext}}
    done 
    ((nloop+=1))
    if [ ${nloop} -gt 100 ]
    then 
      _message "@RED@ ERROR! Infinite loop in block variable incorporation for script @DEF@${1//.${ext}}@RED@!\nA @BV:*@ variable must be missing or recursive?!@DEF@\n"
      exit 1 
    fi 
  done
  #}}}

  #If we do not have a CosmoSIS file {{{
  if [ "${ext}" != "ini" ] 
  then 
    #Insert the startup code {{{
    cat > ${1} <<- EOF
		
		#Source the Script Documentation Functions {{{
		source @RUNROOT@/@MANUALPATH@/CosmoPipe.man.sh
		_initialise
		#}}}
		
		EOF
    #}}}
  fi
  #}}}

  ##Check that we have valid DATAHEAD use {{{
  #if [ "${ext}" != "ini" ] && [ "$2" == "USES_DATAHEAD" ]
  #then 
  #  _message "- @RED@ERROR\n"
  #  _message "Cannot use datahead with cosmosis input files\n"
  #  _message "@DEF -->$1\n"
  #  exit 1
  #fi 
  ##}}}

  #Check if we are stoelzner {{{
  if [ `whoami` == 'qwright' ] || [ `whoami` == 'stoelzner' ]
  then 
    if [ "${ext}" != "ini" ] && [ $(( ( RANDOM % 100 )  + 1 )) -gt 99 ] 
    then 
      echo '# Check if benjamin has had his coffee ----' >> ${1}
      echo '_message "\n\n@RED@~~~~~~~~~~~~~~~~~~~~~~~~~~~@DEF@\n"' >> ${1}
      echo '_message "@RED@~~   @BLU@ HEY! LISTEN!!!! @RED@   ~~\n"' >> ${1}
      echo '_message "@RED@~~~~~~~~~~~~~~~~~~~~~~~~~~~@DEF@\n\n"' >>${1}
      echo 'sleep 5' >> ${1}
      echo '_message "@RED@Have you had your coffee?!!\n\n"' >> ${1}
      echo 'sleep 5' >> ${1}
      echo '_message "@BLU@  If not: @DEF@GO GET IT NOW! \n"' >> ${1}
      echo 'sleep 30' >> ${1}
      echo '_message "@BLU@ Good. Now we can continue...\n@DEF@"' >> ${1}
      echo "# ----" >> ${1}
    elif [ "${ext}" != "ini" ] && [ $(( ( RANDOM % 100 )  + 1 )) -gt 99 ] 
    then 
      echo "# Ensure that Benjamin is taken care of <3 ----" >> ${1}
      echo "_message \"\n\n@RED@#####################################@DEF@\n\"" >> ${1}
      echo "_message \"@RED@#####################################@DEF@\n\"" >> ${1}
      echo "_message \"@RED@##                                 ##@DEF@\n\"" >> ${1}
      echo "_message \"@RED@##    @DEF@ IT'S  DANGEROUS  TO  GO @RED@    ##@DEF@\n\"" >> ${1}
      echo "_message \"@RED@##    @DEF@    ALONE!  TAKE  THIS.  @RED@    ##@DEF@\n\"" >> ${1}
      echo "_message \"@RED@##                                 ##@DEF@\n\"" >> ${1}
      echo "_message \"@RED@##   @BLU@           {             @RED@     ##@DEF@\n\"" >> ${1}
      echo "_message \"@RED@##   @BLU@        {   }{   }       @RED@     ##@DEF@\n\"" >> ${1}
      echo "_message \"@RED@##   @BLU@         } {  } {        @RED@     ##@DEF@\n\"" >> ${1}
      echo "_message \"@RED@##   @BLU@      .-{\\\`}\\\`}{\\\`\\\`}-.       @RED@    ##@DEF@\n\"" >> ${1}
      echo "_message \"@RED@##   @BLU@     (   } {   {   )     @RED@     ##@DEF@\n\"" >> ${1}
      echo "_message \"@RED@##   @BLU@     |\\\`-.._____..-'|     @RED@     ##@DEF@\n\"" >> ${1}
      echo "_message \"@RED@##   @BLU@     |             ;--.  @RED@     ##@DEF@\n\"" >> ${1}
      echo "_message \"@RED@##   @BLU@     |            (__  \\ @RED@     ##@DEF@\n\"" >> ${1}
      echo "_message \"@RED@##   @BLU@     |             | )  )@RED@     ##@DEF@\n\"" >> ${1}
      echo "_message \"@RED@##   @BLU@     |             |/  / @RED@     ##@DEF@\n\"" >> ${1}
      echo "_message \"@RED@##   @BLU@     |             /  /  @RED@     ##@DEF@\n\"" >> ${1}
      echo "_message \"@RED@##   @BLU@     |            (  /   @RED@     ##@DEF@\n\"" >> ${1}
      echo "_message \"@RED@##   @BLU@     \\             y'    @RED@     ##@DEF@\n\"" >> ${1}
      echo "_message \"@RED@##   @BLU@      \\\`-.._____..-'      @RED@     ##@DEF@\n\"" >> ${1}
      echo "_message \"@RED@##                                 ##@DEF@\n\"" >> ${1}
      echo "_message \"@RED@##                                 ##@DEF@\n\"" >> ${1}
      echo "_message \"@RED@#####################################@DEF@\n\"" >> ${1}
      echo "_message \"@RED@#####################################@DEF@\n\"" >> ${1}
      echo 'sleep 30' >> ${1}
      echo "# ----" >> ${1}
    fi 
  fi 
  #}}}

  #Generate main code block:  
  #Does the code work on DATAHEAD?
  if [ "$2" == "USES_DATAHEAD" ] 
  then 
    #Add code for each file in DATAHEAD {{{
    for item in ${_head} 
    do 
      echo '# ----' >> ${1}
      _itemfile=@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/DATAHEAD/${item/=/\/}
      sed "s#\\@DB:DATAHEAD\\@#${_itemfile}#g" ${1//.${ext}/_prehead.${ext}} >> ${1}
      echo '# ----' >> ${1}
    done 
    #}}}
  elif [ "$2" == "USES_ALLHEAD" ] 
  then 
    #Add code for all files in DATAHEAD together {{{
    _itemlist=''
    for item in ${_head} 
    do 
      _itemfile=@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/DATAHEAD/${item/=/\/}
      _itemlist="${_itemlist} ${_itemfile}"
    done 
    #_itemlist=`echo ${_itemlist}`
    #sed "s#\\@DB:ALLHEAD\\@#${_itemlist}#g" ${1//.${ext}/_prehead.${ext}} >> ${1}
    _nchunk=50000
    if [ ${#_itemlist} -gt ${_nchunk} ] 
    then 
      #>&2 echo -n "In chunks:"
      _ccount=0
      cat ${1//.${ext}/_prehead.${ext}} >> ${1} 
      while [ ${_ccount} -lt ${#_itemlist} ]
      do 
        #>&2 echo -n '.'
        @P_SED_INPLACE@ "s#\\@DB:ALLHEAD\\@#${_itemlist:${_ccount}:${_nchunk}}\\@DB:ALLHEAD\\@#g" ${1}
        _ccount=$((_ccount+_nchunk))
      done 
      @P_SED_INPLACE@ "s#\\@DB:ALLHEAD\\@##g" ${1} 
      #>&2 echo ' - Done'
    else 
      #>&2 echo "All at once"
      sed "s#\\@DB:ALLHEAD\\@#${_itemlist:1}#g" ${1//.${ext}/_prehead.${ext}} >> ${1}
    fi 
    #}}}
  else 
    #The code doesn't work on DATAHEAD, so just run it: {{{
    cat ${1//.${ext}/_prehead.${ext}} >> ${1}
    #}}}
  fi 

  #If we do not have a CosmoSIS file {{{
  if [ "${ext}" != "ini" ] 
  then 
    #Insert the finalisation code {{{
    cat >> ${1} <<- EOF
		
		#Finalise {{{
		_finalise
		#}}}
		
		EOF
    #}}}
  fi
  #}}}

}
#}}}

#}}}

