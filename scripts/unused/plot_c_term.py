#!/usr/bin/python

import numpy as np
import matplotlib as ml
ml.use('Agg')
import matplotlib.pyplot as plt
import sys
import string
from matplotlib.ticker import ScalarFormatter, FormatStrFormatter
from palettable.colorbrewer.qualitative import Dark2_8

plt.rc('font', size=10)

patchlist="@ALLPATCH@ @PATCHLIST@"
patchlist=patchlist.split()

fmt=['x']+['o']*7
if len(patchlist) > 8:
    fmt=['o']*8+['x']*8

outfile = sys.argv[1]
infiles = sys.argv[2:]

indata = {}

i=0
for patch in patchlist:
    indata[patch] = np.loadtxt(infiles[i])
    indata[patch][:,0] = indata[patch][:,0] + i*0.01
    indata[patch][-2,0] = indata[patch][-2,0] + 0.05
    i+=1

i=0
fig, ax = plt.subplots(3, 1, sharex=True)
xpt,ypt=1.0,30.
fig.subplots_adjust(hspace=0)
for patch in patchlist:
    ax[0].set_xlim(0.01,1.19)
    ax[0].set_ylim(-4.9,1.9)
    ax[0].errorbar(indata[patch][:-1,0], indata[patch][:-1,2]*1e3, yerr=indata[patch][:-1,3]*1e3, fmt=fmt[i], color=Dark2_8.mpl_colors[i%8])
    ax[0].axhline(y=0., xmin=-1., xmax=3., color = 'k', linestyle = 'dotted')
    ax[0].set_ylabel(r'$<\epsilon_1> \times 10^3$')
    ax[1].set_ylim(-1.9,2.9)
    ax[1].errorbar(indata[patch][:-1,0], indata[patch][:-1,4]*1e3, yerr=indata[patch][:-1,5]*1e3, fmt=fmt[i], color=Dark2_8.mpl_colors[i%8])
    ax[1].axhline(y=0., xmin=-1., xmax=3., color = 'k', linestyle = 'dotted')
    ax[1].set_ylabel(r'$<\epsilon_2> \times 10^3$')
    ax[2].set_ylim(8.,34.)
    ax[2].plot(indata[patch][:-1,0], indata[patch][:-1,1], color=Dark2_8.mpl_colors[i%8])
    ax[2].set_ylabel(r'% weight per bin')
    ax[2].set_xlabel(r'$Z_\mathrm{B}$ midpoint of tomographic bin')
    ax[2].text(xpt,ypt,fmt[i]+' '+patchlist[i],  color=Dark2_8.mpl_colors[i%8])
    ypt=ypt-5
    if ypt < 20:
      xpt=xpt-0.2
      ypt=30
    i+=1

plt.savefig(outfile, dpi=300)
plt.close()
