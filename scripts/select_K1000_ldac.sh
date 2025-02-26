#=========================================
#
# File Name : equalN_split.sh
# Created By : awright
# Creation Date : 04-07-2023
# Last Modified : Fri 07 Feb 2025 05:12:07 PM CET
#
#=========================================

#Define the output filename 
input="@DB:DATAHEAD@"
output=${input}
outext=${output##*.}
output=${output//.${outext}/_k1000.${outext}}

#Check whether we need to use links 
links="FALSE"
for file in ${input} ${output}
do 
  if [ ${#file} -gt 250 ] 
  then 
    links="TRUE"
  fi 
done 

if [ "${links}" == "TRUE" ] 
then
  #Remove existing infile links 
  if [ -e infile_$$.lnk.${outext} ] || [ -h infile_$$.lnk.${outext} ]
  then 
    rm -f infile_$$.lnk.${outext}
  fi 
  #Remove existing outfile links 
  if [ -e outfile_$$.lnk.${outext} ] || [ -h outfile_$$.lnk.${outext} ]
  then 
    rm -f outfile_$$.lnk.${outext}
  fi
  #Create input link
  originp=${input}
  ln -s ${input} infile_$$.lnk.${outext} 
  input="infile_$$.lnk.${outext}"
  #Create output links 
  ln -s ${output} outfile_$$.lnk.${outext}
  origout=${output}
  output=outfile_$$.lnk.${outext}
fi 

#Identify the sources to remove 
radeclims=@RUNROOT@/@CONFIGPATH@/DR5_new_ra_dec_lims.txt

#Filter the DATAHEAD catalogues based on the block-variable condition {{{
_message "@BLU@Identifying K1000 tiles in file ${input}@DEF@\n"
#}}}
#Identify and keep only relevant fields {{{ 
@P_RSCRIPT@ @RUNROOT@/@SCRIPTPATH@/select_K1000.R \
  -i ${input} \
  -l ${radeclims} \
  -o ${output} \
  --id_only 2>&1 
_message " -@RED@ Done! (`date +'%a %H:%M'`)@DEF@\n"
#}}}

objstr=''
{
@RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldactestexist -i ${input} -t OBJECTS -k fieldsel 2>&1 && objstr="" || objstr="FAIL"
} >&1

if [ "${objstr}" == "" ] 
then 
  #Remove the original column
  _message "  > @BLU@Removing previous {fieldsel} column@DEF@"
  @RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacdelkey \
    -i ${input} \
    -o ${input}_tmp \
    -k fieldsel -t OBJECTS 2>&1
  _message "@RED@ - Done\n"
else 
  ln -s ${input} ${input}_tmp
fi 
_message "  > @BLU@Merging field selection variable column@DEF@"
#Merge field selection variable
@RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacjoinkey \
  -i ${input}_tmp \
  -p ${output} \
  -o ${output}_tmp \
  -k fieldsel -t OBJECTS 2>&1
_message "@RED@ - Done\n"

  #Remove zero weight sources from input catalogue {{{
_message "  > @BLU@Removing non-selected fields@DEF@"
@PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/ldacfilter.py \
         -i ${output}_tmp \
	       -o ${output} \
	       -t OBJECTS \
	       -c "(fieldsel==1);" 2>&1 
_message " -@RED@ Done! (`date +'%a %H:%M'`)@DEF@\n"
#}}}

if [ "${links}" == "TRUE" ] 
then 
  #Move the output file to the original name/location
  mv ${output} ${origout}
  #remove temporary files 
  rm -f ${input}_tmp ${output}_tmp
  #remove links 
  rm -f ${input} 
  #Reset input and output variables
  input=${originp}
  output=${origout}
else 
  #remove temporary files 
  rm -f ${input}_tmp ${output}_tmp
fi 

#Update the datahead 
_replace_datahead "${input}" "${output}"

