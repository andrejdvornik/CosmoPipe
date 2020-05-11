import numpy as np
import sys
import math
import ldac
import astropy.io.fits as pyfits

def weighted_avg_and_std(values, weights):
    """
    Return the weighted average and standard deviation.

    values, weights -- Numpy ndarrays with the same shape.
    """
    average = np.average(values, weights=weights)
    variance = np.average((values-average)**2, weights=weights)  # Fast and numerically precise
    return (average, math.sqrt(variance))

try:
  catalogue=pyfits.open(sys.argv[1])[1].data
  e1=catalogue.field('@E1VAR@')
  e2=catalogue.field('@E2VAR@')
  weight=catalogue.field('@WEIGHTNAME@')
  Z_B=catalogue.field('Z_B')
  GAAP_Flag=catalogue.field('GAAP_Flag_ugriZYJHKs')
except:
  ldac_cat = ldac.LDACCat(sys.argv[1])
  catalogue = ldac_cat['OBJECTS']
  e1=catalogue['@E1VAR@']
  e2=catalogue['@E2VAR@']
  weight=catalogue['@WEIGHTNAME@']
  Z_B=catalogue['Z_B']
  GAAP_Flag=catalogue['GAAP_Flag_ugriZYJHKs']

area=float(sys.argv[2])

#Define the tomographic bins 
tomolims="@TOMOLIMS@"
tomolims=tomolims.split()

#Nbins is nTOMO + 1 (ALL) = len(tomolims)-1+1
nbins=len(tomolims)


print "# zlow zhigh n_obj n_eff[1/arcmin^2] sigma_e1 sigma_e2 sigma_e1_wsq sigma_e2_wsq"

for j in range(nbins):
  if (j<nbins-1) :
    low_z = float(tomolims[j])
    high_z = float(tomolims[j+1])
  else:
    low_z = float(tomolims[0])
    high_z = float(tomolims[nbins-1])

  low_z_cut = low_z + 0.001 
  high_z_cut = high_z + 0.001 
  photoz_cut_low  = np.greater(Z_B, low_z_cut)
  photoz_cut_high = np.less_equal(Z_B, high_z_cut)
  photoz_cut      = np.logical_and(photoz_cut_low, photoz_cut_high)
  GAAP_Flag_cut   = np.equal(GAAP_Flag,0)
  all_cuts = photoz_cut * GAAP_Flag_cut
  
  number = np.shape(weight[all_cuts])[0]
  
  n_eff = np.sum(weight[all_cuts])**2/np.sum(weight[all_cuts]**2)/area
  sigma_e1 = weighted_avg_and_std(e1[all_cuts],weight[all_cuts])[1]
  sigma_e2 = weighted_avg_and_std(e2[all_cuts],weight[all_cuts])[1]

  sigma_e1_wsq = weighted_avg_and_std(e1[all_cuts],weight[all_cuts]**2)[1]
  sigma_e2_wsq = weighted_avg_and_std(e2[all_cuts],weight[all_cuts]**2)[1]

  print low_z, high_z, number, n_eff, sigma_e1, sigma_e2, sigma_e1_wsq, sigma_e2_wsq
