##
# 
# KiDS COSMOLOGY PIPELINE Default Configuration Variables 
# Written by A.H. Wright (2019-09-30) 
#
##

# Defaults for runtime variables 

#i-magnitude label
IMAGNAME=i

#Blind Character
BLIND=C #A B C 

#Shape measurement variables: e1
E1NAME=autocal_e1_C
#Shape measurement variables: e2  
E2NAME=autocal_e2_C

#Uncorrected shape measurement variables: e1
RAWE1NAME=autocal_e1_C
#Uncorrected shape measurement variables: e2  
RAWE2NAME=autocal_e2_C

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
ZSPECNAME='z_spec_B'

#Photo-z column name
ZPHOTNAME='Z_B'

#Number of threads
NTHREADS=32

#Nz delta-z stepsize
NZSTEP=@NZSTEP@

#List of m-bias values 
MBIASVALUES="-0.0128 -0.0104 -0.0114 +0.0072 +0.0061"
#List of m-bias uncertainties
MBIASERRORS="0.02 0.02 0.02 0.02 0.02"
#m-bias correlation  
MBIASCORR=0.99

#Limits of the tomographic bins
TOMOLIMS='0.1 0.3 0.5 0.7 0.9 1.2'

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

#Minimum Number of modes for COSEBIs
NMINCOSEBIS=1
#Maximum Number of modes for COSEBIs
NMAXCOSEBIS=5

#Name of the lensing weight variable  
WEIGHTNAME=recal_weight_@BV:BLIND@

#Statistic of choice for chain 
STATISTIC=cosebis

#Sampler 
SAMPLER=multinest

#Boltzman Code 
BOLTZMAN=COSMOPOWER_HM2015_S8

#Simulated spectroscopic calibration sample(s)
SIMSPECZCAT=/net/home/fohlen13/jlvdb/LegaZy/TEST/SKiLLS_spec/realisation/

#Simulated catalogues with constant shear 
SIMMAINCAT=/net/home/fohlen11/awright/SKiLLS/skills_v07D7p1/

#Simulated catalogues with variable shear 
SIMVARCAT=/net/home/fohlen11/awright/SKiLLS/skills_v07D7p1/

#Catalogue of Blended objects in Simulated catalogues
SIMBLENDCAT=/net/home/fohlen11/awright/SKiLLS/SKiLLS/skills_v07D7p1_lite_blended/

#COSEBI file base name 
COSEBISBASE=@BV:COSEBISBASE@

#CosmoSIS pipeline specification
COSMOSIS_PIPELINE=@BV:COSMOSIS_PIPELINE@

#Data Vector Length 
DVLENGTH=@BV:DVLENGTH@

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
LBINSCOV=@BV:LBINSCOV@
#Minimum of ell bins for covariance computation 
LMINCOV=@BV:LMINCOV@
#Maximum of ell bins for covariance computation 
LMAXCOV=@BV:LMAXCOV@

#Number of ell bins for bandpowers computation 
LBINSBANDPOWERS=@BV:LBINSBANDPOWERS@
#Minimum of ell bins for bandpowers computation 
LMINBANDPOWERS=@BV:LMINBANDPOWERS@
#Maximum of ell bins for bandpowers computation 
LMAXBANDPOWERS=@BV:LMAXBANDPOWERS@

#Sampler to use as basis of 'list sampler' 
LIST_INPUT_SAMPLER=@BV:LIST_INPUT_SAMPLER@

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

#Number of iterations in SOM construction 
NITER=1000

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

#Sampler name 
SAMPLER=multinest

#Scale-length variable column name 
SCALELENGTHNAME=@BV:SCALELENGTHNAME@

#Simulation identifier label column name 
SIMLABEL=@BV:SIMLABEL@

#Path to Reference Chain for Figure Construction 
REFCHAIN=@BV:REFCHAIN@

#Statistic to compute 
STATISTIC=cosebis



