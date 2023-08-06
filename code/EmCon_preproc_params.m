%Processing parameters for EmCon
%
%Author: Eric Fields
%Version Date: 6 August 2023

%Copyright (c) 2023, Eric Fields
%All rights reserved.
%This code is free and open source software made available under the terms 
%of the 3-clause BSD license:
%https://opensource.org/licenses/BSD-3-Clause

%Get main data directory
main_dir = EmCon_main_dir();

%Channel locations information
% chanlocs_file = fullfile(fileparts(which('eeglab.m')), 'plugins/dipfit5.1/standard_BESA/standard-10-5-cap385.elp');

%Channels to remove immediately after import 
%(set to empty cell array to keep all chanels)
remove_chans = {'TRIGGER', 'F11', 'F12', 'FT11', 'FT12'};

%New sampling rate 
%(set to false if you do not want to resample)
resample_rate = false;

%Reference electrodes
ref_chans = {'M1', 'M2'};

%Event code shift
%(set to false if no shift is needed)
ec_shift = false;

%Code used to denote boundary events
boundary_code = 'boundary';

%Minimum gap size (in ms) for deleting gaps/breaks and buffer to leave on each side
%set gap_thresh = false to leave all data
gap_thresh = 20e3;
gap_buffer = 10e3;

%Filtering for continuous data
%High-pass filters should be applied here; low pass filters can be applied later
high_pass = 0.1;
low_pass  = false;

%Epoch information
epoch_time    = [-250, 1150];
baseline_time = [-200, -1];

%Bin descriptor file
bin_desc_file = fullfile(main_dir, 'code', 'EmCon_bin_desc.txt');
