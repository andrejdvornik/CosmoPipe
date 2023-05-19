#=========================================
#
# File Name : cut_bin_n.sh
# Created By : awright
# Creation Date : 31-03-2023
# Last Modified : Fri 19 May 2023 02:05:46 PM CEST
#
#=========================================

#Number of tomographic bins 
ntomo="@BV:NTOMO@"

#For dropping each bin
for bindrop in `seq ${ntomo}`
do 
  tomostring=''
  nottomostring=''
  for tomo1 in `seq $ntomo` 
  do 
    for tomo2 in `seq ${tomo1} $ntomo` 
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


