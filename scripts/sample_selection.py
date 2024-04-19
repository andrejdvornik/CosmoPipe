  #!/usr/bin/env python
# -*- coding: utf-8 -*-


import time
import multiprocessing as multi
import numpy as np
import matplotlib.pyplot as pl
import scipy
from scipy.integrate import simps, trapz, cumtrapz
from scipy.interpolate import interp1d, UnivariateSpline
import scipy.special as sp
import astropy.io.fits as fits
from astropy.units import eV
import astropy.units as u
from astropy.cosmology import FlatLambdaCDM, Flatw0waCDM, LambdaCDM, z_at_value
from astropy.stats import sigma_clip
import scipy.stats as ss
from scipy.signal import find_peaks
from scipy.stats import gaussian_kde
from sklearn.neighbors import KernelDensity
import matplotlib.patheffects as pe
import matplotlib.patches as mpatches
from matplotlib.patches import Rectangle



if __name__ == '__main__':


    random = True
    print(random)
    
    min_z = 0.0
    max_z = 0.7
    
    

    h = 1.0
    omegam = 0.3
    omegav = 0.7

    cosmo_model = LambdaCDM(H0=h*100., Om0=omegam, Ode0=omegav)


    import dill as pickle
    with open('/net/home/fohlen13/dvornik/smf_for_cosmo/mass_lim_final.npy', 'rb') as dill_file:
        fit_func_inv = pickle.load(dill_file)
        
    with open('/net/home/fohlen13/dvornik/smf_for_cosmo/mass_lim_low_final.npy', 'rb') as dill_file:
        fit_func_low = pickle.load(dill_file)

    
    
    file_in = fits.open('/net/home/fohlen13/dvornik/lephare_bright_stellarmasses/absmag_ugriZYJHKs/photozs.DR4.1_bright_ugri+KV_masses.fits')
    
    data_in = file_in[1].data
    
    print(len(data_in))
    
    
    z_in = data['z_ANNZ_KV']
    
    r_proj = cosmo_model.comoving_distance(z_in).value
    
    step = 0.5
    m_low = 8.5
    m_high = 11.5
    bins = np.int((m_high-m_low)/step)
    
    m_bins = np.linspace(m_low, m_high, bins+1, endpoint=True)
    m_bins = np.array([9.1,9.6,9.95,10.25,10.5,10.7,11.3])
    
    z_print = []
    mass_print = []
    
    index_column = z_in.copy()
    index_column[:] = -99
    print(np.unique(index_column))
    
    x = np.linspace(6.0, 13.0, 100)
    pl.rc('text',usetex=True)
    #pl.rcParams.update({'font.size': 20})
    fig, ax = pl.subplots(1, 1, figsize=(6, 6))
    ax.set_ylim([6, 12])
    ax.set_xlim([0, 0.55])
    ax.hexbin(z_in, stellar_mass_in, gridsize=100, cmap=my_cmap, bins='log', rasterized=True, extent=(0, 0.7, 6, 12))
    ax.plot(fit_func_inv(x), x, label=r'$M_{\star}\, \mathrm{limit}$')
    for i in range(bins):
        z_low = fit_func_low(m_bins[i+1])
        z_high = fit_func_inv(m_bins[i])
        
        idx = np.where((stellar_mass_in <= m_bins[i+1]) & (stellar_mass_in > m_bins[i]) & (z_in <= z_high) & (z_in > z_low))
        ax.scatter(z_in[idx], stellar_mass_in[idx], color='k', alpha=0.25, marker='.', s=1, rasterized=True)
        print(stellar_mass_in[idx].size)
        index_column[idx] = i+1
        
        ax.add_patch(Rectangle((z_low,m_bins[i]),(z_high-z_low),(m_bins[i+1]-m_bins[i]),linewidth=1,edgecolor='r',facecolor='none'))
        z_print.append(np.median(z_in[idx]))
        mass_print.append(np.log10(np.median(10.0**stellar_mass_in[idx])))
       
    ax.set_ylabel(r'$\log(M_{\star}/h^{-2}\,M_{\odot})$')
    ax.set_xlabel(r'$z_{\mathrm{ANNz}}$')
    #ax.axes.set_aspect('equal')
    handles, labels = ax.get_legend_handles_labels()
    # manually define a new patch
    patch = mpatches.Patch(edgecolor='red', facecolor='white', label=r'$\mathrm{Volume\, limited\ sample}$')
    # handles is a list, so append manual patch
    handles.append(patch)
    # plot the legend
    pl.legend(handles=handles, loc='lower right')#, fontsize=12)
            
    pl.tight_layout()
    pl.savefig('/net/home/fohlen13/dvornik/smf_for_cosmo/selection_update2.pdf', dpi=800)
    pl.clf()
   
    
    data_out = np.copy(data[np.where(index_column != -99)])
    print(len(data_out)) #check size
    new_cols = fits.Column(name='bins', format='I', array=index_column[np.where(index_column != -99)])
    new_cols1 = fits.Column(name='stellar_mass', format='D', array=stellar_mass_in[np.where(index_column != -99)])
    new_cols2 = fits.Column(name='r_como', format='D', array=r_proj[np.where(index_column != -99)])
    
    cols = fits.ColDefs(data_out)
    hdu = fits.BinTableHDU.from_columns(cols + new_cols + new_cols1 + new_cols2)
    hdu.writeto('/net/home/fohlen13/dvornik/smf_for_cosmo/selection_final_test.fits', overwrite=True)

   
    
    
    if random:
        print('\nCreate randoms')
        data_in = fits.open('/net/home/fohlen13/dvornik/smf_for_cosmo/selection_final.fits')
        data_in = data_in[1].data
        random_in = fits.open('/net/home/fohlen13/dvornik/random_cats/bright_randoms/ANNzBright_match_100A_randoms.fits')
        random_in = random_in[1].data
        
        print(len(random_in['ID']))
        z_in_rand = random_in['z_ANNZ_KV']
        
        for i in range(bins):
            
            z_low = fit_func_low(m_bins[i+1])
            z_high = fit_func_inv(m_bins[i])
        
            idx = np.where((z_in_rand <= z_high) & (z_in_rand > z_low))
            random = np.copy(random_in[idx])
        
            mask_bin = np.where(data_in['bins']==i+1)
            index = np.in1d(random['clone_ID'], data_in['ID'][mask_bin])
            
            data_out = np.copy(random[np.where(random[index])])#[::3]) # remove every 3nd after testing
            print(len(data_out))
            
            num_col = np.arange(len(data_out['clone_ID']))
            print(len(np.unique(num_col)))
            r_proj_rand = cosmo_model.comoving_distance(data_out['z_ANNZ_KV']).value
            
            cols = fits.ColDefs(data_out)
            num = fits.Column(name='UNIQUEID', format='J', array=num_col)
            new_cols_r = fits.Column(name='r_como', format='D', array=r_proj_rand)
            
            hdu = fits.BinTableHDU.from_columns(cols + num + new_cols_r)
            hdu.writeto('/net/home/fohlen13/dvornik/random_cats/bright_randoms/selection_final_{}.fits'.format(i+1), overwrite=True)




    
