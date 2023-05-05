#!/bin/bash
# wrapper script for covariance calculation

#Set Stop-On-Error {{{
abort()
{
  echo -e "\033[0;31m - !FAILED!" >&2
  echo -e "\033[0;34m An error occured during the run_covariance.sh step \033[0m" >&2
  echo >&2
  exit 1
}
trap 'abort' 0
set -e 
#}}}

#Create progress function 
progressupdate()
{
  _file=$1
  _pid=$! # Process Id of the previous running command
  _i=0
  while kill -0 $_pid 2>/dev/null 1>&2 
  do
    _i=$(( (_i+1) %4 ))
    if [ ! -f $_file ] 
    then 
      printf "Waiting for output file (loop $_i)...\r"
    else 
      _line=`grep -v ^$ $_file | tail -1 ` 
      if [ "$_line" == "" ]
      then 
        printf "Processing (loop $_i)...\r"
      else
        printf "$_line\r"
      fi 
    fi 
    sleep 10
  done
  wait $_pid 
  return $?
}

### settings

# cosmology
omf=0.2905
ovf=0.7095      
sif=0.826
huf=0.6898
nsf=0.969
obf=0.0473
w0f=-1.00
waf=0.00

# binnings
ZBLIMS="@TOMOLIMS@"
NTOMO=`echo @TOMOLIMS@ | awk '{print NF-1}'`     # no. of redshift bins
zstep=@NZSTEP@  # z step size in p(z) file
nt=@NTHETABINCOV@     # no. of angular bins
tbmin=@THETAMINCOV@   # min. angular bin boundary [arcmin]
tbmax=@THETAMAXCOV@   # max. angular bin boundary [arcmin]

# files and paths
run_ident=@RUNID@
input_path=@RUNROOT@/@STORAGEPATH@/covariance/input/
result_path=@RUNROOT@/@STORAGEPATH@/covariance/output/
dens_eps_file=$input_path/@SURVEY@_neff_sigmae.txt
angular_bin_file=TC_@SURVEY@_@ALLPATCH@_@FILEBODY@@FILESUFFIX@_xi_e1cor_e2cor_A_tomo_1_1_logbin.dat
mask_file=@RUNROOT@/@STORAGEPATH@/@MASKFILE@

# covariance settings
do_cov=1    # 1: calculate covariance; 0: skip calculation
cov_ssc=1   # 1: include; 0: switch off
cov_ng=1
cov_g=1
use_actual_pairs=1   # 1: use actual galaxy pairs for shape noise; 0: use expectation value

### CODE ###

### internal settings
home=@RUNROOT@/@STORAGEPATH@/covariance/
repo_path=@RUNROOT@/@SCRIPTPATH@/CosmoFisherForecast/ #/home/joachimi/coderepo/
zfromfile=1
zmin=0.0
zfile=${input_path}/@NZFILEID@comb@NZFILESUFFIX@
binlist=""  # unused
nonlinfit=TAK12
transferfunc=EHW
hmf_type=T10
flag_2h=1  # use 2h term in trispectrum     
nl=1  # unused
lmin=1.  # unused
lmax=1.  # unused
cov_space=1  # use real space covariance
printzpg=1
export THPS_LINLOG=from_file   # read binning from file
export THPS_COV_INVERSE=yes    # calculate inverse  

### prepare p(z) files
cd $input_path

zshift=`awk 'BEGIN{ print '${zstep}'/2. }'`
echo "" > ${input_path}/@NZFILEID@comb@NZFILESUFFIX@

for i in `seq $NTOMO` 
do
  awk 'BEGIN{ printf "%15.10f\t%15.10f\n", 0.0,0.0 }; { printf "%15.10f\t%15.10f\n", $1+'${zshift}',$2 }; END{ printf "%15.10f\t%15.10f\n", $1+'${zstep}',0.0 }' ${input_path}/@NZFILEID@${i}@NZFILESUFFIX@ > ${input_path}/@NZFILEID@${i}_sorted@NZFILESUFFIX@
  paste ${input_path}/@NZFILEID@comb@NZFILESUFFIX@ ${input_path}/@NZFILEID@${i}_sorted@NZFILESUFFIX@ > ${input_path}/@NZFILEID@comb@NZFILESUFFIX@.tmp
  mv ${input_path}/@NZFILEID@comb@NZFILESUFFIX@.tmp ${input_path}/@NZFILEID@comb@NZFILESUFFIX@
