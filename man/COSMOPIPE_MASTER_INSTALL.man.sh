#
# Documentation & Housekeeping functions
#

#Starting Prompt {{{
function _prompt { 
  echo -e "${BLU}=====================================================${DEF}"
  echo -e "${BLU}== ${RED} Cosmology Pipeline Installation Master Script ${BLU} ==${DEF}"
  echo -e "${BLU}=====================================================${DEF}"
  sleep 1
  echo -e "Welcome to the installation script, ${RED}`whoami`${DEF}!" 
  if [ "$1" != "0" ] 
  then 
    sleep .2
    echo -e "I will be running with many ${RED} pre-defined ${DEF} variables! A sample are below:"
    echo -e "(These can be edited now in the MASTER_INSTALL ${RED} or ${DEF} later in your configure.sh)"
    sleep .2
    echo -e "    RUNROOT${BLU}=${RED}$RUNROOT ${DEF}"
    echo -e "    SURVEY${BLU}=${RED}$SURVEY ${DEF}"
    echo -e "    SURVEYAREA${BLU}=${RED}$SURVEYAREA ${DEF}"
    echo -e "    PATCHPATH${BLU}=${RED}$PATCHPATH ${DEF}"
    echo -e "    PATCHLIST${BLU}=${RED}$PATCHLIST ${DEF}"
    echo -e "    ALLPATCH${BLU}=${RED}$ALLPATCH ${DEF}"
    echo -e "    FILESUFFIX${BLU}=${RED}$FILESUFFIX ${DEF}"
    echo -e "    USER${BLU}=${RED}$USER ${DEF}"
    echo -e "    WEIGHTNAME${BLU}=${RED}$WEIGHTNAME ${DEF}"
    echo -e "    FILEBODY${BLU}=${RED}$FILEBODY ${DEF}"
    echo -e "    TOMOLIMS${BLU}=${RED}\"$TOMOLIMS\" ${DEF}"
    echo -e "    SCRIPTPATH${BLU}=${RED}$SCRIPTPATH ${DEF}"
    echo -e "    STORAGEPATH${BLU}=${RED}$STORAGEPATH ${DEF}"
    echo -e "    CONFIGPATH${BLU}=${RED}$CONFIGPATH ${DEF}"
    sleep .2
    echo -e ""
    echo -e "If you want to update these now then you ${RED} may kill the script now ${DEF} and"
    echo -e "edit the COSMOPIPE_MASTER_INSTALL.sh script variables (at the top of the file). Otherwise you " 
    echo -e "will need to edit and rerun the configure script after the MASTER_INSTALL is completed. " 
    sleep .2
    echo -en "${BLU}You have 10 sec to decide... ${DEF}"
    
    sleep 1 & _spinner 
    
    echo " OK!"
    sleep 1
    echo -e "${BLU}Starting Installation now. ${DEF}"
    sleep .5
    echo -e "${BLU}=======================================${DEF}"
  else 
    sleep 1 
    echo 
    echo -e "You are running without ${RED}VERBOSE${DEF} output."
    echo -e "${BLU}Starting Installation now, but will not prompt further.${DEF}"
    echo 
    sleep 1 
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
  echo RUNROOT PACKROOT USER DATE 
} 
#}}}

# Output data {{{ 
function _outputs { 
  #NONE
  echo 
} 
#}}}

#Additional Functions 

#Make waiting interesting with a spinner! {{{
function _spinner {
  _pid=$! # Process Id of the previous running command
  _spin='-\|/'
  _i=0
  while kill -0 $_pid 2>/dev/null 1>&2 
  do
    _i=$(( (_i+1) %4 ))
    printf "[${_spin:$_i:1}]\b\b\b"
    sleep .1
  done
}
#}}}

#Error for existing installation {{{
function _existing_install_error { 
  echo -e "   >${RED} ERROR: There is a previous pipeline installation in ${DEF}" 
  echo -e "   >${BLU} ${RUNROOT}/INSTALL ${DEF}" 
  echo -e "   >${RED} If you want to rerun the installation, then you must delete it!${DEF}" 
  echo -e "${BLU}=======================================${DEF}"
  trap : 0 
  exit 1 
} #}}}

