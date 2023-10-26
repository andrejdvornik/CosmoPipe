#=========================================
#
# File Name : replicate_datahead.sh
# Created By : awright
# Creation Date : 25-04-2023
# Last Modified : Fri 01 Sep 2023 09:09:14 AM CEST
#
#=========================================

NREPL=@BV:NREPL@

for i in `seq ${NREPL}` 
do 
  _message "   > @BLU@Constructing replicate @DEF@#${i}@BLU@ of the DATAHEAD @DEF@"
  for file in @DB:ALLHEAD@ 
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
done 

_writelist_datahead "${outlist}"

