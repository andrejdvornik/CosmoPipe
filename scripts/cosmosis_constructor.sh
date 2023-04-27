#=========================================
#
# File Name : cosmosis_constructor.sh
# Created By : awright
# Creation Date : 14-04-2023
# Last Modified : Wed 19 Apr 2023 08:52:51 AM CEST
#
#=========================================

#Script to generate a cosmosis .ini, values, & priors file 

#Prepare the starting items {{{
cat > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_base.ini <<- EOF
[DEFAULT]
MY_PATH      = @RUNROOT@/

stats_name    = @DB:STATISTIC@
CSL_PATH      = %(MY_PATH)s/INSTALL/cosmosis-standard-library/
KCAP_PATH     = %(MY_PATH)s/INSTALL/kcap/

OUTPUT_FOLDER =  %(MY_PATH)s/@STORAGEPATH@/MCMC/output/@SURVEY@_@BLINDING@/@DB:BOLTZMAN@/%(stats_name)s/chain/
CONFIG_FOLDER = @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/

blind         = @DB:BLIND@
redshift_name = source

SAMPLER_NAME = @DB:SAMPLER@
RUN_NAME = %(SAMPLER_NAME)s_%(blind)s

data_file = @DB:mcmc_inp@


EOF
#}}}

#Set up the scale cuts module {{{
cat > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_scalecut.ini <<- EOF
[scale_cuts]
file = %(KCAP_PATH)s/modules/scale_cuts/scale_cuts.py
output_section_name = scale_cuts_output
data_and_covariance_fits_filename = %(data_file)s
simulate = F
simulate_with_noise = T
mock_filename =
EOF
#}}}

#Requested statistic {{{
STATISTIC="@DB:STATISTIC@"
if [ "${STATISTIC^^}" == "COSEBIS" ] #{{{
then 
  #Scalecuts {{{
  lo=`echo @DB:NMINCOSEBIS@ | awk '{print $1-0.5}'`
  hi=`echo @DB:NMAXCOSEBIS@ | awk '{print $1+0.5}'`
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_scalecut.ini <<- EOF
use_stats = En
keep_ang_En   = ${lo} ${hi} 
cosebis_extension_name = En
cosebis_section_name = cosebis

EOF
#}}}

#Base variables {{{
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_base.ini <<- EOF
;COSEBIs settings
COSEBIS_PATH = %(MY_PATH)s/INSTALL/kcap/cosebis/
tmin_cosebis = @THETAMINCOV@
tmax_cosebis = @THETAMAXCOV@
nmax_cosebis = @DB:NMAXCOSEBIS@
WnLogPath = @RUNROOT@/@CONFIGPATH@/cosebis/WnLog/

EOF
#}}}

#statistic {{{
cat > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_statistic.ini <<- EOF
[cosebis]
file = %(COSEBIs_PATH)s/libcosebis.so
theta_min = %(tmin_cosebis)s
theta_max = %(tmax_cosebis)s
n_max = %(nmax_cosebis)s
Roots_n_Norms_FolderName = %(COSEBIS_PATH)s/TLogsRootsAndNorms/
Wn_Output_FolderName = %(WnLogPath)s
Tn_Output_FolderName = %(COSEBIS_PATH)s/TpnLog/
output_section_name =  cosebis
add_2D_cterm = 0 ; (optional) DEFAULT is 0: don't add it

EOF
#}}}

#}}}
elif [ "${STATISTIC^^}" == "BANDPOWERS" ] #{{{
then 
  #scale cut {{{
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_scalecut.ini <<- EOF
use_stats = PeeE
bandpower_e_cosmic_shear_extension_name = PeeE
bandpower_e_cosmic_shear_section_name = bandpower_shear_e

EOF
#}}}

#Statistic {{{
cat > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_statistic.ini <<- EOF

EOF
#}}}

#}}}
elif [ "${STATISTIC^^}" == "XIPM" ] #{{{
then 
  #scale cut {{{
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_scalecut.ini <<- EOF
use_stats = xipm
xi_plus_extension_name = xiP
xi_minus_extension_name = xiM
xi_plus_section_name = shear_xi_plus_binned
xi_minus_section_name = shear_xi_minus_binned

EOF
#}}}
 
#statistic {{{
cat > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_statistic.ini <<- EOF

EOF
#}}}

#}}}
else 
  #ERROR: unknown statistic {{{
  _message "Statistic Unknown: ${STATISTIC^^}\n"
  exit 1
  #}}}
fi
#}}}

#Requested sampler {{{
SAMPLER="@DB:SAMPLER@"
listparam=''
if [ "${SAMPLER^^}" == "TEST" ] #{{{
then 
  
cat > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_sampler.ini <<- EOF
[test]
save_dir=%(OUTPUT_FOLDER)s/output_%(RUN_NAME)s
fatal_errors=T

EOF

#}}}
elif [ "${SAMPLER^^}" == "MAXLIKE" ] #{{{
then 

cat > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_sampler.ini <<- EOF
[maxlike]
method = Nelder-Mead
tolerance = 0.01
maxiter = 1000000
max_posterior = T

EOF

