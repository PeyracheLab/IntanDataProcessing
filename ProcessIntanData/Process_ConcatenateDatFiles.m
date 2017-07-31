function Process_ConcatenateDatFiles(recList,mergename)

% Concatenates dat files, cross-platform code
%
%  USAGE
%
%    Process_ConcatenateDatFiles(recList,mergename)
%
%    recList        a cell array of filebasenames (with or without '.dat' extenstion)
%    mergename      final concatenated file (if only one file in recList,
%                   the file is jsut renames)
%
%    Dependencies:  none

% Copyright (C) 2016 Adrien Peyrache
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.


if ispc
    cmdline = 'copy /B ';
    if length(recList)>1
        for ii=1:length(recList)-1
            cmdline = [cmdline recList{ii} '.dat + '];
        end
         cmdline = [cmdline recList{end} '.dat ' mergename '.dat']; 
    else
        cmdline = [cmdline recList{1} '.dat ' mergename '.dat']; 
    end
elseif isunix || ismac
    if length(recList)>1
        cmdline = 'cat ';
        for ii=1:length(recList)-1
            cmdline = [cmdline recList{ii} '.dat '];
        end
         cmdline = [cmdline recList{end} '.dat > ' mergename '.dat']; 
    else
        cmdline = ['mv ' recList{1} '.dat ' mergename '.dat']; 
    end
else
    error('Cannot determine the OS')
end

system(cmdline)