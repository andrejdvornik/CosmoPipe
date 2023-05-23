#!/usr/bin/env python
"""
Convert any variable width string columns to fixed width string columns

Signature: fits_str_col_fix.py $infile $outfile
"""
import sys

import astropandas as apd


if len(sys.argv) != 3:
    raise ValueError("input and output file paths are required arguments")

data = apd.read_fits(sys.argv[1])
for col, dtype in zip(data.columns, data.dtypes):
    if dtype.kind == "O":  # string columns are represented as python objects
        data[col] = data[col].astype("|S")  # required minimum width is determined automatically
        print("converted column '{:}' to data type '{:}'".format(col, data[col].dtype.str))
apd.to_fits(data, sys.argv[2])
