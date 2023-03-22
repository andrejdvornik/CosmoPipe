#
# Correct the constant shear bias term for all files in DATAHEAD 
#

#Get the input filename 
current=@DB:DATAHEAD@

#Correct the constant shear term {{{
appendstr="_ccorr"
#Define the output file name 
outputname=${current//.cat/${appendstr}.cat}
#Check if the outputname file exists 
if [ -f ${outputname} ] 
then 
  #If it exists, remove it 
  echo -n "Removing previous catalogue c-corrected catalogue for ${current##*/}"
  rm -f ${outputname}
  echo " - Done!"
fi 
#Construct the output tomographic bin 
echo -n "Constructing c-corrected catalogue for ${current##*/}"
@PYTHON3BIN@/python3 @RUNROOT@/@SCRIPTPATH@/correct_cterm.py \
  -i ${current_file} \
  -o ${outputname} 
echo " - Done!"
#}}}

#Update the datahead {{{
_replace_datahead ${current} ${outputname}
#}}}

