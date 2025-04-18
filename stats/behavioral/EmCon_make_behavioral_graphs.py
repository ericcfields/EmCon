# -*- coding: utf-8 -*-
"""
Make bar graphs of memory results for EmCon

Author:Eric Fields
Version Date: 18 April 2025
"""

from os.path import join
import numpy as np
import pandas as pd
import scipy.stats as sps
import matplotlib.pyplot as plt
import seaborn as sns

main_dir = r'C:\Users\fieldsec\OneDrive - Westminster College\Documents\ECF\Research\EmCon\DATA'


#%% IMPORT DATA

sdata = pd.read_csv(join(main_dir, 'stats', 'behavioral', 'EmCon_memory_long.csv'))
sdata = sdata[sdata['valence'] != 'animal']
sdata['delay'] = sdata['delay'].replace({'I':'immediate', 'D':'delayed'})

#drop unused participants
drop_subs = ['01_EmCon', '07_EmCon', '18_EmCon']
sdata = sdata[~sdata['sub_id'].isin(drop_subs)]
assert len(sdata['sub_id'].unique()) == 30


#%% MAKE BAR GRAPHS

DVs = {'HitRate': 'hit rate', 'FARate': 'false alarm rate', 
       'dprime':"d' (discriminability)", 'criterion':'c (response bias)'}

for DV in DVs:
    
    #Check assumptions
    print('####### %s #######' % DV)
    print('SKEW')
    print(sdata[['delay', 'valence', DV]].groupby(['delay', 'valence']).skew())
    print('KURTOSIS')
    print(sdata[['delay', 'valence', DV]].groupby(['delay', 'valence']).aggregate(sps.kurtosis))
    
    plt.figure()

    # fig = sns.barplot(x='delay', y=DV, hue='valence', 
    #                   estimator=np.mean,
    #                   errorbar='se',
    #                   order=['immediate', 'delayed'], hue_order=['NEU', 'NEG'],
    #                   palette=['dimgray', 'firebrick'],
    #                   data = sdata)
    
    fig = sns.boxplot(data=sdata, x='delay', y=DV, hue='valence',
                       palette=['dimgray', 'firebrick'],
                       whis=(0, 100), fliersize=0, showmeans=True,
                       meanprops={'marker': 's',
                                  'markerfacecolor':'lime',
                                  'markeredgecolor':'lime',
                                  'markersize':'6'})
    
    sns.stripplot(x='delay', y=DV, hue='valence',
                  order=['immediate', 'delayed'], hue_order=['NEU', 'NEG'],
                  palette=['dimgray', 'firebrick'],
                  edgecolor='gray', linewidth=1,
                  data=sdata, dodge=True, alpha=0.6, ax=fig)
    
    fig.legend_.remove()
    plt.xlabel('')
    plt.ylabel(DVs[DV])
    plt.rcParams.update({'font.size': 18})
    if DV in ['HitRate', 'FARate']:
        plt.yticks(np.arange(0, 1.01, 0.2))
    elif DV == 'dprime':
        plt.yticks(np.arange(-0.5, 3.01, 0.5))
    else:
        plt.yticks(np.arange(-1, 2.01, 0.5))
        
    plt.show()
    
    plt.savefig(join(main_dir, 'stats', 'behavioral', 'plots', '%s.tif' % DV), dpi=1000, bbox_inches='tight')
    
    plt.close()
