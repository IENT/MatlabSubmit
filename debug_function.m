function [ output ] = debug_function(p)
%DEBUG_FUNCTION demo function to test submitting to the cluster
%   This function simply returns the input parameters and the time it was called.
%   It is used by debug_output_collector to check the order of the output collector.
%
% Copyright (c) 2017, Christian Rohlfing, Julian Becker, Jens Schneider, Patrick Wilken, Tobias Kabzinski

output = p;
% output.structs = {p.structs}; % For testing evaluation with structs they have to be inside cell, otherwise they would be interpreted as nested parameters

end

