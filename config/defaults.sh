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
BLIND=A

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

#List of m-bias values 
MBIASVALUES="-0.0128 -0.0104 -0.0114 +0.0072 +0.0061"
#List of m-bias uncertainties
MBIASERRORS="0.02 0.02 0.02 0.02 0.02"
#m-bias correlation  
MBIASCORR=0.99

#Limits of the tomographic bins
TOMOLIMS='0.1 0.3 0.5 0.7 0.9 1.2'
#TOMOLIMS='0.10 0.42 0.58 0.71 0.90 1.14 2.00'

#Variable used to define tomographic bins 
TOMOVAR=Z_B

#Theta limits for covariance 
THETAMINCOV="0.50"
#Theta limits for covariance 
THETAMAXCOV="300.00"

#Theta limits for xipm (can be highres for BP/COSEBIs)
THETAMINXI="0.50"
#Theta limits for xipm (can be highres for BP/COSEBIs)
THETAMAXXI="300.00"
#Number of Theta bins for xipm (can be highres for BP/COSEBIs)
NTHETABINXI="1000"
#Number of Xipm bins used for science 
NXIPM=9 
#Maximum Theta for analysing Xim (arcmin)
THETAMAXXIM=300
#Minimum Theta for analysing Xim (arcmin) 
THETAMINXIM=4

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

#Name of the base file for cosmosis/onecov
NPAIRBASE=XI_KiDS_1000_NScomb_nBins_5

#Statistic of choice for chain 
STATISTIC=cosebis

#Sampler 
SAMPLER=multinest

#Boltzman Code 
BOLTZMAN=COSMOPOWER_HM2015_S8

#Simulated spectroscopic calibration sample(s)
SIMSPECZCAT=/net/home/fohlen13/jlvdb/LegaZy/TEST/SKiLLS_spec/realisation/

#Simulated catalogues with constant shear 
SIMMAINCAT=/net/home/fohlen11/awright/SKiLLS/skills_v07D7ten_single/
#SIMMAINCAT=/net/home/fohlen12/awitt/KiDS_mock_photometry/mice2/mag/test_full_all/mice2_all_result_photoz_recalweight.fits
#SIMMAINCAT=/net/home/fohlen11/awright/KiDS/Legacy/StratLearn/MICE2_KV450/ 
#SIMMAINCAT=/net/home/fohlen11/awright/SKiLLS/skills_v07D7ten/

#Simulated catalogues with variable shear 
SIMVARCAT=/net/home/fohlen11/awright/SKiLLS/skills_v07D7p1/

#Catalogue of Blended objects in Simulated catalogues
SIMBLENDCAT=/net/home/fohlen11/awright/SKiLLS/SKiLLS/skills_v07D7p1_lite_blended/

#COSEBI file base name 
COSEBISBASE=@BV:COSEBISBASE@

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
#Compute the split-gaussian component of the covariance (True or False) 
SPLITGAUSS=True 
#Compute the super-sample component of the covariance (True or False) 
SSC=True 

#Number of ell bins for covariance computation 
LBINSCOV=100
#Minimum of ell bins for covariance computation 
LMINCOV=2
#Maximum of ell bins for covariance computation 
LMAXCOV=10000

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
#Priors: A_IA
PRIOR_AIA="-6.0 1.0 6.0"

#Magnitude limits for the wide field sample (effective after weighting)
MAGLIMITS="20 23.5"

#Filter for defining the magnitude limits for the wide field sample (effective after weighting)
MAGLIMIT_FILTER="r"



