#
# Simply convert LDAC to FITS
#

import sys
import ldac
from astropy.io import fits 
import numpy as np
import tabeval
import argparse
import datetime
import os

def expand_path(path):
    """
    taken from: https://github.com/KiDS-WL/MICE2_mocks @ abandon-FITS-support
                -> MICE2_mocks/galmock/core/utils.py
    Normalises a path (e.g. from the command line) and substitutes environment
    variables and the user (e.g. ~/ or ~user/).
    Parameters:
    -----------
    path : str
        Input raw path.
    Returns:
    --------
    path : str
        Normalized absolute path with substitutions applied.
    """
    # check for tilde
    if path.startswith("~" + os.sep):
        path = os.path.expanduser(path)
    elif path.startswith("~"):  # like ~user/path/file
        home_root = os.path.dirname(os.path.expanduser("~"))
        path = os.path.join(home_root, path[1:])
    path = os.path.expandvars(path)
    path = os.path.normpath(path)
    path = os.path.abspath(path)
    return path

parser = argparse.ArgumentParser(
    description="ldac2fits convertion with ldac.py - "
                "convert LDAC to fits with optional filter using analytical expressions",
    epilog="Filter conditions support bracketing and implement the "
           "following operators: " + ", ".join(
               "%s (%s)" % (o.symbol, o.ufunc.__name__)
               for o in tabeval.math.operator_list))
parser.add_argument(
    "-i", metavar="input", type=expand_path, required=True,
    help="input LDAC table file")
parser.add_argument(
    "-o", metavar="output", type=expand_path, required=True,
    help="output FITS table file")
parser.add_argument(
    "-c", metavar="condition", required=True,
    help="filter condition to apply on table entries")
parser.add_argument(
    "-t", metavar="table", default="OBJECTS",
    help="name of table on which filter condition is applied "
         "(default: %(default)s)")

args = parser.parse_args()
condition = tabeval.MathTerm.from_string(args.c.strip(";"))

ldac_cat = ldac.LDACCat(args.i)
ldac_table = ldac_cat[args.t]

try:
    print("applying filter:     %s" % condition.code)
except AttributeError:
    raise SyntaxError("invalid expression '%s'" % args.c.strip(";"))
mask = condition(tab)
selected = sum(mask)
if selected == 0:
    raise ValueError("filter condition has no matching entries")
print("selecting entries:   %d of %d" % (selected, len(mask)))
ldac_table = ldac_table.filter(mask)

allcols=[]
for col in ldac_table.keys(): 
    format=str(ldac_table[col].dtype)
    if "<U" in format: 
        format=format.replace("<U","")+"A"
    else:
        format=np.dtype(format)
    allcols=np.append(allcols,
            [fits.Column(name=col, format=format, array=ldac_table[col])])

hdulist = fits.BinTableHDU.from_columns(allcols) 
hdulist.writeto(outfile, overwrite=True)


