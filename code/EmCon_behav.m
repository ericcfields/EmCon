%Convenience function to run behavioral data processing code for EmCon
%
%AUTHOR: Eric Fields
%VERSION DATE: 6 August 2023

%Copyright (c) 2023, Eric Fields
%All rights reserved.
%This code is free and open source software made available under the terms 
%of the 3-clause BSD license:
%https://opensource.org/licenses/BSD-3-Clause

function EmCon_behav(sub_id)

    %Add directory to Python path
    main_dir = EmCon_main_dir();
    py_addpath(fullfile(main_dir, 'code'));

    %Process subject
    if strcmp(sub_id, 'all')
        py.EmCon_behav.process_all(main_dir);
    else
        py.EmCon_behav.process_sub(sub_id, main_dir);
    end

end
