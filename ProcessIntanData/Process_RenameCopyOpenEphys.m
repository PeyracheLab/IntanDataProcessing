function recList = Process_RenameCopyIntan(fbasename,varargin)
% Preprocess raw Intan data file and folders. Multple folders are renamed
% with number (instead of start time)
%
%  USAGE
%
%    recList = Process_RenameCopyIntan(fbasename,<optional> newfbasename)
%
%    INPUT:
%    fbasename      the base name of the Intan recording (everything until
%                   the last '_', e.g. 'MouseXXX_YYMMDD')
%    newfbsaneme    change the file base name
%
%    OUTPUT:
%    recList        a cell array containing the names of the new folders
%
%    Dependencies:  npy-matlab https://github.com/kwikteam/npy-matlab

% Copyright (C) 2015-2020 Adrien Peyrache and Adrian Duszkiewicz
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.

processName = [];

%Parameters:
eraseDir    = 1; %Remove original directories

if ~isempty(varargin)
    newfbasename = varargin{1};
    if length(varargin)>1
        cpVideo = varargin{2};
    end
else
    
    fbasename = '2020-01-27'
    newfbasename = fbasename;
end


try
    
 %file path for the OpenEphys binary file#
   

folders = dir(['recording' '*']);
nRec = length(folders);

recName = {};
durations = [];
filePath = {};

processName = 'listing folders';
for ii=1:nRec
    
    if folders(ii).isdir
        
        fname = folders(ii).name;
        recName = [recName;{fname}];
        nRec = length(recName);
        filePath{nRec} = fullfile(fname,'continuous','Rhythm_FPGA-100.0');  
        
    else
        warning('not a folder')
    end
    
end

nRec = length(recName);
recList = cell(nRec,1);


if length(recList) == 0
    error('No data fodlers detected')
end

for ii=1:nRec
    disp(ii)
    nber = num2str(ii);
    if ii<10
        nber = ['0' nber];
    end
    
    % seems buggy without the nber
    %if nRec>1
    newFbase = [newfbasename '-' nber];
%    else
 %       newFbase = newfbasename;
  %  end
    recList{ii} = newFbase;
    
    processName = 'creating destination folder';
    if ~exist(newFbase,'dir')
        mkdir(newFbase)
    end
    
    processName = 'moving continuous.dat';
    fname = fullfile(filePath{ii},'continuous.dat');
    if exist(fname,'file')
        movefile(fname,[newFbase '.dat'],'f')
    else
        warning(['Dat file ' fname ' does not exist'])
    end
    
    processName = 'moving continuous.xml';
    fname = fullfile(filePath{ii},'continuous.xml');
    if exist(fname,'file')
        movefile(fname,[newFbase '.xml'],'f')
    else
        warning(['XML file ' fname ' does not exist. Try animal root folder'])
        fname = fullfile('..','amplifier.xml');
        if exist(fname,'file')
            movefile(fname,[newFbase '.xml'],'f')
        else
            warning(['XML file ' fname ' does not exist. Skipping it'])
        end
    end
    
    
        
    processName = 'create Epoch_TS.csv';
    fname = fullfile(filePath{ii}, 'timestamps.npy');
    if exist(fname, 'file')
        timestamps = readNPY(fname);
        num_samples = length(timestamps);
        warning('Considering 30kHz sampling rate');
        durations = [durations;num_samples/30000];
        targetFile = fullfile(newFbase, [newFbase '_timestamps.npy']);
        movefile(fname, targetFile, 'f');
    else
        warning(['Timestamp file ' fname ' does not exist']);
    end
        
    
    
    processName = 'moving csv file';
    csvFile = dir(fullfile(recName{ii}, '*.csv'));
    if ~isempty(csvFile)
        fname = fullfile(recName{ii},csvFile.name);
        targetFile = fullfile(pwd, [newFbase, '.csv']);
        movefile(fname,targetFile,'f');
    else
        warning(['Found no csv file for ' recName{ii}]);
    end
    
    
    if eraseDir
        dirContent = dir(fullfile(recName{ii},'*'));
        if ~isempty(dirContent)
            answer = input('Original directory not empty, are you sure you want to remove it? [Y/N]','s');
            if strcmpi(answer,'y')
                try
                    rmdir(recName{ii},'s')
                catch
                    keyboard
                end
            end
        end
    end

end

%% Writing epochs.csv
epochs = zeros(nRec, 2);
start = 0;
%if length(durations) == nRec
for ii=1:nRec
    epochs(ii,1) = start;
    start = start + durations(ii);
    epochs(ii,2) = start;
end
csvwrite('Epoch_TS.csv',epochs);
%end

catch
    warning(lasterr)
    warning(['Error while ' processName ])
   
end