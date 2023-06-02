#=========================================
#
# File Name : convert_to_ldac.sh
# Created By : awright
# Creation Date : 20-03-2023
# Last Modified : Fri 02 Jun 2023 01:20:51 PM CEST
#
#=========================================

#Input file name 
input="@DB:DATAHEAD@"

#Notify 
_message "   > @BLU@Cleaning FITS catalogue for use as LDAC: @DEF@${input##*/}@DEF@ "

#Clean the first catalogue of variable-length items 
@PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/fits_str_col_fix.py ${input} ${input} 2>&1

#Convert the catalogue int64 columns to int32
@P_RSCRIPT@ @RUNROOT@/@SCRIPTPATH@/convert_to_ldac.R ${input} 2>&1

_message " @BLU@- @RED@Done! (`date +'%a %H:%M'`)\n@DEF@"
