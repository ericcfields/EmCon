%Convenience function to run behavioral data processing code for EmCon
%
%AUTHOR: Eric Fields
%VERSION DATE: 5 August 2023

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
