function [p,para_value_ids] = fill_p(para_set, combo_id) 
% FILL_P write parameter values for a given combo id into 'p'
%   
%    p = FILL_P(para_set, combo_id) creates a parameter structure 'p' with a field
%    for each parameter and fills them with values associated with the current
%    combination id
%
% Copyright (c) 2017, Christian Rohlfing, Julian Becker, Jens Schneider, Patrick Wilken, Tobias Kabzinski

    p = struct();
    
    % Get parameter value ids from combination id
    num_of_values = cellfun(@numel, para_set.para_values);
    para_value_ids = cell(length(num_of_values), 1);
    [para_value_ids{:}] = ind2sub(num_of_values', combo_id);
    para_value_ids = cell2mat(para_value_ids);
    
    % For all paramters write the value corresponding to current value id into p
    for para_id = 1:length(para_value_ids)
        current_value = para_set.para_values{para_id}{para_value_ids(para_id)};
        p = queue.internal.setfield_by_str(p, para_set.para_names{para_id}, current_value);             
    end

end