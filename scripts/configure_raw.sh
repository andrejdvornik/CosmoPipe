##
# 
# KiDS COSMOLOGY PIPELINE Configuration
# Written by A.H. Wright (2019-09-30) 
# Created by @USER@ (@DATE@)
#
##

#Set Stop-On-Error {{{
abort()
{
  echo -e "\033[0;31m - !FAILED!" >&2
  echo -e "\033[0;34m An error occured during the configuration \033[0m" >&2
  echo >&2
  exit 1
}
trap 'abort' 0
set -e 
#}}}

##
# If you need to edit any paths, do so here and rerun the configure script
##

#Paths and variables for configuration
#Designation for "all patches"
ALLPATCH=@ALLPATCH@
#Blind Character
BLIND=UNBLINDED #A B C UNBLINDED
#Blind identifier
BLINDING=${BLIND} #blind${BLIND} or ${BLIND}
#Path to pipeline config files 
CONFIGPATH=@CONFIGPATH@
#Date
DATE=@DATE@
#Prior values for the gaussian dz's (per tomo bin)
DZPRIORMU="@DZPRIORMU@"
DZPRIORSD="@DZPRIORSD@"
DZPRIORNSIG="@DZPRIORNSIG@"
#Shape mesurement variables 
E1VAR=bias_corrected_e1
E2VAR=bias_corrected_e2
#Patch catalogue suffix 
FILESUFFIX=@FILESUFFIX@
#Path to the CosmoFisherForecast repository
COSMOFISHER=@COSMOFISHER@ 
#Patch Subset Keyword
SHEARSUBSET=@SHEARSUBSET@ 
#Name of the likelihood function to use
LIKELIHOOD=@LIKELIHOOD@
#Name of the likelihood when in use (stops crosstalk between simulatneous runs)
COSMOPIPECFNAME=@COSMOPIPECFNAME@
#Nz file name 
NZFILEID=@NZFILEID@
#Nz file suffix
NZFILESUFFIX=@NZFILESUFFIX@
#Nz delta-z stepsize
NZSTEP=@NZSTEP@
#Survey Footprint Mask file
MASKFILE=@MASKFILE@
#List of m-bias values and errors 
MBIASVALUES="-0.0128 -0.0104 -0.0114 +0.0072 +0.0061"
MBIASERRORS="0.02 0.02 0.02 0.02 0.02"
#Path to Patchwise Catalogues
PATCHPATH=@PATCHPATH@
PATCHLIST=@PATCHLIST@
#Path to python binary folder
PYTHONBIN=@PYTHONBIN@
#Format of the recal_weight estimation grid 
RECALGRID=@RECALGRID@
#Root directory for pipeline scripts
PACKROOT=@PACKROOT@
#ID for various outputs 
RUNID=@RUNID@
#Root directory for running pipeline
RUNROOT=@RUNROOT@
#Directory for runtime scripts 
RUNTIME=@RUNTIME@
#Path for modified scripts
SCRIPTPATH=@SCRIPTPATH@
#Path for outputs
STORAGEPATH=@STORAGEPATH@
#Survey ID  
SURVEY=@SURVEY@
#Survey Area in arcmin
SURVEYAREA=@SURVEYAREA@
#Path to THELI LDAC tools
THELIPATH=@THELIPATH@
#Limits of the tomographic bins
TOMOLIMS=@TOMOLIMS@
#Username 
USER=@USER@
#Name of the lensing weight variable  
WEIGHTNAME=@WEIGHTNAME@
#Theta limits for covariance 
THETAMINCOV="@THETAMINCOV@"
THETAMAXCOV="@THETAMAXCOV@"
NTHETABINCOV="@NTHETABINCOV@"
#Xi plus/minus limits 
XIPLUSLIMS="@XIPLUSLIMS@"
XIMINUSLIMS="@XIMINUSLIMS@"
#Name of the lensing weight variable  
WEIGHTNAME=@WEIGHTNAME@

##
# Variables and paths should not be editted below here!
##

# Set up the tomographic bin limit vectors (for MCMC configuration) {{{
TOMOLIMSLOVEC=`echo $TOMOLIMS | awk '{$NF = ""; print $0}' | sed 's/ $//g' | sed 's/ /,/g'`
TOMOLIMSHIVEC=`echo $TOMOLIMS | awk '{$1  = ""; print $0}' | sed 's/^ //g' | sed 's/ /,/g'`
NTOMO=`echo $TOMOLIMS | awk '{print NF-1}'`
#}}}

