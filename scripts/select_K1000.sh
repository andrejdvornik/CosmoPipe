#=========================================
#
# File Name : ldacfilter.sh
# Created By : awright
# Creation Date : 16-05-2023
# Last Modified : Tue 12 Mar 2024 04:41:25 PM CET
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
  -i ${input} \
  -l ${radeclims} \
  -o ${output}  2>&1 
_message " -@RED@ Done! (`date +'%a %H:%M'`)@DEF@\n"
#}}}
_replace_datahead "${input}" "${output}"

