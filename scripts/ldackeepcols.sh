#=========================================
#
# File Name : ldackeepcols.sh
# Created By : awright
# Creation Date : 12-06-2023
# Last Modified : Thu 10 Aug 2023 07:42:07 AM CEST
#
#=========================================

#Input catalogue
input=@DB:DATAHEAD@

#Define the output catalogue name 
ext=${input##*.}
output=${input//.${ext}/_rmcol.${ext}}

#Notify 
_message "@DEF@ > @BLU@Keeping only desired columns in catalogue ${input##*/}@DEF@"

#Check if input file lengths are ok 
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
  #Create input link
  originp=${input}
  ln -s ${input} infile.lnk 
  input="infile.lnk"
  #Create output links 
  ln -s ${output} outfile.lnk
  origout=${output}
  output=outfile.lnk
fi 

#Column strings to match to: 
keepstr="@BV:KEEPSTRINGS@"
#Convert the string gaps into "or"
keepstr="${keepstr// /\\|}"

#Get the list of all columns 
cols=`@RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacdesc -i ${input} -t OBJECTS 2>&1 | grep "Key name" | sed 's@Key name:\(\.\)\{1,\}@@' || echo `

if [ "${cols}" == "" ] 
then 
  _message "@RED@ - ERROR! Column read using ldacdesc failed! Is this an LDAC catalogue?@DEF@\n"
  _message "${input}\n"
  exit 1 
fi 

#Select the columns to remove 
delcols=`echo ${cols} | sed 's/ /\n/g' | grep -iv "${keepstr}" || echo `

if [ "${delcols}" == "${cols}" ]
then 
  _message "@RED@ - ERROR! Deletion would remove all columns?!@DEF@\n"
  _message "@BLU@columns:@DEF@\n"
  _message "${cols}\n"
  _message "@BLU@delete cols:@DEF@"
  _message "${delcols}\n"
  _message "@BLU@keep strings:@DEF@\n"
  _message "${keepstr}"
  exit 1
elif [ "${delcols}" == "" ] 
then 
  _message "@RED@ - Skip! There is nothing to delete!@DEF@\n"
else 
  #Remove the columns 
  @RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacdelkey -i ${input} -o ${output} -t OBJECTS -k ${delcols} 2>&1

  _message "@BLU@ - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"
  
  if [ "${links}" == "TRUE" ] 
  then 
    rm ${input} ${output}
    input=${originp}
    output=${origout}
  fi 
  
  #Update the datahead
  _replace_datahead "${input##*/}" "${output##*/}"
fi 

