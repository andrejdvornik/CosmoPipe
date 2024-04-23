#
# Documentation & Housekeeping functions
#

#Starting Prompt {{{
function _prompt { 
  #Check if we do want verbose output
  if [ "$1" != "0" ] 
  then 
    _message "${BLU}=====================================================${DEF}\n"
    _message "${BLU}== ${RED} Cosmology Pipeline Template Manual File ${BLU} ==${DEF}\n"
    _message "${BLU}=====================================================${DEF}\n"
  fi 
}
#}}}

#Mode description {{{
function _description { 
  echo 
  echo "# A short description of what the mode does."
  echo "#"
  echo "# Function takes input data:"
  echo "# `_inp_data`"
  echo "#"
}
#}}}

# Abort Message {{{
_abort()
{
  #Message to print when script aborts 
  _message "${RED} - !FAILED!\n"
  #$0 is the script that was running when this error occurred
  _message "${BLU} An error occured while running $0.\n"
  _message "${DEF} Check the relevant logging file for this step.\n\n"
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
  #Data outputs (leave blank if none)
  echo 
} 
#}}}

#Additional Functions 


