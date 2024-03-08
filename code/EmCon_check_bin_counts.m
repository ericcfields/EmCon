%Check bin counts for EmCon
%
%Author: Eric Fields
%Version Date: 8 March 2024

function EmCon_check_bin_counts(EEG)

    %Main bins
    if ~all(EEG.EVENTLIST.trialsperbin(1:3) == [200, 200, 40])
        warning('Bin counts are wrong for bins 1-3');
    end
    
    %Make sure remembered and forgotten bins add up to total
    if sum(EEG.EVENTLIST.trialsperbin(8:9)) ~= 100
        warning('Immediate NEU memory bin counts are wrong')
    end
    if sum(EEG.EVENTLIST.trialsperbin(12:13)) ~= 100
        warning('Immediate NEG memory bin counts are wrong')
    end
    
    if sum(EEG.EVENTLIST.trialsperbin(24:25)) ~= 100
        warning('Delayed NEU memory bin counts are wrong')
    end
    if sum(EEG.EVENTLIST.trialsperbin(28:29)) ~= 100
        warning('Delayed NEG memory bin counts are wrong')
    end
    
    %Make sure R & K and up to old
    if EEG.EVENTLIST.trialsperbin(9) ~= sum(EEG.EVENTLIST.trialsperbin(10:11))
        warning('R and K do not add up to Old for NEU immediate');
    end
    if EEG.EVENTLIST.trialsperbin(13) ~= sum(EEG.EVENTLIST.trialsperbin(14:15))
        warning('R and K do not add up to Old for NEG immediate');
    end
    if EEG.EVENTLIST.trialsperbin(17) ~= sum(EEG.EVENTLIST.trialsperbin(18:19))
        warning('R and K do not add up to Old for animal immediate');
    end
    if EEG.EVENTLIST.trialsperbin(21) ~= sum(EEG.EVENTLIST.trialsperbin(22:23))
        warning('R and K do not add up to Old for both immediate');
    end
    if EEG.EVENTLIST.trialsperbin(25) ~= sum(EEG.EVENTLIST.trialsperbin(26:27))
        warning('R and K do not add up to Old for NEU delayed');
    end
    if EEG.EVENTLIST.trialsperbin(29) ~= sum(EEG.EVENTLIST.trialsperbin(30:31))
        warning('R and K do not add up to Old for NEG delayed');
    end
    if EEG.EVENTLIST.trialsperbin(33) ~= sum(EEG.EVENTLIST.trialsperbin(34:35))
        warning('R and K do not add up to Old for animal delayed');
    end
    if EEG.EVENTLIST.trialsperbin(37) ~= sum(EEG.EVENTLIST.trialsperbin(38:39))
        warning('R and K do not add up to Old for both delayed');
    end
    
    %Make sure NEU + NEG adds up to "both" bins
    if EEG.EVENTLIST.trialsperbin(20) ~= sum(EEG.EVENTLIST.trialsperbin([8, 12]))
        warning('NEU and NEG do not add up to both for immediate new');
    end
    if EEG.EVENTLIST.trialsperbin(21) ~= sum(EEG.EVENTLIST.trialsperbin([9, 13]))
        warning('NEU and NEG do not add up to both for immediate old');
    end
    if EEG.EVENTLIST.trialsperbin(37) ~= sum(EEG.EVENTLIST.trialsperbin([25, 29]))
        warning('NEU and NEG do not add up to both for delayed old');
    end
    if EEG.EVENTLIST.trialsperbin(36) ~= sum(EEG.EVENTLIST.trialsperbin([24, 28]))
        warning('NEU and NEG do not add up to both for delayed new');
    end
    
    %Make sure new and K add up to NotR
    if EEG.EVENTLIST.trialsperbin(72) ~= sum(EEG.EVENTLIST.trialsperbin([8, 10]))
        warning('New and K do not add up to NotR for NEU immediate');
    end
    if EEG.EVENTLIST.trialsperbin(73) ~= sum(EEG.EVENTLIST.trialsperbin([12, 14]))
        warning('New and K do not add up to NotR for NEG immediate');
    end
    if EEG.EVENTLIST.trialsperbin(74) ~= sum(EEG.EVENTLIST.trialsperbin([16, 18]))
        warning('New and K do not add up to NotR for animal immediate');
    end
    
    if EEG.EVENTLIST.trialsperbin(75) ~= sum(EEG.EVENTLIST.trialsperbin([24, 26]))
        warning('New and K do not add up to NotR for NEU delayed');
    end
    if EEG.EVENTLIST.trialsperbin(76) ~= sum(EEG.EVENTLIST.trialsperbin([28, 30]))
        warning('New and K do not add up to NotR for NEG delayed');
    end
    if EEG.EVENTLIST.trialsperbin(77) ~= sum(EEG.EVENTLIST.trialsperbin([32, 34]))
        warning('New and K do not add up to NotR for animal delayed');
    end
    
    %Check accuracy
    bin_names = {EEG.EVENTLIST.bdf.description};
    bin_names = cellfun(@(x) strtrim(x), bin_names, 'UniformOutput', false);
    for bn = 1:length(bin_names)
    
        bin_name = strtrim(bin_names{bn});
    
        if contains(bin_name, '_corr')
            continue;
        end
    
        corr_bn = find(strcmp(bin_names, [bin_name '_corr']));
        assert(length(corr_bn)==1);
    
        if (EEG.EVENTLIST.trialsperbin(corr_bn) / EEG.EVENTLIST.trialsperbin(bn)) < 0.8
            warning('Accuracy is under 0.8 for %s', bin_name);
        end
    
    end

end
