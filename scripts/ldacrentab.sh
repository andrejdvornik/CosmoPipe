#=========================================
#
# File Name : ldacrentab.sh
# Created By : awright
# Creation Date : 20-03-2023
# Last Modified : Tue 21 Mar 2023 08:46:41 AM CET
#
#=========================================

#Input file name 
input="@DB:DATAHEAD@"

#Get the existing table name 
@RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacdesc -i ${input} > @RUNROOT@/@STORAGEPATH@/rentab.txt 2>&1 
tabname=`grep -A 1 "BINTABLE" @RUNROOT@/@STORAGEPATH@/rentab.txt | tail -1 | awk -F. '{print $NF}'`

#Rename existing table to OBJECTS
@RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacrentab -i ${input} -o ${input}_rentabtmp \
  -t ${tabname} OBJECTS 

#Remove the rentab temporary file 
rm @RUNROOT@/@STORAGEPATH@/rentab.txt

#Rename the output file 
mv ${input}_rentabtmp ${input}

