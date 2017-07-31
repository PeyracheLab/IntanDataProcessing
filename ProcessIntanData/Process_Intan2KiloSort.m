function mergename = Process_Intan(fbasename,varargin)

% Processes raw data from Intan, renames files and folders, concatenates
% dat files (if multiple) and runs KiloSort.
%
%  USAGE
%
%    Process_Intan2KiloSort(filebasename,<optional>mergename)
%
%    filebasename   a cell array of filebasenames (with or without '.dat' extenstion)
%    mergename      final concatenated file and folder name (if omitted,
%                   mergename will be the name of the current folder.
%
%    Dependencies:  KiloSortWrapper, KiloSort

% Copyright (C) 2016 Adrien Peyrache
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.

%% Parameters
%script in development to re-reference channels. Be cautious, may lack
%dependencies
removeNoise = 0; 

if isempty(varargin)
    [~,mergename,~] = fileparts(pwd);
else
    mergename = varargin{1};
end
fprintf('Processing %s...\n',mergename);

%% Rename and copy Intant folders
recList = Process_RenameCopyIntan(fbasename,mergename);
if isempty(recList)
    error('No data folders!')
end

%% Re-reference data if needed, USE WITH PRECAUTIOUS
if removeNoise
    for ii=1:length(recList)
        Process_RemoveMuscleArtifactsFromDat(recList{ii},64,1:64,1:64)
    end
end

%% Concatenate Data for Kilosort (or others)
Process_ConcatenateDatFiles(recList,mergename)

%% Copy files to new final directory
if length(recList)>1
    mkdir(mergename)
end
movefile([mergename '.dat'],mergename,'f')
copyfile([recList{1} '.xml'],[mergename '.xml'],'f')
movefile([mergename '.xml'],mergename,'f')


