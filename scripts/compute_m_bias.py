#=========================================
#
# File Name : compute_m_surface.py
# Created By : awright
# Creation Date : 08-05-2023
# Last Modified : Fri 26 May 2023 02:13:18 PM CEST
#
#=========================================

import numpy as np
import pandas as pd
import statsmodels.api as sm 

from scipy import stats
from astropy.io import fits
from astropy.table import Table
from argparse import ArgumentParser

import mcal_functions as mcf 

# >>>>>>>>>>>>>>>>>>>>>>>>>>>>> Arguments 
parser = ArgumentParser(description='Compute m-bias from calibration surface')
parser.add_argument("--input_surface", dest="input_surface",
            help="Full Input file name and path for m-surface",required=True)
parser.add_argument("--input_cat", dest="input_data",
            help="Full Input file name and path", metavar="input",required=True)
parser.add_argument("--output", dest="outputpath",
            help="Full Output file name and path",required=True)
parser.add_argument("--m12name", dest="col_m12",nargs=2,
            help="Column names for the m1/m2 variables in the m_surface file",required=True)
parser.add_argument("--weightname", dest="col_weight",
            help="Column name for the weight variable",required=True)
parser.add_argument("--SNRname", dest="col_SNR",
            help="Column name for the SNR variable",required=True)
parser.add_argument("--Rname", dest="col_R",
            help="Column name for the Resolution variable",required=True)

#Parse the arguments
args = parser.parse_args()

# >>>>>>>>>>>>>>>> workhorse
# load data catalogue
cata_data = mcf.flexible_read(args.input_data)
print('Number of sources in the data', len(cata_data))

### select weight
print(args.col_weight)
print(cata_data)
cata_data = cata_data[cata_data[args.col_weight]>0]
cata_data.reset_index(drop=True, inplace=True)
print('selected objects (weight>0)', len(cata_data))

# load m calibraiton surface 
cata_surface = mcf.flexible_read(args.input_surface)

# calculate m
m_res = pd.DataFrame(-999., index=np.arange(1),
                    columns = ['m1', 'm2', 'm1_err', 'm2_err','Nwei'])
m1, m2, m1_err, m2_err = mcf.mCalFunc_from_surface(cata=cata_data, surface=cata_surface, 
                            col_SNR=args.col_SNR, col_R=args.col_R, col_weight=args.col_weight, 
                            col_m1=args.col_m12[0], col_m2=args.col_m12[1])
print(f'{args.input_data}: {(m1+m2)/2.}, {(m1_err+m2_err)/2.}')
m_res.loc[0, 'm1'] = m1
m_res.loc[0, 'm2'] = m2
m_res.loc[0, 'm1_err'] = m1_err
m_res.loc[0, 'm2_err'] = m2_err
m_res.loc[0, 'Nwei'] = np.sum(cata_data[col_weight].values)

m_res.to_csv(args.outputpath, index=False, float_format='%.6f')
print(f'results saved to {args.outputpath}')
