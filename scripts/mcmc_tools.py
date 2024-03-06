import numpy as np
import pandas as pd
import h5py
from scipy.special import logsumexp

# Convert parameter names to cosmosis parameter name
cosmosis_names={
    'omega_c':'cosmological_parameters--omch2',
    'omega_b':'cosmological_parameters--ombh2',
    'omega_m':'COSMOLOGICAL_PARAMETERS--OMEGA_M',
    'h':'cosmological_parameters--h0',
    'w0':'cosmological_parameters--w',
    'wa':'cosmological_parameters--wa',
    'n_s':'cosmological_parameters--n_s',
    'S8_input':'cosmological_parameters--s_8_input',
    'S8':'COSMOLOGICAL_PARAMETERS--S_8',
    'sigma_8':'COSMOLOGICAL_PARAMETERS--SIGMA_8',
    'sigma_8_input':'COSMOLOGICAL_PARAMETERS--SIGMA_8_INPUT',
    'A_S':'COSMOLOGICAL_PARAMETERS--A_S',
    'Omega_m':'Omega_m',
    'Omega_nu':'COSMOLOGICAL_PARAMETERS--OMEGA_NU',
    'Omega_Lambda':'COSMOLOGICAL_PARAMETERS--OMEGA_LAMBDA',
    'Theta_MC':'COSMOLOGICAL_PARAMETERS--COSMOMC_THETA',
    'A_bary':'halo_model_parameters--a',
    'A_IA':'intrinsic_alignment_parameters--a',
    'A_IA_linz':'intrinsic_alignment_parameters--a_ia',
    'B_IA_linz':'intrinsic_alignment_parameters--b_ia',
    'AIA':'intrinsic_alignment_parameters--a',
    'beta':'intrinsic_alignment_parameters--beta',
    'A_IA_derived':'INTRINSIC_ALIGNMENT_PARAMETERS--A',
    'beta_derived':'INTRINSIC_ALIGNMENT_PARAMETERS--BETA',
    'uncorr_AIA':'intrinsic_alignment_parameters--uncorr_a',
    'uncorr_beta':'intrinsic_alignment_parameters--uncorr_beta',
    'M1':'intrinsic_alignment_parameters--log10_m_mean_1',
    'M2':'intrinsic_alignment_parameters--log10_m_mean_2',
    'M3':'intrinsic_alignment_parameters--log10_m_mean_3',
    'M4':'intrinsic_alignment_parameters--log10_m_mean_4',
    'M5':'intrinsic_alignment_parameters--log10_m_mean_5',
    'M6':'intrinsic_alignment_parameters--log10_m_mean_6',
    'A1':'intrinsic_alignment_parameters--a1',
    'A2':'intrinsic_alignment_parameters--a2',
    'alpha1':'intrinsic_alignment_parameters--alpha1',
    'alpha2':'intrinsic_alignment_parameters--alpha2',
    'b_ta':'intrinsic_alignment_parameters--bias_ta',
    'log_T_AGN':'halo_model_parameters--log_t_agn',
    'logT_AGN':'halo_model_parameters--logt_agn',
    'A_bary_shared':'halo_model_parameters_shared--a',
    'A_IA_shared':'intrinsic_alignment_parameters_shared--a',
    'AIA_shared':'intrinsic_alignment_parameters_shared--a',
    'log_T_AGN_shared':'halo_model_parameters_shared--log_t_agn',
    'deltaz_uncorr_1':'nofz_shifts--uncorr_bias_1',
    'deltaz_uncorr_2':'nofz_shifts--uncorr_bias_2',
    'deltaz_uncorr_3':'nofz_shifts--uncorr_bias_3',
    'deltaz_uncorr_4':'nofz_shifts--uncorr_bias_4',
    'deltaz_uncorr_5':'nofz_shifts--uncorr_bias_5',
    'deltaz_uncorr_6':'nofz_shifts--uncorr_bias_6',
    'deltaz_uncorr_7':'nofz_shifts--uncorr_bias_7',
    'deltaz_uncorr_8':'nofz_shifts--uncorr_bias_8',
    'deltaz_uncorr_9':'nofz_shifts--uncorr_bias_9',
    'deltaz_uncorr_10':'nofz_shifts--uncorr_bias_10',
    'deltaz_uncorr_11':'nofz_shifts--uncorr_bias_11',
    'deltaz_uncorr_12':'nofz_shifts--uncorr_bias_12',
    'deltaz_1':'NOFZ_SHIFTS--BIAS_1',
    'deltaz_2':'NOFZ_SHIFTS--BIAS_2',
    'deltaz_3':'NOFZ_SHIFTS--BIAS_3',
    'deltaz_4':'NOFZ_SHIFTS--BIAS_4',
    'deltaz_5':'NOFZ_SHIFTS--BIAS_5',
    'deltaz_6':'NOFZ_SHIFTS--BIAS_6',
    'deltaz_7':'NOFZ_SHIFTS--BIAS_7',
    'deltaz_8':'NOFZ_SHIFTS--BIAS_8',
    'deltaz_9':'NOFZ_SHIFTS--BIAS_9',
    'deltaz_10':'NOFZ_SHIFTS--BIAS_10',
    'deltaz_11':'NOFZ_SHIFTS--BIAS_11',
    'deltaz_12':'NOFZ_SHIFTS--BIAS_12',
    'deltaz_out_1':'DELTA_Z_OUT--BIN_1',
    'deltaz_out_2':'DELTA_Z_OUT--BIN_2',
    'deltaz_out_3':'DELTA_Z_OUT--BIN_3',
    'deltaz_out_4':'DELTA_Z_OUT--BIN_4',
    'deltaz_out_5':'DELTA_Z_OUT--BIN_5',
    'deltaz_out_6':'DELTA_Z_OUT--BIN_6',
    'deltaz_out_7':'DELTA_Z_OUT--BIN_7',
    'deltaz_out_8':'DELTA_Z_OUT--BIN_8',
    'deltaz_out_9':'DELTA_Z_OUT--BIN_9',
    'deltaz_out_10':'DELTA_Z_OUT--BIN_10',
    'deltaz_out_11':'DELTA_Z_OUT--BIN_11',
    'deltaz_out_12':'DELTA_Z_OUT--BIN_12',
    'prior':'prior',
    'like':'like',
    'post':'post',
    'weight':'weight',
    'log_weight':'log_weight'
}

