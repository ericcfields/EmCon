%Save list of bad epochs to exclude from ICA training
%
%First, mark bad epochs via visual inspectsion
%This script will then save a list of the marked epochs, which the ICA
%script can use later
%
%Author: Eric Fields
%Version Date: 9 August 2023

%Copyright (c) 2023, Eric Fields
%All rights reserved.
%This code is free and open source software made available under the terms 
%of the 3-clause BSD license:
%https://opensource.org/licenses/BSD-3-Clause

%Get bad epochs
bad_epochs = EEG.reject.rejmanual;
assert(length(bad_epochs) == EEG.trials);
%Save bad epochs
writematrix(bad_epochs', fullfile(main_dir, 'ICA', [sub_id '_bad_epochs.csv']));

%Check if enough data is left for ICA
if ((128/EEG.srate) * EEG.pnts * sum(~bad_epochs) < 30 * length(EEG.chanlocs)^2)
    warndlg('You may not have enough data points for reliable ICA training');
end

%Exclude channels
exc_chan_idx = listdlg('ListString', {EEG.chanlocs.labels}, ... 
                       'PromptString', 'Choose electrodes to exclude from ICA:', ...
                       'ListSize', [250, 300], ...
                       'OKString', 'Exclude', ...
                       'CancelString', 'Use all channels');
if isempty(exc_chan_idx)
    exc_chan_idx = 0;
end
writematrix(exc_chan_idx', fullfile(main_dir, 'ICA', [sub_id '_exclude_chans.csv']));

%Report percent bad
fprintf('\n%.2f%% of epochs rejected\n\n', mean(bad_epochs)*100);

%Report exclusion electrodes
if ~exc_chan_idx
    fprintf('\nICA will use all channels\n\n');
else
    fprintf('\nThe following electrodes will be excluded from ICA:\n'); 
    fprintf('%s ', EEG.chanlocs(exc_chan_idx).labels);
    fprintf('\n\n');
end
