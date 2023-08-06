# -*- coding: utf-8 -*-
"""
Process behvavioral data for EmCon

Author: Eric Fields
Version Date: 5 August 2023
"""

import os
from os.path import join

import numpy as np
import scipy.stats as sps
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
    https://www.computerpsych.com/Research_Software/sps.normDist/Online/Detection_Theory
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
    out['d']    = sps.norm.ppf(hit_rate) - sps.norm.ppf(fa_rate) #d'
    out['Ad']   = sps.norm.cdf(out['d'] / np.sqrt(2)) #AUC estimated from d'
    out['beta'] = np.exp((sps.norm.ppf(fa_rate)**2 - sps.norm.ppf(hit_rate)**2) / 2) #β
    out['c']    = -(sps.norm.ppf(hit_rate) + sps.norm.ppf(fa_rate)) / 2 #criterion
    
    #Calculate non-parametric measures
    out['A'] = (0.5 + np.sign(hit_rate - fa_rate) *
                ( ((hit_rate - fa_rate)**2 + np.abs(hit_rate - fa_rate)) /
                  (4 * max((hit_rate, fa_rate)) - 4 * hit_rate * fa_rate))) #A' (non-parametric AUC)

    out['B'] = (np.sign(hit_rate - fa_rate) *
                ( (hit_rate*(1-hit_rate) - fa_rate*(1-fa_rate)) /
                  (hit_rate*(1-hit_rate) + fa_rate*(1-fa_rate)))) #B'' (non-parametric bias)
    
    return out


def process_sub_behav_data(sub_id, main_dir=None, behav_data=None):
    """
    Calculate accuracy and reaction time for the encoding task for sub_id 
    and add to dataframe in mem_data
    """
    
    if main_dir is None:
        main_dir = os.getcwd()
    
    behav_dir = join(main_dir, 'psychopy')
    
    ############## IMPORT ENCODING DATA ##############
    
    #Find encoding psychopy file
    enc_file = [file for file in os.listdir(behav_dir) if 
    			file.startswith('%s_EmCon_enc' % sub_id) and
    			file.endswith('.csv')]
    assert len(enc_file) == 1
    enc_file = enc_file[0]
    #Import retrieval data
    enc_data = pd.read_csv(join(behav_dir, enc_file))
    #Remove dots in column names
    enc_data.columns = [x.replace('.', '_') for x in enc_data.columns]
    
    ############## CALCULATE ACC AND RT ##############
    
    #Get just non-practice trial rows
    enc_data = enc_data[enc_data['block_loop_thisRepN'] == 1]

    #Adjust reaction time for delay in gamepad component starting
    gp_delay = enc_data['gamepad_resp_started'] - enc_data['resp_cue_text_started']
    enc_data['gamepad_resp_rt'] += gp_delay

    #Initalize data frame
    if behav_data is None:
        behav_data = pd.DataFrame()

    #Trial numbers
    for cond in ['NEU', 'NEG', 'animal']:
        behav_data.loc[sub_id, cond+'_N'] = enc_data.loc[enc_data['condition'] == cond,
                                                              'gamepad_resp_keys'].count()

    #Accuracy
    resp_hand = enc_data['animal_hand'].iloc[0]
    for cond in ['NEU', 'NEG', 'animal']:
        #Find the correct response
        if cond == 'animal':
            if resp_hand == 'R':
                corr_resp = 5
            elif resp_hand == 'L':
                corr_resp = 4
        else:
            if resp_hand == 'R':
                corr_resp = 4
            elif resp_hand == 'L':
                corr_resp = 5
        #Calculate accuracy
        behav_data.loc[sub_id, cond+'_acc'] = np.mean(enc_data.loc[enc_data['condition'] == cond,
                                                                   'gamepad_resp_keys'] == corr_resp)

    #Reaction time
    for cond in ['NEU', 'NEG', 'animal']:
        behav_data.loc[sub_id, cond+'_meanRT'] = enc_data.loc[enc_data['condition'] == cond, 
                                                              'gamepad_resp_rt'].mean()
    for cond in ['NEU', 'NEG', 'animal']:
        behav_data.loc[sub_id, cond+'_medianRT'] = enc_data.loc[enc_data['condition'] == cond, 
                                                                'gamepad_resp_rt'].median()
    for cond in ['NEU', 'NEG', 'animal']:
        behav_data.loc[sub_id, cond+'_tmeanRT'] = sps.trim_mean(enc_data.loc[enc_data['condition'] == cond, 
                                                                            'gamepad_resp_rt'], 0.2)
    
    return behav_data