cosmosis_names_inv = {v: k for k, v in cosmosis_names.items()}

# Convert parameter names to latex format 
latex_names={
    'omega_c':r'$\omega_{\rm cdm}$', 
    'omega_b':r'$\omega_{\rm b}$', 
    'omega_m':r'$\Omega_{\rm m}$', 
    'h':r'$h$', 
    'w0':r'$w_0$',
    'wa':r'$w_{\rm a}$',
    'n_s':r'$n_{\rm s}$', 
    'S8_input':r'$S_{\rm 8}$', 
    'S8':r'$S_8$', 
    'sigma_8':r'$\sigma_8$',
    'sigma_8_input':r'$\sigma_{\rm 8, input}$',
    'A_S':r'$A_{\rm s}$',
    'Omega_m':r'$\Omega_{\rm m}$',
    'Omega_nu':r'$\Omega_\nu$',
    'Omega_Lambda':r'$\Omega_\Lambda$',
    'Theta_MC':r'$\Theta_{\rm MC}$',
    'A_bary':r'$A_{\rm bary}$', 
    'A_IA':r'$A_{\rm IA}$',
    'A_IA_linz':r'$A_{\rm IA}$',
    'B_IA_linz':r'$B_{\rm IA}$',
    'AIA':r'$A_{\rm IA}$',
    'beta':r'$\beta$',
    'A_IA_derived':r'$A_{\rm IA}$',
    'beta_derived':r'$\beta$',
    'uncorr_AIA':r'$A_{\rm IA}$',
    'uncorr_beta':r'$\beta$',
    'M1':r'$\log_{10}M_1$',
    'M2':r'$\log_{10}M_2$',
    'M3':r'$\log_{10}M_3$',
    'M4':r'$\log_{10}M_4$',
    'M5':r'$\log_{10}M_5$',
    'M6':r'$\log_{10}M_6$',
    'A1':r'$A_1$',
    'A2':r'$A_2$',
    'alpha1':r'$\alpha_1$',
    'alpha2':r'$\alpha_2$',
    'b_ta':r'$b_{\rm TA}$',
    'log_T_AGN':r'$\log{T_{\rm AGN}}$',
    'logT_AGN':r'$\log{T_{\rm AGN}}$',
    'A_bary_shared':r'$A_{\rm bary}$', 
    'A_IA_shared':r'$A_{\rm IA}$',
    'AIA_shared':r'$A_{\rm IA}$',
    'log_T_AGN_shared':r'$\log{T_{\rm AGN}}$',
    'deltaz_1':r'$\delta_{\rm z, 1}$', 
    'deltaz_2':r'$\delta_{\rm z, 2}$', 
    'deltaz_3':r'$\delta_{\rm z, 3}$', 
    'deltaz_4':r'$\delta_{\rm z, 4}$', 
    'deltaz_5':r'$\delta_{\rm z, 5}$',
    'deltaz_6':r'$\delta_{\rm z, 6}$', 
    'deltaz_7':r'$\delta_{\rm z, 7}$', 
    'deltaz_8':r'$\delta_{\rm z, 8}$', 
    'deltaz_9':r'$\delta_{\rm z, 9}$', 
    'deltaz_10':r'$\delta_{\rm z, 10}$', 
    'deltaz_11':r'$\delta_{\rm z, 11}$',
    'deltaz_12':r'$\delta_{\rm z, 12}$',
    'deltaz_uncorr_1':r'$\delta_{\rm z, 1, uncorr}$', 
    'deltaz_uncorr_2':r'$\delta_{\rm z, 2, uncorr}$', 
    'deltaz_uncorr_3':r'$\delta_{\rm z, 3, uncorr}$', 
    'deltaz_uncorr_4':r'$\delta_{\rm z, 4, uncorr}$', 
    'deltaz_uncorr_5':r'$\delta_{\rm z, 5, uncorr}$',
    'deltaz_uncorr_6':r'$\delta_{\rm z, 6, uncorr}$',
    'deltaz_uncorr_7':r'$\delta_{\rm z, 7, uncorr}$', 
    'deltaz_uncorr_8':r'$\delta_{\rm z, 8, uncorr}$', 
    'deltaz_uncorr_9':r'$\delta_{\rm z, 9, uncorr}$', 
    'deltaz_uncorr_10':r'$\delta_{\rm z, 10, uncorr}$', 
    'deltaz_uncorr_11':r'$\delta_{\rm z, 11, uncorr}$',
    'deltaz_uncorr_12':r'$\delta_{\rm z, 12, uncorr}$',
    'deltaz_out_1':r'$\delta_{\rm z, 1, out}$', 
    'deltaz_out_2':r'$\delta_{\rm z, 2, out}$', 
    'deltaz_out_3':r'$\delta_{\rm z, 3, out}$', 
    'deltaz_out_4':r'$\delta_{\rm z, 4, out}$', 
    'deltaz_out_5':r'$\delta_{\rm z, 5, out}$',
    'deltaz_out_6':r'$\delta_{\rm z, 6, out}$',
    'deltaz_out_7':r'$\delta_{\rm z, 7, out}$', 
    'deltaz_out_8':r'$\delta_{\rm z, 8, out}$', 
    'deltaz_out_9':r'$\delta_{\rm z, 9, out}$', 
    'deltaz_out_10':r'$\delta_{\rm z, 10, out}$', 
    'deltaz_out_11':r'$\delta_{\rm z, 11, out}$',
    'deltaz_out_12':r'$\delta_{\rm z, 12, out}$',
    'prior':'prior', 
    'like':'like', 
    'post':'post', 
    'weight':'weight',
    'log_weight':'log_weight'
}

