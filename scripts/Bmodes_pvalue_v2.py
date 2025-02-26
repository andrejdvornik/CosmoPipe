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
parser.add_argument("--title", dest="title",
    help="Plot title", metavar="title",required=True)
parser.add_argument("--suffix", dest="suffix",
    help="Plot title suffix", metavar="suffix",required=True)
parser.add_argument("--mult", dest="mult", type=float,
    help="Multiplicative factor applied to the chi2 before calculating the p-value", metavar="mult",required=False)   

args = parser.parse_args()
inputfile = args.inputfile
statistic = args.statistic
ntomo = args.ntomo
thetamin = args.thetamin
thetamax = args.thetamax
output_dir = args.output_dir
title = args.title
suffix = args.suffix
mult = args.mult

def pvalue(data, cov, mask=None, mult=1.0):
    if np.any(mask):
        n_data = len(mask)
    else: 
        n_data = len(data)
        mask = np.full(n_data, True)
    chi2 = mult*np.dot(data[mask],np.dot(np.linalg.inv(cov[mask,:][:,mask]),data[mask]))
    p = stats.chi2.sf(chi2, n_data)
    return(p)

def plot_bmodes(x_data, y_data, y_data_plot, y_error, cov, bin1_data, bin2_data, angbin, outfile, ylabel, ntomo, mult = False):
    if mult:
        factor = mult
    else:
        factor = 1.0
    if ntomo != 1:
        fig, ax = plt.subplots(3,7, figsize = (13,5), sharex=True, sharey=True)
        plt.subplots_adjust(wspace=0, hspace=0, bottom=0.1, left=0.07)
    else:
        fig, ax = plt.subplots(1,1, figsize = (5,5), sharex=True, sharey=True)
        # Convert to array to make indexing work
        ax = np.array([[ax, None],[None,None]])
        plt.subplots_adjust(wspace=0, hspace=0, bottom=0.1, left=0.15)
    leg1=Rectangle((0,0),0,0,alpha=0.0)
    bincount=0
    for bin1 in range(ntomo):
        for bin2 in range(bin1,ntomo):
            x = bincount//7
            y = bincount%7
            idx = np.where((bin1_data==bin1+1) & (bin2_data==bin2+1))[0]
            ax[x,y].errorbar(x_data[idx], y_data_plot[idx], y_error[idx], linestyle = 'None', marker = '.', markersize=5)
            ax[x,y].text(0.03, 0.96, 'zbin %d-%d'%(bin1+1,bin2+1), horizontalalignment='left', verticalalignment='top', transform = ax[x,y].transAxes)
            ax[x,y].axhline(y=0, color='black', linestyle= 'dashed')
            p = pvalue(y_data, cov,  mask=np.where((bin1_data==bin1+1) & (bin2_data==bin2+1))[0], mult=factor)
            if p > 1e-2:
                ax[x,y].text(0.03, 0.01, 'p = %.2f'%p, horizontalalignment='left', verticalalignment='bottom', transform = ax[x,y].transAxes)
            else:
                ax[x,y].text(0.03, 0.01, 'p = %.2e'%p, horizontalalignment='left', verticalalignment='bottom', transform = ax[x,y].transAxes)
            if statistic == 'cosebis':
                p_nmax6 = pvalue(y_data, cov,  mask=np.where((bin1_data==bin1+1) & (bin2_data==bin2+1) & (angbin<=6))[0], mult=factor)
                if p_nmax6 > 1e-2:
                    plt.text(0.03, 0.11, 'p = %.2f'%p_nmax6, color='blue', horizontalalignment='left', verticalalignment='bottom', transform = ax[x,y].transAxes)
                else:
                    plt.text(0.03, 0.11, 'p = %.2e'%p_nmax6, color='blue', horizontalalignment='left', verticalalignment='bottom', transform = ax[x,y].transAxes)
            bincount+=1
    ax[0,0].set_xscale(xscale)
    fig.supylabel(ylabel)
    fig.supxlabel(xlabel)
    plt.text(0.07, 0.9, r'%s %s %s, $\theta=[%.2f,%.2f]$'%(title,suffix,statistic,thetamin,thetamax) , fontsize=14, transform=plt.gcf().transFigure, color='red')
    p = pvalue(y_data, cov, mult=factor)
    if ntomo != 1:
        if p > 1e-2:
            plt.text(0.90, 0.9, 'p = %.2f'%p, fontsize=14, transform=plt.gcf().transFigure, color='black', horizontalalignment='right')
        else:
            plt.text(0.90, 0.9, 'p = %.2e'%p, fontsize=14, transform=plt.gcf().transFigure, color='black', horizontalalignment='right')
        
        if statistic == 'cosebis':
            p_nmax6 = pvalue(y_data, cov, mask = np.where(angbin <= 6)[0], mult=factor)
            if p_nmax6 > 1e-2:
                plt.text(0.90, 0.95, 'p = %.2f'%p_nmax6, fontsize=14, transform=plt.gcf().transFigure, color='blue', horizontalalignment='right')
            else:
                plt.text(0.90, 0.95, 'p = %.2e'%p_nmax6, fontsize=14, transform=plt.gcf().transFigure, color='blue', horizontalalignment='right')
    if mult:
        plt.savefig(outfile + '_mult_v2.pdf')
    else:
        plt.savefig(outfile + '_v2.pdf')
    plt.close()

