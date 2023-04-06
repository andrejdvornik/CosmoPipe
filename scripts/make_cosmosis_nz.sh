#=========================================
#
# File Name : make_cosmosis_nz.sh
# Created By : awright
# Creation Date : 30-03-2023
# Last Modified : Wed Apr  5 09:17:31 2023
#
#=========================================


inputs="@DB:nz@"

if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_nz ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_nz/
fi 

#Construct the output base
file=${inputs##* }
output_base=${file##*/}
output_base=${output_base%%_ZB*}
output_base="@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_nz/${output_base}"

if [ -f ${output_base}_comb_Nz.fits ]
then 
  _message " > @BLU@Removing previous COSMOSIS Nz file@DEF@ ${output_base##*/}_comb_Nz.fits@DEF@"
  rm ${output_base}_comb_Nz.fits
  _message " - @RED@Done!@DEF@\n"
fi 


_message " > @BLU@Constructing COSMOSIS Nz file@DEF@"
#Construct the Nz combined fits file and put into covariance/input/
@PYTHON3BIN@/python3 @RUNROOT@/@SCRIPTPATH@/MakeNofZForCosmosis_function.py \
  --inputs @DB:nz@ \
  --neff @DB:cosmosis_neff@ \
  --output_base ${output_base} 2>&1 
_message " - @RED@Done!@DEF@\n"

#Update the datablock 
_write_datablock cosmosis_nz "${output_base##*/}_comb_Nz.fits"

