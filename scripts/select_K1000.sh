#=========================================
#
# File Name : ldacfilter.sh
# Created By : awright
# Creation Date : 16-05-2023
# Last Modified : Fri 07 Feb 2025 05:01:31 PM CET
#
#=========================================

#Input catalogue from datahead 
input="@DB:DATAHEAD@"
ext=${input##*.}
#Avoid duplicate "_filt" extensions {{{
inputbase=${input##*/}
output=${input//.${ext}/_k1000.${ext}}
#}}}
radeclims=@RUNROOT@/@CONFIGPATH@/DR5_new_ra_dec_lims.txt

#Filter the DATAHEAD catalogues based on the block-variable condition {{{
_message "@BLU@Identifying K1000 sources from file ${inputbase}@DEF@\n"
#}}}
#Identify and keep only K1000 sources {{{ 
@P_RSCRIPT@ @RUNROOT@/@SCRIPTPATH@/select_K1000.R \
  --id_only \
  -i ${input} \
  -l ${radeclims} \
  -o ${output}  2>&1 
_message " -@RED@ Done! (`date +'%a %H:%M'`)@DEF@\n"
@RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacjoinkey \
  -i ${input} \
  -p ${output} \
  -o ${output}_tmp \
  -k K1000Flag -t OBJECTS 2>&1
@RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacfilter \
  -i ${output}_tmp \
  -o ${output} \
  -c "(K1000Flag==1);" -t OBJECTS 2>&1
rm ${output}_tmp 
#}}}
_replace_datahead "${input}" "${output}"

