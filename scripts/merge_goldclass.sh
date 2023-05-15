#=========================================
#
# File Name : merge_goldclass.sh
# Created By : awright
# Creation Date : 27-03-2023
# Last Modified : Tue Apr  4 10:30:00 2023
#
#=========================================


#If needed, make the gold catalogue folder 
if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/main_all_tomo_gold/ ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/main_all_tomo_gold
fi 

#For each catalogue in the output folder of compute_nz_weights 
mainlist=`_read_datablock main_all_tomo`
outlist=""
for input in @DB:som_weight_refr_cats@
do
  #Construct the output name {{{
  outname=${input##*/}
  #Outname extension 
  outext=${outname##*.}
  outname=${outname//.${outext}/_gold.${outext}}
  #}}}
  #Check that input and columns are different {{{
  if [ "${input}" == "${outname}" ] 
  then 
    _message "@RED@ ERROR!\n"
    _message "@RED@Input and Output catalogue names are the same.\n"
    _message "@RED@Unable to proceed with LDAC joinkey\n@DEF@"
    exit 1
  fi 
  #}}}
  #Get the main catalogue name for this file {{{
  maincat=${input##*/}
  maincat=${maincat%%_refr_DIRsom*}
  maincat=`_blockentry_to_filelist ${mainlist} | sed 's/ /\n/g' | grep ${maincat}`
  if [ "${maincat}" == "" ] 
  then 
    _message "@RED@ ERROR!\n"
    _message "@RED@Main catalogue corresponding to calibration catalogue was not found?!@DEF@\n"
    exit 1
  fi 
  #}}}
  #Merge the goldclass column {{{
  _message "   > @BLU@Merging goldclass column for ${i}@DEF@${input##*/}"
  @RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacjoinkey \
    -i @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/main_all_tomo/${maincat} \
    -p ${input} \
    -o @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/main_all_tomo_gold/${outname}_tmp \
    -k SOMweight -t OBJECTS > @RUNROOT@/@LOGPATH@/${outname//.${outext}/.log} 2>&1
  _message " -@RED@ Done!@DEF@\n"
  #}}}
  #Construct the output tomographic bin {{{
  _message "   > @BLU@Removing non-gold sources for ${i}@DEF@${input##*/}"
  @PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/ldacfilter.py \
           -i @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/main_all_tomo_gold/${outname}_tmp \
  	       -o @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/main_all_tomo_gold/${outname} \
  	       -t OBJECTS \
  	       -c "(SOMweight>0);" >>@RUNROOT@/@LOGPATH@/${outname//.${outext}/.log} 2>&1 
  _message " -@RED@ Done!@DEF@\n"
  #}}}
  #Remove the temporary file {{{
  rm @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/main_all_tomo_gold/${outname}_tmp
  #}}}
  #Save the output file to the list {{{
  outlist="$outlist $outname"
  #}}}
done 

#Add the new file to the datablock 
_add_datablock main_all_tomo_gold "`echo ${outlist}`"

