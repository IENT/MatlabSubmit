function results = debug(status)
% DEBUG tests functionality of MatlabSubmit
%
% Copyright (c) 2017, Christian Rohlfing, Julian Becker, Jens Schneider, Patrick Wilken, Tobias Kabzinski

    if nargin < 1
        status = '';
    end
    
%% Configuration
    local_flag = 1; % Whether to run locally, otherwise submition to the cluster
    skip_flag = 0; % Whether to skip user dialog and use default answers
    
    % What do you want to be tested?
    test_simulation = 1; % can be turned off if just testing evalutaion
    test_submit_twice = 0; % call submit_job twice without testing completeness in between; should copy from separate mat-files of first submission
    collect_results_once = 0; % collect results in case no simulation was run
    test_rerun = 0;
    test_extension = 0;
    test_rerun_after_extension = 0;
    test_permutaion_of_p = 0; % check if order of fields in p can be changed
    test_change_of_ext = 0; % change which parameters are external 
    test_new_parameter = 0;  % add new parameter before restart, should cause error
    
    test_dont_collect_output = 0;
    test_switch_collect_output = 0; % check if it is possible to turn on/off output collection when restarting
    test_function_without_output = 0;  % @disp (default function)   
    test_debug_outputcollector = 0; % check if output collector looks as expected
   
    test_find_functions = 1;

    pause_before_collect_results = 0; % to wait for jobs to finish if submitted to cluster
%% Tests
    % Create parameter struct with all possible parameter classes:
    p.nocell = 'nocell';
    p.logicals = {true, false};
    p.complex = {1i, 1 - 0.25i};
    p.floats = num2cell((1:3)*pi);
    p.matrices = {uint16([1,2;3,4]); uint16([5,6;7,8])};
    p.strings = {'str1','str2'};
    p.cells = {{'cell1(1)', 'cell1(2)'} , {'cell2(1)', 'cell2(2)'}};
    struct1.structparameter = 'struct1';
    struct2.structparameter = 'struct2';
    p.structs = {struct1, struct2};
    p.nested.nestedparameter = {'nested1'};%','nested2'};
    p.nested.nestedtwice.nestedtwiceparameter = {'nestedtwice1', 'nestedtwice2'};
    p.external = {'strings','nested.nestedtwice.nestedtwiceparameter'; 'logicals', 'floats'};
  
    % Create conf
    conf.job_name = 'MatlabSubmitDebugging';
%     conf.priority = '-513';
    conf.memory_limit = '2G';
%     conf.server_names = 'Maegde';
%     conf.local_disk_space = '2G';
    conf.collect_write_period = 3;
    
    if  ~test_function_without_output
        conf.fun_handle = @debug_function;
    end
       
    if test_dont_collect_output
        conf.collect_output = 0;
    end
    
    % Submition
    output_collector = {};
    if test_simulation 
        
        % Skip first loop if restart
        start_run_idx = 1;
        if strcmp(status, 'extension')
            start_run_idx = 2;
            test_extension = 1;
        else
            % Delete data from previous runs 
            if exist(sprintf('/scratch/%s/queue_results/MatlabSubmitDebugging', getenv('USER')),'dir')
                rmdir(sprintf('/scratch/%s/queue_results/MatlabSubmitDebugging', getenv('USER')),'s');
            end        
        end
        
        for run_idx = start_run_idx:1 + test_extension
            % Restart case
            if run_idx == 2
                % Expand parameter struct
                p.floats = num2cell((1:5)*pi);
                p.matrices = {uint16([1,2;3,4]); uint16([5,6;7,8]); uint16([9,10;11,12])};
                % Test permutation of parameter values
                p.logicals = {false, true};
                p.structs = {struct2, struct1};
                % Try new parameter
                if test_new_parameter
                    p.new = {'new1', 'new2'};
                end
                % Test permutation of fields
                if test_permutaion_of_p
                    p = orderfields(p);  
                    p.nested = orderfields(p.nested, [2,1]);
                end
                if test_change_of_ext
                    p.external = {'nocell','nested.nestedparameter'; 'logicals', 'matrices'};
                end
                if test_switch_collect_output
                    conf.collect_output = test_dont_collect_output; % switch from collecting to not collecting or the other way around 
                end
            end
            
            % Submit jobs
            queue.submit_job(p, conf, local_flag, skip_flag);
            
            if test_submit_twice
                queue.submit_job(p, conf, local_flag, skip_flag);
            end

            % Re-run case
            if (run_idx == 1 && test_rerun) || (run_idx == 2 && test_rerun_after_extension)
                % Wait for jobs to finish
                if pause_before_collect_results
                    pause();
                end
                
                % Simulate failed jobs by deleting some results
                try
                    delete(sprintf('/scratch/%s/queue_results/MatlabSubmitDebugging/5.mat', getenv('USER')))
                    some_mat = load(sprintf('/scratch/%s/queue_results/MatlabSubmitDebugging/7.mat', getenv('USER')));
                    output_collector = some_mat.output_collector;
                    output_length = length(output_collector);         
                    output_collector(floor(output_length/2):output_length) = cell(1,floor(output_length/2)+1); %#ok<NASGU>
                    save(sprintf('/scratch/%s/queue_results/MatlabSubmitDebugging/7.mat', getenv('USER')), 'output_collector', '-append');
                catch me %#ok<NASGU>
                end
                
                % Test completeness (will restart failed jobs)
                queue.collect_results(p, conf);
            end
            
            % Test completeness
            if pause_before_collect_results
                pause();
            end
            [results, output_collector] = queue.collect_results(p, conf);
        end
    end
    
    % Test completeness if no simulation was run
    if collect_results_once && ~test_simulation
        [results, output_collector] = queue.collect_results(p, conf);
    end

    % Check output collector
    if test_debug_outputcollector && ~test_dont_collect_output && ~test_function_without_output
        debug_output_collector(output_collector, p); 
    end
    
    % Test functions that find certain parameters or combination ids
    if test_find_functions
        p_part.floats = {pi*2};
        p_part.strings = 'str1';
        p_part.cells = {{'cell1(1)', 'cell1(2)'}};
        p_part.structs = {struct2};
        p_part.logicals = true;
        p_part.matrices = uint16([1,2;3,4]);
        p_part.nested.nestedparameter = 'nested1';
        p_part.nested.nestedtwice.nestedtwiceparameter = {'nestedtwice2'};
        
        found_job_ids = queue.find_combo_ids(p_part, p); 
        
        found_ps_ext_int = queue.find_parameters(p, [3, 4; 5, 6]);
        found_ps_combo_id = queue.find_parameters(p, 12);
        found_ps_para_values = queue.find_parameters(p, [1,1,2,1,2,1,1,1,2,1; 1,2,1,2,1,1,1,2,1,2]);
    end    

end
