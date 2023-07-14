#=========================================
#
# File Name : cut_bin_n.sh
# Created By : awright
# Creation Date : 31-03-2023
# Last Modified : Fri 07 Jul 2023 08:07:07 PM CEST
#
#=========================================

#Number of tomographic bins 
NTOMO=`echo @BV:TOMOLIMS@ | awk '{print NF-1}'`

#For dropping each bin
for bindrop in `seq ${NTOMO}`
do 
  tomostring=''
  nottomostring=''
  for tomo1 in `seq $NTOMO` 
  do 
    for tomo2 in `seq ${tomo1} $NTOMO` 
    do 
      if [ $tomo1 -ne $bindrop ] && [ $tomo2 -ne $bindrop ]
      then 
        tomostring="${tomostring} ${tomo1}+${tomo2}"
      else 
        nottomostring="${nottomostring} ${tomo1}+${tomo2}"
      fi 
    done
  done
  
  #Apply the tomostring to the .ini file 
  sed "s/@BINSTRINGONE@/${tomostring}/g" @RUNROOT@/@CONFIGPATH@/run_2cosmo_cosebis_zsplit.ini \
    > @RUNROOT@/@CONFIGPATH@/run_2cosmo_cosebis_zsplit_${bindrop}.ini
  sed -i "s/@BINSTRINGTWO@/${nottomostring}/g" @RUNROOT@/@CONFIGPATH@/run_2cosmo_cosebis_zsplit_${bindrop}.ini 
done 


