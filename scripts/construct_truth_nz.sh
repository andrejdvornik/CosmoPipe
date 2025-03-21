#=========================================
#
# File Name : construct_truth_nz.sh
# Created By : awright
# Creation Date : 22-03-2023
# Last Modified : Sat Feb 17 06:08:45 2024
#
#=========================================

#Construct the nz_true folder, if needed 
if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/nz_true ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/nz_true
fi 

#For each of the reference files: 
outlist=""
for input in @DB:som_weight_refr_gold@ 
do 
  #Define the output filename 
  output=${input%%_refr_DIRsom*}
  if [ "${output}" == "${input}" ] 
  then 
    #We are not using raw reference catalogues 
    output=${input%.*}
  fi 
  #Add the Nz file suffice
  output=${output}@NZFILESUFFIX@
  output=${output##*/}
  outlist="${outlist} ${output}"

  #Run the Nz construction 
  @P_RSCRIPT@ @RUNROOT@/@SCRIPTPATH@/construct_nz.R \
    -i ${input} \
    -o @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/nz_truth/${output} \
    --zname @BV:ZSPECNAME@ \
    --zstep @BV:NZSTEP@ \
    --somweightname "SOMweight" \
    --origweightname "@BV:WEIGHTNAME@" 2>&1 

done

#Add the Nz file(s) to the datablock 
_write_datablock nz "${outlist}"

