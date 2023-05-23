#
# Script to construct a pipeline from input pipeline descriptor 
#

set -e 
#set -x 

#Source the Script Documentation Functions {{{
source @RUNROOT@/@MANUALPATH@/CosmoPipe.man.sh
_initialise
#}}}

#Paths and variables for configuration {{{
source @RUNROOT@/variables.sh
#}}}

#Do the variable check {{{
blockneeds=`_varcheck $0`
#}}}

#Read the pipeline description file {{{
pipeline_steps=`_read_pipe @PIPELINE@`
#>&2 echo ${pipeline_steps}
count=0
#If there are any substeps 
while [[ " ${pipeline_steps} " =~ " ." ]]
do 
  count=$((count+1))
  #Loop through the steps
  for step in ${pipeline_steps}
  do 
    #Strip out the step number {{{
    stepnum=${step##*=}
    step=${step%=*}
    #}}}
    #If the step is a substep
    if [ "${step:0:1}" == "." ]
    then 
      #Read the substep modes 
      sublist=`_read_pipe $step ${stepnum}` 
      #Replace the substep (whole matches only)
      pipeline_steps=`echo " $pipeline_steps " | sed "s/ $step=${stepnum} / $sublist /" | xargs echo `
    fi 
  done 
  #If count > 100: there is something wrong 
  if [ $count -gt 100 ] 
  then 
    _message " -ERROR! Something has gone wrong with the pipeline step determination...\n"
    _message " Current pipeline step list is:\n"
    _message " ${pipeline_steps}"
    exit 1
  fi 
done
#}}}

#Check that all functions exits {{{
_err=0
for step in ${pipeline_steps}
do 
  #Strip out the version number 
  step=${step%=*}
  #If the step is not a HEAD or VARS change
  if [ "${step:0:1}" != "@" ] && [ "${step:0:1}" != "!" ] \
    && [ "${step:0:1}" != "%" ] && [ "${step:0:1}" != "+" ] && [ "${step:0:1}" != "-" ]
  then 
    #If the step has no script 
    if [ ! -f @RUNROOT@/@SCRIPTPATH@/${step}.sh ] && [ ! -f @RUNROOT@/@CONFIGPATH@/${step}.ini ]
    then 
      #Notify the user that it is missing 
      if [ ${_err} == "0" ]
      then 
        missing="${step}.sh"
      else 
        missing="${missing}\n${step}.sh"
      fi 
      _err=$((_err+1))
    fi 
  fi
done 
#If there was an error, prompt and stop 
if [ "${_err}" != "0" ]
then 
  if [ "${_err}" == "1" ]
  then 
    #If there was only one missing file 
    _message "${RED} - ERROR${DEF}\n\n"
    _message "   ${RED}ERROR: script ${missing} does not exist in the script path!${DEF}\n"
    _message "   ${BLU}       it is either misspelled in the pipeline.ini file, or does not exist yet!${DEF}\n"
    exit 1
  else 
    #If there was many missing files 
    _message "${RED} - ERROR${DEF}\n\n"
    _message "${RED}ERROR: the following ${_err} scripts do not exist in the script path!${DEF}\n"
    _message "${missing}\n"
    _message "${BLU}They are either misspelled in the pipeline.ini file, or does not exist yet!${DEF}\n"
    exit 1
  fi 
fi 
#}}}

#Initialise datablock {{{ 
if [ -f @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/block.txt ] 
then 
  #echo -en "\nBLOCK EXISTS:"
  #Check if block is a testing block 
  ntest=`grep -c "_validitytest_" @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/block.txt || echo `
  #Save the current block status
  if [ ! -f @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/run_block.txt ] && [ "${ntest}" == "0" ]
  then 
    #echo -en " COPY BLOCK TO RUNBLOCK\n"
    #run_block will already exist if a recent pipeline construction attempt failed... don't overwrite it!
    cp @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/block.txt @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/run_block.txt
  elif [ -f @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/run_block.txt ] 
  then 
    #echo -en " COPY RUNBLOCK TO BLOCK\n"
    #reset the block 
    cp @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/run_block.txt @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/block.txt
  elif [ "${ntest}" != "0"  ]
  then 
    #echo -en " REMOVE BLOCK & START NEW (${ntest})\n"
    rm  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/block.txt
    _initialise_datablock
  fi 
  @P_SED_INPLACE@ "s/={.*/={_validitytest_}/" @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/block.txt
else 
  echo -en " NO BLOCK : START NEW\n"
  _initialise_datablock
fi
#}}}

#Check the validity of the pipeline {{{
#Add default variables (if they exist) {{{
if [ -f @PIPELINE@_defaults.sh ]
then 
  _add_default_vars
fi 
#}}}
#For each step in the pipeline: 
for step in ${pipeline_steps}
do 
  #Strip out the version number 
  step=${step%=*}
  #If the step is a HEAD update 
  if [ "${step:0:1}" == "@" ]
  then 
    #Modify the HEAD to the request value {{{
    _write_datahead "${step:1}" "_validitytest_"
    #}}}
  elif [ "${step:0:1}" == "!" ]
  then 
    #Modify the datablock with the current HEAD {{{
		_write_datablock ${step:1} "`_read_datahead`"
    #}}}
  elif [ "${step:0:1}" == "%" ]
  then 
    #Modify the datablock with the current HEAD {{{
    names=${step:1}
    oldname=${names%%-*}
    newname=${names##*-}
		_rename_blockitem "${oldname}" "${newname}" TEST
    #}}}
  elif [ "${step:0:1}" == "+" ]
  then 
    #Add the new variable to the datablock {{{
    _write_blockvars ${step:1} "_validitytest_"
    #}}}
  else 
    #Check for the manual file  {{{
    if [ ! -f @RUNROOT@/@MANUALPATH@/${step}.man.sh ]
    then 
      #If not found, error 
      _message "${RED} - ERROR${DEF}\n\n"
      _message "${RED}ERROR: the manual files for the following script are not available!\n   ${step}.sh!${DEF}\n"
      exit 1
    fi
    #}}}
    #Source the step documentation {{{
    source @RUNROOT@/@MANUALPATH@/${step}.man.sh 
    #}}}
    #Perform the variable check {{{
    blockneeds=`_varcheck $step.sh`
    if [ ! -f  @PIPELINE@_defaults.sh ] 
    then 
      touch  @PIPELINE@_defaults.sh
    fi 
    if [ "${blockneeds}" != "" ]
    then 
      for var in ${blockneeds}
      do 
        #Check whether the variable is already in the pipeline defaults 
        exists=`grep -c "^${var}=" @PIPELINE@_defaults.sh || echo`
        if [ "${exists}" == "0" ]
        then 
          #If not, check whether the global defaults file exists 
          if [ -f defaults.sh ]
          then 
            #If so, check whether this variable is in the global defaults 
            exists=`grep -c "^${var}=" defaults.sh || echo`
            if [ "${exists}" != "0" ]
            then 
              #If so, use the global default 
              grep -m 1 -B 1 "${var}=" defaults.sh >> @PIPELINE@_defaults.sh 
            else 
              #Otherwise, insert a blank entry 
              echo "#INSERT DEFAULT VALUE HERE:" >> @PIPELINE@_defaults.sh 
              echo ${var}=@${var}@ >> @PIPELINE@_defaults.sh 
            fi
          else 
            #If there is no global defaults, insert a blank entry 
            echo "#INSERT DEFAULT VALUE HERE:" >> @PIPELINE@_defaults.sh 
            echo ${var}=@${var}@ >> @PIPELINE@_defaults.sh 
          fi 
        fi 
      done 
      #sort @PIPELINE@_defaults.sh | uniq > @PIPELINE@_defaults_uniq.sh
      #mv @PIPELINE@_defaults_uniq.sh @PIPELINE@_defaults.sh
    fi 
    #}}}
    #Check inputs and outputs {{{
    inputs=`_inp_data`
    outputs=`_outputs`
    #}}}
    #Check the data block for these inputs {{{
    for inp in $inputs
    do 
      #If not in the data block 
      if [ "$(_inblock $inp)" == "0" ] 
      then 
        if [ "${inp}" == "ALLHEAD" ]
        then 
          #Error 
          _message "${RED}(WARNING)${DEF} "
        else 
          #Error 
          _message " - ERROR!\n\n"
          _message "   ${RED}ERROR: ${BLU}Input ${DEF}${inp}${BLU} does not exist in the data-block when needed for step ${DEF}${step}${BLU}!${DEF}\n" 
          _message "                ${BLU}`_read_datablock`\n"
          _message "   ${RED}       Pipeline is invalid!${DEF}\n" 
          exit 1 
        fi 
      fi 
    done 
    #}}}
    #Save these outputs to the data block  {{{
    for out in $outputs
    do 
      if [ "${out}" != "DATAHEAD" ] && [ "${out}" != "ALLHEAD" ]
      then 
        _write_datablock $out "_validitytest_"
      fi 
    done 
    datablock=`_read_datablock`
    #}}}
  fi 
done
#Reset the documentation functions 
VERBOSE=0 _initialise
#Remove the test block 
rm -f @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/block.txt
#Remove empty datablock directories {{{
for item in `ls @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/`
do 
  #If the item is a directory 
  if [ -d ${item} ]
  then 
    #If the directory is empty {{{
    if [ ! "$(ls -A ${item})" ]
    then 
      #Remove the directory {{{
      rmdir ${item}
      #}}}
    fi 
    #}}}
  fi 
done 
#}}}
#Replace the initial block, if present {{{
if [ -f @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/run_block.txt ]
then 
  mv @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/run_block.txt @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/block.txt
fi 
#}}}
#}}}

#Pipeline is valid: construct pipeline commands {{{
#Preamble 
cat @RUNROOT@/@SCRIPTPATH@/pipeline_base.sh > @RUNROOT@/@PIPELINE@_pipeline.sh

#Add the opening prompt {{{
cat >> @RUNROOT@/@PIPELINE@_pipeline.sh <<- EOF 
`_openingprompt`

#Add the default variables to the datablock 
_add_default_vars 
EOF
#}}}

#For each step in the pipeline {{{
for step in ${pipeline_steps}
do 
  #Strip out the version number {{{
  stepnum=${step##*=}
  step=${step%=*}
  #}}}
  #Write each step of the pipeline 
  if [ "${step:0:1}" == "@" ]
  then 
    if [ "${step:1}" == "" ] 
    then 
    	#If this is a datahead clearing: {{{
    	cat >> @RUNROOT@/@PIPELINE@_pipeline.sh <<- EOF 
			
			#Clear the datahead 
			#Intermediate Step: clear the DATAHEAD {{{
			#Notify
			_message "@BLU@Clearing the current DATAHEAD @DEF@ {\n"
			#Erase the datahead by doing a NULL assignment 
			_write_datahead "${step:1}"
			#Notify
			_message "} - @RED@Done!@DEF@\n"
			#}}}


			EOF
    	#}}}
    else 
    	#If this is a datahead assignment: {{{
    	cat >> @RUNROOT@/@PIPELINE@_pipeline.sh <<- EOF 
			
			#Modify the HEAD to the request value
			#Intermediate Step: write block item ${step:1} to current DATAHEAD {{{
			#Notify
			_message "@BLU@Copying requested elements of ${step:1} to DATAHEAD @DEF@ {\n"
			#Modify the current HEAD to requested block element
			_add_datahead "${step:1}"
			#Notify
			_message "} - @RED@Done!@DEF@\n"
			#}}}


			EOF
    	#}}}
    fi
  elif [ "${step:0:1}" == "!" ]
  then 
    #If this is a datablock assignment: {{{
    cat >> @RUNROOT@/@PIPELINE@_pipeline.sh <<- EOF 
		
		#Intermediate Step: write current DATAHEAD to block item: ${step:1} {{{
		#Notify
		_message "@BLU@Copying current DATAHEAD items to ${step:1}@DEF@ {\n"
		#Modify the datablock with the current HEAD
		_add_head_to_block ${step:1} 
		#Notify
		_message "} - @RED@Done!@DEF@\n"
		#}}}

		EOF
    #}}}
  elif [ "${step:0:1}" == "%" ]
  then 
    names=${step:1}
    oldname=${names%%-*}
    newname=${names##*-}
    #If this is a datablock rename: {{{
    cat >> @RUNROOT@/@PIPELINE@_pipeline.sh <<- EOF 
		
		#Intermediate Step: rename block item ${oldname} to ${newname} {{{
		#Notify
		_message "@BLU@Renaming block item ${oldname} to ${newname}@DEF@"
		#Rename block item
		_rename_blockitem "${oldname}" "${newname}"
		#Notify
		_message " - @RED@Done!@DEF@\n"
		#}}}

		EOF
    #}}}
  elif [ "${step:0:1}" == "+" ]
  then 
    #>&2 echo "ASSIGNMENT TIME: ${step}"
    #If this is a blockvariable assignment: {{{
    _var=${step:1}
    _varval=${_var#*=}
    _var=${_var%%=*}
    cat >> @RUNROOT@/@PIPELINE@_pipeline.sh <<- EOF 
		
		#Modify the block variable to the request value
		#Intermediate Step: write block variable ${_var} to requested value {{{
		#Notify
		_message "@BLU@Assigning variable @RED@${_var^^}@BLU@ to @DEF@${_varval}"
		#Modify the VARS to include requested block element
		_write_blockvars ${_var^^} "${_varval}"
		#Notify
		_message " @BLU@- @RED@Done!@DEF@\n"
		#}}}


		EOF
    #}}}
  else 
    #If this is a bone-fide script method {{{
    #Source the documentation information 
    source @RUNROOT@/@MANUALPATH@/${step}.man.sh 
    if [ -f @RUNROOT@/@SCRIPTPATH@/${step}.sh ] 
    then 
      basefile=@RUNROOT@/@SCRIPTPATH@/${step}.sh
    else 
      basefile=@RUNROOT@/@CONFIGPATH@/${step}.ini
    fi
    #Write the step to the pipeline file {{{
    cat >> @RUNROOT@/@PIPELINE@_pipeline.sh <<- EOF 
		
		#Step $stepnum: $step {{{
		#DESCRIPTION: #{{{
		`_description`
		#}}}
		#Update script for datablock 
		_incorporate_datablock ${basefile} `_uses_datahead`
		#Run the mode 
		`_runcommand` > @RUNROOT@/@LOGPATH@/step_${stepnum}_${step##*/}.log
		#}}}
		 
		EOF
    #}}}
    #}}}
  fi
done 
#}}}

#Add the closing prompt {{{
cat >> @RUNROOT@/@PIPELINE@_pipeline.sh <<- EOF 
`_closingprompt`
EOF
#}}}

#Add the pipeline end
cat @RUNROOT@/@SCRIPTPATH@/pipeline_close.sh >> @RUNROOT@/@PIPELINE@_pipeline.sh

#}}}

#End
trap : 0 
