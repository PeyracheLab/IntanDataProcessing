function [returnVar,msg] = Process_ElecGrps2NewDat(fbasename,newName,nbChan,elecIx,varargin)

% USAGE:
%     Process_ElecGrps2NewDat(fname,newName,nbChan,elecIx,options)
%     This function creates a new dat file including only data from one electrode group (as defined in Neuroscope).
%     It can also substract the median of high pass filtered signals from certain channels
%     (e.g. from a given probe).
%
% INPUTS:
%     fname:        dat file name (with or without '.sat' extension)
%     newName:      new dat file name
%     nbChan:       total number of channels
%     elecIx:       vector of electrode indices that are extracted
%
%    <options>      optional list of property-value pairs (see table below)
%
%    =========================================================================
%     Properties    Values
%    -------------------------------------------------------------------------
%     'refChan'             vector of electrode indices to compute median
%                           (median is not substracted if refChan is not an argument)
%     'highFc'              high-pass frequency divided by Nyquist frequency 
%                           (2 value vector for bandpass, default low-pass
%                           cut-off: 0.9)
%     'isGPU'               true for GPU computing (for filtering)
%    =========================================================================


% Copyright (C) 2013-18 Adrien Peyrache
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.

%Parameters
chunk = 1e6; %chunk size, 1e7 needs a lot of RAM & GPU memory (depending on the number of reference channel for the median)
refChan = [];
highFc  = [300 8000]/10000; %default, assuming sampling frequency of 20kHz
isGPU = 0; %very significant speed increase with GPU

datFile = [fbasename '.dat'];
if ~exist(datFile,'file')
    error([datFile ' does not exist'])
end

fctName = 'Process_ElecGrp2NewDat';

% Parse options
for i = 1:2:length(varargin)
  if ~isa(varargin{i},'char')
    error(['Parameter ' num2str(i+3) ' is not a property (type ''help ' fctName ' ''for details).']);
  end
  switch(lower(varargin{i}))
    case 'refchan'
      refChan = varargin{i+1};
      if ~isa(refChan,'numeric') 
        error(['Incorrect value for property ''refChan'' (type ''help ' fctName ' ''for details).']);
      end
      if numel(refChan) <3
          warning('Computing median with less than 3 channels')
      end
      
    case 'highfc'
      highFc = varargin{i+1};
      if ~isa(highFc,'numeric') && numel(highFc)>2 && any(highFc>1)
        error(['Incorrect value for property ''highFc'' (type ''help ' fctName ' ''for details).']);
      end  
    case 'isgpu'
      isGPU = varargin{i+1};
      if ~ (isa(isGPU,'numeric') || isa(isGPU,'logical'))
        error(['Incorrect value for property ''isGPU'' (type ''help ' fctName ' ''for details).']);
      end  
  end
end

% Open original dat file
fid = fopen(newName,'w');

%% Computing filter options if median is substracted
if refChan
    if length(highFc) == 1
        highFc = [highFc 0.9];
    end
    
    [bFilt, aFilt] = butter(3, highFc, 'bandpass');
    
end

%     try
       
    infoFile = dir(datFile);

    nbChunks = floor(infoFile.bytes/(nbChan*chunk*2));
    warning off
    if nbChunks==0
        chunk = infoFile.bytes/(nbChan*2);
    end

    %h = waitbar;
    for ix=0:nbChunks
        %h = waitbar(ix/nbChunks);
        
        %% load data in a memory map
        if ix<nbChunks
            m = memmapfile(datFile,'Format',{'int16',[nbChan chunk],'x'},'Offset',ix*chunk*nbChan*2,'Repeat',1,'writable',false);
        else
            newchunk = infoFile.bytes/(2*nbChan)-nbChunks*chunk;
            m = memmapfile(datFile,'Format',{'int16',[nbChan newchunk],'x'},'Offset',nbChunks*chunk*nbChan*2,'Repeat',1,'writable',false);
        end

        grpDat = double(m.Data.x(elecIx,:));

        %% median substraction
        if refChan
            
            tmpDat = double(m.Data.x(refChan,:));
            if isGPU
                refDat = gpuArray(tmpDat);
            else
                refDat = tmpDat;
            end
            clear tmpDat;
            
            datF = filter(bFilt, aFilt, refDat,[],2);
            datF = fliplr(datF);
            datF = filter(bFilt, aFilt, datF,[],2);
            datF = fliplr(datF);
            grpDat = bsxfun(@minus, grpDat, median(datF));
            if isGPU
                grpDat = gather(grpDat);
            end
        end
        % wirte data to disk
        fwrite(fid,grpDat(:),'int16');
        clear m datF refDat grpDat
        
    end
    %close(h)

    fclose(fid);

    warning on
    returnVar = 1;
    msg = '';

%     catch
%         keyboard
%         returnVar = 0;
%         msg = lasterr; 
%     end

end
