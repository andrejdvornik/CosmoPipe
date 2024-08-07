#=========================================
#
# File Name : combine_cats.sh
# Created By : awright
# Creation Date : 20-03-2023
# Last Modified : Thu May 23 20:15:33 2024
#
#=========================================


#Get the DATAHEAD filelist 
input="@DB:ALLHEAD@" 

#Remove leading space
if [ "${input:0:1}" == " " ]
then
  input=${input:1}
fi
#Check if there is more than one file in the datahead 
nfile=`echo ${input} | awk '{print NF}'` 
if [ ${nfile} -gt 1 ] 
then 
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
  outname=@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/DATAHEAD/${output:0:${i}}_comb.${ext}

  #Check if input file lengths are ok {{{
  links="FALSE"
  for file in ${input} ${outname}
  do 
    if [ ${#file} -gt 255 ] 
    then 
      links="TRUE"
    fi 
  done 
  
  if [ "${links}" == "TRUE" ] 
  then
    #Remove existing infile links 
    if [ -e infile_$$.lnk ] || [ -h infile_$$.lnk ]
    then 
      rm infile_$$.lnk
    fi 
    #Remove existing outfile links 
    if [ -e outfile_$$.lnk ] || [ -h outfile_$$.lnk ]
    then 
      rm outfile_$$.lnk
    fi
    #Create input link
    originp=${input}
    input=''
    count=0
    for file in ${originp}
    do 
      ((count+=1))
      ln -s ${file} infile_$$_$count.lnk 
      input="${input} infile_$$_$count.lnk"
    done 
    #Create output links 
    ln -s ${outname} outfile_$$.lnk
    origout=${outname}
    outname=outfile_$$.lnk
  fi 
  #}}}
  
  #Combine the DATAHEAD catalogues into one 
  _message "   > @BLU@Constructing combined catalogue @DEF@${outname}@DEF@ "
  @RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacpaste \
    -i ${input} \
    -o ${outname} 2>&1 
  _message " @RED@- Done! (`date +'%a %H:%M'`)@DEF@\n"

  #If using links, replace them {{{
  if [ "${links}" == "TRUE" ] 
  then 
    rm ${input} ${outname}
    input=${originp}
    outname=${origout}
  fi 
  #}}}
  
  
  #Update datahead 
  for _file in ${input}
  do 
    #Replace the first file with the output name, then clear the rest
    _replace_datahead ${_file} "${outname}"
    outname=""
  done 
else 
  _message "   > @BLU@There is only @RED@1 file@BLU@ in the DATAHEAD: @DEF@nothing to do!\n@DEF@"
fi 

