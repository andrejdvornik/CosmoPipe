#=========================================
#
# File Name : equalN_split.sh
# Created By : awright
# Creation Date : 04-07-2023
# Last Modified : Sat 13 Apr 2024 09:34:32 AM CEST
#
#=========================================

#Define the output filename 
input="@DB:DATAHEAD@"
output=${input}
outext=${output##*.}
output=${output//.${outext}/_2dcc.${outext}}

#Calculate and output the 2D cterms 
#Step 1, correct the c's 
@P_RSCRIPT@ @RUNROOT@/@SCRIPTPATH@/correct_2D_cterm.R \
  -i @DB:DATAHEAD@ \
  -v @BV:XNAME@ @BV:YNAME@ \
  -e @BV:E1NAME@ @BV:E2NAME@ \
  -o ${output} 2>&1 

#Remove the original columns 
@RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacdelkey \
  -i @DB:DATAHEAD@ \
  -o @DB:DATAHEAD@_tmp \
  -k @BV:E1NAME@ @BV:E2NAME@ -t OBJECTS 2>&1

#Merge new E1E2 columns 
@RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacjoinkey \
  -i @DB:DATAHEAD@_tmp \
  -p ${output} \
  -o ${output}_tmp \
  -k @BV:E1NAME@ @BV:E2NAME@ c1_2D_mean c2_2D_mean -t OBJECTS 2>&1

mv ${output}_tmp ${output}
rm @DB:DATAHEAD@_tmp

#Update the datahead 
_replace_datahead "${input}" "${output}"

