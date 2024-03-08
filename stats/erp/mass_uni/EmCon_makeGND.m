%Make GND variable & file for EmCon
%
%Author: Eric Fields
%Version Date: 8 March 2024

clearvars; close all;

main_dir = 'C:\Users\fieldsec\OneDrive - Westminster College\Documents\ECF\Research\EmCon\DATA';
mua_dir = fullfile(main_dir, 'stats', 'erp', 'mass_uni');

%Get files to include in GND
sub_files = strsplit(fileread(fullfile(main_dir, 'ERPsets\GM\EmCon_gm_list.txt')), '\n');
sub_files = sub_files(contains(sub_files, '.erp'));
sub_files = cellfun(@(x) strtrim(x), sub_files, 'UniformOutput', false);


%% Filter and strip impedance values

lp_thresh = 10;
overwrite = false;

for i =  1:length(sub_files)

    %Load ERP
    sub_file = sub_files{i};
    [erp_dir, sub_id] = fileparts(sub_file);

    %Skip existing filtered sets
    filt_setname = sprintf('%s_%dHzLP.erp', sub_id, lp_thresh);
    if exist(fullfile(erp_dir, filt_setname), 'file') && ~overwrite
        fprintf('\n%s already exists (skipping)\n', filt_setname);
        continue;
    end

    %Start/clear EEGLAB
    [~, ~, ~, ~] = eeglab;
    
    fprintf('\nCreating %s\n', filt_setname);

    %Load ERP
    ERP = pop_loaderp('filename', [sub_id '.erp'], 'filepath', erp_dir);

    %Filter ERP
    ERP = pop_filterp(ERP, 1:28, 'Cutoff', lp_thresh, 'Design', 'butter', 'Filter', 'lowpass', 'Order', 2);

    %Remove impedance from chanlocs
    ERP.chanlocs = rmfield(ERP.chanlocs, 'impedance');
    ERP.chanlocs = rmfield(ERP.chanlocs, 'median_impedance');

    %Save
    ERP = pop_savemyerp(ERP, 'erpname', sprintf('%s_%dHzLP', sub_id, lp_thresh), ... 
                        'filename', filt_setname, ... 
                        'filepath', erp_dir, 'Warning', 'off');

end


%% Create GND

%Change directory to make saving GND easy
cd(mua_dir);

%List of filtered ERPs to include in GND
filt_sub_files = cellfun(@(x) [x(1:end-4) '_10HzLP.erp'], sub_files, 'UniformOutput', false);

%Create a GND structure
GND = erplab2GND(filt_sub_files, ...
                 'exclude_chans', {'VEOG', 'HEOG', 'blink'}, ...
                 'exp_name', 'EmCon', ...
                 'out_fname', 'EmCon.GND', ...
                 'bsln', [-200, -1]);

%Downsample the data in the GND from 512Hz to 128 Hz using boxcar filter
%Filter averages together each time point with the surrounding 2 time
%points
GND = decimateGND(GND, 4, 'boxcar', [-200 -1], 'yes', 0);

% Visually examine data
gui_erp(GND)
