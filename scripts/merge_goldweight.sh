#=========================================
#
# File Name : merge_goldweight.sh
# Created By : awright
# Creation Date : 21-09-2023
# Last Modified : Wed 07 Feb 2024 12:48:50 AM CET
#
#=========================================

#Construct and merge the gold weights for the reference sample catalogues {{{
#For each catalogue in the output folder of compute_nz_weights {{{
inref="@DB:som_weight_reference@"
incal="@DB:som_weight_training@"
mainlist_all="@DB:som_weight_refr_cats@"
mainlist_all_cal="@DB:som_weight_calib_cats@"
nref=`echo ${inref} | awk '{print NF}'`
ncal=`echo ${incal} | awk '{print NF}'`
nrefout=`echo ${mainlist_all} | awk '{print NF}'`
outlist=""

#Reorder the reference, calibration, and mainlist lists to be in tomographic ordering {{{
NTOMO=`echo @BV:TOMOLIMS@ | awk '{print NF-1}'`
inref_ord=''
incal_ord=''
inmain_ord=''
inmain_ord_cal=''
for i in `seq -w $NTOMO`
do
  #Define the Z_B limits from the TOMOLIMS {{{
  ZB_lo=`echo @BV:TOMOLIMS@ | awk -v n=$i '{print $n}'`
  ZB_hi=`echo @BV:TOMOLIMS@ | awk -v n=$i '{print $(n+1)}'`
  #}}}
  #Define the tomographic bin string {{{
  ZB_lo_str=`echo $ZB_lo | sed 's/\./p/g'`
  ZB_hi_str=`echo $ZB_hi | sed 's/\./p/g'`
  appendstr="_ZB${ZB_lo_str}t${ZB_hi_str}"
  #Select the files that have this string 
  tomo_ref_files=`echo ${inref} | sed 's/ /\n/g' | grep ${appendstr} | awk '{printf $0 " "}' || echo `
  tomo_train_files=`echo ${incal} | sed 's/ /\n/g' | grep ${appendstr} | awk '{printf $0 " "}' || echo `
  tomo_main_files=`echo ${mainlist_all} | sed 's/ /\n/g' | grep ${appendstr} | awk '{printf $0 " "}' || echo `
  tomo_main_files_cal=`echo ${mainlist_all_cal} | sed 's/ /\n/g' | grep ${appendstr} | awk '{printf $0 " "}' || echo `
  #append these lists to the new file lists 
  inref_ord="${inref_ord} ${tomo_ref_files}"
  incal_ord="${incal_ord} ${tomo_train_files}"
  inmain_ord="${inmain_ord} ${tomo_main_files}"
  inmain_ord_cal="${inmain_ord_cal} ${tomo_main_files_cal}"
done 