if statistic == 'cosebis':
    extension = 'Bn'
    ylabel = r'$B_{\rm n}[10^{-10}{\rm rad}^2]$'
    xlabel = r'n'
    xscale = 'linear'
if statistic == 'bandpowers':
    extension = 'PeeB'
    ylabel = r'$\mathcal{C}_{\rm BB}(\ell)/\ell\;[10^{-7}]$'
    xlabel = r'$\ell$'
    xscale = 'log'
if statistic == 'xiEB':
    extension_plus = 'xiP'
    extension_minus = 'xiM'
    ylabel_plus = r'$\theta\xi_+[10^{-4}{\rm arcmin}]$'
    ylabel_minus = r'$\theta\xi_-[10^{-4}{\rm arcmin}]$'
    xlabel = r'$\theta$'
    xscale = 'log'

with fits.open(inputfile) as f:
    if statistic != 'xiEB':
        B_data = f[extension].data
        n_data = len(B_data)
        B_cov = f['COVMAT'].data[n_data:,:][:,n_data:]
        B_std = np.sqrt(np.diag(B_cov))
    else:
        B_data_plus = f[extension_plus].data
        B_data_minus = f[extension_minus].data
        B_data_plusminus = np.concatenate([B_data_plus['VALUE'],B_data_minus['VALUE']])
        n_data = len(B_data_plus)
        B_cov_plus = f['COVMAT'].data[:n_data,:][:,:n_data]
        B_cov_minus = f['COVMAT'].data[n_data:,:][:,n_data:]
        B_std_plus = np.sqrt(np.diag(B_cov_plus))
        B_std_minus = np.sqrt(np.diag(B_cov_minus))
        B_cov_plusminus = f['COVMAT'].data
        B_std_plusminus = np.sqrt(np.diag(B_cov_plusminus))

n_combinations = int(ntomo*(ntomo+1)/2)
n_data_per_bin = int(n_data / n_combinations)

if suffix:
    outfile = output_dir+'/bmodes_%.2f-%.2f_%s'%(thetamin,thetamax,suffix)
else:
    outfile = output_dir+'/bmodes_%.2f-%.2f'%(thetamin,thetamax)

if statistic == 'cosebis':
    plot_bmodes(x_data=B_data['ANG'], y_data=B_data['VALUE'], y_data_plot=B_data['VALUE']*1e10, y_error=B_std*1e10, cov=B_cov, bin1_data=B_data['BIN1'], bin2_data=B_data['BIN2'], angbin=B_data['ANGBIN'], outfile=outfile, ylabel=ylabel, ntomo = ntomo)
    if mult:
        plot_bmodes(x_data=B_data['ANG'], y_data=B_data['VALUE'], y_data_plot=B_data['VALUE']*1e10, y_error=B_std*1e10, cov=B_cov, bin1_data=B_data['BIN1'], bin2_data=B_data['BIN2'], angbin=B_data['ANGBIN'], outfile=outfile, ylabel=ylabel, ntomo = ntomo, mult=mult)
if statistic == 'bandpowers':
    plot_bmodes(x_data=B_data['ANG'], y_data=B_data['VALUE'], y_data_plot=B_data['VALUE']/B_data['ANG']*1e7, y_error=B_std/B_data['ANG']*1e7, cov=B_cov, bin1_data=B_data['BIN1'], bin2_data=B_data['BIN2'], angbin=B_data['ANGBIN'], outfile=outfile, ylabel=ylabel, ntomo = ntomo)
    if mult:
        plot_bmodes(x_data=B_data['ANG'], y_datat=B_data['VALUE'], y_data_plot=B_data['VALUE']/B_data['ANG']*1e7, y_error=B_std/B_data['ANG']*1e7, cov=B_cov, bin1_data=B_data['BIN1'], bin2_data=B_data['BIN2'], angbin=B_data['ANGBIN'], outfile=outfile, ylabel=ylabel, ntomo = ntomo, mult=mult)

