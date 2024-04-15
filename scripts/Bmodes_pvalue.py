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

args = parser.parse_args()
inputfile = args.inputfile
statistic = args.statistic
ntomo = args.ntomo
thetamin = args.thetamin
thetamax = args.thetamax
output_dir = args.output_dir
title = args.title
suffix = args.suffix

def pvalue(data, cov, mask=None):
    if any(mask):
        n_data = len(np.where(mask)[0])
    else: 
        n_data = len(data)
        mask = np.full(n_data, True)
    # mask = np.where(mask)
    chi2 = np.dot(data[mask],np.dot(np.linalg.inv(cov[mask,:][:,mask]),data[mask]))
    p = stats.chi2.sf(chi2, n_data)
    return(p)


if statistic == 'cosebis':
    extension = 'Bn'
    ylabel = r'$B_{\rm n}[10^{-10}{\rm rad}^2]$'
    xlabel = r'n'
if statistic == 'bandpowers':
    extension = 'PeeB'
    ylabel = r'$\mathcal{C}_{\rm BB}(\ell)/\ell\;[10^{-7}]$'
    xlabel = r'$\ell$'
if statistic == 'xiEB':
    extension_plus = 'xiP'
    extension_minus = 'xiM'
    ylabel_plus = r'$\theta\xi_+[10^{-4}{\rm arcmin}]$'
    ylabel_minus = r'$\theta\xi_-[10^{-4}{\rm arcmin}]$'
    xlabel = r'$\theta$'

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

