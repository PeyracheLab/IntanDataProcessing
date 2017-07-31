function [returnVar,msg] = Process_NewReference(fname,nbChan,refChan,rerefChan)

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

if ~strcmp(fname(end-2:end),'dat')
    fname = [fname '.dat'];
end

if saveCopy
    system(['cp ' fname ' ' fname(1:end-4) '_original.dat'])
end

    fprintf('ReReferencing %s\n',fname)
    try
        infoFile = dir(fname);

        chunk = 1e6;
        nbChunks = floor(infoFile.bytes/(nbChan*chunk*2));
        warning off
        if nbChunks==0
            chunk = infoFile.bytes/(nbChan*2);
        end

        for ix=0:nbChunks-1
            h = waitbar(ix/nbChunks);
            m = memmapfile(fname,'Format','int16','Offset',ix*chunk*nbChan*2,'Repeat',chunk*nbChan,'writable',true);
            d = m.Data;
            d = double(reshape(d,[nbChan chunk]));
            
            %High pass filtering
            filtD = gaussFilter(d',fs,fc);
            filtD = d-filtD';
            
            ref = filtD(refChan,:);
            if length(refChan)>1
                ref = median(ref);
            end
            ref = repmat(ref,[length(rerefChan) 1]);
            d(rerefChan,:) = d(rerefChan,:)-ref;
            
            m.Data = int16(d(:));
            clear d m
        end
        close(h)


        newchunk = infoFile.bytes/(2*nbChan)-nbChunks*chunk;

        if newchunk
            m = memmapfile(fname,'Format','int16','Offset',nbChunks*chunk*nbChan*2,'Repeat',newchunk*nbChan,'writable',true);
            d = m.Data;
            d = double(reshape(d,[nbChan newchunk]));
            
            %High pass filtering
            filtD = gaussFilter(d',fs,fc);
            filtD = d-filtD';
                        
            ref = filtD(refChan,:);
            if length(refChan)>1
                ref = median(ref);
            end
            ref = repmat(ref,[length(rerefChan) 1]);
            d(rerefChan,:) = d(rerefChan,:)-ref;
            m.Data = int16(d(:));
            
         clear d m
        end
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

function dout = gaussFilter(d,fs,fc)

    sigma   = fs./(2*pi*fc);
    N       = round(10*sigma);
    gw      = gausswin(N,5);
    dout    = convn(d,gw,'same');

end