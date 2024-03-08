%Event triggers were recorded twice for 21_EmCon
%
%Author: Eric Fields
%Version Date: 8 March 2024

%Find repeats and build logical array indexing non-repeats
keep_idx = true(size(EEG.event));
for ev = 2:length(EEG.event)
    if (EEG.event(ev).type == EEG.event(ev-1).type) && ((EEG.event(ev).latency - EEG.event(ev-1).latency) < 50)
        keep_idx(ev) = false;
    end
end

%Update events to only include non-repeats
EEG.event = EEG.event(keep_idx);

[ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);
