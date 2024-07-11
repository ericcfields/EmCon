# -*- coding: utf-8 -*-
"""
Fix problems in PsychoPy files

Author: Eric Fields
Version Date: 27 June 2024
"""

import os
from os.path import join
import shutil

import pandas as pd

main_dir = r'C:\Users\fieldsec\OneDrive - Westminster College\Documents\ECF\Research\EmCon\DATA'
behav_dir = join(main_dir, 'psychopy')


#%% Copy files with repeated study name corrected (EmCon repeated twice)

for file in os.listdir(join(behav_dir, 'orig')):
    
    #Sub 05 has flipped behavioral buttson that need to be corrected (see below)
    if file.startswith('05_EmCon_enc') and file.endswith('.csv'):
        continue
    
    #Sub 06 has two encoding files that need to be combined (see below)
    if file.startswith('06_EmCon_enc') and file.endswith('.csv'):
        continue
    
    if file.startswith('07_EmCon'):
        continue
    
    #Sub 13 had a false start that generated an extra encoding file
    if file.startswith('13_EmCon') and ('14h22.10.502' in file):
        continue
    
    #Get rid of repeated study name
    if 'EmCon_EmCon' in file:
        new_file = join(behav_dir, file.replace('EmCon_EmCon', 'EmCon'))
    else:
        new_file = join(behav_dir, file)
    
    #Copy file with corrected name
    if not os.path.isfile(new_file):
        print('Adding %s' % new_file)
        shutil.copy2(join(behav_dir, 'orig', file), new_file)
    

#%% Fix flipped response buttons during encoding for 05_EmCon

new_file = join(behav_dir, '05_EmCon_enc_2023-10-27_16h36.07.964_corrected.csv')
if not os.path.isfile(new_file):
    enc_05 = pd.read_csv(join(behav_dir, 'orig', '05_EmCon_EmCon_enc_2023-10-27_16h36.07.964.csv'))
    enc_05['animal_hand'] = 'R'
    enc_05.to_csv(new_file)


#%% Combine encoding for 06_EmCon (split into two files due to error)

merged_file_06 = join(behav_dir, '06_EmCon_enc_2023-10-30.csv')

if not os.path.isfile(merged_file_06):

    #Get trial rows from the two parts
    pt1 = pd.read_csv(join(behav_dir, 'orig', '06_EmCon_enc_2023-10-30_15h36.09.271.csv'))
    pt1 = pt1[pt1['valence'].notna()]
    pt2 = pd.read_csv(join(behav_dir, 'orig', '06_EmCon_enc_2023-10-30_16h01.42.053.csv'))
    pt2 = pt2[pt2['valence'].notna()]
    
    full_data = pd.concat((pt1, pt2), ignore_index=True)
    
    full_data.to_csv(merged_file_06, index=False)


#%% Correct 07_EmCon (first retrieval run on wrong list)

enc_07 = pd.read_csv(join(behav_dir, 'orig', '07_EmCon_enc_2023-11-01_15h52.47.363.csv'))
ret1_07 = pd.read_csv(join(behav_dir, 'orig', '07_EmCon_ret1_2023-11-01_17h01.45.175.csv'))
ret2_07 = pd.read_csv(join(behav_dir, 'orig', '07_EmCon_ret2_2023-11-02_19h04.30.714.csv'))

#Change conditions in encoding file
trials_idx = enc_07['valence'].isin(['NEU', 'NEG', 'animal'])
assert trials_idx.sum() == 440
for row in enc_07[trials_idx].index:
    word = enc_07.loc[row, 'stim_word']
    if word in ret1_07['stim_word'].values:
        if word in ret2_07['stim_word'].values:
            enc_07.loc[row, 'test_cond'] = 'both'
        else:
            enc_07.loc[row, 'test_cond'] = 'immediate'
    else:
        if word in ret2_07['stim_word'].values:
            enc_07.loc[row, 'test_cond'] = 'delayed'
        else:
            enc_07.loc[row, 'test_cond'] = 'neither'
            
#NOTE: Stopped here and decided not to fix this
