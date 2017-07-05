function varargout = collect_results(p, conf)
% COLLECT_RESULTS tests completeness of a submition and collects results
%       
%     [results, missing_ids] = COLLECT_RESULTS(para,conf) checks whether all jobs
%     defined by the given parameter struct and configuration are complete.
%     If the simulation has finished successfully, a struct containing the
%     results and the parameter names and values is returned. Otherwise the missing 
%     ids are returned.
% 
%     If the jobs of all parameter combinations have finished
%     successfully the results are also saved in 
%     [conf.result_dir '/' conf.job_name '/' "results.mat"].
% 
%     TODO:
%       * take multiple files if size > 2GB, consider using
%         * HFS5 or
%         * NetCDF
% 
%     See also: queue.submit_job,
%               queue.internal.parameter_combination
%
% Copyright (c) 2017, Christian Rohlfing, Julian Becker, Jens Schneider, Patrick Wilken, Tobias Kabzinski

    % Check parameters
    if nargin < 2
        error('Parameter and configuration struct are necessary arguments!')
    end
    conf = queue.internal.configuration_check(conf, 1);
    
    % Initialize 
    results = struct();
    output_collector = {};
    missing_ext_ids = [];
     
    % Only do something if output was collected at all
    if conf.collect_output == 0
        disp('Output collection has been disabled, hence there are no results to be checked.')
        
        % Deletion of temporary files should be possible even without output collected
        clean_up(conf);
    else           
        % Load full.mat if possible
        full_path = [conf.result_dir, filesep, conf.job_name, filesep, 'full.mat'];   
        full_mat_exists = false;
        old_full.para_set = struct();   
        old_full.run_id = 0;
        
        if exist(full_path, 'file')          
            try
                old_full = load(full_path, 'para_set', 'run_id');    
                full_mat_exists = true;
            catch me
                error('Loading full.mat failed!');
            end     
        end
               
        % Get para set and in restart case compare it to the old parameter set        
        [para_set, combo_ids_same] = queue.internal.parameter_check(p, old_full.para_set, 1);
              
        % Use number of total combinations to distinguish mat-files of different runs
        run_id_current = para_set.int_comb_count * para_set.ext_comb_count;
        
        % Check if full.mat belongs to current run
        if old_full.run_id ~= run_id_current
            
            % Initialize output_collector
            output_collector = cell(1, run_id_current);                 

            % Copy old results from full.mat to new output collector
            if full_mat_exists
                % Load old output_collector
                fprintf('Loading full.mat...\n\n')
                try
                    old_full = load(full_path, 'output_collector'); 
                catch me
                    error('Loading full.mat failed!');
                end
                
                output_collector(combo_ids_same) = old_full.output_collector;
                combo_ids_to_check = setdiff(1:run_id_current, combo_ids_same);
                ext_ids_to_check = unique(ceil(combo_ids_to_check / para_set.int_comb_count));
            else
                combo_ids_to_check = 1:run_id_current;
                ext_ids_to_check = 1:para_set.ext_comb_count;
            end

            % For percentage display
            progress = 0;
            reverseStr = '';

            fprintf('Testing completeness...\n\n');
            % Iterate over external ids
            for ext_id = ext_ids_to_check

                path_to_output_mat = [conf.result_dir, filesep, conf.job_name, filesep, num2str(ext_id) '.mat'];
                run_id = 0;

                % Check for output mat and load run id
                if exist(path_to_output_mat, 'file')
                    load(path_to_output_mat, 'run_id')
                end

                % Check if output mat belongs to current run
                if run_id == run_id_current
                    % Load output collector
                    output_mat = load(path_to_output_mat, 'output_collector');

                    % Get indices for comination ids and current internal ids to be checked 
                    I_new_combo_id = (ext_id - 1) * para_set.int_comb_count < combo_ids_to_check & combo_ids_to_check <= ext_id * para_set.int_comb_count;
                    new_int_ids = combo_ids_to_check(I_new_combo_id) - (ext_id - 1) * para_set.int_comb_count; 

                    % Mark external id as missing if results are incomplete
                    if any(cellfun(@isempty, output_mat.output_collector(new_int_ids)))
                        missing_ext_ids = [missing_ext_ids, ext_id]; %#ok<AGROW>
                    else
                        % Append value to output_collector if up to here all mat-files were complete
                        if isempty(missing_ext_ids)
                            output_collector(combo_ids_to_check(I_new_combo_id)) = output_mat.output_collector(new_int_ids);
                        end
                    end
                else
                    % mat-File is from another run or has disappeared
                    missing_ext_ids = [missing_ext_ids, ext_id]; %#ok<AGROW>
                end

                % Display progress
                progress = progress + 1;
                percent_done = progress / max(length(ext_ids_to_check), 1) * 100;
                msg = sprintf('Progress: %3.0f / 100', percent_done);
                fprintf([reverseStr, msg]);
                reverseStr = repmat(sprintf('\b'), 1, length(msg));
            end

            fprintf('\n')
            if isempty(missing_ext_ids)
                % Check if size of output_collector too big
                s = whos('output_collector');
                size_gb = s.bytes / 2^30;
                if (size_gb < 2)
                    % Save full output collector (if it has changed)
                    disp('All jobs and parameter combinations successfully finished.');
                    fprintf('Saving full.mat...\n\n')
                    if ~isempty(ext_ids_to_check)
                        run_id = run_id_current; %#ok<NASGU>
                        save(full_path, 'output_collector', 'conf', 'para_set', 'run_id', '-v7'); 
                    end
                    
                    % Create results.mat
                    fprintf('Reshaping results... (this might take a while)\n\n')
                    results = queue.internal.reshape_results(para_set, conf, output_collector);                   
                    
                    % Clean up result directory
                    clean_up(conf);
                    
                else 
                    disp('The complete output collector is too big to be saved')
                    fprintf('Size: %f GB\n',size_gb)
                end
            else
                % Display failed jobs
                disp('The jobs with the following ext_ids failed:');
                disp(missing_ext_ids);
                reply = input( '\nDo you want to restart them? [Y/n]\n','s');
                
                % Call submit_job passing missing ids
                if ~strcmpi(reply, 'n')
                    queue.submit_job(p, conf, 0, 0, missing_ext_ids); % Local or cluster is decided inside submit_job
                end
            end
        else
            % If full.mat already exist maybe reshaping has still to be done. If not, there will be only a user output in reshape_results.
            results = queue.internal.reshape_results(para_set, conf);
            
            % If user decided to load results in reshape_results also load output_collector if necessary
            if nargout > 1 && ~isempty(results)
                fprintf('Loading full.mat...\n\n')
                load(full_path, 'output_collector'); 
            end
            
            % Maybe there are still old files that can be deleted
            clean_up(conf);
        end
    end    
    
    if nargout > 0        
        varargout{1} = results;
    end  
    
    if nargout > 1
        varargout{2} = output_collector;
    end
    
    if nargout > 2
        varargout{2} = missing_ext_ids;
    end
             
