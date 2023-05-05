#=========================================
#
# File Name : combine_patch.sh
# Created By : awright
# Creation Date : 20-03-2023
# Last Modified : Fri 05 May 2023 10:19:31 AM CEST
#
#=========================================


#Get the combined catalogue name 
inputcats="@DB:main_cats@"
patches=`echo @PATCHLIST@`

#Select one of the patches
patch=${patches##* }
#Replace the patch variable with the ALLPATCH variable 
match=0
for _file in @DB:main_cats@
do 
  match=`echo ${_file##*/} | grep -c "_${patch}_" || echo`
  if [ "${match}" != "0" ] 
  then 
    outname=`echo ${_file##*/} | sed "s/_${patch}_/_@ALLPATCH@_/"`
    break
  fi 
done 

if [ "${outname}" == "" ] 
then 
  _message "@RED@ - ERROR!\n"
  _message "@RED@Output all-patch catalogue could not be created because\n"
  _message "@RED@the patch label _${patch}_ was not found in the main catalogue names.@DEF@\n"
  exit 1
fi 

if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/main_all ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/main_all
fi 

#Add a patch label to each catalogue (for subsequent patch extraction, if needed)
for cata in @DB:main_cats@
do 
  for patch in ${patches}
  do 
    match=`echo ${cata##*/} | grep -c "_${patch}_" || echo`
    if [ "${match}" != "0" ] 
    then 
      break
    fi 
  done
  #Check if the patch label exists
  cleared=1
  _message "   > @BLU@Testing existence of Patch ID column in @DEF@${cata##*/}@DEF@ "
  @RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldactestexist -i ${cata} -t OBJECTS -k PATCH 2>&1 || cleared=0
  _message " @RED@- Done!@DEF@\n"
  #If exists, delete it 
  if [ "${cleared}" == "1" ] 
  then 
    _message "   > @BLU@Removing existing patch ID key from @DEF@${cata##*/}@DEF@ "
    @RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacdelkey -i ${cata} -o ${cata}_tmp -t OBJECTS -k PATCH 2>&1 
    mv ${cata}_tmp ${cata}
    _message " @RED@- Done!@DEF@\n"
  fi 
  #add the patch label column 
  _message "   > @BLU@Adding patch @DEF@${patch}@BLU@ identification key to @DEF@${cata##*/}@DEF@ "
  @RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacaddkey -i ${cata} -o ${cata}_tmp -t OBJECTS -k PATCH ${patch} string "patch identifier" 2>&1
  #move the new catalogue to the original name 
  mv ${cata}_tmp ${cata}
  _message " @RED@- Done!@DEF@\n"
done 

#Combine the main_cats catalogues into one 
_message "   > @BLU@Constructing patch-combined catalogue @DEF@${outname}@DEF@ "
@RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacpaste -i @DB:main_cats@ -o @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/main_all/${outname} 2>&1 
_message " @RED@- Done!@DEF@\n"

#Add the new file to the datablock 
_write_datablock main_all ${outname##*/}


