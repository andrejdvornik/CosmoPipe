
#Initialisation function {{{ 
function _initialise { 
  _callname=${0##*/} 
  if [ ! -f @RUNROOT@/@MANUALPATH@/${_callname//.sh/.man.sh} ] 
  then 
    _message "${RED} - ERROR! Manual file does not exist!"
    exit 1
  fi 
  source @RUNROOT@/@MANUALPATH@/${_callname//.sh/.man.sh}
  _prompt ${VERBOSE}
}
#}}}

#Finalisation function {{{
function _finalise {
  _unset_functions
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
  _missing=''
  for var in $_varlist
  do 
    if [ "${var:0:3}" == "DB:" ]
    then 
      #Skip data block variables 
      continue
    fi 
    if [ "${!var}" == "" ] 
    then 
      _err=$((_err+1))
      missing="$missing $var"
    elif [ "${!var}" == "@${var^^}@" ]
    then 
      _err=$((_err+1))
      undefined="$undefined $var"
    fi 
  done  
  if [ "${_err}" == "1" ]
  then 
    if [ "${undefined}" != "" ]
    then 
      echo "ERROR: Input variable$undefined, required by the mode ${1##*/}, is still set to a placeholder value!"
    else
      echo "ERROR: Input variable$missing, required by the mode ${1##*/}, is missing entirely (not in the variables file)!"
    fi 
    exit 1 
  elif [ "${_err}" != "0" ]
  then 
    if [ "${undefined}" != "" ]
    then 
      echo "ERROR: Input variables$undefined, required by the mode ${1##*/}, are still set to their placeholder values!"
    fi
    if [ "${missing}" != "" ]
    then
      echo "ERROR: Input variables$missing, required by the mode ${1##*/}, are missing entirely (not in the variables file)!"
    fi
    exit 1 
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

#Number of tomographic bins {{{
function _ntomo { 
  #Number of Tomographic bins specified
  echo '@TOMOLIMS@' | awk '{print NF-1}'
}
#}}}

#Datablock Functions {{{ 

#Initialise the datablock {{{
function _initialise_datablock { 
  #Make the datablock directory, if needed
  if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/ ]
  then 
    mkdir -p @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/
  fi 
  if [ ! -f @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/block.txt ]
  then 
    #Initialise the datablock txt file 
    echo "HEAD: " > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/block.txt
    echo "BLOCK: " >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/block.txt
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
  echo ${_outblock}
}
#}}}

#Write the datablock {{{
function _write_datablock { 
  _head=`_read_datahead`
  #Get the files in this data
  _block=`_read_datablock`
  #Update the datablock txt file: HEAD
  echo "HEAD:" > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/block.txt
  #Add HEAD items to file 
  for _file in ${_head} 
  do 
    echo "${_file}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/block.txt
  done 
  #Update the BLOCK items 
  echo "BLOCK:" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/block.txt
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
  done < @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/block.txt
  echo ${_outhead}
}
#}}}

#Write the datahead {{{
#function _write_datahead { 
function _add_datahead { 
  _block=`_read_datablock`
  #Copy the requested data to the datahead 
  if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${1}/ ] 
  then 
    _message "@RED@ - ERROR! The requested data block component ${1} does not have a folder in the data block?!"
    exit -1 
  fi 
  #remove the existing data in the datahead
  if [ -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/DATAHEAD ]
  then 
    dir=`pwd`
    cd @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/DATAHEAD
    rm -fr ./*.*
    cd $dir
  fi 
  #Copy the requested data to the datahead, if the directory contains anything  
  if [ "$(ls -A @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${1})" ] 
  then 
    rsync -autv @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${1}/* @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/DATAHEAD/ >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/datahead_write.log
  fi 
  #Get the files in this data
  _files=`_read_datablock ${1}`
  _files=${_files##*=}
  _files=${_files//\}/}
  _files=${_files//\{/}
  _files=${_files//,/ }
  #Update the datablock txt file 
  echo "HEAD:" > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/block.txt
  for _file in ${_files} 
  do 
    echo "${_file}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/block.txt
  done 
  echo "BLOCK:" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/block.txt
  for _file in ${_block} 
  do 
    #_file=`echo $_file`
    echo "${_file}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/block.txt
  done
}
#}}}

#Replace an item in the datahead {{{
function _replace_datahead { 
  #Current block
  _block=`_read_datablock`
  #Current head 
  _head=`_read_datahead`
  #Update the datablock txt file 
  echo "HEAD:" > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/block.txt
  for _file in ${_head} 
  do 
    #If this is the file we want to update 
    if [ "${_file}" == "${1}" ] 
    then 
      #Replace this file in the datahead
      echo "${2}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/block.txt
      #Remove the old file 
      rm -f @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/DATAHEAD/${_file}
    else 
      #Otherwise keep going
      echo "${_file}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/block.txt
    fi
  done 
  echo "BLOCK:" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/block.txt
  for _file in ${_block} 
  do 
    #_file=`echo $_file`
    echo "${_file}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/block.txt
  done
}
#}}}

#Add an item to the datahead {{{
#function _add_datahead { 
function _write_datahead { 
  #Current block
  _block=`_read_datablock`
  #Current head 
  _head=`_read_datahead`
  #Update the datablock txt file 
  echo "HEAD:" > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/block.txt
  for _file in ${_head} 
  do 
    #Print the existing datahead items 
    echo "${_file}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/block.txt
  done 
  #Add the new item 
  echo "${2}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/block.txt
  #Write out the block 
  echo "BLOCK:" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/block.txt
  for _file in ${_block} 
  do 
    #_file=`echo ${_file}`
    echo "${_file}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/block.txt
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
    for _file in $2
    do 
      if [ -e "$_file" ]
      then 
        _message " @BLU@>@DEF@ ${_file##*/} @BLU@-->@DEF@ ${1}"
        rsync -autv $_file @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${1}/${_file##*/} >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/datablock_add.log
        _message "@BLU@ - @RED@Done!@DEF@\n"
      fi 
    done 
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
  #Append the full path to head entries 
  for item in ${_head}
  do 
    _itemlist="${_itemlist} @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/DATAHEAD/${item}"
  done 
  #Add the datahead entries to the block 
  _add_datablock ${1} "${_itemlist}"
}
#}}}

# Check whether item 1 is in the datablock {{{
function _inblock { 
  #Item to check 
  _data=$1
  if [ "${_data}" == "DATAHEAD" ]
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
    echo " ${_block} " | grep -c " ${_data}=" | xargs echo
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

# incorporate the current datablock/head into a script {{{ 
function _incorporate_datablock { 
  #Read the current datahead
  _head=`_read_datahead`
  #Read the current datablock 
  _block=`_read_datablock`
  #If needed, back up the original file 
  if [ ! -f ${1//.sh/_noblock.sh} ]
  then 
    cp ${1} ${1//.sh/_noblock.sh}
  fi 

  #Reset the file to the pre-block state 
  #(for cases where someone runs the pipeline twice in a row)
  cp ${1//.sh/_noblock.sh} ${1//.sh/_prehead.sh}

  #Update the script to include the datablock {{{
  for item in ${_block}
  do 
    #Extract the name of the item
    base=${item%%=*}
    #Remove leading and trailing braces
    item=${item//\{/}
    item=${item//\}/}
    #Add spaces
    item=${item//,/ }
    #Loop through entries 
    _itemlist=''
    for _file in ${item}
    do 
      #Add full file paths 
      _itemfile=@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${base}/${_file#*=}
      _itemlist="${_itemlist} ${_itemfile}"
    done 
    #_itemlist=`echo ${_itemlist}`
    @P_SED_INPLACE@ "s#\\@DB:${item%%=*}\\@#${_itemlist:1}#g" ${1//.sh/_prehead.sh}
  done 
  #}}}

  #Insert the startup code {{{
  cat > ${1} <<- EOF
	
	#Source the Script Documentation Functions {{{
	source @RUNROOT@/@MANUALPATH@/CosmoPipe.man.sh
	_initialise
	#}}}
	
	EOF
  #}}}

  #Generate main code block:  
  #Does the code work on DATAHEAD?
  if [ "$2" == "USES_DATAHEAD" ] 
  then 
    #Add code for each file in DATAHEAD {{{
    _itemlist=''
    for item in ${_head} 
    do 
      echo '# ----' >> ${1}
      _itemfile=@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/DATAHEAD/${item/=/\/}
      sed "s#\\@DB:DATAHEAD\\@#${_itemfile}#g" ${1//.sh/_prehead.sh} >> ${1}
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
      _itemlist="${_itemlist} ${itemfile}"
    done 
    #_itemlist=`echo ${_itemlist}`
    sed "s#\\@DB:ALLHEAD\\@#${_itemlist}#g" ${1//.sh/_prehead.sh} >> ${1}
    #}}}
  else 
    #The code doesn't work on DATAHEAD, so just run it: {{{
    cat ${1//.sh/_prehead.sh} >> ${1}
    #}}}
  fi 

  #Insert the finalisation code {{{
  cat >> ${1} <<- EOF
	
	#Finalise {{{
	_finalise
	#}}}
	
	EOF
  #}}}
}
#}}}

#}}}

