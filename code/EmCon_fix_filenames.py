# -*- coding: utf-8 -*-
"""
Fix psychopy file naming problems for EmCon

Author: Eric Fields
Version Date: 27 October 2023
"""

import os
from os.path import join

main_dir = r'C:\Users\fieldsec\OneDrive - Westminster College\Documents\ECF\Research\EmCon\DATA'
behav_dir = join(main_dir, 'psychopy')

for file in os.listdir(behav_dir):
    if 'EmCon_EmCon' in file:
        os.rename(join(behav_dir, file),
                  join(behav_dir, file.replace('EmCon_EmCon', 'EmCon')))
