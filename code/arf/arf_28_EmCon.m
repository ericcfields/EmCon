%Artifact rejection script for EmCon
%
%AUTHOR: Eric Fields
%VERSION DATE: 8 March 2024

%Copyright (c) 2024, Eric Fields
%All rights reserved.
%This code is free and open source software made available under the terms 
%of the 3-clause BSD license:
%https://opensource.org/licenses/BSD-3-Clause

%See arf_readme.md for instructions for using this script.


%% ************************************************************************
%*****************************  PARAMETERS  *******************************
%**************************************************************************

%Some parameters
EmCon_preproc_params;
num_chans = length(EEG.chanlocs);
EEGchans = 1:(num_chans-2);
art_chan_low_pass = 15;

%Independent components to remove from data (if nonre, ICrej = false)
ICrej = [1, 5, 6];
blink_corr = true; %true if one or more rejected ICs represent blinks

%Electrodes to interpolate
interpolate_electrodes = {};

%Time window in which to detect artifacts for each epoch
rej_window = [-200, 1100]; %must be smaller than or equal to epoch specified in preprocessing file.

%Blink detection
%(Implemented as peak to peak amplitude on a filtered version of VEOG not corrected by ICA)
%Flag 2
blink_thresh     = 75;
blink_windowsize = 200;
blink_windowstep = 25;

%Step-like artifacts for all channels
%Flag 3
step_thresh      = 50;
step_windowsize  = 300;
step_windowstep  = 25;
step_chans = 1:num_chans;

%Peak to peak amplitude for all channels
%Flag 4
ppa_thresh       = 250;
ppa_windowsize   = 200;
ppa_windowstep   = 25;
ppa_chans = 1:num_chans;

%Step-based drift detection
%Flag 5
drift_thresh     = 40;
drift_windowsize = 1000;
drift_windowstep = 50;
drift_chans = 1:num_chans;

%Epoch numbers for trials that need to be manually rejected
%Flag 6 
%This should generally be used to remove trials with technical problems, not for artifact
%Examples:
% manual_reject = []; %no manual rejections
% manual_reject = [1, 600]; %manually reject epochs 1 and 600
% manual_reject = [1, 20:43, 201]; %manually reject epochs, 1, 20 through 43, and 201
manual_reject = [];

%Epoch numbers for trials that should be protected from artifact rejection
%YOU PROBABLY DON'T WANT TO DO THIS!
%Syntax as above
manual_unreject = [];


%DON'T CHANGE ANYTHING BELOW THIS LINE UNLESS YOU KNOW WHAT YOU'RE DOING
%**************************************************************************
%**************************************************************************
%**************************************************************************


%% ***** SET-UP *****

%This script should not be run on a dataset that has already had artifact
%rejection performed.
if strfind(EEG.setname, 'ar')
    error(['This script should only be run on data that has not had artifact correction or rejection applied. ' ...
           'To restart fresh, run from_preart again before running this script'])
end

%Set some variables if not previously set
if ~exist('main_dir', 'var')
    arffile_path = mfilename('fullpath');
    if strfind(arffile_path, [filesep 'arf' filesep]) %#ok<STRIFCND>
        main_dir = arffile_path(1:strfind(arffile_path, [filesep 'arf' filesep]));
    else
        main_dir = input('\nData directory:  ', 's');
    end
end
if ~exist('sub_id','var')
    if ~isempty(EEG.subject)
        sub_id = EEG.subject;
    else
        sub_id = input('\nSubject ID: ', 's');
    end
end
if ~exist('batch_proc', 'var')
    batch_proc = false;
end

%Set paths
cd(main_dir);
addpath('code');
addpath(fullfile('code', 'arf'));


%% ***** ARTIFACT DETECTION *****

%Check for ICA weights
if isempty(EEG.icaweights) && ~isempty(ICrej)
    errordlg('EEGset does not have ICA weights!');
end

%Create new ar EEGset
[ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET, 'setname', [EEG.setname '_ar'], 'gui', 'off');

