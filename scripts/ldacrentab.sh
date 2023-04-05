#=========================================
#
# File Name : ldacrentab.sh
# Created By : awright
# Creation Date : 20-03-2023
# Last Modified : Tue Apr  4 17:29:14 2023
#
#=========================================

#Input file name 
input="@DB:DATAHEAD@"

#Get the existing table name 
@RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacdesc -i ${input} > @RUNROOT@/@STORAGEPATH@/rentab.txt 2>&1 
found=`grep -A 1 "BINTABLE" @RUNROOT@/@STORAGEPATH@/rentab.txt | grep -v "BINTABLE" | awk -F. '{print $NF}' | grep -c "OBJECTS" || echo`
if [ "${found}" != "1" ]
then 
  tabname=`grep -A 1 "BINTABLE" @RUNROOT@/@STORAGEPATH@/rentab.txt | grep -v "BINTABLE" | awk -F. '{print $NF}' | grep -v "FIELDS" | tail -1 `
  >&2 echo ${tabname}
  
  if [ "${tabname}" != "OBJECTS" ]
  then 
    #Rename existing table to OBJECTS
    @RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacrentab -i ${input} -o ${input}_rentabtmp \
      -t ${tabname} OBJECTS 
  
    #Remove the rentab temporary file 
    rm @RUNROOT@/@STORAGEPATH@/rentab.txt
  
    #Rename the output file 
    mv ${input}_rentabtmp ${input}
  fi 
fi

