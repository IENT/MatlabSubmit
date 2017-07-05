function [ output ] = debug_eval_function(p)
%DEMO_EVAL_FUNCTION demo function to test the evaluation
%   This function creates some data that are used to test the evaluation
%   function of MATLAB SUBMIT in 'debug_eval'
%
% Copyright (c) 2017, Christian Rohlfing, Julian Becker, Jens Schneider, Patrick Wilken, Tobias Kabzinski

output.scalar = sin(2*pi * (p.plot_x + p.ver/3)) * sin(2*pi * (p.plot_y + p.hor/4)) * (p.col - 3) + p.win;
output.vector = [output.scalar, output.scalar^2, output.scalar * (p.hor - p.ver^2)];
output.matrix = [output.vector; output.vector.^(1/2)];
output.nested.nestedmeasure = 1/output.scalar;
output.non_numeric1 = 'non_numeric';
output.non_numeric2 = {1};

end

