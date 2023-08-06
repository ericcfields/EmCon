%Identify epochs to exclude from ICA training
%
%Author: Eric Fields
%Version Date: 2 August 2023

%Copyright (c) 2023, Eric Fields
%All rights reserved.
%This code is free and open source software made available under the terms 
%of the 3-clause BSD license:
%https://opensource.org/licenses/BSD-3-Clause

clearvars; close all; clc;

%Full path for data directory and relevant files
%Get main data directory
main_dir = EmCon_main_dir();

%Get subject
sub_id = input('\n\nSubject ID:  ','s');
if strcmpi(sub_id, 'rand')
    sub_id = rand_sub('preart', 'bad_epochs', main_dir);
    if isempty(sub_id)
        return;
    end
end

%Start EEGLAB
[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab; %#ok<ASGLU>

%Load preart set
EEG = pop_loadset('filename', [sub_id '_preart.set'], 'filepath', fullfile(main_dir, 'EEGsets'));
[ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, 0);

eeglab redraw;

%Open window for rejection
pop_eegplot(EEG, 1, 1, 0);
