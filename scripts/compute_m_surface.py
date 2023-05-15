# -*- coding: utf-8 -*-
# @Author: lshuns
# @Date:   2023-05-01 11:33:43
# @Last Modified by:   lshuns
# @Last Modified time: 2023-05-03 14:47:17

### estimate m in SNR and R bins using constant image simulations

import numpy as np
import pandas as pd
import statsmodels.api as sm 

from scipy import stats
from astropy.io import fits
from astropy.table import Table
from argparse import ArgumentParser

# >>>>>>>>>>>>>>>>>>>>>>>>>>>>> I/O
parser = ArgumentParser(description='Construct an m-calibration surface')
parser.add_argument("--input", dest="inputpath",
            help="Full Input file name and path", metavar="input",required=True)
parser.add_argument("--output", dest="outputpath",
            help="Full Output file name and path",required=True)
parser.add_argument("--e12name", dest="col_e12",nargs=2,
            help="Column names for the e1/e2 variables",required=True)
parser.add_argument("--g12name", dest="col_g12",nargs=2,
            help="Column names for the g1/g2 variables")
parser.add_argument("--weightname", dest="col_weight",
            help="Column name for the weight variable")
parser.add_argument("--SNRname", dest="col_SNR",
            help="Column name for the SNR variable",required=True)
parser.add_argument("--Rname", dest="col_R",
            help="Column name for the Resolution variable",required=True)
parser.add_argument("--labelname", dest="col_label",
            help="Column name for the sub-simulation label variable")
parser.add_argument("--nbinR", dest="N_R",default=20,type=int,
            help="Number of bins in Resolution to construct")
parser.add_argument("--nbinSNR", dest="N_SNR",default=20,type=int,
            help="Number of bins in SNR to construct")

#Parse the arguments
args = parser.parse_args()

# >>>>>>>>>>>>>>>>>>>>>>>>>>>>> functions
def _WgQuantile1DFunc_SNR_R(values, weights, Nbin):
    """
    Calculate the weighted quantile by given bin numbers
        designed for 1D numpy array.
    """

    # Define the quantile points based on the number of bins
    pq = np.linspace(0, 1, Nbin+1)

    # Sort the data
    ind_sorted = np.argsort(values)
    v_sorted = values[ind_sorted]
    wg_sorted = weights[ind_sorted]
    del ind_sorted, values, weights

    # Compute the quantiles
    Pn = (np.cumsum(wg_sorted) - 0.5*wg_sorted)/np.sum(wg_sorted)

    # interp the quantiles
    res = np.interp(pq, Pn, v_sorted)

    # include all points
    res[0] = 0.
    res[-1] = 999.
    return res

def _WgBin2DFunc_SNR_R(v1, v2, wgs, Nbin1, Nbin2, right=True):
    """
    Calculate the weighted quantile by given bin numbers
        designed for 2D numpy array
    """

    # Calculate quantiles for v1
    q1 = _WgQuantile1DFunc_SNR_R(v1, wgs, Nbin1)

    #Compute quantiles for v2 in each v1 bin
    q2s = np.zeros((Nbin1, Nbin2+1))
    for i in range(Nbin1):

        if right:
            mask = (v1>q1[i]) & (v1<=q1[i+1])
        else:
            mask = (v1>=q1[i]) & (v1<q1[i+1])

        q2s[i] = _WgQuantile1DFunc_SNR_R(v2[mask], wgs[mask], Nbin2)

    return q1, q2s

