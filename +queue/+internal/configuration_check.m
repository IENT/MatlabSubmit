function conf = configuration_check(user_conf, skip_flag, output_flag)
%CONFIGURATION_CHECK checks validity of given configuration struct 
%
%     conf = CONFIGURATION_CHECK(user_conf) checks the given configuration (user_conf)
%     and replaces empty or non-given fields with default values. The default values
%     are stored in /+queue/+internal/default_conf.
% 
%     'conf' is a structure that may contain the following fields: 
% 
%       * conf.fun_handle  
%           Specify the matlab simulation function you want to call for every parameter combination.
%       * conf.job_name    
%           Specify the name of the job.
%       * conf.result_dir   
%           Specify the path where output files can be written. Using any folder in your home directory  
%           is not allowed. If not set, the directory /scratch/[username]/queue_results/[conf.job_name] 
%           will be used. 
%       * conf.tmp_dir     
%           Specify the path where temporary files can be written, such as the current configuration 
%           and the used parameters. Additionally, you can find o-files (giving MATLAB text output
%           of simulation function) for each external combination. If not set, the tmp folder 
%           in your scratch directory will be used.
%       * conf.memory_limit: 
%           Each job needs a memory limitation. Jobs which exceed this limitation will be stopped.
%           The default value is 2 giga byte ('2G').
% 
%     See also: queue.submit_job,
%               queue.internal,
%               queue.internal.parameter_check
%     
%     Advanced configuration:
% 
%       * conf.architecture:
%           Only use 32- or 64-bit servers. For 32-bit set it to 'lx24-x86', for 64-bit use 'lx24-amd64'
%           Also see http://garcon.ient.rwth-aachen.de/wiki/IENTRechenCluster#Einstellung%20der%20gew%C3%BCnschten%20Architektur
%      * conf.collect_output: 
%           Specify whether output collection is enabled (default) or not. If disabled the output
%           of the simulation function will be ignored and no results will be written to the result directory.
%       * conf.collect_write_period: 
%           Specify the interval (in terms of internal jobs) between which the results are written. 
%           E.g. 2 means after every two internal parameter runs the output file will be updated. 
%           If set to 'inf' (default) results are only stored after all internal runs finished.          
%       * conf.priority: 
%           Specify the priority value. Default value should be '-512'. 
%           Also see http://garcon.ient.rwth-aachen.de/wiki/IENTRechenCluster#Prioritäten
%       * conf.project_name: 
%           Specify the name of the project.
%       * conf.server_names: Specify the names of the server where the 
%           jobs must be submitted. Also see http://garcon.ient.rwth-aachen.de/wiki/IENTRechenCluster#Queues
%
% Copyright (c) 2017, Christian Rohlfing, Julian Becker, Jens Schneider, Patrick Wilken, Tobias Kabzinski

    if nargin < 2
        skip_flag = false;
    end
    
    if nargin < 3
        output_flag = false;
    end
    
    % Check if structure
    if ~isstruct(user_conf)
        error('conf has to be a structure. Type ''help queue.internal.configuration_check'' to see the required format')
    end
    
    % load configuration template (default values)
    conf = user_conf.default_conf();
        
    % replace template values with user defined ones
    user_conf_fields = fieldnames(user_conf);
    for i = 1:length(user_conf_fields)
        if ~isempty(user_conf.(user_conf_fields{i}))
            conf.(user_conf_fields{i}) = user_conf.(user_conf_fields{i});
        end
    end

    % make usage of '$USER' in directory names possible
    if ~ispc
      [~,conf.tmp_dir]=system(['echo ' conf.tmp_dir]); conf.tmp_dir(end) = [];
      [~,conf.result_dir]=system(['echo ' conf.result_dir]); conf.result_dir(end) = [];
    else
      dirPre = '//garcon';
      username = getenv('username');
      conf.tmp_dir = strrep([dirPre conf.tmp_dir], '$USER', username);
      conf.result_dir = strrep([dirPre conf.result_dir], '$USER', username);
    end
    
    % Check job name
    if ~ischar(conf.job_name)
        error('Job name has to be a string!')
    end
    
    % Check whether function handle is valid
    if ~isa(conf.fun_handle, 'function_handle')
        error('The functional handle is not valid!')
    end
    
    % Check whether temporary directory exists
    if ~exist(conf.tmp_dir,'dir')
        error('Temporary directory ''%s'' not found', conf.tmp_dir)
    end
    
    % Following checks are only relevant if output is collected
    if conf.collect_output
        
        % Check wether simulation function has only one output
        if nargout(conf.fun_handle) > 1
            error('The simulation function must have only one output. Your function ''%s'' has %d outputs!', func2str(conf.fun_handle), nargout(conf.fun_handle));
        elseif nargout(conf.fun_handle) == 0 
            if output_flag
                warning('Your function ''%s'' has no outputs. The output will not be collected.\n\n', func2str(conf.fun_handle));
            end
            % Don't collect output and skip the remaining checks
            conf.collect_output = false;
        else
            % Check whether result directory exists
            if ~exist(conf.result_dir,'dir')
                error('Base result directory %s not found', conf.result_dir)
            end
            
            % Check whether home was used
            if strcmp(conf.result_dir(1:5), '/home') || conf.result_dir(1) == '~'
                error('Never ever store simulation results in /home/! Use /scratch/ instead.');
            end
            
            % Ask if the folder |result_dir|/job_name should be created if it isn't already avaiable.
            result_dir = [conf.result_dir, '/', conf.job_name];
            if ~exist(result_dir,'dir')
                reply = '';
                if ~skip_flag
                    reply = input(sprintf('Result directory %s not found. Do you want to create it? [Y/n]\n', result_dir),'s');
                end
                if ~strcmpi(reply,'n')
                    % Create the result-directory in the base-directory
                    [status, msg] = mkdir(result_dir);
                    if status == 0
                        error(msg);
                    else
                        fprintf(['Created folder succesfully. ', msg, '\n\n'])
                    end
                else
                    error('I cannot continue without the result directory. Please create it yourself!');
                end
            end
        end
    end
  
    % Check wether simulation function has right number of inputs
    aux_str1 = '';
    aux_str2 = '';
    right_num_inputs = 1;
    if ~isempty(conf.local_disk_space);
        aux_str1 = 'two ';
        aux_str2 = 's';
        right_num_inputs = 2;
    end
    
    if nargin(conf.fun_handle) == 0
        error('The simulation function must have an input!')
    elseif nargin(conf.fun_handle) > right_num_inputs;
        if output_flag
            warning('Only the first %sinput%s of the simulation function will be used. Your function has %d inputs.', aux_str1, aux_str2, nargin(conf.fun_handle));
        end    
    end
       
    % Check wether write period is valid (positiv integer or inf)
    if ~isnumeric(conf.collect_write_period) || conf.collect_write_period < 1 || rem(conf.collect_write_period, 1) > eps
        error('Invalid write period. ''conf.collect_write_period'' has to be a positive integer value.') 
    end
    
    % Check whether -r option is avaiable
    if ~strcmp(conf.matlab_cmd_para(end-1:end),'-r')
        error('Last matlab option (matlab_cmd_para) has to be "-r" (so Matlab is able to run your custom script).')
    end
end