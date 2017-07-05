function [axes_handles] = display_plots(data, disp_options)
%DISPLAY_PLOTS generates plots of data according to the given display options
%
% Copyright (c) 2017, Christian Rohlfing, Julian Becker, Jens Schneider, Patrick Wilken, Tobias Kabzinski  

    % Ask if number of windows is too high    
    if disp_options.win.numel > 20
        reply = input(sprintf('Do you really want to display %d windows? [y/N]\n', disp_options.win.numel),'s');
        if ~isempty(reply) && ~strcmpi(reply, 'y')
            return;
        end
    end
    
    % Get screen size
    screen_size = get(groot,'ScreenSize');
    
    % Define minimum window size
    min_width = screen_size(3)/3;
    min_height = screen_size(4)/3;
    
    % Calculate appropriate window size depending on number of subplots
    plot_size = screen_size(3)/5;
    win_width = max(min_width, disp_options.hor.numel * plot_size);
    win_height = max(min_height, disp_options.ver.numel * plot_size);

    % Arrays to store figure and axes handles
    figure_handles = cell(disp_options.win.numel, 1);
    axes_handles = cell(disp_options.win.numel, disp_options.ver.numel, disp_options.hor.numel);

    % Iterate over windows to plot
    for win_id = 1:disp_options.win.numel
        
        % Initialize data indices
        data_indices = repmat({':'}, ndims(data), 1);

        % Create new figure (using window label if possible)
        if disp_options.win.numel > 1
            figure_handles{win_id} = figure('name', [disp_options.win.label, ' = ',  disp_options.win.tick_labels{win_id}]);
        else
            figure_handles{win_id} = figure;
        end
        
        % Set figure size (centered on screen)
        set(figure_handles{win_id}, 'Position', [max(0, screen_size(3) - win_width)/2, max(0, screen_size(4) - win_height)/2, win_width, win_height]);
        figure_handles{win_id}.Position(4)=figure_handles{win_id}.Position(4)-100;

        % Set data index of window dimension to current window id
        if isfield(disp_options.win, 'dim') 
            data_indices{disp_options.win.dim} = win_id;
        end
        
        % Find out maximum and minimum data value in this window
        data_win = data(data_indices{:});
        data_min = min(data_win(:));
        data_max = max(data_win(:)); 
        
        % Iterate over vertical subplots
        subplot_id = 0;
        for ver_id = 1:disp_options.ver.numel
                      
            ver_str = '';
            % If vertical subplot dimension non-singleton...
            if disp_options.ver.numel > 1
                % ...set data index of vertical subplot dimension to current vertical id
                data_indices{disp_options.ver.dim} = ver_id;
                
                % Create part of titel for subplot that displays parameter values
                if disp_options.ver.numel > 1
                    ver_str = [disp_options.ver.label, ' = ',  disp_options.ver.tick_labels{ver_id}, ' '];
                end
            end
            
            % Iterate over horizontal subplots
            for hor_id = 1:disp_options.hor.numel
                
                hor_str = '';
                % If horizontal subplot dimension non-singleton...
                if disp_options.hor.numel > 1
                    % ...set data index of horizontal subplot dimension to current horizontal id
                    data_indices{disp_options.hor.dim} = hor_id;
                    
                    % Create part of titel for subplot that displays parameter values
%                     if disp_options.ver.numel > 1
                        hor_str = [disp_options.hor.label, ' = ',  disp_options.hor.tick_labels{hor_id}];
%                     end
                end
                
                % Create subplot
                subplot_id = subplot_id + 1;
                axes_handles{win_id, ver_id, hor_id} = subplot(disp_options.ver.numel, disp_options.hor.numel, subplot_id);
                
                % Define colors to be used
                colors = hsv(disp_options.col.numel);
                
                % Hold on, for plots of different color
                hold(axes_handles{win_id, ver_id, hor_id}, 'on'); 
                grid(axes_handles{win_id, ver_id, hor_id}, 'on'); 
                
                % Iterate over plots of different color
                legend_objects = cell(1,disp_options.col.numel);
                for col_id = 1:disp_options.col.numel
                    
                    % If color dimension non-singleton
                    if isfield(disp_options.col, 'dim')
                        % ...set data index of horizontal subplot dimension to current horizontal id
                        data_indices{disp_options.col.dim} = col_id;
                    end           
                    
                    % Apply data indexes and squeeze dimensions
                    data_to_plot = squeeze(data(data_indices{:}));
                    
                    % Get right order of plot axes for 3D plots
                    if ~isvector(data_to_plot) 
                        [~, order] = sort([disp_options.plot_x.dim, disp_options.plot_y.dim], 2, 'descend'); % second dimension will be plotted on x-axis
                        data_to_plot = permute(data_to_plot, order);
                    end
                    
                    % This shouldn't happen...
                    if ~ismatrix(data_to_plot)
                        error('Bug! More than two dimensions left.')
                    end
                    
                    % Get graph function handle
                    graph_handle = str2func(disp_options.graph_function);
                    
                    % Create plot according to graph function
                    switch disp_options.graph_function
                        % Line plots
                        case {'plot', 'loglog', 'semilogx', 'semilogy'}                   
                            legend_objects{col_id} = graph_handle(axes_handles{win_id, ver_id, hor_id}, data_to_plot, 'color', colors(col_id,:)); 
                           
                        % Bar plots    
                        case {'bar', 'bar3', 'barh', 'bar3h'}  
                            graph_obj_handle = graph_handle(axes_handles{win_id, ver_id, hor_id}, data_to_plot, 'FaceColor', colors(col_id,:));
                            
                            % When using different colors make plots transparent (also not neat but colors should be supported)
                            if disp_options.col.numel > 1
                                set(get(graph_obj_handle, 'child'), 'facea', 0.3);
                            end
                            
                        % 3D-plots    
                        case {'surf', 'surfc', 'mesh', 'meshc'}
                            graph_obj_handle = graph_handle(axes_handles{win_id, ver_id, hor_id}, data_to_plot);
                            
                            % When using different colors make plots single-colored and transparent
                            if disp_options.col.numel > 1
                                set(graph_obj_handle, 'FaceColor', colors(col_id,:), 'FaceAlpha', 0.6);
