# EmCon

Last updated: 7 October 2023

**Summary**

This study is designed to examine the relationship between the LPP of the ERP and subsequent memory at varying delays. EEG is recorded as participants are presented with a list of 200 neutral words, 200 negative words, and 40 animal words. The task is to press a button to indicate whether the word is an animal word. After a short delay, half the presented stimuli along with new neutral, negative, and animal words are presented and participants compete a remember/know/new memory test. The other half of the stimuli are tested in a memory test the next day. 

**Contact Information**

Eric Fields  
fieldsec@westminster.edu  
Westminster College  

**License**

Copyright (c) 2023, Eric Fields  
All rights reserved.  
This code is free and open source software made available under the terms of the 3-clause BSD license:  
https://opensource.org/licenses/BSD-3-Clause

**Software Versions**

Code was developed and tested in MATLAB 2023a, EEGLAB 2023.1, ERPLAB 10.0, Python 3.11, and pandas 1.5.3.


## Folder structure and data

* curry - Raw EEG data as recorded in CURRY 8.
* psychopy - Raw behavioral data (from the encoding task and memory tests) recorded in PsychoPy
* EEGsets - All saved EEGLAB datasets (unaveraged EEG data). The processing stream saves the EEGset after import (raw), after epoching but prior to artifact correction and rejection (preart), and after after rejection and correction (postart).
* ERPsets - All saved ERPLAB averaged datasets.
* belist - Contains summary output files from the creation of the ERPLAB EVENTLIST, assigning events to bins, and ERPLAB artifact rejection, as well as a file summarizing the number of times each event code appears.
* ICA - Contains a record of epochs to exclude from ICA training and electrodes to exclude from ICA for each subject (generated in the pre-ICA artifact rejection process). After ICA is ran, this folder contains a text file with the calculated ICA weights.
* code - Contains all data processing code.
* stats - Contains data and code for statistical analysis




## Data processing and analysis: Description and user guide

### Behavioral data

1. Behavioral data is processed and summarized by `EmCon_behav.py`. Assuming MATLAB is properly linked to a Python environment with the SciPy stack, this code is automatically run as part of the EEG pre-processing code, but it may need to be run again if not all data (e.g., the second memory test) is available when EEG pre-processing is done. This can be run from MATLAB by running `EmCon_behav.m` or by running the Python script directly.


### Single subject EEG data processing

**I. Pre-processing**

1. Run `EmCon_preprocess`. This script performs all processing from the initial import of the EEG data up to artifact correction and rejection including binning and epoching (see documentation at the top of the script for details). Parameters for each processing step are found in `EmCon_preproc_params`.

**II. ICA Decomposition**

2. Run `pre_ICA_rej`. A window will pop up. Scroll through the data and click to highlight each epoch that should be excluded from the ICA training set (these will not be permanently deleted from the data). The goal is to exclude epochs with artifact that is not from a regular, consistent source such as EMG, EOG, or EEG. For example, trials with random drift or jump on particular electrodes (e.g., as a result of the participant moving) should be excluded. Don't be afraid to be aggressive here to get the best ICA solution. When finished, click "Update Marks" at the bottom right of the window.

3. Run `save_ICA_rej` immediately after marking trials for exclusion for ICA. This will save the selections you made. It will also ask you if you want to exclude any electrodes from ICA training. You should only do this for electrodes you plan to interpolate later.

4. Run `run_ICA`. This will perform ICA for any participant that has the information from the pre-ICA rejection steps, but does not have ICA weights. It will save the calculated weighting matrix to a file and to the preart EEGset.

**III. Artifact correction and rejection**

5. Run `from_preart`. This script will load the preart EEGset. If there is no subject-specific artifact rejection script, one will be created from the default script. If a script already exists, it will be opened.

6. In the EEGLAB GUI, click on Tools -> Inspect/label components by map. Then click on Plot -> Component activations (scroll) and also Plot -> Channel activations (scroll). Inspect the scalp maps of the components and the activation pattern of the components (in comparison with activations in the original channel data) to determine which independent components represent correctable artifact. This generally consists of 1-3 components that represent blinks and saccades.

7. In the artifact rejection script, change the `ICrej` variable to an array of all components to be rejected (e.g., `[1, 3]`). If one or more of these components seem to capture blinks well, change the `blink_corr` variable to `true`. If you do not wish to perform ICA correction, you can leave both of these variables set to `false`. Note that trials with blinks in the -50 - 200 ms range will be rejected even if blinks are corrected, because the participant had their eyes closed when the stimulus was presented.

8. Run the artifact rejection script. 

9. When the confirmation dialogue comes up, click "Plot single trials" and scroll through the data to check whether the ICA correction is accurately removing the intended artifact and only the intended artifact. Then click "Accept".

10. When the script finishes there will be a summary of artifact detection in the command window which describes rejected trials per channel and per detection algorithm. Two windows will pop up, one showing the data and the other a table showing artifact rejection values for each channel for each rejection algorithm. This table represents the trial the mouse is currently hovering over. Scroll through the data and determine if artifact detection is adequately separating trials that should and should not be rejected. If not, try to determine what changes to algorithm thresholds or other parameters could improve artifact detection. At the command prompt, type 'y' if you are satisfied with artifact correction and rejection and want to save and proceed. Type 'n' if you would like to make some changes to the artifact rejection script and run again. Continue this process until you are satisfied. *NOTE: If for any reason an error is generated and the artifact rejection script does not finish running correctly, you need to restart the process by re-running `from_preart`. This will ensure you are working with the preart set, not a set with partial artifact correction/rejection (running the artifact rejection script again on such a set will cause problems).*


**IV. Averaging**

11. After saving artifact correction/rejection, you will be asked whether you want to calculate ERPs. If you want/need to calculate ERPs at a later time, run `EmCon_make_erp`.




### Statistical Analysis

TBD
