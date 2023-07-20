#
# Update configure.sh for Cosmology Pipeline 
# Written by A.H.Wright (2023-03-10)
#

set -e 

#Set the default variables to determine the installation paths  {{{
source variables.sh 
#}}}

#Source the Script Documentation Functions {{{
source ${PACKROOT}/man/CosmoPipe.man.sh
source ${PACKROOT}/man/configure.man.sh 
#}}}

#Full List of available options {{{ 
OPTLIST=`_get_optlist variables.sh`
#Add INSTALL-only variables 
OPTLIST=`echo $OPTLIST NOCONFIG`
#}}}

#Prompt {{{
_prompt ${VERBOSE}
#}}}

#Variable Check {{{
_varcheck $0
#}}}

cd ${RUNROOT}

cp ${PACKROOT}/scripts/configure_raw.sh configure.sh 

#Update the Configure script for this run {{{
_message "   >${RED} Update the configure script ${DEF}"
MACHINE=`uname`
THELIPATH=`echo ${RUNROOT}/INSTALL/theli-1.6.1/bin/${MACHINE}*`
for OPT in $OPTLIST
do 
  ${P_SED_INPLACE} "s#\\@${OPT}\\@#${!OPT}#g" ${RUNROOT}/configure.sh ${RUNROOT}/variables.sh
done 
_message "${BLU} - Done! ${DEF}\n"
#}}}

#Closing Prompt {{{
_message "${BLU}=======================================${DEF}\n"
#Finished! 
trap : 0
_message "${BLU}=======================================${DEF}\n"
_message "${BLU}==${RED}  Configure file update Complete!  ${BLU}==${DEF}\n"
_message "${BLU}=======================================${DEF}\n"
#}}}

