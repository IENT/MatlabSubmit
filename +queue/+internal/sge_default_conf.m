function conf = sge_default_conf()
%DEFAULT_CONFIG generates the default config
%
% Copyright (c) 2017, Christian Rohlfing, Julian Becker, Jens Schneider, Patrick Wilken, Tobias Kabzinski

conf = struct();
conf.job_system = 'sge';
conf.architecture = '';
conf.collect_output = 1;
conf.collect_write_period = Inf;
conf.fun_handle = @disp;
conf.job_name = 'Matlab_Queue_Job';
conf.local_disk_space = '';
conf.matlab_cmd_para = '-singleCompThread -nojvm -nosplash -nodisplay -r';
conf.matlab_path_lin = '/tools/matlab2016b/bin/matlab';
conf.matlab_path_mac = '/tools/matlab2014b/MATLAB_R2014b.app/bin/matlab';
conf.memory_limit = '2G';
conf.priority = '-512';
conf.project_name = '';
conf.result_dir = '/scratch/$USER/queue_results';
conf.server_names = 'SuperKnechte,MegaKnechte';
conf.tmp_dir = '/scratch/$USER/tmp';
conf.queue_command = 'qsub %s/%s_script.sh';
end
