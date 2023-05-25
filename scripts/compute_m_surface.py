#=========================================
#
# File Name : compute_m_surface.py
# Created By : awright
# Creation Date : 08-05-2023
# Last Modified : Thu 25 May 2023 11:05:01 PM CEST
#
#=========================================

### estimate m in SNR and R bins using constant image simulations

import numpy as np
import pandas as pd
import statsmodels.api as sm 

from scipy import stats
from argparse import ArgumentParser
import mcal_functions as mcf

# >>>>>>>>>>>>>>>>>>>>>>>>>>>>> Arguments 
parser = ArgumentParser(description='Construct an m-calibration surface')
parser.add_argument("--input", dest="inputpath",
            help="Full Input file name and path", metavar="input",required=True)
parser.add_argument("--output", dest="outputpath",
            help="Full Output file name and path",required=True)
parser.add_argument("--etype", dest="etype",type=str,
            help="Ellipticity type to be used for calculating m [measured/true]",required=True)
parser.add_argument("--e12name", dest="col_e12",nargs=2,
            help="Column names for the e1/e2 variables",required=True)
parser.add_argument("--g12name", dest="col_g12",nargs=2,
            help="Column names for the g1/g2 variables",required=True)
parser.add_argument("--weightname", dest="col_weight",
            help="Column name for the weight variable",required=True)
parser.add_argument("--SNRname", dest="col_SNR",
            help="Column name for the SNR variable",required=True)
parser.add_argument("--Rname", dest="col_R",
            help="Column name for the Resolution variable",required=True)
parser.add_argument("--labelname", dest="col_label",
            help="Column name for the sub-simulation label variable",required=True)
parser.add_argument("--nbinR", dest="N_R",default=20,type=int,
            help="Number of bins in Resolution to construct")
parser.add_argument("--nbinSNR", dest="N_SNR",default=20,type=int,
            help="Number of bins in SNR to construct")

#Parse the arguments
args = parser.parse_args()

# load simulation catalogue
cata_sim = mcf.flexible_read(args.inputpath)
try: 
    ncat=len(cata_sim['SeqNr'])
except: 
    ncat=len(cata_sim)

print('Number of sources in the catalogue', ncat)

# get shear values
if args.etype == "true": 
    print('Using input g12 to create e12')
    # perfect shear values from input e
    e1_out, e2_out = mcf.e12_from_g12(cata_sim,args.col_e12,args,col_g12)

elif args.etype == "measured": 
    print('Using observed e12')
    # measured values
    e1_out = np.array(cata_sim[args.col_e12[0]])
    e2_out = np.array(cata_sim[args.col_e12[1]])
else: 
    raise ValueError("etype must be one of 'measured' or 'true', not {args.etype}")

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

# dataframe for saving m_surface definition
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
SNR_edges, R_edges_list = mcf._WgBin2DFunc_SNR_R(cata_used.loc[:, 'SNR'].values, 
                          cata_used.loc[:, 'R'].values, 
                          cata_used.loc[:, 'shape_weight'].values, 
                          args.N_SNR, args.N_R, right=True)

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

# save and read the edge values, and bin the galaxies again (for reproducablility)
mc_surface.to_csv(args.outputpath, index=False, float_format='%.6f')
print(f'edge values saved to {args.outputpath}')

#Read the m surface 
mc_surface = mcf.flexible_read(args.outputpath)
## bin galaxies
cata_used.loc[:, 'binSNR_id'] = -999
cata_used.loc[:, 'binR_id'] = -999

# bin the sim catalogue 
cata_used = mcf.binby_SNR_R(surface=mc_surface,cata=cata_used,SNRname='SNR',Rname='R')

# group
## drop -999 bins
cata_used = cata_used[(cata_used['binSNR_id']>-999)&(cata_used['binR_id']>-999)].copy()
cata_used.reset_index(drop=True, inplace=True)
print('number within surface', len(cata_used))
## sort to speed up
cata_used = cata_used.astype({'binSNR_id': int, 'binR_id': int})
cata_used.sort_values(by=['binSNR_id', 'binR_id'], inplace=True)
cata_used = cata_used.groupby(by=['binSNR_id', 'binR_id'])

# loop over groups and calculate m
i_group = 0
for name, group in cata_used:
    binSNR_id, binR_id = name

    ## mc fitting
    #try: 
    #    res_bin = mcf.mCalFunc_tile_based(group)
    #except: 
    #    res_bin = mcf.mCalFunc_pair_based(group)
    res_bin = mcf.mCalFunc_tile_based(group)

    #Check for indexing error: 
    if mc_surface.loc[i_group,"binSNR_id"] != binSNR_id or \
       mc_surface.loc[i_group,"binR_id"] != binR_id: 
           raise Exception("Indexing error in the m_surface construction!")


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

