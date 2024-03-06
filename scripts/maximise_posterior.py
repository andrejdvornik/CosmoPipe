from argparse import ArgumentParser
import numpy as np
import pandas as pd
import scipy.optimize
from mcmc_tools import load_chain_simple
from cosmosis.runtime.pipeline import LikelihoodPipeline
from cosmosis.runtime.config import Inifile
from astropy.io import fits
from scipy.interpolate import interp1d

parser = ArgumentParser(description='Maximise posterior using start values inferred from a previous chain')
parser.add_argument("--inputchain", dest="inputchain",
    help="Input chain ",required=False, type=str)
parser.add_argument("--outputdir", dest="outputdir",
    help="Output directory",required=True, type=str)
parser.add_argument("--inifile", dest="inifile",
    help="Cosmosis ini file",required=True, type=str)
parser.add_argument("--tolerance", dest="tolerance", default = 1e-3, type=float,
    help="Tolerance parameter",required=False)
parser.add_argument("--maxiter", dest="maxiter",default = 10000, type=int,
    help="Maximum number of iterations",required=False)
parser.add_argument("--data_file_iterative", dest="data_file_iterative",
    help="Fits file containing iterative covariance matrix",required=False, type=str)
parser.add_argument("--iteration", dest="iteration",
    help="Number of covariance iteration",required=False, type=int)
parser.add_argument("--mock", dest="mock",
    help="Number of mock file",required=False, type=int)
parser.add_argument("--data_file_mock", dest="data_file_mock",
    help="Mock data fits file",required=False, type=str)
parser.add_argument("--nzfile", dest="nzfile",
    help="N(z) file",required=False, type=str)
parser.add_argument("--nzcovariance", dest="nzcovariance",
    help="N(z) bias covariance file",required=False, type=str)
parser.add_argument("--nzoutput", dest="nzoutput",
    help="Output directory for biased n(z)",required=False, type=str)
parser.add_argument("--chainsuffix", dest="chainsuffix",
    help="Chainsuffix",required=False, default='', type=str)

args = parser.parse_args()
inputchain = args.inputchain
outputdir = args.outputdir
inifile = args.inifile
tolerance = args.tolerance
maxiter = args.maxiter
data_file_iterative = args.data_file_iterative
iteration = args.iteration
mock = args.mock
data_file_mock = args.data_file_mock
nzcovariance = args.nzcovariance
nzfile = args.nzfile
nzoutput = args.nzoutput
chainsuffix=args.chainsuffix


# Set up cosmosis pipeline
ini = Inifile(inifile) 
if data_file_iterative:
    ini.set('DEFAULT', 'data_file', data_file_iterative)
if data_file_mock:
    ini.set('DEFAULT', 'data_file', data_file_mock)
pipeline = LikelihoodPipeline(ini)
# Get varied parameters
varied_parameters = pipeline.varied_params
varied_params = ['%s--%s'%(p.section, p.name) for p in varied_parameters]
bounds = [(0.0, 1.0) for p in varied_params]

if inputchain:
    chain = load_chain_simple(inputchain)
    # Check if chain is 1cosmo or 2cosmo
    print('Starting optimisation from best-fit of input chain in'+inputchain)
    # Find maximum posterior
    maxpost = np.argmax(chain['post'])
    start_values = chain[varied_params].loc[maxpost].to_numpy()
    print(start_values, flush=True)
else:
    print('Starting optimisation from values file')
    start_values = pipeline.start_vector()

start_values_normalised = pipeline.normalize_vector(start_values)

def minus_log_posterior(values):
    if np.any(values > 1) or np.any(values < 0):
        return(np.inf)
    else:
        params = pipeline.denormalize_vector(values)
        r = pipeline.run_results(params)
        log_post = r.post
        log_like = r.like
        chain.append(np.concatenate((params,[log_post, log_like])))
        return(-log_post)

start = pipeline.run_results(start_values)
chain = [np.concatenate((start_values,[start.post, start.like]))]

def save(values_normalised):
    values = pipeline.denormalize_vector(values_normalised)
    current_step = pipeline.run_results(values)
    chain.append(np.concatenate((values,[current_step.post, current_step.like])))

opt = scipy.optimize.minimize(minus_log_posterior, start_values_normalised, method='Nelder-Mead', jac=False, tol=tolerance,  bounds=bounds,  options={'maxiter':maxiter, 'disp':True, 'adaptive':True})
#, callback=save
res_normalised = opt.x
res = pipeline.denormalize_vector(res_normalised)
r = pipeline.run_results(res)
log_post = r.post
log_like = r.like
chain = np.array(chain)
chain_columns = np.concatenate((varied_params, ['post', 'like']))
df = pd.DataFrame(chain, columns=chain_columns)
chain_columns[0] = '# '+chain_columns[0]

df_values = pd.DataFrame(res, index=varied_params)

# Infer nzbias column names 
columns_bias = [item.startswith('nofz_shifts') for item in varied_params]
nzcovariance = np.loadtxt(nzcovariance)
cholesky = np.linalg.cholesky(nzcovariance)
nzshift = cholesky @ np.array(res[columns_bias])
print(nzshift)
with fits.open(nzfile) as f:
    z = f['NZ_source'].data['Z_MID']
    for i in range(len(nzshift)):
        nz = f['NZ_source'].data['BIN%d'%(i+1)]
        f_int = interp1d(z, nz, kind='cubic', fill_value=0.0, bounds_error=False)
        nz_biased = f_int(z - nzshift[i])
        nz_biased /= np.trapz(nz_biased, z)
        f['NZ_source'].data['BIN%d'%(i+1)] = nz_biased
    if data_file_iterative:
        f.writeto(nzoutput+'/nz%s_iteration_%d.fits'%(chainsuffix,iteration), overwrite=True)
    else:
        f.writeto(nzoutput+'/nz%s_iteration_0.fits'%chainsuffix, overwrite=True)

if data_file_iterative:
    df.to_csv(outputdir+'bestfit%s_chain_iteration_%d.txt'%(chainsuffix,iteration), index=False, sep = '\t', header=chain_columns)
    # np.savetxt(outputdir+'bestfit%s_values_iteration_%d.txt'%(chainsuffix,iteration), res)
    df_values.to_csv(outputdir+'bestfit%s_values_iteration_%d.txt'%(chainsuffix,iteration), header=False, sep = '\t')
    np.savetxt(outputdir+'bestfit%s_chi2_post_iteration_%d.txt'%(chainsuffix,iteration), np.array([-2*log_like,-2*log_post]))
elif data_file_mock:
    np.savetxt(outputdir+'mock/bestfit%s_chi2_post_mock_%d.txt'%(chainsuffix,mock), np.array([-2*log_like,-2*log_post]))
else:
    df.to_csv(outputdir+'bestfit%s_chain_iteration_0.txt'%chainsuffix, index=False, sep = '\t', header=chain_columns)
    # np.savetxt(outputdir+'bestfit%s_values_iteration_0.txt'%chainsuffix, res)
    df_values.to_csv(outputdir+'bestfit%s_values_iteration_0.txt'%chainsuffix, header=False, sep = '\t')
    np.savetxt(outputdir+'bestfit%s_chi2_post_iteration_0.txt'%chainsuffix, np.array([-2*log_like,-2*log_post]))
