%Mass univariate statistical anlysis for EmCon
%
%Author: Eric Fields
%Version Date: 29 February 2024

%% Set-up

%Make sure all EEGLAB functions are on the MATLAB path
[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;
clearvars; close all;

%Paths
main_dir = 'C:\Users\fieldsec\OneDrive - Westminster College\Documents\ECF\Research\EmCon\DATA';
cd(fullfile(main_dir, 'stats', 'erp'));

%Load GND
load(fullfile(main_dir, 'stats', 'erp', 'EmCon_128Hz.GND'), '-mat');

%Parameters
n_perm = 1e4;
thresh_p = 0.01;
chan_hood = 70;


%% Valence analysis

%Define some variables
time_windows = {[300, 1000], [0, 1100]};
chans        = {{'CP3', 'CPZ', 'CP4', 'P3', 'PZ', 'P4'}, {GND.chanlocs.labels}};

for i = 1:length(time_windows)
    
    time_wind = time_windows{i};

    %Full factorial design
    GND = FclustGND(GND, ...
                    'bins', 1:2, ...  
                    'factor_names', 'Valence', ...  
                    'factor_levels', 2, ...
                    'time_wind', time_wind, ...
                    'include_chans', chans{i}, ...
                    'chan_hood', chan_hood, ...
                    'n_perm', n_perm, ...
                    'thresh_p', thresh_p, ...
                    'save_GND', 'no', ...
                    'output_file', fullfile('results', sprintf('EmCon_Valence_%d-%d.xlsx', time_wind(1), time_wind(2))), ...
                    'verblevel', 2);
                
end


%% Save GND

%Save GND with resutls
GND = save_matmk(GND, 'SRME2_128Hz_wResults.GND', GND.filepath, 1);

