#=========================================
#
# File Name : make_m_covariance.sh
# Created By : awright
# Creation Date : 30-03-2023
# Last Modified : Thu 01 Jun 2023 05:10:06 PM CEST
#
#=========================================

#m-bias files 
inputs="@DB:mbias@"

#m-biases file
mbias=`echo ${inputs} | awk '{print $1}'`
#m-sigmas file
msigm=`echo ${inputs} | awk '{print $2}'`
#m-correlation files
mcorr=`echo ${inputs} | awk '{print $3}'`

if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcov ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcov
fi 

#Create the m-covariance matrix [NTOMOxNTOMO] 
@PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/make_m_covariance.py \
  --msigm ${msigm} \
  --mcorr ${mcorr} \
  --output "@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcov/m_corr_r" 2>&1

#Add the new files to the block
_write_datablock mcov "m_corr_r.ascii m_corr_r_0p02.ascii m_corr_r_correl.ascii m_corr_r_uncorrelated_inflated.ascii m_corr_r_uncorrelated_inflated_0p02.ascii"

if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_mcov ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_mcov
fi 

cp @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcov/m_corr_r.ascii @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_mcov/m_corr_r.ascii
_write_datablock cosmosis_mcov "m_corr_r.ascii" 

