function [data, disp_options, varargout] = ...
  apply_properties(data, para_set, properties, measure_name, method, dataSelectionOnly)
%APPLY_PROPERTIES reduces data according to the properties struct and configures display options
%   
%     APPLY_PROPERTIES(data, para_set, properties, measure_name, method) applies
%     the properties given in 'properties' on the data and configures the 
%     displaying. 
% 
%     'properties' has to be a structure that contains a field for each parameter
%     to be configured. Those have to named according to the measure names
%     (as they appear in results.para_names).
% 
%     Example: properties.para_1
%            properties.para_3 % using default values for para_2
% 
%     Within those fields the following information is given:
% 
%     - Which values of the parameter shall be used?
% 
%       You can define a subset of the parameter space to be used for evaluation.
%       This is especially necessary if there are many parameters as 
%       you can at most plot three-dimensional.
% 
%       The values to be used are defined by a cell assigned to the field 
%       'values'.
% 
%           Example: properties.para_1.values = {1, 2, 3};
% 
%       Alternatively you can average over the parameter by assigning '#AVG'
%       or use all values by the shortcut '#ALL'.
% 
%           Example: properties.para_3.values = '#AVG';
% 
%       If no values are given '#ALL' of them are used.
% 
%     - How shall the parameter dimension be plotted?
% 
%       For tables you always have to define one parameter to be printed in x- and one 
%       to be printed in y-direction.
% 
%       For plots you don't need the y-direction if plotting two-dimensional.
%       In addition you can create new windows, new subplots or plots in
%       different colors for the different parameter values.
% 
%       Those options are given within the field 'disp'. The specifiers are:
%           - 'plot_x' (plot in x-direction)
%           - 'plot_y' (plot in y-direction)
%           - 'win' (new window for each parameter value)
%           - 'hor' (new horizontal subplot for each parameter value)
%           - 'ver' (new vertical subplot for each parameter value)
%           - 'col' (graph of different color for each parameter value)
% 
%           Example: properties.para_1.disp = 'plot_x'
% 
%     - How shall the axes be labeled? (optional)
% 
%       You can assign new labels and tick-labels to the axis. Those are given
%       in the fields 'label' and 'tick_labels'. 'tick labels' has to be a 
%       cell of length equal to the number of different parameter values. 
% 
%           Example: properties.para_1.label = 'Parameter 1';
%                    properties.para_1.tick_labels = {'one', 'two', three'};
% 
%       If no labels are given the parameter names and values are used 
%       (see also: queue.internal.value2str). 
% 
%     If measures are not scalars you can also assign properties to the measure 
%     dimensions in the same way. They can be accessed by adding an underscore 
%     and the dimension number to the name (see fieldnames of results.data).
% 
%       Example: properties.my_measure_2.values = '#AVG' 
%                averages over the second dimension of measure 'my_measure'
%
%     You can also use specific indices.
%     Example: properties.my_measure_2.values = {1,2}
%                selects the first two entries in the second dimension
%
%     If evaluation method is not 'single_table' or 'data' complex data is 
%     represented as an extra dimension seperating the real and the imaginary 
%     part. This extra dimension can also be accessed by an underscore. For 
%     example for scalar complex numbers
%
%        Example: properties.complex_measure_1.values = 1
%                 selects the real part of 'complex_measure'
% 
%     TODO(?): custom function, i.e. for weighting of parameter values
%
% Copyright (c) 2017, Christian Rohlfing, Julian Becker, Jens Schneider, Patrick Wilken, Tobias Kabzinski
   
    if nargin < 6, dataSelectionOnly = 0; end
    % Initialization
    if strcmpi(method, 'tables')
        disp_options.other_parameters.label = {};
        disp_options.other_parameters.tick_labels = {};
        disp_options_str = {'plot_x', 'plot_y'};
        
    elseif ~any(strcmpi(method, {'data', 'single_table'}))
        disp_options = struct();
        disp_options_str = {'plot_x', 'plot_y', 'win', 'hor', 'ver', 'col'};
    else
        disp_options = struct(); % not used for 'data' or 'single_table'
    end    
    
    % Calculate number of measure dimensions
    ndim_measure = find(size(data) ~= 1, 1, 'last') - length(para_set.para_names);
    
    % Create measure names
    for measure_dim = 1:ndim_measure
       para_set.para_names{end + 1} = [measure_name, '_', int2str(measure_dim)];
       para_set.para_values{end + 1} = num2cell(1:size(data, length(para_set.para_names)));
    end

    % Apply value options
    data_indices = cell(ndims(data),1);
    for para_id = 1:length(para_set.para_names) 
        value_field = [para_set.para_names{para_id}, '.values']; 
        
        % If values were put directly in the parameter field (without .values) use those (this way you get the data for an instance of p from submission)
        if iscell(para_set.para_names{para_id})
            value_field = para_set.para_names{para_id};
        else
            value_field = [para_set.para_names{para_id}, '.values'];
        end
        
         % Default value option is 'use all'
        if ~queue.internal.isfield_by_str(properties, value_field) || ...
            (~any(cellfun(@isempty,para_set.para_values{para_id})) && isempty(queue.internal.getfield_by_str(properties, value_field))) || ...
            all(strcmp(queue.internal.getfield_by_str(properties, value_field), '#ALL'))
            properties = queue.internal.setfield_by_str(properties, value_field, para_set.para_values{para_id});
        end
        
        % Process data according to option
        [data,data_indices_id] = process_data(data, para_id, queue.internal.getfield_by_str(properties, value_field), para_set);
        data_indices{para_id} = data_indices_id{para_id};
    end
    if dataSelectionOnly, data = data_indices; return; end
    
    % Squeeze data while remembering names of non-singleton dimensions
    non_singleton_ids = size(data) ~= 1;
    non_singleton_para_names = para_set.para_names(non_singleton_ids);
    non_singleton_para_values = para_set.para_values(non_singleton_ids);
    non_singleton_ndim_measure = sum(non_singleton_ids(length(para_set.para_names) - ndim_measure + 1 : end));
    data = squeeze(data); 
    
    if ~any(strcmpi(method, {'data', 'single_table'}))
        % Initialize numel for all window dimensions with 1
        for disp_str_id = 1:length(disp_options_str)
            disp_options.(disp_options_str{disp_str_id}).numel = 1;
        end

        % Stores whether display options are already assigned
        disp_option_assigned = false(length(disp_options_str), 1);

        % Iterate through all parameters and check display options
        for para_id = 1:length(non_singleton_para_names)

            % Check if display option given
            if queue.internal.isfield_by_str(properties, [non_singleton_para_names{para_id}, '.disp'])
                disp_str = queue.internal.getfield_by_str(properties, [non_singleton_para_names{para_id}, '.disp']);

                % Check if display option string
                if ~ischar(disp_str)
                    error('Display option for parameter ''%s'' has to be a string!', non_singleton_para_names{para_id})
                end
                
                % Check if display option is valid
                [disp_valid, disp_option_id] = ismember(disp_str, disp_options_str);
                if disp_valid

                    % Check if display option was assigned before
                    if ~disp_option_assigned(disp_option_id)

                        % Store parameter dimension
                        disp_options.(disp_str).dim = para_id;

                        % Assign label to current dimension
                        disp_options.(disp_str).label = get_label(properties, non_singleton_para_names{para_id}); 

                        % Assign tick labels for current dimension
                        disp_options.(disp_str).tick_labels = get_tick_labels(properties, non_singleton_para_names{para_id}); 

                        % Remember that current display option is used up
                        disp_option_assigned(disp_option_id) = true;

                        % Store number of elements in current dimension (makes displaying more convenient) 
                        disp_options.(disp_str).numel = size(data, para_id);
                    else
                        % Error if display option was assigned before
                        error('Display options must be assigned uniquely. ''%s'' was used twice or more!', disp_str)
                    end
                else
                    if ~strcmpi(method, 'tables')
                        % Error if given display option does not exist for plotting (as it is necessary)
                        error('Display option for parameter ''%s'' is invalid!', non_singleton_para_names{para_id})
                    else
                        % Just warning in case of tables (because number of dimensions is not restricted)
                        warning('Display option for parameter ''%s'' is invalid. Ignoring it.', non_singleton_para_names{para_id})
                        
                        % Treat as one of 'other' parameters
                        disp_options.other_parameters.label{end + 1, 1} = get_label(properties, non_singleton_para_names{para_id});
                        disp_options.other_parameters.tick_labels{end + 1, 1} = get_tick_labels(properties, non_singleton_para_names{para_id});
                    end
                end

            % If parameter is non-singlton and it is not a measure dimension display option is mendatory for plots  
            elseif ~strcmpi(method, 'tables') && para_id < length(non_singleton_para_names) - non_singleton_ndim_measure + 1
                str = cellfun(@(x)[queue.internal.value2str(x),' '],non_singleton_para_values{para_id},'UniformOutput',false);
                str = [str{:}];
                error('Dimension of parameter ''%s'' is non-singleton. You have to specify how to plot it by giving a display option (disp) or fix the values (values)!\nAll values: %s', non_singleton_para_names{para_id},str)
            
            % In case of table add all non specified parameters to 'other_parameters' field   
            elseif strcmpi(method, 'tables')
                disp_options.other_parameters.label{end + 1, 1} = get_label(properties, non_singleton_para_names{para_id});
                disp_options.other_parameters.tick_labels{end + 1, 1} = get_tick_labels(properties, non_singleton_para_names{para_id});non_singleton_para_values = para_set.para_values(non_singleton_ids);
            end
        end        

        % Lookup for plot string 
        plot_xy = {'plot_x', 'plot_y'};

        % Automatically assign remaining measure dimension to the free plot axes
        for para_id = length(non_singleton_para_names) - non_singleton_ndim_measure + 1: length(non_singleton_para_names)
            if ~queue.internal.isfield_by_str(properties, non_singleton_para_names{para_id}) || ~queue.internal.isfield_by_str(properties, [non_singleton_para_names{para_id}, '.disp'])
                disp_option_id = find(~disp_option_assigned, 1, 'first');
                if disp_option_id <= 2
                    plot_str = plot_xy{disp_option_id};
                    disp_options.(plot_str).dim = para_id;
                    disp_options.(plot_str).label = get_label(properties, non_singleton_para_names{para_id});
                    disp_options.(plot_str).tick_labels = get_tick_labels(properties, non_singleton_para_names{para_id});
                    disp_options.(plot_str).numel = size(data, para_id);
                    disp_option_assigned(disp_option_id) = true;
                else
                    if strcmpi(method, 'tables')
                        error('There are too many dimensions to be displayed! The sum of the number of plot parameters and measure dimensions has to be 2.')
                    else
                        error('There are too many dimensions to be plotted! The sum of the number of plot parameters and measure dimensions has to be 2 or 3.')
                    end
                end   
            end
        end

        % Decide if 2D or 3D plot
        ndim_to_plot = sum(disp_option_assigned(1:2));

        % Define valid plot functions depending on dimensions and choose default if none given
        switch ndim_to_plot
            case 1
                
                % Set supported graph functions for plotting
                if ~strcmpi(method, 'tables')
                    supported_graph_functions = {'plot', 'bar', 'bar3', 'barh', 'bar3h', 'loglog', 'semilogx', 'semilogy'};                  
                end
                
                % Use 'plot' as default
                default_method = 'plot';

                % For one dimensional data use x instead of y
                if disp_option_assigned(2)
                    disp_options.plot_x = disp_options.plot_y;
                    disp_options = rmfield(disp_options, 'plot_y');
                    disp_options.plot_y.numel = 1;
                end

                % Store label for measure values
                disp_options.plot_y.label = get_label(properties, measure_name);

            case 2
                % Set supported graph functions
                if ~strcmpi(method, 'tables')
                    supported_graph_functions = {'surf', 'surfc', 'mesh', 'meshc', 'imagesc', 'image'};
                end
                
                % Use 'surf' as default
                default_method = 'surf';
   
                % Store label for measure values
                disp_options.plot_z.label = get_label(properties, measure_name);

            otherwise        
                % If number of dimensions is not 1 or 2 no plot can be created
                error(['Plotting of %d dimensions is not supported! '...
                    'Please adjust properties so that number of plotting parameters and measure dimensions add up to 1 or 2.'], ndim_to_plot) 
        end
        
        if ~strcmpi(method, 'tables')
            % Check if graph function is valid considering the number of plot dimensions
            if ~ischar(method) || ~ismember(method, supported_graph_functions)
                warning('Graph function invalid or not suitable for a plot of %d dimensions! Using ''%s'' instead', ndim_to_plot, default_method)
                method = default_method;
            end

            % Store graph_function
            disp_options.graph_function = method;
        end
    end
    
    % If necessary return parameter names and parameter values to output filtered results
    if nargout > 2
        varargout{1} = non_singleton_para_names;
        varargout{2} = cellfun(@(x) queue.internal.getfield_by_str(properties, [x, '.values']), non_singleton_para_names, 'UniformOutput', false);
        varargout{3} = data_indices;
    end
end


function [data,data_indices] = process_data(data, para_id, values, para_set)
% This function processes the 'values' field of the properties struct for
% each parameter. Either 'data' is averaged over one dimension or it is
% reduced to the indexes corresponding to the given parameter values. 
%%
    % If specifier '#AVG' given...
    data_indices = repmat({':'}, ndims(data), 1);
    if ischar(values) && strcmp(values, '#AVG')
        % ...apply averaging
        data = mean(data, para_id);
        data_indices{para_id} = '#AVG';
    % If values are given 
    elseif ~isequal(values, para_set.para_values{para_id})
        
        % Also use cell for single value
        converted = false;
        if ~iscell(values)
            values = {values};
            % Remember this for different error messages
            converted = true;
        end
        
        % Search for the given values in all values to get indices (similar to 'translate_ids')
        id_mapping = [];
        for chosen_value_id = 1:numel(values);
            % Get chosen value
            chosen_value = values{chosen_value_id};
            
            chosen_value_found = false;
            for para_value_id = 1:numel(para_set.para_values{para_id})
                % Get one value of whole set
                para_value = para_set.para_values{para_id}{para_value_id};
                
                % Deal with precision error of floats (for example when using colon operator)
                floatcompare = 0;
                if isfloat(chosen_value) && isfloat(para_value) && isequal(size(chosen_value), size(para_value))
                    floatcompare = abs(chosen_value - para_value) <= eps(chosen_value);
                end
                
                % When found store new id
                if isequal(chosen_value, para_value) || all(floatcompare(:))
                    id_mapping(end + 1) = para_value_id; %#ok<AGROW>
                    chosen_value_found = true;
                    break;
                end
            end
            
            % If value not in set display error
            if ~chosen_value_found
                if converted
                    % Case of single value that was converted to cell, therefore most likely wrong usage of the values field
                    error('Values for parameter %s not valid. Make it a keyword (''#ALL'', ''#AVG'') or a cell of parameter values.', para_set.para_names{para_id}) % TODO Add help command
                else
                    % Case of several values given in a cell, therefore most likely a wrong value by mistake
                    error('Some chosen parameter values for parameter ''%s'' are not contained in the parameter space!', para_set.para_names{para_id});
                end
            end
        end

        % Reduce data to the chosen values
        data_indices{para_id} = id_mapping;
        data = data(data_indices{:});    
    end
end

function label = get_label(properties, para_name)
% This function processes the 'label' field of the properties structure.
% Either the given label is checked and assigned or a standard label is
% generated.
%%
    % Default label is parameter name
    label = para_name;
    
    % If label was given...
    if queue.internal.isfield_by_str(properties, para_name) && queue.internal.isfield_by_str(properties, [para_name, '.label'])
        % ...use that one
        given_label = queue.internal.getfield_by_str(properties, [para_name, '.label']);

        % Check label
        if ischar(given_label)
            % Assign it
            label = given_label;
        else
            % If not valid use default
            warning('Invalid label for parameter ''%s''. Using ''%s'' instead.', para_name, label)
        end
    end
end

function tick_labels = get_tick_labels(properties, para_name)
% This function processes the 'tick_labels' field of the properties structure.
% Either the given labels are checked and assigned or standard labels are
% generated.
%%

    % Tick label only assigned for non-singular dimensions, for others empty string is returned
    tick_labels = '';
    
    % Default tick labels are given values
    values = queue.internal.getfield_by_str(properties, [para_name, '.values']);
    if iscell(values)
        % Generate tick labels for parameter values
        [tick_labels, proper_flag] = cellfun(@queue.internal.value2str, queue.internal.getfield_by_str(properties, [para_name, '.values']), 'UniformOutput', false);
        
        % Always use row vectors
        tick_labels = tick_labels(:)';
        proper_flag = proper_flag(:)';
        
        if ~all(cell2mat(proper_flag))
            % If tick not properly assigned (just consists of class) add an index (i.e. [struct]<1>)
            for tick_id = find(~cell2mat(proper_flag))
                tick_labels{tick_id} = [tick_labels{tick_id}, '<', int2str(tick_id), '>'];
            end
        end
        
        % If label was given...
        if queue.internal.isfield_by_str(properties, para_name) && queue.internal.isfield_by_str(properties, [para_name, '.tick_labels'])
            % ...use that one
            given_tick_labels = queue.internal.getfield_by_str(properties, [para_name, '.tick_labels']);

            % Check labels
            if iscell(given_tick_labels) && all(cellfun(@ischar, given_tick_labels)) && length(tick_labels) == length(given_tick_labels);
                % Assign them
                tick_labels = given_tick_labels;
            else
                % If not valid use defaults
                warning('Invalid tick labels for parameter ''%s''. Using defaults instead.', para_name)
            end
        end
    end
end