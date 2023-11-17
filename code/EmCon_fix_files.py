# -*- coding: utf-8 -*-
"""
Fix psychopy file naming problems for EmCon

Author: Eric Fields
Version Date: 17 November 2023
"""

import os
from os.path import join
import shutil

import pandas as pd

main_dir = r'C:\Users\fieldsec\OneDrive - Westminster College\Documents\ECF\Research\EmCon\DATA'
behav_dir = join(main_dir, 'psychopy')

#%% Copy files with repeated study name corrected

for file in os.listdir(join(behav_dir, 'orig')):
    
    if file.startswith('06_EmCon_enc') and file.endswith('.csv'):
        continue
    
    #Get rid of repeated study name
    if 'EmCon_EmCon' in file:
        new_file = join(behav_dir, file.replace('EmCon_EmCon', 'EmCon'))
    else:
        new_file = join(behav_dir, file)
    
    #Copy file with corrected name
    if not os.path.isfile(new_file):
        shutil.copy2(join(behav_dir, 'orig', file), new_file)
    

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
