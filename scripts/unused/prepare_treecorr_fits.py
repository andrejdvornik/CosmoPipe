#
# Simply convert LDAC to FITS
#

import sys
import ldac
from astropy.io import fits 


infile = sys.argv[1]
outfile = sys.argv[2]

ldac_cat = ldac.LDACCat(infile)
ldac_table = ldac_cat['OBJECTS']

hdulist = fits.BinTableHDU.from_columns(
    [fits.Column(name=col, format='1D', unit='deg',array=ldac_table[col]) for col in ["ALPHA_J2000","DELTA_J2000"]]+
    [fits.Column(name=col, format='1E', array=ldac_table[col]) for col in ['e1_corr','e2_corr','PSF_e1','PSF_e2','@WEIGHTNAME@','@WEIGHTNAME@_sq']])
hdulist.writeto(outfile, overwrite=True)
