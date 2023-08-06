%Return a EEG random subject
%
%INPUTS
% present  - string indicating a set type to draw subjects from; e.g.
%            'preart' {default: 'curry'}
% missing  - string indicating a set type that has not been created yet for
%            the subject; e.g., 'postart' {default: []}
% main_dir - The main study directory {default: pwd}
%
%OUTPUT
% sub_id   - string sub_id for a randomly chosen subject in the specified
%            subset
%
%EXAMPLE USAGE
% sub_id = rand_sub('raw', 'post_art', main_dir)
%
%Author: Eric Fields
%Version Date: 23 July 2023

%Copyright (c) 2023, Eric Fields
%All rights reserved.
%This code is free and open source software made available under the terms 
%of the 3-clause BSD license:
%https://opensource.org/licenses/BSD-3-Clause

function sub_id = rand_sub(present, missing, main_dir)

    %Set defaults for missing arguments
    if nargin < 3
        main_dir = pwd;
    end
    if nargin < 2
        missing = [];
    end
    if ~nargin
        present = 'curry';
    end

    subs_subset = get_subset(present, missing, main_dir);
    
    %get random subject
    if isempty(subs_subset)
        fprintf('\n\nNo subjects left!\n\n');
        sub_id = [];
    else
        sub_id = subs_subset{randi(length(subs_subset))};
    end
    
end
