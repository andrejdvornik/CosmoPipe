#=========================================
#
# File Name : replicate.sh
# Created By : awright
# Creation Date : 25-04-2023
# Last Modified : Wed 28 Feb 2024 10:06:28 AM CET
#
#=========================================

NREPL=@BV:NREPL@
ASLINK=@BV:LINKREPL@

outlist=''
inlist=''
for file in @DB:ALLHEAD@ 
do 
  inlist="$inlist ${file##*/}"
  _message "   > @BLU@Constructing @DEF@${NREPL}@BLU@ replicates for catalogue @DEF@${file##*/}@DEF@ "
  for i in `seq ${NREPL}` 
  do 
    ofile=${file##*/}
    ext=${ofile##*.}
    ofile=${ofile//.${ext}/_${i}.${ext}}
    if [ "${ASLINK^^}" == "TRUE" ]
    then 
      if [ $i -eq 1 ]
      then 
        if [ -f ${file} ] 
        then 
          #Move the file to the new location 
          mv -f ${file} ${file//.${ext}/_${i}.${ext}}
        else 
          #Update the link reference 
          target=`readlink ${file}`
          #Update the target for the new replication 
          linkfile=${target//.${ext}/_1.${ext}}
          linkfile=${linkfile##*/}
          #Create the new link 
          ln -sf ${linkfile} ${file//.${ext}/_${i}.${ext}}
        fi 
      else 
        linkfile=${file//.${ext}/_1.${ext}}
        linkfile=${linkfile##*/}
        ln -sf ${linkfile} ${file//.${ext}/_${i}.${ext}}
      fi 
    else 
      #duplicate the file 
      rsync -atv ${file} ${file//.${ext}/_${i}.${ext}}
    fi 
    #Add duplicate to output list 
    outlist="$outlist $ofile"
  done 
  _message " @RED@- Done! (`date +'%a %H:%M'`)@DEF@\n"
done 
_replace_datahead "${inlist}" "${outlist}"


