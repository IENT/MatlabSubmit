function copy_old_results(combo_ids_same, para_set, conf, missing_ext_ids)
% COPY_OLD_RESULTS create output mat-files filled with results of previous run
%
% Copyright (c) 2017, Christian Rohlfing, Julian Becker, Jens Schneider, Patrick Wilken, Tobias Kabzinski
    
    % Load full output collector from previous run
    old_full = load([conf.result_dir, filesep, conf.job_name, filesep, 'full.mat'], 'output_collector');
    
    % Use number of total combinations to distinguish mat-files of different runs
    run_id_current = para_set.int_comb_count * para_set.ext_comb_count;
    
    % Find out wich output files have to be loaded
    ext_ids_to_check = unique(ceil(combo_ids_same / para_set.int_comb_count));
    if ~isempty(missing_ext_ids)
        ext_ids_to_check = intersect(missing_ext_ids, ext_ids_to_check);
    end
    
    % Iterate over external ids
    for new_ext_id = ext_ids_to_check
        
        path_to_output_mat = [conf.result_dir, filesep, conf.job_name, filesep, num2str(new_ext_id) '.mat'];
        run_id = 0;
        
         % Check for output mat and load run id
        if exist(path_to_output_mat, 'file')
            load(path_to_output_mat, 'run_id')
        end
        
        % Check if output mat belongs to current run
        if run_id == run_id_current
            % Load output collector
            load(path_to_output_mat, 'output_collector')
        else
            % Create and save empty output collector
            output_collector = cell(1, para_set.int_comb_count);
            run_id = run_id_current; %#ok<NASGU>
            save(path_to_output_mat, 'output_collector', 'run_id', '-v7')
        end
        
        % Get indices for old combination ids
        I_old_combo_id = (new_ext_id - 1) * para_set.int_comb_count < combo_ids_same & combo_ids_same <= new_ext_id * para_set.int_comb_count;
        
        % Copy results and save
        output_collector(combo_ids_same(I_old_combo_id) - (new_ext_id - 1) * para_set.int_comb_count) = old_full.output_collector(I_old_combo_id);
        save(path_to_output_mat, 'output_collector', '-append')
    end       
end

