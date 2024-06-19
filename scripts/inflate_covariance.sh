#=========================================
#
# File Name : combine_covariances.sh
# Created By : awright
# Creation Date : 22-03-2024
# Last Modified : Thu Apr 11 07:31:48 2024
#
#=========================================

#Inflate Covariances 
input="@DB:DATAHEAD@"
ext=${input%%*.}
output=${input//.${ext}/_infl.${ext}}

#Inflate the covariances by specified factor {{{
@P_RSCRIPT@ @RUNROOT@/@SCRIPTPATH@/inflate_covariance.R \
  --input ${input} \
  --factor @BV:FACTOR@ \
  --output ${output} 2>&1 
#}}}

_replace_datahead ${input} ${output}


