  #!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import argparse
import numpy as np
import matplotlib.pyplot as pl
import astropy.io.fits as fits
# import astropy.units as u
# from astropy.cosmology import FlatLambdaCDM, Flatw0waCDM, LambdaCDM, z_at_value
from astropy.cosmology import LambdaCDM
# from astropy.stats import sigma_clip
# import scipy.stats as ss
# from scipy.signal import find_peaks
# from scipy.stats import gaussian_kde
# from sklearn.neighbors import KernelDensity
import dill as pickle
pl.ioff()



if __name__ == '__main__':

    parser = argparse.ArgumentParser()
    parser.add_argument('--h0', type=float, help='h0 from LePhare or other stellar mass code estimation routine', nargs='?', default=1.0, const=1.0)
    parser.add_argument('--omegam', type=float, help='Om_m from LePhare or other stellar mass code estimation routine', nargs='?', default=0.3, const=0.3)
    parser.add_argument('--omegav', type=float, help='Om_v from LePhare or other stellar mass code estimation routine', nargs='?', default=0.7, const=0.7)
    parser.add_argument('--area', type=float, help='Effective area of the survey/catalogue', nargs='?', default=777.4, const=777.4)
    parser.add_argument('--min_mass', type=float, help='Minimum stellar mass bin limit', nargs='?', default=7.0, const=7.0)
    parser.add_argument('--max_mass', type=float, help='Maximum stellar mass bin limit', nargs='?', default=12.5, const=12.5)
    parser.add_argument('--nbins', type=int, help='Number of stellar mass bins', nargs='?', default=30, const=30)
    parser.add_argument('--min_z', type=float, help='Minimum redshift of the bin if not using computed stellar mass limits', nargs='?', default=0.001, const=0.001)
    parser.add_argument('--max_z', type=float, help='Maximum redshift of the bin if not using computed stellar mass limits', nargs='?', default=1.0, const=1.0)
    parser.add_argument('--stellar_mass_column', type=str, help='Stellar mass column', default='stellar_mass', required=True)
    parser.add_argument('--z_column', type=str, help='Redshift column', default='z_ANNZ_KV', required=True)
    parser.add_argument('--path', type=str, help='Path to npy files required for mass limit', required=True)
    parser.add_argument('--file', type=str, help='Input catalogue', default='fluxscale_fixed.fits', required=True)
    parser.add_argument('--compare_to_gama', type=bool, help='Plot comparison figures', nargs='?', default=False, const=True)
    parser.add_argument('--output_path', type=str, help='Output path', required=True)
    parser.add_argument('--output_name', type=str, help='Output name', required=True)
    parser.add_argument('--f_tomo', type=float, help='Fraction of galaxies in this bin', required=True)
    args = parser.parse_args()

    compare_to_gama = args.compare_to_gama
    path = args.path
    
    area_kids = args.area
    total_sky_area = 180.**2/np.pi**2*4.*np.pi #~41253.0
    frac = (area_kids/total_sky_area)
    f_tomo = args.f_tomo
    
    # TODO: Check the units for masses
    # From LePhare's documentation: https://www.cfht.hawaii.edu/~arnouts/LEPHARE/DOWNLOAD/lephare_doc.pdf
    # Mass is the stellar mass (M_sun)
    """
    From Blicki+2021:
    We used a standard concordance cosmology (Ωm = 0.3, ΩΛ = 0.7, and H0 = 70 km s^-1 Mpc^-1),
    a Chabrier (2003) initial mass function, the Calzetti et al. (1994) dust-extinction law, 
    Bruzual & Charlot (2003) stellar population synthesis models, 
    and exponentially declining star formation histories. 
    The input photometry to LePhare was extinction corrected using the Schlegel et al. (1998) maps 
    with the Schlafly & Finkbeiner (2011) coefficients, as described in Kuijken et al. (2019).
    """
    
    nbins = args.nbins
    Mmin_smf = args.min_mass
    Mmax_smf = args.max_mass
    min_z = args.min_z
    max_z = args.max_z
    
    stellar_mass_column = args.stellar_mass_column
    z_column = args.z_column
    
    h0 = args.h0
    omegam = args.omegam
    omegav = args.omegav
    
    
    out_path = args.output_path
    outname = args.output_name

    file_in = fits.open(args.file)

    """
    compare_to_gama = True
    
    area_kids = 777.4
    frac = (area_kids/41253.0)
    

    nbins = 30
    Mmin_smf = 7.0
    Mmax_smf = 12.5
    
    stellar_mass_column = 'stellar_mass'
    z_column = 'z_ANNZ_KV'
    
    h0 = 1.0
    omegam = 0.3
    omegav = 0.7
    
    file_in = fits.open('fluxscale_fixed.fits')
    
    """

    cosmo_model = LambdaCDM(H0=h0*100., Om0=omegam, Ode0=omegav)

    # TODO: what are these files?
    # M_star_lim(z) the completeness in stellar mass as a function of redshift or our 
    # flux limited sample
    # z_max,i: The maximum redshift beyond which galaxy i with stellar mass M_star,i 
    # would no longer be part of the sample
    with open(os.path.join(path, 'mass_lim.npy'), 'rb') as dill_file:
        fit_func_inv = pickle.load(dill_file)
    
    # Not used
    # with open(os.path.join(path, 'mass_lim_low.npy'), 'rb') as dill_file:
    #     fit_func_low = pickle.load(dill_file)
    
    data = file_in[1].data
    
    stellar_mass_in = data[stellar_mass_column]
    z_in = data[z_column]
    
    # We set the possible minimum z to 0.001
    z_min = np.maximum(0.001, min_z)
    # max_z is given as an input, this is the maximum redshift in the stellar mass-redshift bin.
    z_max_bin = max_z * np.ones_like(stellar_mass_in)
    # This is the function that was imported. Finds z_max for each stellar mass?
    z_max = fit_func_inv(stellar_mass_in)
    # Set z_max_i to which ever is smaller:
    # the maximum redshift where it can be visible given the flux limit, 
    # or maximum redshift of the stellar mass-redshift bin
    z_max_i = np.minimum(z_max_bin, z_max)
    
    # Comoving distance at z_min and z_max_i in units of Mpc h
    # z_max_i should be the maximum redshift at which galaxy i is visible.
    # dc_min and dc_max will depend on cosmology.
    # TODO: What is their sensitivity to cosmology?
    dc_min = cosmo_model.comoving_distance(z_min).to('Mpc').value * h0
    dc_max = cosmo_model.comoving_distance(z_max_i).to('Mpc').value * h0

    # comoving volume between zmin and zmax (a fraction of a spherical shell of thickness dc_max-dc_min)
    # V_max_i is the comoving volume over which galaxy i would be visible in the sample. 
    V_max = 4.0*np.pi/3.0 * frac * (dc_max**3.0 - dc_min**3.0)
    
    M_bins = np.linspace(Mmin_smf, Mmax_smf, nbins+1, endpoint=True, retstep=True)
    step = M_bins[1]
    M_bins = M_bins[0]
    
    phi_bins = np.zeros(nbins)
    vmax_out = np.zeros(nbins)
    M_center = (M_bins[1:] + M_bins[:-1])/2.0
    
    # This is the same as doing a weighted histogram, where the weights are 1/V_max
    # If the sample is volume limited then all galaxies that exist in our stellar mass-redshift bins
    # are observable.
    for i in range(nbins):
        index = ((stellar_mass_in > M_bins[i]) & (M_bins[i+1] > stellar_mass_in))
        phi_bins[i] = np.sum(1.0/V_max[index])
        # Compute the arithmetic mean, ignoring NaNs.
        vmax_out[i] = np.nanmean(V_max[index])
    
    phi_bins = np.abs(phi_bins)
    
    # TODO: To help with the integration I think we want to output the min and max mass and also report the units
    data_out = np.array([10.0**M_center, phi_bins/step, np.ones_like(phi_bins)]).T
    vmax_out = np.array([M_center, vmax_out]).T
    
    np.savetxt(f"{out_path}/smf_vec/{outname}_smf.txt", np.nan_to_num(data_out))
    np.savetxt(f"{out_path}/vmax/{outname}_vmax.txt", np.nan_to_num(vmax_out))
    np.savetxt(f"{out_path}/f_tomo/{outname}_vmax.txt", np.array([f_tomo]))
    
    
    if compare_to_gama:
        baldry = np.genfromtxt('/net/home/fohlen13/dvornik/smf_for_cosmo/gsmf-B12.txt')
        wright = np.genfromtxt('/net/home/fohlen13/dvornik/smf_for_cosmo/GAMAII_BBD_GSMFs.csv', delimiter=',')
        kids = np.genfromtxt('/net/home/fohlen13/dvornik/smf_for_cosmo/smf2_final.txt')
        #kids = np.genfromtxt('/net/home/fohlen13/dvornik/2x2pt/data_final_fix/bin_13_mlf.txt')
    
        mstar_og = 10.819 - 1.0*np.log10(h0/0.7)
        alpha_1 = -0.646
        alpha_2 = -1.507
        phi_1 = -2.39
        phi_2 = -3.452
        
        xrange = wright[:,0]
        phi_angus_og = np.log(10.0) * np.exp(-10.0**(xrange - mstar_og)) * (10.0**phi_1 * (10.0**(xrange - mstar_og))**(alpha_1+1) + 10.0**phi_2 * (10.0**(xrange -     mstar_og))**(alpha_2+1))

        
        pl.rc('text',usetex=True)
        pl.rcParams.update({'font.size': 20})
        fig, ax = pl.subplots(1, 1, figsize=(8, 8))
        ax.errorbar(baldry[:,0] - 2.0*np.log10(h0/0.7), baldry[:,2]*0.001, yerr=baldry[:,3]*0.001, ls='', ms=3, marker='o', label='Baldry et al. 2012')
        ax.errorbar(wright[:,0] - 2.0*np.log10(h0/0.7), wright[:,4], yerr=[wright[:,5], wright[:,6]], ls='', ms=3, marker='o', label='Wright et al. 2017')
        #ax.errorbar(M_center, phi_bins/step, yerr=0, ls='', ms=3, marker='o', label='KiDS bright')
        #ax.errorbar(np.log10(kids[:,0]) + 2.0*np.log10(1.0/0.7), kids[:,1] * 0.7**3.0, yerr=0, ls='', ms=3, marker='o', label='KiDS bright')
        #ax.errorbar(M_center + 2.0*np.log10(h0/0.7), phi_bins/step, yerr=0, ls='', ms=3, marker='o', label='This sample')
        #ax.errorbar(np.log10(kids[:,0]), kids[:,1], yerr=0, ls='', ms=3, marker='o', label='KiDS bright')
        ax.errorbar(M_center, phi_bins/step, yerr=0, ls='', ms=3, marker='o', label='This sample')
        #ax.plot(wright[:,0], phi_angus_og, ls='--', color='red')
        ax.set_yscale('log')
        ax.set_ylim([1e-8, 1e-1])
        ax.set_xlim([7, 13])
        ax.set_xlabel(r'$\log(M_{\star}/h^{2}M_{\odot})$')
        ax.set_ylabel(r'$\phi (\mathrm{dex}^{-1}\,h^{3}\,\mathrm{Mpc}^{-3})$')
        ax.legend()
        pl.savefig(f"{out_path}/smf/{outname}_smf_comp.png")
        pl.clf()
        pl.close()
    
    quit()
    
