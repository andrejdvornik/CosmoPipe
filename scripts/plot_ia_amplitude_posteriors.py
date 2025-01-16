"""
plots IA amplitude as a function of z from chains
"""

from matplotlib import pyplot as plt
import numpy as np
from argparse import ArgumentParser
from mcmc_tools import load_chain
from statsmodels.stats.weightstats import DescrStatsW

# What could possibly go wrong?
import warnings
warnings.simplefilter(action='ignore', category=FutureWarning)

parser = ArgumentParser(description='Plot IA amplitude')
parser.add_argument("--inputbase", dest="inputbase",
    help="Input files", required=True)
parser.add_argument("--output_dir", dest="output_dir",
    help="Output directory", metavar="output",required=True)
parser.add_argument("--f_r", dest="f_r", type=float, nargs='+',
    help="Fraction of red galaxies per tomographic bin", metavar="f_r",required=True)
parser.add_argument("--logM", dest="logM", type=float, nargs='+',
    help="log halo mass per tomographic bin", metavar="logM",required=True)
parser.add_argument("--logM_pivot", dest="logM_pivot", type=float,
    help="log pivot mass", metavar="logM_pivot",required=True)
parser.add_argument("--a_pivot_zdep", dest="a_pivot_zdep", type=float,
    help="pivot scale factor for redshift dependent IA model", metavar="a_pivot_zdep",required=True)
parser.add_argument("--weighted",choices=["False", "True"],required=True)

### settings
args = parser.parse_args()
chainbase = args.inputbase
output_path = args.output_dir
if args.weighted == 'True':
    weighted = True
else:
    weighted = False
# hardcode for now, check later
tomo_z = np.array([0.341,0.479,0.587,0.789,0.938,1.230])
tomo_fr = args.f_r
log_m = args.logM
quantile_levels = [0.1587, 0.5, 0.8414]
zmin = 0.0
zmax = 1.7
a_pivot_zdep = args.a_pivot_zdep
z_pivot = 1/a_pivot_zdep - 1
logm_pivot = args.logM_pivot
plot_steps = 1000


### code

# preliminaries
#plt.rc('text', usetex=True) # enable TEX
plt.rcParams.update({'font.size': 20})  # general font size
plt.rcParams.update({'legend.loc': 'upper left'})  # position of legend
plt.rcParams.update({'xtick.top': True })  # add ticks to top of panels
plt.rcParams.update({'xtick.labeltop' : False })  # but don't plot labels again

z = np.linspace(zmin,zmax,plot_steps)

ntomo = len(tomo_z)


# read & process chains
try:
    NLA_chain = load_chain(chainbase+'_linear.txt')
    ia_const = NLA_chain[0]['intrinsic_alignment_parameters--a'].to_numpy()
    if weighted == False:
        ia_const_quantiles = np.quantile(ia_const, quantile_levels)
    else:
        ia_const_weights = NLA_chain[0]['weight'].to_numpy()
        data = DescrStatsW(data=ia_const, weights=ia_const_weights)
        ia_const_quantiles = data.quantile(probs=quantile_levels, return_pandas=False)
except:
    print('NLA chain not found!')

try:
    scaledep_chain = load_chain(chainbase+'_tatt.txt')
    ia_scaledep = scaledep_chain[0]['intrinsic_alignment_parameters--a1'].to_numpy()
    if weighted == False:
        ia_scaledep_quantiles = np.quantile(ia_scaledep, quantile_levels)
    else:
        ia_scaledep_weights = scaledep_chain[0]['weight'].to_numpy()
        data = DescrStatsW(data=ia_scaledep, weights=ia_scaledep_weights)
        ia_scaledep_quantiles = data.quantile(probs=quantile_levels, return_pandas=False)
except:
    print('Scaledep chain not found!')

try:
    zdep_chain = load_chain(chainbase+'_linear_z.txt')
    ia_zdep = zdep_chain[0][['intrinsic_alignment_parameters--a_ia','intrinsic_alignment_parameters--b_ia']].to_numpy().T
    ia_zdep_quantiles = np.zeros( (3,plot_steps) )
    for i in range(plot_steps):
        ia_amp = ia_zdep[0] + ia_zdep[1] * ( (1.+z_pivot)/(1.+z[i]) - 1.)  # zdep model
        if weighted == False:
            ia_zdep_quantiles[:,i] = np.quantile(ia_amp, quantile_levels)
        else:
            ia_zdep_weights = zdep_chain[0]['weight'].to_numpy()
            data = DescrStatsW(data=ia_amp, weights=ia_zdep_weights)
            ia_zdep_quantiles[:,i] = data.quantile(probs=quantile_levels, return_pandas=False)
