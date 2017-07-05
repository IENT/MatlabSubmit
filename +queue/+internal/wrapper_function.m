function [varargout] = wrapper_function(task_id, job_name, tmpdir, intermediatedir, varargin)
%WRAPPER_FUNCTION calls simulation function for specific combination of external parameters
% 
%     output_collector = WRAPPER_FUNCTION(task_id,job_name,tmpdir,intermediatedir) 
%     For every external parameter combination, this function is called, 
%     which then calls the simulation function. The task id corresponds
%     to the cluster numeration of arrayjobs. It is mapped to the
%     external id within the WRAPPER_FUNCTION. Job name and the path to
%     the temporary directory are necessary to load the configuration
%     in non-local runs. The output collector including all the results 
%     for all internal parameter combinations is returned.
%     output_collector = WRAPPER_FUNCTION(task_id,job_name,tmpdir,intermediatedir,conf,para_set)
%     Does not load the configuration from temporary directory, but takes
%     the given one and also uses the given parameter set.
% 
%     See also: queue.submit_job
%               queue.internal.parameter_combination
%
% Copyright (c) 2017, Christian Rohlfing, Julian Becker, Jens Schneider, Patrick Wilken, Tobias Kabzinski

    if nargout > 0
        varargout{1} = {};
    end
   
    % Load configuration and parameter set
    if ~isempty(varargin)
        % local
        conf = varargin{1};
        para_set = varargin{2}; 
    else
        % cluster
        conf = load([tmpdir, '/', job_name '_config.mat']);
        para_set = load([tmpdir, '/', job_name '_parameters.mat']);
    end
    
    % Get external id from task id
    if task_id <= length(conf.ext_ids)
        ext_id = conf.ext_ids(task_id);
    else
        error('task_id exceeds index of ext_ids');
    end
    
    % Initialize output collector
    output_collector = cell(1, para_set.int_comb_count);
    
    if conf.collect_output
        % Initialization       
        write_period_counter = 0;
        
        % Use number of total combinations to distinguish mat-files of different runs
        run_id = 0;
        run_id_current = para_set.ext_comb_count * para_set.int_comb_count;   
        
        % Check if output mat-file already exists
        path_to_output_mat = [conf.result_dir, '/', conf.job_name, '/', num2str(ext_id) '.mat'];        
        if exist(path_to_output_mat, 'file')
            % If so load run id
            load(path_to_output_mat, 'run_id');
        end
        
        % Check if mat-file belongs to current job (i.e. no parameter extension)
        if run_id == run_id_current
            % If so use it
            load(path_to_output_mat, 'output_collector');
        else
            % Otherwise create a new one with an empty output collector in it        
            run_id = run_id_current; %#ok<NASGU>
            save(path_to_output_mat, 'output_collector', 'run_id', '-v7');
        end
    end       
    
    % Iterate through internal combinations
    for int_id = 1:para_set.int_comb_count;
       
        % Only call simulation function if combination id is new
        if isempty(output_collector{int_id})
            
            % Display current id
            fprintf('\n<int_id = %d/%d>\n\n', int_id, para_set.int_comb_count);

            % Convert external and internal id into combination id
            combo_id = (ext_id - 1) * para_set.int_comb_count + int_id;
            
            % Get internal parameter values for this internal id
            p = queue.internal.fill_p(para_set, combo_id);

            % If necessary use intermediatedir as second input
            inputs = {p};
            if ~isempty(conf.local_disk_space)
                inputs{end + 1} = intermediatedir; %#ok<AGROW>
            end
            
            % Initialize cell of outputs (this way execution works for functions with or without outputs)
            outputs = cell(nargout(conf.fun_handle), 1);
            
            % ---Execute function---
            [outputs{:}] = conf.fun_handle(inputs{:});
            
            % Store output and generate a name for this combination
            if conf.collect_output
                output.data = outputs{:};
                output.name = field_name_gen(job_name, p, para_set.para_names);
            end
        else
            % If combination from previous run, results were already copied in submit_job
            output = output_collector{int_id};
            fprintf('\n<int_id = %d/%d> <copied>\n\n', int_id, para_set.int_comb_count);  
        end

        % Collect output
        if conf.collect_output
            
            % Store value inside output collector
            output_collector{int_id} = output; 
            
            % Increment counter
            write_period_counter = write_period_counter + 1;

            % If the write period becomes zero append the file with new executions
            if (write_period_counter >= conf.collect_write_period) || (int_id == para_set.int_comb_count)
                save(path_to_output_mat, 'output_collector', '-append');         
                write_period_counter = 0;
            end
        end    
    end
    
    % If requested, store output_collector as an output parameter
    if nargout > 0 && conf.collect_output
        varargout{1} = output_collector;
    end
end

function field_name = field_name_gen(job_name, p, para_names)
% This function will generate a field name by using the parameter names and values.
%%
    % Begin field name with job name 
    field_name = job_name;
    
    % Add string for each parameter
    for para_id=1:length(para_names)
        
        % Generate string
        value_str = queue.internal.value2str(queue.internal.getfield_by_str(p, para_names{para_id}));
        
        % Append current parameter and its value to name
        field_name = [field_name, '_', para_names{para_id}, '=', value_str]; %#ok<AGROW>
    end
end



