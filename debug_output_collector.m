function [] = debug_output_collector(output_collector, p)
% DEBUG_OUTPUT_COLLECTOR checks the consistency of an demo output collector
%
%   DEBUG_OUTPUT_COLLECTOR(output_collector, p) checks the completeness and the order of an output 
%   collector that was calculated with 'debug_function'. To use it, 
%   submit a job using 'debug_function' as function handle. 
%   Then call DEBUG_OUTPUT_COLLECTOR and hand the output collector and the 
%   used parameter struct as input arguments.
%
% Copyright (c) 2017, Christian Rohlfing, Julian Becker, Jens Schneider, Patrick Wilken, Tobias Kabzinski   

    if isempty(output_collector)
        disp('Output collector is empty!');
        return;
    end

    % Get parameter set
    para_set = queue.internal.parameter_check(p);
    
    % Initialization
    para_value_ids = zeros(length(para_set.para_names),1);
    combo_ids = zeros(1,length(output_collector));
    
    % Get number of parameter values
    num_of_values = cellfun(@numel, para_set.para_values);
    
    % For each result...
    for out_index = 1:length(output_collector)
        % ...get parameters used...
        current_para_values = cellfun(@(x) queue.internal.getfield_by_str(output_collector{out_index}.data, x), para_set.para_names, 'UniformOutput', false);
        % ...and find out the parameter value ids
        for para_id = 1:length(para_set.para_names)
            for para_value_id = 1:length(para_set.para_values{para_id})
                if isequaln(current_para_values{para_id}, para_set.para_values{para_id}{para_value_id})
                   para_value_ids(para_id) = para_value_id;
                end
            end
        end
        % Convert parameter value ids into combination id
        para_value_ids_cell = num2cell(para_value_ids, 2);
        combo_ids(out_index) = sub2ind(num_of_values', para_value_ids_cell{:}); 
    end
    
    output_collector_ok = true;
    
    % Check for all combination ids
    if ~isequal(sort(combo_ids), 1:length(combo_ids));
        disp('There are combinations missing!')
        output_collector_ok = false;
    end
    
    % Check for dublicates
    if length(unique(combo_ids)) ~= length(combo_ids)
        disp('There were duplicates in the output collector!')
        output_collector_ok = false;
    end
    
    % Check if sorted
    if ~issorted(combo_ids)
        disp('The output collector is not sorted!')
        output_collector_ok = false;
    end
    
    % Everthing fine
    if output_collector_ok == true
        disp('The output collector looks right!')
    end
    
    % Plot combination ids. Ids are expected to be ascending therefore you should see a straight line.
    figure; plot(combo_ids, '*');
    title('Comination ID Plot')
    xlabel('actual combo id');
    ylabel('expected combo id');
      
end

