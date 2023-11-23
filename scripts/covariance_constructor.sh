#=========================================
#
# File Name : covariance_constructor.sh
# Created By : awright
# Creation Date : 14-04-2023
# Last Modified : Fri 10 Nov 2023 04:02:25 PM CET
#
#=========================================

#Script to generate a covariance .ini

#Create the covariance_inputs directory
if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs/
fi 
#Create the mixterm directory
if [ "@BV:MIXTERM@" == "True" ]
then 
  if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs/mixterm/triplets ]
  then 
    mkdir -p @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs/mixterm/triplets/
  fi 
fi

# Infer statistic {{{
STATISTIC="@BV:STATISTIC@"
SECONDSTATISTIC="@BV:SECONDSTATISTIC@"
if [ "${STATISTIC^^}" == "XIPM" ]
then
est_shear=xi_pm
elif [ "${STATISTIC^^}" == "COSEBIS" ]
then
est_shear=cosebi
elif [ "${STATISTIC^^}" == "BANDPOWERS" ]
then
est_shear=bandpowers
else 
  #ERROR: Unknown statistic {{{
  _message "Unknown statistic: ${STATISTIC^^}\n"
  exit 1
  #}}}
fi
if [ "@BV:MIXTERM@" == "True" ]
then 
  mix_term="xipxip"
else
  mix_term=""
fi
if [ "${SECONDSTATISTIC^^}" == "XIPM" ] || [ "${SECONDSTATISTIC^^}" == "COSEBIS" ] || [ "${SECONDSTATISTIC^^}" == "BANDPOWERS" ]
then
  if [ "${STATISTIC^^}" == "${SECONDSTATISTIC^^}" ]
  then
    _message "You requested the OneCovariance to compute the correlation between two statistics, but both were set to ${STATISTIC^^}! Computing the covariance for this statistic only!\n"
    cov_between_stats=False
  else
    _message "You requested the OneCovariance to compute the correlation between ${STATISTIC^^} and ${SECONDSTATISTIC^^}!\n"
    cov_between_stats=True
  fi
fi
#}}}

# Infer central values of the prior for cosmological and nuisance parameters
central_value () {
  n=`echo $1 | awk '{print NF}'`
  if [ $n == 1 ]
  then
    value=`echo $1`
  elif [ $n == 3 ]
  then
    value=`echo $1 | awk '{print $2}'`
  fi
  echo $value
}
AIA=`central_value "@BV:PRIOR_AIA@"`
H0=`central_value "@BV:PRIOR_H0@"`
omega_b=`central_value "@BV:PRIOR_OMBH2@"`
omega_c=`central_value "@BV:PRIOR_OMCH2@"`
w0=`central_value "@BV:PRIOR_W@"`
wa=`central_value "@BV:PRIOR_WA@"` 
ns=`central_value "@BV:PRIOR_NS@"`
mnu=`central_value "@BV:PRIOR_MNU@"`
S8=`central_value "@BV:PRIOR_S8INPUT@"`
Omega_m=`echo "$omega_b $omega_c $H0" | awk '{printf "%f", ($1 + $2) /$3 /$3}'`
Omega_b=`echo "$omega_b $H0" | awk '{printf "%f", $1 /$2 /$2}'`
Omega_de=`echo "$Omega_m $H0" | awk '{printf "%f", 1 - $1}'`
sigma8=`echo "$S8 $Omega_m" | awk '{printf "%f", $1 / sqrt($2/0.3)}'`

# Covariance input path (just pointing to a inputs folder in the datablock) 
input_path="@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs"
# Output path
if [ "${cov_between_stats}" == "True" ]
then
  output_path=@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_@BV:STATISTIC@_@BV:SECONDSTATISTIC@
else
  output_path=@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_@BV:STATISTIC@
fi
# COSEBIs basis function path
COSEBISLOC=@RUNROOT@/@CONFIGPATH@/cosebis/
mbiaslist=""
for file in @DB:cosmosis_mbias@
do 
  mbiaslist="${mbiaslist} `cat ${file}`"
