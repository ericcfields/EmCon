%Make GM file from usable subjects for EmCon
%
%Author: Eric Fields
%Version Date: 1 December 2023

%% Set-up

clearvars; close all;

%Full path for data directory and relevant files
main_dir = EmCon_main_dir();

%Usability status from data log to include in ERPs
use_status = {'YES', 'PROBABLY', 'MAYBE'};

%Low pass filter to use for viewing
lp_filt = 15;

%Delete current GM files and lists
cd(fullfile(main_dir, 'ERPsets', 'GM'))
delete *.erp
delete EmCon_GM_list.txt
% delete *.txt
cd(main_dir);


%% Make GM lists

%Get array of usable subjects
data_log = readcell(fullfile(main_dir, 'EmCon_EEG_DataLog.xlsx'));
data_log = data_log(cellfun(@ischar, data_log(:, 3)), :);
usable_subs = data_log(ismember(data_log(:,3), use_status));

%Create text file of usabel ERPsets
gm_list_file = fullfile(main_dir, 'ERPsets', 'GM', 'EmCon_gm_list.txt');
f_gm = fopen(gm_list_file, 'wt');
for i = 1:length(usable_subs)
    sub_id = usable_subs{i};
    fprintf(f_gm, '%s\\ERPsets\\%s.erp\n', main_dir, sub_id);
end
fclose(f_gm);

%% Make GM ERPsets

subset = {''};

[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;

for i = 1:length(subset)
    
    sub_list = fullfile(main_dir, 'ERPsets', 'GM', sprintf('EmCon_gm_list%s.txt', subset{i}));

    %Create GM ERP for AGAT
    ERP = pop_gaverager(sub_list, 'Criterion', 35, 'ExcludeNullBin', 'on', 'SEM', 'on', 'Weighted', 'on');
    ERP.subject = '';
    ALLERP = ERP; 
    CURRENTERP = 1;
    ERP = pop_savemyerp(ERP, 'erpname', sprintf('EmCon_GM%s_%dsubs_WEIGHTED', subset{i}, length(ERP.workfiles)), ...
                        'filename', sprintf('EmCon_GM%s_%dsubs_WEIGHTED.erp', subset{i}, length(ERP.workfiles)), ... 
                        'filepath', fullfile(main_dir, 'ERPsets', 'GM'), 'Warning', 'on');
    ALLERP(CURRENTERP) = ERP;

    %Average usable ERPsets
    ERP = pop_gaverager(sub_list, 'Criterion', 35, 'ExcludeNullBin', 'on', 'SEM', 'on', 'Weighted', 'off');
    ERP.subject = '';
    CURRENTERP = CURRENTERP + 1;
    ALLERP(CURRENTERP) = ERP;
    ERP = pop_savemyerp(ERP, 'erpname', sprintf('EmCon_GM%s_%dsubs', subset{i}, length(ERP.workfiles)), ...
                        'filename', sprintf('EmCon_GM%s_%dsubs.erp', subset{i}, length(ERP.workfiles)), ... 
                        'filepath', fullfile(main_dir, 'ERPsets', 'GM'), 'Warning', 'on');
    ALLERP(CURRENTERP) = ERP;
    %Create filtered ERPset
    ERP = pop_filterp(ERP,  1:28 , 'Cutoff', lp_filt, 'Design', 'butter', 'Filter', 'lowpass', 'Order', 2);
    ERP.erpname = [ERP.erpname sprintf('_%dHzLP', lp_filt)];
    ERP.filename = ''; ERP.filepath = '';
    CURRENTERP = CURRENTERP + 1;
    ALLERP(CURRENTERP) = ERP;
    
end
                
eeglab redraw; erplab redraw;
