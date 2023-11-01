#=========================================
#
# File Name : compute_m_bias.sh
# Created By : awright
# Creation Date : 08-05-2023
# Last Modified : Wed 01 Nov 2023 01:51:50 PM CET
#
#=========================================

#For each file in the calib and reference catalogue folders, compute the bias
calib_cats="@DB:som_weight_calib_gold@"
refr_cats="@DB:som_weight_refr_gold@"

#Construct the dz folders, if needed 
if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/nzbias ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/nzbias
fi 
if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/nzcov ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/nzcov
fi 

#Construct the tomographic bin catalogue strings {{{
binstrings=''
NTOMO=`echo @BV:TOMOLIMS@ | awk '{print NF-1}'`
for i in `seq ${NTOMO}`
do
  #Define the Z_B limits from the TOMOLIMS {{{
  ZB_lo=`echo @BV:TOMOLIMS@ | awk -v n=$i '{print $n}'`
  ZB_hi=`echo @BV:TOMOLIMS@ | awk -v n=$i '{print $(n+1)}'`
  #}}}
  #Define the string to append to the file names {{{
  ZB_lo_str=`echo $ZB_lo | sed 's/\./p/g'`
  ZB_hi_str=`echo $ZB_hi | sed 's/\./p/g'`
  appendstr="_ZB${ZB_lo_str}t${ZB_hi_str}"
  #}}}
  binstrings="${binstrings} ${appendstr}"
done
#}}}

if [ "@BV:CALIBWEIGHTNAME@" != "" ] 
then 
  calibweight="-cw @BV:CALIBWEIGHTNAME@"
else 
  calibweight=''
fi 

#Run the Nz bias construction for each bin {{{
@P_RSCRIPT@ @RUNROOT@/@SCRIPTPATH@/compute_dz_priors.R -c ${calib_cats} -r ${refr_cats} \
  --binstrings ${binstrings} \
  ${calibweight} \
  -w @BV:WEIGHTNAME@ \
  --syserr @BV:NZSYSERROR@ \
  -g "SOMweight" \
  -z @BV:ZSPECNAME@ \
  --biasout @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/nzbias/Nz_biases.txt \
  --covout @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/nzcov/Nz_covariance.txt 2>&1
#}}}

#Add the Nzcov file(s) to the datablock 
_write_datablock nzcov "Nz_covariance.txt"
#Add the Nzcov file(s) to the datablock 
_write_datablock nzbias "Nz_biases.txt"