# Combine tomographic bins into a single bin and calculate pvalue
if ntomo != 1:
    inv_B_cov = np.linalg.inv(B_cov)
    B_combined = np.zeros(n_data_per_bin)
    inv_cov_combined = np.zeros((n_data_per_bin,n_data_per_bin))
    for k in range(n_data_per_bin):
        data = []
        idx = np.where(B_data['ANGBIN']==k+1)[0]
        B_combined[k] = np.average(B_data['VALUE'][idx], weights=1/np.diag(B_cov[idx,:][:,idx]))
    
    for i in range(n_combinations):
        for j in range(i,n_combinations):
            inv_cov_combined += inv_B_cov[i*n_data_per_bin:(i+1)*n_data_per_bin,:][:,j*n_data_per_bin:(j+1)*n_data_per_bin]
    B_cov_combined = np.linalg.inv(inv_cov_combined)
    if suffix:
        outfile_combined = output_dir+'/bmodes_%.2f-%.2f_%s_onetomo'%(thetamin,thetamax,suffix)
    else:
        outfile_combined = output_dir+'/bmodes_%.2f-%.2f_onetomo'%(thetamin,thetamax)

    if statistic == 'cosebis':
        plot_bmodes(x_data=B_data['ANG'][:n_data_per_bin], y_data=B_combined, y_data_plot=B_combined*1e10, y_error=np.sqrt(np.diag(B_cov_combined))*1e10, cov=B_cov_combined, bin1_data=B_data['BIN1'], bin2_data=B_data['BIN2'], angbin=B_data['ANGBIN'], outfile=outfile_combined, ylabel=ylabel, ntomo = 1)
    if statistic == 'bandpowers':
        plot_bmodes(x_data=B_data['ANG'][:n_data_per_bin], y_data=B_combined, y_data_plot=B_combined/B_data['ANG'][:n_data_per_bin]*1e7, y_error=np.sqrt(np.diag(B_cov_combined))/B_data['ANG'][:n_data_per_bin]*1e7, cov=B_cov_combined, bin1_data=B_data['BIN1'], bin2_data=B_data['BIN2'], angbin=B_data['ANGBIN'], outfile=outfile_combined, ylabel=ylabel, ntomo = 1)

if statistic == 'xiEB':
    if suffix:
        outfile_plus = output_dir+'/bmodes_xiEB_plus_%.2f-%.2f_%s'%(thetamin,thetamax,suffix)
        outfile_minus = output_dir+'/bmodes_xiEB_minus_%.2f-%.2f_%s'%(thetamin,thetamax,suffix)
    else:
        outfile_plus = output_dir+'/bmodes_xiEB_plus_%.2f-%.2f'%(thetamin,thetamax)
        outfile_minus = output_dir+'/bmodes_xiEB_minus_%.2f-%.2f'%(thetamin,thetamax)

    plot_bmodes(x_data=B_data_plus['ANG'], y_data=B_data_plus['VALUE'], y_data_plot=B_data_plus['VALUE']*B_data_plus['ANG']*1e4, y_error=B_std_plus*B_data_plus['ANG']*1e4, cov=B_cov_plus, bin1_data=B_data_plus['BIN1'], bin2_data=B_data_plus['BIN2'], angbin=B_data_plus['ANGBIN'], outfile=outfile_plus, ylabel=ylabel_plus, ntomo = ntomo)
    plot_bmodes(x_data=B_data_minus['ANG'], y_data=B_data_minus['VALUE'], y_data_plot=B_data_minus['VALUE']*B_data_minus['ANG']*1e4, y_error=B_std_minus*B_data_minus['ANG']*1e4, cov=B_cov_minus, bin1_data=B_data_plus['BIN1'], bin2_data=B_data_minus['BIN2'], angbin=B_data_minus['ANGBIN'], outfile=outfile_minus, ylabel=ylabel_minus, ntomo = ntomo)
    if mult:
        plot_bmodes(x_data=B_data_plus['ANG'], y_data=B_data_plus['VALUE'], y_data_plot=B_data_plus['VALUE']*B_data_plus['ANG']*1e4, y_error=B_std_plus*B_data_plus['ANG']*1e4, cov=B_cov_plus, bin1_data=B_data_plus['BIN1'], bin2_data=B_data_plus['BIN2'], angbin=B_data_plus['ANGBIN'], outfile=outfile_plus, ylabel=ylabel_plus, ntomo = ntomo, mult=mult)
        plot_bmodes(x_data=B_data_minus['ANG'], y_data=B_data_minus['VALUE'], y_data_plot=B_data_minus['VALUE']*B_data_minus['ANG']*1e4, y_error=B_std_minus*B_data_minus['ANG']*1e4, cov=B_cov_minus, bin1_data=B_data_plus['BIN1'], bin2_data=B_data_minus['BIN2'], angbin=B_data_minus['ANGBIN'], outfile=outfile_minus, ylabel=ylabel_minus, ntomo = ntomo, mult=mult)





