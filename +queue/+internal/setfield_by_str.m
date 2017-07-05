function [ strct ] = setfield_by_str(strct, field_str, value)
% SETFIELD_BY_STR sets the value of a field in a structure by its name
%   necessary because p.(x) doesn't work for parameters in substructures (e.g. x = 'var.subvar')
%
% Copyright (c) 2017, Christian Rohlfing, Julian Becker, Jens Schneider, Patrick Wilken, Tobias Kabzinski

fields = textscan(field_str, '%s', 'Delimiter', '.');
strct = setfield(strct, fields{1}{:}, value);

end

