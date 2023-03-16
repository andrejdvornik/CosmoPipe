##
# 
# KiDS COSMOLOGY PIPELINE Configuration
# Written by A.H. Wright (2019-09-30) 
# Created by @USER@ (@DATE@)
#
##

##
# Variables and paths should not be editted here! 
# - Change variables in the variables.sh file
# - Change pipeline formats in the pipeline.sh file 
##

set -e 

#Source the Script Documentation Functions {{{
source @PACKROOT@/man/CosmoPipe.man.sh
source @PACKROOT@/man/${0//.sh/.man.sh} 
#}}}

#Get the option list {{{
OPTLIST=`_get_optlist @RUNROOT@/variables.sh`
#}}}

#Paths and variables for configuration {{{
source @RUNROOT@/variables.sh
#}}}

#Prompt {{{
_prompt ${VERBOSE}
#}}}

#Variable Check {{{
_varcheck $0
#}}}

#Remove any previous pipeline versions {{{
if [ -d ${RUNROOT}/${RUNTIME} ]
then 
  _message "   >${RED} Removing previous configuration ${DEF}" 
  rm -fr ${RUNROOT}/${RUNTIME}
  _message "${BLU} - Done! ${DEF}\n"
fi 
mkdir -p ${RUNROOT}/${RUNTIME}
#}}}

#Make and populate the runtime scripts directory {{{
_message "   >${RED} Copying Provided Data Products to Storage Path${DEF}" 
mkdir -p ${RUNROOT}/${STORAGEPATH}
rsync -autvz ${PACKROOT}/data/* ${RUNROOT}/${STORAGEPATH}/ > ${RUNROOT}/INSTALL/datatranfer.log 2>&1 
_message "${BLU} - Done! ${DEF}\n"
_message "   >${RED} Copying scripts & configs to Run directory${DEF}" 
rsync -autvz ${PACKROOT}/scripts/* ${RUNROOT}/${SCRIPTPATH}/ >> ${RUNROOT}/INSTALL/datatranfer.log 2>&1 
rsync -autvz ${PACKROOT}/config/* ${RUNROOT}/${CONFIGPATH}/ >> ${RUNROOT}/INSTALL/datatranfer.log 2>&1 
rsync -autvz ${PACKROOT}/man/* ${RUNROOT}/${MANUALPATH}/ >> ${RUNROOT}/INSTALL/datatranfer.log 2>&1 
_message "${BLU} - Done! ${DEF}\n"
# _message "   >${RED} Copying post processing scripts to Run directory${DEF}" 
# rsync -autvz ${RUNROOT}/INSTALL/post_process_mcmcs/make_all.py ${RUNROOT}/${SCRIPTPATH}/ \
#   >> ${RUNROOT}/INSTALL/datatranfer.log 2>&1 
# _message "${BLU} - Done! ${DEF}\n"
cd ${RUNROOT}
#}}}

##Make a copy of the CosmoFisherForecast Repository {{{
#mkdir -p ${RUNROOT}/${SCRIPTPATH}/CosmoFisherForecast
#cp -rf ${COSMOFISHER}/* ${RUNROOT}/${SCRIPTPATH}/CosmoFisherForecast/
##}}}

##Convert Survey area from arcmin to deg {{{
#SURVEYAREADEG="`awk -v s=${SURVEYAREA} 'BEGIN { printf "%.4f", s/3600.0 }'`"
##Add derived quantity to option list 
#OPTLIST=`echo $OPTLIST SURVEYAREADEG`
##}}}

#Update the runtime scripts with the relevant paths & variables {{{
_message "   >${RED} Modify Runtime Scripts ${DEF}" 
for OPT in $OPTLIST
do 
  ${P_SED_INPLACE} "s#\@${OPT}\@#${!OPT}#g" ${RUNROOT}/${SCRIPTPATH}/*.* ${RUNROOT}/${CONFIGPATH}/{.,*}/*.*
done 
_message "${BLU} - Done! ${DEF}\n"
#}}}

#Create the pipeline, & update the runtime scripts with the relevant paths & variables {{{
for pipe in ${PIPELINE}
do 
  _message "   >${RED} Constructing Pipeline ${pipe} ${DEF}" 
  bash ${RUNROOT}/${SCRIPTPATH}/construct_pipeline.sh ${RUNROOT}/pipeline.ini
  _message "${BLU} - Done! ${DEF}\n"
done 
#}}}

#Set the run_COSMOLOGY_PIPELINE.sh file to read and execute only
chmod a-w ${RUNROOT}/${PIPELINE}_pipeline.sh

_message "   >${RED} Finished! To run the Cosmology pipeline run: ${DEF}\n"
_message "   ${BLU} ${PIPELINE}_pipeline.sh ${DEF}\n"

trap : 0
