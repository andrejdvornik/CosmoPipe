# ----------------------------------------------------------------
# File Name:           correct_cterm.py
# Author:              Angus H Wright (awright@astro.rub.de)
# Author:              Catherine Heymans (heymans@roe.ac.uk)
# Description:         short python script to apply a c-correction
# ----------------------------------------------------------------
import sys
import ldac
import numpy as np
from astropy.io import fits
from argparse import ArgumentParser

parser = ArgumentParser(description='Take input information and output a treecorr input catalogue ')
parser.add_argument("-i", "--inputfile", dest="inputfile",
    help="Full Input file name", metavar="inputFile",required=True)
parser.add_argument("-o", "--outputfile", dest="outputfile",
    help="Full Output file name", metavar="outputFile",required=True)

args = parser.parse_args()
    
#open the ldac catalogue using functions in ldac.py
#tests have shown ldac.py is much faster than using astropy
ldac_cat = ldac.LDACCat(args.inputfile)
ldac_table = ldac_cat['OBJECTS']

#Ellipticity names 
e1colname='@BV:E1NAME@'
e2colname='@BV:E2NAME@'
#Weight name 
wtcolname='@BV:WEIGHTNAME@' 
#PSF Ellipticity names 
psfe1colname='@BV:PSFE1NAME@'
psfe2colname='@BV:PSFE2NAME@'
#RADec Names 
racolname='@BV:RANAME@'
deccolname='@BV:DECNAME@'

#Select required columns 
e1=ldac_table[e1colname]
e2=ldac_table[e2colname]
weight=ldac_table[wtcolname]

# Lets also pass through the PSF ellipticity for star-gal-xcorr 
PSF_e1=ldac_table[psfe1colname]
PSF_e2=ldac_table[psfe2colname]

#RAdec names 
ra=ldac_table[racolname]
dec=ldac_table[deccolname]

#carry through the square of the weight for
#Npair calculation hack with Treecorr
wsq=weight*weight

#Write out to output file - crucial that RA/DEC (in degrees) are double precision
#If you don't have that you round to a couple of arcsec for fields with ra > 100
hdulist = fits.BinTableHDU.from_columns(
    [fits.Column(name=racolname, format='1D', unit='deg',array=ra),
     fits.Column(name=deccolname, format='1D', unit='deg',array=dec),
     fits.Column(name=e1colname, format='1E', array=e1),
     fits.Column(name=e2colname, format='1E', array=e2),
     fits.Column(name=psfe1colname, format='1E', array=PSF_e1),
     fits.Column(name=psfe2colname, format='1E', array=PSF_e2),
     fits.Column(name=wtcolname, format='1E', array=weight),
     fits.Column(name=wtcolname+'_sq', format='1E', array=wsq)])
hdulist.writeto(args.outputfile, overwrite=True)
