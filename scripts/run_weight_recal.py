# -*- coding: utf-8 -*-
# @Author: lshuns
# @Date:   2022-05-31 15:06:40
# @Last Modified by:   lshuns
# @Last Modified time: 2022-09-26 17:26:26

### correct alpha in variance with method C
############ (20*20 resolution and SNR bins)
############ direct correction
############ assume scalelength and R cut already applied

import os
import argparse

import pandas as pd 
import numpy as np
import ldac 

import statsmodels.api as sm
import mcal_functions as mcf 

# +++++++++++++++++++++++++++++ parser for command-line interfaces
parser = argparse.ArgumentParser(
    description=f"step1_methodC.py: correct alpha in variance with method C.",
    formatter_class=argparse.RawTextHelpFormatter)
parser.add_argument(
    "--inpath", type=str,
    help="the in path for the catalogue.")
parser.add_argument(
    "--outpath", type=str, 
    help="the output path for the final catalogue") 
parser.add_argument(
    "--nbins_SNR", type=int,default=20,
    help="number of SNR bins.")
parser.add_argument(
    "--nbins_R", type=int,default=20,
    help="number of resolution bins.")
parser.add_argument(
    "--col_weight", type=str,
    help="columns to the weight in the catalogue.")
parser.add_argument(
    "--col_var", type=str,
    help="columns to the variance in the catalogue.")
parser.add_argument(
    "--col_snr", type=str,
    help="columns to the SNR in the catalogue.")
parser.add_argument(
    "--cols_e12", type=str, nargs=2, 
    help="column names for e1_gal, e2_gal.")
parser.add_argument(
    "--cols_e12_corr", type=str, nargs=2, default=None,
    help="column names for e1, e2, correction.")
parser.add_argument(
    "--cols_e12_raw", type=str, nargs=2, default=None,
    help="column names for e1, e2, raw measurement.\n\
    this or cols_e12_corr should be exclusive.")
parser.add_argument(
    "--cols_psf_e12", type=str, nargs=2, 
    help="column names for e1_psf, e2_psf.")
parser.add_argument(
    "--flagsource", type=str, default='False',
    help="Do we want to flag and remove outlying sources?.")

## arg parser
args = parser.parse_args()

col_weight = args.col_weight
col_var = args.col_var
col_snr = args.col_snr
col_e1, col_e2 = args.cols_e12
flagsource = args.flagsource == "True"
print([args.flagsource,flagsource])

if args.cols_e12_corr is not None:
    col_e1_corr, col_e2_corr = args.cols_e12_corr
elif args.cols_e12_raw is not None:
    col_e1_raw, col_e2_raw = args.cols_e12_raw
else:
    raise Exception('either cols_e12_corr or cols_e12_raw has to be provided!')

col_psf_e1, col_psf_e2 = args.cols_psf_e12

# +++++++++++++++++++++++++++++ workhorse
# >>>>>>>>>>>>>>>>>>> values for variance to weight
#  set discretisation correction (see flensfit)
tinterval = 0.02
tintervalsq = tinterval*tinterval
# give prior weight quantities
priorsigma = 0.253091
# give prior weight quantities
priormoment = 2.*priorsigma*priorsigma
efunc_emax = 0.804
maxmoment = efunc_emax*efunc_emax/2.
maxweight = 2*(maxmoment-tintervalsq)/(tintervalsq*maxmoment + priormoment*(maxmoment-tintervalsq))
minweight = 0

# >>>>>>>>>>>>>>>>>>> load info
obj_cat, ldac_cat = mcf.flexible_read(args.inpath)

print('number total', len(obj_cat))
# all float32 to float64
#for key in obj_cat.keys(): 
#    if np.issubdtype(obj_cat[key].dtype,np.floating):
#        print(f'updating key {key}') 
#        obj_cat[key] = obj_cat[key].astype(np.float64)

# get the raw e
if 'col_e1_corr' in locals(): 
    obj_cat['raw_e1'] = obj_cat[col_e1]-obj_cat[col_e1_corr]
    obj_cat['raw_e2'] = obj_cat[col_e2]-obj_cat[col_e2_corr]
else:
    obj_cat['raw_e1'] = obj_cat[col_e1_raw]
    obj_cat['raw_e2'] = obj_cat[col_e2_raw]

print('Ready with raw e1e2')

# a unique id for easy merge
obj_cat['AlphaRecal_index'] = np.arange(len(obj_cat))

print(obj_cat['AlphaRecal_index'])

# >>>>>>>>>>>>>>>>>>>> binning

print('Computing R bins')

# start with R bin
obj_cat['bin_R'] = pd.qcut(obj_cat['R'], args.nbins_R,duplicates='drop',
                                    labels=False, retbins=False)

print('Computing SNR bins')

# initialize
obj_cat['bin_snr'] = np.zeros(len(obj_cat)) + -999

# in each R bin, do SNR binning
for ibin_R in range(args.nbins_R):

    # select catalogue
    mask_binR = (obj_cat['bin_R'] == ibin_R)

    if any(mask_binR):
        # bin in R
        obj_cat.loc[mask_binR,'bin_snr'] = pd.qcut(obj_cat.loc[mask_binR,col_snr], args.nbins_SNR, 
                                                   duplicates='drop',labels=False, retbins=False)
                                                

print('Constructing Data Frame')