done

awk '{ printf "%15.10f\t", $1; for (i=2;i<=2*'${NTOMO}';i+=2) printf "%15.10f\t", $i; printf "\n" }' ${input_path}/@NZFILEID@comb@NZFILESUFFIX@ > ${input_path}/@NZFILEID@comb@NZFILESUFFIX@.tmp
mv ${input_path}/@NZFILEID@comb@NZFILESUFFIX@.tmp ${input_path}/@NZFILEID@comb@NZFILESUFFIX@

zmax=`awk 'END{ print $1 }' ${input_path}/@NZFILEID@comb@NZFILESUFFIX@`

### prepare n_dens and sigma_eps files

awk '{ if ((NR>1)&&(NR<='${NTOMO}'+1)) printf "%15.10f\t%15.10f\n", $4, $4 }' $dens_eps_file > ${result_path}/@SURVEY@_ndens_${run_ident}.dat
awk '{ if ((NR>1)&&(NR<='${NTOMO}'+1)) printf "%15.10f\n", sqrt($7^2+$8^2) }' $dens_eps_file > ${result_path}/@SURVEY@_sigmaeps_${run_ident}.dat

if [ -s ${result_path}/thps_cov_${run_ident}_ndens.dat ] 
then 
  rm -f ${result_path}/thps_cov_${run_ident}_ndens.dat
fi 
ln -s ${result_path}/@SURVEY@_ndens_${run_ident}.dat ${result_path}/thps_cov_${run_ident}_ndens.dat

if [ -s ${result_path}/thps_cov_${run_ident}_sigma_sq.dat ] 
then 
  rm -f ${result_path}/thps_cov_${run_ident}_sigma_sq.dat
fi 
ln -s ${result_path}/@SURVEY@_sigmaeps_${run_ident}.dat ${result_path}/thps_cov_${run_ident}_sigma_sq.dat

### prepare angular binning files

tstep=`awk 'BEGIN{ print (log('${tbmax}')-log('${tbmin}'))/'${nt}' }'`

awk 'BEGIN{ for (i=1;i<='${nt}';i++) printf "%15.10e\t%15.10e\n",'${tbmin}'*(exp(i*'${tstep}')+exp((i-1)*'${tstep}'))/2.,'${tbmin}'*(exp(i*'${tstep}')-exp((i-1)*'${tstep}')) }' > ${result_path}/thps_cov_binning_angular_${run_ident}.dat  # all in arcmin; uses arithmetic mean

tmin=`awk 'BEGIN{ print '${tbmin}'*exp('${tstep}'/2.) }'`
tmax=`awk 'BEGIN{ print '${tbmax}'*exp((-1.)*'${tstep}'/2.) }'`

### prepare survey window files

if [ -s ${result_path}/survey_window_alm_${run_ident}.dat ]
then
  echo "Re-use survey window alm file:"
  echo "  > ${result_path}/survey_window_alm_${run_ident}.dat"

else 
  echo -n "Calculating survey window function"
  ${repo_path}/covariances/survey_window/windowL ${mask_file} ${result_path}/survey_window_alm_${run_ident}.dat ${result_path}/survey_window_area_${run_ident}.dat > ${result_path}/survey_window_area_${run_ident}.log 2>&1 
fi

area=`awk '{ if ($1!="#") print $1 }' ${result_path}/survey_window_area_${run_ident}.dat`

echo -e " - Done!"
echo "Use effective area for survey:" $area

cp ${result_path}/survey_window_alm_${run_ident}.dat ${result_path}/thps_cov_${run_ident}_alms.dat
awk '{ if (NR==2) print $0 }' ${result_path}/survey_window_area_${run_ident}.dat > ${result_path}/thps_cov_${run_ident}_alms_area.dat

