#=========================================
#
# File Name : get_features.sh
# Created By : awright
# Creation Date : 06-08-2023
# Last Modified : Sun Aug  6 22:05:56 2023
#
#=========================================

#Get the list of magnitudes 
maglist="@BV:MAGLIST@" 

#Get the feature specification 
feature_types="@BV:FEATURETYPES@"

#Check for colours, mags, or both 
magnitude=FALSE
colours=FALSE
if [[ "${feature_types^^}" =~ "MAG" ]]
then 
  if [[ "${feature_types^^}" =~ "ALLMAG" ]] 
  then 
    magnitudes="ALL"
  else 
    magnitudes="REF"
  fi
fi 
if [[ "${feature_types^^}" =~ "COLOUR" ]] || [[ "${feature_types^^}" =~ "COLOR" ]]
then 
  if [[ "${feature_types^^}" =~ "ALLCOL" ]] 
  then 
    colours="ALL"
  else 
    colours="SIMPLE"
  fi
fi 

features=""
if [ "${colours}" == "ALL" ]
then 
  #Get the number of magnitudes 
  nmag=`echo ${maglist} | awk '{print NF}'`
  #Loop through the magnitudes  
  for i in `seq 1 $((nmag-1))`
  do 
    #Loop through the remaining magnitudes  
    for j in `seq $((i+1)) ${nmag}`
    do 
      #Construct the colour label 
      col=`echo ${maglist} | awk -v i=${i} -v j=${j} '{print $i "-" $j}'`
      #Add the colour to the feature space 
      features="${features} ${col}"
    done 
  done 
fi 
if [ "${colours}" == "SIMPLE" ] 
then 
  #Get the number of neighbouring colours 
  ncol=`echo ${maglist} | awk '{print NF-1}'`
  #Loop through the colours 
  for i in `seq 1 ${ncol}`
  do 
    #Construct the colour label 
    col=`echo ${maglist} | awk -v i=${i} '{print $i "-" $(i+1)}'`
    #Add the colour to the feature space 
    features="${features} ${col}"
  done 
fi 
if [ "${magnitudes}" == "ALL" ]
then 
  features="${features} ${maglist}" 
fi 
if [ "${magnitudes}" == "REF" ]
then 
  features="${features} @BV:REFMAGNAME@"
fi 

#Assign the feature space to the block variables 
_write_blockvars "SOMFEATURES" "${features}"