def BMD(like, weight):
    # From Handley et al. 2019, arXiv:1903.06682
    d = 2 * (np.sum((like**2) * weight) - np.sum(like * weight)**2)
    return(d)
def BMD_nautilus(logZ, logV_i, logL_i, D_KL):
    d = 2/np.exp(logZ) * np.sum(np.exp(logV_i)*np.exp(logL_i) * (logL_i - logZ - D_KL)**2)
    return(d)
def d_like(like, weight):
    # eq.45, Joachimi et al. 2021
    chisquare_min = np.min(-2*like)
    d = np.sum(-2*like * weight) - chisquare_min
    return(d)
def d_post(like, post, weight):
    # eq.46, Joachimi et al. 2021
    chisquare_maxpost = -2*like[np.argmax(post)]
    d = np.sum(-2*like * weight) - chisquare_maxpost
    return(d)
def KL_nautilus(logZ, logV_i, logL_i):
    D_KL = 1/np.exp(logZ) * np.sum(np.exp(logV_i)*np.exp(logL_i)*logL_i) - logZ
    return(D_KL)
def load_chain_simple(path):
    with open(path) as f:
        columns = f.readline().strip('\n')[1:].split()
    data = pd.read_table(path, names = columns, comment = '#')
    # For Nautilus: compute weight from log_weight
    if ('log_weight' in columns) and ('weight' not in columns):
        data['weight'] = np.exp(data['log_weight'])
    # Add likelihood column if it's not there (for example in Nautilus chains)
    if 'like' not in columns:
        data['like'] = data['post'] - data['prior']
    return(data)

