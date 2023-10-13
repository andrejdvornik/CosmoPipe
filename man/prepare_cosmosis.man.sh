#
# prepare_cosmosis.sh Documentation & Housekeeping functions
#

#Starting Prompt {{{
function _prompt { 
  #Check if we do want verbose output
  if [ "$1" != "0" ] 
  then
    _message "@BLU@========================================@DEF@\n"
    _message "@BLU@== @RED@ Running prepare_cosmosis.sh Mode @BLU@ ==@DEF@\n"
    _message "@BLU@========================================@DEF@\n"
  fi 
}
#}}}

#Mode description {{{
function _description { 
  echo "#"
  echo '# Prepare the n_effective and sigma_e input files '
  echo '# for CosmoSIS'
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
  #$0 is the script that was running when this error occurred
  _message "@BLU@ An error occured while running:\n@DEF@$0.\n" >&2
  _message "@BLU@ Check the logging file for this step in:\n" >&2
  _message "@DEF@@RUNROOT@/@LOGPATH@/\n" >&2
  exit 1
}
trap '_abort' 0
set -e 
#}}}

# Input variables {{{ 
function _inp_var { 
  #Variable inputs (leave blank if none)
  echo ALLPATCH BLU BV:BOLTZMAN BV:PRIOR_ABARY BV:PRIOR_AIA BV:PRIOR_H0 BV:PRIOR_LOGTAGN BV:PRIOR_MNU BV:PRIOR_NS BV:PRIOR_OMBH2 BV:PRIOR_OMCH2 BV:PRIOR_OMEGAK BV:PRIOR_S8INPUT BV:PRIOR_W BV:PRIOR_WA BV:TOMOLIMS DATABLOCK DEF PATCHLIST RED RUNROOT STORAGEPATH SURVEY
} 
#}}}

# Input data {{{ 
function _inp_data { 
  #Data inputs (leave blank if none)
  echo ALLHEAD nz nzbias_uncorr
} 
#}}}

# Output data {{{ 
function _outputs { 
  #Data outputs (leave blank if none)
  outlist=''
  for patch in @PATCHLIST@ @ALLPATCH@ @ALLPATCH@comb
  do 
    outlist="${outlist} cosmosis_neff_${patch} cosmosis_sigmae_${patch} cosmosis_xipm_${patch}"
  done 
  echo ${outlist} cosmosis_inputs
} 
#}}}

# Execution command {{{ 
function _runcommand { 
  #Command for running the script 
  echo bash @RUNROOT@/@SCRIPTPATH@/prepare_cosmosis.sh
} 
#}}}

# Unset Function command {{{ 
function _unset_functions { 
  #Remove these functions from the environment
  unset -f _prompt _description _inp_data _inp_var _abort _outputs _runcommand _unset_functions
} 
#}}}

#Additional Functions 

