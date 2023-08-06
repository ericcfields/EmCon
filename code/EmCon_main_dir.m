%Define main data directory for EmCon
%
%Author: Eric Fields
%Version Date: 6 August 2023

%Copyright (c) 2023, Eric Fields
%All rights reserved.
%This code is free and open source software made available under the terms 
%of the 3-clause BSD license:
%https://opensource.org/licenses/BSD-3-Clause

function main_dir = EmCon_main_dir()

    %Define main directory
    main_dir = 'C:\Users\fieldsec\OneDrive - Westminster College\Documents\ECF\Research\EmCon\DATA';
    
    %Make sure the directory exists
    if ~exist(main_dir, 'dir')
        error('%s does not exist.\nPlease update EmCon_main_dir.m', main_dir)
    end
    
end
