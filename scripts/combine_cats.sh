#=========================================
#
# File Name : combine_cats.sh
# Created By : awright
# Creation Date : 20-03-2023
# Last Modified : Fri 19 May 2023 04:10:49 PM CEST
#
#=========================================


#Get the DATAHEAD filelist 
input="@DB:ALLHEAD@" 

#Remove leading space
if [ "${input:0:1}" == " " ]
then
  input=${input:1}
fi
#Get the output name 
#First & last file names 
output=${input##* }
output2=${input%% *}
output=${output##*/}
output2=${output2##*/}
#First file extension 
ext=${output##*.}
for i in `seq ${#output}`
do
  #Check for the first part of the filenames that is different
  if [ "${output:0:${i}}" != "${output2:0:${i}}" ]
  then
    break
  fi
done

#Check if the last character is an underscore
if [ ${i} -gt 2 ]
then 
  ((i-=2))
  if [ "${output:${i}:1}" != "_" ]
  then
    ((i+=1))
  fi
fi 

#Construct the output name 
outname=${output:0:${i}}_comb.${ext}

#Combine the DATAHEAD catalogues into one 
_message "   > @BLU@Constructing combined catalogue @DEF@${outname}@DEF@ "
@RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacpaste \
  -i ${input} \
  -o @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/DATAHEAD/${outname} 2>&1 
_message " @RED@- Done! (`date +'%a %H:%M'`)@DEF@\n"

#Update datahead 
for _file in ${input}
do 
  #Replace the first file with the output name, then clear the rest
  _replace_datahead ${_file##*/} "${outname}"
  outname=""
done 

