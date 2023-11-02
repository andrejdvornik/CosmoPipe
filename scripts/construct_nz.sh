#=========================================
#
# File Name : compute_nz.sh
# Created By : awright
# Creation Date : 22-03-2023
# Last Modified : Wed 01 Nov 2023 03:41:32 PM CET
#
#=========================================

#Construct the nz folder, if needed 
if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/nz ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/nz
fi 

#For each of the specz_calib_cats files: 
outlist=""
for input in @DB:som_weight_calib_gold@ 
do 
  #Define the output filename 
  output=${input%%_DIRsom*}
  if [ "${output}" == "${input}" ] 
  then 
    #We are not using raw calibration catalogues 
    output=${input%.*}
  fi 
  #Add the Nz file suffice
  output=${output}@NZFILESUFFIX@
  output=${output##*/}
  outlist="${outlist} ${output}"

  #Run the Nz construction 
  @P_RSCRIPT@ @RUNROOT@/@SCRIPTPATH@/construct_nz.R \
    -i ${input} \
    -o @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/nz/${output} \
    --zname @BV:ZSPECNAME@ \
    --zstep @BV:NZSTEP@ \
    --somweightname "SOMweight" \
    --origweightname "@BV:CALIBWEIGHTNAME@" 2>&1 

done

#Add the Nz file(s) to the datablock 
_write_datablock nz "${outlist}"

