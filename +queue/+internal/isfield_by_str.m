function [ result ] = isfield_by_str(strct, field_str)
%ISFIELD_BY_STR checks if a field in a structure exists
%   necessary because isfield(p, x) doesn't work for substructures (e.g. x = 'var.subvar')
%
% Copyright (c) 2017, Christian Rohlfing, Julian Becker, Jens Schneider, Patrick Wilken, Tobias Kabzinski

fields = textscan(field_str, '%s', 'Delimiter', '.');
try
    getfield(strct, fields{1}{:});
    result = true;
catch 
    result = false;   
end