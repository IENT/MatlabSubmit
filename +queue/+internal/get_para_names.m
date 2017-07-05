function [para_names] = get_para_names(p)
%GET_PARA_NAMES searches the parameter struct for names of (possibly nested) parameters
%
% Copyright (c) 2017, Christian Rohlfing, Julian Becker, Jens Schneider, Patrick Wilken, Tobias Kabzinski

    para_names = {};
    fields = fieldnames(p);

    % Iterate through fields
    for m=1:length(fields)

        current_field = fields{m};
        current_val = p.(current_field);  
        
        if ~isstruct(current_val)
            % Store field name as parameter name if no nested struct
            append_para_names = {current_field};  
        else 
            % If nested recursively call function for substruct 
            append_para_names = queue.internal.get_para_names(current_val);
            
            % Generate full name (add current fieldname and '.')
            append_para_names = cellfun(@(x,y) [x,'.',y], repmat({current_field}, size(append_para_names)), append_para_names, 'UniformOutput', false);                           
        end
        
        % Append names to list
        para_names = [para_names; append_para_names];  %#ok<AGROW>
    end          
end