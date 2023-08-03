%Define main data directory for EmCon
%
%Author: Eric Fields
%Version Date: 1 August 2023

function main_dir = EmCon_main_dir()

    %Defin main directory
    main_dir = 'C:\Users\fieldsec\OneDrive - Westminster College\Documents\ECF\Research\EmCon\DATA';
    
    %Make sure the directory exists
    if ~exist(main_dir, 'dir')
        error('%s does not exist.\nPlease update EmCon_main_dir.m', main_dir)
    end
    
end
