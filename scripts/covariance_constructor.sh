#=========================================
#
# File Name : covariance_constructor.sh
# Created By : awright
# Creation Date : 14-04-2023
# Last Modified : Fri 05 May 2023 10:49:58 AM CEST
#
#=========================================

#Script to generate a covariance .ini

# Infer statistic {{{
STATISTIC="@BV:STATISTIC@"
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
  #ERROR: unknown statistic {{{
  _message "Statistic Unknown: ${STATISTIC^^}\n"
  exit 1
  #}}}
fi
#}}}

# Covariance input path (just pointing to a inputs folder in the datablock) 
input_path="@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs"
# Output path
output_path=@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance/
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
cross_terms = True
unbiased_clustering = False

[output settings]
directory = ${output_path}
file = covariance_list.dat, covariance_matrix.mat
style = list, matrix
corrmatrix_plot = correlation_coefficient.pdf
save_configs = save_configs.ini
save_Cells = True
save_trispectra = False
save_alms = True

[covELLspace settings]
ell_min = @BV:LMINCOV@
ell_max = @BV:LMAXCOV@
ell_bins = @BV:LBINSCOV@
ell_type = log
delta_z = 0.08
tri_delta_z = 0.5
integration_steps = 500
nz_interpolation_polynom_order = 1
mult_shear_bias = 0.0192, 0.007671, 0.00711, 0.005669, 0.006
limber = True
pixelised_cell = False
pixel_Nside = 2048

EOF
#}}}

# Statistic {{{
if [ "${STATISTIC^^}" == "XIPM" ]
then
cat > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs/@SURVEY@_CosmoPipe_constructed_statistic.ini <<- EOF
[covTHETAspace settings]
theta_min = @BV:THETAMINXI@
theta_max = @BV:THETAMAXXI@
theta_bins = @BV:NTHETABINXI@
theta_type = log
theta_list = 1, 2, 3
xi_pp = True
xi_mm = True

mix_term_file_path_catalog = ${input_path}/mixterm/catalog
mix_term_col_name_weight = weight
mix_term_col_name_pos1 = x 
mix_term_col_name_pos2 = y 
mix_term_col_name_zbin = z_bin
mix_term_isspherical = True
mix_term_target_patchsize = 10
mix_term_do_overlap = True
mix_term_do_mix_for = xipxip
mix_term_nbins_phi = 100
mix_term_nmax = 10
mix_term_dpix_min = 0.25
mix_term_do_ec = True
mix_term_file_path_save_triplets = ${input_path}/mixterm/triplets
mix_term_file_path_load_triplets = 

EOF
elif [ "${STATISTIC^^}" == "COSEBIS" ]
then
cat > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs/@SURVEY@_CosmoPipe_constructed_statistic.ini <<- EOF
[covCOSEBI settings]
En_modes = @BV:NMAXCOSEBIS@
theta_min = @BV:THETAMINXI@
theta_max = @BV:THETAMAXXI@
En_accuracy = 1e-4
Wn_style = log

EOF
elif [ "${STATISTIC^^}" == "BANDPOWERS" ]
then
cat > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs/@SURVEY@_CosmoPipe_constructed_statistic.ini <<- EOF
[covbandpowers settings]
apodisation_log_width = 0.5
theta_lo = @BV:THETAMINXI@
theta_up = @BV:THETAMAXXI@
theta_binning = 300
ell_min = @BV:LMINBANDPOWERS@
ell_max = @BV:LMAXBANDPOWERS@
ell_bins = @BV:NBINSBANDPOWERS@
ell_type = log

EOF
fi

#}}}

# Survey specs {{{
cat > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
[survey specs]
mask_directory = ${input_path}/mask
mask_file_clust = mask_BOSS_2dFLenS_wcs_nside4096.fits
alm_file_clust = alms_clust.ascii
survey_area_clust_in_deg2 = 1500
n_eff_clust = 1.18, 1.85
survey_area_ggl_in_deg2 = 1000
mask_file_lensing = mask_BOSS_2dFLenS_wcs_nside4096.fits
alm_file_lensing = alms_lens.ascii
survey_area_lensing_in_deg2 = 867
ellipticity_dispersion = 0.270211643434, 0.261576890227, 0.276513819228, 0.265404482999, 0.286084532469
n_eff_lensing = 0.605481425815, 1.163822540526, 1.764459694692, 1.249143662985, 1.207829761642 

EOF
#}}}

# Redshift distribution {{{
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
[redshift]
z_directory = ${input_path}/redshift_distribution
zclust_file = BOSS_and_2dFLenS_n_of_z1_res_0.01.asc, BOSS_and_2dFLenS_n_of_z2_res_0.01.asc
value_loc_in_clustbin = left
zlens_file = K1000_photoz_1.asc, K1000_photoz_2.asc, K1000_photoz_3.asc, K1000_photoz_4.asc, K1000_photoz_5.asc
value_loc_in_lensbin = mid

EOF
#}}}

# All kinds of parameters {{{
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
[cosmo]
sigma8 = 0.838
h = 0.767
omega_m = 0.3
omega_b = 0.045
omega_de = 0.7
w0 = -1.0
wa = 0.0
ns = 0.96
neff = 3.046
m_nu = 0.0
tcmb0 = 2.725

[bias]
model = Tinker10
bias_2h = 1.0
mc_relation_cen = duffy08
mc_relation_sat = duffy08

[IA]
A_IA = 0.264
eta_IA = 0.0
z_pivot_IA = 0.3

[hod]
model_mor_cen = double_powerlaw
model_mor_sat = double_powerlaw
dpow_logm0_cen = 10.6
dpow_logm1_cen = 11.25
dpow_a_cen = 3.41
dpow_b_cen = 0.99
dpow_norm_cen = 1.0
dpow_norm_sat = 0.56
model_scatter_cen = lognormal
model_scatter_sat = modschechter
logn_sigma_c_cen = 0.35
modsch_logmref_sat = 12.0
modsch_alpha_s_sat = -1.34
modsch_b_sat = 0.59

[halomodel evaluation]
m_bins = 900
log10m_min = 9
log10m_max = 18
hmf_model = Tinker10
mdef_model = SOMean
mdef_params = overdensity, 200
disable_mass_conversion = True
delta_c = 1.686
transfer_model = EH
small_k_damping_for1h = damped

[powspec evaluation]
non_linear_model = mead2015
log10k_bins = 200
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

[tabulated inputs files]
npair_directory = ${input_path}/npair/
npair_mm_file = XI_K1000_theta_0.5_300.0_nBins_5_Bin?_Bin?.ascii
cosebi_directory = ${input_path}/cosebis/
wn_log_file = WnLog?.table
Tn_plus_file = Tplus?.table
Tn_minus_file = Tminus?.table

[misc]
num_cores = 8

EOF
#}}}

#Construct the .ini file {{{
cat \
  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs/@SURVEY@_CosmoPipe_constructed_base.ini \
  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs/@SURVEY@_CosmoPipe_constructed_statistic.ini \
  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs/@SURVEY@_CosmoPipe_constructed_other.ini > \
  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs/@SURVEY@_CosmoPipe_constructed.ini

#}}}

# Not used: {{{
#[covRspace settings]
#projected_radius_min = 0.01
#projected_radius_max = 10
#projected_radius_bins = 24
#projected_radius_type = log
#mean_redshift = 0.51, 0.6
#projection_length_clustering = 100
#}}}