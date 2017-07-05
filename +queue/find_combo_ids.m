function [ combo_ids ] = find_combo_ids(p_part, p)
% FIND_COMBO_IDS finds out the job id of certain parameter combinations
%   
%     combo_ids = FIND_COMBO_IDS(p_part, p) returns all the job ids 
%     associated to combinations of a subset of parameters given in p_part. 
%     The format of p_part must be the same as the parameter struct p itself. 
%     If a parameter is not specified all possible values are used.
%
% Copyright (c) 2017, Christian Rohlfing, Julian Becker, Jens Schneider, Patrick Wilken, Tobias Kabzinski

    % Get parameter sets
    para_set_part = queue.internal.parameter_check(p_part);
    para_set_full = queue.internal.parameter_check(p);
    
    % If p_part is empty return all ids (because all values are allowed)
    if isempty(fieldnames(p_part))
        combo_ids = 1:para_set_full.ext_comb_count * para_set_full.int_comb_count;
        return;
    end
    
    % Rewrite para_set_part so that parameters are at the same place as in para_set_full
    [~, para_mapping] = ismember(para_set_part.para_names, para_set_full.para_names);
    para_set_part.para_values(para_mapping,:) = para_set_part.para_values; 
    
    % If parameter is not given use all parameter values
    for para_id = 1:length(para_set_full.para_names)
        if ~ismember(para_set_full.para_names(para_id), para_set_part.para_names)
            para_set_part.para_values(para_id) = para_set_full.para_values(para_id);
        end
    end
    
    % Complete para_set_part by using all names
    para_set_part.para_names = para_set_full.para_names;
    
    % Find out combination ids of smaller parameter set within full parameter space (same problem as parameter extension) 
    combo_ids = queue.internal.translate_ids(para_set_part.para_values, para_set_full.para_values);   
end

