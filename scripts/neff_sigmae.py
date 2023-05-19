import numpy as np
import sys
import ldac
import astropy.io.fits as pyfits

  catalogue=pyfits.open(sys.argv[1])[1].data
  e1=catalogue.field('@BV:E1NAME@')
  e2=catalogue.field('@BV:E2NAME@')
  weight=catalogue.field('@BV:WEIGHTNAME@')
except Exception:
  ldac_cat = ldac.LDACCat(sys.argv[1])
  catalogue = ldac_cat['OBJECTS']
  e1=catalogue['@BV:E1NAME@']
  e2=catalogue['@BV:E2NAME@']
  weight=catalogue['@BV:WEIGHTNAME@']

area=float(sys.argv[2])
parser = ArgumentParser(description='Compute neff and sigmae from user inputs')
parser.add_argument('-i','--input', dest="input", type=str,required=True,
         help='file for input catalogue')
parser.add_argument('--e1name', dest="e1name", type=str,default='e1',
         help='Name of the e1 component in the catalogue')
parser.add_argument('--e2name', dest="e2name", type=str,default='e2',
         help='Name of the e2 component in the catalogue')
parser.add_argument('--wname', dest="wname", type=str,default='weight',
         help='Name of the weight in the catalogue')
parser.add_argument('--area', dest="area", type=float,required=True,
         help='Area of the survey in square arcmin')

args = parser.parse_args()
try:
  catalogue=pyfits.open(args.input)[1].data
  e1=catalogue.field(args.e1name)
  e2=catalogue.field(args.e2name)
  weight=catalogue.field(args.wname)
except Exception:
  ldac_cat = ldac.LDACCat(args.input)
  catalogue = ldac_cat['OBJECTS']
  e1=catalogue[args.e1name]
  e2=catalogue[args.e2name]
  weight=catalogue[args.weightname]

area=args.area

# NOTE: currently the m-bias is not used in the calculation
##m-bias values per tomographic bin
#mbias="@MBIASVALUES@"
#mbias_p1=[float(s) + 1.0 for s in mbias.split()]
##estimate of m-bias for full sample
#mbias_p1.append(sum(mbias_p1)/len(mbias_p1))
mbias_p1 = 1.0 

print("# n_obj n_eff[1/arcmin^2] sigma_e1 sigma_e2 sigma_e1_wsq sigma_e2_wsq sigma_e")

number = len(e1)

weight_sq = weight**2
weight_sum = weight.sum()

n_eff = (
  np.sum( weight * mbias_p1    )**2 /
  np.sum((weight * mbias_p1)**2) /
  area)

mean_e1 = np.average(e1, weights=weight)
mean_e2 = np.average(e2, weights=weight)

sigma_e1 = np.sqrt((  # standard error of the mean
    np.sum(weight * e1**2   ) /
    np.sum(weight * mbias_p1) -
    mean_e1**2
  ) / weight_sum)

sigma_e2 = np.sqrt((  # standard error of the mean
    np.sum(weight * e2**2   ) /
    np.sum(weight * mbias_p1) -
    mean_e2**2
  ) / weight_sum)

mean_e1_wsq = np.average(e1, weights=weight**2)
mean_e2_wsq = np.average(e2, weights=weight**2)
sigma_e1_wsq = np.sqrt((  # standard error of the mean with weights squared
    np.sum((weight * e1      )**2) /
    np.sum((weight * mbias_p1)**2) -
    mean_e1_wsq**2
  ) / weight_sum)
sigma_e2_wsq = np.sqrt((  # standard error of the mean with weights squared
    np.sum((weight * e2      )**2) /
    np.sum((weight * mbias_p1)**2) -
    mean_e2_wsq**2
  ) / weight_sum)

sigma_e = (  # geometric mean
  np.sqrt(  # standard deviation of e1 (assuming mean is zero)
    np.sum((weight * e1      )**2) /
    np.sum((weight * mbias_p1)**2)
  ) / 2.0 +
  np.sqrt(  # standard deviation of e2 (assuming mean is zero)
    np.sum((weight * e2      )**2) /
    np.sum((weight * mbias_p1)**2)
  ) / 2.0)

print(number, n_eff, sigma_e1, sigma_e2, sigma_e1_wsq, sigma_e2_wsq, sigma_e)

