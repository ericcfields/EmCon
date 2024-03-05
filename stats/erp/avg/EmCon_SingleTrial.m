%Get single trial data for EmCon analyses
%
%Author: Eric Fields
%Version Date: 5 March 2024

%% SET-UP

clearvars; close all;

main_dir = EmCon_main_dir();
st_dir = fullfile(main_dir, 'stats', 'erp', 'avg');

%Get array of usable subjects
use_status = {'YES', 'PROBABLY', 'MAYBE'};
data_log = readcell(fullfile(main_dir, 'EmCon_EEG_DataLog.xlsx'));
data_log = data_log(cellfun(@ischar, data_log(:, 3)), :);
subs = data_log(ismember(data_log(:,3), use_status));

%ERP data parameters
p_chans = {'CP3', 'CPZ', 'CP4', 'P3', 'PZ', 'P4'};
p_time_wind = [500, 800];


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

    %GET PSYCHOPY DATA
    %Find psychopy encoding file
    behav_files = {dir(fullfile(main_dir, 'psychopy')).name};
    behav_file = behav_files(contains(behav_files, [subs{s} '_enc']) & contains(behav_files, '.csv'));
    assert(length(behav_file) == 1);
    behav_file = behav_file{1};
    %Import psychopy data to table
    behav_data = readtable(fullfile(main_dir, 'psychopy', behav_file));
    %Drop non-trial rows
    idx = ~isnan(behav_data{:, 'unique_id'});
    behav_data = behav_data(idx, :);
    %Check that trial numbers match
    assert(height(behav_data) == length(EEG.epoch));
    %Check that event codes match
    for ep = 1:length(EEG.epoch)
        assert(behav_data{ep, 'word_ec'} == str2double(EEG.epoch(ep).eventtype(end-3:end-1)));
    end
    
    %Get indices
    p_chan_idx = find(ismember({EEG.chanlocs.labels}, p_chans));
    [~, p_start_sample] = min(abs( EEG.times - p_time_wind(1) ));
    [~, p_end_sample  ] = min(abs( EEG.times - p_time_wind(2) ));

    %Get rid of warnings about adding data to each row
    warning('off', 'MATLAB:table:RowsAddedExistingVars');
    
    for ep = 1:length(EEG.epoch)
        
        %Update row
        row = row+1;
        
        %sub ID
        data{row, 'sub_id'} = subs{s};

        %unique word ID
        %TO DO
        data{row, 'word_id'} = behav_data{ep, 'unique_id'};
        data{row, 'word'} = behav_data{ep, 'stim_word'};
        
        %Find timelocked event within epoch
        ev_idx = find(EEG.epoch(ep).eventlatency==0);
        assert(length(ev_idx)==1);
        
        %Get valence condition
        first_bin = EEG.epoch(ep).eventbini(1);
        if first_bin == 1
            data{row, 'valence'} = "NEU";
        elseif first_bin ==2
            data{row, 'valence'} = "NEG";
        elseif first_bin == 3
            data{row, 'valence'} = "animal";
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

        
        %Get EEG data
        data{row, 'LPP'} = mean(mean(EEG.data(p_chan_idx, p_start_sample:p_end_sample, ep)));
        
        %EEG rejection
        data{row, 'art_rej'} = EEG.reject.rejmanual(ep);
        
    end
    
end

%Write data to csv
writetable(data, fullfile(st_dir, 'EmCon_SingleTrial.csv'));

%Turn warnings back on
warning('on', 'MATLAB:table:RowsAddedExistingVars');


%% CREATE WORD AVERAGED DATA

%Get rid of warnings about adding data to each row
warning('off', 'MATLAB:table:RowsAddedExistingVars');

wdata = table;
row = 0;
for wid = unique(data{:, 'word_id'})'

    row = row + 1;

    %Get trials with this word
    word_idx = data.word_id == wid;
    word_data = data(word_idx, :);

    %Check for consistency of word and valence
    assert(height(unique(word_data.word)) == 1);
    assert(height(unique(word_data.valence)) == 1);
    
    %Add word id, word, and valence
    wdata{row, 'word_id'} = wid;
    wdata{row, 'word'} = string(word_data{1, 'word'}{1});
    wdata{row, 'valence'} = string(word_data{1, 'valence'}{1});

    %Get memory rate and LPP for immediate trials
    idx = (word_data.delay == "immediate") & (word_data.art_rej == 0);
    wdata{row, 'N_immediate'} = sum(idx);
    wdata{row, 'LPP_immediate'} = mean(word_data{idx, 'LPP'});
    wdata{row, 'recog_mem_immediate'} = mean(word_data{idx, 'old_resp'});

    %Get memory rate and LPP for delayed trials
    idx = (word_data.delay == "delayed") & (word_data.art_rej == 0);
    wdata{row, 'N_delayed'} = sum(idx);
    wdata{row, 'LPP_delayed'} = mean(word_data{idx, 'LPP'});
    wdata{row, 'recog_mem_delayed'} = mean(word_data{idx, 'old_resp'});

end

%Write data to csv
writetable(wdata, fullfile(st_dir, 'EmCon_WordAveraged.csv'));

%Turn warnings back on
warning('on', 'MATLAB:table:RowsAddedExistingVars');