def process_sub_mem_data(sub_id, mem_data=None, main_dir=None):
    """
    Calculate memory statistics for sub_id and add to dataframe in mem_data
    """
    
    if main_dir is None:
        main_dir = os.getcwd()
    
    behav_dir = join(main_dir, 'psychopy')
    
    ############## IMPORT MEMORY DATA ##############
    
    ##### Immediate retrieval #####
    #Find retrieval file
    ret1_file = [file for file in os.listdir(behav_dir) if 
                 file.startswith('%s_EmCon_ret1' % sub_id) and
                 file.endswith('.csv')]
    assert len(ret1_file) == 1
    ret1_file = ret1_file[0]
    #Import retrieval data
    ret1_data = pd.read_csv(join(behav_dir, ret1_file))
    #Remove dots in column names
    ret1_data.columns = [x.replace('.', '_') for x in ret1_data.columns]

    ##### Delayed retrieval #####
    #Find retrieval file
    ret2_file = [file for file in os.listdir(behav_dir) if 
                 file.startswith('%s_EmCon_ret2' % sub_id) and
                 file.endswith('.csv')]
    if ret2_file:
        assert len(ret2_file) == 1
        ret2_file = ret2_file[0]
        #Import retrieval data
        ret2_data = pd.read_csv(join(behav_dir, ret2_file))
        #Remove dots in column names
        ret2_data.columns = [x.replace('.', '_') for x in ret2_data.columns]
        
    
    ############## CALCULATE MEMORY STATS ##############
    
    #Initialize data frame
    if mem_data is None:
        mem_data = pd.DataFrame(columns= ['NEU_I_Old_N', 'NEU_I_New_N', 'NEG_I_Old_N', 'NEG_I_New_N', 'animal_I_Old_N', 'animal_I_New_N',
                                          'NEU_D_Old_N', 'NEU_D_New_N', 'NEG_D_Old_N', 'NEG_D_New_N', 'animal_D_Old_N', 'animal_D_New_N',
                                          'NEU_I_HitRate', 'NEG_I_HitRate', 'animal_I_HitRate',
                                          'NEU_D_HitRate', 'NEG_D_HitRate', 'animal_D_HitRate',
                                          'NEU_I_FARate', 'NEG_I_FARate', 'animal_I_FARate',
                                          'NEU_D_FARate', 'NEG_D_FARate', 'animal_D_FARate',
                                          'NEU_I_dprime', 'NEG_I_dprime', 'animal_I_dprime',
                                          'NEU_D_dprime', 'NEG_D_dprime', 'animal_D_dprime',
                                          'NEU_I_Ad', 'NEG_I_Ad', 'animal_I_Ad',
                                          'NEU_D_Ad', 'NEG_D_Ad', 'animal_D_Ad',
                                          'NEU_I_criterion', 'NEG_I_criterion', 'animal_I_criterion',
                                          'NEU_D_criterion', 'NEG_D_criterion', 'animal_D_criterion',
                                          'NEU_I_A', 'NEG_I_A', 'animal_I_A',
                                          'NEU_D_A', 'NEG_D_A', 'animal_D_A',
                                          'NEU_I_B', 'NEG_I_B', 'animal_I_B',
                                          'NEU_D_B', 'NEG_D_B', 'animal_D_B',
                                          'NEU_I_K_HitRate', 'NEG_I_K_HitRate', 'animal_I_K_HitRate',
                                          'NEU_D_K_HitRate', 'NEG_D_K_HitRate', 'animal_D_K_HitRate',
                                          'NEU_I_R_HitRate', 'NEG_I_R_HitRate', 'animal_I_R_HitRate',
                                          'NEU_D_R_HitRate', 'NEG_D_R_HitRate', 'animal_D_R_HitRate',
                                          'NEU_I_K_FARate', 'NEG_I_K_FARate', 'animal_I_K_FARate',
                                          'NEU_D_K_FARate', 'NEG_D_K_FARate', 'animal_D_K_FARate',
                                          'NEU_I_R_FARate', 'NEG_I_R_FARate', 'animal_I_R_FARate',
                                          'NEU_D_R_FARate', 'NEG_D_R_FARate', 'animal_D_R_FARate'])

    for mem_test in ['I', 'D']:
        for val_cond in ['NEU', 'NEG', 'animal']:
            
            #Get relevant data
            if mem_test == 'I':
                ret_data = ret1_data
            elif ret2_file:
                ret_data = ret2_data
            else:
                continue
        
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
            mem_data.at[sub_id, '%s_%s_%s' % (val_cond, mem_test, 'Old_N')] = hits + misses
            mem_data.at[sub_id, '%s_%s_%s' % (val_cond, mem_test, 'New_N')] = FA + CR
            
            #Memory rates
            mem_data.at[sub_id, '%s_%s_%s' % (val_cond, mem_test, 'HitRate')] = hits / (hits + misses)
            mem_data.at[sub_id, '%s_%s_%s' % (val_cond, mem_test, 'FARate')] = FA / (FA + CR)
            
            #Signal detection measures
            SD_meas = SDT(hits, misses, FA, CR)
            mem_data.at[sub_id, '%s_%s_%s' % (val_cond, mem_test, 'dprime')] = SD_meas['d']
            mem_data.at[sub_id, '%s_%s_%s' % (val_cond, mem_test, 'Ad')] = SD_meas['Ad']
            mem_data.at[sub_id, '%s_%s_%s' % (val_cond, mem_test, 'criterion')] = SD_meas['c']
            mem_data.at[sub_id, '%s_%s_%s' % (val_cond, mem_test, 'A')] = SD_meas['A']
            mem_data.at[sub_id, '%s_%s_%s' % (val_cond, mem_test, 'B')] = SD_meas['B']
            
            #RK measures
            mem_data.at[sub_id, '%s_%s_%s' % (val_cond, mem_test, 'K_HitRate')] = K_hits / (hits + misses)
            mem_data.at[sub_id, '%s_%s_%s' % (val_cond, mem_test, 'R_HitRate')] = R_hits / (hits + misses)
            mem_data.at[sub_id, '%s_%s_%s' % (val_cond, mem_test, 'K_FARate')] = K_FA / (FA + CR)
            mem_data.at[sub_id, '%s_%s_%s' % (val_cond, mem_test, 'R_FARate')] = R_FA / (FA + CR)
    
    return mem_data


