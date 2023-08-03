# -*- coding: utf-8 -*-
"""
Process behvavioral data for EmCon

Author: Eric Fields
Version Date: 3 August 2023
"""

import os
from os.path import join

import numpy as np
from scipy.stats import norm
import pandas as pd


def SDT(hits, misses, fas, crs):
    """ 
    Returns a dict with signal detection measures given hits, misses, 
    false alarms, and correct rejections
    
    adapted from:
    Jonas Kristoffer Lindeløv
    https://lindeloev.net/calculating-d-in-python-and-php/
    
    Reference for formulas:
    Stanislaw, H., & Todorov, N. (1999). Calculation of signal detection theory 
    measures. Behavior Research Methods, Instruments, & Computers, 31(1), 137-149.
    
    Calculations checked against: 
    https://www.computerpsych.com/Research_Software/NormDist/Online/Detection_Theory
    """
    
    # Floors and ceilings are replaced by half hits and half FA's
    half_hit = 0.5 / (hits + misses)
    half_fa = 0.5 / (fas + crs)
 
    # Calculate hit_rate and avoid d' infinity
    hit_rate = hits / (hits + misses)
    if hit_rate == 1:
        print('WARNING: Hit rate = 1 and was replaced with 1 - 0.5/n')
        hit_rate = 1 - half_hit
    if hit_rate == 0:
        print('WARNING: Hit rate = 0 and was replaced with 0.5/n')
        hit_rate = half_hit
 
    # Calculate false alarm rate and avoid d' infinity
    fa_rate = fas / (fas + crs)
    if fa_rate == 1:
        print('WARNING: FA rate = 1 and was replaced with 1 - 0.5/n')
        fa_rate = 1 - half_fa
    if fa_rate == 0:
        print('WARNING: FA rate = 0 and was replaced with 0.5/n')
        fa_rate = half_fa
        
    #Calculate d', beta, c and Ad'
    out = {}
    out['d']    = norm.ppf(hit_rate) - norm.ppf(fa_rate) #d'
    out['Ad']   = norm.cdf(out['d'] / np.sqrt(2)) #AUC estimated from d'
    out['beta'] = np.exp((norm.ppf(fa_rate)**2 - norm.ppf(hit_rate)**2) / 2) #β
    out['c']    = -(norm.ppf(hit_rate) + norm.ppf(fa_rate)) / 2 #criterion
    
    #Calculate non-parametric measures
    out['A'] = (0.5 + np.sign(hit_rate - fa_rate) *
                ( ((hit_rate - fa_rate)**2 + np.abs(hit_rate - fa_rate)) /
                  (4 * max((hit_rate, fa_rate)) - 4 * hit_rate * fa_rate))) #A' (non-parametric AUC)

    out['B'] = (np.sign(hit_rate - fa_rate) *
                ( (hit_rate*(1-hit_rate) - fa_rate*(1-fa_rate)) /
                  (hit_rate*(1-hit_rate) + fa_rate*(1-fa_rate)))) #B'' (non-parametric bias)
    
    return out


#%% SET-UP

main_dir = r'C:\Users\fieldsec\OneDrive - Westminster College\Documents\ECF\Research\EmCon\DATA'
sub_id = 'P1_EmCon'

behav_dir = join(main_dir, 'behav_data')


#%% IMPORT RETRIEVAL DATA

#Find retrieval file
ret_file = [file for file in os.listdir(behav_dir) if 
            file.startswith('%s_EmCon_ret' % sub_id) and
            file.endswith('.csv')]
assert len(ret_file) == 1
ret_file = ret_file[0]

#Import retrieval data
ret_data = pd.read_csv(join(behav_dir, ret_file))
#Remove dots in column names
ret_data.columns = [x.replace('.', '_') for x in ret_data.columns]


#%% MEMORY ANALYSES

#Initialize data frame
mem_data = pd.DataFrame()

for val_cond in ['NEU', 'NEG', 'animal']:
    
    #Just the trials in the current condition
    cond_idx = ret_data['condition'] == val_cond
    
    #Calculate hits, misses, false alarms, and correct rejections
    hits = sum((ret_data.loc[cond_idx, 'mem_cond'] == 'Old') &
               (ret_data.loc[cond_idx, 'oldnew_resp_keys'] == 5))
    misses = sum((ret_data.loc[cond_idx, 'mem_cond'] == 'Old') &
                 (ret_data.loc[cond_idx, 'oldnew_resp_keys'] == 4))
    FA = sum((ret_data.loc[cond_idx, 'mem_cond'] == 'New') &
             (ret_data.loc[cond_idx, 'oldnew_resp_keys'] == 5))
    CR = sum((ret_data.loc[cond_idx, 'mem_cond'] == 'New') &
             (ret_data.loc[cond_idx, 'oldnew_resp_keys'] == 4))
    K_hits = sum((ret_data.loc[cond_idx, 'mem_cond'] == 'Old')&
                (ret_data.loc[cond_idx, 'rk_resp_keys'] == '4'))
    R_hits = sum((ret_data.loc[cond_idx, 'mem_cond'] == 'Old')&
                (ret_data.loc[cond_idx, 'rk_resp_keys'] == '5'))
    assert hits == K_hits + R_hits
    K_FA = sum((ret_data.loc[cond_idx, 'mem_cond'] == 'New')&
               (ret_data.loc[cond_idx, 'rk_resp_keys'] == '4'))
    R_FA = sum((ret_data.loc[cond_idx, 'mem_cond'] == 'New')&
               (ret_data.loc[cond_idx, 'rk_resp_keys'] == '5'))
    assert FA == K_FA + R_FA
    
    #Trial numbers
    mem_data.at[sub_id, val_cond+'_Old_N'] = hits + misses
    mem_data.at[sub_id, val_cond+'_New_N'] = FA + CR
    
    #Memory rates
    mem_data.at[sub_id, val_cond+'_HitRate'] = hits / (hits + misses)
    mem_data.at[sub_id, val_cond+'_FARate'] = FA / (FA + CR)
    
    #Signal detection measures
    SD_meas = SDT(hits, misses, FA, CR)
    mem_data.at[sub_id, val_cond+'_dprime'] = SD_meas['d']
    mem_data.at[sub_id, val_cond+'_Ad'] = SD_meas['Ad']
    mem_data.at[sub_id, val_cond+'_criterion'] = SD_meas['c']
    mem_data.at[sub_id, val_cond+'_A'] = SD_meas['A']
    mem_data.at[sub_id, val_cond+'_B'] = SD_meas['B']
    
    #RK measures
    mem_data.at[sub_id, val_cond+'_K_HitRate'] = K_hits / (hits + misses)
    mem_data.at[sub_id, val_cond+'_R_HitRate'] = R_hits / (hits + misses)
    mem_data.at[sub_id, val_cond+'_K_FARate'] = K_FA / (FA + CR)
    mem_data.at[sub_id, val_cond+'_R_FARate'] = R_FA / (FA + CR)
