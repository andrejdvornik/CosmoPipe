#=========================================
#
# File Name : convert_to_ldac.sh
# Created By : awright
# Creation Date : 20-03-2023
# Last Modified : Fri 02 Jun 2023 10:35:47 PM CEST
#
#=========================================

#Input file name 
input="@DB:DATAHEAD@"

objstr=''
echo "Testing existance of OBJECTS, FIELDS, FIELD_POS, and SeqNr"
@RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldactestexist -i ${input} -t OBJECTS -k FIELD_POS 2>&1 || objstr="FAIL"
@RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldactestexist -i ${input} -t OBJECTS -k SeqNr 2>&1 || objstr="FAIL"
@RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldactestexist -i ${input} -t FIELDS 2>&1 || objstr="FAIL"

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