def process_sub(sub_id, main_dir=None, behav_data=None, mem_data=None, save_files=True):
    """
    Run encoding and behavioral statistis for a subject and add to summary files
    """
    
    #Encoding
    behav_summary = join(main_dir, 'stats', 'behavioral', 'EmCon_EncBehav_summary.csv')
    if behav_data is None:
        if os.path.exists(behav_summary):
            behav_data = pd.read_csv(behav_summary)
        else:
            behav_data = None
    behav_data = process_sub_behav_data(sub_id, behav_data=behav_data, main_dir=main_dir)
    if save_files:
        behav_data.to_csv(behav_summary)
    
    #Retrieval
    mem_summary = join(main_dir, 'stats', 'behavioral', 'EmCon_Memory_summary.csv')
    if mem_data is None:
        if os.path.exists(mem_summary):
            mem_data = pd.read_csv(mem_summary)
        else:
            mem_data = None
    mem_data = process_sub_mem_data(sub_id, mem_data=mem_data, main_dir=main_dir)
    if save_files:
        mem_data.to_csv(mem_summary)
    
    return (behav_data, mem_data)


def process_all(main_dir=None):
    """
    Process behavioral and memory data for all subjects
    """
    
    if main_dir is None:
        main_dir = os.getcwd()
        
    behav_dir = join(main_dir, 'psychopy')
    
    #Find all subjects
    sub_ids = list(set(file[:8] for file in os.listdir(behav_dir) if file.endswith('.csv')))
    
    #Start from scratch
    behav_data = None
    mem_data = None
    
    #Proces all subjects
    for sub_id in sub_ids:
        
        #We don't need to resave the file everytime
        if sub_id == sub_ids[-1]:
            save_files = True
        else:
            save_files = False
        
        #Process data for subject
        (behav_data, mem_data) = process_sub(sub_id, main_dir=main_dir, 
                                             behav_data=behav_data, mem_data=mem_data, 
                                             save_files=save_files)
        
    return (behav_data, mem_data)


def main():
    
    main_dir = r'C:\Users\fieldsec\OneDrive - Westminster College\Documents\ECF\Research\EmCon\DATA'
    
    sub_id = input('Sub ID: ')

    if sub_id == 'all':
        (behav_data, mem_data) = process_all(main_dir)
    else:
        (behav_data, mem_data) = process_sub(sub_id, main_dir)


if __name__ == '__main__':
    main()