%Create blink channel
if strfind(EEG.setname, 'ICA')
    warndlg('Blink channel calculated from ICA corrected data. Detection of blinks during stimulus presentation may not be accurate.')
end
blink_chan = num_chans + 1;
blink_syntax = sprintf('ch%d = ch%d label blink', blink_chan, find(strcmp({EEG.chanlocs.labels}, 'VEOG')));
EEG = pop_eegchanoperator(EEG, {blink_syntax}, 'ErrorMsg', 'popup', 'Warning', 'off');
EEG = pop_basicfilter(EEG, blink_chan, 'Cutoff',  art_chan_low_pass, 'Design', 'butter', 'Filter', 'lowpass', 'Order',  2);
[ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);

%Check that data is epoch mean baselined
assert(abs(mean(EEG.data(:))) < 0.1);

%Remove ICs
if ~isempty(ICrej)
    EEG = pop_subcomp(EEG, ICrej, double(~batch_proc));
    EEG.setname = strrep(EEG.setname, ' pruned with ICA', '_ICAcorr');
    [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);
end

%Interpolate electrodes
if ~isempty(interpolate_electrodes)
    interp_idx = find(ismember({EEG.chanlocs.labels}, interpolate_electrodes));
    fprintf('\nInterpolating ');
    fprintf('%s ', EEG.chanlocs(interp_idx).labels);
    fprintf('\n\n');
    EEG = pop_interp(EEG, interp_idx, 'spherical');
    [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);
end

%Pre-stimulus baseline correct
EEG = pop_rmbase(EEG, baseline_time);
[ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET, 'setname', [EEG.setname '_bsln'], 'gui', 'off');

%Prepare variables for filter thresholds table
clearvars -global outmwppth; clearvars -global outstepth; clearvars -global thresholds;
global outmwppth;   %#ok<GVMIS,NUSED> %threshold values output by pop_artmwppth
global outstepth;   %#ok<GVMIS,NUSED> %threshold values output by pop_artstep
global outflat;     %#ok<GVMIS,NUSED> %threshold values output by pop_artflatline
global chanlabels; %#ok<GVMIS>
chanlabels = {EEG.chanlocs.labels};

%Blink detection
if blink_corr
    blink_rej_window = [-50 200];
else
    blink_rej_window = rej_window;
end
EEG  = NCL_pop_artmwppth(EEG, 'Channel', blink_chan, 'Flag', [1, 2], 'Threshold', blink_thresh, ...
                         'Twindow', blink_rej_window, 'Windowsize', blink_windowsize, ...
                         'Windowstep', blink_windowstep, 'Review', 'off');
plotthresh.addFilter('Name','Blink','Channels',blink_chan,'Type','NCL_pop_artmwppth','Threshold',blink_thresh);

%Step function based detection
EEG  = NCL_pop_artstep(EEG, 'Channel', step_chans, 'Flag', [1, 3], 'Threshold', ...
                       step_thresh, 'Twindow', rej_window, 'Windowsize', step_windowsize, ...
                       'Windowstep', step_windowstep, 'Review', 'off');
plotthresh.addFilter('Name','Step','Channels',step_chans,'Type','NCL_pop_artstep','Threshold',step_thresh);

%Peak to peak amplitude detection
EEG  = NCL_pop_artmwppth(EEG, 'Channel', ppa_chans, 'Flag', [1, 4], 'Threshold', ppa_thresh, ...
                         'Twindow', rej_window, 'Windowsize', ppa_windowsize, ...
                         'Windowstep', ppa_windowstep, 'Review', 'off');
plotthresh.addFilter('Name','Pk-Pk','Channels',ppa_chans,'Type','NCL_pop_artmwppth','Threshold',ppa_thresh);

%Drift detection
EEG  = NCL_pop_artstep(EEG, 'Channel', drift_chans, 'Flag', [1, 5], 'Threshold', drift_thresh, ...
                       'Twindow', rej_window, 'Windowsize', drift_windowsize, ...
                       'Windowstep', drift_windowstep, 'Review', 'off');
