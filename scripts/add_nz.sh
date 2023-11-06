#=========================================
#
# File Name : add_nz.sh
# Created By : awright
# Creation Date : 22-03-2023
# Last Modified : Fri 03 Nov 2023 09:49:58 PM CET
#
#=========================================

#Construct the nz folder, if needed 
if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/nz ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/nz
fi 

#Check that the Nz file(s) exists
if [ -d "@NZPATH@" ]
then 
  _message " > @BLU@ Nz Path is a directory: assuming that @DEF@\`ls\`@BLU@ ordering is tomographic order!@DEF@\n"
  #we have a directory {{{
  inputlist=`ls @NZPATH@`
  filelist=""
  #This just makes sure that the files are added correctly
  for file in ${inputlist} 
  do 
    #Construct the output name {{{
    inpname=${file##*/}
    #}}}
    _message " --> @BLU@ ${inpname}@DEF@\n"
    #Save the output file to the list {{{
    filelist="$filelist @NZPATH@/$inpname"
    #}}}
  done 
  #}}}
elif [ -f "@NZPATH@" ]
then 
  #we have a single file {{{
  _message " > @BLU@ Nz Path is a single file: @DEF@@NZPATH@\n"
  filelist=@NZPATH@
  #}}}
else 
  _message " > @BLU@ Nz Path is a file list:@DEF@\n"
  #we have a file list {{{
  filelist=""
  for inp in @NZPATH@
  do 
    _message " --> @BLU@ ${inp}@DEF@\n"
    if [ ! -f ${inp} ]
    then 
     _message "${RED} - ERROR: Nz file ${inp} does not exist!"
      exit -1 
    fi 
    filelist="${filelist} ${inp}"
  done 
  #}}}
fi 

#Define the Nz names expected by the pipeline
outlist=""
baseblock=`_read_datablock @BV:NZNAME_BASEBLOCK@`
basenames=`_blockentry_to_filelist ${baseblock}`
if [ "${basenames}" == "" ] 
then 
  for input in ${filelist}
  do 
    outlist="${outlist} ${input##*/}"
  done 
else 
  for input in ${basenames}
  do 
    #Define the output filename 
    output=${input%%_DIRsom*}
    if [ "${output}" == "${input}" ] 
    then 
      #We are not using raw calibration catalogues 
      output=${input%.*}
    fi 
    #Add the Nz file suffice
    output=${output}@NZFILESUFFIX@
    output=${output##*/}
    outlist="${outlist} ${output}"
  done
fi 
#Add the Nz file(s) to the datablock, using the correct naming {{{
nfile=`echo ${outlist} | awk '{print NF}'`
newoutlist=''
for i in `seq ${nfile}`
do 
  #File to transfer 
  fromfile=`echo ${filelist} | awk -v n=${i} '{print $n}'`
  fromext=${fromfile##*.}
  #Name of destination file 
  tofile=`echo ${outlist} | awk -v n=${i} '{print $n}'`
  toext=${tofile##*.}
  #Check extensions match 
  if [ "${fromext}" != "${toext}" ]
  then 
    #If not, change the tofile extension to .${fromext}
    tofile=${tofile%.${toext}}.${fromext}
  fi 
  #Notify 
  _message " > @BLU@ Writing Nz file to block:@DEF@\n"
  _message "${fromfile##*/}@BLU@ -> @DEF@${tofile##*/}\n"
  #Copy 
  rsync -autv ${fromfile} @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/nz/${tofile}
  newoutlist="${newoutlist} ${tofile}"
done 
#}}}

#Add files to datablock list 
_write_datablock nz "${newoutlist}"

