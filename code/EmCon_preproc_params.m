%Processing parameters for EmCon
%
%Author: Eric Fields
%Version Date: 5 August 2023

%Get main data directory
main_dir = EmCon_main_dir();

%Channel locations information
% chanlocs_file = fullfile(fileparts(which('eeglab.m')), 'plugins/dipfit5.1/standard_BESA/standard-10-5-cap385.elp');

%Bin descriptor file
bin_desc_file = fullfile(main_dir, 'code', 'EmCon_bin_desc.txt');

%Code used to denote boundary events
boundary_code = 'boundary';

%Reference electrodes
ref_chans = {'M1', 'M2'};

%Filtering for continuous data
%High-pass filters should be applied here; low pass filters can be applied later
high_pass = 0.1;
low_pass  = false;

%Epoch information
epoch_time    = [-250, 1150];
baseline_time = [-200, -1];

%Empty channels to remove
remove_chans = {'TRIGGER', 'F11', 'F12', 'FT11', 'FT12'};

%New sampling rate
resample_rate = false;

%Event code shift
ec_shift = false;