#Check if we replicated the reference catalogues, or used them as is {{{
if [ ${nref} -eq ${nrefout} ]
then 
  inputlist=""
  for input in ${inref_ord} 
  do
    #Remove the extension 
    ext=${input##*.}
    file=${input//.${ext}/}
    #Remove the last number (this is the replication of the N goldweight SOMs)
    base=${file%_*}.${ext}
    #Check if base is in the inputlist 
    nbase=0
    for out in ${inputlist}
    do 
      if [ "${base}" == "${out}" ]
      then 
        nbase=$((nbase+1))
      fi 
    done 
    if [ $nbase -gt 1 ]
    then 
      _message "@RED@ - ERROR\nSomething wrong in the creation of the input reference filelist@DEF@\n"
      exit 1 
    elif [ ${nbase} -eq 0 ]
    then 
      inputlist="${inputlist} ${base}"
    fi
  done 
else
  #We used the SOM_DIR internal replication: base list is the raw reference list
  inputlist="${inref_ord}"
fi 
#}}}

#Notify in logfile {{{
echo "input list is:"
for input in ${inputlist}
do
  echo ${input}
done
#}}}

#Save the reference input list, it is needed for the calibration catalogues (which inherit the reference name)
ref_inputlist="${inputlist}"
#Use the reference catalogue main list for the first section
mainlist_all="${inmain_ord}" 

#Loop over inputlist files 
for input in ${ref_inputlist}
do
  #Construct the output name {{{
  outname=${input##*/}
  #Outname extension 
  outext=${outname##*.}
  outname=${outname//.${outext}/_goldwt.${outext}}
  #}}}
  #Get the main catalogue names for this file {{{
  maincat=${input##*/}
  mainbase=${maincat%.*}
  #mainbase=${mainbase%%_refr_DIRsom*}
  maincat=`echo ${mainlist_all} | sed 's/ /\n/g' | grep ${mainbase} || echo` 
  if [ "${maincat}" == "" ] 
  then 
    _message "@BLU@Skipping @DEF@${mainbase}@BLU@ - no match in reference catalogues\n"
    continue
  fi 
  nmain=`echo ${mainlist_all} | sed 's/ /\n/g' | grep -c ${mainbase} || echo` 
  if [ "${nmain}" == "" ] || [ ${nmain} -lt 2 ]
  then 
    _message "@RED@ ERROR!\n"
    _message "@RED@There are insufficient catalogues to create goldweight?!@DEF@\n"
    exit 1
  fi 
  #}}}
  #If needed, make the gold catalogue folder {{{
  if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/som_weight_refr_gold/ ]
  then 
    mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/som_weight_refr_gold
  fi 
  outfile=@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/som_weight_refr_gold/${outname}
  #}}}
  #Check that input and columns are different {{{
  if [ "${input}" == "${outfile}" ] 
  then 
    _message "@RED@ ERROR!\n"
    _message "@RED@Input and Output catalogue names are the same.\n"
    _message "@RED@Unable to proceed with LDAC joinkey\n@DEF@"
    exit 1
  fi 
  #}}}
  #Add file paths to goldclass catalogues {{{
  mainlist=''
  for main in ${maincat} 
  do 
    mainlist="${mainlist} ${main}"
  done 
  #}}}
  #Notify {{{ 
  _message " > @BLU@Working on Catalogue @DEF@${outname} {\n"
  _message "   -> @BLU@Constructing Gold Weight from ${nmain} files@DEF@"
  #}}}
  #Compute and Merge the Gold weights {{{
  echo "mainlist: ${mainlist}"
  @P_RSCRIPT@ @RUNROOT@/@SCRIPTPATH@/make_goldweight.R \
    -p ${mainlist} \
    -o ${outfile} \
    -w SOMweight 2>&1 
  _message " -@RED@ Done! (`date +'%a %H:%M'`)@DEF@\n"
  #}}}
  _message "   -> @BLU@Removing zero-weight sources from base catalogue@DEF@"
  #Check if the "input" catalogue exists, or if we need to use the first datahead replicant {{{
  if [ ! -f ${input} ]
  then 
    #There is no 'input', use the first replicant 
    #Assumes the replication naming structure to avoid mismatches!
    inpext=${input##*.}
    input=${input//.${inpext}/_1.${inpext}}
    #Check again if the "input" catalogue exists, otherwise error {{{
    if [ ! -f ${input} ]
    then 
      echo ${input}
      _message "@RED@ - ERROR! Cannot determine input reference file name?!@DEF@\n"
      exit 1 
    fi 
  fi 
  #}}}
  #}}}
  #Remove zero weight sources from input catalogue {{{
  @PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/ldacfilter.py \
           -i ${input} \
  	       -o ${input}_tmp \
  	       -t OBJECTS \
  	       -c "(@BV:WEIGHTNAME@>0);" 2>&1 
  _message " -@RED@ Done! (`date +'%a %H:%M'`)@DEF@\n"
  #}}}
  #Merge the goldweight column {{{
  _message "   -> @BLU@Merging goldweight column @DEF@"
  #Check if input file lengths are ok {{{
  links="FALSE"
  for file in ${input} ${outfile}
  do 
    if [ ${#file} -gt 250 ] 
    then 
      links="TRUE"
    fi 
  done 

  if [ "${links}" == "TRUE" ] 
  then
    #Remove existing infile links 
    if [ -e infile.lnk ] || [ -h infile.lnk ]
    then 
      rm infile.lnk
    fi 
    #Remove existing outfile links 
    if [ -e outfile.lnk ] || [ -h outfile.lnk ]
    then 
      rm outfile.lnk
    fi
    #Create input link
    originp=${input}
    ln -s ${input}_tmp infile.lnk_tmp
    input="infile.lnk"
    #Create outfile links 
    ln -s ${outfile} outfile.lnk
    origout=${outfile}
    outfile=outfile.lnk
  fi 
  #}}}
  @RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacjoinkey \
    -i ${input}_tmp \
    -p ${outfile} \
    -o ${outfile}_tmp \
    -k SOMGoldWeight -t OBJECTS 2>&1
  _message " -@RED@ Done! (`date +'%a %H:%M'`)@DEF@\n"
  #Undo linking {{{
  if [ "${links}" == "TRUE" ] 
  then 
    #Remove old links {{{
    rm ${input}_tmp ${outfile}
    mv ${outfile}_tmp ${origout}_tmp 
    input=${originp}
    outfile=${origout}
    #}}}
  fi 
  #}}}
  #Delete the temporary input file 
  rm -f ${input}_tmp 
  #}}}
  #Rename the original weight column {{{
  _message "   -> @BLU@Changing original @BV:WEIGHTNAME@ column to @BV:WEIGHTNAME@_nogoldwt@DEF@"
  #Check if input file lengths are ok {{{
  links="FALSE"
  for file in ${outfile}
  do 
    if [ ${#file} -gt 250 ] 
    then 
      links="TRUE"
    fi 
  done 
  if [ "${links}" == "TRUE" ] 
  then
    #Remove existing outfile links 
    if [ -e outfile.lnk ] || [ -h outfile.lnk ]
    then 
      rm outfile.lnk
    fi
    #Create outfile links 
    ln -s ${outfile}_tmp outfile.lnk_tmp
    origout=${outfile}
    outfile=outfile.lnk
  fi 
  #}}}
  @RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacrenkey \
    -i ${outfile}_tmp \
    -o ${outfile} \
    -k @BV:WEIGHTNAME@ @BV:WEIGHTNAME@_nogoldwt 2>&1
  #Undo linking {{{
  if [ "${links}" == "TRUE" ] 
  then 
    #Remove old links {{{
    rm ${outfile}_tmp
    mv ${outfile} ${origout} 
    outfile=${origout}
    #}}}
  fi 
  #}}}
  _message " -@RED@ Done! (`date +'%a %H:%M'`)@DEF@\n"
  #remove the temporary output file 
  rm ${outfile}_tmp 
  #}}}
  #Incorporate the goldweight column into the shape weight {{{
  _message "   -> @BLU@Incorporating goldweight into @BV:WEIGHTNAME@ column@DEF@"
  #Check if input file lengths are ok {{{
  links="FALSE"
  for file in ${outfile}
  do 
    if [ ${#file} -gt 250 ] 
    then 
      links="TRUE"
    fi 
  done 
  if [ "${links}" == "TRUE" ] 
  then
    #Remove existing outfile links 
    if [ -e outfile.lnk ] || [ -h outfile.lnk ]
    then 
      rm outfile.lnk
    fi
    #Create outfile links 
    ln -s ${outfile} outfile.lnk
    origout=${outfile}
    outfile=outfile.lnk
  fi 
  #}}}
  @RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldaccalc \
    -i ${outfile} \
    -o ${outfile}_tmp \
    -t OBJECTS \
    -c "SOMGoldWeight*@BV:WEIGHTNAME@_nogoldwt;" -n "@BV:WEIGHTNAME@" "Shape measurement weight including gold weight" -k FLOAT 2>&1
  #Undo linking {{{
  if [ "${links}" == "TRUE" ] 
  then 
    #Remove old links {{{
    rm ${outfile}
    mv ${outfile}_tmp ${origout}_tmp
    outfile=${origout}
    #}}}
  fi 
  #}}}
  _message " -@RED@ Done! (`date +'%a %H:%M'`)@DEF@\n"
  #}}}
  #Convert the SOMGoldWeight into a binary Goldclass {{{
  _message "   -> @BLU@Constructing binary goldclass@DEF@"
  #Check if input file lengths are ok {{{
  links="FALSE"
  for file in ${outfile}
  do 
    if [ ${#file} -gt 250 ] 
    then 
      links="TRUE"
    fi 
  done 
  if [ "${links}" == "TRUE" ] 
  then
    #Remove existing outfile links 
    if [ -e outfile.lnk ] || [ -h outfile.lnk ]
    then 
      rm outfile.lnk
    fi
    #Create outfile links 
    ln -s ${outfile}_tmp outfile.lnk_tmp
    origout=${outfile}
    outfile=outfile.lnk
  fi 
  #}}}
  @RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldaccalc \
    -i ${outfile}_tmp \
    -o ${outfile}     \
    -t OBJECTS \
    -c "1-SOMGoldWeight/(SOMGoldWeight+0.000000000000001);" -n "SOMnonGold" "Inverse selection of Binary GoldWeight" -k SHORT 2>&1
  #Undo linking {{{
  if [ "${links}" == "TRUE" ] 
  then 
    #Remove old links {{{
    rm ${outfile}_tmp
    mv ${outfile} ${origout}
    outfile=${origout}
    #}}}
  fi 
  #}}}
  #Check if input file lengths are ok {{{
  links="FALSE"
  for file in ${outfile}
  do 
    if [ ${#file} -gt 250 ] 
    then 
      links="TRUE"
    fi 
  done 
  if [ "${links}" == "TRUE" ] 
  then
    #Remove existing outfile links 
    if [ -e outfile.lnk ] || [ -h outfile.lnk ]
    then 
      rm outfile.lnk
    fi
    #Create outfile links 
    ln -s ${outfile} outfile.lnk
    origout=${outfile}
    outfile=outfile.lnk
  fi 
  #}}}
  @RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldaccalc \
    -i ${outfile} \
    -o ${outfile}_tmp     \
    -t OBJECTS \
    -c "1-SOMnonGold;" -n "SOMweight" "Binary GoldWeight (for use with gold-weighted @BV:WEIGHTNAME@)" -k SHORT 2>&1
  _message " -@RED@ Done! (`date +'%a %H:%M'`)@DEF@\n"
  #Undo linking {{{
  if [ "${links}" == "TRUE" ] 
  then 
    #Remove old links {{{
    rm ${outfile}
    mv ${outfile}_tmp ${origout}_tmp
    outfile=${origout}
    #}}}
  fi 
  #}}}
  #Delete the temporary output file
  mv ${outfile}_tmp ${outfile}
  #}}}
  #Save the output file to the list {{{
  outlist="$outlist $outname"
  #}}}
  #Notify {{{
  _message " }\n"
  #}}}
done 
#}}}

#Add the new file to the datablock {{{
if [ "${outlist}" != "" ]
then 
  _write_datablock som_weight_refr_gold "`echo ${outlist}`"
fi 
#}}}

#}}}

#Construct and merge the gold weights for the calibration sample catalogues {{{
#For each catalogue in the output folder of compute_nz_weights {{{
mainlist_all="${inmain_ord_cal}"
ncal=`echo ${incal_ord} | awk '{print NF}'`
ncalout=`echo ${mainlist_all} | awk '{print NF}'`
outlist=""

#Check if we replicated the calibration catalogues, or used them as is {{{
if [ ${ncal} -eq ${ncalout} ]
then 
  inputlist=""
  for input in ${incal_ord}
  do
    #Remove the extension 
    ext=${input##*.}
    file=${input//.${ext}/}
    #Remove the last number (this is the replication of the N goldweight SOMs)
    base=${file%_*}.${ext}
    #Check if base is in the inputlist 
    nbase=0
    for out in ${inputlist}
    do 
      if [ "${base}" == "${out}" ]
      then 
        nbase=$((nbase+1))
      fi 
    done 
    if [ $nbase -gt 1 ]
    then 
      _message "@RED - ERROR\nSomething wrong in the creation of the input calibration filelist@DEF@\n"
      exit 1 
    elif [ ${nbase} -eq 0 ]
    then 
      inputlist="${inputlist} ${base}"
    fi
  done 
else
  #We used the SOM_DIR internal replication: base list is the raw calibration list
  inputlist="${incal_ord}"
fi 
#}}}

#Notify in logfile {{{
echo "input list is:"
for input in ${inputlist}
do
  echo ${input}
done
#}}}

#Loop over inputlist files and construct output file names
outlist=''
for input in ${inputlist}
do
  #Construct the output name {{{
  outname=${input##*/}
  #Outname extension
  outext=${outname##*.}
  outname=${outname//.${outext}/_goldwt.${outext}}
  outlist="${outlist} ${outname}"
  #}}}
done
 
#Loop over inputlist files 
count=0
for input in ${ref_inputlist}
do
  count=$((count+1))
  #Get the main catalogue names for this file {{{
  maincat=${input##*/}
  mainbase=${maincat%.*}
  #mainbase=${mainbase%%_DIRsom*}
  maincat=`echo ${mainlist_all} | sed 's/ /\n/g' | grep ${mainbase} || echo` 
  if [ "${maincat}" == "" ] 
  then 
    _message "@BLU@Skipping @DEF@${mainbase}@BLU@ - no match in training catalogues\n"
    continue
  fi 
  nmain=`echo ${mainlist_all} | sed 's/ /\n/g' | grep -c ${mainbase} || echo` 
  if [ "${nmain}" == "" ] || [ ${nmain} -lt 2 ]
  then 
    _message "@RED@ ERROR!\n"
    _message "@RED@There are insufficient catalogues to create goldweight?!@DEF@\n"
    exit 1
  fi 
  #}}}
  #If needed, make the gold catalogue folder {{{
  if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/som_weight_calib_gold/ ]
  then 
    mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/som_weight_calib_gold
  fi 
  outname=`echo ${outlist} | awk -v n=$count '{print $n}'`
  outfile=@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/som_weight_calib_gold/${outname}
  #}}}
  #Check that input and columns are different {{{
  if [ "${input}" == "${outfile}" ] 
  then 
    _message "@RED@ ERROR!\n"
    _message "@RED@Input and Output catalogue names are the same.\n"
    _message "@RED@Unable to proceed with LDAC joinkey\n@DEF@"
    exit 1
  fi 
  #}}}
  #Add file paths to goldclass catalogues {{{
  mainlist=''
  for main in ${maincat} 
  do 
    mainlist="${mainlist} ${main}"
  done 
  #}}}
  #Notify {{{ 
  _message " > @BLU@Working on Catalogue @DEF@${outname} {\n"
  _message "   -> @BLU@Constructing Gold Weight from ${nmain} files@DEF@"
  #}}}
  #Compute and Merge the Gold weights {{{
  echo "mainlist: ${mainlist}"
  @P_RSCRIPT@ @RUNROOT@/@SCRIPTPATH@/make_goldweight.R \
    -p ${mainlist} \
    -o ${outfile} \
    -w SOMweight 2>&1 
  _message " -@RED@ Done! (`date +'%a %H:%M'`)@DEF@\n"
  #}}}
  #Base catalogue for this file is the nth calibration input catalogue:
  cal_input=`echo ${inputlist} | awk -v n=${count} '{print $n}'`
  #Check if the "cal_input" catalogue exists, or if we need to use the first datahead replicant {{{
  if [ ! -f ${cal_input} ]
  then 
    #There is no 'cal_input', use the first replicant 
    #Assumes the replication naming structure to avoid mismatches!
    cal_inpext=${cal_input##*.}
    cal_input=${cal_input//.${cal_inpext}/_1.${cal_inpext}}
    #Check again if the "cal_input" catalogue exists, otherwise error {{{
    if [ ! -f ${cal_input} ]
    then 
      echo ${cal_input}
      _message "@RED@ - ERROR! Cannot determine input calibration file name?!@DEF@\n"
      exit 1 
    fi 
  fi 
  #}}}
  #}}}
  #Remove zero weight sources from input catalogue {{{
  suffix=''
  if [ "@BV:CALIBWEIGHTNAME@" != "" ]
  then 
    _message "   -> @BLU@Removing zero-weight sources @DEF@"
    @PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/ldacfilter.py \
             -i ${cal_input} \
    	       -o ${cal_input}_tmp \
    	       -t OBJECTS \
    	       -c "(@BV:CALIBWEIGHTNAME@>0);" 2>&1 
    _message " -@RED@ Done! (`date +'%a %H:%M'`)@DEF@\n"
    suffix='_tmp'
  fi 
  #}}}
  #Merge the goldweight column {{{
  _message "   -> @BLU@Merging goldweight column @DEF@"
  @RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacjoinkey \
    -i ${cal_input}${suffix} \
    -p ${outfile} \
    -o ${outfile}_tmp \
    -k SOMGoldWeight -t OBJECTS 2>&1
  _message " -@RED@ Done! (`date +'%a %H:%M'`)@DEF@\n"
  #Delete the temporary input file 
  if [ "${suffix}" == "_tmp" ]
  then
    rm ${cal_input}_tmp 
  fi 
  #}}}
  #Construct final combination of calibration gold weights and any pre-existing weight{{{
  if [ "@BV:CALIBWEIGHTNAME@" != "" ]
  then 
    #Rename the original weight column {{{
    _message "   -> @BLU@Changing original @BV:CALIBWEIGHTNAME@ column to @BV:CALIBWEIGHTNAME@_nogoldwt@DEF@"
    @RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacrenkey \
      -i ${outfile}_tmp \
      -o ${outfile} \
      -k @BV:CALIBWEIGHTNAME@ @BV:CALIBWEIGHTNAME@_nogoldwt 2>&1
    _message " -@RED@ Done! (`date +'%a %H:%M'`)@DEF@\n"
    #remove the temporary output file 
    rm ${outfile}_tmp 
    #}}}
    #Incorporate the goldweight column into the calibration weight {{{
    _message "   -> @BLU@Incorporating goldweight into @BV:CALIBWEIGHTNAME@ column for @DEF@"
    @RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldaccalc \
      -i ${outfile} \
      -o ${outfile}_tmp \
      -t OBJECTS \
      -c "SOMGoldWeight*@BV:CALIBWEIGHTNAME@_nogoldwt;" -n "@BV:CALIBWEIGHTNAME@" "@BV:CALIBWEIGHTNAME@ including SOM gold weight" -k FLOAT 2>&1
    _message " -@RED@ Done! (`date +'%a %H:%M'`)@DEF@\n"
    #}}}
    #Convert the SOMGoldWeight into a binary Goldclass {{{
    _message "   -> @BLU@Constructing binary goldclass for @DEF@"
    @RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldaccalc \
      -i ${outfile}_tmp \
      -o ${outfile}     \
      -t OBJECTS \
      -c "SOMGoldWeight/(SOMGoldWeight+0.000000000000001);" -n "SOMweight" "Binary GoldWeight (for use with gold-weighted @BV:CALIBWEIGHTNAME@)" -k SHORT 2>&1
    _message " -@RED@ Done! (`date +'%a %H:%M'`)@DEF@\n"
    #Delete the temporary output file
    rm ${outfile}_tmp 
    #}}}
  else 
    #Rename the SOMGoldWeight column {{{
    _message "   -> @BLU@Renaming SOMGoldWeight to SOMweight@DEF@"
    @RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacrenkey \
      -i ${outfile}_tmp \
      -o ${outfile} \
      -k SOMGoldWeight SOMweight 2>&1
    _message " -@RED@ Done! (`date +'%a %H:%M'`)@DEF@\n"
    #remove the temporary output file 
    rm ${outfile}_tmp 
    #}}}
  fi 
  #}}}
  #Notify {{{
  _message " }\n"
  #}}}
done 
#}}}

#
##For each catalogue in the output folder of compute_nz_weights {{{
#mainlist_all="@DB:som_weight_calib_cats@"
#training_all="@DB:som_weight_training@"
#outlist=""
#count=0
#for input in ${inputlist}
#do
#  count=$((count+1))
#  #Construct the output name {{{
#  input_calib=`echo ${training_all} | awk -v n=$count '{print $n}'`
#  outname=${input_calib##*/}
#  #Outname extension 
#  outext=${outname##*.}
#  outname=${outname//.${outext}/_goldwt.${outext}}
#  #}}}
#  #Check that input and columns are different {{{
#  if [ "${input_calib}" == "${outname}" ] 
#  then 
#    _message "@RED@ ERROR!\n"
#    _message "@RED@Input and Output catalogue names are the same.\n"
#    _message "@RED@Unable to proceed with LDAC joinkey\n@DEF@"
#    exit 1
#  fi 
#  #}}}
#  #Get the main catalogue names for this file {{{
#  maincat=${input##*/}
#  mainbase=${maincat%.*}
#  #mainbase=${maincat%%_DIRsom*}
#  maincat=`echo ${mainlist_all} | sed 's/ /\n/g' | grep ${mainbase} || echo` 
#  if [ "${maincat}" == "" ] 
#  then 
#    _message "@BLU@Skipping @DEF@${mainbase}@BLU@ - no match in calibration catalogues\n"
#    continue
#  fi 
#  nmain=`echo ${mainlist_all} | sed 's/ /\n/g' | grep -c ${mainbase} || echo` 
#  if [ "${nmain}" == "" ] || [ ${nmain} -lt 2 ]
#  then 
#    _message "@RED@ ERROR!\n"
#    _message "@RED@There are insufficient catalogues to create goldweight?!@DEF@\n"
#    exit 1
#  fi 
#  #}}}
#  #If needed, make the gold catalogue folder {{{
#  if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/som_weight_calib_gold/ ]
#  then 
#    mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/som_weight_calib_gold
#  fi 
#  outfile=@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/som_weight_calib_gold/${outname}
#  #}}}
#  #Add file paths to goldclass catalogues {{{
#  mainlist=''
#  for main in ${maincat} 
#  do 
#    mainlist="${mainlist} ${main}"
#  done 
#  #}}}
#  ##Remove zero weight sources from input catalogue {{{
#  #_message " > @BLU@Removing zero-weight sources for @DEF@${mainfile##*/}"
#  #@PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/ldacfilter.py \
#  #         -i ${input} \
#  #	       -o ${outfile} \
#  #	       -t OBJECTS \
#  #	       -c "(@BV:WEIGHTNAME@>0);" 2>&1 
#  #_message " -@RED@ Done! (`date +'%a %H:%M'`)@DEF@\n"
#  ##}}}
#  #Notify {{{ 
#  _message " > @BLU@Constructing Gold Weight for input calibration catalogue ${outname%_goldwt*}"
#  #}}}
#  #Compute and Merge the Gold weights {{{
#  @P_RSCRIPT@ @RUNROOT@/@SCRIPTPATH@/make_goldweight.R \
#    -p ${mainlist} \
#    -o ${outfile} \
#    -w SOMweight 2>&1 
#  _message " -@RED@ Done! (`date +'%a %H:%M'`)@DEF@\n"
#  #}}}
#  #Merge the goldweight column {{{
#  _message " > @BLU@Merging goldweight column for @DEF@${input_calib##*/}"
#  @RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacjoinkey \
#    -i @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/som_weight_training/${input_calib} \
#    -p ${outfile} \
#    -o ${outfile}_tmp \
#    -k SOMGoldWeight -t OBJECTS 2>&1
#  _message " -@RED@ Done! (`date +'%a %H:%M'`)@DEF@\n"
#  #move the temporary file to the output 
#  mv ${outfile}_tmp ${outfile}
#  #}}}
#  #Save the output file to the list {{{
#  outlist="$outlist $outname"
#  #}}}
#done 
##}}}
#
#Add the new file to the datablock {{{
if [ "${outlist}" != "" ]
then 
  _write_datablock som_weight_calib_gold "`echo ${outlist}`"
fi 
#}}}

#}}}


