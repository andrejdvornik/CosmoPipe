#=========================================
#
# File Name : compute_nz.sh
# Created By : awright
# Creation Date : 22-03-2023
# Last Modified : Wed 22 Mar 2023 06:34:53 PM CET
#
#=========================================

#Construct the nz folder, if needed 
if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/nz ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/nz
fi 

#For each of the specz_calib_cats files: 
outlist=""
for input in @DB:som_weight_calib_cats@ 
do 
  #Define the output filename 
  output=${input%%_DIRsom*}@NZFILESUFFIX@
  output=${output##*/}
  outlist="${outlist} ${output}"

  #Run the Nz construction 
  @P_RSCRIPT@ @RUNROOT@/@SCRIPTPATH@/construct_nz.R ${input} @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/nz/${output}

done

#Add the Nz file(s) to the datablock 
_write_datablock nz "${outlist}"

