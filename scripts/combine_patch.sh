#=========================================
#
# File Name : combine_patch.sh
# Created By : awright
# Creation Date : 20-03-2023
# Last Modified : Tue 28 Mar 2023 11:53:35 AM CEST
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
  #add the patch label column 
  @RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacaddkey -i ${cata} -o ${cata}_tmp -t OBJECTS -k PATCH ${patch} string "patch identifier"
  #move the new catalogue to the original name 
  mv ${cata}_tmp ${cata}
done 

#Combine the main_cats catalogues into one 
@RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacpaste -i @DB:main_cats@ -o @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/main_all/${outname}

#Add the new file to the datablock 
_write_datablock main_all ${outname##*/}


