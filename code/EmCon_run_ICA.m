%Run ICA on epoched data for LER
%
%Author: Eric Fields
%Version Date: 2 August 2023

clearvars; close all;

%% Set-up

%Get main data directory
main_dir = EmCon_main_dir();

%Update paths
cd(main_dir);
addpath(fullfile(main_dir, 'code'));

%Find subjects with pre-ICA rejection but no ICA weights
sub_ids = get_subset('bad_epochs', 'ICA', main_dir);

%% Run ICA

for i = 1:length(sub_ids)
    
    sub_id = sub_ids{i};

    %% Load and prep training set

    %start EEGLAB
    [ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab; %#ok<ASGLU>

    %Load preart set
    EEG = pop_loadset('filename', [sub_id '_preart.set'], 'filepath', fullfile(main_dir, 'EEGsets'));
    [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, 0);
    [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET, 'setname', [EEG.subject '_ICAtrain'], 'gui', 'off');
    
    %Check that data is epoch mean baselined
    assert(abs(mean(EEG.data(:))) < 0.1);
    
    %Load bad epochs
    bad_epochs = logical(csvread(fullfile(main_dir, 'ICA', [sub_id '_bad_epochs.csv'])));
    
    %Remove bad epochs
    if ~isempty(bad_epochs) && any(bad_epochs)
        assert(length(bad_epochs) == EEG.trials);
        EEG = pop_rejepoch(EEG, bad_epochs, 0);
        [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);
        assert(EEG.trials == sum(~bad_epochs));
    end
    
    %Check that there is sufficient data for ICA
    if ((128/EEG.srate) * EEG.pnts * sum(~bad_epochs) < 30 * length(EEG.chanlocs)^2)
        warning('You may not have enough data points for reliable ICA training');
    end
    
    %Exclude chans
    exc_chaninds = csvread(fullfile(main_dir, 'ICA', [sub_id, '_exclude_chans.csv']));
    inc_chaninds = find(~ismember(1:length(EEG.chanlocs), exc_chaninds));
    
    %% Run ICA
    
    %ICA algorithm
    tic
    EEG = pop_runica(EEG, 'extended', 1, ... 
                     'maxsteps', 1024, ...
                     'chanind', inc_chaninds, ...
                     'logfile', fullfile(main_dir, 'ICA', [sub_id '_ICA_log.txt']));
    fprintf('\nICA took %.1f minutes.\n\n', toc/60)
    [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET, 'setname', [EEG.setname '_ICA'], 'gui', 'off'); %#ok<ASGLU>

    %Save ICA weights
    pop_expica(EEG, 'weights', fullfile(main_dir, 'ICA', [sub_id '_ICAw.txt']));
    
    %% Add weights to preart set

    %Load preart set
    EEG = pop_loadset('filename', [sub_id '_preart.set'], 'filepath', fullfile(main_dir, 'EEGsets'));
    [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, 0);

    %Import ICA weights
    EEG = pop_editset(EEG, 'icachansind', 'ALLEEG(end-1).icachansind', 'icaweights', 'ALLEEG(end-1).icaweights', 'icasphere', 'ALLEEG(end-1).icasphere');
    [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);

    %Save pre-artifact rejection EEGset
    EEG = eeg_checkset(EEG);
    EEG = pop_saveset(EEG, 'filename', [sub_id '_preart.set'], 'filepath', fullfile(main_dir, 'EEGsets'));
    [ALLEEG, EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
    
end

eeglab redraw;