#}}}
elif [ "${SAMPLER^^}" == "MULTINEST" ] #{{{
then 

cat > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_sampler.ini <<- EOF
[multinest]
max_iterations=100000
multinest_outfile_root= %(OUTPUT_FOLDER)s/%(RUN_NAME)s_
resume=T
tolerance = 0.01
constant_efficiency = F
live_points = 1000
efficiency = 0.3

EOF

#}}}
elif [ "${SAMPLER^^}" == "POLYCHORD" ] #{{{
then 

cat > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_sampler.ini <<- EOF
[polychord]
live_points = 300
;tolerance = 0.001
tolerance = 0.01
num_repeats = 60
boost_posteriors = 10.0 
fast_fraction = 0.1 
feedback = 3 
resume = T
base_dir = %(OUTPUT_FOLDER)s/PC
polychord_outfile_root = pc_run

EOF

#}}}
elif [ "${SAMPLER^^}" == "APRIORI" ] #{{{
then 

cat > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_sampler.ini <<- EOF
[apriori]
nsample=500000

EOF

#}}}
elif [ "${SAMPLER^^}" == "LIST" ] #{{{
then 
  ndof="@DB:DVLENGTH@"
  listparam="scale_cuts_output/theory#${ndof}"
  list_input="@DB:LIST_INPUT_SAMPLER@"

	cat > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_sampler.ini <<- EOF
	[list]
	filename = %(OUTPUT_FOLDER)s/output_${list_input}_%(blind)s.txt 
	
	EOF

#}}}
elif [ "${SAMPLER^^}" == "EMCEE" ] #{{{
then 
  _message "Sampler Unimplemented: ${SAMPLER^^}\n"
  exit 1

#}}}
else 
  #ERROR: unknown sampler {{{
  _message "Sampler Unknown: ${SAMPLER^^}\n"
  exit 1
  #}}}
fi
#}}}

#Prepare the pipeline section {{{ 
extraparams="cosmological_parameters/S_8 cosmological_parameters/sigma_8 cosmological_parameters/A_s cosmological_parameters/omega_m cosmological_parameters/omega_nu cosmological_parameters/omega_lambda cosmological_parameters/cosmomc_theta"
shifts=""
NTOMO=@DB:NTOMO@
for i in `seq ${NTOMO}`
do 
   shifts="${shifts} nofz_shifts/bias_${i}"
done

cat > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_pipe.ini <<- EOF
[pipeline]
modules = @DB:COSMOSIS_PIPELINE@
values  = %(CONFIG_FOLDER)s/@SURVEY@_values.ini
priors  = %(CONFIG_FOLDER)s/@SURVEY@_priors.ini
likelihoods  = loglike
extra_output = ${extraparams} ${shifts} ${listparam}
quiet = F
timing = T
debug = F

[runtime]
sampler = %(SAMPLER_NAME)s

[output]
filename = %(OUTPUT_FOLDER)s/output_%(RUN_NAME)s.txt
format = text


EOF
#}}}

#Requested boltzman {{{
BOLTZMAN="@DB:BOLTZMAN@"
if [ "${BOLTZMAN^^}" == "CAMB_HM2015" ] #{{{
then 

cat > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_boltzman.ini <<- EOF
[camb]
file = %(CSL_PATH)s/boltzmann/camb/camb_interface.py
do_reionization = F
mode = power
nonlinear = pk
halofit_version = mead
neutrino_hierarchy = normal
kmax = 20.0
zmid = 2.0
nz_mid = 100
zmax = 6.0
nz = 150
zmax_background = 6.0
zmin_background = 0.0
nz_background = 6000

EOF
#}}}
elif [ "${BOLTZMAN^^}" == "COSMOPOWER_HM2015" ] #{{{
then 
cat > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_boltzman.ini <<- EOF
[cosmopower]
file = %(MY_PATH)s/INSTALL/CosmoPowerCosmosis/cosmosis_modules/cosmopower_interface.py
path_2_trained_emulator = %(MY_PATH)s/INSTALL/CosmoPowerCosmosis/
use_specific_k_modes = F
; otherwise it uses the k-modes the emulator is trained on
kmax = 10.0
kmin = 1e-5
nk = 200

[distances]
file = %(MY_PATH)s/INSTALL/CosmoPowerCosmosis/cosmosis_modules/camb_distances.py
do_reionization = F
mode = transfer
nonlinear = pk
halofit_version = mead
neutrino_hierarchy = normal
kmax = 20.0
zmid = 2.0
nz_mid = 100
zmax = 6.0
nz = 150
background_zmax = 6.0
background_zmin = 0.0
background_nz = 6000

EOF
#}}}
elif [ "${BOLTZMAN^^}" == "COSMOPOWER_HM2020" ] #{{{
then 
cat > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_boltzman.ini <<- EOF
[cosmopower]
file = %(MY_PATH)s/INSTALL/CosmoPowerCosmosis/cosmosis_modules/cosmopower_interface_mead2020_feedback_log10_ratio.py
path_2_trained_emulator = %(MY_PATH)s/INSTALL/CosmoPowerCosmosis/train_emulator_camb_new/outputs/
use_specific_k_modes = F
; otherwise it uses the k-modes the emulator is trained on
kmax = 10.0
kmin = 1e-5
nk = 200

