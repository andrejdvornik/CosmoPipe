#
# Documentation & Housekeeping functions
#

#Starting Prompt {{{
function _prompt { 
  if [ "$1" != "0" ] 
  then 
    echo 
    echo -e "${BLU}=====================================================${DEF}"
    echo -e "${BLU}== ${RED}     Cosmology Pipeline Construction Mode      ${BLU} ==${DEF}"
    echo -e "${BLU}=====================================================${DEF}"
    echo 
    echo -e "Constructing the pipelin ${RED}${PIPELINE}${DEF} from the configuration file:"
    echo -e "${BLU}${RUNROOT}/${SCRIPTPATH}/pipeline.ini${DEF}"
    echo 
  fi 
}
#}}}

# Abort Message {{{
_abort()
{
  echo -e "${RED} - !FAILED!" >&2
  echo -e "${BLU} An error occured while running $0." >&2
  echo -e "${DEF} Check the relevant logging file for this step." >&2
  echo >&2
  exit 1
}
trap '_abort' 0
set -e 
#}}}

# Input data {{{ 
function _inp_data { 
  #Data inputs: NONE
  echo 
} 
#}}}

# Input variables {{{ 
function _inp_var { 
  #Variable inputs 
  echo RUNROOT SCRIPTPATH PIPELINE
} 
#}}}

# Output data {{{ 
function _outputs { 
  #NONE
  echo 
} 
#}}}

#Additional Functions 

function _read_pipe { 
  #Check for the number of pipelines with this name, and continue if 0
  _npipe=`grep -c --ignore-case "${1}:" ${RUNROOT}/${SCRIPTPATH}/pipeline.ini || echo 0`
  if [ "${_npipe}" == "0" ]
  then 
    _message "${RED}ERROR: There is no pipeline called ${1} in the pipeline script:\n"
    _message "${BLU}       ${RUNROOT}/${SCRIPTPATH}/pipeline.ini${DEF}\n"
    exit 1
  elif [ "${_npipe}" != "1" ]
  then 
    _message "${RED}ERROR: There is more than one pipeline called ${1} in the pipeline script! There are ${_npipe}.\n"
    _message "${BLU}       ${RUNROOT}/${SCRIPTPATH}/pipeline.ini${DEF}\n"
    exit 1
  fi
  grep --ignore-case "${1}:" ${RUNROOT}/${SCRIPTPATH}/pipeline.ini | awk -F: '{print $2}' | xargs echo 
} 

