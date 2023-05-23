#=========================================
#
# File Name : make_cosmosis_nz.sh
# Created By : awright
# Creation Date : 30-03-2023
# Last Modified : Tue 23 May 2023 04:56:11 PM CEST
#
#=========================================


inputs="@DB:nz@"

if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_nz ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_nz/
fi 

#Get the file list {{{
outputlist=''
for patch in @PATCHLIST@ @ALLPATCH@ 
do 
  filelist=''
  for ZBIN1 in `seq ${ntomo}`
  do
    #Define the Z_B limits from the TOMOLIMS {{{
    ZB_lo=`echo @BV:TOMOLIMS@ | awk -v n=$ZBIN1 '{print $n}'`
    ZB_hi=`echo @BV:TOMOLIMS@ | awk -v n=$ZBIN1 '{print $(n+1)}'`
    #}}}
    #Define the string to append to the file names {{{
    ZB_lo_str=`echo $ZB_lo | sed 's/\./p/g'`
    ZB_hi_str=`echo $ZB_hi | sed 's/\./p/g'`
    appendstr="_ZB${ZB_lo_str}t${ZB_hi_str}"
    #}}}
    file=`echo ${inputs} | sed 's/ /\n/g' | grep "_${patch}_" | grep ${appendstr} || echo `
    #Check if the output file exists 
    if [ "${file}" == "" ] 
    then 
      continue
    fi 
    filelist="${filelist} ${file}"
  done 
  if [ "${filelist}" == "" ] 
  then 
    continue
  fi 
  #Construct the output base
  file=${filelist##* }
  output_base=${file##*/}
  output_base=${output_base%%_ZB*}
  output_base="@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_nz/${output_base}"
  
  if [ -f ${output_base}_comb_Nz.fits ]
  then 
    _message " > @BLU@Removing previous COSMOSIS Nz file@DEF@ ${output_base##*/}_comb_Nz.fits@DEF@"
    rm ${output_base}_comb_Nz.fits
    _message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"
  fi 
  
  _message " > @BLU@Constructing COSMOSIS Nz file @RED@${output_base}_comb_Nz.fits@DEF@"
  #Construct the Nz combined fits file and put into covariance/input/
  @PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/MakeNofZForCosmosis_function.py \
    --inputs ${filelist} \
    --neff @DB:cosmosis_neff@ \
    --output_base ${output_base} 2>&1 
  _message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"

  #Save output to the outputlist 
  outputlist="${outputlist} ${output_base##*/}_comb_Nz.fits"
done 

#Update the datablock 
_write_datablock cosmosis_nz "${outputlist}"

