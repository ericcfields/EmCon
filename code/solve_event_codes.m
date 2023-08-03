%Why are we missing some of event code 230?

clearvars; close all;

main_dir = EmCon_main_dir();
sub_id = 'P1_EmCon';

[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab; %#ok<ASGLU>

%Load existing raw set
fprintf('\nRaw set already exists. Loading %s\n\n', fullfile(main_dir, 'EEGsets', [sub_id '_raw.set']));
EEG = pop_loadset('filename', [sub_id '_raw.set'], 'filepath', fullfile(main_dir, 'EEGsets'));
[ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, 0);

%Get events
[ec_counts, all_events] = get_event_code_counts(EEG);

%What happends before and after 230
b4_230 = [];
after_230 = [];
for i = 1:length(all_events)
    if all_events(i) == 230
        b4_230 = [b4_230 all_events(i-1)]; %#ok<AGROW>
        after_230 = [after_230 all_events(i+1)]; %#ok<AGROW>
    end
end
%Report
[B, BG] = groupcounts(b4_230');
disp('Event codes before 230');
disp([B BG]);
[B, BG] = groupcounts(after_230');
disp('Event codes after 230');
disp([B BG]);

eeglab redraw;
