%Report rejection rate by channel
%
%INPUTS
% EEG       - EEG struct
% printout  - boolean indicating whether to print results to command window
%             {default: true}
%OUTPUT
% chan_rej_array   - simple cell array table of rejected trials by channel
% chan_rej_numeric - one dimensional array of rejection numbers in the
%                    order that channels appear in chanlocs
%
%Author: Eric Fields
%Version Date: 6 August 2023

%Copyright (c) 2023, Eric Fields
%All rights reserved.
%This code is free and open source software made available under the terms 
%of the 3-clause BSD license:
%https://opensource.org/licenses/BSD-3-Clause

function [chan_rej_array, chan_rej_numeric] = chan_rej_report(EEG, printout)
    
    %Set default input
    if nargin < 2
        printout = true;
    end

    %Simple rejected trials by channel table
    chan_rej_numeric = sum(EEG.reject.rejmanualE, 2);
    chan_rej_array = [{EEG.chanlocs.labels}' num2cell(chan_rej_numeric)];
    
    if printout
        %Split table for easier display
        split_chan_rej_array = chan_rej_array;
        if mod(length(split_chan_rej_array), 2)
            split_chan_rej_array(end+1, :) = {'', NaN};
        end
        midp = round(length(split_chan_rej_array)/2, 0);
        split_chan_rej_array = [split_chan_rej_array(1:midp, :) split_chan_rej_array(midp+1:end, :)];

        %Display at console
        fprintf('\nRejected trials by electrode: \n');
        disp(split_chan_rej_array);
        fprintf('\n\n');
    end
    
end
