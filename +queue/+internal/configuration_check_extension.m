function conf = configuration_check_extension(conf, old_conf, output_flag)
%CONFIGURATION_CHECK_EXTENSION additional checks of configuration in paramter extension case 
%
% Copyright (c) 2017, Christian Rohlfing, Julian Becker, Jens Schneider, Patrick Wilken, Tobias Kabzinski

    if nargin < 3
        output_flag = 0;
    end

    % Check if simulation function changed                                
    if ~isequal(conf.fun_handle, old_conf.fun_handle)
        error('Simulation function differs from previous run. Use ''%s'' or change job name.', func2str(old_conf.fun_handle))
    end
    
    % Check if collect_output changed
    if xor(conf.collect_output, old_conf.collect_output)
        conf.collect_output = old_conf.collect_output;
        if output_flag
            warning('conf.collect_output has to match previous run. It was set to %d.', conf.collect_output)
        end
    end
end

