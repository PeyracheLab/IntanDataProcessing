function [returnVar,msg] = Process_ExtractElecGrps2NewDat(fbasename,nbChan,elecIx)

% USAGE:
%     Process_NewReference(fname,nbChan,refChan,rerefChan)
%     This function substracts one channel or the median of multiple
%     channels (the 'reference' channels) from other channels
% INPUTS:
%     fname:        dat file name (with or without '.sat' extension)
%     nbChan:       total number of channels in dat file(s)
%     refChan:      reference channel(s) (could be a vector, in this case the median of the channels will be the new reference)
%     rerefChan:    vector of channels to re-reference

% Copyright (C) 2013-16 Adrien Peyrache
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.

%Parameters
fs = 20000; %sampling frequency
fc = 600; %high-pass cut-off frequency
saveCopy = 1;

datFile = [fbasename '.dat'];

newName = [fbasename '_Tmp'];
if ~exist(newName,'dir')
    mkdir(newName)
end
fid = fopen(fullfile(newName,[newName '.dat']),'w');

    try
        infoFile = dir(datFile);

        chunk = 1e6;
        nbChunks = floor(infoFile.bytes/(nbChan*chunk*2));
        warning off
        if nbChunks==0
            chunk = infoFile.bytes/(nbChan*2);
        end
        
        for ix=0:nbChunks-1
            h = waitbar(ix/nbChunks);
            m = memmapfile(datFile,'Format','int16','Offset',ix*chunk*nbChan*2,'Repeat',chunk*nbChan,'writable',false);
            d = m.Data;
            d = double(reshape(d,[nbChan chunk]));
            
            grpDat = d(elecIx,:);
            fwrite(fid,grpDat(:),'int16');
            clear d m
        end
        close(h)
        
        newchunk = infoFile.bytes/(2*nbChan)-nbChunks*chunk;

        if newchunk
            m = memmapfile(datFile,'Format','int16','Offset',nbChunks*chunk*nbChan*2,'Repeat',newchunk*nbChan,'writable',false);
            d = m.Data;
            d = double(reshape(d,[nbChan newchunk]));
            
            grpDat = d(elecIx,:);
            fwrite(fid,grpDat(:),'int16');
            clear d m
            
         clear d m
        end
        
        fclose(fid)
      
        warning on
        returnVar = 1;
        msg = '';

    catch
        keyboard
        returnVar = 0;
        msg = lasterr; 
    end
    clear m

end