if statistic != 'xiEB':
    if ntomo !=1:
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
                if p > 1e-2:
                    ax[x,y].text(0.03, 0.04, 'p = %.2f'%p, horizontalalignment='left', verticalalignment='bottom', transform = ax[x,y].transAxes)
                else:
                    ax[x,y].text(0.03, 0.04, 'p = %.2e'%p, horizontalalignment='left', verticalalignment='bottom', transform = ax[x,y].transAxes)
                bincount+=1
        if statistic == 'bandpowers':
            ax[0,0].set_xscale('log')
        fig.supylabel(ylabel)
        fig.supxlabel(xlabel)
        plt.text(0.07, 0.9, r'%s %s %s, $\theta=[%.2f,%.2f]$'%(title,suffix,statistic,thetamin,thetamax) , fontsize=14, transform=plt.gcf().transFigure, color='red')
        chi2 = np.dot(B_data['VALUE'],np.dot(np.linalg.inv(B_cov),B_data['VALUE']))
        p = stats.chi2.sf(chi2, n_data)
        if p > 1e-2:
            plt.text(0.90, 0.9, 'p = %.2f'%p, fontsize=14, transform=plt.gcf().transFigure, color='black', horizontalalignment='right')
        else:
            plt.text(0.90, 0.9, 'p = %.2e'%p, fontsize=14, transform=plt.gcf().transFigure, color='black', horizontalalignment='right')
        if suffix:
            plt.savefig(output_dir+'/bmodes_%.2f-%.2f_%s.pdf'%(thetamin,thetamax,suffix))
        else:
            plt.savefig(output_dir+'/bmodes_%.2f-%.2f.pdf'%(thetamin,thetamax))
        plt.close()
        plist = ['All:             %.2e'%(p)]

        if statistic =='cosebis':
            # update n_data and n_data per bin 
            idx = np.where((B_data['BIN1']==1) & (B_data['BIN2']==1) & (B_data['ANGBIN']<=5))[0]
            n_data_per_bin = len(B_data['VALUE'][idx])
            n_data = n_combinations * n_data_per_bin
            fig, ax = plt.subplots(3,7, figsize = (13,5), sharex=True, sharey=True)
            plt.subplots_adjust(wspace=0, hspace=0, bottom=0.1, left=0.07)
            bincount=0
            leg1=Rectangle((0,0),0,0,alpha=0.0)
            for bin1 in range(ntomo):
                for bin2 in range(bin1,ntomo):
                    x = bincount//7
                    y = bincount%7
                    idx = np.where((B_data['BIN1']==bin1+1) & (B_data['BIN2']==bin2+1) & (B_data['ANGBIN']<=5))[0]
                    ax[x,y].errorbar(B_data['ANG'][idx], B_data['VALUE'][idx]*1e10, B_std[idx]*1e10, linestyle = 'None', marker = '.', markersize=5)
                    ax[x,y].text(0.03, 0.96, 'zbin %d-%d'%(bin1+1,bin2+1), horizontalalignment='left', verticalalignment='top', transform = ax[x,y].transAxes)
                    ax[x,y].axhline(y=0, color='black', linestyle= 'dashed')
                    chi2 = np.dot(B_data['VALUE'][idx],np.dot(np.linalg.inv(B_cov[idx,:][:,idx]),B_data['VALUE'][idx]))
                    p = stats.chi2.sf(chi2, n_data_per_bin)
                    if p > 1e-2:
                        ax[x,y].text(0.03, 0.04, 'p = %.2f'%p, horizontalalignment='left', verticalalignment='bottom', transform = ax[x,y].transAxes)
                    else:
                        ax[x,y].text(0.03, 0.04, 'p = %.2e'%p, horizontalalignment='left', verticalalignment='bottom', transform = ax[x,y].transAxes)
                    bincount+=1
            fig.supylabel(ylabel)
            fig.supxlabel(xlabel)
            plt.text(0.07, 0.9, r'%s %s %s, $\theta=[%.2f,%.2f]$'%(title,suffix,statistic,thetamin,thetamax), fontsize=14, transform=plt.gcf().transFigure, color='red')
            idx = np.where(B_data['ANGBIN']<=5)[0]
            chi2 = np.dot(B_data['VALUE'][idx],np.dot(np.linalg.inv(B_cov[idx,:][:,idx]),B_data['VALUE'][idx]))
            p = stats.chi2.sf(chi2, n_data)
            if p > 1e-2:
                plt.text(0.90, 0.9, 'p = %.2f'%p, fontsize=14, transform=plt.gcf().transFigure, color='black', horizontalalignment='right')
            else:
                plt.text(0.90, 0.9, 'p = %.2e'%p, fontsize=14, transform=plt.gcf().transFigure, color='black', horizontalalignment='right')
            if suffix:
                plt.savefig(output_dir+'/bmodes_%.2f-%.2f_nmax5_%s.pdf'%(thetamin,thetamax,suffix))
            else:
                plt.savefig(output_dir+'/bmodes_%.2f-%.2f_nmax5.pdf'%(thetamin,thetamax))
            plt.close()
            plist_5 = ['All:             %.2e'%(p)]

        p_singlebins=np.zeros((ntomo,ntomo))
        p_excludeone=np.zeros((ntomo,ntomo))
        p_singlebins_5=np.zeros((ntomo,ntomo))
        p_excludeone_5=np.zeros((ntomo,ntomo))
        for i in range(1,ntomo+1):
            mask_only = (B_data['BIN1']==i) | (B_data['BIN2']==i)
            mask_without = (B_data['BIN1']!=i) & (B_data['BIN2']!=i)
            p_only = pvalue(B_data['VALUE'], B_cov, mask_only)
            p_without = pvalue(B_data['VALUE'], B_cov, mask_without)

            plist.append('Bin %d only:      %.2e'%(i,p_only))
            plist.append('Excluding bin %d: %.2e'%(i,p_without))
            if suffix:
                np.savetxt(output_dir+'/pvalues_%.2f-%.2f_%s.pdf.txt'%(thetamin,thetamax,suffix),plist, fmt='%s')
            else:
                np.savetxt(output_dir+'/pvalues_%.2f-%.2f.pdf.txt'%(thetamin,thetamax),plist, fmt='%s')
            
            if statistic =='cosebis':
                mask_only_5 = ((B_data['BIN1']==i) | (B_data['BIN2']==i)) & (B_data['ANGBIN']<=5)
                mask_without_5 = (B_data['BIN1']!=i) & (B_data['BIN2']!=i) & (B_data['ANGBIN']<=5)
                p_only_5 = pvalue(B_data['VALUE'], B_cov, mask_only_5)
                p_without_5 = pvalue(B_data['VALUE'], B_cov, mask_without_5)

                plist_5.append('Bin %d only:      %.2e'%(i,p_only_5))
                plist_5.append('Excluding bin %d: %.2e'%(i,p_without_5))
                if suffix:
                    np.savetxt(output_dir+'/pvalues_%.2f-%.2f_nmax5_%s.pdf.txt'%(thetamin,thetamax,suffix),plist_5, fmt='%s')
                else:
                    np.savetxt(output_dir+'/pvalues_%.2f-%.2f_nmax5.pdf.txt'%(thetamin,thetamax),plist_5, fmt='%s')

            for j in range(i,ntomo+1):
                mask_only = ((B_data['BIN1']==i) & (B_data['BIN2']==j)) | ((B_data['BIN1']==j) & (B_data['BIN2']==i))
                mask_without = ((B_data['BIN1']!=i) & (B_data['BIN2']!=j)) & ((B_data['BIN1']!=j) & (B_data['BIN2']!=i))
                p_singlebins[i-1,j-1] = pvalue(B_data['VALUE'], B_cov, mask_only)
                p_excludeone[i-1,j-1] = pvalue(B_data['VALUE'], B_cov, mask_without)
                if statistic =='cosebis':
                    mask_only_5 = (((B_data['BIN1']==i) & (B_data['BIN2']==j)) | ((B_data['BIN1']==j) & (B_data['BIN2']==i))) & (B_data['ANGBIN']<=5)
                    mask_without_5 = (((B_data['BIN1']!=i) & (B_data['BIN2']!=j)) & ((B_data['BIN1']!=j) & (B_data['BIN2']!=i))) & (B_data['ANGBIN']<=5)
                    p_singlebins_5[i-1,j-1] = pvalue(B_data['VALUE'], B_cov, mask_only_5)
                    p_excludeone_5[i-1,j-1] = pvalue(B_data['VALUE'], B_cov, mask_without_5)
        if suffix:
            np.savetxt(output_dir+'/pvalues_singlebins_%.2f-%.2f_%s.pdf.txt'%(thetamin,thetamax,suffix),p_singlebins, fmt='%.2e')
            np.savetxt(output_dir+'/pvalues_excludeone_%.2f-%.2f_%s.pdf.txt'%(thetamin,thetamax,suffix),p_excludeone, fmt='%.2e')
            if statistic =='cosebis':
                np.savetxt(output_dir+'/pvalues_singlebins_%.2f-%.2f_nmax5_%s.pdf.txt'%(thetamin,thetamax,suffix),p_singlebins_5, fmt='%.2e')
                np.savetxt(output_dir+'/pvalues_excludeone_%.2f-%.2f_nmax5_%s.pdf.txt'%(thetamin,thetamax,suffix),p_excludeone_5, fmt='%.2e')
        else:
            np.savetxt(output_dir+'/pvalues_singlebins_%.2f-%.2f.pdf.txt'%(thetamin,thetamax),p_singlebins, fmt='%.2e')
            np.savetxt(output_dir+'/pvalue_excludeone_%.2f-%.2f.pdf.txt'%(thetamin,thetamax),p_excludeone, fmt='%.2e')
            if statistic =='cosebis':
                np.savetxt(output_dir+'/pvalues_singlebins_%.2f-%.2f_nmax5.pdf.txt'%(thetamin,thetamax),p_singlebins_5, fmt='%.2e')
                np.savetxt(output_dir+'/pvalue_excludeone_%.2f-%.2f_nmax5.pdf.txt'%(thetamin,thetamax),p_excludeone_5, fmt='%.2e')

    else:
        fig, ax = plt.subplots(1,1, figsize = (5,5), sharex=True, sharey=True)
        plt.subplots_adjust(wspace=0, hspace=0, bottom=0.1, left=0.15)
        leg1=Rectangle((0,0),0,0,alpha=0.0)
        for bin1 in range(ntomo):
            for bin2 in range(bin1,ntomo):
                if statistic == 'cosebis':
                    ax.errorbar(B_data['ANG'], B_data['VALUE']*1e10, B_std*1e10, linestyle = 'None', marker = '.', markersize=5)
                if statistic == 'bandpowers':
                    ax.errorbar(B_data['ANG'], B_data['VALUE']/B_data['ANG']*1e7, B_std/B_data['ANG']*1e7, linestyle = 'None', marker = '.', markersize=5)
                ax.text(0.03, 0.96, 'zbin %d-%d'%(bin1+1,bin2+1), horizontalalignment='left', verticalalignment='top', transform = ax.transAxes)
                ax.axhline(y=0, color='black', linestyle= 'dashed')
        if statistic == 'bandpowers':
            ax.set_xscale('log')
        fig.supylabel(ylabel)
        fig.supxlabel(xlabel)
        plt.text(0.07, 0.9, r'%s %s %s, $\theta=[%.2f,%.2f]$'%(title,suffix,statistic,thetamin,thetamax), fontsize=14, transform=plt.gcf().transFigure, color='red')
        chi2 = np.dot(B_data['VALUE'],np.dot(np.linalg.inv(B_cov),B_data['VALUE']))
        p = stats.chi2.sf(chi2, n_data)
        if p > 1e-2:
            ax.text(0.16, 0.12, 'p = %.2f'%p, fontsize=14, transform=plt.gcf().transFigure, color='black', horizontalalignment='left')
        else:
            ax.text(0.16, 0.12, 'p = %.2e'%p, fontsize=14, transform=plt.gcf().transFigure, color='black', horizontalalignment='left')
        if suffix:
                plt.savefig(output_dir+'/bmodes_%.2f-%.2f_%s.pdf'%(thetamin,thetamax,suffix))
        else:
            plt.savefig(output_dir+'/bmodes_%.2f-%.2f.pdf'%(thetamin,thetamax))
        plt.close()

        if statistic =='cosebis':
            # update n_data and n_data per bin 
            idx = np.where(B_data['ANGBIN']<=5)[0]
            n_data_per_bin = len(B_data['VALUE'][idx])
            n_data = n_combinations * n_data_per_bin
            fig, ax = plt.subplots(1,1, figsize = (5,5), sharex=True, sharey=True)
            plt.subplots_adjust(wspace=0, hspace=0, bottom=0.1, left=0.15)
            leg1=Rectangle((0,0),0,0,alpha=0.0)
            for bin1 in range(ntomo):
                for bin2 in range(bin1,ntomo):
                    ax.errorbar(B_data['ANG'][idx], B_data['VALUE'][idx]*1e10, B_std[idx]*1e10, linestyle = 'None', marker = '.', markersize=5)
                    ax.text(0.03, 0.96, 'zbin %d-%d'%(bin1+1,bin2+1), horizontalalignment='left', verticalalignment='top', transform = ax.transAxes)
                    ax.axhline(y=0, color='black', linestyle= 'dashed')
            fig.supylabel(ylabel)
            fig.supxlabel(xlabel)
            plt.text(0.07, 0.9, r'%s %s %s, $\theta=[%.2f,%.2f]$'%(title,suffix,statistic,thetamin,thetamax), fontsize=14, transform=plt.gcf().transFigure, color='red')
            idx = np.where(B_data['ANGBIN']<=5)[0]
            chi2 = np.dot(B_data['VALUE'][idx],np.dot(np.linalg.inv(B_cov[idx,:][:,idx]),B_data['VALUE'][idx]))
            p = stats.chi2.sf(chi2, n_data)
            if p > 1e-2:
                ax.text(0.16, 0.12, 'p = %.2f'%p, fontsize=14, transform=plt.gcf().transFigure, color='black', horizontalalignment='left')
            else:
                ax.text(0.16, 0.12, 'p = %.2e'%p, fontsize=14, transform=plt.gcf().transFigure, color='black', horizontalalignment='left')
            if suffix:
                plt.savefig(output_dir+'/bmodes_%.2f-%.2f_nmax5_%s.pdf'%(thetamin,thetamax,suffix))
            else:
                plt.savefig(output_dir+'/bmodes_%.2f-%.2f_nmax5.pdf'%(thetamin,thetamax))
            plt.close()