done 
mbiaslist=`echo ${mbiaslist} | sed 's/ /,/g'`
NTOMO=`echo @BV:TOMOLIMS@ | awk '{print NF-1}'` 
# Base settings {{{
cat > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs/@SURVEY@_CosmoPipe_constructed_base.ini <<- EOF
[covariance terms]
gauss = @BV:GAUSS@
split_gauss = @BV:SPLIT_GAUSS@
nongauss = @BV:NONGAUSS@
ssc = @BV:SSC@

[observables]
cosmic_shear = True
est_shear = ${est_shear}
ggl = False
est_ggl = gamma_t
clustering = False
est_clust = w
cstellar_mf = False
cross_terms = True
unbiased_clustering = True

[csmf settings]
csmf_log10Mmin = 9.1
csmf_log10Mmax = 11.3
csmf_N_log10M_bin = 10
csmf_directory = @RUNROOT@/INSTALL/OneCovariance/input/conditional_smf/
;csmf_log10M_bins = 
V_max_file = V_max.asc
f_tomo_file = f_tomo.asc

[output settings]
directory = ${output_path}
file = covariance_list.dat, covariance_matrix.mat
style = list, matrix
list_style_spatial_first = True
corrmatrix_plot = correlation_coefficient.pdf
save_configs = save_configs.ini
save_Cells = True
save_trispectra = False
save_alms = True
use_tex = False

[covELLspace settings]
ell_min = @BV:LMINCOV@
ell_max = @BV:LMAXCOV@
ell_bins = @BV:LBINSCOV@
ell_type = log
delta_z = 0.08
tri_delta_z = 0.5
integration_steps = 500
nz_interpolation_polynom_order = 1
mult_shear_bias = ${mbiaslist}
limber = True
pixelised_cell = False
pixel_Nside = 2048
n_spec = 0
ell_spec_min = 2
ell_spec_max = 514
ell_spec_bins = 64
ell_spec_type = lin
ell_photo_min = 51
ell_photo_max = 2952
ell_photo_bins = 12
ell_photo_type = log

[covRspace settings]
projected_radius_min = 0.01
projected_radius_max = 10
projected_radius_bins = 24
projected_radius_type = log
mean_redshift = 0.51, 0.6
projection_length_clustering = 100

EOF
#}}}

# Statistic {{{
cat > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs/@SURVEY@_CosmoPipe_constructed_statistic.ini <<- EOF

EOF

if [ "${STATISTIC^^}" == "XIPM" ] || [ "${SECONDSTATISTIC^^}" == "XIPM" ]
then
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs/@SURVEY@_CosmoPipe_constructed_statistic.ini <<- EOF
[covTHETAspace settings]
theta_min = @BV:THETAMINXI@
theta_max = @BV:THETAMAXXI@
theta_bins = @BV:NXIPM@
theta_type = log
theta_list = 1, 2, 3
xi_pp = True
xi_mm = True
theta_accuracy = 1e-5
integration_intervals = 50

mix_term_do_mix_for = ${mix_term}
mix_term_file_path_catalog = @DB:main_all_gold_recal_cc@
mix_term_col_name_weight = @BV:WEIGHTNAME@
mix_term_col_name_pos1 = @BV:RANAME@
mix_term_col_name_pos2 = @BV:DECNAME@
mix_term_col_name_zbin = TOMOBIN
mix_term_isspherical = True
mix_term_target_patchsize = 10
mix_term_do_overlap = True
mix_term_nbins_phi = 100
mix_term_nmax = 10
mix_term_dpix_min = 0.25
mix_term_do_ec = True
mix_term_file_path_save_triplets = ${input_path}/mixterm/triplets
#mix_term_file_path_load_triplets = ${input_path}/mixterm/triplets

EOF
else
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs/@SURVEY@_CosmoPipe_constructed_statistic.ini <<- EOF
[covTHETAspace settings]
theta_accuracy = 1e-5
integration_intervals = 50

EOF
fi

