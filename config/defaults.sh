##
# 
# KiDS COSMOLOGY PIPELINE Default Configuration Variables 
# Written by A.H. Wright (2019-09-30) 
#
##

# Defaults for runtime variables 

#List of magnitudes for use in calibration 
MAGLIST="MAG_GAAP_u MAG_GAAP_g MAG_GAAP_r MAG_GAAP_i1 MAG_GAAP_i2 MAG_GAAP_Z MAG_GAAP_Y MAG_GAAP_J MAG_GAAP_H MAG_GAAP_Ks"

#Reference magnitude for use in calibration 
REFMAGNAME="MAG_AUTO"

#Form of the SOM calibration feature space ({ALLMAG,MAG,ALLCOLOUR,COLOUR})
FEATURETYPES="ALLCOLOUR+MAG"

#Blind Character
BLIND=A                 # KiDS-Legacy
#BLIND=C                 # KiDS-1000

#Shape measurement variables: e1
E1NAME=autocal_e1_@BV:BLIND@
#Shape measurement variables: e2  
E2NAME=autocal_e2_@BV:BLIND@

#Uncorrected shape measurement variables: e1
RAWE1NAME=raw_e1
#Uncorrected shape measurement variables: e2  
RAWE2NAME=raw_e1

#PSF Shape measurement variables: e1
PSFE1NAME=PSF_e1
#PSF Shape measurement variables: e2
PSFE2NAME=PSF_e2

#RADec names: RA
RANAME=ALPHA_J2000
#RADec names: Declination 
DECNAME=DELTA_J2000

#Number of bootstrap realisations
NBOOT=300

#Specz column name
ZSPECNAME='z_spec'

#Photo-z column name
ZPHOTNAME='Z_B'

#Number of threads
NTHREADS=12

#Nz delta-z stepsize
NZSTEP=0.05

#Number of spatial splits 
NSPLIT=5
#Number of spatial splits to retain
NSPLITKEEP=5

#Do we want to always save TPDs in the chain file (makes files much larger)
SAVE_TPDS=False
#Do we want to split the datavector in any way?
SPLITMODE=

#List of m-bias values
#MBIASVALUES="-0.009  -0.011  -0.015  +0.002  +0.007"      #KiDS-1000
#MBIASVALUES="-0.0230168 -0.015999775 -0.01162315 0.019508625 0.02944635 0.044750725" #KiDS-Legacy Blind A
MBIASVALUES="-0.013 -0.018 -0.008 0.019 0.034"            #SSL K1000
#List of m-bias uncertainties
#MBIASERRORS="0.019 0.020 0.017 0.012 0.010"               #KiDS-1000
#MBIASERRORS="0.02  0.02  0.02  0.02  0.02"                #KV450
#MBIASERRORS=                                              #KiDS-Legacy
MBIASERRORS="0.017 0.007 0.007 0.006 0.006"            #SSL K1000
#Use an Analytic m-bias covariance?
ANALYTIC_MCOV=TRUE
#m-bias correlation
MBIASCORR=0.99

#Limits of the tomographic bins
#TOMOLIMS='0.1 0.3 0.5 0.7 0.9 1.2'                        #KiDS-1000
TOMOLIMS='0.10 0.42 0.58 0.71 0.90 1.14 2.00'             #KiDS-Legacy
#TOMOLIMS='0.10 0.42 0.58 0.71 0.90 1.14 2.00'             #KiDS-Legacy finebins

#Variable used to define tomographic bins 
TOMOVAR=Z_B

#Theta limits for covariance 
THETAMINCOV="0.50"
#Theta limits for covariance 
THETAMAXCOV="300.00"

PATCH_CENTERFILE=""

#Theta limits for xipm (can be highres for BP/COSEBIs)
THETAMIN="0.50"
#Theta limits for xipm (can be highres for BP/COSEBIs)
THETAMAX="300.00"
#Number of Theta bins for xipm (can be highres for BP/COSEBIs)
NTHETABIN="1000"
#Number of Xipm bins used for science
NTHETAREBIN=9
#Maximum Theta for analysing Xim (arcmin)
THETAMAXM=300
#Minimum Theta for analysing Xim (arcmin)
THETAMINM=4

#Minimum Number of modes for COSEBIs
NMINCOSEBIS=1
#Maximum Number of modes for COSEBIs
NMAXCOSEBIS=10

#Name of the lensing weight variable  
WEIGHTNAME=weight

#Name of the lensing weight variable  
CALIBWEIGHTNAME=PriorWeight

