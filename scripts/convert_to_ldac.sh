#=========================================
#
# File Name : convert_to_ldac.sh
# Created By : awright
# Creation Date : 20-03-2023
# Last Modified : Tue 13 Jun 2023 04:06:54 PM CEST
#
#=========================================

#Input file name 
input="@DB:DATAHEAD@"

objstr=''
_message "@BLU@Testing existance of @RED@OBJECTS@BLU@, @RED@FIELDS@BLU@, @RED@FIELD_POS@BLU@, and @RED@SeqNr@BLU@:\n{@DEF@\n"
@RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldactestexist -i ${input} -t OBJECTS -k FIELD_POS 2>&1 && _message " @BLU@FIELD_POS found!@DEF@\n" || objstr="FAIL"
@RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldactestexist -i ${input} -t OBJECTS -k SeqNr 2>&1 && _message " @BLU@SeqNr found!@DEF@\n" || objstr="FAIL"
@RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldactestexist -i ${input} -t FIELDS 2>&1 && _message " @BLU@FIELDS table found!@DEF@\n" || objstr="FAIL"
_message "@BLU@} - @RED@Done!@DEF@\n"

if [ "${objstr}" == "FAIL" ] 
then 
  #Notify 
  _message "   > @BLU@Converting non-LDAC FITS catalogue for use as LDAC: @DEF@${input##*/}@DEF@ "

  #Clean the first catalogue of variable-length items 
  @PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/fits_str_col_fix.py ${input} ${input} 2>&1

  #Convert the catalogue int64 columns to int32
  @P_RSCRIPT@ @RUNROOT@/@SCRIPTPATH@/convert_to_ldac.R ${input} 2>&1

  _message " @BLU@- @RED@Done! (`date +'%a %H:%M'`)\n@DEF@"
else 
  #Notify 
  _message "   > @BLU@Catalogue @DEF@${input##*/}@BLU@ already appears LDAC compatible!@DEF@\n"
fi 

