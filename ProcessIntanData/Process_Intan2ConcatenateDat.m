function mergename = Process_Intan2ConcatenateDat(fbasename,varargin)

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
Process_ConcatenateDatFiles(recList,mergename);

%% Copy files to new final directory
%if length(recList)>1
mkdir(mergename);
%end

%% Moving xml and dat file
movefile([mergename '.dat'],mergename,'f')
copyfile([recList{1} '.xml'],[mergename '.xml'],'f')
movefile([mergename '.xml'],mergename,'f')

%% Moving position csv file if any exists and renaming it for python (starting at 0)
nRec = length(recList);
for ii=1:nRec
    fname = [recList{ii} '.csv'];
    if exist(fname, 'file')
        targetFile = fullfile(pwd, mergename, [mergename '_' num2str(ii-1) '.csv']);
        movefile(fname, targetFile);
    end
end

%% Copying analogin file if any exists 
for ii=1:nRec
    fname = fullfile(pwd, recList{ii}, [recList{ii} '_analogin.dat']);
    if exist(fname, 'file')
        targetFile = fullfile(pwd, mergename, [mergename '_' num2str(ii-1) '_analogin.dat']);
        movefile(fname, targetFile);
    end
end

%% Moving Epoch_TS.csv file
fname = fullfile(pwd, 'Epoch_TS.csv');
if exist(fname, 'file')    
    target = fullfile(pwd, mergename, 'Epoch_TS.csv');
    movefile(fname, target);
end

%% Concatenating auxiliary files
if nRec>1
    cmdline = 'cat ';
    for ii=1:nRec-1
        cmdline = [cmdline fullfile(pwd, recList{ii}, [recList{ii} '_auxiliary.dat '])];
    end
    cmdline = [cmdline fullfile(pwd, recList{end},[recList{end} '_auxiliary.dat']) ' > ' mergename '_auxiliary.dat'];
else    
    cmdline = ['mv ' fullfile(pwd, recList{1},[recList{1} '_auxiliary.dat ']) mergename '_auxiliary.dat'];
end
system(cmdline);
fname = fullfile(pwd, [mergename '_auxiliary.dat']);
target = fullfile(pwd, mergename, [mergename '_auxiliary.dat']);
movefile(fname, target);
    


        