plotthresh.addFilter('Name','Drift','Channels',drift_chans,'Type','NCL_pop_artstep','Threshold',drift_thresh);

%Manual rejection
if ~isempty(manual_reject)
    fprintf('Manually rejecting epochs');
    disp(manual_reject);
    fprintf('\n');
    EEG.reject.rejmanual(manual_reject) = 1;
    for epoch_num = manual_reject
        EEG= markartifacts(EEG, [1, 6], 1:EEG.nbchan, [], epoch_num, 1);
    end
    EEG = ecf_pop_syncroartifacts(EEG, 'Direction', 'bidirectional');
    pop_summary_AR_eeg_detection(EEG, '');
end

%Manual unrejection
%BE CAREFUL!
if exist('manual_unreject', 'var') && ~isempty(manual_unreject)
    fprintf('\n\n**********************************************************\n')
    fprintf('Manually UNrejecting epochs');
    disp(manual_unreject)
    fprintf('\nWARNING!\n')
    fprintf('\nThese trials will not be rejected even if they contain artifact!\n')
    fprintf('\n**********************************************************\n\n')
    EEG.reject.rejmanual(manual_unreject) = 0;
    EEG.reject.rejmanualE(:, manual_unreject) = 0;
    EEG = ecf_pop_syncroartifacts(EEG, 'Direction', 'eeglab2erplab');
    pop_summary_AR_eeg_detection(EEG, '');
end

[ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);

%Rejection report
[~, ~, ~, rej_by_bin] = pop_summary_AR_eeg_detection(EEG, 'none');
fprintf('Smallest New/Old Bin: %d\n\n', min(EEG.EVENTLIST.trialsperbin([8, 9, 12, 13, 24, 25, 28, 29]) - rej_by_bin([8, 9, 12, 13, 24, 25, 28, 29])));
chan_rej_array = chan_rej_report(EEG);

%Plot threshold table window
%Window can be shown via EEGPLOT window > Display >
if ~batch_proc
    plotthresh.update;
end


%% ***** REVIEW & SAVE *****

%%% Should the current artifact marks be saved?
if batch_proc
    %If we're batch processing, save artifact rejection and compute ERPs
    save_rej = true; %#ok<UNRCH>
else
    %If not batch processing:
    %Open window for visual inspection
    ECF_pop_eegplot(EEG, 1, 1, 0, rej_window);
    %pop_eegplot(EEG, 1, 1, 0);
    %User decides whether to save current rejection scheme
    user_resp = input('Save artifact rejection?(y/n): ','s');
    if strcmpi(user_resp, 'y')
        save_rej = true;
    else
        save_rej = false;
    end
end

%%% Now we save set with artifact marks and flags (and computer ERPs if
%%% requested) OR we delete the current set and go back to the preart set
if save_rej
    %Save to disk
    EEG = pop_saveset(EEG, 'filename', [sub_id '_postart.set'], 'filepath', fullfile(main_dir, 'EEGsets'));
    [ALLEEG, EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
    EEG = pop_summary_AR_eeg_detection(EEG,fullfile(main_dir, 'belist', [sub_id '_AR_summary' '.txt']));
    %Compute ERPs if requested
    if ~exist('compute_erps', 'var')
        user_resp = input('Compute ERPs?(y/n): ', 's');
        if strcmpi(user_resp, 'y')
            compute_erps = true;
        else
            compute_erps = false;
        end
    end 
    if compute_erps
        EmCon_make_erp;
    end
else
    %If user chooses not to save, delete ar EEGsets and return to preart set
    CURRENTSET = CURRENTSET - 2;
    EEG = ALLEEG(CURRENTSET);
    ALLEEG = ALLEEG(1:CURRENTSET);
end

if ~batch_proc
    eeglab redraw;
    erplab redraw;
end