def mCalFunc_tile_based(cataSim, psf_frame=False):
    """
    NOTE: this can only be used when 
        1. the input shear are constant across the tile image
        2. number of tiles are sufficient large

    Calculate the residual shear bias for a given simulated catalogue
        it first calculates shear g_out for each tile (accounting for shape noise cancellation)
            then estimate bias using all tiles and shear inputs by requiring sum(g_out - (1+m)g_in) -> min

        Used columns and their names:
            tile_label: unique label for tile
            g1_in, g2_in: input shear
            e1_out, e2_out: measured ellipticity
            shape_weight: shape measurement weights
            if psf_frame:
                e1_psf, e2_psf: ellipticity of PSF
    """

    # out gal e
    e1_out = np.array(cataSim['e1_out'])
    e2_out = np.array(cataSim['e2_out'])

    # rotate to psf frame
    if psf_frame:
        print('Measured e will be rotated to PSF frame...')
        # out PSF 
        e1_psf = np.array(cataSim['e1_psf'])
        e2_psf = np.array(cataSim['e2_psf'])
        PSF_angle = np.arctan2(e2_psf, e1_psf)

        # rotate the ellipticities
        ct = np.cos(PSF_angle)
        st = np.sin(PSF_angle)
        e1_uc = e1_out*ct + e2_out*st
        e2_uc = -e1_out*st + e2_out*ct
        del e1_psf, e2_psf, PSF_angle, ct, st

        e1_out = e1_uc
        e2_out = e2_uc
        del e1_uc, e2_uc

    # build dataframe and select used columns
    cataSim = pd.DataFrame({'tile_label': np.array(cataSim['tile_label']),
                            'g1_in': np.array(cataSim['g1_in']),
                            'g2_in': np.array(cataSim['g2_in']),
                            'e1_out': e1_out,
                            'e2_out': e2_out,
                            'shape_weight': np.array(cataSim['shape_weight'])
                            })
    del e1_out, e2_out

    # sort to speed up
    cataSim.sort_values(by=['tile_label', 'g1_in', 'g2_in'], inplace=True)

    # prepare the weighted mean
    cataSim.loc[:, 'e1_out'] *= cataSim['shape_weight'].values
    cataSim.loc[:, 'e2_out'] *= cataSim['shape_weight'].values

    # group based on tile and shear
    cataSim = cataSim.groupby(['tile_label', 'g1_in', 'g2_in'], as_index=False).sum()
    if len(cataSim) < 10:
        raise Exception('less than 10 points for lsq, use pair_based!')
    # print('number of groups (points) for lsq', len(cataSim))
    ## last step of the weighted mean
    cataSim.loc[:, 'e1_out'] /= cataSim['shape_weight'].values
    cataSim.loc[:, 'e2_out'] /= cataSim['shape_weight'].values

    # get least square values
    ## e1
    mod_wls = sm.WLS(cataSim['e1_out'].values, 
                     sm.add_constant(cataSim['g1_in'].values,has_constant='add'),
                     weights=cataSim['shape_weight'].values)
    res_wls = mod_wls.fit() 
    print(res_wls.summary())
    print(res_wls.params)
    m1 = res_wls.params[1] - 1
    c1 = res_wls.params[0]
    m1_err = (res_wls.cov_params()[1, 1])**0.5
    c1_err = (res_wls.cov_params()[0, 0])**0.5
    ## e2
    mod_wls = sm.WLS(cataSim['e2_out'].values, 
                        sm.add_constant(cataSim['g2_in'].values,has_constant='add'), 
                        weights=cataSim['shape_weight'].values)
    res_wls = mod_wls.fit()
    print(res_wls.summary())
    m2 = res_wls.params[1] - 1
    c2 = res_wls.params[0]
    m2_err = (res_wls.cov_params()[1, 1])**0.5
    c2_err = (res_wls.cov_params()[0, 0])**0.5

    # save
    del cataSim
    res = {'m1': m1, 'm2': m2,
            'c1': c1, 'c2': c2,
            'm1_err': m1_err, 'm2_err': m2_err,
            'c1_err': c1_err, 'c2_err': c2_err,
            }

    return res

# >>>>>>>>>>>>>>>>>>>>>>>>>>>>> workhorse

# load simulation catalogue
file_type = args.inputpath[-3:]
if file_type == 'csv':
    cata_sim = pd.read_csv(args.inputpath)
elif file_type == 'her':
    cata_sim = pd.read_feather(args.inputpath)
elif file_type == 'its':
    with fits.open(args.inputpath) as hdul:
        cata_sim = hdul[1].data
else:
    raise Exception(f'Not supported input file type! {args.inputpath}')
print('Number of sources in the catalogue', len(cata_sim))

# get shear values
if args.col_g12 is not None: 
    print('Using input g12 to create e12')
    # perfect shear values from input e
    g = np.array(cata_sim[args.col_g12[0]]) + 1j*np.array(cata_sim[args.col_g12[1]])
    e_in_gal = np.array(cata_sim[args.col_e12[0]]) + 1j*np.array(cata_sim[args.col_e12[1]])
    e_true = (e_in_gal+g) / (1+np.conj(g)*e_in_gal)

    e1_out = (e_true.real).astype(float)
    e2_out = (e_true.imag).astype(float)
else:
    print('Using observed e12')
    # measured values
    e1_out = np.array(cata_sim[args.col_e12[0]])
    e2_out = np.array(cata_sim[args.col_e12[1]])

# save useable parameters
cata_used = pd.DataFrame({
    'e1_out': e1_out.astype(float),
    'e2_out': e2_out.astype(float),
    'g1_in': np.array(cata_sim[args.col_g12[0]]).astype(float),
    'g2_in': np.array(cata_sim[args.col_g12[1]]).astype(float),
    'SNR': np.array(cata_sim[args.col_SNR]).astype(float),
    'R': np.array(cata_sim[args.col_R]).astype(float),
    'tile_label': np.array(cata_sim[args.col_label]).astype(str),
    })
del e1_out, e2_out
## weight for galaxies
if args.col_weight is not None:
    cata_used.loc[:, 'shape_weight'] = np.array(cata_sim[args.col_weight]).astype(float)
else:
    cata_used.loc[:, 'shape_weight'] = 1
## delete original catalogue
del cata_sim

# select non-zero weights
cata_used = cata_used[cata_used['shape_weight']>0]
cata_used.reset_index(drop=True, inplace=True)
print('selected objects (weight>0)', len(cata_used))
## for saving binning info
cata_used.loc[:, 'binSNR_id'] = -999
cata_used.loc[:, 'binR_id'] = -999