### prepare galaxy pair count files
if [ $use_actual_pairs -eq 1 ]
then
  echo -ne "Calculating galaxy pair counts "
  ngal_raw=`awk '{ if ($1!="#") printf "%s,", $3 }' ${dens_eps_file}`  # read raw galaxy number per tomo bin

  ndens_ratio=`awk -v var="$ngal_raw" 'BEGIN{ split(var,array,",") }; { printf "%g,", $1/(array[NR]/('${area}'*3600.)) }' ${result_path}/thps_cov_${run_ident}_ndens.dat`  # ratio of weighted number density over raw number density
  ndens_ratio_array=(${ndens_ratio//,/ })
  ndens_ratio_array_length=${#ndens_ratio_array[*]}
  if [ "$ndens_ratio_array_length" != "$NTOMO" ]
  then
      echo "Error: incorrect number of entries in variable ndens_ratio."
      exit -1
  fi

  echo "" > ${input_path}/ndens_reweighting_${run_ident}.dat
  for (( i=0; i<${ndens_ratio_array_length}; i++ ))
  do
    printf "%15.10g\n" ${ndens_ratio_array[i]} >> ${input_path}/ndens_reweighting_${run_ident}.dat
  done

  echo "" > ${result_path}/thps_cov_${run_ident}_npair.dat

  for ZBIN1 in `seq $NTOMO`
  do
    Z_B_low=`echo $ZBLIMS | awk -v n=$ZBIN1 '{print $n}'`
    Z_B_high=`echo $ZBLIMS | awk -v n=$ZBIN1 '{print $(n+1)}'`
    Z_B_low_str=`echo $Z_B_low | sed 's/\./p/g'`
    Z_B_high_str=`echo $Z_B_high | sed 's/\./p/g'`

    for ZBIN2 in `seq $ZBIN1 $NTOMO`
    do
      Z_B_low2=`echo $ZBLIMS | awk -v n=$ZBIN2 '{print $n}'`
      Z_B_high2=`echo $ZBLIMS | awk -v n=$ZBIN2 '{print $(n+1)}'`
      Z_B_low_str2=`echo $Z_B_low2 | sed 's/\./p/g'`
      Z_B_high_str2=`echo $Z_B_high2 | sed 's/\./p/g'`
      echo "" > ${input_path}/npair_tot_ZB${Z_B_low_str}t${Z_B_high_str}_ZB${Z_B_low_str2}t${Z_B_high_str2}.dat

      for patch in @PATCHLIST@ 
      do
        awk '{ if ($1!="#" && $1!="##") print $11 }' \
          ${input_path}/@SURVEY@_${patch}_@FILEBODY@@FILESUFFIX@_filt_ZB${Z_B_low_str}t${Z_B_high_str}_ZB${Z_B_low_str2}t${Z_B_high_str2}_ggcorr.out > ${input_path}/tmp.dat
	      paste ${input_path}/npair_tot_ZB${Z_B_low_str}t${Z_B_high_str}_ZB${Z_B_low_str2}t${Z_B_high_str2}.dat \
          ${input_path}/tmp.dat > ${input_path}/tmp2.dat
	      mv ${input_path}/tmp2.dat \
          ${input_path}/npair_tot_ZB${Z_B_low_str}t${Z_B_high_str}_ZB${Z_B_low_str2}t${Z_B_high_str2}.dat
      done

      awk -v ratio1="${ndens_ratio_array[ZBIN1-1]}" -v ratio2="${ndens_ratio_array[ZBIN2-1]}" \
        '{ sum=0.0; for(i=1;i<=NF;i++) sum+=$i; print sum*ratio1*ratio2 }' \
        ${input_path}/npair_tot_ZB${Z_B_low_str}t${Z_B_high_str}_ZB${Z_B_low_str2}t${Z_B_high_str2}.dat \
        > ${input_path}/tmp2.dat # includes correction for weighted galaxy counts
      mv ${input_path}/tmp2.dat \
         ${input_path}/npair_tot_ZB${Z_B_low_str}t${Z_B_high_str}_ZB${Z_B_low_str2}t${Z_B_high_str2}.dat

      paste ${result_path}/thps_cov_${run_ident}_npair.dat \
        ${input_path}/npair_tot_ZB${Z_B_low_str}t${Z_B_high_str}_ZB${Z_B_low_str2}t${Z_B_high_str2}.dat \
        > ${input_path}/tmp.dat
      mv ${input_path}/tmp.dat ${result_path}/thps_cov_${run_ident}_npair.dat
    done
  done
  echo -e " - Done! "
  rm -f ${input_path}/tmp*.dat
else
  rm -f ${result_path}/thps_cov_${run_ident}_npair.dat
fi

### create parameter files

run_ident_noise=noise

cp ${repo_path}/psvareos/proc/thps.param ${result_path}/

awk '{
 if (/Omega_m/) print "Omega_m			'${omf}'"
 else if (/Omega_v/) print "Omega_v			'${ovf}'"
 else if (/w_0/) print "w_0            	    '${w0f}'"
 else if (/w_a/) print "w_a			     '${waf}'"
 else if (/Omega_b/) print "Omega_b			'${obf}'"
 else if (/h_100/) print "h_100			'${huf}'"
 else if (/sigma_8/) print "sigma_8			'${sif}'"
 else if (/n_spec/) print "n_spec			'${nsf}'"
 else if (/bg_zdistr_zmin/) print "bg_zdistr_zmin          '${zmin}'"
 else if (/bg_zdistr_zmax/) print "bg_zdistr_zmax         '${zmax}'"
 else if (/bg_zdistr_file/) print "bg_zdistr_file         '${zfromfile}'"
 else if (/bg_zdistr_zfile/) print "bg_zdistr_zfile         '${zfile}'"
 else if (/method/) print "method           '${nonlinfit}'"
 else if (/transferfunc/) print "transferfunc     '${transferfunc}'"
 else if (/outp_path/) print "outp_path		'${result_path}'"
 else if (/tomo_nbin/) print "tomo_nbin		'${NTOMO}'"
 else if (/tomo_id/) print "tomo_id		'${run_ident}'"	
 else if (/tomo_bins/) print "tomo_bins               '${binlist}'"
 else if (/tomo_nlbin/) print "tomo_nlbin              '${nl}'"
 else if (/tomo_lmin/) print "tomo_lmin               '${lmin}'"
 else if (/tomo_lmax/) print "tomo_lmax               '${lmax}'"
 else if (/tomo_real/) print "tomo_real               '${cov_space}'"
 else if (/tomo_ntbin/) print "tomo_ntbin               '${nt}'"
 else if (/tomo_tmin/) print "tomo_tmin               '${tbmin}'"
 else if (/tomo_tmax/) print "tomo_tmax               '${tbmax}'"
 else if (/tomo_print/) print "tomo_print              '${printzpg}'"
 else if (/A_survey/) print "A_survey               '${area}'"
 else if (/halo_massfunc_type/) print "halo_massfunc_type         '${hmf_type}'"
 else if (/halo_use_2h/) print "halo_use_2h               '${flag_2h}'"      
 else print $0
}' ${result_path}/thps.param > ${result_path}/thps_@SURVEY@_${run_ident}.param
rm -f ${result_path}/thps.param

awk '{  
 if (/tomo_id/) print "tomo_id          '${run_ident_noise}'"  
 else print $0
}' ${result_path}/thps_@SURVEY@_${run_ident}.param > ${result_path}/thps_@SURVEY@_${run_ident_noise}.param

cp ${result_path}/thps_cov_${run_ident}_ndens.dat ${result_path}/thps_cov_${run_ident_noise}_ndens.dat
if [ $use_actual_pairs -eq 1 ]
then
  cp ${result_path}/thps_cov_${run_ident}_npair.dat ${result_path}/thps_cov_${run_ident_noise}_npair.dat
else
  rm -f ${result_path}/thps_cov_${run_ident_noise}_npair.dat
fi
cp ${result_path}/thps_cov_${run_ident}_sigma_sq.dat ${result_path}/thps_cov_${run_ident_noise}_sigma_sq.dat
cp ${result_path}/thps_cov_binning_angular_${run_ident}.dat ${result_path}/thps_cov_binning_angular_${run_ident_noise}.dat
cp ${result_path}/thps_cov_${run_ident}_alms.dat ${result_path}/thps_cov_${run_ident_noise}_alms.dat
cp ${result_path}/thps_cov_${run_ident}_alms_area.dat ${result_path}/thps_cov_${run_ident_noise}_alms_area.dat


awk '{  
 if (/tomo_tmin/) print "tomo_tmin               '${tmin}'"
 else if (/tomo_tmax/) print "tomo_tmax               '${tmax}'"
 else print $0
}' ${result_path}/thps_@SURVEY@_${run_ident}.param > ${result_path}/thps_@SURVEY@_${run_ident}_xi.param



