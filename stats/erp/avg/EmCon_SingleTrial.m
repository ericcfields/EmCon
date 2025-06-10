%Get single trial data for EmCon analyses
%
%Author: Eric Fields
%Version Date: 15 May 2025

%% SET-UP

clearvars; close all;

main_dir = 'C:\Users\fieldsec\OneDrive - Westminster College\Documents\ECF\Research\EmCon\DATA';
st_dir = fullfile(main_dir, 'stats', 'erp', 'avg');

addpath(fullfile(main_dir, 'code'));

%Get array of usable subjects
use_status = {'YES', 'PROBABLY', 'MAYBE'};
data_log = readcell(fullfile(main_dir, 'EmCon_EEG_DataLog.xlsx'));
data_log = data_log(cellfun(@ischar, data_log(:, 3)), :);
subs = data_log(ismember(data_log(:,3), use_status));

%ERP data parameters
a_chans = {'FP2', 'FZ', 'F4'};
a_time_wind = [850, 1100];
p_chans = {'CP3', 'CPZ', 'CP4', 'P3', 'PZ', 'P4'};
p_time_wind = [500, 700];


%% GET SINGLE TRIAL DATA

%Initialize variables
data = table;
row = 0;

%Get trial data
for s = 1:length(subs)
    
    fprintf('Retrieving data from %s\n\n', subs{s});
    
    %re-start EEGLAB
    [ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab; %#ok<ASGLU>
    
    %Load subject data
    EEG = pop_loadset('filename', [subs{s} '_postart.set'], 'filepath', fullfile(main_dir, 'EEGsets'));
    [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, 0);

    %Check baseline
    baseline_time = [-200, -1];
    [~, bsln_start] = min(abs(EEG.times - baseline_time(1)));
    [~, bsln_end] = min(abs(EEG.times - baseline_time(2)));
    assert(max(max(mean(EEG.data(:, bsln_start:bsln_end, :), 2))) < 1e-3);

    %GET PSYCHOPY DATA
    %Find psychopy encoding file
    behav_files = {dir(fullfile(main_dir, 'psychopy')).name};
    behav_file = behav_files(contains(behav_files, [subs{s} '_enc']) & contains(behav_files, '.csv'));
    if any(contains(behav_file, '_corrected'))
        behav_file = behav_file(contains(behav_file, '_corrected'));
    end
    assert(length(behav_file) == 1);
    behav_file = behav_file{1};
    %Import psychopy data to table
    behav_data = readtable(fullfile(main_dir, 'psychopy', behav_file));
    %Drop non-trial rows
    idx = ~isnan(behav_data{:, 'unique_id'});
    behav_data = behav_data(idx, :);
    
    %Deal with missing trials for 15_EmCon (4 trials not recorded after
    %2nd long break)
    if strcmp(subs{s}, '15_EmCon')
        behav_data = behav_data([1:300, 305:440], :);
    end
    %Deal with missing trials for 33_EmCon
    if strcmp(subs{s}, '33_EmCon')
        behav_data = behav_data(22:end, :);
    end

    %Check that trials match in EEG data and psychopy data
    assert(height(behav_data) == length(EEG.epoch));
    for ep = 1:length(EEG.epoch)
        assert(behav_data{ep, 'word_ec'} == str2double(EEG.epoch(ep).eventtype(end-3:end-1)));
        %fprintf('Epoch %d:\t%d\t%d\n', ep, behav_data{ep, 'word_ec'}, str2double(EEG.epoch(ep).eventtype(end-3:end-1)));
    end
    
    %Get channel and time point indices for ROIs
    p_chan_idx = find(ismember({EEG.chanlocs.labels}, p_chans));
    [~, p_start_sample] = min(abs( EEG.times - p_time_wind(1) ));
    [~, p_end_sample  ] = min(abs( EEG.times - p_time_wind(2) ));
    a_chan_idx = find(ismember({EEG.chanlocs.labels}, a_chans));
    [~, a_start_sample] = min(abs( EEG.times - a_time_wind(1) ));
    [~, a_end_sample  ] = min(abs( EEG.times - a_time_wind(2) ));

    %Get rid of warnings about adding data to each row
    warning('off', 'MATLAB:table:RowsAddedExistingVars');
    
    for ep = 1:length(EEG.epoch)
        
        %Update row
        row = row+1;
        
        %sub ID
        data{row, 'sub_id'} = subs{s};

        %Word and word ID
        data{row, 'word_id'} = behav_data{ep, 'unique_id'};
        data{row, 'word'} = behav_data{ep, 'stim_word'};
        
        %Find timelocked event within epoch
        ev_idx = find(EEG.epoch(ep).eventlatency==0);
        assert(length(ev_idx)==1);

        %Add order or presentation
        data{row, 'order'} = ep;
        
        %Get valence condition
        first_bin = EEG.epoch(ep).eventbini(1);
        if first_bin == 1
            data{row, 'valence'} = "NEU";
        elseif first_bin ==2
            data{row, 'valence'} = "NEG";
        elseif first_bin == 3
            data{row, 'valence'} = "animal";
        else
            error('First bin for %s epoch %d is not 1, 2, or 3', subs{s}, ep);
        end

        %Get accuracy
        if any(ismember(EEG.epoch(ep).eventbini, [5, 6, 7]))
            data{row, 'acc'} = 1;
        else
            data{row, 'acc'} = 0;
        end

        %Get memory condition
        mem_bin = EEG.epoch(ep).eventbini(ismember(EEG.epoch(ep).eventbini, [8, 9, 12, 13, 16, 17, 24, 25, 28, 29, 32, 33]));
        assert(length(mem_bin)<=1);
        if ~isempty(mem_bin)
            switch mem_bin
                case 8
                    assert(strcmp(data{row, 'valence'}, 'NEU'));
                    data{row, 'delay'} = "immediate";
                    data{row, 'old_resp'} = 0;
                case 9
                    assert(strcmp(data{row, 'valence'}, 'NEU'));
                    data{row, 'delay'} = "immediate";
                    data{row, 'old_resp'} = 1;
                case 12
                    assert(strcmp(data{row, 'valence'}, 'NEG'));
                    data{row, 'delay'} = "immediate";
                    data{row, 'old_resp'} = 0;
                case 13
                    assert(strcmp(data{row, 'valence'}, 'NEG'));
                    data{row, 'delay'} = "immediate";
                    data{row, 'old_resp'} = 1;
                case 16
                    assert(strcmp(data{row, 'valence'}, 'animal'));
                    data{row, 'delay'} = "immediate";
                    data{row, 'old_resp'} = 0;
                case 17
                    assert(strcmp(data{row, 'valence'}, 'animal'));
                    data{row, 'delay'} = "immediate";
                    data{row, 'old_resp'} = 1;
                case 24
                    assert(strcmp(data{row, 'valence'}, 'NEU'));
                    data{row, 'delay'} = "delayed";
                    data{row, 'old_resp'} = 0;
                case 25
                    assert(strcmp(data{row, 'valence'}, 'NEU'));
                    data{row, 'delay'} = "delayed";
                    data{row, 'old_resp'} = 1;
                case 28
                    assert(strcmp(data{row, 'valence'}, 'NEG'));
                    data{row, 'delay'} = "delayed";
                    data{row, 'old_resp'} = 0;
                case 29
                    assert(strcmp(data{row, 'valence'}, 'NEG'));
                    data{row, 'delay'} = "delayed";
                    data{row, 'old_resp'} = 1;
                case 32
                    assert(strcmp(data{row, 'valence'}, 'animal'));
                    data{row, 'delay'} = "delayed";
                    data{row, 'old_resp'} = 0;
                case 33
                    assert(strcmp(data{row, 'valence'}, 'animal'));
                    data{row, 'delay'} = "delayed";
                    data{row, 'old_resp'} = 1;
            end
        end

        %Get remember/know condition
        if data{row, 'old_resp'} == 1
	        rk_bin = EEG.epoch(ep).eventbini(ismember(EEG.epoch(ep).eventbini, [10, 11, 14, 15, 18, 19, 26, 27, 30, 31, 34, 35]));
	        assert(length(mem_bin)<=1);
	        if ~isempty(rk_bin)
		        switch rk_bin
			        case 10
				        assert(strcmp(data{row, 'valence'}, 'NEU'));
				        assert(data{row, 'delay'} == "immediate");
				        data{row, 'rk_resp'} = 0;
			        case 11
				        assert(strcmp(data{row, 'valence'}, 'NEU'));
				        assert(data{row, 'delay'} == "immediate");
				        data{row, 'rk_resp'} = 1;
			        case 14
				        assert(strcmp(data{row, 'valence'}, 'NEG'));
				        assert(data{row, 'delay'} == "immediate");
				        data{row, 'rk_resp'} = 0;
			        case 15
				        assert(strcmp(data{row, 'valence'}, 'NEG'));
				        assert(data{row, 'delay'} == "immediate");
				        data{row, 'rk_resp'} = 1;
			        case 18
				        assert(strcmp(data{row, 'valence'}, 'animal'));
				        assert(data{row, 'delay'} == "immediate");
				        data{row, 'rk_resp'} = 0;
			        case 19
				        assert(strcmp(data{row, 'valence'}, 'animal'));
				        assert(data{row, 'delay'} == "immediate");
				        data{row, 'rk_resp'} = 1;
			        case 26
				        assert(strcmp(data{row, 'valence'}, 'NEU'));
				        assert(data{row, 'delay'} == "delayed");
				        data{row, 'rk_resp'} = 0;
			        case 27
				        assert(strcmp(data{row, 'valence'}, 'NEU'));
				        assert(data{row, 'delay'} == "delayed");
				        data{row, 'rk_resp'} = 1;
			        case 30
				        assert(strcmp(data{row, 'valence'}, 'NEG'));
				        assert(data{row, 'delay'} == "delayed");
				        data{row, 'rk_resp'} = 0;
			        case 31
				        assert(strcmp(data{row, 'valence'}, 'NEG'));
				        assert(data{row, 'delay'} == "delayed");
				        data{row, 'rk_resp'} = 1;
			        case 34
				        assert(strcmp(data{row, 'valence'}, 'animal'));
				        assert(data{row, 'delay'} == "delayed");
				        data{row, 'rk_resp'} = 0;
			        case 35
				        assert(strcmp(data{row, 'valence'}, 'animal'));
				        assert(data{row, 'delay'} == "delayed");
				        data{row, 'rk_resp'} = 1;
		        end
	        end
        else
	        data{row, 'rk_resp'} = 0;
        end
        
        %Get EEG data
        data{row, 'frontal_pos'} = mean(mean(EEG.data(a_chan_idx, a_start_sample:a_end_sample, ep)));
        data{row, 'LPP'} = mean(mean(EEG.data(p_chan_idx, p_start_sample:p_end_sample, ep)));
        
        %EEG rejection
        data{row, 'art_rej'} = EEG.reject.rejmanual(ep);
        
    end
    
end

%Write data to csv
writetable(data, fullfile(st_dir, 'data', 'EmCon_SingleTrial.csv'));

%Turn warnings back on
warning('on', 'MATLAB:table:RowsAddedExistingVars');


%% ADD SUB VARIALBES AND CALCULATE WORD AND SUB AVERAGED DATA

py_addpath(st_dir);
py.EmCon_compile_averaged.main();