#Name to base the Nz labels on 
NZNAME_BASEBLOCK=som_weight_calib_cats
NZNAME_BASEBLOCK_LENS=som_weight_calib_cats
NZNAME_BASEBLOCK_OBS=som_weight_calib_cats

##### DANGER WILL ROBINSON!
##### Inconsistent naming here and with SURVEY will create a bug
##### This naming is now taken care of by .fiducial_combination in subroutines
#####Name of the base file for cosmosis/onecov
#####NPAIRBASE=XI_KiDS_1000_NScomb             #KiDS-1000
#####NPAIRBASE=XI_KiDS_Legacy_NScomb           #KiDS-Legacy

#Statistic of choice for chain 
STATISTIC=cosebis

#Sampler 
SAMPLER=nautilus

#Boltzman Code 
BOLTZMAN=COSMOPOWER_HM2015_S8

#Simulated spectroscopic calibration sample(s)
SIMSPECZCAT=/net/home/fohlen13/jlvdb/LegaZy/TEST/SKiLLS_spec/realisation/

#Simulated catalogues with constant shear
#SIMMAINCAT=/net/home/fohlen11/awright/SKiLLS/skills_v07D7ten_single/                          #Legacy Testing
#SIMMAINCAT=/net/home/fohlen12/awitt/KiDS_mock_photometry/mice2/mag/test_full_all/mice2_all_result_photoz_recalweight.fits  #Legacy MICE2
#SIMMAINCAT=/net/home/fohlen11/awright/KiDS/Legacy/StratLearn/MICE2_KV450/                    #KiDS-1000
SIMMAINCAT=/net/home/fohlen11/awright/SKiLLS/skills_v07D7ten/

#Simulated catalogues with variable shear 
SIMVARCAT=/net/home/fohlen11/awright/SKiLLS/skills_v07D7p1/

#Catalogue of Blended objects in Simulated catalogues
SIMBLENDCAT=/net/home/fohlen11/awright/SKiLLS/SKiLLS/skills_v07D7p1_lite_blended/

#COSEBI file base name
COSEBISBASE=@BV:COSEBISBASE@

#Patches to use in CosmoSIS calculations
COSMOSIS_PATCHLIST="NS"

#CosmoSIS pipeline specification
COSMOSIS_PIPELINE="default"

#Data Vector Length 
DVLENGTH=75 

#Ellipticity type for m-calibration ('measured' or 'true')
ETYPE='measured'

#Filtering condition 
FILTERCOND=@BV:FILTERCOND@
#Strings to match to columns when reducing catalogue size  
KEEPSTRINGS=@BV:KEEPSTRINGS@


#Input shear variable names: gamma_1
G1NAME=@BV:G1NAME@
#Input shear variable names: gamma_2 
G2NAME=@BV:G2NAME@

#Compute the Gaussian component of the covariance (True or False)
GAUSS=True
#Compute the non-gaussian component of the covariance (True or False)
NONGAUSS=True
#Compute the mixterm component of the covariance (True or False)
MIXTERM=False
MIXTERM_BASEFILE=main_all_gold_recal_cc_@BV:BLIND@
#Split Gaussian contributions in the output file (True or False; True adds considerable runtime (x2+)!)
SPLIT_GAUSS=False
#Compute the super-sample component of the covariance (True or False)
SSC=True
#Second statistic for calculating cross-covariances
SECONDSTATISTIC=""

#Number of ell bins for covariance computation 
LBINSCOV=100
#Minimum of ell bins for covariance computation 
LMINCOV=2
#Maximum of ell bins for covariance computation 
LMAXCOV=10000

SECONDSTATISTIC=""

#String which determines type of bandpowers correlation function (EE,NE,NN) (shear, GGL, clustering)
BANDPOWERMODE='EE'
#Number of Bandpowers
NBANDPOWERS=8
#Minimum of ell bins for bandpowers computation 
LMINBANDPOWERS=100
#Maximum of ell bins for bandpowers computation 
LMAXBANDPOWERS=1500
#Apodisation width for bandpowers 
APODISATIONWIDTH=0.5

#Sampler to use as basis of 'list sampler' 
LIST_INPUT_SAMPLER=multinest 

#name of the m1 column 
M1NAME=@BV:M1NAME@
#name of the m2 column 
M2NAME=@BV:M2NAME@

#m-calibration surface file 
MSURFACE=@BV:MSURFACE@

#Number of Resolution bins for m-surface construction 
NBINR=20
#Number of SNR bins for m-surface construction 
NBINSNR=20

