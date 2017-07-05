function [ value_str, proper_str_flag ] = value2str( value )
%VALUE2STR Creates string for value of arbritary class 
%
% Copyright (c) 2017, Christian Rohlfing, Julian Becker, Jens Schneider, Patrick Wilken, Tobias Kabzinski

    % Return if value could be displayed properly
    proper_str_flag = 1;
    
    % Numerical classes
    if isnumeric(value) || islogical(value);
        if length(value) == 1
            if isreal(value)
                value_str = sprintf('%.3g', value);
            else
                value_str = num2str(round(value*1000)/1000);
            end
        elseif length(value) > 1 && numel(value) <= 10
            value_str = mat2str(round(value*1000)/1000);
        else
            value_str ='[matrix]';
            proper_str_flag = 0;
        end
    % Strings
    elseif ischar(value)
        if size(value,1) == 1 && size(value,2) <= 20
            value_str = sprintf('''%s''', value);
        elseif length(value) > 1 && numel(value) <= 20
            value_str = mat2str(value);
        else 
            value_str ='[char]';
            proper_str_flag = 0;
        end           
    % Cells, structs etc.
    else
        value_str = ['[', class(value), ']'];
        proper_str_flag = 0;
    end

end