#Construct the DZPRIOR python vectors (for modifying likelihood etc) {{{
DZPRIORMUVEC=${DZPRIORMU//  / } #Remove any multiple spaces
DZPRIORSDVEC=${DZPRIORSD//  / } #Remove any multiple spaces
DZPRIORMUVEC=${DZPRIORMUVEC// /,} #Convert spaces to commas
DZPRIORSDVEC=${DZPRIORSDVEC// /,} #Convert spaces to commas 
DZPRIORMUVEC=${DZPRIORMUVEC//,,/,} #Undo any double commas to be sure
DZPRIORSDVEC=${DZPRIORSDVEC//,,/,} #Undo any double commas to be sure
#}}}
 
#Remove any previous pipeline versions {{{
if [ -d ${RUNROOT}/${RUNTIME} ]
then 
  echo -en "   >\033[0;34m Removing previous configuration \033[0m" 
  rm -fr ${RUNROOT}/${RUNTIME}
  echo -e "\033[0;31m - Done! \033[0m" 
fi 
mkdir -p ${RUNROOT}/${RUNTIME}
#}}}

#Make and populate the runtime scripts directory {{{
echo -en "   >\033[0;34m Copying default KiDS Data Products to Storage Path\033[0m" 
mkdir -p ${RUNROOT}/${STORAGEPATH}
rsync -autvz ${PACKROOT}/data/* ${RUNROOT}/${STORAGEPATH}/ > ${RUNROOT}/INSTALL/datatranfer.log 2>&1 
echo -e "\033[0;31m - Done! \033[0m" 
echo -en "   >\033[0;34m Copying scripts & configs to Run directory\033[0m" 
rsync -autvz ${PACKROOT}/scripts/* ${RUNROOT}/${SCRIPTPATH}/ >> ${RUNROOT}/INSTALL/datatranfer.log 2>&1 
rsync -autvz ${PACKROOT}/config/* ${RUNROOT}/${CONFIGPATH}/ >> ${RUNROOT}/INSTALL/datatranfer.log 2>&1 
echo -e "\033[0;31m - Done! \033[0m" 
echo -en "   >\033[0;34m Copying post processing scripts to Run directory\033[0m" 
rsync -autvz ${RUNROOT}/INSTALL/post_process_mcmcs/make_all.py ${RUNROOT}/${SCRIPTPATH}/ \
  >> ${RUNROOT}/INSTALL/datatranfer.log 2>&1 
echo -e "\033[0;31m - Done! \033[0m" 
cd ${RUNROOT}

#}}}

#Subset the Shear Catalogues? {{{
if [ "${SHEARSUBSET}" != "NONE" ]
then 
  #Trim the Shear Catalogues to the desired subset {{{
  for PATCH in $PATCHLIST $ALLPATCH
  do 
    echo -n "Subsetting the sources in patch ${PATCH} by Column ${SHEARSUBSET} (Keeping ${SHEARSUBSET}!=0)"
    ldacfilter -i ${PATCHPATH}/${SURVEY}_${PATCH}_reweight_${RECALGRID}${FILESUFFIX}.cat \
             -o ${PATCHPATH}/${SURVEY}_${PATCH}_reweight_${RECALGRID}${FILESUFFIX}_${SHEARSUBSET}.cat \
    	       -t OBJECTS \
    	       -c "(${SHEARSUBSET}!=0);" \
             > ${PATCHPATH}/${SURVEY}_${PATCH}_reweight_${RECALGRID}${FILESUFFIX}_${SHEARSUBSET}.log 2>&1
    echo " - Done!"
  done 
  echo "Updating File Suffix ${FILESUFFIX} to ${FILESUFFIX}_${SHEARSUBSET}!!"
  FILESUFFIX=${FILESUFFIX}_${SHEARSUBSET}
  #}}}
fi 
#}}}

#Make a copy of the CosmoFisherForecast Repository {{{
mkdir -p ${RUNROOT}/${SCRIPTPATH}/CosmoFisherForecast
cp -rf ${COSMOFISHER}/* ${RUNROOT}/${SCRIPTPATH}/CosmoFisherForecast/
#}}}

#Update the runtime scripts with the relevant paths & variables {{{
echo -en "   >\033[0;34m Modify Runtime Scripts \033[0m" 
cp ${PACKROOT}/scripts/run_COSMOLOGY_PIPELINE_raw.sh ${RUNROOT}/run_COSMOLOGY_PIPELINE.sh
sed -i "s#\@ALLPATCH\@#${ALLPATCH}#g" ${RUNROOT}/${SCRIPTPATH}/*.* ${RUNROOT}/run_COSMOLOGY_PIPELINE.sh ${RUNROOT}/${CONFIGPATH}/{.,*}/*.*
sed -i "s#\@BLINDING\@#${BLINDING}#g" ${RUNROOT}/${SCRIPTPATH}/*.* ${RUNROOT}/run_COSMOLOGY_PIPELINE.sh ${RUNROOT}/${CONFIGPATH}/{.,*}/*.*
sed -i "s#\@BLIND\@#${BLIND}#g" ${RUNROOT}/${SCRIPTPATH}/*.* ${RUNROOT}/run_COSMOLOGY_PIPELINE.sh ${RUNROOT}/${CONFIGPATH}/{.,*}/*.*
sed -i "s#\@CONFIGPATH\@#${CONFIGPATH}#g" ${RUNROOT}/${SCRIPTPATH}/*.* ${RUNROOT}/run_COSMOLOGY_PIPELINE.sh ${RUNROOT}/${CONFIGPATH}/{.,*}/*.*
sed -i "s#\@DATE\@#`date +%Y-%m-%d`#g" ${RUNROOT}/${SCRIPTPATH}/*.* ${RUNROOT}/run_COSMOLOGY_PIPELINE.sh ${RUNROOT}/${CONFIGPATH}/{.,*}/*.*
sed -i "s#\@DZPRIORMU\@#${DZPRIORMU}#g" ${RUNROOT}/${SCRIPTPATH}/*.* ${RUNROOT}/run_COSMOLOGY_PIPELINE.sh ${RUNROOT}/${CONFIGPATH}/{.,*}/*.*
sed -i "s#\@DZPRIORSD\@#${DZPRIORSD}#g" ${RUNROOT}/${SCRIPTPATH}/*.* ${RUNROOT}/run_COSMOLOGY_PIPELINE.sh ${RUNROOT}/${CONFIGPATH}/{.,*}/*.*
sed -i "s#\@DZPRIORMUVEC\@#${DZPRIORMUVEC}#g" ${RUNROOT}/${SCRIPTPATH}/*.* ${RUNROOT}/run_COSMOLOGY_PIPELINE.sh ${RUNROOT}/${CONFIGPATH}/{.,*}/*.*
sed -i "s#\@DZPRIORSDVEC\@#${DZPRIORSDVEC}#g" ${RUNROOT}/${SCRIPTPATH}/*.* ${RUNROOT}/run_COSMOLOGY_PIPELINE.sh ${RUNROOT}/${CONFIGPATH}/{.,*}/*.*
sed -i "s#\@DZPRIORNSIG\@#${DZPRIORNSIG}#g" ${RUNROOT}/${SCRIPTPATH}/*.* ${RUNROOT}/run_COSMOLOGY_PIPELINE.sh ${RUNROOT}/${CONFIGPATH}/{.,*}/*.*
sed -i "s#\@E1VAR\@#${E1VAR}#g" ${RUNROOT}/${SCRIPTPATH}/*.* ${RUNROOT}/run_COSMOLOGY_PIPELINE.sh ${RUNROOT}/${CONFIGPATH}/{.,*}/*.*
sed -i "s#\@E2VAR\@#${E2VAR}#g" ${RUNROOT}/${SCRIPTPATH}/*.* ${RUNROOT}/run_COSMOLOGY_PIPELINE.sh ${RUNROOT}/${CONFIGPATH}/{.,*}/*.*
sed -i "s#\@FILESUFFIX\@#${FILESUFFIX}#g" ${RUNROOT}/${SCRIPTPATH}/*.* ${RUNROOT}/run_COSMOLOGY_PIPELINE.sh ${RUNROOT}/${CONFIGPATH}/{.,*}/*.*
sed -i "s#\@COSMOFISHER\@#${COSMOFISHER}#g" ${RUNROOT}/${SCRIPTPATH}/*.* ${RUNROOT}/run_COSMOLOGY_PIPELINE.sh ${RUNROOT}/${CONFIGPATH}/{.,*}/*.*
sed -i "s#\@LIKELIHOOD\@#${LIKELIHOOD}#g" ${RUNROOT}/${SCRIPTPATH}/*.* ${RUNROOT}/run_COSMOLOGY_PIPELINE.sh ${RUNROOT}/${CONFIGPATH}/{.,*}/*.*
sed -i "s#\@COSMOPIPECFNAME\@#${COSMOPIPECFNAME}#g" ${RUNROOT}/${SCRIPTPATH}/*.* ${RUNROOT}/run_COSMOLOGY_PIPELINE.sh ${RUNROOT}/${CONFIGPATH}/{.,*}/*.*
sed -i "s#\@NTOMO\@#${NTOMO}#g" ${RUNROOT}/${SCRIPTPATH}/*.* ${RUNROOT}/run_COSMOLOGY_PIPELINE.sh ${RUNROOT}/${CONFIGPATH}/{.,*}/*.*
sed -i "s#\@NZFILEID\@#${NZFILEID}#g" ${RUNROOT}/${SCRIPTPATH}/*.* ${RUNROOT}/run_COSMOLOGY_PIPELINE.sh ${RUNROOT}/${CONFIGPATH}/{.,*}/*.*
sed -i "s#\@NZFILESUFFIX\@#${NZFILESUFFIX}#g" ${RUNROOT}/${SCRIPTPATH}/*.* ${RUNROOT}/run_COSMOLOGY_PIPELINE.sh ${RUNROOT}/${CONFIGPATH}/{.,*}/*.*
sed -i "s#\@NZSTEP\@#${NZSTEP}#g" ${RUNROOT}/${SCRIPTPATH}/*.* ${RUNROOT}/run_COSMOLOGY_PIPELINE.sh ${RUNROOT}/${CONFIGPATH}/{.,*}/*.*
sed -i "s#\@MASKFILE\@#${MASKFILE}#g" ${RUNROOT}/${SCRIPTPATH}/*.*  ${RUNROOT}/run_COSMOLOGY_PIPELINE.sh  ${RUNROOT}/${CONFIGPATH}/{.,*}/*.*
sed -i "s#\@MBIASVALUES\@#${MBIASVALUES}#g" ${RUNROOT}/${SCRIPTPATH}/*.*  ${RUNROOT}/run_COSMOLOGY_PIPELINE.sh  ${RUNROOT}/${CONFIGPATH}/{.,*}/*.*
sed -i "s#\@MBIASERRORS\@#${MBIASERRORS}#g" ${RUNROOT}/${SCRIPTPATH}/*.*  ${RUNROOT}/run_COSMOLOGY_PIPELINE.sh  ${RUNROOT}/${CONFIGPATH}/{.,*}/*.*
sed -i "s#\@PATCHPATH\@#${PATCHPATH}#g" ${RUNROOT}/${SCRIPTPATH}/*.*  ${RUNROOT}/run_COSMOLOGY_PIPELINE.sh ${RUNROOT}/${CONFIGPATH}/{.,*}/*.*
sed -i "s#\@PATCHLIST\@#${PATCHLIST}#g" ${RUNROOT}/${SCRIPTPATH}/*.* ${RUNROOT}/run_COSMOLOGY_PIPELINE.sh ${RUNROOT}/${CONFIGPATH}/{.,*}/*.*
sed -i "s#\@PYTHONBIN\@#${PYTHONBIN}#g" ${RUNROOT}/${SCRIPTPATH}/*.* ${RUNROOT}/run_COSMOLOGY_PIPELINE.sh ${RUNROOT}/${CONFIGPATH}/{.,*}/*.*
sed -i "s#\@RECALGRID\@#${RECALGRID}#g" ${RUNROOT}/${SCRIPTPATH}/*.* ${RUNROOT}/run_COSMOLOGY_PIPELINE.sh ${RUNROOT}/${CONFIGPATH}/{.,*}/*.*
sed -i "s#\@RUNROOT\@#${RUNROOT}#g" ${RUNROOT}/${SCRIPTPATH}/*.* ${RUNROOT}/run_COSMOLOGY_PIPELINE.sh ${RUNROOT}/${CONFIGPATH}/{.,*}/*.*
sed -i "s#\@RUNID\@#${RUNID}#g" ${RUNROOT}/${SCRIPTPATH}/*.* ${RUNROOT}/run_COSMOLOGY_PIPELINE.sh ${RUNROOT}/${CONFIGPATH}/{.,*}/*.*
sed -i "s#\@SCRIPTPATH\@#${SCRIPTPATH}#g" ${RUNROOT}/${SCRIPTPATH}/*.* ${RUNROOT}/run_COSMOLOGY_PIPELINE.sh ${RUNROOT}/${CONFIGPATH}/{.,*}/*.*
sed -i "s#\@STORAGEPATH\@#${STORAGEPATH}#g" ${RUNROOT}/${SCRIPTPATH}/*.* ${RUNROOT}/run_COSMOLOGY_PIPELINE.sh ${RUNROOT}/${CONFIGPATH}/{.,*}/*.*
sed -i "s#\@SURVEY\@#${SURVEY}#g" ${RUNROOT}/${SCRIPTPATH}/*.* ${RUNROOT}/run_COSMOLOGY_PIPELINE.sh ${RUNROOT}/${CONFIGPATH}/{.,*}/*.*
sed -i "s#\@SURVEYAREA\@#${SURVEYAREA}#g" ${RUNROOT}/${SCRIPTPATH}/*.* ${RUNROOT}/run_COSMOLOGY_PIPELINE.sh ${RUNROOT}/${CONFIGPATH}/{.,*}/*.*
sed -i "s#\@THELIPATH\@#${THELIPATH}#g" ${RUNROOT}/${SCRIPTPATH}/*.* ${RUNROOT}/run_COSMOLOGY_PIPELINE.sh ${RUNROOT}/${CONFIGPATH}/{.,*}/*.*
sed -i "s#\@TOMOLIMS\@#${TOMOLIMS}#g" ${RUNROOT}/${SCRIPTPATH}/*.* ${RUNROOT}/run_COSMOLOGY_PIPELINE.sh ${RUNROOT}/${CONFIGPATH}/{.,*}/*.*
sed -i "s#\@TOMOLIMSLOVEC\@#${TOMOLIMSLOVEC}#g" ${RUNROOT}/${SCRIPTPATH}/*.* ${RUNROOT}/run_COSMOLOGY_PIPELINE.sh ${RUNROOT}/${CONFIGPATH}/{.,*}/*.*
sed -i "s#\@TOMOLIMSHIVEC\@#${TOMOLIMSHIVEC}#g" ${RUNROOT}/${SCRIPTPATH}/*.* ${RUNROOT}/run_COSMOLOGY_PIPELINE.sh ${RUNROOT}/${CONFIGPATH}/{.,*}/*.*
sed -i "s#\@USER\@#${USER}#g" ${RUNROOT}/${SCRIPTPATH}/*.* ${RUNROOT}/run_COSMOLOGY_PIPELINE.sh ${RUNROOT}/${CONFIGPATH}/{.,*}/*.*
sed -i "s#\@WEIGHTNAME\@#${WEIGHTNAME}#g" ${RUNROOT}/${SCRIPTPATH}/*.* ${RUNROOT}/run_COSMOLOGY_PIPELINE.sh  ${RUNROOT}/${CONFIGPATH}/{.,*}/*.*
sed -i "s#\@THETAMINCOV\@#${THETAMINCOV}#g" ${RUNROOT}/${SCRIPTPATH}/*.* ${RUNROOT}/run_COSMOLOGY_PIPELINE.sh  ${RUNROOT}/${CONFIGPATH}/{.,*}/*.*
sed -i "s#\@THETAMAXCOV\@#${THETAMAXCOV}#g" ${RUNROOT}/${SCRIPTPATH}/*.* ${RUNROOT}/run_COSMOLOGY_PIPELINE.sh  ${RUNROOT}/${CONFIGPATH}/{.,*}/*.*
sed -i "s#\@NTHETABINCOV\@#${NTHETABINCOV}#g" ${RUNROOT}/${SCRIPTPATH}/*.* ${RUNROOT}/run_COSMOLOGY_PIPELINE.sh  ${RUNROOT}/${CONFIGPATH}/{.,*}/*.*
sed -i "s#\@XIPLUSLIMS\@#${XIPLUSLIMS}#g" ${RUNROOT}/${SCRIPTPATH}/*.* ${RUNROOT}/run_COSMOLOGY_PIPELINE.sh  ${RUNROOT}/${CONFIGPATH}/{.,*}/*.*
sed -i "s#\@XIMINUSLIMS\@#${XIMINUSLIMS}#g" ${RUNROOT}/${SCRIPTPATH}/*.* ${RUNROOT}/run_COSMOLOGY_PIPELINE.sh  ${RUNROOT}/${CONFIGPATH}/{.,*}/*.*
echo -e "\033[0;31m - Done! \033[0m" 
#}}}

#Set the run_COSMOLOGY_PIPELINE.sh file to read and execute only
chmod a-w ${RUNROOT}/run_COSMOLOGY_PIPELINE.sh

echo -e "   >\033[0;34m Finished! To run the Cosmology pipeline run: \033[0m" 
echo -e "   \033[0;31mrun_COSMOLOGY_PIPELINE.sh \033[0m" 

trap : 0
