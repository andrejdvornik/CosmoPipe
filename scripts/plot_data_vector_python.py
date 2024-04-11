from argparse import ArgumentParser
import numpy as np
import astropy.io.fits as fits
from scipy import stats
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle
import matplotlib.pylab as pl
from matplotlib.font_manager import FontProperties
from matplotlib.ticker import ScalarFormatter


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

if statistic == 'cosebis':
    extension_E = 'En'
    extension_B = 'Bn'
    ylabel_E = r'$E_{\rm n}[10^{-10}{\rm rad}^2]$'
    ylabel_B = r'$B_{\rm n}[10^{-10}{\rm rad}^2]$'
    xlabel = r'n'
    xscale= 'linear'
    scaling = 1e10
if statistic == 'bandpowers':
    extension_E = 'PeeE'
    extension_B = 'PeeB'
    ylabel_E = r'$\mathcal{C}_{\rm EE}(\ell)/\ell\;[10^{-7}]$'
    ylabel_B = r'$\mathcal{C}_{\rm BB}(\ell)/\ell\;[10^{-7}]$'
    xlabel = r'$\ell$'
    xscale= 'log'
    scaling = 1e7
if (statistic == 'xiE') or (statistic == 'xiB') or (statistic == 'xipm'):
    extension_E = 'xiP'
    extension_B = 'xiM'
    if statistic == 'xipm':
        ylabel_E = r'$\theta\xi_+[10^{-4}{\rm arcmin}]$'
        ylabel_B = r'$\theta\xi_-[10^{-4}{\rm arcmin}]$'
    elif statistic == 'xiE':
        ylabel_E = r'$\theta\xi^{\rm E}_+[10^{-4}{\rm arcmin}]$'
        ylabel_B = r'$\theta\xi^{\rm E}_-[10^{-4}{\rm arcmin}]$'
    else:
        ylabel_E = r'$\theta\xi^{\rm B}_+[10^{-4}{\rm arcmin}]$'
        ylabel_B = r'$\theta\xi^{\rm B}_-[10^{-4}{\rm arcmin}]$'
    xlabel = r'$\theta$'
    xscale= 'log'
    scaling = 1e4

with fits.open(inputfile) as f:
    E_data = f[extension_E].data
    B_data = f[extension_B].data
    n_data = len(E_data)
    E_cov = f['COVMAT'].data[:n_data,:][:,:n_data]
    B_cov = f['COVMAT'].data[n_data:,:][:,n_data:]

if (statistic == 'xiE') or (statistic == 'xiB'):
    ymax_E = np.max(E_data['ANG']*E_data['VALUE']*scaling*1.3)
    ymin_E = np.min(E_data['ANG']*E_data['VALUE']*scaling*1.3)
    ymax_B = np.max(B_data['ANG']*B_data['VALUE']*scaling*1.3)
    ymin_B = np.min(B_data['ANG']*B_data['VALUE']*scaling*1.3)
elif statistic == 'bandpowers':
    ymax_E = np.max(E_data['VALUE']/E_data['ANG']*scaling*1.3)
    ymin_E = np.min(E_data['VALUE']/E_data['ANG']*scaling*1.3)
    ymax_B = np.max(B_data['VALUE']/B_data['ANG']*scaling*1.3)
    ymin_B = np.min(B_data['VALUE']/B_data['ANG']*scaling*1.3)
else:
    ymax_E = np.max(E_data['VALUE']*scaling*1.3)
    ymin_E = np.min(E_data['VALUE']*scaling*1.3)
    ymax_B = np.max(B_data['VALUE']*scaling*1.3)
    ymin_B = np.min(B_data['VALUE']*scaling*1.3)


n_combinations = int(ntomo*(ntomo+1)/2)
n_data_per_bin = int(n_data / n_combinations)
E_std = np.sqrt(np.diag(E_cov))
B_std = np.sqrt(np.diag(B_cov))

# plotting sizes
yprops=dict(rotation=90, horizontalalignment='center',verticalalignment='center', x=10,labelpad=20, fontsize=15)
leg1=Rectangle((0,0),0,0,alpha=0.0)
formatter = ScalarFormatter(useMathText=True)
formatter.set_scientific(True)                                                                                               
fig_width_pt = 246.0*3.5 # Get this from LaTex using \the\columnwidth  
inches_per_pt = 1.0/72.27
golden_mean = (np.sqrt(5)-1.0)/2.0
fig_width  = fig_width_pt*inches_per_pt # width in inches                                                                      
fig_height = fig_width*golden_mean # height in inches                                                                          
fig_size = [fig_width, fig_height*1.5]           
fontsize=15
params = {'axes.labelsize':15,
          'font.size':10,
          'legend.fontsize':17,
          'xtick.labelsize':12,
          'ytick.labelsize':12,
          'figure.figsize':fig_size,
          'font.family': 'serif'}
