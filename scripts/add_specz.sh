#
# Add the calibration sample to the data block 
#

#Check that the specz catalogue exists
if [ ! -f @BV:SPECZCAT@ ]
then 
  _message "${RED} - ERROR: specz catalogue @BV:SPECZCAT@ does not exist!"
  exit -1 
fi 

#Update the datablock contents file 
_add_datablock specz_cat @BV:SPECZCAT@

