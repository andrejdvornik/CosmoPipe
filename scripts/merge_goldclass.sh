#=========================================
#
# File Name : merge_goldclass.sh
# Created By : awright
# Creation Date : 27-03-2023
# Last Modified : Wed 19 Jul 2023 09:44:54 AM CEST
#
#=========================================


#If needed, make the gold catalogue folder 
if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/som_weight_refr_gold/ ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/som_weight_refr_gold
fi 

#For each catalogue in the output folder of compute_nz_weights 
mainlist=`_read_datablock som_weight_reference`
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
  outfile=@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/som_weight_refr_gold/${outname}
  #}}}
  #Get the main catalogue name for this file {{{
  maincat=${input##*/}
  maincat=${maincat%%_refr_DIRsom*}
  _message "${maincat}\n"
  maincat=`_blockentry_to_filelist ${mainlist} | sed 's/ /\n/g' | grep ${maincat} || echo` 
  if [ "${maincat}" == "" ] 
  then 
    _message "@RED@ ERROR!\n"
    _message "@RED@Main catalogue corresponding to calibration catalogue was not found?!@DEF@\n"
    exit 1
  fi 
  mainfile=@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/som_weight_reference/${maincat}
  #}}}
  #Check if input file lengths are ok {{{
  links="FALSE"
  for file in ${input} ${outfile} ${mainfile}
  do 
    if [ ${#file} -gt 255 ] 
    then 
      links="TRUE"
    fi 
  done 
  #}}}
  #If needed, make the links {{{
  if [ "${links}" == "TRUE" ] 
  then 
    #Remove existing infile links 
    if [ -h infile.lnk ]
    then 
      rm infile.lnk
    fi 
    #Remove existing outfile links 
    if [ -h outfile.lnk ]
    then 
      rm outfile.lnk
    fi
    #Remove existing mainfile links 
    if [ -h mainfile.lnk ]
    then 
      rm mainfile.lnk
    fi  
    #Create input link
    originp=${input}
    ln -s ${input} infile.lnk 
    input="infile.lnk"
    #Create output links 
    ln -s ${outfile} outfile.lnk
    origout=${outfile}
    outfile=outfile.lnk
    #Create maincat links 
    ln -s ${mainfile} mainfile.lnk
    origmain=${mainfile}
    mainfile=mainfile.lnk
  fi 
  #}}}
  #Remove zero weight sources from main catalogue {{{
  _message "   > @BLU@Removing zero-weight sources for ${i}@DEF@${mainfile##*/}"
  @PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/ldacfilter.py \
           -i ${mainfile} \
  	       -o ${mainfile}_tmp \
  	       -t OBJECTS \
  	       -c "(@BV:WEIGHTNAME@>0);" 2>&1 
  _message " -@RED@ Done! (`date +'%a %H:%M'`)@DEF@\n"
  #}}}
  #Merge the goldclass column {{{
  _message "   > @BLU@Merging goldclass column for ${i}@DEF@${input##*/}"
  @RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacjoinkey \
    -i ${mainfile}_tmp \
    -p ${input} \
    -o ${outfile}_tmp \
    -k SOMweight -t OBJECTS 2>&1
  _message " -@RED@ Done! (`date +'%a %H:%M'`)@DEF@\n"
  #}}}
  #Construct the output tomographic bin {{{
  _message "   > @BLU@Removing non-gold sources for ${i}@DEF@${input##*/}"
  @PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/ldacfilter.py \
           -i ${outfile}_tmp \
  	       -o ${outfile} \
  	       -t OBJECTS \
  	       -c "(SOMweight>0);" 2>&1 
  _message " -@RED@ Done! (`date +'%a %H:%M'`)@DEF@\n"
  #}}}
  #Remove the temporary file {{{
  rm ${outfile}_tmp
  #}}}
  #If using links, remove them {{{
  if [ "${links}" == "TRUE" ] 
  then 
    rm ${input} ${outfile} ${mainfile}
    input=${originp}
    outfile=${origout}
    mainfile=${origmain}
  fi 
  #}}}
  #Save the output file to the list {{{
  outlist="$outlist $outname"
  #}}}
done 

#Add the new file to the datablock 
_add_datablock som_weight_refr_gold "`echo ${outlist}`"

