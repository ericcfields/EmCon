%Make GM file from usable subjects for EmCon
%
%Author: Eric Fields
%Version Date: 8 March 2024


%% SET-UP

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


%% MAKE GM LISTS

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

%% MAKE GM ERPSETS

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
    
end
                
eeglab redraw; erplab redraw;


%% ADD MAIN EFFECT AND DIFFERENCE BINS

%Main effect bins
ERP = pop_binoperator(ERP, ...
                      {'b85 = (b8+b12)/2 label main_New_immediate', ...  
                       'b86 = (b9+b13)/2 label main_Old_immediate', ...
                       'b87 = (b72+b73)/2 label main_NotR_immediate', ...
                       'b88 = (b11+b15)/2 label main_R_immediate', ...
                       'b89 = (b24+b28)/2 label main_New_delayed', ...
                       'b90 = (b25+b29)/2 label main_Old_delayed', ...
                       'b91 = (b75+b76)/2 label main_NotR_delayed', ...
                       'b92 = (b27+b31)/2 label main_R_delayed'});
ALLERP(CURRENTERP) = ERP;

%Difference wave bins
ERP = pop_binoperator(ERP, ...
                      {'b93 = b2-b1 label diff_NEG-NEU', ...  
                       'b94 = b3-b1 label diff_animal-NEU', ...
                       'b95 = b9-b8 label diff_NEU_Immediate_Old-New', ...
                       'b96 = b13-b12 label diff_NEG_Immediate_Old-New', ...
                       'b97 = b21-b20 label diff_both_Immediate_Old-New', ...
                       'b98 = b86-b85 label diff_main_Immediate_Old-New', ...
                       'b99 = b25-b24 label diff_NEU_Delayed_Old-New', ...
                       'b100 = b29-b28 label diff_NEG_Delayed_Old-New', ...
                       'b101 = b37-b36 label diff_both_Delayed_Old-New', ...
                       'b102 = b90-b89 label diff_main_Delayed_Old-New', ...
                       'b103 = b11-b72 label diff_NEU_Immediate_R-NotR', ...
                       'b104 = b15-b73 label diff_NEG_Immediate_R-NotR', ...
                       'b105 = b27-b75 label diff_NEU_Delayed_R-NotR', ...
                       'b106 = b31-b76 label diff_NEG_Delayed_R-NotR', ...
                       'b107 = b88-b87 label diff_main_immediate_R-NotR', ...
                       'b108 = b92-b91 label diff_main_delayed_R-NotR'});
ALLERP(CURRENTERP) = ERP;

ERP = pop_savemyerp(ERP, ...
                    'erpname', sprintf('EmCon_GM%s_%dsubs', subset{i}, length(ERP.workfiles)), ...
                    'filename', sprintf('EmCon_GM%s_%dsubs.erp', subset{i}, length(ERP.workfiles)), ... 
                    'filepath', fullfile(main_dir, 'ERPsets', 'GM'), 'Warning', 'on');
ALLERP(CURRENTERP) = ERP;


%% CREATE FILTERED ERPSET

%Create filtered ERPset
ERP = pop_filterp(ERP, 1:28, 'Cutoff', lp_filt, 'Design', 'butter', 'Filter', 'lowpass', 'Order', 2);
ERP.erpname = [ERP.erpname sprintf('_%dHzLP', lp_filt)];
ERP.filename = ''; ERP.filepath = '';
CURRENTERP = CURRENTERP + 1;
ALLERP(CURRENTERP) = ERP;

eeglab redraw; erplab redraw;
