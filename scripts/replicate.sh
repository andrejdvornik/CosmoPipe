#=========================================
#
# File Name : replicate.sh
# Created By : awright
# Creation Date : 25-04-2023
# Last Modified : Fri 01 Sep 2023 09:10:15 AM CEST
#
#=========================================

NREPL=@BV:NREPL@

for file in @DB:ALLHEAD@ 
do 
  outlist=''
  _message "   > @BLU@Constructing @DEF@${NREPL}@BLU@ replicates for catalogue @DEF@${file##*/}@DEF@ "
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
  _message " @RED@- Done! (`date +'%a %H:%M'`)@DEF@\n"
  _replace_datahead "${file}" "${outlist}"
done 


