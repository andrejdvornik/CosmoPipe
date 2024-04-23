#!/bin/bash

#Set Stop-On-Error {{{
abort()
{
  echo -e "\033[0;31m - !FAILED!" >&2
  echo -e "\033[0;34m An error occured during the create_fixed_param_file.sh step \033[0m" >&2
  echo >&2
  exit 1
}
trap 'abort' 0
set -e 
#}}}

best_fit=$1

n=`wc -l $best_fit | awk '{print $1}'`

param_list=`awk -v n=$n '{if (NR==n-1) print $0}' $best_fit | sed 's/#//g' | sed 's/,//g'`
value_list=`awk -v n=$n '{if (NR==n) print $0}' $best_fit`

echo "data.experiments=['@COSMOPIPELFNAME@']"

i=1
for param in $param_list
do
    case $param in
	"omega_cdm")    kind=cosmo;;
	"ln10^{10}A_s") kind=cosmo;;
	"omega_b")      kind=cosmo;;
	"n_s")          kind=cosmo;;
	"h")            kind=cosmo;;
	"A_IA")         kind=nuisance;;
	"A_bary")       kind=nuisance;;
	"c_min")        kind=cosmo;;
	"eta_0")        kind=nuisance;;
	"dc")           kind=nuisance;;
	"Ac")           kind=nuisance;;
	"D_z1")         kind=nuisance;;
	"D_z2")         kind=nuisance;;
	"D_z3")         kind=nuisance;;
	"D_z4")         kind=nuisance;;
	"D_z5")         kind=nuisance;;
	"dm")           kind=nuisance;;
	"Omega_m")      kind=derived;;
	"sigma8")       kind=derived;;
    esac
    value=`echo $value_list | awk '{print $'$i'}'`
    echo "data.parameters['$param'] = [ $value, $value, $value, 0, 1, '$kind']"
    #grep "data.parameters\['$param'\]" $param_file
    i=$[$i+1]
done

echo "data.cosmo_arguments['Omega_k'] = 0."
echo "data.cosmo_arguments['N_eff'] = 2.0328"
echo "data.cosmo_arguments['N_ncdm'] = 1"
echo "data.cosmo_arguments['m_ncdm'] = 0.06"
echo "data.cosmo_arguments['T_ncdm'] = 0.71611"
echo "data.cosmo_arguments['sBBN file'] = data.path['cosmo']+'/bbn/sBBN.dat'"
echo "data.cosmo_arguments['k_pivot'] = 0.05"
echo "data.write_step=1"

trap : 0