if [ "${STATISTIC^^}" == "COSEBIS" ]  || [ "${SECONDSTATISTIC^^}" == "COSEBIS" ]
then
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs/@SURVEY@_CosmoPipe_constructed_statistic.ini <<- EOF
[covCOSEBI settings]
En_modes = @BV:NMAXCOSEBIS@
theta_min = @BV:THETAMINXI@
theta_max = @BV:THETAMAXXI@
En_accuracy = 1e-4
Wn_style = log

EOF
fi

if [ "${STATISTIC^^}" == "BANDPOWERS" ]  || [ "${SECONDSTATISTIC^^}" == "BANDPOWERS" ]
then
theta_lo=`echo 'e(l(@BV:THETAMINXI@)+@BV:APODISATIONWIDTH@/2)' | bc -l | awk '{printf "%.9f", $0}'`
theta_up=`echo 'e(l(@BV:THETAMAXXI@)-@BV:APODISATIONWIDTH@/2)' | bc -l | awk '{printf "%.9f", $0}'`
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs/@SURVEY@_CosmoPipe_constructed_statistic.ini <<- EOF
[covbandpowers settings]
apodisation_log_width = @BV:APODISATIONWIDTH@
theta_lo = ${theta_lo}
theta_up = ${theta_up}
theta_binning = @BV:NTHETABINXI@
ell_min = @BV:LMINBANDPOWERS@
ell_max = @BV:LMAXBANDPOWERS@
ell_bins = @BV:NBANDPOWERS@
ell_type = log
bandpower_accuracy = 1e-7

EOF
fi

#}}}

# Survey specs {{{
#Get the neffective list 
nefflist=""
for file in @DB:cosmosis_neff@
do 
  nefflist="${nefflist} `cat ${file}`"
done 
nefflist=`echo ${nefflist} | sed 's/ /,/g'`
#get the sigmae list 
sigmaelist=""
for file in @DB:cosmosis_sigmae@
do 
  sigmaelist="${sigmaelist} `cat ${file}`"