#Existing column name to re-name: 
OLDKEY=@BV:OLDKEY@
#New column name for re-name: 
NEWKEY=@BV:NEWKEY@

#Dimensions of the SOM 
SOMDIM="101 101"
#Number of iterations in SOM construction 
NITER=1000
#Do we want to optimise the number of heirarchical clusters?
OPTIMISE=--optimise
#What is the minium number of allowed HCs
MINNHC=2000 

#Number of sources to use in match sliding redshift window 
MATCH_NIDX=1000
#Do we want to normalise (whiten) the feature space before matching?
MATCHNORMALISE=--norm
#Do we want to allow duplicates in the matching process? 
MATCHDUPLICATES=--duplicates 

#Aspect ratio to use when splitting catalogue 
SPLITASP=1

#Systematic error for Nz bias estimation 
NZSYSERROR=0.01

#PSF Shape coefficient column names: Q11
PSFQ11NAME=@BV:PSFQ11NAME@
#PSF Shape coefficient column names: Q12
PSFQ12NAME=@BV:PSFQ12NAME@
#PSF Shape coefficient column names: Q22
PSFQ22NAME=@BV:PSFQ22NAME@

#Resolution variable column name 
RNAME=R

#Label for simulation tiles 
SIMLABEL=tile_label

#Sampler name 
SAMPLER=multinest

#Scale-length variable column name 
SCALELENGTHNAME=@BV:SCALELENGTHNAME@

#Simulation identifier label column name 
SIMLABEL=@BV:SIMLABEL@

#Path to Reference Chain for Figure Construction 
REFCHAIN=/net/home/fohlen13/stoelzner/kids1000_chains/all_chains/main_chains/cosebis/chain/output_multinest_C.txt

#Statistic to compute 
STATISTIC=cosebis

#Priors in cosmosis syntax
#Priors: Omega_m*h^2
PRIOR_OMCH2="0.051 0.11570 0.255"
#Priors: Omega_b*h^2
PRIOR_OMBH2="0.019 0.02233 0.026"
#Priors: H0
PRIOR_H0="0.64 0.68980 0.82"
#Priors: n_s
PRIOR_NS="0.84 0.96900 1.1"
#Priors: S_8
PRIOR_S8INPUT="0.1 0.77700 1.3"
#Priors: sigma_8
PRIOR_SIGMA8="0.1 0.77700 1.3"
#Priors: Omega_K
PRIOR_W="-1.0"
PRIOR_OMEGAK="0.0"
#Priors: w_0
PRIOR_W="-1.0"
#Priors: w_a
PRIOR_WA="0.0"
#Priors: m_nu
PRIOR_MNU="0.06"
#Priors: log(T_AGN)
PRIOR_LOGTAGN="7.1 8.0 8.3"
#Priors: Baryon feedback Amplitude A (HM2015)
PRIOR_ABARY="2.0 2.6 3.13"

#IA model choice: can be linear, linearz, massdep or tatt
IAMODEL=linear
#Linear IA model: Amplitude
PRIOR_AIA="-6.0 1.0 6.0"
#Linear-z model: IAMODEL=linearz
#Linear-z IA model: Amplitude
PRIOR_A_IA="-6.0 1.0 6.0"
#Linear-z IA model: B
PRIOR_B_IA="gaussian -3.7 4.3"
#Linear IA model: pivot scale factor
PRIOR_A_PIV=0.769

#Massdep IA model: IAMODEL=massdep A/Beta are controlled by the ia_models parameter files in /config/ia_models
#Massdep IA model: pivot mass
PRIOR_LOG10_M_PIV=13.5
#Massdep IA model: mean mass bin 1
PRIOR_LOG10_M_MEAN_1="gaussian 11.732 0.073"
#Massdep IA model: mean mass bin 2
PRIOR_LOG10_M_MEAN_2="gaussian 12.495 0.066"
#Massdep IA model: mean mass bin 3
PRIOR_LOG10_M_MEAN_3="gaussian 12.798 0.063"
#Massdep IA model: mean mass bin 4
PRIOR_LOG10_M_MEAN_4="gaussian 12.964 0.060"
#Massdep IA model: mean mass bin 5
PRIOR_LOG10_M_MEAN_5="gaussian 13.089 0.058"
#Massdep IA model: mean mass bin 6
PRIOR_LOG10_M_MEAN_6="gaussian 13.242 0.055"
#Massdep IA model: red fraction bin 1
PRIOR_F_R_1=0.158
#Massdep IA model: red fraction bin 2
PRIOR_F_R_2=0.198
#Massdep IA model: red fraction bin 3
PRIOR_F_R_3=0.206
#Massdep IA model: red fraction bin 4
PRIOR_F_R_4=0.258
#Massdep IA model: red fraction bin 5
PRIOR_F_R_5=0.207
#Massdep IA model: red fraction bin 6
PRIOR_F_R_6=0.026