else:
    if ntomo !=1:
        # XIP plot
        fig, ax = plt.subplots(3,7, figsize = (13,5), sharex=True, sharey=True)
        plt.subplots_adjust(wspace=0, hspace=0, bottom=0.1, left=0.07)
        bincount=0
        leg1=Rectangle((0,0),0,0,alpha=0.0)
        for bin1 in range(ntomo):
            for bin2 in range(bin1,ntomo):
                x = bincount//7
                y = bincount%7
                idx = np.where((B_data_plus['BIN1']==bin1+1) & (B_data_plus['BIN2']==bin2+1))[0]
                ax[x,y].errorbar(B_data_plus['ANG'][idx], B_data_plus['VALUE'][idx]*B_data_plus['ANG'][idx]*1e4, B_std_plus[idx]*B_data_plus['ANG'][idx]*1e4, linestyle = 'None', marker = '.', markersize=5)
                ax[x,y].text(0.03, 0.96, 'zbin %d-%d'%(bin1+1,bin2+1), horizontalalignment='left', verticalalignment='top', transform = ax[x,y].transAxes)
                ax[x,y].axhline(y=0, color='black', linestyle= 'dashed')
                chi2 = np.dot(B_data_plus['VALUE'][idx],np.dot(np.linalg.inv(B_cov_plus[idx,:][:,idx]),B_data_plus['VALUE'][idx]))
                p = stats.chi2.sf(chi2, n_data_per_bin)
                if p > 1e-2:
                    ax[x,y].text(0.03, 0.04, 'p = %.2f'%p, horizontalalignment='left', verticalalignment='bottom', transform = ax[x,y].transAxes)
                else:
                    ax[x,y].text(0.03, 0.04, 'p = %.2e'%p, horizontalalignment='left', verticalalignment='bottom', transform = ax[x,y].transAxes)
                bincount+=1
        ax[0,0].set_xscale('log')
        fig.supylabel(ylabel_plus)
        fig.supxlabel(xlabel)
        plt.text(0.07, 0.9, r'%s %s %s, $\theta=[%.2f,%.2f]$'%(title,suffix,statistic,thetamin,thetamax) , fontsize=14, transform=plt.gcf().transFigure, color='red')
        chi2 = np.dot(B_data_plus['VALUE'],np.dot(np.linalg.inv(B_cov_plus),B_data_plus['VALUE']))
        p = stats.chi2.sf(chi2, n_data)
        if p > 1e-2:
            plt.text(0.90, 0.9, 'p = %.2f'%p, fontsize=14, transform=plt.gcf().transFigure, color='black', horizontalalignment='right')
        else:
            plt.text(0.90, 0.9, 'p = %.2e'%p, fontsize=14, transform=plt.gcf().transFigure, color='black', horizontalalignment='right')
        if suffix:
            plt.savefig(output_dir+'/bmodes_xiEB_plus_%.2f-%.2f_%s.pdf'%(thetamin,thetamax,suffix))
        else:
            plt.savefig(output_dir+'/bmodes_xiEB_plus_%.2f-%.2f.pdf'%(thetamin,thetamax))
        plt.close()

        # xiM plot
        fig, ax = plt.subplots(3,7, figsize = (13,5), sharex=True, sharey=True)
        plt.subplots_adjust(wspace=0, hspace=0, bottom=0.1, left=0.07)
        bincount=0
        leg1=Rectangle((0,0),0,0,alpha=0.0)
        for bin1 in range(ntomo):
            for bin2 in range(bin1,ntomo):
                x = bincount//7
                y = bincount%7
                idx = np.where((B_data_minus['BIN1']==bin1+1) & (B_data_minus['BIN2']==bin2+1))[0]
                ax[x,y].errorbar(B_data_minus['ANG'][idx], B_data_minus['VALUE'][idx]*B_data_minus['ANG'][idx]*1e4, B_std_minus[idx]*B_data_minus['ANG'][idx]*1e4, linestyle = 'None', marker = '.', markersize=5)
                ax[x,y].text(0.03, 0.96, 'zbin %d-%d'%(bin1+1,bin2+1), horizontalalignment='left', verticalalignment='top', transform = ax[x,y].transAxes)
                ax[x,y].axhline(y=0, color='black', linestyle= 'dashed')
                chi2 = np.dot(B_data_minus['VALUE'][idx],np.dot(np.linalg.inv(B_cov_minus[idx,:][:,idx]),B_data_minus['VALUE'][idx]))
                p = stats.chi2.sf(chi2, n_data_per_bin)
                if p > 1e-2:
                    ax[x,y].text(0.03, 0.04, 'p = %.2f'%p, horizontalalignment='left', verticalalignment='bottom', transform = ax[x,y].transAxes)
                else:
                    ax[x,y].text(0.03, 0.04, 'p = %.2e'%p, horizontalalignment='left', verticalalignment='bottom', transform = ax[x,y].transAxes)
                bincount+=1
        ax[x,y].set_xscale('log')
        fig.supylabel(ylabel_minus)
        fig.supxlabel(xlabel)
        plt.text(0.07, 0.9, r'%s %s %s, $\theta=[%.2f,%.2f]$'%(title,suffix,statistic,thetamin,thetamax) , fontsize=14, transform=plt.gcf().transFigure, color='red')
        chi2 = np.dot(B_data_minus['VALUE'],np.dot(np.linalg.inv(B_cov_minus),B_data_minus['VALUE']))
        p = stats.chi2.sf(chi2, n_data)
        if p > 1e-2:
            plt.text(0.90, 0.9, 'p = %.2f'%p, fontsize=14, transform=plt.gcf().transFigure, color='black', horizontalalignment='right')
        else:
            plt.text(0.90, 0.9, 'p = %.2e'%p, fontsize=14, transform=plt.gcf().transFigure, color='black', horizontalalignment='right')
        if suffix:
            plt.savefig(output_dir+'/bmodes_xiEB_minus_%.2f-%.2f_%s.pdf'%(thetamin,thetamax,suffix))
        else:
            plt.savefig(output_dir+'/bmodes_xiEB_minus_%.2f-%.2f.pdf'%(thetamin,thetamax))
        plt.close()
    else:
        # XIP plot
        fig, ax = plt.subplots(1,1, figsize = (5,5), sharex=True, sharey=True)
        plt.subplots_adjust(wspace=0, hspace=0, bottom=0.1, left=0.15)
        bincount=0
        leg1=Rectangle((0,0),0,0,alpha=0.0)
        for bin1 in range(ntomo):
            for bin2 in range(bin1,ntomo):
                x = bincount//7
                y = bincount%7
                idx = np.where((B_data_plus['BIN1']==bin1+1) & (B_data_plus['BIN2']==bin2+1))[0]
                ax.errorbar(B_data_plus['ANG'][idx], B_data_plus['VALUE'][idx]*B_data_plus['ANG'][idx]*1e4, B_std_plus[idx]*B_data_plus['ANG'][idx]*1e4, linestyle = 'None', marker = '.', markersize=5)
                ax.text(0.03, 0.96, 'zbin %d-%d'%(bin1+1,bin2+1), horizontalalignment='left', verticalalignment='top', transform = ax.transAxes)
                ax.axhline(y=0, color='black', linestyle= 'dashed')
                chi2 = np.dot(B_data_plus['VALUE'][idx],np.dot(np.linalg.inv(B_cov_plus[idx,:][:,idx]),B_data_plus['VALUE'][idx]))
                p = stats.chi2.sf(chi2, n_data_per_bin)
                # if p > 1e-2:
                #     ax.text(0.03, 0.04, 'p = %.2f'%p, horizontalalignment='left', verticalalignment='bottom', transform = ax.transAxes)
                # else:
                #     ax.text(0.03, 0.04, 'p = %.2e'%p, horizontalalignment='left', verticalalignment='bottom', transform = ax.transAxes)
                bincount+=1
        ax.set_xscale('log')
        fig.supylabel(ylabel_plus)
        fig.supxlabel(xlabel)
        plt.text(0.07, 0.9, r'%s %s %s, $\theta=[%.2f,%.2f]$'%(title,suffix,statistic,thetamin,thetamax) , fontsize=14, transform=plt.gcf().transFigure, color='red')
        chi2 = np.dot(B_data_plus['VALUE'],np.dot(np.linalg.inv(B_cov_plus),B_data_plus['VALUE']))
        p = stats.chi2.sf(chi2, n_data)
        if p > 1e-2:
            plt.text(0.90, 0.9, 'p = %.2f'%p, fontsize=14, transform=plt.gcf().transFigure, color='black', horizontalalignment='right')
        else:
            plt.text(0.90, 0.9, 'p = %.2e'%p, fontsize=14, transform=plt.gcf().transFigure, color='black', horizontalalignment='right')
        if suffix:
            plt.savefig(output_dir+'/bmodes_xiEB_plus_%.2f-%.2f_%s.pdf'%(thetamin,thetamax,suffix))
        else:
            plt.savefig(output_dir+'/bmodes_xiEB_plus_%.2f-%.2f.pdf'%(thetamin,thetamax))
        plt.close()

        # xiM plot
        fig, ax = plt.subplots(1,1, figsize = (5,5), sharex=True, sharey=True)
        plt.subplots_adjust(wspace=0, hspace=0, bottom=0.1, left=0.15)
        bincount=0
        leg1=Rectangle((0,0),0,0,alpha=0.0)
        for bin1 in range(ntomo):
            for bin2 in range(bin1,ntomo):
                x = bincount//7
                y = bincount%7
                idx = np.where((B_data_minus['BIN1']==bin1+1) & (B_data_minus['BIN2']==bin2+1))[0]
                ax.errorbar(B_data_minus['ANG'][idx], B_data_minus['VALUE'][idx]*B_data_minus['ANG'][idx]*1e4, B_std_minus[idx]*B_data_minus['ANG'][idx]*1e4, linestyle = 'None', marker = '.', markersize=5)
                ax.text(0.03, 0.96, 'zbin %d-%d'%(bin1+1,bin2+1), horizontalalignment='left', verticalalignment='top', transform = ax.transAxes)
                ax.axhline(y=0, color='black', linestyle= 'dashed')
                chi2 = np.dot(B_data_minus['VALUE'][idx],np.dot(np.linalg.inv(B_cov_minus[idx,:][:,idx]),B_data_minus['VALUE'][idx]))
                p = stats.chi2.sf(chi2, n_data_per_bin)
                if p > 1e-2:
                    ax.text(0.03, 0.04, 'p = %.2f'%p, horizontalalignment='left', verticalalignment='bottom', transform = ax.transAxes)
                else:
                    ax.text(0.03, 0.04, 'p = %.2e'%p, horizontalalignment='left', verticalalignment='bottom', transform = ax.transAxes)
                bincount+=1
        ax.set_xscale('log')
        fig.supylabel(ylabel_minus)
        fig.supxlabel(xlabel)
        plt.text(0.07, 0.9, r'%s %s %s, $\theta=[%.2f,%.2f]$'%(title,suffix,statistic,thetamin,thetamax) , fontsize=14, transform=plt.gcf().transFigure, color='red')
        chi2 = np.dot(B_data_minus['VALUE'],np.dot(np.linalg.inv(B_cov_minus),B_data_minus['VALUE']))
        p = stats.chi2.sf(chi2, n_data)
        # if p > 1e-2:
        #     plt.text(0.90, 0.9, 'p = %.2f'%p, fontsize=14, transform=plt.gcf().transFigure, color='black', horizontalalignment='right')
        # else:
        #     plt.text(0.90, 0.9, 'p = %.2e'%p, fontsize=14, transform=plt.gcf().transFigure, color='black', horizontalalignment='right')
        if suffix:
            plt.savefig(output_dir+'/bmodes_xiEB_minus_%.2f-%.2f_%s.pdf'%(thetamin,thetamax,suffix))
        else:
            plt.savefig(output_dir+'/bmodes_xiEB_minus_%.2f-%.2f.pdf'%(thetamin,thetamax))
        plt.close()


    chi2 = np.dot(B_data_plusminus,np.dot(np.linalg.inv(B_cov_plusminus),B_data_plusminus))
    p = stats.chi2.sf(chi2, 2*n_data)
    print('%.2e'%p)