end

function clean_up(conf)
% Clean up temporary files and output mat-files
%%    
    % Get file names
    [mat_output_strings, mat_file_names] = list_files([conf.result_dir, filesep, conf.job_name, filesep, '(\d+).mat']);
    [tmp_output_strings, tmp_file_names] = list_files([conf.tmp_dir, filesep, conf.job_name, '.o(\d+).(\d+)']);

    % Ask if to be deleted
    if ~(isempty(mat_output_strings) && isempty(tmp_output_strings))    % Is it possible to reduce the number of if-statements here?
        if ~isempty(mat_output_strings)
            fprintf('\nThe following mat-files are not used any more:\n')
            fprintf('%s\n', mat_output_strings{:})
        end      
        if ~isempty(tmp_output_strings)
            fprintf('\nThe following temporary files are not used any more:\n')
            fprintf('%s\n', tmp_output_strings{:})
        end

        add_string = ''; 
        if ~isempty(mat_output_strings) && ~isempty(tmp_output_strings)
            add_string = ' yes/no [t] just temporary files [m] just mat-files';
        end

        reply = input(['\nDo you want to delete them? [Y/n]', add_string, '\n'], 's');
        if all(~strcmpi(reply, {'n', 't'})) && ~isempty(mat_output_strings)
                delete(mat_file_names{:});
        end
        if all(~strcmpi(reply, {'n', 'm'})) && ~isempty(tmp_output_strings)
                delete(tmp_file_names{:});
        end   
    end
end

function [output_strings, file_names] = list_files(pattern)
% This function returns all filenames match the given regexp pattern ('file_names'). 
% 'output_strings' are the filenames processed in the following way:
% If 'pattern' contains the metacharacter '(\d+)' the files are sorted by this number.
% If the numbers are ascending this is represented by an interval (e.g. [5-10]).
% If 'pattern' contains several '(\d+)' then the processing is done recursively beginning with the leftmost appearance.
%%
    output_strings = '';
    file_list = '';
    file_names = {};
    
    % Read files
    path = strrep(pattern, '(\d+)', '*');
    try
        file_list = ls(path);
    catch me %#ok<NASGU>
    end
    
    % Create sorted list
    if ~isempty(file_list)
        tokens_found = regexp(file_list, pattern, 'tokens');
        file_names = regexp(file_list, pattern, 'match');
        % If several '(\d+)' find tokens of first and call function again for each of them
        if ~isempty(tokens_found)
            if size(tokens_found{1}, 2) > 1
                first_tokens_found = unique(cellfun(@(x) x{1}, tokens_found, 'UniformOutput', false));
                for token = first_tokens_found
                    position = strfind(pattern, '(\d+)');
                    new_pattern = [pattern(1:position - 1), token{:}, pattern(position + 5:end)];
                    output_strings = [output_strings, list_files(new_pattern)]; %#ok<AGROW> % recursion actually a bit over the top here (tmp-files have two numbers, therefore only one recursion)
                end
            % If only one '(\d+)'... 
            else    
                %...sort...
                tokens_found = sort(cellfun(@str2double, cellfun(@(x) x, tokens_found)));
                % ...and look for ascending intervals
                boundaries = find([1, diff(tokens_found) ~= 1, 1]);

                % Create string for each interval
                for interval_id = 1:length(boundaries) - 1
                    if boundaries(interval_id) == boundaries(interval_id + 1) - 1
                        interval_str = num2str(tokens_found(boundaries(interval_id))); 
                    else
                        interval_str = ['[', num2str(tokens_found(boundaries(interval_id))), '-', num2str(tokens_found(boundaries(interval_id + 1) - 1)), ']'];
                    end
                    output_strings = [output_strings, {strrep(path, '*', interval_str)}];   %#ok<AGROW>
                end
            end
        end
    end
end