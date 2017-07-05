function [varargout] = submit_job(p, conf, local_flag, skip_flag, missing_ext_ids)
%SUBMIT_JOB starts a submition
% 
%     output_collector = SUBMIT_JOB(para,conf) submits an array job from 
%     Matlab to the IENT cluster. The submition has to be configured with
%     the struct 'conf', especially the function you want to evaluate is 
%     passed here (type 'help queue.internal.configuration_check' for 
%     details). The input parameter space is defined in 'p' (type 
%     'help queue.internal.parameter_check' for details). For each 
%     combination of parameters a job will be submitted that evaluates the 
%     simulation function.
% 
%     'output_collector' will contain the results of the submition only if you 
%     perform a local run. In every case it will be stored inside full.mat in
%     the result directory specified in 'conf'.
% 
%     [...] = SUBMIT_JOB(para, conf, local_flag) runs the jobs locally instead
%     of doing a submition to the cluster if local_flag is set to true. The 
%     default value is false.
% 
%     [...] = SUBMIT_JOB(para, conf, local_flag, skip_flag) omits the user dialogs when
%     the flag is set to true. The default value is false.
% 
%     [...] = SUBMIT_JOB(para, conf, skip_flag, missing_ext_ids) runs a job
%     again, but only restarts those external ids mentioned.
% 
%     Example:        
% 
%       % For this example a function that performs a very simple calculation 
%       % is used:
%       % function [ out ] = dummy_function(in)
%       %   out.my_measure = in.para1 * str2double(in.para2(5));
%       % end
% 
%       % Create parameter struct p with the values you want to simulate
%       p.para1 = num2cell(1:3);
%       p.para2 = {'test1','test2'};
%       % Assign external parameter (optionally)
%       % p.external = {'var1'};
% 
%       % Create configuration struct (It is a minimum 
%       % configuration only, please read documentation of 
%       % configuration_check for complete information).
%       conf.fun_handle = @dummy_function;
%       conf.job_name = 'my_job_name';
% 
%       % Submit jobs to the cluster
%       queue.submit_job(p, conf);
% 
%       % When jobs are finished get results by
%       results = queue.collect_results(p, conf)
% 
% 
%     See also: queue.internal.configuration_check
%               queue.internal.parameter_check
%
% Copyright (c) 2017, Christian Rohlfing, Julian Becker, Jens Schneider, Patrick Wilken, Tobias Kabzinski

    if nargin < 1 || isempty(p)
        error('I need at least a parameter struct!');
    end
    
    % Initialize missing input arguments 
    if nargin < 2
        conf = struct();
    end

    if nargin < 3
        local_flag = false;
    end
    
    if nargin < 4
        skip_flag = false;
    end
    
    if nargin < 5
        missing_ext_ids = [];
    else
        % Ask where to restart jobs
        reply = input('Locally [L] or on the cluster [c]?\n','s');
        if isempty(reply) || ~strcmpi(reply, 'c')
            local_flag = true;
        else
            local_flag = false;
        end
    end
        
    % Check configuration
    fprintf('Checking configuration...\n\n')  
    if isempty(conf)
        disp('No configuration provided. Using only default values.');
    end
    conf = queue.internal.configuration_check(conf, skip_flag, 1);

    % Check if mat-files from previous run exist        
    old_para_set = struct();
    old_full_mat_exists = 0; 
    
    file_list = '';
    try
        file_list = ls([conf.result_dir, filesep, conf.job_name, filesep, '*.mat']);
    catch me %#ok<NASGU>
    end
    
    full_path = [conf.result_dir, filesep, conf.job_name, filesep, 'full.mat'];
    mat_tokens_found = {};
    if ~isempty(file_list)
        mat_tokens_found = regexp(file_list, [conf.result_dir, '/', conf.job_name, '/', '(full|(\d+))\.mat'], 'tokens');
        mat_tokens_found = cellfun(@(x) x{1}, mat_tokens_found, 'UniformOutput', false);
        
        % Load old parameter set and configuration
        if ismember({'full'}, mat_tokens_found)
            try
                old_full_mat = load(full_path, 'para_set', 'conf');
                old_para_set = old_full_mat.para_set;
                old_conf = old_full_mat.conf;
                old_full_mat_exists = 1;
            catch me %#ok<NASGU>
            end
        end   
    end
        
    % Check if configuration is consistent with previous run
    if old_full_mat_exists
        conf = queue.internal.configuration_check_extension(conf, old_conf, 1);
    end
   
    % Check parameter struct, convert it to parameter set and in extension case compare it to the old parameter set
    fprintf('Checking parameter struct...\n\n')  
    [para_set, combo_ids_same] = queue.internal.parameter_check(p, old_para_set, 1);  
    
    
    % Deal with extension case
    if old_full_mat_exists
        % Avoid doing simulation twice
        if length(combo_ids_same) == para_set.ext_comb_count * para_set.int_comb_count
            fprintf('Already simulated these parameters! Complete output collector can be found here:\n%s\n', full_path);
            disp('(To force a restart change job name or delete results.)');
            if nargout > 0
                varargout{1} = {};
            end
            return;
        else
            % User output, suppressed if obviously a re-run
            if isempty(missing_ext_ids)
                disp('Previous simulation found. Some already calculated results will be copied.')
            end
        end
    else
        if isempty(missing_ext_ids)
            disp('No previous simulation found.')
        end
    end
          
    % Set ext_ids to be started
    if isempty(missing_ext_ids)
        conf.ext_ids = 1:para_set.ext_comb_count;  
    else
        conf.ext_ids = missing_ext_ids;
    end
    
    % If there is only one external parameter combination, ask to run locally
    if para_set.ext_comb_count == 1 && local_flag == 0
        local_flag = true; 
        if ~skip_flag
            reply = input('There were no external parameters hence a single job.\nDo you like to execute it locally? [Y/n] \n', 's');
            if strcmpi(reply, 'n')
                local_flag = false;
            end
        end 
    end
    
    % Ask if everything is fine
    if ~skip_flag
        if numel(mat_tokens_found) > 1 && isempty(missing_ext_ids)
            fprintf('There are still output mat-files in your result directory. Those will be used or overwritten!\n')
        end
        if local_flag
            fprintf('Number of resulted external (run locally) jobs are %d. \nNumber of resulted internal runs are %d.\n', length(conf.ext_ids), para_set.int_comb_count)
        else
            fprintf('Number of resulted external jobs are %d. \nNumber of resulted internal runs are %d.\n', length(conf.ext_ids), para_set.int_comb_count)
        end
        reply = input('Do you want to continue? [Y/n] \n','s');
        if strcmpi(reply, 'n')
            if nargout > 0
                varargout{1} = {};
            end
            return;
        end
    end
    
    % Saving the config information and the combined parameters
    if ~local_flag
        save([conf.tmp_dir, filesep, conf.job_name '_config.mat'], '-struct', 'conf', '-v7');
        save([conf.tmp_dir, filesep, conf.job_name '_parameters.mat'], '-struct', 'para_set', '-v7');    
    end
      
    % Generate output mat-files containing old results
    if old_full_mat_exists
        disp('Copying results from previous run...');
        queue.internal.copy_old_results(combo_ids_same, para_set, conf, missing_ext_ids);       
    end
    
    output_collector = {}; 
    
    % Start running
    if ~local_flag
        
        % Submission to the cluster
        fprintf('Generating script...\n\n')
        
        try
            generate_script(conf);
        catch me
            fprintf('There was an error during the generation of the script.\nThis submission cannot continue.');
            error(['Error Message : ' me.message]);
        end
        
        fprintf('Submitting jobs...\n\n')

        % Call qsub
        [status, result] = system(sprintf(conf.queue_command, conf.tmp_dir, conf.job_name));
        if status
            error(['There was a problem during the submission.\nPlease check ' conf.job_name '_script.sh.']);
        end

        disp(result);

    else
        % Local submission
        output_collector = cell(1,length(conf.ext_ids)*para_set.int_comb_count);
        
        % Iterate over all external ids and simulate wrapper_function calls:
        for task_id = 1:length(conf.ext_ids)
            fprintf('\n<<ext_id = %d/%d>>\n\n', conf.ext_ids(task_id), length(conf.ext_ids))
            ext_result = queue.internal.wrapper_function(task_id, conf.job_name, conf.tmp_dir, '', conf, para_set);
            if conf.collect_output
                output_collector((task_id-1)*para_set.int_comb_count + 1:task_id*para_set.int_comb_count) = ext_result;
            end
        end
    end
    
    % Assign return values
    if nargout > 0
        varargout{1} = output_collector;
    end
    
