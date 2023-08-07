%Add user flags indicating subsequent memory for EmCon ERP
%
%Author: Eric Fields
%Version Date: 7 August 2023

%Copyright (c) 2023, Eric Fields
%All rights reserved.
%This code is free and open source software made available under the terms 
%of the 3-clause BSD license:
%https://opensource.org/licenses/BSD-3-Clause

function EEG = EmCon_add_mem_flags(EEG, main_dir)

    %Get subject ID from EEG struct
    sub_id = EEG.subject;
    
    %Find memory files
    mem_files = get_files(fullfile(main_dir, 'psychopy'), '.csv');
    %Immediate retrieval
    ret1_file = mem_files(contains(mem_files, [sub_id '_EmCon_ret1']));
    assert(length(ret1_file) == 1);
    ret1_file = ret1_file{1};
    %Delayed retrieval
    ret2_file = mem_files(contains(mem_files, [sub_id '_EmCon_ret2']));
    if length(ret2_file) == 1
        ret2_file = ret2_file{1};
    elseif length(ret2_file) > 1
        error('There appears to be multiple delayed retrieval files for %s', sub_id);
    end
    
    %Import memory data
    warning('off', 'MATLAB:table:ModifiedAndSavedVarnames');
    ret1_data = readtable(fullfile(main_dir, 'psychopy', ret1_file), 'VariableNamingRule', 'modify');
    if ~isempty(ret2_file)
        ret2_data = readtable(fullfile(main_dir, 'psychopy', ret2_file), 'VariableNamingRule', 'modify');
        ret_data = [ret1_data; ret2_data];
    else
        ret_data = ret1_data;
    end
    
    %Find word events
    word_idx = find(ismember([EEG.EVENTLIST.eventinfo.code], [201, 202, 211, 212, 220]));
    if length(word_idx) ~= 400
        warning('There should be 400 word event codes, but there are %d', length(word_idx));
    end
    
    %Loop through word events and assign flags
    for i = word_idx
    
        %Find word and fixation event codes
        fix_ec = EEG.EVENTLIST.eventinfo(i-1).code;
        word_ec = EEG.EVENTLIST.eventinfo(i).code;
        if EEG.EVENTLIST.eventinfo(i+1).code ~= 230
            continue
        end
    
        %Find row in retrieval data matching this event
        ret_idx = (ret_data{:, 'fix_ec'} == fix_ec) & (ret_data{:, 'word_ec'} == word_ec);
    
        %Find memory responses and assign flags
        if sum(ret_idx) == 0
            
            if ~isempty(ret2_file)
                error('Could not find fixation event code = %d and word event code = %d in the retrieval data.', fix_ec, word_ec);
            end
    
        elseif sum(ret_idx) > 1
    
            error('More than one retrieval event matches fixation event code = %d and word event code = %d in the retrieval data.', fix_ec, word_ec);
    
        else
    
            %This should be an old trial
            assert(strcmp(ret_data{ret_idx, 'mem_cond'}, 'Old'));
    
            %Immediate or delayed memory?
            test_cond = ret_data{ret_idx, 'mem_test'}{1};
    
            
    
            %Find memory responses
            oldnew_resp = ret_data{ret_idx, 'oldnew_resp_keys'};
            rk_resp = ret_data{ret_idx, 'rk_resp_keys'};
    
            %Set memory flags
            if strcmp(test_cond, 'immediate')
                %Set code indicating that memory flag has been set
                EEG = set_elist_user_flag(EEG, i, 1);
                %Set memory codes based on response
                if oldnew_resp == 5
                    EEG = set_elist_user_flag(EEG, i, 2);
                    if rk_resp == 5
                        EEG = set_elist_user_flag(EEG, i, 3);
                    end
                end
            elseif strcmp(test_cond, 'delayed')
                %Set code indicating that memory flag has been set
                EEG = set_elist_user_flag(EEG, i, 4);
                %Set memory codes based on response
                if oldnew_resp == 5
                    EEG = set_elist_user_flag(EEG, i, 5);
                    if rk_resp == 5
                        EEG = set_elist_user_flag(EEG, i, 6);
                    end
                end
            end
    
        end
    
    end
    
    %Update EEG.history
    hist_command = sprintf('EEG = EmCon_add_mem_flags(EEG, ''%s'')', main_dir);
    EEG = eeg_hist(EEG, hist_command);

end


function EEG = set_elist_user_flag(EEG, event_num, flag, value)
%Set user flags in ERPLAB's EVENTLIST struct
%
%INPUTS:
% event_num - event indices in EEG.EVENTLIST.eventinfo
% flag      - flag to set for each event in event_num
% value     - value to set the flag (must be 0 or 1) {default: 1}
%
%OUTPUTS:
% EEG       - EEG struct with EVENTLIST use flags updated

    %If no value input, turn flag on
    if nargin < 4
        value = 1;
    end
    
    %Check inputs
    if ~all(ismember(value, [0, 1]))
        error('value input must be 0 or 1')
    end
    if length(value) ~= 1 && length(value) ~= length(even_num)
        error('The value parameter is not the same size as the number of events');
    end
    if length(event_num) ~= length(flag)
        error('Number of events must match number of flags');
    end
    
    %User flags start at flag 9
    flag = flag + 8;
    
    %If setting the flag to the same value for every event, resize value
    %input to match
    if length(value) == 1
        repmat(value, [1, length(event_num)]);
    end
    
    %Loop through events and update flags
    for i = 1:length(event_num)
        ev = event_num(i);
        EEG.EVENTLIST.eventinfo(ev).flag = bitset(EEG.EVENTLIST.eventinfo(ev).flag, flag(i), value(i));
    end
    
end
