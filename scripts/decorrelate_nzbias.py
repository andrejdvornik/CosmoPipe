import numpy as np
from argparse import ArgumentParser

parser = ArgumentParser(description='Construct the Nz file needed by cosmosis')
parser.add_argument('--zbias', dest='dz_file', type=str, required=True, help="deltaz values file")
parser.add_argument('--zcov', dest='dzcov_file', type=str, required=True, help="deltaz covariance file")
parser.add_argument('--output', dest='output', type=str, required=True, help="output file")

args = parser.parse_args()

file=open(args.dz_file)
delta_z=np.loadtxt(file,comments='#')


file=open(args.dzcov_file)
cov_z=np.loadtxt(file,comments='#')

L = np.linalg.cholesky(cov_z) 
inv_L = np.linalg.inv(L)
delta_x = np.dot(inv_L,delta_z)

np.savetxt(args.output,delta_x)
