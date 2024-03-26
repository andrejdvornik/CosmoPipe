#=========================================
#
# File Name : ldacfilter.sh
# Created By : awright
# Creation Date : 16-05-2023
# Last Modified : Thu 14 Mar 2024 01:10:34 PM CET
#
#=========================================

#Input catalogue from datahead 
input="@DB:DATAHEAD@"
ext=${input##*.}
#Avoid duplicate "_filt" extensions {{{
inputbase=${input##*/}
output=${input//.${ext}/_notk1000.${ext}}
#}}}
radeclims=@RUNROOT@/@CONFIGPATH@/DR4_ra_dec_lims.txt

#Filter the DATAHEAD catalogues based on the block-variable condition {{{
_message "@BLU@Identifying non-K1000 sources from file ${inputbase}@DEF@\n"
#}}}
#Identify and keep only K1000 sources {{{ 
@P_RSCRIPT@ @RUNROOT@/@SCRIPTPATH@/select_K1000.R \
  -i ${input} \
  -l ${radeclims} \
  -o ${output}  2>&1 
_message " -@RED@ Done! (`date +'%a %H:%M'`)@DEF@\n"
#}}}
_replace_datahead "${input}" "${output}"

