%05_EmCon was run with the wrong input for which button indicated animal
%Event codes need to be changed to reflect the correct responses
%
%Author: Eric Fields
%Version Date: 5 March 2024

%Fix response button event codes
for enum = 1:length(EEG.event)
    if EEG.event(enum).type == 235
        EEG.event(enum).type = 236;
    elseif EEG.event(enum).type == 236
        EEG.event(enum).type = 235;
    end
end

%Update EEG
[ALLEEG, EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
