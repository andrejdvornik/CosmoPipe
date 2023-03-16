#
# Script to construct a pipeline from input pipeline descriptor 
#

set -e 

#Source the Script Documentation Functions {{{
source @RUNROOT@/@MANUALPATH@/CosmoPipe.man.sh
source @RUNROOT@/@MANUALPATH@/$(basename ${0//.sh/.man.sh})
#}}}

#Do the variable check {{{
_varcheck $0
#}}}

#Read the pipeline description file {{{
pipeline_steps=`_read_pipe @PIPELINE@`
pipeline_scount=""
#If there are any substeps 
while [ "${pipeline_steps//[^.]}" != "" ]
do 
  #Loop through the steps
  for step in ${pipeline_steps}
  do 
    #If the step is a substep
    if [ "${step:0:1}" == "." ]
    then 
      #Read the substep modes 
      sublist=`_read_pipe $step` 
      #Replace the substep (whole matches only)
      pipeline_steps=`echo " $pipeline_steps " | sed "s/ $step / $sublist /" | xargs echo `
    fi 
  done 
done
#}}}

#Check that all functions exits {{{
for step in ${pipeline_steps}
do 
  if [ ! -f @RUNROOT@/@SCRIPTPATH@/${step}.sh ] 
  then 
    _message "${RED}ERROR: script ${step}.sh does not exist in the script path!${DEF}\n"
    _message "${BLU}       it is either misspelled in the pipeline.ini file, or does not exist yet!${DEF}\n"
  fi 
done 
#}}}

#Initialise datablock {{{ 
datablock=""
#}}}

#Check the validity of the pipeline {{{
#For each step in the pipeline: 
for step in ${pipeline_steps}
do 
  #Source the step documentation 
  source @RUNROOT@/@MANUALPATH@/${step//.sh/.man.sh} 
  #Perform the variable check 
  _varcheck $step
  #Check inputs and outputs 
  inputs=_inp_data
  outputs=_outputs
  #Check the data block for these inputs 
  for inp in $inputs
  do 
    #If not in the data block 
    if [ $(_inblock "$datablock" $inp) ]
    then 
      #Error 
      _message "${RED}ERROR: ${BLU}Input ${DEF}${inp}${BLU} does not exist in the data-block when needed for step ${DEF}${step}${BLU}!${DEF}\n" 
      _message "${RED}       Pipeline is invalid!${DEF}\n" 
      exit 1 
    fi 
  done 
  #Save these outputs to the data block 
  datablock=`echo $datablock $outputs`
done
#Reset the documentation functions 
source @RUNROOT@/@MANUALPATH@/${0//.sh/.man.sh} 
#}}}

#Pipeline is valid: construct pipeline commands {{{
#Preamble 
cat @RUNROOT@/@SCRIPTPATH@/pipeline_base.sh > @RUNROOT@/@SCRIPTPATH@/@PIPELINE@_pipeline.sh

#For each step in the pipeline
for step in ${pipeline_steps}
do 
  #Source the documentation information 
  source @RUNROOT@/@MANUALPATH@/${step//.sh/.man.sh} 
  #Write the step to the pipeline file 
  cat >> @RUNROOT@/@SCRIPTPATH@/@PIPELINE@_pipeline.sh <<- EOF 
  
  #Step $count: $step {{{
  #DESCRIPTION: #{{{
  `_description`
  #}}}
  #Source function commands 
  source @RUNROOT@/@MANUALPATH@/${step//.sh/.man.sh}
  #Run the mode 
  `_runcommand`
  #}}}
   
  EOF
done 

#Add the pipeline end
cat @RUNROOT@/@SCRIPTPATH@/pipeline_close.sh >> @RUNROOT@/@SCRIPTPATH@/@PIPELINE@_pipeline.sh
#}}}

