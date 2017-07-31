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
%    Dependencies:  none

% Copyright (C) 2015-2016 Adrien Peyrache
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.

processName = [];

%Parameters:
eraseDir    = 1; %Remove original directories
cpVideo     = 1; %Move and rename video files from original folders
videoExt    = {'avi';'mpg';'mov'};

if ~isempty(varargin)
    newfbasename = varargin{1};
    if length(varargin)>1
        cpVideo = varargin{2};
    end
else
    newfbasename = fbasename;
end


try
    
folders = dir([fbasename '_*']);
nRec = length(folders);

date = [];
startTime = [];
recName = {};

processName = 'listing folders';
for ii=1:nRec
    
    if folders(ii).isdir;
        fname = folders(ii).name;
        recName = [recName;{fname}];
        k = strfind(fname,'_');
        date = [date;str2num(fname(k(end-1)+1:k(end)-1))];
        startTime = [startTime;str2num(fname(k(end)+1:end))];
    else
        warning('not a folder')
    end
    
end

[startTime,ix] = sort(startTime);
recName = recName(ix);
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
    
    if nRec>1
        newFbase = [newfbasename '-' nber];
    else
        newFbase = newfbasename;
    end
    
    recList{ii} = newFbase;
    
    processName = 'creating destination folder';
    if ~exist(newFbase,'dir')
        mkdir(newFbase)
    end
    
    processName = 'moving amplifier.dat';
    fname = fullfile(recName{ii},'amplifier.dat');
    if exist(fname,'file')
        movefile(fname,[newFbase '.dat'],'f')
    else
        warning(['Dat file ' fname ' does not exist'])
    end
    
    processName = 'moving amplifier.xml';
    fname = fullfile(recName{ii},'amplifier.xml');
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
    
    processName = 'moving analogin.dat';
    fname = fullfile(recName{ii},'analogin.dat');
    if exist(fname,'file')
        targetFile = fullfile(newFbase,[newFbase '_analogin.dat']);
        movefile(fname,targetFile,'f')
    else
        warning(['Analog-in file ' fname ' does not exist'])
    end
    
    processName = 'moving auxiliary.dat';
    fname = fullfile(recName{ii},'auxiliary.dat');
    if exist(fname,'file')
        targetFile = fullfile(newFbase,[newFbase '_auxiliary.dat']);
        movefile(fname,targetFile,'f')
    else
        warning(['Auxiliary file ' fname ' does not exist'])
    end    
    
    processName = 'moving digitalin.dat';
    fname = fullfile(recName{ii},'digitalin.dat');
    if exist(fname,'file')
        targetFile = fullfile(newFbase,[newFbase '_digitalin.dat']);
        movefile(fname,targetFile,'f')        
    else
        warning(['Digital-in file ' fname ' does not exist'])
    end
    
    processName = 'moving time.dat';
    fname = fullfile(recName{ii},'time.dat');
    if exist(fname,'file')
        targetFile = fullfile(newFbase,[newFbase '_time.dat']);
        movefile(fname,targetFile,'f')
    else
        warning(['Timestamp file ' fname ' does not exist'])
    end
    
    processName = 'moving info.rhd';
    fname = fullfile(recName{ii},'info.rhd');
    if exist(fname,'file')
        targetFile = fullfile(newFbase,[newFbase '_info.rhd']);
        movefile(fname,targetFile,'f')
    else
        warning(['Intan info file ' fname ' does not exist'])
    end
    
    processName = 'moving movie file';
    videoFile   = [];
    videoIx     = 1;
    while isempty(videoFile) && videoIx <= length(videoExt)
        videoFile = dir(fullfile(recName{ii},['*.' videoExt{videoIx}]));
        if isempty(videoFile)
            warning(['No ' videoExt{videoIx} ' video file, try next format'])
        end
        videoIx = videoIx+1;
    end
    if isempty(videoFile)
        warning('No video file found')
    elseif length(videoFile) >1
        warning('There should be one and only one video file here, type ''videoName = xxx'' to enter the proper video name, and then ''return''')
        keyboard
    else
        videoName = fullfile(recName{ii},videoFile(1).name);
        targetFile = fullfile(newFbase,[newFbase '.avi']);
        movefile(videoName,targetFile,'f')
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

catch
    warning(lasterr)
    warning(['Error while ' processName ])
    keyboard
end