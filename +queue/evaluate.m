function varargout = evaluate(results, method, properties, measures)
%EVALUATE create plots or tables out of results from cluster submission
%
%     EVALUATE(results) creates a single, possibly big table containing the
%     results for all numeric measures of your submition.
%
%     results = EVALUATE(...) returns the part of the results used for evaluation
%
%     EVALUATE(results, method, properties) lets you choose an evaluation method.
%     Possible values are:
% 
%       - 'single_table': Create a single table with all data (default)
%       - 'tables': Create a table for each parameter combination 
%       - 'plot', 'bar', 'bar3', 'barh', 'bar3h', 'loglog', 'semilogx' or 'semilogy': Create 2D plots
%       - 'surf', 'surfc', 'mesh', 'meshc', 'image' or 'imagesc': Create 3D plots  
%       - 'data': Just return data
% 
%     The 'data' option is useful to filter data (create subset or average over
%     certain parameters).
%
%     For all methods exept for 'single_table' and 'data' a configuration via a
%     properties struct is mendatory. 'properties' is a structure with fields for 
%     each input parameter that configures how to plot its dimension of the 
%     results array. Type 'help queue.internal.apply_properties' to see the 
%     required structure of 'properties'.
% 
%     Example: (continuing from submit_job example) 
%       % Create properties struct:
%       properties.para1.disp = 'plot_x'; % plot 'para1' along x-axis 
%       properties.para2.disp = 'plot_y'; % plot 'para2' along y-axis
%
%       % Start evaluation 
%       queue.evaluate(results, 'surf', properties);
% 
%     EVALUATE(results, method, properties, measures) only evaluates the measures 
%     given in 'measures'. It has to be a cell containing the measure names as 
%     they appear in the fieldnames of 'results.data'. If the measures have 
%     different number of dimensions and the evaluation method is 'tables' 
%     or some plot function giving measures is required as otherwise the 
%     dimensions of the data cannot be suitable for the evaluation method 
%     in every case.
%     
%     Example: (continuing from submit_job example)
%        % Create properties struct:
%        properties.para1.disp = 'plot_x'; % plot 'para1' along x-axis 
%        properties.para2.disp = 'hor'; % create horizontal subfigur for every value of 'para2' 
%        
%        % Start evaluation (using bar plots)
%        queue.evaluate(results, 'bar', properties, 'my_measure');
% 
%     You can give several methods, properties and measures by using cells! 
%     For this the length of the cells has either to be one or equal to the lengths
%     of the other input cells. If only one properties method/struct/measure
%     is given it will be used for all evaluations. If there are several there
%     will be an evaluation for all first cell contents, all second ones and so on.
% 
%     Examples: 
%       % Create properties structs:
%        properties_plot.para1.disp = 'plot_x'; % plot 'para1' along x-axis 
%        properties_plot.para2.disp = 'col'; % use new color for every value of 'para2' 
%
%        properties_table.para1.disp = 'plot_x'; % display 'para1' in rows of table
%        properties_table.para2.disp = 'plot_y'; % display 'para1' in columns of table 
%       
%       % Start evaluation (create table and plots for the same measure) 
%       queue.evaluate(results, {'tables', 'plot'}, {properties_table, properties_plot}, 'my_measure')'; 
% 
%     See also: queue.internal.apply_properties
%               queue.internal.display_tables
%               queue.internal.display_plots
%
% Copyright (c) 2017, Christian Rohlfing, Julian Becker, Jens Schneider, Patrick Wilken, Tobias Kabzinski
 

    % Set default values
    if nargin < 2 || isempty(method)
        method = 'single_table';
    end
        
    if nargin < 3
        properties = struct();
    end

    % Get usual para set from results struct
    para_set = rmfield(results, 'data');
    
     % Get all measure names
    all_measures = queue.internal.get_para_names(results.data);
    
    % Except for method 'data'...
    if ~strcmp(method, 'data')      
        % ...only use numeric measures
        numeric_measures = all_measures(cellfun(@(x) isnumeric(queue.internal.getfield_by_str(results.data, x)), all_measures));

        if ~any(strcmp(method, {'single_table', 'data'}))
            % Get all complex measures
            complex_measures = numeric_measures(cellfun(@(x) ~isreal(queue.internal.getfield_by_str(results.data, x)), numeric_measures));

            % Split complex measures into real and imaginary part
            for complex_measure_id = 1:length(complex_measures)
                % Get measure data
                measure_data = queue.internal.getfield_by_str(results.data, complex_measures{complex_measure_id});

                new_measure_data = zeros([size(measure_data), 2]);
                new_ndim_measure = find(size(new_measure_data) ~= 1, 1, 'last');

                indices = repmat({':'}, [1, new_ndim_measure]);
                indices{end} = 1;
                new_measure_data(indices{:}) = real(measure_data);
                indices{end} = 2;
                new_measure_data(indices{:}) = imag(measure_data);

                % Assign real and imaginary part to new parameter
                results.data = queue.internal.setfield_by_str(results.data, complex_measures{complex_measure_id}, new_measure_data);        
            end
        end
    else
        % Pretend all measures were numeric for 'data' method
        numeric_measures = all_measures;
    end
    
    % Also use cell for single properties struct and method
    if ~iscell(properties)
        properties = {properties};
    end
    if ~iscell(method)
        method = {method};
    end    
        
    % Use all numeric measures if list of measures not given
    if nargin < 4 || isempty(measures)
        measures = numeric_measures;
    else   
        % Also use cell for single measures
        if ~iscell(measures)
            measures = {measures};
        end  

        % Check if measures are valid
        measure_exists = ismember(measures, all_measures);
        measure_numeric = ismember(measures, numeric_measures);

        if ~all(measure_exists)
            error('At least one specified measure does not occur in the results!')
        end
        if ~all(measure_numeric)
            error('At least one specified measure is not numeric. Only numeric measures can be evaluated!')
        end
    end
    
    % Check if several properties struct but single table
    if any(strcmp(method, 'single_table')) && length(properties) > 1
        error('You cannot have several properties structs when creating a single table!')
    end
    
    % Determine number of evaluations
    num_of_evals = max([length(properties), length(measures), length(method)]);
    
    % Use single property struct/measure/method for all evaluations
    single_properties_flag = false;
    if length(properties) == 1
        properties = cellfun(@(x) properties, cell(num_of_evals, 1));
        single_properties_flag = true;
    end
    single_measure_flag = false;
    if length(measures) == 1
        measures = cellfun(@(x) measures, cell(num_of_evals, 1));
        single_measure_flag = true;
    end
    if length(method) == 1
        method = cellfun(@(x) method, cell(num_of_evals, 1));
    end
    
    % Check consistency of measures, properties and methods
    if ~all([length(properties), length(method)] == num_of_evals)
        error('Number of measures, properties and methods does not match. You have to pass either a single properties struct / method or one for each measure.')
    end
    
    % Initialize output cell depending on number of required outputs
    if nargout == 0 && ~any(strcmp(method, 'single_table'))
        outputs = cell(2, 1);
    else
        outputs = cell(4, 1);
        
        % If data is outputted initialize results struct to store it 
        current_filtered_results = struct();
        
        % If we have different properties for the same measure we have to output several results structs, therefore initialize cell
        filtered_results = {};     
    end
    
