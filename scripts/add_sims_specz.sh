#
# Add the simulated calibration sample to the data block 
#

#If needed, make the gold catalogue folder 
if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/sims_specz/ ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/sims_specz
fi 

#Check that the specz catalogue exists
if [ -d @BV:SIMSPECZCAT@ ]
then 
  inputlist=`ls @BV:SIMSPECZCAT@`
  filelist=""
  #This just makes sure that the files are added correctly
  for file in ${inputlist} 
  do 
    #Construct the output name {{{
    outname=${file##*/}
    #}}}
    #Save the output file to the list {{{
    filelist="$filelist @BV:SIMSPECZCAT@/$outname"
    #}}}
  done 
elif [ -f @BV:SIMSPECZCAT@ ]
then 
  filelist=@BV:SIMSPECZCAT@
else 
  _message "${RED} - ERROR: simulated specz catalogue @BV:SIMSPECZCAT@ does not exist!"
  exit -1 
fi 

#Update the datablock contents file 
_add_datablock sims_specz "$filelist"

