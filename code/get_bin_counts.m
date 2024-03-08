%Get counts of non-rejected trials for all bins for all subs
%
%Author: Eric Fields
%Version Date: 8 March 2024

%Study-specific parameters
main_dir = EmCon_main_dir();
study_name = 'EmCon';

%Find all subjecst with an artifact corrected EEGset
sub_ids = get_subset('postart', [], main_dir);

bin_counts = table;
row = 0;
for i = 1:length(sub_ids)

    row = row + 1;

    sub_id = sub_ids{i};

    [ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab; %#ok<ASGLU>

    %Load post-art dataset
    EEG = pop_loadset('filename',[sub_id '_postart.set'], ...
                      'filepath',fullfile(main_dir, 'EEGsets'));
    [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, 0);

    %Calculate non-reject trial numbers for each bin
    [~, ~, ~, rej_by_bin] = pop_summary_AR_eeg_detection(EEG, 'none');
    trials_per_bin = EEG.EVENTLIST.trialsperbin - rej_by_bin;

    %Add subject ID to this row
    bin_counts{row, 'sub_id'} = string(sub_id);

    %Get bin names and make sure they match
    bin_names = {EEG.EVENTLIST.bdf.description};
    bin_names = cellfun(@(x) strtrim(x), bin_names, 'UniformOutput', false);
    if i > 1
        if ~isequal(bin_counts.Properties.VariableNames(2:end), bin_names)
            error('Bin names do not match for %s', sub_id);
        end
    end

    %Add bin counts to table
    bin_counts{row, bin_names} = trials_per_bin;

end

writetable(bin_counts, fullfile(main_dir, 'belist', sprintf('%s_all_bin_counts.csv', study_name)));
