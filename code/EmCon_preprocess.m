%Preprocessing script for EmCon
%
%AUTHOR: Eric Fields
%VERSION DATE: 6 August 2023

%Copyright (c) 2023, Eric Fields
%All rights reserved.
%This code is free and open source software made available under the terms 
%of the 3-clause BSD license:
%https://opensource.org/licenses/BSD-3-Clause

%This script performs the following processing steps according to
%parameters given in EmCon_preproc_params
% 1. Process behavioral data (see EmcCon_behav.py)
% 2. Import data from curry .cdt file
% 3. Fix any problems in raw data if there is a fix_raw script
% 4. Delete any channels specified in preproc_params file
% 5. Downsample the data if specified in preproc_params file
% 6. Re-reference the data
% 7. Shift event codes to correct for trigger timing if specified in
%    preproc_params file
% 8. Delete long gaps between event codes if specified in preproc_params file
% 9. Apply filters with half-amplitude cut-offs specified in preproc_parmascfiles
% 10. Bin and epoch data according to bin descriptor file


%clear the workspace and close all figures/windows
clearvars; close all;


%% ***** PARAMETERS *****

%Script defining pre-processing parameters
EmCon_preproc_params;

%String, cell array, or text file giving IDs of subjects to process
% subject_ids = get_subset('bdf', 'raw', main_dir);


%% ***** SET-UP *****

%Paths
cd(main_dir)
addpath(fullfile(main_dir, 'code'));

%If subject_ids variable is not defined above, prompt user
if ~exist('subject_ids', 'var') || isempty(subject_ids)
    subject_ids = input('\n\nSubject ID:  ', 's');
end

%Parse subject ID input
%If subject_ids is a cell array, use as is
if iscell(subject_ids)
    sub_ids = subject_ids;
%If subject_ids is a text file, read lines into cell array
elseif exist(subject_ids, 'file')
    sub_ids = {};
    f_in = fopen(subject_ids);
    while ~feof(f_in)
        sub_ids = [sub_ids fgetl(f_in)]; %#ok<AGROW>
    end
    fclose(f_in);
%If subject_ids is a string (i.e., single subject), convert to cell array
elseif ischar(subject_ids)
    sub_ids = {subject_ids};
else
    error('\nInappropriate value for subject_ids variable\n');
end

%Batch processing report
if length(sub_ids) > 1
    batch_proc = true;
    fprintf('\n\n**********************************************************\n')
    fprintf('\n\nBatch processing %d subjects\n\n', length(sub_ids))
    disp(sub_ids)
    fprintf('\n\n**********************************************************\n')
else
    batch_proc = false;
end

%Create folder structure if it doesn't exist
if ~exist(fullfile(main_dir, 'belist'), 'dir')
    mkdir(fullfile(main_dir, 'belist'));
end
if ~exist(fullfile(main_dir, 'EEGsets'), 'dir')
    mkdir(fullfile(main_dir, 'EEGsets'));
end
if ~exist(fullfile(main_dir, 'ERPsets'), 'dir')
    mkdir(fullfile(main_dir, 'ERPsets'));
end
if ~exist(fullfile(main_dir, 'ICA'), 'dir')
    mkdir(fullfile(main_dir, 'ICA'));
end


%% ***** DATA PROCESSING *****

