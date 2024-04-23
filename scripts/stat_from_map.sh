#=========================================
#
# File Name : stat_from_map.sh
# Created By : awright
# Creation Date : 30-10-2023
# Last Modified : Wed Jan 10 05:14:09 2024
#
#=========================================

#Inherit a statistic from a healpix map 

#Input files from DATAHEAD 
input=@DB:DATAHEAD@

#Map name 
map="@BV:HPMAPFILE@"

#Statistic name 
statname="@BV:STATNAME@"

#Statistic modifier function 
statfun="@BV:STATFUNC@"

#Inherit the statistic from the map 
ext=${input##*.}
output=${input/.${ext}/_${statname}.${ext}}

_message " > @BLU@Adding Statistic @RED@${statname}@BLU@ from map @RED@${map##*/}@BLU@ to catalogue @RED@${input##*/}@DEF@"
if [ "${statfun}" != "" ] 
then 
  _message "\n   IMPORTANT: @BLU@Statistic will be modified from map value using @RED@f(x):=${statfun}@DEF@"
  statfun="--function ${statfun}"
fi 
@PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/stat_from_map.py\
    --incat  ${input} \
    --inmap  ${map} \
    --outpath ${output} \
    --statname ${statname} \
    --col_RA @BV:RANAME@ \
    --col_Dec @BV:DECNAME@ \
    ${statfun} 2>&1 
_message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"
_replace_datahead ${input} ${output}




