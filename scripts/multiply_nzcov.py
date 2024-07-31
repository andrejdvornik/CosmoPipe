from argparse import ArgumentParser
import numpy as np

parser = ArgumentParser(description='Multiply the dz covariance matrix by an arbitrary factor')
parser.add_argument("--file", dest="file",
    help="Input covariance matrix", metavar="file",required=True)
parser.add_argument("--factor", dest="factor",
    help="Multiplication factor", metavar="factor", type=float,required=True)

args = parser.parse_args()
cov = np.loadtxt(args.file)
cov *= args.factor
np.savetxt(args.file, cov)






