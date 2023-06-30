#
# Documentation & Housekeeping functions
#

#Starting Prompt {{{
function _prompt { 
  if [ "$1" != "0" ] 
  then 
    _message "\n${BLU}=====================================================${DEF}\n"
    _message "${BLU}== ${RED}     Cosmology Pipeline Construction Mode      ${BLU} ==${DEF}\n"
    _message "${BLU}=====================================================${DEF}\n\n"
    _message "Constructing the pipeline ${RED}${PIPELINE}${DEF} from the configuration file:\n"
    _message "${BLU}${RUNROOT}/${SCRIPTPATH}/pipeline.ini${DEF}\n\n"
  fi 
}
#}}}

# Abort Message {{{
_abort()
{
  _message "${RED} - !FAILED!\n" 
  _message "${BLU} An error occured while running $0.\n" 
  _message "${DEF} Check the relevant logging file for this step.\n" 
  trap : 0
  exit 1
}
trap '_abort' 0
set -e 
#}}}

# Input data {{{ 
function _inp_data { 
  #Data inputs (leave blank if none)
  echo 
} 
#}}}

# Input variables {{{ 
function _inp_var { 
  #Variable inputs (leave blank if none)
  echo 
} 
#}}}

# Output data {{{ 
function _outputs { 
  #NONE
  echo 
} 
#}}}

#Additional Functions 

#Read pipeline {{{
function _read_pipe { 
  #Pipeline file location 
  _PIPELOC=${RUNROOT}/pipeline.ini
  #Step & step number 
  _step=${1}
  _stepnum=''
  #If there is a number provided, use that: 
  if [ "${2}" != "" ] 
  then 
    #Use substep numbering if stepnum is provided
    _stepnum="${2}."
  fi 
  #Check for the number of pipelines with this name, and continue if 0
  _npipe=`grep -v "^#" ${_PIPELOC} | grep -Fc --ignore-case "${_step}:" | xargs echo `
  #>&2 echo "Number of pipelines: ${_npipe}"
  if [ "${_npipe}" == "0" ]
  then 
    _message "${RED} - ERROR${DEF}\n\n"
    _message "${RED}ERROR: There is no pipeline called ${_step} in the pipeline script:\n"
    _message "${BLU}       ${_PIPELOC}${DEF}\n"
    exit 1
  elif [ "${_npipe}" != "1" ]
  then 
    _message "${RED} - ERROR${DEF}\n\n"
    _message "${RED}ERROR: There is more than one pipeline called ${_step} in the pipeline script! There are ${_npipe}.\n"
    _message "${BLU}       ${_PIPELOC}${DEF}\n"
    exit 1
  fi
  #Create the steps with numbering 
  grep -v "^#" ${_PIPELOC} | awk -v S="${_stepnum}" -v pipe="${_step}:" -v seen="F" -v count=0 '{
    if ($1 == "" ) next
      if ($1 != pipe && seen == "F") {
        next
      } else if ($1 == pipe) {
      seen="T"
    }
    #If we arrive at the next block, break
    if (substr($1,length($1),1) == ":" && $1 != pipe) {
      seen="F"
      next
    }
    inquote="F"
    for(i=1; i<=NF; i++) {
      if (inquote=="T") { 
        res=match($i,"\"")
        if (res==0) { 
          quotestring=quotestring "," $i 
        } else { 
          print quotestring "," $i "=_"
          inquote="F"
        }
      } else { 
        if (i!=1 || substr($i,length($i),1)!=":") {
          if (substr($i,1,1) == "@" || substr($i,1,1) == "!" || substr($i,1,1) == "%" ) {
            #Step has no number
            print $i "=_"
          } else if ( $i == "RESUME") {
            print $i 
          } else if (substr($i,1,1) == "+") {
            #Step is a variable assignment 
            match($i,"=")
            if (substr($i,RSTART+1,1)=="\"") { 
              inquote="T"
              quotestring=$i
            } else { 
              print $i "=_"
            }
          } else if (substr($i,1,1) == "#") {
            next
          } else {
            #Add (sub)step number
            count+=1
            print $i "=" S count
          }
        }
      }
    }
  }' | xargs echo
  #grep -v "^#" ${_PIPELOC} | grep --ignore-case "${1}:" | awk -F: '{print $2}' | \
  #  awk -v S=${_stepnum} '{
  #    count=0 
  #    for(i=1; i<=NF; i++) 
  #      if (substr($i,1,1) == "@" || substr($i,1,1) == "!") {
  #        #Step has no number 
  #        print $i "=_" 
  #      } else {
  #        #Add (sub)step number
  #        count+=1
  #        print $i "=" S count
  #      }
  #    }' | xargs echo 
} 
#}}}

#Pipeline Opening Prompt {{{
function _openingprompt { 
  _banner="===================================="
  echo "echo -e \"@BLU@==============${_banner:0:${#PIPELINE}}===================@DEF@\""
  echo "echo -e \"@BLU@== @RED@ CosmoPipe Pipeline File: ${PIPELINE} @BLU@ ==@DEF@\""
  echo "echo -e \"@BLU@==============${_banner:0:${#PIPELINE}}===================@DEF@\""
  echo  
}
#}}}

#Pipeline Closing Prompt {{{
function _closingprompt { 
  echo 
  echo "echo -e \"@BLU@====================================@DEF@\""
  echo "echo -e \"@BLU@== @RED@ CosmoPipe Pipeline Finished! @BLU@ ==@DEF@\""
  echo "echo -e \"@BLU@====================================@DEF@\""
}
#}}}


