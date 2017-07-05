function [para_set, combo_ids_same] = parameter_check(p, old_para_set, output_flag)
%PARAMETER_CHECK check consistency of a parameter struct
% 
%     para_set = PARAMETER_CHECK(p) checks the consistency of the parameter struct p
%     and converts it into a more convenient representation ('para_set', see below).
% 
%     'p' has to be a structure containing cells as fields. Each field name is 
%     interpreted as the name of one parameter. The cell has to contain all 
%     the values you want evaluate for this parameter. Parameter values can 
%     be of arbitrary class. Additionally the field 'p.external' is a cell of
%     external parameter names. By defining external parameters you can control
%     the number and size of your jobs. There will be a new job for each 
%     combination of external parameters, combinations of internal parameters
%     will be done within these jobs.
% 
%     Example: p.var1 = num2cell(1:3);      % parameter 'var1' with values 1, 2 and 3
%              p.var2 = {true, false};      % parameter 'var2' with values true and false
%              p.external = {'var2'};       % var2 external, therefore there will be two jobs, one for var2 = true and one for var2 = false
% 
%     Nested parameter are also possible. They might be useful to group parameters.
% 
%     Example: p.nested.var1 = {[1,2], [3,4]};     % parameter 'nested.var1' with values [1,2] and [3,4]
%              p.nested.var2 = {'a','b'};          % parameter 'nested.var2' with values 'a' and 'b'
%              p.external = {'nested.var2'}; 
% 
%     The output 'para_set' is a structure with following fields:
% 
%       * para_names    cell containing all names of the parameters
%       * para_values   cell array containing all parameter values for every parameter
%       * ext_comb_count    number of possible combinations of external parameter values
%       * int_comb_count    number of possible combinations of internal parameter values
% 
%     [para_set, combo_ids_same] = PARAMETER_CHECK(p, old_para_set) additionally 
%     compares the generated parameter set with the one of a previous run 
%     (old_para_set). This means the combination ids derived from 'old_para_set' 
%     are mapped to the combination ids of 'para_set' that are associated with 
%     the same parameter combinations. This is used in the parameter extension 
%     case to find out which parameter value combinations have already been 
%     calculated and can be copied from the old results. The new ids are 
%     returned in 'combo_ids_same'. For example, combo_ids_same(n) is the new 
%     id for a combination of parameters that used to have the id n in the 
%     previous run.
%
% Copyright (c) 2017, Christian Rohlfing, Julian Becker, Jens Schneider, Patrick Wilken, Tobias Kabzinski

    if nargin < 2
        old_para_set = struct();
    end
    
    if nargin < 3
        output_flag = 0;
    end
    
    % Check if structure
    if ~isstruct(p)
        error('p has to be a structure. Type ''help queue.internal.parameter_check'' to see the required format')
    end
    
    % Initialization
    ext_para_names = {};
    combo_ids_same = [];

    % Get external parameters
    if isfield(p, 'external')
        ext_para_names = p.external(:); % allowing p.external to be row or collumn cell vector
        p = rmfield(p, 'external');
    end
    
    % Read all parameter names from struct
    para_names = queue.internal.get_para_names(p); 
    
    % Sort parameters: Put internal paramters in front and external at the back, this way internal combinations will lie adjacent in the output collector
    [ext_para_found, ext_para_ids] = ismember(ext_para_names, para_names); 
    
        % Check if specified external parameters exist
        if ~all(ext_para_found)
            error('Some specified external parameters do not exist in the parameter struct.');
        end
        
    int_para_ids = setdiff((1:length(para_names))', ext_para_ids);
    para_names = para_names([int_para_ids; ext_para_ids]);
       
    % If there are any fields which are not a cell yet, convert them silently 
    for n = 1:length(para_names)
        cur_vals = queue.internal.getfield_by_str(p, para_names{n});
        if ~iscell(cur_vals)
            p = queue.internal.setfield_by_str(p, para_names{n}, {cur_vals});
        end
    end
    
    % Get parameter values
    para_values = cellfun(@(x) queue.internal.getfield_by_str(p, x), para_names, 'UniformOutput', false);
    
    % Calculate combination counts
    ext_comb_count = prod(cellfun(@numel, para_values(length(int_para_ids) + 1:end)));
    int_comb_count = prod(cellfun(@numel, para_values(1:length(int_para_ids))));
    
    % Compare new and old parameter set in restart case
    if ~isempty(fieldnames(old_para_set))        
        % Check if old parameters appear in new paramter struct and store a mapping (because order might have changed)
        [same_id, para_mapping] = ismember(old_para_set.para_names, para_names);
        
        % Check if parameters have changed
        if ~all(same_id) || length(para_names) > length(old_para_set.para_names)
            error('Cannot simulate the same job with different parameters! Please specify the same parameters (with differnet values) or change job name!')
        end
        
        if nargout > 1
            % Create a mapping between old and new parameter value ids         
            combo_ids_same = queue.internal.translate_ids(old_para_set.para_values, para_values, para_mapping, output_flag);
        end        
    end
    
    % Write parameter set
    para_set.para_names = para_names;
    para_set.para_values = para_values;
    para_set.ext_comb_count = ext_comb_count;
    para_set.int_comb_count = int_comb_count;
    
end