# dataframe for saving results
mc_surface = pd.DataFrame(-999., 
                    index = np.arange(args.N_SNR*args.N_R), 
                    columns = ['binSNR_id', 'binR_id',
                                'binSNR_min', 'binSNR_max',
                                'binR_min', 'binR_max',
                                'm1_raw', 'm1_raw_err', 'm2_raw', 'm2_raw_err',
                                'c1', 'c1_err', 'c2', 'c2_err'])
mc_surface = mc_surface.astype({'binSNR_id': int, 'binR_id': int})

i_group = 0
# get the binning edges
SNR_edges, R_edges_list = _WgBin2DFunc_SNR_R(cata_used.loc[:, 'SNR'].values, 
        cata_used.loc[:, 'R'].values, 
        cata_used.loc[:, 'shape_weight'].values, 
                                    args.N_SNR, args.N_R,
                                    right=True)

## bin in SNR
cata_used.loc[:, 'binSNR_id'] = pd.cut(cata_used.loc[:, 'SNR'].values, SNR_edges, 
                            right=True, labels=False)
## bin in the R
for i_SNR, R_edges in enumerate(R_edges_list):
    mask_binSNR = cata_used['binSNR_id'].values == i_SNR
    cata_used.loc[mask_binSNR, 'binR_id'] = pd.cut(
                                cata_used.loc[mask_binSNR, 'R'].values, 
                                R_edges, 
                                right=True, labels=False)
    del mask_binSNR

    # save edge values
    for i_R in range(len(R_edges)-1):
        mc_surface.loc[i_group, 'binSNR_id'] = i_SNR
        mc_surface.loc[i_group, 'binR_id'] = i_R
        mc_surface.loc[i_group, 'binSNR_min'] = SNR_edges[i_SNR]
        mc_surface.loc[i_group, 'binSNR_max'] = SNR_edges[i_SNR+1]
        mc_surface.loc[i_group, 'binR_min'] = R_edges[i_R]
        mc_surface.loc[i_group, 'binR_max'] = R_edges[i_R+1]
        i_group += 1

# save and read the edge values, and bin the galaxies again for reproducable
mc_surface.to_csv(args.outputpath, index=False, float_format='%.6f')
print(f'edge values saved to {args.outputpath}')
mc_surface = pd.read_csv(args.outputpath)
## bin galaxies
cata_used.loc[:, 'binSNR_id'] = -999
cata_used.loc[:, 'binR_id'] = -999

SNR_edges = np.unique(mc_surface.loc[:,'binSNR_min']).tolist() \
            + [np.max(mc_surface.loc[:,'binSNR_max'])]

cata_used.loc[:, 'binSNR_id'] = pd.cut(cata_used.loc[:, 'SNR'].values, SNR_edges, 
                            right=True, labels=False)

for i_SNR in range(len(SNR_edges)-1):

    R_edges = np.unique(mc_surface.loc[(mc_surface['binSNR_id']==i_SNR),'binR_min']).tolist() \
              + [np.max(mc_surface.loc[(mc_surface['binSNR_id']==i_SNR),'binR_max'])]

    mask_binSNR = cata_used['binSNR_id'].values == i_SNR
    cata_used.loc[mask_binSNR, 'binR_id'] = pd.cut(cata_used.loc[mask_binSNR, 'R'].values, 
                                R_edges, right=True, labels=False)
    del mask_binSNR

# group
## drop -999 bins
cata_used = cata_used[(cata_used['binSNR_id']>-999)&(cata_used['binR_id']>-999)].copy()
cata_used.reset_index(drop=True, inplace=True)
print('number within doom', len(cata_used))
## sort to speed up
cata_used = cata_used.astype({'binSNR_id': int, 'binR_id': int})
cata_used.sort_values(by=['binSNR_id', 'binR_id'], inplace=True)
cata_used = cata_used.groupby(by=['binSNR_id', 'binR_id'])

# loop over groups and calculate m
i_group = 0
for name, group in cata_used:
    binSNR_id, binR_id = name

    # mc fitting
    res_bin = mCalFunc_tile_based(group)

    # save shear bias
    mc_surface.loc[i_group, 'm1_raw'] = res_bin['m1']
    mc_surface.loc[i_group, 'm1_raw_err'] = res_bin['m1_err']
    mc_surface.loc[i_group, 'm2_raw'] = res_bin['m2']
    mc_surface.loc[i_group, 'm2_raw_err'] = res_bin['m2_err']
    mc_surface.loc[i_group, 'c1'] = res_bin['c1']
    mc_surface.loc[i_group, 'c1_err'] = res_bin['c1_err']
    mc_surface.loc[i_group, 'c2'] = res_bin['c2']
    mc_surface.loc[i_group, 'c2_err'] = res_bin['c2_err']
    i_group += 1 
    del group

## save surface
mc_surface.to_csv(args.outputpath, index=False, float_format='%.6f')
print(f'results saved to {args.outputpath}')

