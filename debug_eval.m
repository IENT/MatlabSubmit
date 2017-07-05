function [filtered_results, handles] = debug_eval(results)
%DEBUG_EVAL tests the evaluate function of MATLAB SUBMIT
%
% Copyright (c) 2017, Christian Rohlfing, Julian Becker, Jens Schneider, Patrick Wilken, Tobias Kabzinski

    % Create parameter struct
    p.plot_x = num2cell(0:0.1:1);
    p.plot_y = num2cell(0:0.1:1);
    p.win = num2cell(5:0.5:7);
    p.hor = num2cell(-1:2);
    p.ver = num2cell(7:9);
    p.col = num2cell(3:0.1:3.3);
    
    p.external = {'win', 'hor', 'ver'};
        
    % Get rid of old results to be able to restart job
    if exist(sprintf('/scratch/%s/queue_results/MatlabSubmitEvalDebugging', getenv('USER')), 'dir')
        rmdir(sprintf('/scratch/%s/queue_results/MatlabSubmitEvalDebugging', getenv('USER')), 's');
    end
        
    % If results aren't given...
    if nargin < 1     
        % ...create configuration,...
        conf.job_name = 'MatlabSubmitEvalDebugging';
        conf.fun_handle = @debug_eval_function;
        
        % ...submit jobs,...
        queue.submit_job(p, conf, 1);
        
        % ...and collect results
        results = queue.collect_results(p, conf);
    end
      
    % Create properties struct for plots
    properties_plot.plot_x.values = '#AVG';
    properties_plot.plot_x.disp = 'plot_x';
    properties_plot.plot_x.label = 'plot_x_label';
    properties_plot.plot_x.tick_labels = {'eins','zwei','drei','vier','fünf','sechs','sieben','acht', 'neun', 'zehn', 'elf'};
    properties_plot.plot_y.values = '#AVG';
    properties_plot.plot_y.disp = 'plot_y';
    properties_plot.win.values = {5.5, 5};
    properties_plot.win.disp = 'win';
    properties_plot.win.label = 'Fenster';
    properties_plot.win.tick_labels = {'fünf', 'fünfkommafünf'};
    properties_plot.ver.disp = 'ver';
    properties_plot.hor.values = {-1, 2};
    properties_plot.hor.disp = 'hor';
    properties_plot.col.values = '#AVG';
    properties_plot.matrix_1.tick_labels = {'mat1', 'mat2'};
%     properties_plot.matrix_1.disp = 'plot_x';
    properties_plot.matrix_2.values = {1,2};
%     properties_plot.col.disp = 'col';
%     properties_plot.col.tick_labels = {'farbe1', 'farbe2', 'farbe3', 'farbe4'};
    

    % Create properties struct for tables
    properties_table.plot_x.values = num2cell(0:0.2:1);
    properties_table.plot_x.disp = 'plot_x';
    properties_table.plot_x.label = 'plot_x_label';
    properties_table.plot_y.values = '#ALL';
    properties_table.plot_y.disp = 'plot_y';
    properties_table.win.values = {5, 5.5};
    properties_table.win.label = 'TEST';
    properties_table.win.tick_labels = {'bla', 'test'};
    properties_table.hor.values = {-1, 2};
    properties_table.col.values = '#AVG';
%     properties_table.matrix_1.disp = 'plot_x';
%     properties_table.matrix_2.disp = 'plot_y';
%     
    % Start evaluation  
%     filtered_results = queue.evaluate(results, {'tables', 'plot'}, {properties_table, properties_plot}, 'scalar');
    filtered_results = queue.evaluate(results, 'surf', properties_plot, 'matrix');
%     [filtered_results, handles] = queue.evaluate(results, {'tables', ''}, {properties_table, properties_plot}, 'vector');
    
end

