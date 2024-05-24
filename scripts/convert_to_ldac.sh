#=========================================
#
# File Name : convert_to_ldac.sh
# Created By : awright
# Creation Date : 20-03-2023
# Last Modified : Fri 24 May 2024 11:07:49 AM CEST
#
#=========================================

#Input file name 
input="@DB:DATAHEAD@"
extn=${input##*.}
output=${input%.${extn}}.cat

objstr=''
run=0
_message "@BLU@Testing existance of @RED@OBJECTS@BLU@, @RED@FIELDS@BLU@, @RED@FIELD_POS@BLU@, and @RED@SeqNr@BLU@:\n{@DEF@\n"
#Brackets catch shell messages like segmentation fault and abort 
{
@RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldactestexist -i ${input} -t OBJECTS -k FIELD_POS 2>&1 && _message " @BLU@FIELD_POS found!@DEF@\n" || objstr="FAIL"
} >&1
if [ "${objstr}" == "FAIL" ] 
then 
  run=1
fi 
{
@RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldactestexist -i ${input} -t OBJECTS -k SeqNr 2>&1 && _message " @BLU@SeqNr found!@DEF@\n" || objstr="FAIL"
} >&1
{
@RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldactestexist -i ${input} -t FIELDS 2>&1 && _message " @BLU@FIELDS table found!@DEF@\n" || objstr="FAIL"
} >&1
if [ "${objstr}" == "FAIL" ] && [ "${run}" == "0" ]
then 
  run=2
fi 
_message "@BLU@} - @RED@Done!@DEF@\n"

if [ "${objstr}" == "FAIL" ] 
then 
  if [ "${run}" == "1" ] 
  then 
    _message "   > @BLU@Adding missing FIELD_POS variable: @DEF@${input##*/}@DEF@ "
    @RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacaddkey -i ${input} -o ${input}_tmp -t OBJECTS -k FIELD_POS 1 SHORT "FIELD_POS identifier" 2>&1
    mv ${input}_tmp ${output}
    _message " @BLU@- @RED@Done! (`date +'%a %H:%M'`)\n@DEF@"
    if [ "${input}" != "${output}" ]
    then 
      _replace_datahead ${input} ${output}
    fi 
  else 
    #Notify 
    _message "   > @BLU@Converting non-LDAC FITS catalogue for use as LDAC: @DEF@${input##*/}@DEF@ "

    #Remove existing output file 
    if [ "${input}" != "${output}" ] && [ -f ${output} ]
    then 
      rm ${output}
    fi 

    #Clean the first catalogue of variable-length items 
    @PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/fits_str_col_fix.py ${input} ${output} 2>&1

    #If the output file doesn't exist, nothing was updated; duplicate the input 
    if [ ! -f ${output} ]
    then 
      rsync -atvL ${input} ${output}
    fi 

    #Convert the catalogue int64 columns to int32, and enforce LDAC format
    @P_RSCRIPT@ @RUNROOT@/@SCRIPTPATH@/convert_to_ldac.R ${output} 2>&1

    _message " @BLU@- @RED@Done! (`date +'%a %H:%M'`)\n@DEF@"

    #Update the datahead 
    _replace_datahead ${input} ${output}
  fi 
else 
  #Notify 
  _message "   > @BLU@Catalogue @DEF@${input##*/}@BLU@ already appears LDAC compatible!@DEF@\n"
  #Check if we need to rename 
  if [ "${input}" != "${output}" ]
  then 
    _replace_datahead ${input} ${output}
  fi 
fi 

