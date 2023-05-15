#=========================================
#
# File Name : ldacrentab.sh
# Created By : awright
# Creation Date : 20-03-2023
# Last Modified : Mon 15 May 2023 10:52:28 AM CEST
#
#=========================================

#Input file name 
input="@DB:DATAHEAD@"

#Notify 
_message "   > @BLU@Checking for FITS table in @DEF@${input##*/}@DEF@ "
#Get the existing table name 
@RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacdesc -i ${input} > @RUNROOT@/@STORAGEPATH@/rentab.txt 2>&1 
_message " @BLU@- @RED@Done! (`date +'%a %H:%M'`)\n@DEF@"
found=`grep -A 1 "BINTABLE" @RUNROOT@/@STORAGEPATH@/rentab.txt | grep -v "BINTABLE" | awk -F. '{print $NF}' | grep -c "OBJECTS" || echo`
if [ "${found}" != "1" ]
then 
  _message "   > @BLU@Checking for name of FITS table in @DEF@${input##*/}@DEF@ "
  tabname=`grep -A 1 "BINTABLE" @RUNROOT@/@STORAGEPATH@/rentab.txt | grep -v "BINTABLE" | awk -F. '{print $NF}' | grep -v "FIELDS" | tail -1 `
  _message " @BLU@- @RED@Done!@BLU@ Table name is @DEF@${tabname}@BLU@ (`date +'%a %H:%M'`)\n@DEF@"
  if [ "${tabname}" != "OBJECTS" ]
  then 
    _message "   > @BLU@Renaming FITS table in @DEF@${input##*/} to @DEF@OBJECTS "
    #Rename existing table to OBJECTS
    @RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacrentab -i ${input} -o ${input}_rentabtmp \
      -t ${tabname} OBJECTS 
  
    #Remove the rentab temporary file 
    rm @RUNROOT@/@STORAGEPATH@/rentab.txt
  
    #Rename the output file 
    mv ${input}_rentabtmp ${input}
    _message " @BLU@- @RED@Done! (`date +'%a %H:%M'`)\n@DEF@"
  fi 
fi

