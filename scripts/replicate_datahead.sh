#=========================================
#
# File Name : replicate_datahead.sh
# Created By : awright
# Creation Date : 25-04-2023
# Last Modified : Wed 15 Nov 2023 10:59:02 PM CET
#
#=========================================

NREPL=@BV:NREPL@
ASLINK=@BV:LINKREPL@ 

for i in `seq ${NREPL}` 
do 
  _message "   > @BLU@Constructing replicate @DEF@#${i}@BLU@ of the DATAHEAD @DEF@"
  for file in @DB:ALLHEAD@ 
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
      rsync -atvL ${file} ${file//.${ext}/_${i}.${ext}}
    fi 
    #Add duplicate to output list 
    outlist="$outlist $ofile"
  done 
  _message " @RED@- Done! (`date +'%a %H:%M'`)@DEF@\n"
done 

_message "   > @BLU@Cleaning DATAHEAD @DEF@"
for file in @DB:ALLHEAD@
do 
  rm -f ${file}
done 
_message " @RED@- Done! (`date +'%a %H:%M'`)@DEF@\n"

_writelist_datahead "${outlist}"