done 
sigmaelist=`echo ${sigmaelist} | sed 's/ /,/g'`
surveymask=@SURVEYMASKFILE@
surveymaskfile=${surveymask##*/}
surveymaskdir=${surveymask%/*}
cat > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
[survey specs]
survey_area_lensing_in_deg2 = @SURVEYAREADEG@
ellipticity_dispersion = ${sigmaelist}
n_eff_lensing = ${nefflist}
mask_directory = ${surveymaskdir}
mask_file_lensing = ${surveymaskfile}

EOF
#}}}

# Redshift distribution {{{
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
[redshift]
z_directory = @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_nz/
zlens_file =@DB:cosmosis_nz@
value_loc_in_lensbin = mid
zlens_extension = NZ_SOURCE

EOF
#}}}

# All kinds of parameters {{{
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
[cosmo]
sigma8 = $sigma8
h = $H0
omega_m = $Omega_m
omega_b = $Omega_b
omega_de = $Omega_de
w0 = $w0
wa = $wa
ns = $ns
neff = 3.046
m_nu = $mnu
tcmb0 = 2.725

[bias]
model = Tinker10
bias_2h = 1.0
mc_relation_cen = duffy08
mc_relation_sat = duffy08
log10mass_bins = 9.1, 11.3

[IA]
A_IA = $AIA
eta_IA = 0.0
z_pivot_IA = 0.3

[hod]
model_mor_cen = double_powerlaw
model_mor_sat = double_powerlaw
dpow_logm0_cen = 10.51
dpow_logm1_cen = 11.38
dpow_a_cen = 7.096
dpow_b_cen = 0.2
dpow_norm_cen = 1.0
dpow_norm_sat = 0.56
model_scatter_cen = lognormal
model_scatter_sat = modschechter
logn_sigma_c_cen = 0.35
modsch_logmref_sat = 13.0
modsch_alpha_s_sat = -0.858
modsch_b_sat = -0.024, 1.149

[halomodel evaluation]
m_bins = 900
log10m_min = 6
log10m_max = 18
hmf_model = Tinker10
mdef_model = SOMean
mdef_params = overdensity, 200
disable_mass_conversion = True
delta_c = 1.686
transfer_model = CAMB
small_k_damping_for1h = damped

[powspec evaluation]
non_linear_model = mead2020_feedback
log10k_bins = 400
log10k_min = -3.49
log10k_max = 2.15

[trispec evaluation]
log10k_bins = 70
log10k_min = -3.49
log10k_max = 2
matter_klim = 0.001
matter_mulim = 0.001
small_k_damping_for1h = damped
lower_calc_limit = 1e-200

[misc]
num_cores = @BV:COVNCORES@

[tabulated inputs files]
npair_directory = @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_xipm/
npair_mm_file = @BV:NPAIRBASE@_nBins_${NTOMO}_Bin?_Bin?.ascii
cosebi_directory = @RUNROOT@/INSTALL/OneCovariance/input/cosebis/
wn_log_file = WnLog?.table
wn_gg_file = W_Psi?-0.50-300.00-lmin-0.5-lmax-1000000.0-lbins-1000000.table
Tn_plus_file = Tplus?.table
Tn_minus_file = Tminus?.table
Qn_file = Q_n?_0.50-300.00
Un_file = U_n?_0.50-300.00
Cell_directory = ${output_path}

EOF
#}}}

# Covariance between summary statistics {{{
if [ "${cov_between_stats}" == "True" ]
then
    arb_fourier_filter_mmE_file_xipm="fourier_weight_realspace_cf_mm_p_?.table"
    arb_fourier_filter_mmB_file_xipm="fourier_weight_realspace_cf_mm_m_?.table"
    arb_real_filter_mm_p_file_xipm="real_weight_realspace_cf_mm_p_?.table"
    arb_real_filter_mm_m_file_xipm="real_weight_realspace_cf_mm_m_?.table"

    arb_fourier_filter_mmE_file_cosebis="WnLog?-0.50-300.00.table"
    arb_fourier_filter_mmB_file_cosebis="WnLog?-0.50-300.00.table"
    arb_real_filter_mm_p_file_cosebis="Tplus?_0.50-300.00.table"
    arb_real_filter_mm_m_file_cosebis="Tminus?_0.50-300.00.table"

    arb_fourier_filter_mmE_file_bandpowers="fourier_weight_bandpowers_mmE_?.table"
    arb_fourier_filter_mmB_file_bandpowers="fourier_weight_bandpowers_mmB_?.table"
    arb_real_filter_mm_p_file_bandpowers="real_weight_bandpowers_mmE_?.table"
    arb_real_filter_mm_m_file_bandpowers="real_weight_bandpowers_mmB_?.table"

cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
arb_summary_directory = @RUNROOT@/INSTALL/OneCovariance/input/arbitrary_summary/
arb_fourier_filter_mmE_file = ${arb_fourier_filter_mmE_file_@BV:STATISTIC@}, ${arb_fourier_filter_mmE_file_@BV:SECONDSTATISTIC@}
arb_fourier_filter_mmB_file = ${arb_fourier_filter_mmB_file_@BV:STATISTIC@}, ${arb_fourier_filter_mmB_file_@BV:SECONDSTATISTIC@}
arb_real_filter_mm_p_file = ${arb_real_filter_mm_p_file_@BV:STATISTIC@}, ${arb_real_filter_mm_p_file_@BV:SECONDSTATISTIC@}
arb_real_filter_mm_m_file = ${arb_real_filter_mm_m_file_@BV:STATISTIC@}, ${arb_real_filter_mm_m_file_@BV:SECONDSTATISTIC@}

[arbitrary_summary]
do_arbitrary_obs = True
oscillations_straddle = 50
arbitrary_accuracy = 1e-5

EOF

fi
#}}}


#Construct the .ini file {{{
cat \
  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs/@SURVEY@_CosmoPipe_constructed_base.ini \
  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs/@SURVEY@_CosmoPipe_constructed_statistic.ini \
  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs/@SURVEY@_CosmoPipe_constructed_other.ini > \
  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs/@BV:STATISTIC@_@SURVEY@_CosmoPipe_constructed.ini

#}}}

