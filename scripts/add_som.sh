#
# Add the calibration sample to the data block 
#

#Check that the specz catalogue exists
if [ ! -f @SOMFILE@ ]
then 
  _message "${RED} - ERROR: SOM file @SOMFILE@ does not exist!"
  exit -1 
fi 

#Update the datablock contents file 
_add_datablock som @SOMFILE@