pl.rcParams.update(params)
pl.subplots_adjust(wspace=0.,hspace=0.) # you can add spaces between the block here
pl.clf()
fig = pl.figure(1, figsize = (20,20))
pl.clf()

if (statistic == 'cosebis') or (statistic == 'bandpowers'):
    # Plotting
    for bin1 in range(1,ntomo+1):
        for bin2 in range(bin1,ntomo+1):
            index=int(ntomo*(bin1-1)-(bin1-1)*(bin1-1-1)/2+(bin2-1)-(bin1-1))
            ax=pl.subplot(ntomo+1,ntomo+1,(bin1-1)*(ntomo+1)+(bin2-1)+2) # use this for upper triangle
            ax.set_ylim(ymin_E,ymax_E)
            pl.xscale(xscale)
            idx = np.where((E_data['BIN1']==bin1) & (E_data['BIN2']==bin2))[0]
            # Plot data
            if statistic == 'bandpowers':
                ax.errorbar(E_data['ANG'][idx], E_data['VALUE'][idx]/E_data['ANG'][idx]*scaling, E_std[idx]/E_data['ANG'][idx]*scaling, linestyle = 'None', marker = '.', markersize=5)
            else:
                ax.errorbar(E_data['ANG'][idx],E_data['VALUE'][idx]*scaling, yerr=E_std[idx]*scaling, fmt='d',markeredgecolor='C0',mew=1,markerfacecolor='C0', color='C0', markersize=4)

            ax.axhline(y=0, color='k', ls=':',label='')
            pl.setp(ax.get_yticklabels(),  visible=False)
            pl.setp(ax.get_xticklabels(),  visible=False)
            if bin1==1:
                ax.set_xlabel(xlabel)
                ax.xaxis.set_label_coords(0.5, 1.4) 
                pl.setp(ax.get_xticklabels(),  visible=True)
                ax.xaxis.tick_top()
            if bin2==ntomo:
                pl.setp(ax.get_yticklabels(),  visible=True)
                ax.yaxis.tick_right()
            if (bin2==ntomo) & (bin1==np.floor(ntomo/2.)):
                ax.set_ylabel(ylabel_E,**yprops)
                ax.yaxis.set_label_coords(1.4, 0.0) 
            lg = pl.legend([leg1],['z-'+str(bin1)+str(bin2)],loc='upper right',
                        handlelength=0,borderpad=0,labelspacing=0.,ncol=3,prop={'size':fontsize}
                        ,columnspacing=0,frameon=None)
            lg.draw_frame(False)
            # pl.gca().add_artist(lg)
            # if((bin1==1) & (bin2==bin1)):
            #     lg = pl.legend(bbox_to_anchor=(0.0, 1),handlelength=1,borderpad=0,labelspacing=0.1,ncol=1,prop={'size':fontsize}
            #         ,columnspacing=0,frameon=None)
            #     lg.draw_frame(False)
                
            #################################################################
            # lower triangle for B-modes
            ax=pl.subplot(ntomo+1,ntomo+1,(bin2-1)*(ntomo+1)+(bin1-1)+ntomo+2)
            if bin1==1:
                pl.setp(ax.get_yticklabels(),  visible=True)
            else:
                pl.setp(ax.get_yticklabels(),  visible=False)
            if bin2==ntomo:
                pl.setp(ax.get_xticklabels(),  visible=True)
            else:
                pl.setp(ax.get_xticklabels(),  visible=False)
                
            # ax.set_ylim(ymin_B,ymax_B)
            ax.set_ylim(ymin_E,ymax_E)
            pl.xscale(xscale)
            
            if (bin1==1)&(bin2==np.floor(ntomo/2.)):
                ax.set_ylabel(ylabel_B,**yprops)
                ax.yaxis.set_label_coords(-0.5, 0.0) 
            if bin2==ntomo:
                ax.set_xlabel(xlabel)
            idx = np.where((E_data['BIN1']==bin1) & (E_data['BIN2']==bin2))[0]
            # Plot data
            if statistic == 'bandpowers':
                ax.errorbar(B_data['ANG'][idx], B_data['VALUE'][idx]/B_data['ANG'][idx]*scaling, B_std[idx]/B_data['ANG'][idx]*scaling, linestyle = 'None', marker = '.', markersize=5)
            else:
                ax.errorbar(B_data['ANG'][idx],B_data['VALUE'][idx]*scaling, yerr=B_std[idx]*scaling, fmt='d',markeredgecolor='C0',mew=1,markerfacecolor='C0', color='C0', markersize=4)
            
            ax.axhline(y=0, color='k', ls=':')
            lg = pl.legend([leg1],['z-'+str(bin1)+str(bin2)],loc='upper right',
                    handlelength=0,borderpad=0,labelspacing=0.1,ncol=2,prop={'size':fontsize}
                    ,columnspacing=0,frameon=None)
            lg.draw_frame(False)
            # pl.gca().add_artist(lg)
            # if((bin1==1) & (bin2==bin1)):
            #     lg = pl.legend(bbox_to_anchor=(-0.1, 0.5),handlelength=1,borderpad=0,labelspacing=0.1,ncol=1,prop={'size':fontsize}
            #         ,columnspacing=0,frameon=None)
            #     lg.draw_frame(False)
    fig.suptitle(r'%s %s %s, $\theta=[%.2f,%.2f]$'%(title,suffix,statistic,thetamin,thetamax), fontsize=20)
    if suffix:
        pl.savefig(output_dir+'/datavector_%.2f-%.2f_%s.pdf'%(thetamin,thetamax,suffix))
    else:
        pl.savefig(output_dir+'/datavector_%.2f-%.2f.pdf'%(thetamin,thetamax))
    pl.close()

    if statistic == 'cosebis':
        yprops=dict(rotation=90, horizontalalignment='center',verticalalignment='center', x=10,labelpad=20, fontsize=15)
        leg1=Rectangle((0,0),0,0,alpha=0.0)
        formatter = ScalarFormatter(useMathText=True)
        formatter.set_scientific(True)                                                                                               
        fig_width_pt = 246.0*3.5 # Get this from LaTex using \the\columnwidth  
        inches_per_pt = 1.0/72.27
        golden_mean = (np.sqrt(5)-1.0)/2.0
        fig_width  = fig_width_pt*inches_per_pt # width in inches                                                                      
        fig_height = fig_width*golden_mean # height in inches                                                                          
        fig_size = [fig_width, fig_height*1.5]           
        fontsize=15
        params = {'axes.labelsize':15,
                'font.size':10,
                'legend.fontsize':17,
                'xtick.labelsize':12,
                'ytick.labelsize':12,
                'figure.figsize':fig_size,
                'font.family': 'serif'}
        pl.rcParams.update(params)
        pl.subplots_adjust(wspace=0.,hspace=0.) # you can add spaces between the block here
        pl.clf()
        fig = pl.figure(1, figsize = (20,20))
        pl.clf()
        # Plotting
        for bin1 in range(1,ntomo+1):
            for bin2 in range(bin1,ntomo+1):
                index=int(ntomo*(bin1-1)-(bin1-1)*(bin1-1-1)/2+(bin2-1)-(bin1-1))
                ax=pl.subplot(ntomo+1,ntomo+1,(bin1-1)*(ntomo+1)+(bin2-1)+2) # use this for upper triangle
                ax.set_ylim(ymin_E,ymax_E)
                pl.xscale(xscale)
                idx = np.where((E_data['BIN1']==bin1) & (E_data['BIN2']==bin2) & (E_data['ANGBIN']<=5))[0]
                # Plot data
                ax.errorbar(E_data['ANG'][idx],E_data['VALUE'][idx]*scaling, yerr=E_std[idx]*scaling, fmt='d',markeredgecolor='C0',mew=1,markerfacecolor='C0', color='C0', markersize=4)

                ax.axhline(y=0, color='k', ls=':',label='')
                pl.setp(ax.get_yticklabels(),  visible=False)
                pl.setp(ax.get_xticklabels(),  visible=False)
                if bin1==1:
                    ax.set_xlabel(xlabel)
                    ax.xaxis.set_label_coords(0.5, 1.4) 
                    pl.setp(ax.get_xticklabels(),  visible=True)
                    ax.xaxis.tick_top()
                if bin2==ntomo:
                    pl.setp(ax.get_yticklabels(),  visible=True)
                    ax.yaxis.tick_right()
                if (bin2==ntomo) & (bin1==np.floor(ntomo/2.)):
                    ax.set_ylabel(ylabel_E,**yprops)
                    ax.yaxis.set_label_coords(1.4, 0.0) 
                lg = pl.legend([leg1],['z-'+str(bin1)+str(bin2)],loc='upper right',
                            handlelength=0,borderpad=0,labelspacing=0.,ncol=3,prop={'size':fontsize}
                            ,columnspacing=0,frameon=None)
                lg.draw_frame(False)
                # pl.gca().add_artist(lg)
                # if((bin1==1) & (bin2==bin1)):
                #     lg = pl.legend(bbox_to_anchor=(0.0, 1),handlelength=1,borderpad=0,labelspacing=0.1,ncol=1,prop={'size':fontsize}
                #         ,columnspacing=0,frameon=None)
                #     lg.draw_frame(False)
                    
                #################################################################
                # lower triangle for B-modes
                ax=pl.subplot(ntomo+1,ntomo+1,(bin2-1)*(ntomo+1)+(bin1-1)+ntomo+2)
                if bin1==1:
                    pl.setp(ax.get_yticklabels(),  visible=True)
                else:
                    pl.setp(ax.get_yticklabels(),  visible=False)
                if bin2==ntomo:
                    pl.setp(ax.get_xticklabels(),  visible=True)
                else:
                    pl.setp(ax.get_xticklabels(),  visible=False)
                    
                # ax.set_ylim(ymin_B,ymax_B)
                ax.set_ylim(ymin_E,ymax_E)
                pl.xscale(xscale)
                
                if (bin1==1)&(bin2==np.floor(ntomo/2.)):
                    ax.set_ylabel(ylabel_B,**yprops)
                    ax.yaxis.set_label_coords(-0.5, 0.0) 
                if bin2==ntomo:
                    ax.set_xlabel(xlabel)
                idx = np.where((E_data['BIN1']==bin1) & (E_data['BIN2']==bin2) & (B_data['ANGBIN']<=5))[0]
                # Plot data
                ax.errorbar(B_data['ANG'][idx],B_data['VALUE'][idx]*scaling, yerr=B_std[idx]*scaling, fmt='d',markeredgecolor='C0',mew=1,markerfacecolor='C0', color='C0', markersize=4)
                
                ax.axhline(y=0, color='k', ls=':')
                lg = pl.legend([leg1],['z-'+str(bin1)+str(bin2)],loc='upper right',
                        handlelength=0,borderpad=0,labelspacing=0.1,ncol=2,prop={'size':fontsize}
                        ,columnspacing=0,frameon=None)
                lg.draw_frame(False)
                # pl.gca().add_artist(lg)
                # if((bin1==1) & (bin2==bin1)):
                #     lg = pl.legend(bbox_to_anchor=(-0.1, 0.5),handlelength=1,borderpad=0,labelspacing=0.1,ncol=1,prop={'size':fontsize}
                #         ,columnspacing=0,frameon=None)
                #     lg.draw_frame(False)
        fig.suptitle(r'%s %s %s, $\theta=[%.2f,%.2f]$'%(title,suffix,statistic,thetamin,thetamax), fontsize=20)
        if suffix:
            pl.savefig(output_dir+'/datavector_%.2f-%.2f_%s_nmax5.pdf'%(thetamin,thetamax,suffix))
        else:
            pl.savefig(output_dir+'/datavector_%.2f-%.2f_nmax5.pdf'%(thetamin,thetamax))
        pl.close()

        pl.rcParams.update(pl.rcParamsDefault)

