#=========================================
#
# File Name : replicate.sh
# Created By : awright
# Creation Date : 25-04-2023
# Last Modified : Fri 28 Jul 2023 12:17:09 PM CEST
#
#=========================================

NREPL=@BV:NREPL@

for file in @DB:ALLHEAD@ 
do 
  outlist=''
  for i in `seq ${NREPL}` 
  do 
    ofile=${file##*/}
    ext=${ofile##*.}
    ofile=${ofile//.${ext}/_${i}.${ext}}
    #duplicate the file 
    rsync -atvL ${file} ${file//.${ext}/_${i}.${ext}}
    #Add duplicate to output list 
    outlist="$outlist $ofile"
  done 
  _replace_datahead "${file}" "${outlist}"
done 


