%Returns the number of occurences of each event code in an EEGset
%
%INPUTS
% EEG         - An EEGLAB EEGset
% output_file - A .csv or .txt file to write output to. (Optional: default
%               is no output file)
%
%OUTPUT
% ec_counts   - an array with the number of occurences of each event code
%               1 through 255
% all_events  - a simple array of every event code in the EEGset in order
%
%USAGE EXAMPLE
% [ec_counts, all_events] = get_event_code_counts(EEG, 'ec_counts.csv');
%
%Author: Eric Fields
%Version Date: 12 March 2019

%Copyright (c) 2023, Eric Fields
%All rights reserved.
%This code is free and open source software made available under the terms 
%of the 3-clause BSD license:
%https://opensource.org/licenses/BSD-3-Clause

function [ec_counts, all_events] = get_event_code_counts(EEG, output_file)
    
    %Default to no output file
    if nargin < 2
        output_file = false;
    end
    
    %Get a simple array of all events in EEGset
    %(Some sets have triggers as strings, some as numbers)
    if isa(EEG.event(1).type, 'char')
        all_events = {EEG.event.type}';
        all_events = all_events(~strcmpi(all_events, 'boundary'));
        all_events = cellfun(@str2num, all_events);
    else
        all_events = cell2mat({EEG.event.type})';
    end
    
    %Check that only codes 1 - 255 exist
    all_event_codes = unique(all_events);
    if ~all(ismember(all_event_codes, 1:255))
        error('get_event_code_counts assumes that only codes 1-255 are possible, but other event codes were found.');
    end
    
    %Get counts for all possible event codes
    ec_counts = NaN(255, 2);
    for ec = 1:255
        ec_counts(ec, 1) = ec;
        ec_counts(ec, 2) = sum(all_events == ec);
    end
    
    %Output to file if requested
    if output_file
        %Determine csv or tab separated
        if strcmpi('.csv', output_file(end-3:end))
            csep = ',';
        else
            csep = sprintf('\t');
        end
        %Write file
        f_out = fopen(output_file, 'wt');
        fprintf(f_out, 'event_code%scount\n', csep); %header
        for i = 1:length(ec_counts)
            fprintf(f_out, '%d%s%d\n', ec_counts(i, 1), csep, ec_counts(i, 2));
        end
        fclose(f_out);
    end
    
end
