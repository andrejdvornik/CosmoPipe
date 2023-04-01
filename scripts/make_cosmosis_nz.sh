#=========================================
#
# File Name : make_cosmosis_nz.sh
# Created By : awright
# Creation Date : 30-03-2023
# Last Modified : Fri 31 Mar 2023 11:38:59 AM CEST
#
#=========================================


inputs="@DB:nz@"

if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_nz ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_nz/
fi 

#Construct the output base
output_base=${file##*/}
output_base=${output_base%%_ZB*}
output_base="@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_nz/${output_base}"

if [ -f ${output_base}_comb_Nz.fits ]
then 
  _message " > @BLU@Removing previous COSMOSIS Nz file@DEF@ ${output_base##*/}_comb_Nz.fits"
  rm ${output_base}_comb_Nz.fits
  _message " - @RED@Done!\n"
fi 


_message " > @BLU@Constructing COSMOSIS Nz file@DEF@"
#Construct the Nz combined fits file and put into covariance/input/
@PYTHON3BIN@/python3 @RUNROOT@/@SCRIPTPATH@/MakeNofZForCosmosis_function.py \
  --inputs @DB:nz@ \
  --neffs @DB:cosmosis_neff@ \
  --output_base ${output_base} 2>&1 
_message " - @RED@Done!\n"

#Update the datablock 
_write_datablock cosmosis_nz "${output_base##*/}_comb_Nz.fits"
_write_datablock cosmosis_neff "${output_base##*/}_comb_neff.txt"
_write_datablock cosmosis_sigmae "${output_base##*/}_comb_sigmae.txt"