# construct an intermediate pd df for grouping 
pd_cat = pd.DataFrame({'bin_R':obj_cat['bin_R'],
                       'bin_snr':obj_cat['bin_snr'],
                       'AlphaRecal_index':obj_cat['AlphaRecal_index'],
                       f'{col_var}':obj_cat[col_var],
                       'raw_e1':obj_cat['raw_e1'],
                       'raw_e2':obj_cat['raw_e2'],
                       f'{col_psf_e1}':obj_cat[col_psf_e1],
                       f'{col_psf_e2}':obj_cat[col_psf_e2] })

print('Starting recalibration')
# group based on binning
pd_cat_corr = []
for name, group in pd_cat.groupby(by=['bin_R', 'bin_snr']):
    # Total sort + groupby

    # >>>>>>>>>>>>>>>> calculate alpha
    # unique index
    index_obj = group['AlphaRecal_index'].values
    # variance
    Var = np.array(group[col_var])
    # out shear
    e1_out = np.array(group['raw_e1'])
    e2_out = np.array(group['raw_e2'])
    emod_out = np.hypot(e1_out, e2_out)
    # out PSF 
    e1_psf = np.array(group[col_psf_e1])
    e2_psf = np.array(group[col_psf_e2])
    del group
    # rotate to PSF frame
    mask_tmp = emod_out > 0
    e_psf_rotated = e1_out * e1_psf + e2_out * e2_psf
    e_psf_rotated[mask_tmp] /= emod_out[mask_tmp]
    del mask_tmp, e1_psf, e2_psf, e1_out, e2_out, emod_out
    #clip extreme data 
    dev = np.abs(Var-np.median(Var))
    fitmask = (dev <= 5*1.4826*np.median(dev))
    # calculate alpha using least square
    mod_ols = sm.OLS(Var[fitmask], sm.add_constant(e_psf_rotated[fitmask]))
    # compute the heteroskedasticity weights 
    res_ols = mod_ols.fit()
    fitvals = res_ols.predict()
    residuals = np.abs(Var[fitmask]-fitvals)
    resid_mod_ols = sm.OLS(residuals,sm.add_constant(fitvals))
    resid_wgt = 1.0 / resid_mod_ols.fit().predict()**2
    #Fit weighted model with heteroskedasticity weights 
    mod_wls = sm.WLS(Var[fitmask], sm.add_constant(e_psf_rotated[fitmask]),weights=resid_wgt)

    ##Get the results 
    #res_ols = mod_ols.fit()
    #alpha = res_ols.params[1]

    #Get the results 
    try: 
        res_wls = mod_wls.fit()
        alpha = res_wls.params[1]
        fitvals = res_wls.get_prediction(sm.add_constant(e_psf_rotated))
    except:
        print(f"warning: weighted LS fit failed in bin {name}")
        alpha = res_ols.params[1]
        fitvals = res_ols.get_prediction(sm.add_constant(e_psf_rotated))
    
    #Get the confidence interval 
    conf_int = fitvals.conf_int(obs=True,alpha=0.3173105)
    conf_int = conf_int[:,1]-conf_int[:,0]
    mask = ((Var > fitvals.predicted + conf_int*5) | (Var < fitvals.predicted - conf_int*5))
    # alpha_err = (res_ols.cov_params()[1, 1])**0.5

    # >>>>>>>>>>>>>>>> correct 
    ## get logvar correction
    Var_corr = Var - alpha * e_psf_rotated
    del e_psf_rotated, Var

    # >>>>>>>>>>>>>>>> save
    pd_cat_tmp = pd.DataFrame({'AlphaRecal_index': index_obj, 
                            'AlphaRecalC_variance': Var_corr,
                            'mask': mask})
    del index_obj, Var_corr, mask, fitvals, conf_int
    pd_cat_corr.append(pd_cat_tmp)
    del pd_cat_tmp

print("Done! Constructing final catalogue")
pd_cat_corr = pd.concat(pd_cat_corr)

# transfer back to weights
## hard cut on min var
pd_cat_corr.loc[:, 'AlphaRecalC_variance'] = np.maximum(pd_cat_corr['AlphaRecalC_variance'].values, tintervalsq)
## now convert these new 2Dvariances into weights
pd_cat_corr.loc[:, 'AlphaRecalC_weight'] = 2*(maxmoment - pd_cat_corr['AlphaRecalC_variance'].values)\
                / (pd_cat_corr['AlphaRecalC_variance'].values*maxmoment \
                    + priormoment*(maxmoment - pd_cat_corr['AlphaRecalC_variance'].values))
## post process of weights
pd_cat_corr.loc[(pd_cat_corr['AlphaRecalC_weight']>maxweight), 'AlphaRecalC_weight'] = maxweight
pd_cat_corr.loc[(pd_cat_corr['AlphaRecalC_weight']<maxweight/1000.), 'AlphaRecalC_weight'] = 0.
if flagsource: 
    print('number with well modelled alphas after weight recalibration', np.sum(pd_cat_corr['mask']==False), 'fraction', np.sum(pd_cat_corr['mask']==False)/len(pd_cat_corr))
    pd_cat_corr.loc[(pd_cat_corr['mask']), 'AlphaRecalC_weight'] = 0.
    pd_cat_corr.drop('mask',axis=1,inplace=True) 

# merge
obj_cat = obj_cat.merge(pd_cat_corr, how = 'outer', on = 'AlphaRecal_index',suffixes=('_orig',None))
# if raw weight is zero, keep it zero
obj_cat.loc[obj_cat[col_weight]<maxweight/1000.,'AlphaRecalC_weight'] = 0

# save
mcf.flexible_write(obj_cat,args.outpath, ldac_cat)
print('final results saved to', args.outpath)

