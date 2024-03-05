%Psychopy crashed during presentation
%One trial got repeated when we re-started
%This script changes the event codes for the second presentation to 249
%(which is otherwise unused)
%
%Author: Eric Fields
%Version Date: 5 March 2024

%Check event numbers for repeat
assert(all([EEG.event(641:642).type] == [124, 212]));
assert(all([EEG.event(674:677).type] == [124 212 230 236]));

%Change repeat to event code 249
for enum = 674:677
    EEG.event(enum).type = 249;
end

%Update ALLEEG struct
[ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, 0);