%     close all;   
    axes_handles = {};
    
    % Evaluate measures
    for measure_id = 1:length(measures)
        % Get data for current measure
        data = queue.internal.getfield_by_str(results.data, measures{measure_id});
        
        % Process data and create display options
        [outputs{:}] = queue.internal.apply_properties(data, para_set, properties{measure_id}, measures{measure_id}, method{measure_id});
        data = outputs{1};
        disp_options = outputs{2};
        
        % Generate plots or tables
        switch lower(method{measure_id})
            case {'data', 'single_table'}
                % Nothing to do here
            case 'tables'
                % Display table
                queue.internal.display_tables(data, disp_options);
            otherwise
                % Display plot
                current_axes_handles = {queue.internal.display_plots(data, disp_options)};
                axes_handles = [axes_handles, current_axes_handles]; %#ok<AGROW>
        end
        
        % Store data if it needs to be returned (if there is only one properties struct data will be the same for each measure, therefore only do this once)
        if (nargout > 0 || any(strcmp(method, 'single_table'))) && (~single_properties_flag || ~single_measure_flag || measure_id == 1)
            
            % Create result struct out of data, parameter names and values
            current_filtered_results = queue.internal.setfield_by_str(current_filtered_results, ['data.', measures{measure_id}], data);
            current_filtered_results.para_names = outputs{3}; % para_names
            current_filtered_results.para_values = outputs{4}; % para_values
            
            if single_measure_flag && ~single_properties_flag
                % For a single measure append current results to cell
                filtered_results = [filtered_results, {current_filtered_results}]; %#ok<AGROW>
            else
                % Otherwise just assign updated results struct
                filtered_results = current_filtered_results;
            end
        end
    end

    % Display single table
    if any(strcmp(method, 'single_table'))
        queue.internal.display_single_table(filtered_results);
    end
    
    % Return filtered results if necessary
    if nargout > 0
        % Don't use cell if just one results struct
        if iscell(filtered_results) && numel(filtered_results) == 1
            filtered_results = filtered_results{:};
        end
        varargout{1} = filtered_results;
    end
    
    if nargout > 1 
        % Don't use cell if just one axes handle array
        if numel(axes_handles) == 1
            axes_handles = axes_handles{:};
        end
        varargout{2} = axes_handles;
    end

end

