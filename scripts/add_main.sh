#
# Add the main samples to the data block 
#

# Construct the list of data files 
inplist=''
for patch in @BV:PATCHLIST@
do 
  file=`ls @BV:PATCHPATH@/*_${patch}_*`
  if [ "${file}" == "" ] || [ ! -f ${file} ]
  then 
    _message "@RED@ERROR!\n@DEF@There is no catalogue in the PATCHPATH with the patch designation ${patch}!"
    exit 1 
  fi 
  inplist="$inplist ${file}"
done 

# Update the datablock contents file 
_add_datablock main_cats "`echo $inplist`"