[distances]
file = %(MY_PATH)s/INSTALL/CosmoPowerCosmosis/cosmosis_modules/camb_distances.py
do_reionization = F
mode = transfer
nonlinear = pk
halofit_version = mead
neutrino_hierarchy = normal
kmax = 20.0
zmid = 2.0
nz_mid = 100
zmax = 6.0
nz = 150
background_zmax = 6.0
background_zmin = 0.0
background_nz = 6000

EOF
#}}}
elif [ "${BOLTZMAN^^}" == "COSMOPOWER_HM2015_S8" ] #{{{
then 
cat > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_boltzman.ini <<- EOF
[cosmopower]
file = %(MY_PATH)s/INSTALL/CosmoPowerCosmosis/cosmosis_modules/cosmopower_interface_S8.py
path_2_trained_emulator = %(MY_PATH)s/INSTALL/CosmoPowerCosmosis/S8_input/
use_specific_k_modes = F
; otherwise it uses the k-modes the emulator is trained on
kmax = 10.0
kmin = 1e-5
nk = 200

[distances]
file = %(MY_PATH)s/INSTALL/CosmoPowerCosmosis/cosmosis_modules/camb_distances.py
do_reionization = F
mode = transfer
nonlinear = pk
halofit_version = mead
neutrino_hierarchy = normal
kmax = 20.0
zmid = 2.0
nz_mid = 100
zmax = 6.0
nz = 150
background_zmax = 6.0
background_zmin = 0.0
background_nz = 6000

EOF
#}}}
else 
  #ERROR: unknown boltzman code 
  _message "Boltzman Code Unknown: ${BOLTZMAN^^}\n"
  exit 1
fi
#}}}

#Additional Modules {{{
echo > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini
for module in @DB:COSMOSIS_PIPELINE@
do 
  case ${module} in 
    "sample_S8") #{{{
			cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
			[$module]
			file = %(KCAP_PATH)s/utils/sample_S8.py
			s8_name = s_8_input
			
			EOF
			;;#}}}
    "sigma8toAs") #{{{
			cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
			[$module]
			file = %(KCAP_PATH)s/utils/sigma8toAs.py
			
			EOF
			;; #}}}
    "correlated_dz_priors") #{{{
      shifts=""
      unc_shifts=""
      for i in `seq ${NTOMO}`
      do 
         shifts="${shifts} nofz_shifts/bias_${i}"
         unc_shifts="${unc_shifts} nofz_shifts/uncorr_bias_${i}"
      done
			cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
			[$module]
			file = %(KCAP_PATH)s/utils/correlated_priors.py
			uncorrelated_parameters = ${unc_shifts}
			output_parameters = ${shifts}
			covariance = @DB:nzcov@
			
			EOF
			;; #}}}
    "one_parameter_hmcode") #{{{
      cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
			[$module]
			file = %(KCAP_PATH)s/utils/one_parameter_hmcode.py
			a_0 = 0.98
			a_1 = -0.12
			
			EOF
			;; #}}}
    "extrapolate_power") #{{{
			cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
			[$module]
			file = %(CSL_PATH)s/boltzmann/extrapolate/extrapolate_power.py
			kmax = 500.0
			
			EOF
			;; #}}}
    "load_nz_fits") #{{{
			cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
			[$module]
			file = %(CSL_PATH)s/number_density/load_nz_fits/load_nz_fits.py
			nz_file = %(data_file)s
			data_sets = %(redshift_name)s
			
			EOF
			;; #}}}
    "source_photoz_bias") #{{{
      cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
			[$module]
			file = %(CSL_PATH)s/number_density/photoz_bias/photoz_bias.py
			mode = additive
			sample = nz_%(redshift_name)s
			bias_section  = nofz_shifts
			interpolation = cubic
			output_deltaz = T
			output_section_name = delta_z_out
			
			EOF
			;; #}}}
    "linear_alignment") #{{{
			cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
			[$module]
			file = %(CSL_PATH)s/intrinsic_alignments/la_model/linear_alignments_interface.py
			method = bk_corrected
			
			EOF
			;; #}}}
    "projection") #{{{
			cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
			[$module]
			file = %(CSL_PATH)s/structure/projection/project_2d.py
			ell_min_logspaced = 1.0
			ell_max_logspaced = 1.0e4
			n_ell_logspaced = 50
			position-shear = F
			fast-shear-shear-ia = %(redshift_name)s-%(redshift_name)s
			verbose = F
			get_kernel_peaks = F
			
			EOF
			;; #}}}
    "likelihood") #{{{
			cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
			[$module]
			file = %(KCAP_PATH)s/utils/mini_like.py
			input_section_name = scale_cuts_output
			like_name = loglike
			EOF
    	;; #}}}
  esac
done
#}}}

#Construct the .ini file {{{
cat \
  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_base.ini \
  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_pipe.ini \
  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_statistic.ini \
  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_scalecut.ini \
  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_boltzman.ini \
  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_sampler.ini \
  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini > \
  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed.ini

#}}}

