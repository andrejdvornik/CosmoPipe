#=========================================
#
# File Name : equalN_split.sh
# Created By : awright
# Creation Date : 04-07-2023
# Last Modified : Thu 25 Apr 2024 09:09:35 AM CEST
#
#=========================================

#Define the output filename 
input="@DB:DATAHEAD@"
output=${input}
outext=${output##*.}
output=${output//.${outext}/_sparse.${outext}}

#Step 1, sparse sample labels 
_message "@BLU@Generating sparse column for @DEF@${input##*/}"
@P_RSCRIPT@ @RUNROOT@/@SCRIPTPATH@/sparse_var.R \
  -i @DB:DATAHEAD@ \
  -s @BV:SEED@ \
  -o ${output} 2>&1 
_message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"

#Select the sparse sources 
_message "@BLU@Combining sparse column@DEF@"
@RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacjoinkey \
  -i @DB:DATAHEAD@ \
  -p ${output} \
  -o ${output}_tmp \
  -k sparse_var -t OBJECTS 2>&1
_message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"

#Select the sparse sources 
_message "@BLU@Selecting sparse sources with fraction @RED@@BV:SPARSEFRAC@@DEF@"
@RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacfilter \
  -i ${output}_tmp \
  -o ${output} \
  -c "(sparse_var<=@BV:SPARSEFRAC@);" -t OBJECTS 2>&1
_message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"

rm ${output}_tmp

#Update the datahead 
_replace_datahead "${input}" "${output}"

