#=========================================
#
# File Name : combine_cats.sh
# Created By : awright
# Creation Date : 20-03-2023
# Last Modified : Mon 20 Mar 2023 02:44:17 PM CET
#
#=========================================


#Get the DATAHEAD filelist 
filelist="@DB:ALLHEAD@" 

#Strip out the final catalogue name. This is the output 
outname=${filelist##* }
filelist=${filelist% *}

#Output name 
outname=@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/DATAHEAD/combined_cats.cat 

#Combine the DATAHEAD catalogues into one 
@RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacpaste -i ${filelist} -o ${outname}

#Update datahead 
for _file in ${filelist}
do 
  _replace_datahead ${_file##*/} ""
done 

