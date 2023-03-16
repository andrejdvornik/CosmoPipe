
#Message function {{{ 
function _message { 
  if [ "$VERBOSE" != "0" ] 
  then 
    echo -en "$1"
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
    if [ "${!var}" == "@${var^^}@" ]
    then 
      _err=$((_err+1))
      missing="$missing $var"
    fi 
  done  
  if [ "${_err}" == "1" ]
  then 
    echo "ERROR: Input variable$missing, required by the mode $(basename $1), is undefined"
    exit 1 
  elif [ "${_err}" != "0" ]
  then 
    echo "ERROR: Input variables$missing, required by the mode $( basename $1), are undefined"
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
  echo $TOMOLIMS | awk '{print NF-1}'
}
#}}}
