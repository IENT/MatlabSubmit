function ids_same = translate_ids(old_para_values, new_para_values, para_mapping, output_flag)
%TRANSLATE_IDS mapping of combo ids for parameter extension
% 
%     ids_same = TRANSLATE_IDS(old_para_values, new_para_values, para_mapping)
%     does the mapping between old and new combination ids. 
% 
%     'para_mapping' is a vector giving the position of the old parameters 
%     in the new parameters. For example para_mapping(3) == 1 means the third 
%     old parameter is now the first new parameter. 
%     'ids_same' are the combination ids (external or internal) that correspond 
%     to combinations of solely old parameters, i.e. those combinations 
%     that were already simulated in a previous run. For example ids_same(5) = 7
%     means that the combination with id 5 in the previous run has now id 7.
%
% Copyright (c) 2017, Christian Rohlfing, Julian Becker, Jens Schneider, Patrick Wilken, Tobias Kabzinski


    % Default parameter mapping is no mapping at all
    if nargin < 3
        para_mapping = 1:size(new_para_values,1);
    end

    % Usually don't show percentages
    if nargin < 4 
        output_flag = 0;
    end
    
    % Apply mapping to have same order of parameters for old and new values
    new_para_values = new_para_values(para_mapping,:);
    
    % Get number of parameter values for all parameters  
    old_num_of_values = cellfun(@numel, old_para_values);
    new_num_of_values = cellfun(@numel, new_para_values);
    
    % Lookup table to map old parameter value ids to new ones
    id_mapping = zeros(length(old_para_values), max(old_num_of_values));  
    
    % Flag to output warning only once
    warning_flag = 0;
    
    if output_flag
        % For percentage display
        progress = 0;
        number_of_iterations = sum(old_num_of_values);
        reverseStr = '';
    end
    
    % For each paramter...  
    for para_id = 1:length(old_para_values)
        % ...if old and new values are not completely equal...
        if ~isequal(new_para_values{para_id}, old_para_values{para_id})
            % ...search for old parameter values in new ones
            for old_value_id = 1:length(old_para_values{para_id})
                % Get old value
                old_value = old_para_values{para_id}{old_value_id};
                
                old_value_found = false;
                for new_value_id = 1:length(new_para_values{para_id})
                    % Get new value
                    new_value = new_para_values{para_id}{new_value_id}; 

                    % Deal with precision error of floats (for example when using colon operator)
                    floatcompare = 0;
                    if isfloat(old_value) && isfloat(new_value) && isequal(size(old_value), size(new_value))
                        floatcompare = abs(old_value - new_value) <= eps(old_value);
                    end
                    
                    % When found store new id
                    if isequal(old_value, new_value) || all(floatcompare(:)) 
                        id_mapping(para_id, old_value_id) = new_value_id;
                        old_value_found = true;
                        break;
                    end                  
                end
                if ~old_value_found
                    error('When doing parameter extension all parameter values from previous run must be contained in the new parameter struct!');
                end
                
                if output_flag
                    % Display progress
                    progress = progress + 1;
                    percent_done = progress / number_of_iterations * 100;
                    msg = sprintf('Progress: %3.0f / 100 \n', percent_done);
                    fprintf([reverseStr, msg]);
                    reverseStr = repmat(sprintf('\b'), 1, length(msg));
                end
            end
            if output_flag && ~warning_flag && length(new_para_values{para_id}) == length(old_para_values{para_id})
               warning_flag = 1;
            end
        % Shortcut for completely equal parameter values (to save time if number of parameter values is large)
        else
            id_mapping(para_id, 1:length(new_para_values{para_id})) = 1:length(new_para_values{para_id});
            if output_flag
                % Display progress
                progress = progress + old_num_of_values(para_id);
                percent_done = progress / number_of_iterations * 100;
                msg = sprintf('Progress: %3.0f / 100 \n', percent_done);
                fprintf([reverseStr, msg]);
                reverseStr = repmat(sprintf('\b'), 1, length(msg));
            end
        end
    end
  
    % Display warning (only here because it conflicts with percentage display)
    if warning_flag
        warning('The order of parameter values was different from previous run. Parameter check will be faster if you keep the order!')
    end
    
    % Create all possible old combinations of parameter value ids
    old_para_value_ids = arrayfun(@(x) 1:x, old_num_of_values, 'UniformOutput', false);
    old_para_value_ids = combvec(old_para_value_ids{:});
    
    % Apply parameter value mapping of parameter value ids
    new_para_value_ids = zeros(size(old_para_value_ids));
    for para_id = 1:size(old_para_value_ids, 1)
        new_para_value_ids(para_id,:) = id_mapping(para_id, old_para_value_ids(para_id, :)); % is there a one line solution?
    end
    
    % Revert parameter mapping to get the right combination id
    new_para_value_ids(para_mapping,:) = new_para_value_ids;
    new_num_of_values(para_mapping,:) = new_num_of_values;
     
    % Convert parameter value ids to combination ids
    new_para_value_ids = num2cell(new_para_value_ids, 2);
    ids_same = sub2ind(new_num_of_values', new_para_value_ids{:}); 
    
end

