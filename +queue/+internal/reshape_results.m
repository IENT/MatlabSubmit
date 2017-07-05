function [varargout] = reshape_results(para_set, conf, output_collector)
%RESHAPE_RESULTS rashape output collector to results struct containing arrays
% 
%     [data] = RESHAPE_RESULTS(input) creates a result struct 'data' that has the same structure as the 
%     output struct of the simulation function. All results of one ouput parameter will be stored inside
%     a multidimensional array at the corresponding place inside the structure. The different dimensions 
%     are associated with the different input parameters. If the output parameters are multidimensional 
%     themselves (and sizes don't change) those dimensions are appended to the ones of input parameters.
% 
%     'input' has to be either the configuration struct 'conf' or the result directory
%     of the simulation.
% 
%     [data, para_names] = RESHAPE_RESULTS(input) additionally returns
%     a list of the input parameters labelling the dimensions of the arrays inside 'data'.
%     For example, para_names{3} = 'var3' means that the third dimension of the arrays
%     corresponds to the parameter called 'var3'
% 
%     [data, para_names, para_values] = RESHAPE_RESULTS(input) also returns the values
%     that were used in the order as they are indexed in the arrays inside 'data'.
%     For example, para_values{2}{5} is the fifth value of the second parameter
%     and is associated with the index 5 of dimension 2 of the arrays.
%
% Copyright (c) 2017, Christian Rohlfing, Julian Becker, Jens Schneider, Patrick Wilken, Tobias Kabzinski    

    results = struct();
    data = struct();
    
    % Initialize run ids
    run_id_current = para_set.int_comb_count * para_set.ext_comb_count;
    run_id = 0;

    % Check if results.mat exists
    results_path = [conf.result_dir, filesep, conf.job_name, filesep, 'results.mat'];
    if exist(results_path, 'file')
        load(results_path, 'run_id');          
    end

    % Check if results have been collected before (then run ids are equal)
    if run_id_current ~= run_id
        
        % Load output_collector if not given
        if nargin < 3
            fprintf('Loading full.mat...\n\n')
            load([conf.result_dir, filesep, conf.job_name, filesep, 'full.mat'], 'output_collector')
        end
        
        % Remove singelton parameters to make data array more compact
        I_non_singelton = cellfun(@(x) length(x) ~= 1, para_set.para_values);
        para_names = para_set.para_names(I_non_singelton);
        para_values = para_set.para_values(I_non_singelton);
        
        % Workaround if the only parameter was directly assigned to the output of the simulation function
        if ~isstruct(output_collector{1}.data)
    
            % Put data into measure ''output''
            for combo_id = 1:length(output_collector) 
                value = output_collector{combo_id}.data;
                output_collector{combo_id}.data = []; % suppresses warning
                output_collector{combo_id}.data.output = value; 
            end
            
            warning(['The output of the simulation function should be a structure of the form ''output.measure_name'', '...
                     'even for a single measure. Storing results as default measure ''output''.'])
        end
        
        % Get number of parameter values and measure names 
        num_of_values = cellfun(@numel, para_values);
        measures = queue.internal.get_para_names(output_collector{1}.data);
    
        % Treat each measure seperately
        for measure_id = 1:length(measures)

            % Read all data of this measure from output collector
            data_current = cellfun(@(x) queue.internal.getfield_by_str(x.data, measures{measure_id}), output_collector, 'UniformOutput', false);
            
            % Check if measure values can be directly concatenated into array
            reshaped_flag = false;
            % Strings do not work because they will be combined when concatenated
            if ~ischar(data_current{1})
                % Class has to be the same for all values
                first_class = class(data_current{1});
                equal_classes = cellfun(@(x) isequal(class(x), first_class), data_current);
                if all(equal_classes)
                    % Size has to be the same for all values
                    first_size = size(data_current{1});
                    equal_sizes = cellfun(@(x) isequal(size(x), first_size), data_current);
                    if all(equal_sizes)
                        % Get measure dimensions
                        reshape_size = first_size(1:find(first_size ~= 1, 1, 'last'));
                        
                        % Create reshaped array using parameter and measure dimensions
                        if length([reshape_size, num_of_values']) > 1
                            data_current = reshape([data_current{:}], [reshape_size, num_of_values']);
                        else
                            % Just assign one- or zerodimensional data
                            data_current = cell2mat(data_current)';
                        end
                        
                        % Shift dimensions so that measure dimensions are last
                        if ~isvector(data_current)
                            data_current = shiftdim(data_current, length(reshape_size));                          
                        end
                        
                        reshaped_flag = true;
                    end
                end
            end    

            % Just reshape cell array if measures cannot be concatenated
            if ~reshaped_flag && length(num_of_values) > 1
                data_current = reshape(data_current, num_of_values');
            end    
            
            % Store data to output struct
            data = queue.internal.setfield_by_str(data, measures{measure_id}, data_current);
            if mod(measure_id,round(length(measures)/10))==0
                fprintf('.');
            end
        end

        % Save results
        fprintf('Saving results.mat...\n\n')
        
        results_path = [conf.result_dir, filesep, conf.job_name, filesep, 'results.mat'];
        run_id = para_set.int_comb_count * para_set.ext_comb_count; %#ok<NASGU>
        save(results_path, 'data', 'para_names', 'para_values', 'run_id', '-v7');

        fprintf('Results can be found here:\n %s\n', results_path);
        
        if nargout > 0
            results.data = data;
            results.para_names = para_names;
            results.para_values = para_values;
        end

    else
        % User output if nothing to be done
        disp('Collect results has already been performed before.');
        fprintf('Results can be found here:\n%s\n\n', results_path);
        
        % Ask if results should be returned
        reply = input('Do you want to load them? [Y/n]\n', 's');
        if ~strcmpi(reply, 'n')
            fprintf('Loading results.mat...\n\n')
            results = load(results_path, 'data', 'para_names', 'para_values');
        end
    end

    if nargout > 0
        varargout{1} = results;
    end
end