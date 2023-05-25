#
# Add the calibration sample to the data block 
#

#If needed, make the m_surface folder 
if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/m_surface/ ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/m_surface
fi 

#Check that the main catalogue(s) exists
if [ -d @BV:MSURFACE@ ]
then 
  inputlist=`ls @BV:MSURFACE@`
  filelist=""
  #This just makes sure that the files are added correctly
  for file in ${inputlist} 
  do 
    #Construct the output name {{{
    outname=${file##*/}
    #}}}
    #Save the output file to the list {{{
    filelist="$filelist @BV:MSURFACE@/$outname"
    #}}}
  done 
elif [ -f @BV:MSURFACE@ ]
then 
  filelist=@BV:MSURFACE@
else 
  _message "${RED} - ERROR: simulated main catalogue @BV:MSURFACE@ does not exist!"
  exit -1 
fi 

#Update the datablock contents file 
_add_datablock m_surface "$filelist"
