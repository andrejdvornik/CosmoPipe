#=========================================
#
# File Name : ldackeepcols.sh
# Created By : awright
# Creation Date : 12-06-2023
# Last Modified : Tue 26 Mar 2024 02:45:12 AM CET
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
for file in ${input} ${output}
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
  ln -s ${input} infile_$$.lnk 
  input="infile_$$.lnk"
  #Create output links 
  ln -s ${output} outfile_$$.lnk
  origout=${output}
  output=outfile_$$.lnk
fi 

#Column strings to match to: 
keepstr="@BV:KEEPSTRINGS@"
#Convert the string gaps into "or"
keepstr="${keepstr// /\\|}"

#Get the list of all columns 
cols=`@RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacdesc -i ${input} -t OBJECTS 2>/dev/null | grep "Key name" | sed 's@Key name:\(\.\)\{1,\}@@' || echo `

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
  _replace_datahead "${input}" "${output}"
fi 

