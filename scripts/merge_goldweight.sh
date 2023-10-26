#=========================================
#
# File Name : merge_goldweight.sh
# Created By : awright
# Creation Date : 21-09-2023
# Last Modified : Fri 22 Sep 2023 11:40:41 AM CEST
#
#=========================================

#Construct and merge the gold weights for the reference sample catalogues {{{
#For each catalogue in the output folder of compute_nz_weights {{{
mainlist_all=`_read_datablock som_weight_refr_cats`
outlist=""
for input in @DB:som_weight_reference@ 
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
  maincat=`_blockentry_to_filelist ${mainlist_all} | sed 's/ /\n/g' | grep ${mainbase} || echo` 
  if [ "${maincat}" == "" ] 
  then 
    _message "@BLU@Skipping @DEF@${mainbase}@BLU@ - no match in reference catalogues\n"
    continue
  fi 
  nmain=`_blockentry_to_filelist ${mainlist_all} | sed 's/ /\n/g' | grep -c ${mainbase} || echo` 
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
    mainlist="${mainlist} @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/som_weight_refr_cats/${main}"
  done 
  #}}}
  #Notify {{{ 
  _message " > @BLU@Constructing Gold Weight for input reference catalogue @DEF@${mainbase}"
  #}}}
  #Compute and Merge the Gold weights {{{
  @P_RSCRIPT@ @RUNROOT@/@SCRIPTPATH@/make_goldweight.R \
    -p ${mainlist} \
    -o ${outfile} 2>&1 
  _message " -@RED@ Done! (`date +'%a %H:%M'`)@DEF@\n"
  #}}}
  #Remove zero weight sources from input catalogue {{{
  _message " > @BLU@Removing zero-weight sources from @DEF@${input##*/}"
  @PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/ldacfilter.py \
           -i ${input} \
  	       -o ${input}_tmp \
  	       -t OBJECTS \
  	       -c "(@BV:WEIGHTNAME@>0);" 2>&1 
  _message " -@RED@ Done! (`date +'%a %H:%M'`)@DEF@\n"
  #}}}
  #Merge the goldweight column {{{
  _message " > @BLU@Merging goldweight column for ${i}@DEF@${input##*/}"
  @RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacjoinkey \
    -i ${input}_tmp \
    -p ${outfile} \
    -o ${outfile}_tmp \
    -k SOMweight -t OBJECTS 2>&1
  _message " -@RED@ Done! (`date +'%a %H:%M'`)@DEF@\n"
  #Delete the temporary input file 
  rm ${input}_tmp 
  #}}}
  #Rename the original weight column {{{
  _message " > @BLU@Changing original @BV:WEIGHTNAME@ column to @BV:WEIGHTNAME@_nogoldwt for @DEF@${outfile##*/}"
  @RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacrenkey \
    -i ${outfile}_tmp \
    -o ${outfile} \
    -k @BV:WEIGHTNAME@ @BV:WEIGHTNAME@_nogoldwt 2>&1
  _message " -@RED@ Done! (`date +'%a %H:%M'`)@DEF@\n"
  #remove the temporary output file 
  rm ${outfile}_tmp 
  #}}}
  #Incorporate the goldweight column into the shape weight {{{
  _message " > @BLU@Incorporating goldweight into @BV:WEIGHTNAME@ column for @DEF@${outfile##*/}"
  @RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldaccalc \
    -i ${outfile} \
    -o ${outfile}_tmp \
    -t OBJECTS \
    -c "SOMweight*@BV:WEIGHTNAME@_nogoldwt;" -n "@BV:WEIGHTNAME@" "Shape measurement weight including gold weight" -k FLOAT 2>&1
  _message " -@RED@ Done! (`date +'%a %H:%M'`)@DEF@\n"
  #move the temporary output file to output location 
  mv ${outfile}_tmp ${outfile}
  #}}}
  #Save the output file to the list {{{
  outlist="$outlist $outname"
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
mainlist_all=`_read_datablock som_weight_calib_cats`
training_all=`_read_datablock som_weight_training`
training_all=`_blockentry_to_filelist ${training_all}`
outlist=""
count=0
for input in @DB:som_weight_reference@ 
do
  count=$((count+1))
  #Construct the output name {{{
  input_calib=`echo ${training_all} | awk -v n=$count '{print $n}'`
  outname=${input_calib##*/}
  #Outname extension 
  outext=${outname##*.}
  outname=${outname//.${outext}/_goldwt.${outext}}
  #}}}
  #Check that input and columns are different {{{
  if [ "${input_calib}" == "${outname}" ] 
  then 
    _message "@RED@ ERROR!\n"
    _message "@RED@Input and Output catalogue names are the same.\n"
    _message "@RED@Unable to proceed with LDAC joinkey\n@DEF@"
    exit 1
  fi 
  #}}}
  #Get the main catalogue names for this file {{{
  maincat=${input##*/}
  mainbase=${maincat%.*}
  #mainbase=${maincat%%_DIRsom*}
  maincat=`_blockentry_to_filelist ${mainlist_all} | sed 's/ /\n/g' | grep ${mainbase} || echo` 
  if [ "${maincat}" == "" ] 
  then 
    _message "@BLU@Skipping @DEF@${mainbase}@BLU@ - no match in calibration catalogues\n"
    continue
  fi 
  nmain=`_blockentry_to_filelist ${mainlist_all} | sed 's/ /\n/g' | grep -c ${mainbase} || echo` 
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
  outfile=@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/som_weight_calib_gold/${outname}
  #}}}
  #Add file paths to goldclass catalogues {{{
  mainlist=''
  for main in ${maincat} 
  do 
    mainlist="${mainlist} @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/som_weight_calib_cats/${main}"
  done 
  #}}}
  ##Remove zero weight sources from input catalogue {{{
  #_message " > @BLU@Removing zero-weight sources for @DEF@${mainfile##*/}"
  #@PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/ldacfilter.py \
  #         -i ${input} \
  #	       -o ${outfile} \
  #	       -t OBJECTS \
  #	       -c "(@BV:WEIGHTNAME@>0);" 2>&1 
  #_message " -@RED@ Done! (`date +'%a %H:%M'`)@DEF@\n"
  ##}}}
  #Notify {{{ 
  _message " > @BLU@Constructing Gold Weight for input calibration catalogue ${outname%_goldwt*}"
  #}}}
  #Compute and Merge the Gold weights {{{
  @P_RSCRIPT@ @RUNROOT@/@SCRIPTPATH@/make_goldweight.R \
    -p ${mainlist} \
    -o ${outfile} \
    -w SOMweight 2>&1 
  _message " -@RED@ Done! (`date +'%a %H:%M'`)@DEF@\n"
  #}}}
  #Merge the goldweight column {{{
  _message " > @BLU@Merging goldweight column for @DEF@${input_calib##*/}"
  @RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacjoinkey \
    -i @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/som_weight_training/${input_calib} \
    -p ${outfile} \
    -o ${outfile}_tmp \
    -k SOMweight -t OBJECTS 2>&1
  _message " -@RED@ Done! (`date +'%a %H:%M'`)@DEF@\n"
  #move the temporary file to the output 
  mv ${outfile}_tmp ${outfile}
  #}}}
  #Save the output file to the list {{{
  outlist="$outlist $outname"
  #}}}
done 
#}}}

#Add the new file to the datablock {{{
if [ "${outlist}" != "" ]
then 
  _write_datablock som_weight_calib_gold "`echo ${outlist}`"
fi 
#}}}

#}}}


