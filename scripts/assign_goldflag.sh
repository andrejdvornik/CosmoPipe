#=========================================
#
# File Name : assign_goldflag.sh
# Created By : awright
# Creation Date : 22-03-2023
# Last Modified : Wed 22 Mar 2023 04:33:34 PM CET
#
#=========================================


for input in @DB:main_calib_cats@
do 
  #Combine the main_cats catalogues into one 
  @RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacjoinkey \
    -i @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/main_tomo_cats/${input} \
    -p @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/main_calib_cats/${outname} \
    -k SOMweight -t OBJECTS
done 

#Add the new file to the datablock 
_add_datablock main_all ${outname##*/}
