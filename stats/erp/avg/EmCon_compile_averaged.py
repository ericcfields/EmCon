# -*- coding: utf-8 -*-
"""
Take single trial data and create word and subject averaged data and add other 
information.

Author: Eric Fields
Version Date: 12 March 2024
"""

from os.path import join
import pandas as pd


def make_word_averaged(st_data, out_dir=None):
    """
    Average data by word and return long format and wide format data
    """

    idx = (st_data['art_rej'] == 0) & (st_data['acc'] == 1)
    
    #Get word averaged data
    wdata = st_data[idx].groupby(['word', 'valence', 'delay']).mean(numeric_only=True).reset_index()
    wdata['word_id'] = wdata['word_id'].astype(int)
    
    #Add trial numbers
    trial_nums = st_data[idx].groupby(['word', 'delay'])['LPP'].count()
    for word in wdata['word']:
        for dly in ['immediate', 'delayed']:
            cidx = (wdata['word']==word) & (wdata['delay']==dly)
            if cidx.sum() == 0:
                assert (word, dly) not in trial_nums.index
            else:
                wdata.loc[cidx, 'N_trials'] = trial_nums[(word, dly)]
    
    #Long format data output
    if out_dir is not None:
        wdata.to_csv(join(out_dir, 'EmCon_WordAveraged_long.csv'), index=False)
    
    #Convert to wide format
    wdata_wide = wdata.pivot(index='word', columns='delay')
    #Collapse column multi-index
    wdata_wide.columns = ['_'.join(col) for col in wdata_wide.columns]
    wdata_wide.drop(['valence_delayed', 'word_id_delayed'], axis=1, inplace=True)
    wdata_wide.reset_index(inplace=True)
    wdata_wide.rename({'valence_immediate':'valence', 'word_id_immediate': 'word_id'}, axis=1, inplace=True)
    
    #Wide format data output
    if out_dir is not None:
        wdata_wide.to_csv(join(out_dir, 'EmCon_WordAveraged_wide.csv'), index=False)
    
    return (wdata, wdata_wide)


def make_sub_averaged(st_data, out_dir=None):
    """
    Average data by subject and return long format and wide format data
    """

    idx = (st_data['art_rej'] == 0) & (st_data['acc'] == 1)
    
    #Get word averaged data
    sdata = st_data[idx].groupby(['sub_id', 'valence', 'delay']).mean(numeric_only=True).reset_index()
    sdata.drop('word_id', axis=1, inplace=True)
    
    #Add trial numbers
    trial_nums = st_data[idx].groupby(['sub_id', 'valence', 'delay'])['LPP'].count()
    for sub in sdata['sub_id'].unique():
        for val in ['NEU', 'NEG', 'animal']:
            for dly in ['immediate', 'delayed']:
                cidx = (sdata['sub_id']==sub) & (sdata['valence']==val) & (sdata['delay']==dly)
                sdata.loc[cidx, 'N_trials'] = trial_nums[(sub, val, dly)]
                
    #Long format data output
    if out_dir is not None:
        sdata.to_csv(join(out_dir, 'EmCon_SubAveraged_long.csv'), index=False)
        
    #Convert to wide format
    sdata_wide = sdata.pivot(index='sub_id', columns=['valence', 'delay'])
    #Collapse column multi-index
    sdata_wide.columns = ['_'.join(col) for col in sdata_wide.columns]
    sdata_wide.reset_index(inplace=True)
    
    #Wide format data output
    if out_dir is not None:
        sdata_wide.to_csv(join(out_dir, 'EmCon_SubAveraged_wide.csv'), index=False)
    
    return (sdata, sdata_wide)


def main():

    main_dir = r'C:\Users\fieldsec\OneDrive - Westminster College\Documents\ECF\Research\EmCon\DATA'
    avg_dir = join(main_dir, 'stats', 'erp', 'avg')
    out_dir = join(avg_dir, 'data')
    
    #Import data
    st_file = join(avg_dir, 'data', 'EmCon_SingleTrial.csv')
    st_data = pd.read_csv(st_file)
    mem_data = pd.read_csv(join(main_dir, 'stats', 'behavioral', 'EmCon_memory_wide.csv'))
    
    #Add response bias data
    for sub in st_data['sub_id'].unique():
        for val in ['NEU', 'NEG', 'animal']:
            for dly in ['immediate', 'delayed']:
                
                #Get index for relevant trials
                idx = ((st_data['sub_id'] == sub) &
                       (st_data['valence'] == val) &
                       (st_data['delay'] == dly))
                
                #Add signal detection measure of response bias
                mem_col = '%s_%s_criterion' % (val, dly[0].upper())
                st_data.loc[idx, 'sub_bias'] = mem_data.loc[mem_data['sub_id']==sub, mem_col].values[0]
    #Output data with response bias added
    st_data.to_csv(st_file, index=False)
    
    #Get word averaged data
    (wdata, wdata_wide) = make_word_averaged(st_data, out_dir=out_dir)
    
    #Get subject averaged data
    (sdata, sdata_wide) = make_sub_averaged(st_data, out_dir=out_dir)
    

if __name__ == '__main__':
    main()
