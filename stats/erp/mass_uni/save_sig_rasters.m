function save_sig_rasters(GND, t, save_dir, file_prefix, filetype)
%For a given test in the GND, show and save raster plots only for effects
%with significant time points

%Author:Eric Fields
%Version Date: 3 April 2024
    
    %Assign default values to missing variables
    if nargin < 4
        file_prefix = GND.exp_desc;
    end
    if nargin < 5
        filetype = '.tif';
    end

    if ~isempty(file_prefix) && ~strcmp(file_prefix(end), '_')
        file_prefix = [file_prefix '_'];
    end

    if length(GND.F_tests(t).factors) == 1

        if any(any(GND.F_tests(t).null_test))
            F_sig_raster(GND, t, 'use_color', 'rgb', 'x_ticks', 0:200:1000);
            saveas(gcf, fullfile(save_dir, sprintf('%s%s.%s', file_prefix, GND.F_tests(t).factors{1}, filetype)));
        end
    
    else
    
        for f = 1:length(GND.F_tests(t).factors)
            if any(any(GND.F_tests(t).null_test.(GND.F_tests(t).factors{f})))
                F_sig_raster(GND, length(GND.F_tests), 'effect', GND.F_tests(t).factors{f}, 'use_color', 'rgb', 'x_ticks', 0:200:1000);
                saveas(gcf, fullfile(save_dir, sprintf('%s%s.%s', file_prefix, GND.F_tests(t).factors{f}, filetype)));
            end
        end
    
    end

end