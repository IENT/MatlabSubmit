function conf = lsf_default_conf()
%DEFAULT_CONFIG generates the default config
%
% Copyright (c) 2017, Christian Rohlfing, Julian Becker, Jens Schneider, Patrick Wilken, Tobias Kabzinski

conf = struct();
conf.job_system = 'lsf';
conf.architecture = '';
conf.collect_output = 1;
conf.collect_write_period = Inf;
conf.fun_handle = @disp;
conf.job_name = 'Matlab_Queue_Job';
conf.local_disk_space = '';
conf.matlab_cmd_para = '-singleCompThread -nojvm -nosplash -nodisplay -r';
conf.matlab_path_lin = 'matlab';
conf.matlab_path_mac = '';
conf.memory_limit = '2000';
conf.priority = '';
conf.project_name = '';
conf.result_dir = '/$WORK/queue_results';
conf.server_names = '';
conf.time_limit = '1:00';
conf.tmp_dir = '/$WORK/tmp';
conf.queue_command = 'bsub < %s/%s_script.sh';
end