def load_chain(path):
    data = load_chain_simple(path)
    # Check if the chains is 2cosmo 
    if 'cosmological_parameters_1' in str(data.columns):
        columns_set1 = [item for item in data.columns if (item.startswith('COSMOLOGICAL_PARAMETERS_1--')) or(item.startswith('cosmological_parameters_1')) or (item.startswith('halo_model_parameters_1')) or (item.startswith('intrinsic_alignment_parameters_1')) or (item.startswith('INTRINSIC_ALIGNMENT_PARAMETERS_1--'))]
        columns_set2 = [item for item in data.columns if (item.startswith('COSMOLOGICAL_PARAMETERS_2--')) or (item.startswith('cosmological_parameters_2')) or (item.startswith('halo_model_parameters_2')) or (item.startswith('intrinsic_alignment_parameters_2')) or (item.startswith('INTRINSIC_ALIGNMENT_PARAMETERS_2--'))]
        data_set1 = data[columns_set1]
        data_set2 = data[columns_set2]

        data_set1.columns = [i.replace('_1','') for i in data_set1.columns]
        data_set2.columns = [i.replace('_2','') for i in data_set2.columns]
        diff = data_set1 - data_set2
        columns_shared = [item for item in data.columns if (item.startswith('COSMOLOGICAL_PARAMETERS--')) or (item.startswith('cosmological_parameters--')) or (item.startswith('cosmological_parameters_shared--')) or (item.startswith('halo_model_parameters_shared--')) or (item.startswith('intrinsic_alignment_parameters_shared--')) or (item.startswith('NOFZ_SHIFTS')) or item in ['prior','like','post','weight', 'log_weight']]
        data_shared = data[columns_shared]

        columns_tpd_set1 = [item for item in data.columns if '_SET1' in item] 
        columns_tpd_set2 = [item for item in data.columns if '_SET2' in item]
        if (len(columns_tpd_set1)==len(columns_tpd_set2)) and (len(columns_tpd_set1)!=0):
            # Put TPDs in correct order: bin_1-bin_1...bin_1-bin_N, bin_2-bin_2...bin_2-bin_N,..., bin_N-bin_N
            correct_order=[]
            for i in range(1,10):
                for j in range(i,10):
                    correct_order.append('%s_%s'%(j,i))
            columns_tpd_set1_sorted = []
            columns_tpd_set2_sorted = []
            for i in range(len(correct_order)):
                for item in columns_tpd_set1:
                    if 'BIN_'+correct_order[i] in item:
                        columns_tpd_set1_sorted.append(item)
                for item in columns_tpd_set2:
                    if 'BIN_'+correct_order[i] in item:
                        columns_tpd_set2_sorted.append(item)
            # If xipm sort the column: xip...xim
            # This will probably crash when running with two different statistics?
            if 'XIP_SET1--BIN_1_1_0' in data.columns:
                columns_tpd_set1_sorted = [item for item in columns_tpd_set1_sorted if 'XIP_SET1' in item] + [item for item in columns_tpd_set1_sorted if 'XIM_SET1' in item]
                columns_tpd_set2_sorted = [item for item in columns_tpd_set2_sorted if 'XIP_SET2' in item] + [item for item in columns_tpd_set2_sorted if 'XIM_SET2' in item]
            tpd_set1 = data[columns_tpd_set1_sorted]
            tpd_set2 = data[columns_tpd_set2_sorted]
            return(data_set1, data_set2, diff, data_shared, tpd_set1, tpd_set2)
        else:
            return(data_set1, data_set2, diff, data_shared, None, None)
    else: #1cosmo chain NOFZ_SHIFTS--
        columns = [item for item in data.columns if (item.startswith('cosmological_parameters')) or (item.startswith('halo_model_parameters')) or (item.startswith('intrinsic_alignment_parameters')) or (item.startswith('INTRINSIC_ALIGNMENT_PARAMETERS')) or (item.startswith('COSMOLOGICAL_PARAMETERS')) or (item.startswith('NOFZ_SHIFTS--')) or (item.startswith('nofz_shifts--')) or (item in ['prior','like','post','weight', 'log_weight'])]
        data_array = data[columns]
        if ('cosmological_parameters--omch2' in data.columns) and ('cosmological_parameters--ombh2' in data.columns) and ('cosmological_parameters--h0' in data.columns):
            data_array = data_array.assign(Omega_m = (data['cosmological_parameters--omch2'] + data['cosmological_parameters--ombh2'])/(data['cosmological_parameters--h0']**2))
        columns_tpd = [item for item in data.columns if '--BIN' in item] 
        if (len(columns_tpd)!=0):
            tpd = data[columns_tpd]
            # Put TPDs in correct order: bin_1-bin_1...bin_1-bin_N, bin_2-bin_2...bin_2-bin_N,..., bin_N-bin_N
            correct_order=[]
            for i in range(1,10):
                for j in range(i,10):
                    correct_order.append('%s_%s'%(j,i))
            columns_tpd_sorted = []
            for i in range(len(correct_order)):
                for item in columns_tpd:
                    if 'BIN_'+correct_order[i] in item:
                        columns_tpd_sorted.append(item)
            # If xipm sort the column: xip...xim
            # This will probably crash when running with two different statistics?
            if 'SHEAR_XI_PLUS_BINNED--BIN_1_1_0' in data.columns:
                print('reordering')
                columns_tpd_sorted = [item for item in columns_tpd_sorted if 'SHEAR_XI_PLUS_BINNED' in item] + [item for item in columns_tpd_sorted if 'SHEAR_XI_MINUS_BINNED' in item]
            tpd = data[columns_tpd_sorted]
            return(data_array, tpd)
        else:
            return(data_array, None)
            
