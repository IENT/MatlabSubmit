function [p] = find_parameters(p_full, input, para_value_flag)
%FIND_PARAMETERS finds out parameters used for certain ids
%    
%     p = FIND_PARAMETERS(p_full, combo_id) returns a parameter struct p
%     that is filled with the parameters used for the specified 
%     combo id. 
% 
%     p_full is the full parameter struct used for submition.
% 
%     p = FIND_PARAMETERS(p_full, [ext_id, int_id]) returns a parameter struct p
%     that is filled with the parameters used for the specified 
%     external and internal ids. 
% 
%     p = FIND_PARAMETERS(p_full, para_value_ids) returns a parameter struct p
%     that is filled with the parameters used for the specified 
%     parameter value ids (row vector). 
% 
%     In both cases you can input several sets of ids by adding columns.
%     Output will then be a cell of parameter structs.
% 
%     p = FIND_PARAMETERS(p_full, input, para_value_flag) forces input to be 
%     interpreted as para_value_ids (usefull if there are only 1 or 2 parameters). 
%     (ugly, changed ASAP)
%
% Copyright (c) 2017, Christian Rohlfing, Julian Becker, Jens Schneider, Patrick Wilken, Tobias Kabzinski

    if nargin < 3
        para_value_flag = 0;
    end
    
    % Get parameter set
    para_set = queue.internal.parameter_check(p_full);
    
    if size(input, 2) <= 2 && ~para_value_flag
        
        % Get combo id in both cases
        if size(input, 2) == 2
            ext_id = input(:, 1);
            int_id = input(:, 2);

            % Check if external or internal id is too high
            if any(ext_id > para_set.ext_comb_count) || any(int_id > para_set.int_comb_count)
                error('At least one of the ids exceeds the the size of the parameter struct! p has %d external and %d internal combinations.', para_set.ext_comb_count, para_set.int_comb_count)
            end

            combo_id = (ext_id-1) * para_set.int_comb_count + int_id;
        else
            combo_id = input;

            % Check if external or internal id is too high
            if combo_id > para_set.ext_comb_count * para_set.int_comb_count
                error('The combination id exceeds the the size of the parameter struct! p has %d combinations.', para_set.ext_comb_count * para_set.int_comb_count)
            end
        end

        % Fill parameter values in p (same as in wrapper function)
        p = arrayfun(@(x) queue.internal.fill_p(para_set, x), combo_id, 'Uniformoutput', false);
        
        % Don't use cell if only one p
        if numel(p) == 1
            p = p{:};
        end
        
    else
        para_value_ids = input;
        p = cell(size(para_value_ids, 1), 1);
        
        % Iterate over given columns
        for p_id = 1:size(para_value_ids, 1)
            % For all paramters write the value corresponding to current value id into p
            for para_id = 1:size(para_value_ids, 2)
                
                % Check if paramter value id is valid
                if para_value_ids(p_id, para_id) <= numel(para_set.para_values{para_id})
                    % Get current value
                    current_value = para_set.para_values{para_id}{para_value_ids(p_id, para_id)};
                else
                    error('Index %1$d for parameter ''%2$s'' is too high! Parameter ''%2$s'' has only %3$d values', ...
                        para_value_ids(p_id, para_id), para_set.para_names{para_id}, numel(para_set.para_values{para_id}))
                end
                
                % Insert value in p
                p{p_id} = queue.internal.setfield_by_str(p{p_id}, para_set.para_names{para_id}, current_value);             
            end
        end
        
        % Don't use cell if only one p
        if numel(p) == 1
            p = p{:};
        end
    end           
    
end

