#=========================================
#
# File Name : ldackeepcols.sh
# Created By : awright
# Creation Date : 12-06-2023
# Last Modified : Tue 21 Nov 2023 09:25:53 AM CET
#
#=========================================

#Input catalogue
input=@DB:DATAHEAD@

#Define the output catalogue name 
ext=${input##*.}
output=${input//.${ext}/_calc.${ext}}

#Notify 
_message "@DEF@ > @BLU@Adding @BV:CALCCOLNAME@ using condition @BV:CALCCOND@ to catalogue ${input##*/}@DEF@"

#Check if input file lengths are ok {{{
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
  if [ -e infile.lnk ] || [ -h infile.lnk ]
  then 
    rm infile.lnk
  fi 
  #Remove existing outfile links 
  if [ -e outfile.lnk ] || [ -h outfile.lnk ]
  then 
    rm outfile.lnk
  fi
  #Create input link
  originp=${input}
  ln -s ${input} infile.lnk 
  input="infile.lnk"
  #Create output links 
  ln -s ${output} outfile.lnk
  origout=${output}
  output=outfile.lnk
fi 
#}}}

#Column strings to match to: 
calccond="@BV:CALCCOND@;"
#Column name to add: 
calccol="@BV:CALCCOLNAME@"
calccom="@BV:CALCCOMM@"

#Get the list of all columns 
cols=`@RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacdesc -i ${input} -t OBJECTS 2>&1 | grep "Key name" | sed 's@Key name:\(\.\)\{1,\}@@' || echo `

if [ "${cols}" == "" ] 
then 
  _message "@RED@ - ERROR! Column read using ldacdesc failed! Is this an LDAC catalogue?@DEF@\n"
  _message "${input}\n"
  exit 1 
fi 

#Check if @BV:CALCCOLNAME@ is one of the columns 
colcheck=`echo ${cols} | sed 's/ /\n/g' | grep -ci "${calccol}" || echo `

if [ ${colcheck} -ne 0 ]
then 
  _message "@RED@ - ERROR! Column name to add already exists!@DEF@\n"
  _message "@BLU@columns:@DEF@\n"
  _message "${cols}\n"
  _message "@BLU@ldaccalc colname:@DEF@"
  _message "${calccol}\n"
  exit 1
else 
  #Calculate the new column 
  @RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldaccalc \
    -i ${input} \
    -o ${output} \
    -t OBJECTS \
    -c "${calccond}" \
    -n "${calccol}" "${calccom}" \
    -k FLOAT 2>&1

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

