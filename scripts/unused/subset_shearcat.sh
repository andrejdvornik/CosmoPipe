
#Subset the Shear Catalogues? {{{
if [ "${SHEARSUBSET}" != "NONE" ]
then 
  #Trim the Shear Catalogues to the desired subset {{{
  for PATCH in $PATCHLIST $ALLPATCH
  do 
    echo -n "Subsetting the sources in patch ${PATCH} by Column ${SHEARSUBSET} (Keeping ${SHEARSUBSET}!=0)"
    echo ""
    list=`${THELIPATH}/ldacdesc -i ${PATCHPATH}/${SURVEY}_${PATCH}_${FILEBODY}${FILESUFFIX}.cat -t OBJECTS | 
          grep "Key name" | awk -F. '{print $NF}' | 
          grep "_WORLD\|_IMAGE\|MAG_GAAP_\|MAG_LIM_\|BPZ_\|SeqNr\|MAGERR_\|FLUX_\|FLUXERR_\|ID" > /dev/null 2>&1`
    ${THELIPATH}/ldacdelkey -i ${PATCHPATH}/${SURVEY}_${PATCH}_${FILEBODY}${FILESUFFIX}.cat\
             -k ${list} -o ${PATCHPATH}/${SURVEY}_${PATCH}_${FILEBODY}${FILESUFFIX}_${SHEARSUBSET}_temp.cat \
             > ${PATCHPATH}/${SURVEY}_${PATCH}_${FILEBODY}${FILESUFFIX}_${SHEARSUBSET}.log 2>&1
    ${PYTHON3BIN}/python3 ${RUNROOT}/${SCRIPTPATH}/ldacfilter.py \
             -i ${PATCHPATH}/${SURVEY}_${PATCH}_${FILEBODY}${FILESUFFIX}_${SHEARSUBSET}_temp.cat \
             -o ${PATCHPATH}/${SURVEY}_${PATCH}_${FILEBODY}${FILESUFFIX}_${SHEARSUBSET}.cat \
    	       -t OBJECTS \
    	       -c "(${SHEARSUBSET}!=0);" \
             >> ${PATCHPATH}/${SURVEY}_${PATCH}_${FILEBODY}${FILESUFFIX}_${SHEARSUBSET}.log 2>&1
    rm ${PATCHPATH}/${SURVEY}_${PATCH}_${FILEBODY}${FILESUFFIX}_${SHEARSUBSET}_temp.cat \
             >> ${PATCHPATH}/${SURVEY}_${PATCH}_${FILEBODY}${FILESUFFIX}_${SHEARSUBSET}.log 2>&1
    echo " - Done!"
  done 
  echo "Updating File Suffix ${FILESUFFIX} to ${FILESUFFIX}_${SHEARSUBSET}!!"
  FILESUFFIX=${FILESUFFIX}_${SHEARSUBSET}
  #}}}
fi 
#}}}

