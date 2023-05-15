#=========================================
#
# File Name : cleanfits.sh
# Created By : awright
# Creation Date : 20-03-2023
# Last Modified : Mon 15 May 2023 10:45:49 AM CEST
#
#=========================================

#Input file name 
input="@DB:DATAHEAD@"

#Notify 
_message "   > @BLU@Cleaning FITS catalogue for use as LDAC: @DEF@${input##*/}@DEF@ "

#Clean the first catalogue of variable-length items 
@PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/fits_str_col_fix.py ${input} ${input} 2>&1

#Convert the catalogue int64 columns to int32
#@P_RSCRIPT@ @RUNROOT@/@SCRIPTPATH@/cleanfits.R ${input} @RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacdesc "@P_SED_INPLACE@" 2>&1
@P_RSCRIPT@ @RUNROOT@/@SCRIPTPATH@/cleanfits.R ${input} 2>&1

_message " @BLU@- @RED@Done! (`date +'%a %H:%M'`)\n@DEF@"
