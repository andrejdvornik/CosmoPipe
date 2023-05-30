#=========================================
#
# File Name : duplicate_perpatch.sh
# Created By : awright
# Creation Date : 30-05-2023
# Last Modified : Tue 30 May 2023 02:10:22 PM CEST
#
#=========================================

#Script to duplicate the DATAHEAD catalogues once per patch 
inputs="@DB:ALLHEAD@" 
outputlist=''
for patch in @PATCHLIST@ 
do 
  for input in ${inputs}
  do 
    #define the output name 
    output=${input//_@ALLPATCH@_/_${patch}_}
    #Add to the output list 
    outputlist="${outputlist} ${output##*/}"
    #Copy the data 
    cp ${input} ${output} 
  done 
done 
#Remove the inputs 
for input in ${inputs}
do 
  rm ${input}
done 

#Update the datablock 
_writelist_datahead "${outputlist}"

