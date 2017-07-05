function [ value ] = getfield_by_str(strct, field_str)
%GETFIELD_BY_STR returns the value of a field in a structure by its name
%   necessary because p.(x) doesn't work for parameters in substructures (e.g. x = 'var.subvar')
%
% Copyright (c) 2017, Christian Rohlfing, Julian Becker, Jens Schneider, Patrick Wilken, Tobias Kabzinski

fields = textscan(field_str, '%s', 'Delimiter', '.');
value = getfield(strct, fields{1}{:});

end

