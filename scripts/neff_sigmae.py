import numpy as np
import sys
import ldac
import astropy.io.fits as pyfits

try:
  catalogue=pyfits.open(sys.argv[1])[1].data
  e1=catalogue.field('@E1VAR@')
  e2=catalogue.field('@E2VAR@')
  weight=catalogue.field('@WEIGHTNAME@')
  Z_B=catalogue.field('Z_B')
  GAAP_Flag=catalogue.field('@GAAPFLAG@')
except Exception:
  ldac_cat = ldac.LDACCat(sys.argv[1])
  catalogue = ldac_cat['OBJECTS']
  e1=catalogue['@E1VAR@']
  e2=catalogue['@E2VAR@']
  weight=catalogue['@WEIGHTNAME@']
  Z_B=catalogue['Z_B']
  GAAP_Flag=catalogue['@GAAPFLAG@']

area=float(sys.argv[2])

#Define the tomographic bins 
tomolims="@TOMOLIMS@"
tomolims=[float(s) for s in tomolims.split()]

# NOTE: currently the m-bias is not used in the calculation
##m-bias values per tomographic bin
#mbias="@MBIASVALUES@"
#mbias_p1=[float(s) + 1.0 for s in mbias.split()]
##estimate of m-bias for full sample
#mbias_p1.append(sum(mbias_p1)/len(mbias_p1))
mbias_p1 = [1.0 for _ in range(len(tomolims))]

#Nbins is nTOMO + 1 (ALL) = len(tomolims)-1+1
nbins=len(tomolims)

print "# zlow zhigh n_obj n_eff[1/arcmin^2] sigma_e1 sigma_e2 sigma_e1_wsq sigma_e2_wsq sigma_e"

for j in range(nbins):
  if (j<nbins-1) :
    low_z = tomolims[j]
    high_z = tomolims[j+1]
  else:
    low_z = tomolims[0]
    high_z = tomolims[nbins-1]

  low_z_cut = low_z + 0.001 
  high_z_cut = high_z + 0.001 
  photoz_cut = (Z_B > low_z_cut) & (Z_B <= high_z_cut)
  GAAP_Flag_cut = GAAP_Flag == 0

  all_cuts = photoz_cut & GAAP_Flag_cut
  number = np.count_nonzero(all_cuts)

  weight_masked = weight[all_cuts]
  weight_sq_masked = weight_masked**2
  weight_sum = weight_masked.sum()

  # if per-object m-bias values are given
  if len(mbias_p1) == len(Z_B):
    mbias_p1_masked = mbias_p1[all_cuts]
  else:
    mbias_p1_masked = mbias_p1[j]

  e1_masked = e1[all_cuts]
  e2_masked = e2[all_cuts]

  n_eff = (
    np.sum( weight_masked * mbias_p1_masked    )**2 /
    np.sum((weight_masked * mbias_p1_masked)**2) /
    area)

  mean_e1 = np.average(e1_masked, weights=weight_masked)
  mean_e2 = np.average(e2_masked, weights=weight_masked)
  sigma_e1 = np.sqrt((  # standard error of the mean
      np.sum(weight_masked * e1_masked**2   ) /
      np.sum(weight_masked * mbias_p1_masked) -
      mean_e1**2
    ) / weight_sum)
  sigma_e2 = np.sqrt((  # standard error of the mean
      np.sum(weight_masked * e2_masked**2   ) /
      np.sum(weight_masked * mbias_p1_masked) -
      mean_e2**2
    ) / weight_sum)

  mean_e1_wsq = np.average(e1_masked, weights=weight_masked**2)
  mean_e2_wsq = np.average(e2_masked, weights=weight_masked**2)
  sigma_e1_wsq = np.sqrt((  # standard error of the mean with weights squared
      np.sum((weight_masked * e1_masked      )**2) /
      np.sum((weight_masked * mbias_p1_masked)**2) -
      mean_e1_wsq**2
    ) / weight_sum)
  sigma_e2_wsq = np.sqrt((  # standard error of the mean with weights squared
      np.sum((weight_masked * e2_masked      )**2) /
      np.sum((weight_masked * mbias_p1_masked)**2) -
      mean_e2_wsq**2
    ) / weight_sum)

  sigma_e = (  # geometric mean
    np.sqrt(  # standard deviation of e1 (assuming mean is zero)
      np.sum((weight_masked * e1_masked      )**2) /
      np.sum((weight_masked * mbias_p1_masked)**2)
    ) / 2.0 +
    np.sqrt(  # standard deviation of e2 (assuming mean is zero)
      np.sum((weight_masked * e2_masked      )**2) /
      np.sum((weight_masked * mbias_p1_masked)**2)
    ) / 2.0)

  print low_z, high_z, number, n_eff, sigma_e1, sigma_e2, sigma_e1_wsq, sigma_e2_wsq, sigma_e
