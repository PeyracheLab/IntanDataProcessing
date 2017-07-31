function Process_Data2KiloSort(fbasename,varargin)

% Preprocess raw data recordings, concatenate dat files (if multiple) and launches KiloSort.
% 
%  USAGE
%
%    Process_Data2KiloSort(filebasename,<optional>mergename)
%
%    filebasename   a cell array of filebasenames (with or without '.dat' extenstion)
%    mergename      final concatenated file and folder name (if omitted,
%                   mergename will be the name of the current folder.
%
%    Dependencies:  none

% Copyright (C) 2016 Adrien Peyrache
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.

%% Parameters
%script in development to re-reference channels. Use with precautious
removeNoise = 0; 

if isempty(varargin)
    [~,mergename,~] = fileparts(pwd);
else
    mergename = varargin{1};
end
fprintf('Processing %s...\n',mergename);

%% Rename and copy Intant folders
datFiles = dir([fbasename '*.dat*']);
if isempty(datFiles)
    error('No dat files!')
end

recList = cell(length(datFiles),1);
for ii=1:length(recList)
    fname       = datFiles(ii).name;
    recList{ii} = fname(1:end-4); 
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
mkdir(mergename)
movefile([mergename '.dat'],mergename,'f')
copyfile([recList{1} '.xml'],fullfile(mergename,[mergename '.xml']),'f')

%%Go to final folder and launch Kilosort
cd(mergename)
%UpdateXml_SpkGrps(mergename)
KiloSortWrapper()