### create fiducial corelation functions
home=`pwd`
cd ${repo_path}/psvareos/proc/
echo -n "Creating Fiducial corellation functions"
./thps_tomo ${result_path}/thps_@SURVEY@_${run_ident}_xi.param > @RUNROOT@/@STORAGEPATH@/covariance/thps_tomo_@SURVEY@_${run_ident}_xi.log 2>&1 
echo -e " - Done!"
cd $home

### run covariance calculation
if [ $do_cov -eq 1 ]
then
  echo "Creating full covariance {"
  cd ${repo_path}/psvareos/proc
  # run with hard-coded lensing xi covariance
  ./thps_cov ${result_path}/thps_@SURVEY@_${run_ident}.param \
    $cov_ssc $cov_ng $cov_g 0 0 1 0 1 0  #> @RUNROOT@/@STORAGEPATH@/covariance/thps_cov_@SURVEY@_${run_ident}.log 2>&1 & 
  #progressupdate @RUNROOT@/@STORAGEPATH@/covariance/thps_cov_@SURVEY@_${run_ident}.log 
  echo "\n} - Done!"
  echo "Creating shape noise only covariance {"
  # run with additional shape noise only covariance 
  ./thps_cov ${result_path}/thps_@SURVEY@_${run_ident_noise}.param \
    0 0 1 0 0 1 0 1 2  #> @RUNROOT@/@STORAGEPATH@/covariance/thps_cov_@SURVEY@_${run_ident_noise}.log 2>&1 & 
  #progressupdate @RUNROOT@/@STORAGEPATH@/covariance/thps_cov_@SURVEY@_${run_ident_noise}.log 
  echo "} - Done!"
  cd $home
