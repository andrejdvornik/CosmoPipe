#=========================================
#
# File Name : weight_from_map.py
# Created By : awright
# Creation Date : 25-10-2023
# Last Modified : Mon 30 Oct 2023 11:34:49 AM CET
#
#=========================================

#Load healpy 
import healpy as hp 
import astropandas as apd 
import os
import argparse
import mcal_functions as mcf 

# +++++++++++++++++++++++++++++ parser for command-line interfaces
parser = argparse.ArgumentParser(
    description=f"Add statistic from a healpix map to a catalogue",
    formatter_class=argparse.RawTextHelpFormatter)
parser.add_argument(
    "--incat", type=str,
    help="the in path for the catalogue.")
parser.add_argument(
    "--inmap", type=str,
    help="the in path for the healpix map.")
parser.add_argument(
    "--outpath", type=str, 
    help="the output path for the final catalogue") 
parser.add_argument(
    "--col_RA", type=str,
    help="column for the RA variable in the catalogue.")
parser.add_argument(
    "--col_Dec", type=str,
    help="column for the Dec variable in the catalogue.")
parser.add_argument(
    "--statname", type=str,
    help="column name for inherited statistic.")
parser.add_argument(
    "--function", type=str,default=None, 
    help="Function to modify the inherited statistic, using 'x' as the dependent variable name; e.g. '3*x**2+12'.")

## arg parser
args = parser.parse_args()

#load the map 
print("Reading healpix map")
hpmap=hp.read_map(args.inmap)
#Get the nside of the map 
nside=hp.npix2nside(len(hpmap))

#Read the catalogue 
print("Reading Catalogue")
cat, ldac_cat = mcf.flexible_read(args.incat,as_df=False)

#Get the statistic per source 
print("Extracting statistic")
tmp_stats=hpmap[hp.ang2pix(nside,cat[args.col_RA],cat[args.col_Dec],lonlat=True)]

#If needed, apply the modifier function 
if args.function is not None: 
    func=lambda x: eval(args.function)
    tmp_stats=func(tmp_stats)

cat[args.statname]=tmp_stats
#Write out the weight 
print("Writing inherited statistic")
#Write the catalogue 
mcf.flexible_write(cat,args.outpath,ldac_cat)