except:
    print('zdep chain not found')

try:
    massdep_chain = load_chain(chainbase+'_massdep.txt')
    ia_massdep = massdep_chain[0][['INTRINSIC_ALIGNMENT_PARAMETERS--A','INTRINSIC_ALIGNMENT_PARAMETERS--BETA','intrinsic_alignment_parameters--log10_m_mean_1','intrinsic_alignment_parameters--log10_m_mean_2','intrinsic_alignment_parameters--log10_m_mean_3','intrinsic_alignment_parameters--log10_m_mean_4','intrinsic_alignment_parameters--log10_m_mean_5','intrinsic_alignment_parameters--log10_m_mean_6']].to_numpy().T
    ia_massdep_quantiles = np.zeros( (3,ntomo) )
    ia_massdep_massfixed_quantiles = np.zeros( (3,ntomo) )
    for i in range(ntomo):
        ia_amp = ia_massdep[0] * tomo_fr[i] * np.power( 10., ia_massdep[1]* ( ia_massdep[2+i] - logm_pivot ) )  # massdep model
        if weighted == False:
            ia_massdep_quantiles[:,i] = np.quantile(ia_amp,quantile_levels)
        else:
            ia_massdep_weights = massdep_chain[0]['weight'].to_numpy()
            data = DescrStatsW(data=ia_amp, weights=ia_massdep_weights)
            ia_massdep_quantiles[:,i] = data.quantile(probs=quantile_levels, return_pandas=False)
        ia_amp = ia_massdep[0] * tomo_fr[i] * np.power( 10., ia_massdep[1]* ( log_m[i] - logm_pivot ) )  # massdep model, fixing halo masses
        if weighted == False:
            ia_massdep_massfixed_quantiles[:,i] = np.quantile(ia_amp, quantile_levels)
        else:
            ia_massdep_weights = massdep_chain[0]['weight'].to_numpy()
            data = DescrStatsW(data=ia_amp, weights=ia_massdep_weights)
            ia_massdep_massfixed_quantiles[:,i] = data.quantile(probs=quantile_levels, return_pandas=False)

except:
    print('Massdep chain not found')


# create plot
try:
    plt.plot(z, np.ones(plot_steps) * ia_const_quantiles[1], color="black", label="constant amplitude")
    plt.fill_between(z, np.ones(plot_steps) * ia_const_quantiles[0], np.ones(plot_steps) * ia_const_quantiles[2], color="black", alpha=0.5, label="")
except:
    pass

try:
    plt.plot(z, np.ones(plot_steps) * ia_scaledep_quantiles[1], color=u'#1f77b4', label="mod. scale dependence")
    plt.fill_between(z, np.ones(plot_steps) * ia_scaledep_quantiles[0], np.ones(plot_steps) * ia_scaledep_quantiles[2], color=u'#1f77b4', alpha=0.5, label="")
except:
    pass

try:
    plt.plot(z, ia_zdep_quantiles[1], color=u'#2ca02c', label="redshift dependence")
    plt.fill_between(z, ia_zdep_quantiles[0], ia_zdep_quantiles[2], color=u'#2ca02c', alpha=0.5, label="")
except:
    pass

try:
    #plt.errorbar(tomo_z, ia_massdep_massfixed_quantiles[1], yerr=[ia_massdep_massfixed_quantiles[1]-ia_massdep_massfixed_quantiles[0],ia_massdep_massfixed_quantiles[2]-ia_massdep_massfixed_quantiles[1]], capsize=3, fmt='--', color="orange", label="mass dependence, halo masses fixed")
    plt.errorbar(tomo_z, ia_massdep_quantiles[1], yerr=[ia_massdep_quantiles[1]-ia_massdep_quantiles[0],ia_massdep_quantiles[2]-ia_massdep_quantiles[1]], capsize=3, fmt='.', color="red", label="mass dependence")
except:
    pass


plt.xlim([zmin,zmax])
plt.xlabel("$z$")
plt.ylabel("$A_{\\rm IA, total}$")
plt.legend(loc='lower right',fontsize=14)

plt.savefig(output_path + "/plot_ia_amplitude_posteriors.png",bbox_inches='tight',dpi=300)


quit()