else
  echo "Skip calculation of covariance."
fi

### post-processing

if [ -s ${result_path}/thps_cov_${run_ident}_list.dat ]
then
  awk '{ if (($1!="")&&($1==$7)&&($2==$8)&&($5==$11)&&($6==$12)) print $0 }' ${result_path}/thps_cov_${run_ident}_list.dat > ${result_path}/thps_cov_${run_ident}_list_diag.dat   # get diagonal entries only
fi

if [ -s ${result_path}/thps_cov_${run_ident_noise}_list.dat ]
then
  awk '{ if (($1!="")&&($1==$7)&&($2==$8)&&($5==$11)&&($6==$12)) print $0 }' ${result_path}/thps_cov_${run_ident_noise}_list.dat > ${result_path}/thps_cov_${run_ident_noise}_list_diag.dat   # get diagonal entries only
fi

if ([ $cov_ssc -eq 1 ] || [ $cov_ng -eq 1 ]) && [ $cov_g -eq 1 ]
then
  nc=2
else
  nc=1
fi

#make resort_cov
#./resort_cov $nt $NTOMO $nc ${result_path} ${run_ident}  # make results CosmoMC compatible

cat $0 > ${result_path}/thps_cov_${run_ident}.log

cd ${result_path}

tar cvfz @SURVEY@_cov_results_${run_ident}.tar.gz thps_cov_${run_ident}_list.dat \
  thps_cov_${run_ident}_noise_list.dat xi_p_${run_ident}.dat xi_m_${run_ident}.dat \
  thps_cov_${run_ident}.log > tarball_creation.log 2>&1 || echo "Results tarball creation failed, a file must be missing..."

echo "Finished: run_covariance."
trap : 0
