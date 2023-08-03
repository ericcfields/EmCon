%Create an ERPset from a postart EEGset
%
%Author: Eric Fields
%Version Date: 2 August 2023


%% Paremeters and Set-up

%Half-amplitude cutoff of filter for viewing ERP data
lp_cutoff = 15;

%Get main data directory
if ~exist('main_dir', 'var')
    main_dir = EmCon_main_dir();
end

%If batch_proc variable is not set, we aren't batch processing
if ~exist('batch_proc', 'var')
    batch_proc = false;
end


%% Make ERP

%Create ERP
ERP = pop_averager(ALLEEG, 'Criterion', 'good', 'DSindex', CURRENTSET, 'ExcludeBoundary', 'on', 'SEM', 'on');
if isempty(ALLERP)
    ALLERP = ERP;
    CURRENTERP = 1;
else
    CURRENTERP = CURRENTERP + 1;
    ALLERP(CURRENTERP) = ERP;
end

%Add bins
%TO DO

%Save ERP
if batch_proc
    erp_overwrite_warn = 'off'; %#ok<UNRCH>
else
    erp_overwrite_warn = 'on';
end
ERP = pop_savemyerp(ERP, 'erpname', sub_id, 'filename', [sub_id '.erp'], 'filepath', fullfile(main_dir, 'ERPsets'), 'Warning', erp_overwrite_warn);
ALLERP(CURRENTERP) = ERP;


%% Create filtered set for viewing

if ~batch_proc
    ERP = pop_filterp(ERP, 1:num_chans, 'Cutoff', lp_cutoff, 'Design', 'butter', 'Filter', 'lowpass', 'Order', 2);
    ERP.erpname = sprintf('%s_%dHzLP', ERP.erpname, lp_cutoff);
    ERP.filename = ''; ERP.filepath = '';
    CURRENTERP = CURRENTERP + 1;
    ALLERP(CURRENTERP) = ERP;
end


%% Plot for quality check

if ~batch_proc

    bin_sets = {[5, 6]};
    for b = 1:length(bin_sets)
        bins = bin_sets{b};
        ERP = pop_ploterps(ERP, [1, 2], [1:28, 30], ...
                           'AutoYlim', 'on', ...
                           'Axsize', [ 0.05 0.08], ...
                           'BinNum', 'on', ...
                           'Blc', 'no', ...
                           'Box', [ 6 5], ...
                           'ChLabel', 'on', ...
                           'FontSizeChan',  10, ...
                           'FontSizeLeg',  12, ...
                           'FontSizeTicks',  10, ...
                           'LegPos', 'bottom', ...
                           'Linespec', {'k-' , 'r-' }, ...
                           'LineWidth',  1, ...
                           'Maximize', 'on', ...
                           'Style', 'Classic', ...
                           'Tag', 'ERP_figure', ...
                           'Transparency',  0, ...
                           'xscale', [ -200.0, 800.0, -200:200:800], ...
                           'YDir', 'reverse' );            
    end

    clear plotset; %Prevents error when trying to use the GUI for additional plotting

    eeglab redraw;
    erplab redraw;

end
