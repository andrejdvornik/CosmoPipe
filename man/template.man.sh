#
# Documentation & Housekeeping functions
#

#Starting Prompt {{{
function _prompt { 
  #Check if we do want verbose output
  if [ "$1" != "0" ] 
  then 
    echo -e "${BLU}=====================================================${DEF}"
    echo -e "${BLU}== ${RED} Cosmology Pipeline Template Manual File ${BLU} ==${DEF}"
    echo -e "${BLU}=====================================================${DEF}"
  fi 
}
#}}}

#Mode description {{{
function _description { 
  echo 
  echo "# A short description of what the mode does."
  echo "#"
  echo "# Function takes input data:"
  echo "# `_inp_dat`"
  echo "#"
}
#}}}

# Abort Message {{{
_abort()
{
  #Message to print when script aborts 
  echo -e "${RED} - !FAILED!" >&2
  #$0 is the script that was running when this error occurred
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