%Loop through subjects and run all pre-processing steps
for i = 1:length(sub_ids)
    
    sub_id = sub_ids{i};

    %start (or re-start) EEGLAB
    [ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab; %#ok<ASGLU>
    

    %% Process behavioral data

    try
        EmCon_behav(sub_id);
    catch
        warning('Couldn''t process behavioral data for %s', sub_id);
    end
    

    %% Import EEG and channel locations

    %Import data or load existing raw set
    if exist(fullfile(main_dir ,'EEGsets', [sub_id '_raw.set']), 'file')

        %Load existing raw set
        fprintf('\nRaw set already exists. Loading %s\n\n', fullfile(main_dir, 'EEGsets', [sub_id '_raw.set']));
        EEG = pop_loadset('filename', [sub_id '_raw.set'], 'filepath', fullfile(main_dir, 'EEGsets'));
        [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, 0);

    else
        
        %Import data
        EEG = loadcurry(fullfile(main_dir, 'curry', [sub_id, '.cdt']), 'KeepTriggerChannel', 'True', 'CurryLocations', 'False');
        EEG.subject = sub_id;
        [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, 0, 'setname', sub_id, 'gui', 'off');
        
        %Fix problems in recorded data (e.g., switched electrodes)
        if exist(fullfile(main_dir, 'code', 'fix_raw', [sub_id '_fix_raw.m']), 'file')
            addpath(fullfile(main_dir, 'code', 'fix_raw'));
            run(fullfile(main_dir, 'code', 'fix_raw', [sub_id '_fix_raw.m']));
        end
        
        %Check that the correct number of channels was recorded
        if EEG.nbchan ~= 35
            if batch_proc
                warning('Expected 35 channels; data contains %d. Skipping %s', EEG.nbchan, sub_id);
            else
                eeglab redraw;
                error('Expected 35 channels; data contains %d.', EEG.nbchan);
            end
        end
        
        %Add channel locations
        % EEG = pop_chanedit(EEG, 'lookup', chanlocs_file);
        % [ALLEEG, EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);

        %Save raw data as EEG set
        EEG = pop_saveset(EEG, 'filename', [sub_id '_raw'], 'filepath', fullfile(main_dir, 'EEGsets'));
        [ALLEEG, EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
        
        %Write file of event code counts
        ec_counts = get_event_code_counts(EEG, fullfile(main_dir, 'belist', [sub_id '_ec_counts.csv']));
        
        %Check triggers for errors
        %TO DO
    
    end
    
    %% Remove Channels
    
    if ~isempty(remove_chans)
        EEG = pop_select(EEG, 'nochannel', remove_chans);
        [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET, 'setname', [EEG.setname '_rchan'], 'gui', 'off');
    end


    %% Downsample
    
    if resample_rate
        EEG = pop_resample(EEG, resample_rate);
        EEG.setname = EEG.setname(1:end-10); %removes ' resampled' from the end of the setname
        [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET, 'setname', [EEG.setname '_dsample'], 'gui', 'off');
    end
 
    
    %% Re-reference
    
    %Find numbers of reference channels
    ref_chans = find(ismember({EEG.chanlocs.labels}, ref_chans));

    %Re-reference
    EEG = eeg_checkset(EEG);
    EEG = pop_reref(EEG, ref_chans);
    [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET, 'setname', [EEG.setname '_ref'], 'gui', 'off');
    
    
    %% Shift event codes
    
    if ec_shift
        EEG  = pop_erplabShiftEventCodes(EEG, 'DisplayEEG', 0, ...
                                         'DisplayFeedback', 'both', 'Eventcodes', 1:255, ...
                                         'Rounding', 'nearest', 'Timeshift', ec_shift);
        [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET, 'setname', [EEG.setname '_shifted'], 'gui', 'off');
    end
    

    %% Delete breaks and gaps
    
    if gap_thresh
        EEG = pop_erplabDeleteTimeSegments(EEG, 'afterEventcodeBufferMS', gap_buffer, ...
                                           'beforeEventcodeBufferMS', gap_buffer, ...
                                           'displayEEG', 0, 'ignoreBoundary', 0, ...
                                           'ignoreUseType', 'ignore', 'timeThresholdMS', gap_thresh);
        [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET, 'setname', [EEG.setname '_delgaps'], 'gui', 'off');
    end
    

    %% Filtering

    if high_pass
        EEG  = pop_basicfilter(EEG, 1:length(EEG.chanlocs), 'Boundary', boundary_code, ...
                               'Cutoff', high_pass, 'Design', 'butter', 'Filter', 'highpass', ... 
                               'Order', 2, 'RemoveDC', 'on');
    end
    if low_pass
        EEG  = pop_basicfilter(EEG, 1:length(EEG.chanlocs), 'Boundary', boundary_code, ... 
                               'Cutoff', low_pass, 'Design', 'butter', 'Filter', 'lowpass', ... 
                               'Order',  2, 'RemoveDC', 'on');
    end
    [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET, 'setname', [EEG.setname '_filt'], 'gui', 'off');
    
    
    %% Bin and epoch

    %Create event list
    EEG  = pop_creabasiceventlist(EEG, 'AlphanumericCleaning', 'on', 'BoundaryNumeric', {-99}, 'BoundaryString', {'boundary'}, ... 
                                  'Eventlist', fullfile(main_dir, 'belist', [sub_id '_eventlist.txt'])); 
    [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET, 'setname', [EEG.setname '_elist'], 'gui', 'off');

    %Assign events to bins
    EEG  = pop_binlister(EEG, 'BDF', bin_desc_file, 'ExportEL', fullfile(main_dir, 'belist', [sub_id '_binlist.txt']), ...
                         'IndexEL', 1, 'SendEL2', 'EEG&Text', 'Voutput', 'EEG');
    [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET, 'setname', [EEG.setname '_bins'], 'gui', 'off');

    %Epoch the data; use the mean of the full epoch as the baseline
    EEG = pop_epochbin(EEG, epoch_time, 'all');
    [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET, 'setname', [EEG.setname '_be'], 'gui', 'off');
    
    %Check bin counts
    %TO DO
    
    %Add ICA weights if they exist
    if exist(fullfile(main_dir, 'ICA', [sub_id '_ICAw.txt']), 'file')
        fprintf('Adding ICA weights from %s\n', fullfile(main_dir, 'ICA', [sub_id '_ICAw.txt']));
        ica_exc_chaninds = readmatrix(fullfile(main_dir, 'ICA', [sub_id, '_exclude_chans.csv']));
        ica_inc_chaninds = find(~ismember(1:length(EEG.chanlocs), ica_exc_chaninds));
        EEG = pop_editset(EEG, 'icachansind', mat2str(ica_inc_chaninds), ... 
                          'icaweights', fullfile(main_dir, 'ICA', [sub_id '_ICAw.txt']), ... 
                          'icasphere', sprintf('eye(%d)', length(ica_inc_chaninds)));
        [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);
    end
    
    %Save pre-artifact rejection EEGset
    EEG = eeg_checkset(EEG);
    EEG = pop_saveset(EEG, 'filename', [sub_id '_preart.set'], 'filepath', fullfile(main_dir, 'EEGsets'));
    [ALLEEG, EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);


end

%% 
eeglab redraw; erplab redraw;