if (statistic == 'xiE') or (statistic == 'xiB') or (statistic == 'xipm'):
    # Plotting
    for bin1 in range(1,ntomo+1):
        for bin2 in range(bin1,ntomo+1):
            index=int(ntomo*(bin1-1)-(bin1-1)*(bin1-1-1)/2+(bin2-1)-(bin1-1))
            ax=pl.subplot(ntomo+1,ntomo+1,(bin1-1)*(ntomo+1)+(bin2-1)+2) # use this for upper triangle
            ax.set_ylim(ymin_E,ymax_E)
            pl.xscale(xscale)
            idx = np.where((E_data['BIN1']==bin1) & (E_data['BIN2']==bin2))[0]
            # Plot data
            ax.errorbar(E_data['ANG'][idx],E_data['ANG'][idx]*E_data['VALUE'][idx]*scaling, yerr=E_data['ANG'][idx]*E_std[idx]*scaling, fmt='d',markeredgecolor='C0',mew=1,markerfacecolor='C0', color='C0', markersize=4)

            ax.axhline(y=0, color='k', ls=':',label='')
            pl.setp(ax.get_yticklabels(),  visible=False)
            pl.setp(ax.get_xticklabels(),  visible=False)
            if bin1==1:
                ax.set_xlabel(xlabel)
                ax.xaxis.set_label_coords(0.5, 1.4) 
                pl.setp(ax.get_xticklabels(),  visible=True)
                ax.xaxis.tick_top()
            if bin2==ntomo:
                pl.setp(ax.get_yticklabels(),  visible=True)
                ax.yaxis.tick_right()
            if (bin2==ntomo) & (bin1==np.floor(ntomo/2.)):
                ax.set_ylabel(ylabel_E,**yprops)
                ax.yaxis.set_label_coords(1.4, 0.0) 
            lg = pl.legend([leg1],['z-'+str(bin1)+str(bin2)],loc='upper right',
                        handlelength=0,borderpad=0,labelspacing=0.,ncol=3,prop={'size':fontsize}
                        ,columnspacing=0,frameon=None)
            lg.draw_frame(False)
            # pl.gca().add_artist(lg)
            # if((bin1==1) & (bin2==bin1)):
            #     lg = pl.legend(bbox_to_anchor=(0.0, 1),handlelength=1,borderpad=0,labelspacing=0.1,ncol=1,prop={'size':fontsize}
            #         ,columnspacing=0,frameon=None)
            #     lg.draw_frame(False)
                
            #################################################################
            # lower triangle for B-modes
            ax=pl.subplot(ntomo+1,ntomo+1,(bin2-1)*(ntomo+1)+(bin1-1)+ntomo+2)
            if bin1==1:
                pl.setp(ax.get_yticklabels(),  visible=True)
            else:
                pl.setp(ax.get_yticklabels(),  visible=False)
            if bin2==ntomo:
                pl.setp(ax.get_xticklabels(),  visible=True)
            else:
                pl.setp(ax.get_xticklabels(),  visible=False)
                
            # ax.set_ylim(ymin_B,ymax_B)
            ax.set_ylim(ymin_E,ymax_E)
            pl.xscale(xscale)
            
            if (bin1==1)&(bin2==np.floor(ntomo/2.)):
                ax.set_ylabel(ylabel_B,**yprops)
                ax.yaxis.set_label_coords(-0.5, 0.0) 
            if bin2==ntomo:
                ax.set_xlabel(xlabel)
            idx = np.where((E_data['BIN1']==bin1) & (E_data['BIN2']==bin2))[0]
            # Plot data
            ax.errorbar(B_data['ANG'][idx],B_data['ANG'][idx]*B_data['VALUE'][idx]*scaling, yerr=B_data['ANG'][idx]*B_std[idx]*scaling, fmt='d',markeredgecolor='C0',mew=1,markerfacecolor='C0', color='C0', markersize=4)
            
            ax.axhline(y=0, color='k', ls=':')
            lg = pl.legend([leg1],['z-'+str(bin1)+str(bin2)],loc='upper right',
                    handlelength=0,borderpad=0,labelspacing=0.1,ncol=2,prop={'size':fontsize}
                    ,columnspacing=0,frameon=None)
            lg.draw_frame(False)
            # pl.gca().add_artist(lg)
            # if((bin1==1) & (bin2==bin1)):
            #     lg = pl.legend(bbox_to_anchor=(-0.1, 0.5),handlelength=1,borderpad=0,labelspacing=0.1,ncol=1,prop={'size':fontsize}
            #         ,columnspacing=0,frameon=None)
            #     lg.draw_frame(False)
    fig.suptitle(r'%s %s, $\theta=[%.2f,%.2f]$'%(title,statistic,thetamin,thetamax), fontsize=20)
    if suffix:
        pl.savefig(output_dir+'/datavector_%.2f-%.2f_%s.pdf'%(thetamin,thetamax,suffix))
    else:
        pl.savefig(output_dir+'/datavector_%.2f-%.2f.pdf'%(thetamin,thetamax))
    pl.close()










