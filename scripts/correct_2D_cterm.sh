#=========================================
#
# File Name : equalN_split.sh
# Created By : awright
# Creation Date : 04-07-2023
# Last Modified : Mon 13 May 2024 09:22:46 PM CEST
#
#=========================================

#Define the output filename 
input="@DB:DATAHEAD@"
output=${input}
outext=${output##*.}
output=${output//.${outext}/_2dcc.${outext}}

#Check whether we need to use links 
links="FALSE"
for file in ${input} ${output}
do 
  if [ ${#file} -gt 250 ] 
  then 
    links="TRUE"
  fi 
done 

if [ "${links}" == "TRUE" ] 
then
  #Remove existing infile links 
  if [ -e infile_$$.lnk.${outext} ] || [ -h infile_$$.lnk.${outext} ]
  then 
    rm -f infile_$$.lnk.${outext}
  fi 
  #Remove existing outfile links 
  if [ -e outfile_$$.lnk.${outext} ] || [ -h outfile_$$.lnk.${outext} ]
  then 
    rm -f outfile_$$.lnk.${outext}
  fi
  #Create input link
  originp=${input}
  ln -s ${input} infile_$$.lnk.${outext} 
  input="infile_$$.lnk.${outext}"
  #Create output links 
  ln -s ${output} outfile_$$.lnk.${outext}
  origout=${output}
  output=outfile_$$.lnk.${outext}
fi 

#Calculate and output the 2D cterms 
#Step 1, correct the c's 
_message " >@BLU@ File ${input%%*/} {\n"
_message "  Using {e1,e2} = {@DEF@@BV:E1NAME@@BLU@,@DEF@@BV:E2NAME@@BLU@}\n"
_message "        { x, y} = {@DEF@@BV:XNAME@@BLU@,@DEF@@BV:YNAME@@BLU@}\n"
_message "             {w}= {@DEF@@BV:WEIGHTNAME@@BLU@}\n"
@P_RSCRIPT@ @RUNROOT@/@SCRIPTPATH@/correct_2D_cterm_wtd.R \
  -i ${input} \
  -v @BV:XNAME@ @BV:YNAME@ \
  -e @BV:E1NAME@ @BV:E2NAME@ \
  -w @BV:WEIGHTNAME@ \
  -o ${output} 2>&1 

objstr=''
{
@RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldactestexist -i ${input} -t OBJECTS -k c1_2D_mean 2>&1 && objstr="" || objstr="FAIL"
} >&1

_message "  > @BLU@Removing previous {e1,e2} columns@DEF@"
if [ "${objstr}" == "" ] 
then 
  #Remove the original columns 
  @RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacdelkey \
    -i ${input} \
    -o ${input}_tmp \
    -k @BV:E1NAME@ @BV:E2NAME@ c1_2D_mean c2_2D_mean -t OBJECTS 2>&1

else 
  #Remove the original columns 
  @RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacdelkey \
    -i ${input} \
    -o ${input}_tmp \
    -k @BV:E1NAME@ @BV:E2NAME@ -t OBJECTS 2>&1
fi 
_message "@RED@ - Done\n"
_message "  > @BLU@Merging corrected {e1,e2} and {c1,c2} columns@DEF@"
#Merge new E1E2 columns 
@RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacjoinkey \
  -i ${input}_tmp \
  -p ${output} \
  -o ${output}_tmp \
  -k @BV:E1NAME@ @BV:E2NAME@ c1_2D_mean c2_2D_mean -t OBJECTS 2>&1
_message "@RED@ - Done\n"

if [ "${links}" == "TRUE" ] 
then 
  #Move the output file to the original name/location
  mv ${output}_tmp ${origout}
  #remove temporary files 
  rm -f ${input}_tmp 
  #remove links 
  rm -f ${input} ${output}
  #Reset input and output variables
  input=${originp}
  output=${origout}
else 
  #Move the temporary output file to the original name/location
  mv ${output}_tmp ${output}
  #remove temporary files 
  rm -f ${input}_tmp 
fi 

#Update the datahead 
_replace_datahead "${input}" "${output}"

