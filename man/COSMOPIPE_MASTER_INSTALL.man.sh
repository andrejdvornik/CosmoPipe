#
# Documentation & Housekeeping functions
#

#Starting Prompt {{{
function _prompt { 
  VERBOSE=1 _message "${BLU}=====================================================${DEF}\n"
  VERBOSE=1 _message "${BLU}== ${RED} Cosmology Pipeline Installation Master Script ${BLU} ==${DEF}\n"
  VERBOSE=1 _message "${BLU}=====================================================${DEF}\n"
  sleep 1
  VERBOSE=1 _message "\nWelcome to the installation script, ${RED}`whoami`${DEF}!\n\n" 
  if [ "$1" != "0" ] 
  then 
    sleep .2
    _message "I will be running with many ${RED} pre-defined ${DEF} variables! A sample are below:\n"
    _message "(These can be edited now in the MASTER_INSTALL ${RED} or ${DEF} later in your configure.sh)\n"
    sleep .2
    _message "    RUNROOT${BLU}=${RED}$RUNROOT ${DEF}\n"
    _message "    SURVEY${BLU}=${RED}$SURVEY ${DEF}\n"
    _message "    SURVEYAREA${BLU}=${RED}$SURVEYAREA ${DEF}\n"
    _message "    PATCHPATH${BLU}=${RED}$PATCHPATH ${DEF}\n"
    _message "    PATCHLIST${BLU}=${RED}$PATCHLIST ${DEF}\n"
    _message "    ALLPATCH${BLU}=${RED}$ALLPATCH ${DEF}\n"
    _message "    FILESUFFIX${BLU}=${RED}$FILESUFFIX ${DEF}\n"
    _message "    USER${BLU}=${RED}$USER ${DEF}\n"
    _message "    WEIGHTNAME${BLU}=${RED}$WEIGHTNAME ${DEF}\n"
    _message "    FILEBODY${BLU}=${RED}$FILEBODY ${DEF}\n"
    _message "    TOMOLIMS${BLU}=${RED}\"$TOMOLIMS\" ${DEF}\n"
    _message "    SCRIPTPATH${BLU}=${RED}$SCRIPTPATH ${DEF}\n"
    _message "    STORAGEPATH${BLU}=${RED}$STORAGEPATH ${DEF}\n"
    _message "    CONFIGPATH${BLU}=${RED}$CONFIGPATH ${DEF}\n"
    sleep .2
    _message "\n"
    _message "If you want to update these now then you ${RED} may kill the script now ${DEF} and\n"
    _message "edit the COSMOPIPE_MASTER_INSTALL.sh script variables (at the top of the file). Otherwise you \n" 
    _message "will need to edit and rerun the configure script after the MASTER_INSTALL is completed. \n" 
    sleep .2
    _message "${BLU}You have 10 sec to decide... ${DEF}"
    
    sleep 1 & _spinner 
    
    echo " OK!"
    sleep 1
    _message "${BLU}Starting Installation now. ${DEF}\n"
    sleep .5
    _message "${BLU}=======================================${DEF}\n"
  else 
    sleep 1 
    VERBOSE=1 _message "You are running without ${RED}VERBOSE${DEF} output.\n"
    VERBOSE=1 _message "${BLU}Starting Installation now, but will not prompt further.${DEF}\n"
    VERBOSE=1 _message "${BLU}=======================================${DEF}\n"
    sleep 1 
  fi 
}
#}}}

# Abort Message {{{
_abort()
{
  _message "${RED} - !FAILED!\n"
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
  VERBOSE=1 _message "   >${RED} ERROR: There is a previous pipeline installation in ${DEF}\n" 
  VERBOSE=1 _message "   >${BLU} ${RUNROOT}/INSTALL ${DEF}\n" 
  VERBOSE=1 _message "   >${RED} If you want to rerun the installation, then you must delete it!${DEF}\n" 
  VERBOSE=1 _message "${BLU}=======================================${DEF}\n"
  trap : 0 
  exit 1 
} #}}}