%                                 set(figure_handles{win_id}, 'Renderer', 'zbuffer');
                            end
                            
                            % Get appropriate number of tick labels
                            step_y = 1;
                            if disp_options.plot_y.numel > 5
                                step_y = round(disp_options.plot_y.numel/5);
                            end
                            
                            % Set tick labels for y-axis
                            set(axes_handles{win_id, ver_id, hor_id}, 'YTick', 1:step_y:disp_options.plot_y.numel, 'YTickLabel', disp_options.plot_y.tick_labels(1:step_y:end));
                            
                            % Set y-axis limits
                            set(axes_handles{win_id, ver_id, hor_id}, 'YLim', [-1, disp_options.plot_y.numel + 1]);
                    
                            % Set label for z-axis
                            zlabel(axes_handles{win_id, ver_id, hor_id}, disp_options.plot_z.label, 'Interpreter', 'none');
                            
                        % Image plots    
                        case {'image', 'imagesc'}
                            % Turn hold off (otherwise white edges, MATLAB bug?)
                            hold(axes_handles{win_id, ver_id, hor_id}, 'off');
                            
                            % Plots of different color make no sense when using imagesc
                            if disp_options.col.numel > 1
                                error('Color option cannot be used in combination with ''image'' or ''imagesc''!');
                            end
                            graph_handle(data_to_plot, 'Parent', axes_handles{win_id, ver_id, hor_id});
                    end
                    
                    % Set title of subplot (not before here because imagesc somehow deletes title)
                    title(axes_handles{win_id, ver_id, hor_id}, [ver_str(end-min(19,length(ver_str)-1):end), hor_str(end-min(19,length(hor_str)-1):end)], 'Interpreter', 'none');
                
                    % Set axis labels (common to 2D and 3D plots)
                    xlabel(axes_handles{win_id, ver_id, hor_id}, disp_options.plot_x.label, 'Interpreter', 'none');
                    ylabel(axes_handles{win_id, ver_id, hor_id}, disp_options.plot_y.label, 'Interpreter', 'none');
                    
                    % Get appropriate number of tick labels
                    step_x = 1;
                    if disp_options.plot_x.numel > 5
                        step_x = round(disp_options.plot_x.numel/5);
                    end
                    
                    % Set tick labels for x-axis
                    set(axes_handles{win_id, ver_id, hor_id}, 'XTick', 1:step_x:disp_options.plot_x.numel, 'XTickLabel', disp_options.plot_x.tick_labels(1:step_x:end));
                    
                    % Set x-axis limits
                    set(axes_handles{win_id, ver_id, hor_id}, 'XLim', [-1, disp_options.plot_x.numel + 1]);
                end             
                
            end
        end
            
        
        % Create legend for top right plot if multiple colors are used
        if disp_options.col.numel > 1
            legend_handle = legend([legend_objects{:}], disp_options.col.tick_labels);
            
            % Put legend to upper left corner (because it is valid for all plots)
%             outer_postion = get(legend_handle, 'OuterPosition');
%             set(legend_handle, 'OuterPosition', [0, 1 - outer_postion(4), outer_postion(3), outer_postion(4)]);
        end
    end
    % Store axes to be linked
        axes_handles_to_link = axes_handles;
        
        % Adjust appeareance of all subfigures in current window 
        if isvector(data_to_plot) 
            % Link axes between subfigures in 2D-Plots
            linkaxes([axes_handles_to_link{:}]);
                        
            plot_axis_letter = 'y';         
        else
            if ~any(strcmp(disp_options.graph_function, {'image', 'imagesc'}))
                
                % Link camera position and target (properties of first subplot will be used)
                linkprop_handle = linkprop([axes_handles_to_link{:}], {'View', 'CameraPosition', 'CameraTarget', 'CameraViewAngle', 'XLim', 'YLim'});
                
                % Link handle has to be stored, otherwise linking is unset when creating next figure
                setappdata(figure_handles{win_id}, ['linkprop_handle_', int2str(win_id)], linkprop_handle);
                
                % Avoid weird jumping of figure (found out by trial and error...)
                set([axes_handles_to_link{:}], 'XLimMode', 'manual', 'YLimMode', 'manual', 'ZLimMode', 'manual', 'CameraPositionMode', 'auto', 'CameraTargetMode', 'auto', 'CameraViewAngleMode', 'auto');  
                
                % Set appropriate point of view
                view(axes_handles_to_link{1}, 25, 25);

            else
                % Link axes for images
                linkaxes([axes_handles_to_link{:}]);
            end      
            
            plot_axis_letter = 'z';
        end
        
        % Set limits of data axis
        data_min = min(data(:));
        data_max = max(data(:));
        set([axes_handles_to_link{:}], [plot_axis_letter, 'lim'], [data_min * 0.99 - (data_max - data_min)*0.1, data_max * 1.01 + (data_max - data_min)*0.1]);
        
end               