end


function generate_script(conf)
% GENERATE_SCRIPT generates shell script for job submission
%
% This function loads the script template from '+queue/+internal/template_queue_script.sh' and replaces
% wild-card characters according to given configuration |conf|.
%%
    switch(conf.job_system)
        case 'sge'
            % Generate architecture requirements
            arch_requirements = ['h_vmem=' conf.memory_limit];
            if ~isempty(conf.architecture)
                arch_requirements = [arch_requirements ',arch=' conf.architecture];
            end
            if ~isempty(conf.local_disk_space)
                arch_requirements = [arch_requirements ',ient_local_disk_free=' conf.local_disk_space];
            end
            if isfield(conf,'arch_requirements') && ~isempty(conf.arch_requirements)
                arch_requirements = [arch_requirements ',' conf.arch_requirements];
            end

            tasks = [num2str(1), ':', num2str(size(conf.ext_ids,2))];

            % Read script template
            script_file = fileread(['+queue', filesep, '+internal', filesep, 'sge_template_queue_script.sh']);

            % Do replacements
            script_file = strrep(script_file,'###LISTOFSERVERS###',         conf.server_names);        
            script_file = strrep(script_file,'###PRIORITY###',              conf.priority);

        case 'lsf'
            % Generate architecture requirements
            arch_requirements = conf.memory_limit;
            time_requirement = conf.time_limit;

            tasks = ['[', num2str(1), '-', num2str(size(conf.ext_ids,2)), ']'];

            % Read script template
            script_file = fileread(['+queue', filesep, '+internal', filesep, 'lsf_template_queue_script.sh']);

            % Do replacements
            script_file = strrep(script_file,'###TIME###',                 time_requirement);                        

    end
    script_file = strrep(script_file,'###ARCHREQUIREMENTS###',      arch_requirements);
    script_file = strrep(script_file,'###JOBNAME###',               conf.job_name);
    script_file = strrep(script_file,'###MATLABPARAM###',           conf.matlab_cmd_para);
    script_file = strrep(script_file,'###MATLABCOMMANDDARWIN###',   conf.matlab_path_mac);
    script_file = strrep(script_file,'###DEFAULTMATLABCOMMAND###',  conf.matlab_path_lin);
    script_file = strrep(script_file,'###TMPDIR###',                conf.tmp_dir);
    script_file = strrep(script_file,'###OUTPUTDIR###',             [conf.result_dir, filesep, conf.job_name]);
    script_file = strrep(script_file,'###PROJECTNAME###',           conf.project_name);    
    script_file = strrep(script_file,'###TASKS###',                 tasks);

    
    % Handle empty parameters
    if isempty(conf.project_name)
        script_file = strrep(script_file, '#$ -P', '');
    end

    % Write file
    hScriptFile = fopen([conf.tmp_dir, filesep, conf.job_name '_script.sh'],'w+');
    fprintf(hScriptFile,'%s',script_file);
    fclose(hScriptFile);
    system(['chmod a+x ',[conf.tmp_dir, filesep, conf.job_name '_script.sh']]);
end
