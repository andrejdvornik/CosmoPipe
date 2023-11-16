#=========================================
#
# File Name : match_to_sims.sh
# Created By : awright
# Creation Date : 15-06-2023
# Last Modified : Tue 14 Nov 2023 09:47:07 PM CET
#
#=========================================

#Script to inherit a label from an input catalogue to a target catalogues 
#Get the target catalogues to match from the DATAHEAD 
input="@DB:ALLHEAD@"
ninp=`echo ${input} | awk '{print NF}'`
#Training catalogues are assumed to be in match_base
train="@DB:match_base@"
ntrain=`echo ${train} | awk '{print NF}'`
#Check for more mismatch in training and target catalogues  {{{
if [ ${ntrain} -ne 1 ] && [ ${ntrain} -ne ${ninp} ] && [ ${ninp} -ne 1 ]
then 
  _message "@RED@ ERROR!@DEF@\n"
  _message "@RED@ The provided training catalogue list is length @BLU@${ntrain}@RED@, and@DEF@\n"
  _message "@RED@ the provided target catalogue list is length @BLU@${ninp}@RED@. These @DEF@\n"
  _message "@RED@ should be of the same length, or one should be a single catalogue.@DEF@\n"
  exit 1
elif [ ${ntrain} -ne ${ninp} ]
then 
  if [ ${ntrain} -ne 1 ] 
  then 
    outlist=''
    for i in `seq ${ninp}` 
    do 
      outlist="${outlist} ${train}"
    done
    train="${outlist}"
  elif [ ${ninp} -ne 1 ]
  then 
    outlist=''
    for i in `seq ${ntrain}` 
    do 
      outlist="${outlist} ${input}"
    done
    input="${outlist}"
  fi 
fi 
#}}}
#Update the ntrain value 
ntrain=`echo ${train} | awk '{print NF}'`

#Construct the training-target feature list 
target_features="@BV:DATAFEATURES@"
nfeat_target=`echo ${target_features} | awk '{print NF}'`

#Loop through the catalogues, constructing the matches 
for i in `seq ${ntrain}`
do 
  #Get the current training catalogue 
  current_train=`echo ${train} | awk -v col=${i} '{print $col}'`
  #Get the current target catalogue 
  current_target=`echo ${input} | awk -v col=${i} '{print $col}'`
  #Construct the output filename 
  ext=${current_target##*.}
  output_file=${current_target//.${ext}/_lab.${ext}}

  #If the output file already exists, remove it (pyFITSIO overwrite causes crash)
  if [ -f ${output_file} ] 
  then 
    rm ${output_file}
  fi 
  
  #Notify that we are matching these catalogues 
  _message " > @BLU@Matching label @BV:LABELNAME@ from training catalogue @RED@${current_train##*/}@BLU@ to target catalogue @RED@${current_target##*/}@DEF@"
    @PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/assign_matching_label.py \
       -t ${current_train} \
       -i ${current_target} \
       -o ${output_file} \
       -l @BV:LABELNAME@ \
       -f ${target_features} 

  #Notify 
  _message " @RED@- Done! (`date +'%a %H:%M'`)@DEF@\n"
  #Update the DATAHEAD 
  _replace_datahead "${current_target}" "${output_file}"

done 
  
