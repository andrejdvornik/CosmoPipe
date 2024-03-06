from argparse import ArgumentParser
import numpy as np
import astropy.io.fits as fits
from scipy import stats
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle


parser = ArgumentParser(description='Calculate bmodes')
parser.add_argument("--inputfile", dest="inputfile",
    help="Input file", required=True)
parser.add_argument("--statistic", dest="statistic",
    help="Statistic", required=True)
parser.add_argument("--ntomo", dest="ntomo", type=int,
    help="Number of tomographic bins", metavar="output",required=True)
parser.add_argument("--thetamin", dest="thetamin", type=float,
    help="Minimum theta", metavar="output",required=True)
parser.add_argument("--thetamax", dest="thetamax", type=float,
    help="Maximum theta", metavar="output",required=True)    
parser.add_argument("--output_dir", dest="output_dir",
    help="Output directory", metavar="output",required=True)

args = parser.parse_args()
inputfile = args.inputfile
statistic = args.statistic
ntomo = args.ntomo
thetamin = args.thetamin
thetamax = args.thetamax
output_dir = args.output_dir

if statistic == 'cosebis':
    extension = 'Bn'
    ylabel = r'$B_{\rm n}[10^{-10}{\rm rad}^2]$'
    xlabel = r'n'
if statistic == 'bandpowers':
    extension = 'PeeB'
    ylabel = r'$\mathcal{C}_{\rm BB}(\ell)/\ell\;[10^{-7}]$'
    xlabel = r'$\ell$'

with fits.open(inputfile) as f:
    B_data = f[extension].data
    n_data = len(B_data)
    B_cov = f['COVMAT'].data[n_data:,:][:,n_data:]


n_combinations = int(ntomo*(ntomo+1)/2)
n_data_per_bin = int(n_data / n_combinations)
B_std = np.sqrt(np.diag(B_cov))


fig, ax = plt.subplots(3,7, figsize = (13,5), sharex=True, sharey=True)
plt.subplots_adjust(wspace=0, hspace=0, bottom=0.1, left=0.07)
bincount=0
leg1=Rectangle((0,0),0,0,alpha=0.0)
for bin1 in range(ntomo):
    for bin2 in range(bin1,ntomo):
        x = bincount//7
        y = bincount%7
        idx = np.where((B_data['BIN1']==bin1+1) & (B_data['BIN2']==bin2+1))[0]
        if statistic == 'cosebis':
            ax[x,y].errorbar(B_data['ANG'][idx], B_data['VALUE'][idx]*1e10, B_std[idx]*1e10, linestyle = 'None', marker = '.', markersize=5)
        if statistic == 'bandpowers':
            ax[x,y].errorbar(B_data['ANG'][idx], B_data['VALUE'][idx]/B_data['ANG'][idx]*1e7, B_std[idx]/B_data['ANG'][idx]*1e7, linestyle = 'None', marker = '.', markersize=5)
        ax[x,y].text(0.03, 0.96, 'zbin %d-%d'%(bin1+1,bin2+1), horizontalalignment='left', verticalalignment='top', transform = ax[x,y].transAxes)
        ax[x,y].axhline(y=0, color='black', linestyle= 'dashed')
        chi2 = np.dot(B_data['VALUE'][idx],np.dot(np.linalg.inv(B_cov[idx,:][:,idx]),B_data['VALUE'][idx]))
        p = stats.chi2.sf(chi2, n_data_per_bin)
        ax[x,y].text(0.03, 0.04, 'p = %.2e'%p, horizontalalignment='left', verticalalignment='bottom', transform = ax[x,y].transAxes)
        bincount+=1
# ax[0,0].set_xticks((5,10,15,20))
# ax[0,0].set_ylim((-6,12))
# ax[0,0].set_ylim((-20,20))
# ax[0,0].set_yticks((0,20))
if statistic == 'bandpowers':
    ax[0,0].set_xscale('log')
fig.supylabel(ylabel)
fig.supxlabel(xlabel)
plt.text(0.07, 0.9, 'Bmodes ' + statistic, fontsize=14, transform=plt.gcf().transFigure, color='red')
chi2 = np.dot(B_data['VALUE'],np.dot(np.linalg.inv(B_cov),B_data['VALUE']))
p = stats.chi2.sf(chi2, n_data)

plt.text(0.90, 0.9, 'p = %.2e'%p, fontsize=14, transform=plt.gcf().transFigure, color='black', horizontalalignment='right')
plt.savefig(output_dir+'/bmodes_%.2f-%.2f.pdf'%(thetamin,thetamax))
plt.close()






