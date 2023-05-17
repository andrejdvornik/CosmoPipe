#=========================================
#
# File Name : ldacfilter.sh
# Created By : awright
# Creation Date : 16-05-2023
# Last Modified : Wed 17 May 2023 06:38:49 AM CEST
#
#=========================================

#Input catalogue from datahead 
input="@DB:DATAHEAD@"
ext=${input##*.}

#Filter the DATAHEAD catalogues based on the block-variable condition
_message "@BLU@Using Condition @DEF@@BV:FILTERCOND@@DEF@\n"
_message "@BLU@Creating Filtered catalogue for @DEF@${input##*/}@DEF@"
#Select sources using required filter condition 
@PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/ldacfilter.py \
  -i ${input} \
  -t OBJECTS \
  -c "(@BV:FILTERCOND@);" \
  -o ${input//.${ext}/_filt.${ext}} 2>&1 
_message " @BLU@- @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"
output=${input//.${ext}/_filt.${ext}}
_replace_datahead ${input##*/} ${output##*/}

