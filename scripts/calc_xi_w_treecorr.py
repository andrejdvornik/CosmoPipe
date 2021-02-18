# ----------------------------------------------------------------
# File Name:           calc_xi_w_treecorr.py
# Author:              Catherine Heymans (heymans@roe.ac.uk)
# Description:         short python script to run treecorr to calculate xi_+/- 
#                      given a KiDS fits catalogue
#                      script will need to change if keywords in KIDS cats are updated
# ----------------------------------------------------------------

import treecorr
import sys
import numpy as np
import astropy.io.fits as fits

def subtractNoise(g_1, g_2, eps_1, eps_2):
    g   = g_1 + 1j * g_2
    g_c = g_1 - 1j * g_2
    eps = eps_1 + 1j * eps_2
    
    e = (eps - g) / (1.0 - g_c*eps)
    e = np.array([e.real, e.imag])
    return e

if __name__ == '__main__':

    # Read in user input to set the nbins, theta_min, theta_max, lin_not_log, fitscat1, fitscat2, outfilename, weighted
    if len(sys.argv) <9: 
        print("Usage: %s nbins theta_min(arcmin) theta_max(arcmin) lin_not_log? catalogue1.fits \
                catalogue2.fits outfilename weighted_analysis?" % sys.argv[0]) 
        sys.exit(1)
    else:
        nbins = int(sys.argv[1]) 
        theta_min = float(sys.argv[2]) 
        theta_max = float(sys.argv[3]) 
        lin_not_log = sys.argv[4] 
        fitscat1 = sys.argv[5]
        fitscat2 = sys.argv[6]
        outfile = sys.argv[7]
        weighted = sys.argv[8]

    # prepare the catalogues
    cat1 = treecorr.Catalog(fitscat1, ra_col='ALPHA_J2000', dec_col='DELTA_J2000', ra_units='deg', dec_units='deg', \
                                      g1_col="e1_corr", g2_col="e2_corr", w_col='@WEIGHTNAME@')
    cat2 = treecorr.Catalog(fitscat2, ra_col='ALPHA_J2000', dec_col='DELTA_J2000', ra_units='deg', dec_units='deg', \
                                      g1_col="e1_corr", g2_col="e2_corr", w_col='@WEIGHTNAME@')

    if nbins > 100: ## Fine-binning
        inbinslop = 1.5
    else: ## Broad bins
        inbinslop = 0.08

    # Define the binning based on command line input
    if(lin_not_log=='true'): 
        gg = treecorr.GGCorrelation(min_sep=theta_min, max_sep=theta_max, nbins=nbins, sep_units='arcmin',\
            bin_type='Linear', bin_slop=inbinslop)
    else: # Log is the default bin_type for Treecorr
        gg = treecorr.GGCorrelation(min_sep=theta_min, max_sep=theta_max, nbins=nbins, sep_units='arcmin', \
            bin_slop=inbinslop)

    ## Linc likes to use only 8 processors
    num_threads = None

    # Calculate the 2pt correlation function
    gg.process(cat1, cat2, num_threads=num_threads)

    if (weighted=='true'):    
    # prepare the weighted_square catalogues - hack so that Treecorr returns the correct Npairs for a weighted sample

        cat1_wsq = treecorr.Catalog(fitscat1, ra_col='ALPHA_J2000', dec_col='DELTA_J2000', ra_units='deg', dec_units='deg', \
                                      g1_col="e1_corr", g2_col="e2_corr", w_col='@WEIGHTNAME@_sq')
        cat2_wsq = treecorr.Catalog(fitscat2, ra_col='ALPHA_J2000', dec_col='DELTA_J2000', ra_units='deg', dec_units='deg', \
                                      g1_col="e1_corr", g2_col="e2_corr", w_col='@WEIGHTNAME@_sq')

        # Define the binning based on command line input
        if(lin_not_log=='true'): 
            gg_wsq = treecorr.GGCorrelation(min_sep=theta_min, max_sep=theta_max, nbins=nbins, sep_units='arcmin',\
                                        bin_type='Linear', bin_slop=inbinslop)
        else: # Log is the default bin_type for Treecorr
            gg_wsq = treecorr.GGCorrelation(min_sep=theta_min, max_sep=theta_max, nbins=nbins, sep_units='arcmin', \
                                        bin_slop=inbinslop)    

        # Calculate the weighted square 2pt correlation function
        gg_wsq.process(cat1_wsq,cat2_wsq, num_threads=num_threads)

        # Calculate the weighted Npairs = sum(weight_a*weight_b)^2 / sum(weight_a^2*weight_b^2)

        npairs_weighted = (gg.weight)*(gg.weight)/gg_wsq.weight

        #Use treecorr to write out the output file updating the npairs column and praise-be for Jarvis and his well documented code
        #as sigma_xip = sigma_xim, I've replaced sigma_xim with the raw npairs so we can store it in case useful at any point
        
        treecorr.util.gen_write(outfile,
                ['r_nom','meanr','meanlogr','xip','xim','xip_pm','xim_im','sigma_xip', 'npairs', 'weight','npairs_weighted' ],
                [ gg.rnom,gg.meanr, gg.meanlogr,gg.xip, gg.xim, gg.xip_im, gg.xim_im, np.sqrt(gg.varxip), gg.npairs, 
                gg.weight, npairs_weighted], precision=12)
    else:

        # Write it out unweighted npairs and praise-be again for Jarvis and his well documented code
        gg.write(outfile, precision=12)

