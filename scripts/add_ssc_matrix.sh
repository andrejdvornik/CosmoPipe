#=========================================
#
# File Name : add_ssc_matrix.sh
# Created By : awright
# Creation Date : 30-03-2023
# Last Modified : Fri 31 Mar 2023 08:46:59 PM CEST
#
#=========================================


if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs
fi 

#Add the SSC matrix to the cosmosis inputs folder 
cp @SSCMATRIX@ @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/thps_ssc_matrix.txt 
#Add the SSC ell vector to the cosmosis inputs folder 
cp @SSCELLVEC@ @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/thps_ssc_matrix_ell_vec.txt 


