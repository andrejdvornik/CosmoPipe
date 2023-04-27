#
# Add the simulated calibration sample to the data block 
#

#If needed, make the gold catalogue folder 
if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/sims_specz/ ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/sims_specz
fi 

#Check that the specz catalogue exists
if [ -d @DB:SIMSPECZCAT@ ]
then 
  filelist=`ls @DB:SIMSPECZCAT@`
elif [ -f @DB:SIMSPECZCAT@ ]
then 
  filelist=@DB:SIMSPECZCAT@
else 
  _message "${RED} - ERROR: simulated specz catalogue @DB:SIMSPECZCAT@ does not exist!"
  exit -1 
fi 

outlist=""
#This just makes sure that the files are added correctly
for file in ${filelist} 
do 
  #Construct the output name {{{
  outname=${file##*/}
  #}}}
  #Save the output file to the list {{{
  outlist="$outlist @DB:SIMSPECZCAT@/$outname"
  #}}}
done 

#Update the datablock contents file 
_add_datablock sims_specz "$outlist"