def analyse_nautilus(basename):
    chain = load_chain(basename+'.txt')
    # 1 cosmo chain
    if len(chain) == 2:
        data, tpd = chain
        two_cosmo = False
    elif len(chain) == 6:
        data_set1, data_set2, diff, data_shared, tpd_set1, tpd_set2 = chain
        two_cosmo = True
    else:
        raise Exception('Could not read chain!')
    # Nautilus evidence
    with h5py.File(basename+'.sampler_status.hdf5', 'r') as f:
        sampler = f['sampler']
        shell_log_l = sampler.attrs['shell_log_l']
        shell_log_v = sampler.attrs['shell_log_v']
        # Evidence per shell: eq(10) in arXiv:2306.16923
        # This should be equivalent to the evidence printed at the bottom of the output chain
        logZ = logsumexp(shell_log_v+shell_log_l)
    # Bayesian model dimensionality 
    if two_cosmo:
        d = BMD(data_shared['like'], data_shared['weight'])
        d_l = d_like(data_shared['like'], data_shared['weight'])
        d_p = d_post(data_shared['like'], data_shared['post'], data_shared['weight'])
    else:
        d = BMD(data['like'], data['weight'])
        d_l = d_like(data['like'], data['weight'])
        d_p = d_post(data['like'], data['post'], data['weight'])
    # KL divergence
    D_KL = KL_nautilus(logZ, shell_log_v, shell_log_l)
    # Bayesian model dimensionality from Nautilus output (should be consistent with estimate from chain)
    d_nautilus = BMD_nautilus(logZ, shell_log_v, shell_log_l, D_KL)

    return(logZ, d, d_l, d_p, d_nautilus, D_KL)