#Scale dependent model: IAMODEL=tatt
#scale dep IA model: pivot z
PRIOR_Z_PIV="0.62"
#scale dep IA model: Amplitude 1
PRIOR_A1="-5.0 1.0 5.0"
#scale dep IA model: Amplitude 2
PRIOR_A2=0.0
#scale dep IA model: Alpha 1
PRIOR_ALPHA1=0.0
#scale dep IA model: Alpha 2
PRIOR_ALPHA2=0.0
#scale dep IA model: Bias
PRIOR_BIAS_TA="-0.5 0.0 1.5"

#Magnitude limits for the wide field sample (effective after weighting)
MAGLIMITS="20 23.5"
#Magnitude threshold for for the definition of the field sample (hard-cut before weighting)
MAGTHRESH="20 25.5"

#Filter for defining the magnitude limits for the wide field sample (effective after weighting)
MAGLIMIT_FILTER="r"

#Input Values for the Nz bias in each tomographic bin (SHOULD BE dz = EST - TRUTH)
#NZBIAS="0.000 +0.002 +0.013 +0.011 -0.006"               #KiDS-1000
#NZBIAS="0.000 +0.002 +0.013 +0.011 -0.006"               #SSL KiDS-1000
NZBIAS="-0.0258348876411008 0.0134629476830202 -0.00130607068876168 0.00825655331002634 -0.0112282260145437 -0.0541954439985493" #KiDS-Legacy Blinded_v2/Legacy_fiducial_v2

#Input Nz covariance matrix
#NZCOVFILE=/net/home/fohlen13/stoelzner/Cat_to_Obs_K1000_P1/data/kids/nofz/SOM_cov_multiplied.asc    #KiDS-1000
NZCOVFILE=/net/home/fohlen14/awright/KiDS/Legacy/CosmicShear/Blinded_v2/work_Legacy_fiducial_v2/CosmoPipe_DataBlock/nzcov/Nz_covariance.txt

#Number of cores to use for Covariance Calculation
COVNCORES=@BV:NTHREADS@
#Number of threads to use for Covariance Calculation
COVNTHREADS=1


#Survey Area in arcmin for the combined patches
#SURVEYAREA_NS=3.12120e+06     #KiDS-1000
#Survey Area in arcmin for the combined patches
#SURVEYAREADEG_NS=867.0        #KiDS-1000
#Survey Area in arcmin for the combined patches
SURVEYAREA_NS=3.630254e+06    #KiDS-Legacy
#Survey Area in arcmin for the combined patches
SURVEYAREADEG_NS=1008.404     #KiDS-Legacy
#Survey Area in arcmin for the combined patches
SURVEYAREA_N=1.860461e+06    #KiDS-Legacy
#Survey Area in arcmin for the combined patches
SURVEYAREADEG_N=516.7947     #KiDS-Legacy
#Survey Area in arcmin for the combined patches
SURVEYAREA_S=1.784322e+06    #KiDS-Legacy
#Survey Area in arcmin for the combined patches
SURVEYAREADEG_S=495.6449     #KiDS-Legacy

#Survey Mask File
SURVEYMASKFILE_NS=/net/home/fohlen11/awright/KiDS/Legacy/Production/KiDS/mosaic_masks/healpix/KiDS_Legacy_NS_healpix_4096_frac.fits
#Survey Area in arcmin for the combined patches
SURVEYMASKFILE_N=/net/home/fohlen11/awright/KiDS/Legacy/Production/KiDS/mosaic_masks/healpix/KiDS_Legacy_N_healpix_4096_frac.fits
#Survey Area in arcmin for the combined patches
SURVEYMASKFILE_S=/net/home/fohlen11/awright/KiDS/Legacy/Production/KiDS/mosaic_masks/healpix/KiDS_Legacy_S_healpix_4096_frac.fits

#Bin slop
BINSLOP=1.5
BINSLOPNN=""
BINSLOPNG=""

#Remove SNR-R-Z_B c-term during shape recalibration
SHAPECAL_CTERM=True

#Multiple to include in Bmode significance computation (Ask Benjmain)
MULT=1.0



