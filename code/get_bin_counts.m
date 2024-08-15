%Get counts of non-rejected trials and rejection rates for all bins for all subs
%
%Author: Eric Fields
%Version Date: 15 August 2024

clearvars; close all;

%Study-specific parameters
main_dir = EmCon_main_dir();
study_name = 'EmCon';

%Find all subjecst with an artifact corrected EEGset
sub_ids = get_subset('postart', [], main_dir);

bin_counts = table;
rej_rate = table;
row = 0;
for s = 1:length(sub_ids)

    row = row + 1;

    sub_id = sub_ids{s};

    [ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab; %#ok<ASGLU>

    %Load post-art dataset
    EEG = pop_loadset('filename',[sub_id '_postart.set'], ...
                      'filepath',fullfile(main_dir, 'EEGsets'));
    [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, 0);

    %Calculate non-rejected trial numbers and rejection rate for each bin
    [~, ~, ~, rej_by_bin] = pop_summary_AR_eeg_detection(EEG, 'none');
    trials_per_bin = EEG.EVENTLIST.trialsperbin - rej_by_bin;
    pct_per_bin = rej_by_bin ./ EEG.EVENTLIST.trialsperbin;

    %Add subject ID to this row
    bin_counts{row, 'sub_id'} = string(sub_id);
    rej_rate{row, 'sub_id'} = string(sub_id);

    %Get bin names and make sure they match
    bin_names = {EEG.EVENTLIST.bdf.description};
    bin_names = cellfun(@(x) strtrim(x), bin_names, 'UniformOutput', false);
    if s > 1
        if ~isequal(bin_counts.Properties.VariableNames(2:end), bin_names)
            error('Bin names do not match for %s', sub_id);
        end
        if ~isequal(rej_rate.Properties.VariableNames(2:end-1), bin_names)
            error('Bin names do not match for %s', sub_id);
        end
    end

    %Add bin counts to tables
    bin_counts{row, bin_names} = trials_per_bin;
    rej_rate{row, bin_names} = pct_per_bin;
    rej_rate{row, 'TOTAL'} = 1 - sum(trials_per_bin(1:3)) / sum(EEG.EVENTLIST.trialsperbin(1:3));

end

writetable(bin_counts, fullfile(main_dir, 'belist', sprintf('%s_all_bin_counts.csv', study_name)));
writetable(rej_rate, fullfile(main_dir, 'belist', sprintf('%s_all_rej_rate.csv', study_name)));

