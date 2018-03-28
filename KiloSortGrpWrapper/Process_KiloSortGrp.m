function Process_KiloSortGrp(fbasename,varargin)

% Process_KiloSortGrp - A wrapper for KiloSort using NeuroSuite data format.
% Processes a dat file (requires also a xml file,
% (http://neurosuite.sourceforge.net/)). Generate one sub-dat file per
% electrode group (for faster processing if GPU card not recent enough or
% for very long recordings) and output files for Phy in each subfolder 
% and files compatible with the NeuroSuite in the root folder.
% 
%  USAGE
%
%    Process_KiloSortGrp(fbasename,<options>)
%
%    fbasename      file base name (e.g. 'fbasename' for fbasename.dat).
%    elecGrp        (optional) a vector of electrode group to be processed
%    WARNING:       the software assumes that there is also a file
%    fbasename.xml in the folder. Otherwise, read http://neurosuite.sourceforge.net/
%


% Copyright (C) 2017 by Adrien Peyrache, Sam McKenzie, Brendon Watson, Luke
% Sjulson (and many other contributions from the Buzsaki Lab, NYU).
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.

xmlFile = [fbasename '.xml'];

par     = LoadXml(xmlFile);
nbChan  = par.nChannels;

if isempty(varargin)
    grpIx = 1:length(par.ElecGp);
else
    grpIx = varargin{1};
    grpIx = grpIx(:)';
end

nbChan = par.nChannels;


for elecGrp=1:length(grpIx)

    tic
    elecIx = par.ElecGp{grpIx(elecGrp)}+1;
    nElec = length(elecIx);

    newDir = [fbasename '_Grp' num2str(grpIx(elecGrp))];
    if ~exist(newDir,'dir')
        mkdir(newDir)
    end
    newDat = fullfile(newDir,[fbasename '_Grp' num2str(grpIx(elecGrp)) '.dat']);
    
    ops = StandardConfig_GrpWrapper(newDat,par,nElec);
    if ops.GPU     
        disp('Initializing GPU')
        gpuDevice(1); % initialize GPU (will erase any existing GPU arrays)
    end
    
    disp('Running Kilosort pipeline')
    % This function creates a new dat file composed of only the signals
    % from one electrode group (as defined in Neuroscope)
    disp('Extracting signals from electrode group')
    %Process_ElecGrps2NewDat(fbasename,newDat,nbChan,elecIx,'refchan',[1:64],'isGPU',ops.GPU);
    Process_ElecGrps2NewDat(fbasename,newDat,nbChan,elecIx);
    
    % CreateChannelMap
    createChannelMapFile_Grp(par,grpIx(elecGrp),newDir)

    %Now this is a classical KiloSort pipeline
    
    disp('PreprocessingData')
    %slight modification of preprocessData
    [rez, DATA, uproj] = preprocessData_KSWrapper(ops); % preprocess data and extract spikes for initialization

    disp('Fitting templates')
    rez = fitTemplates(rez, DATA, uproj);  % fit templates iteratively

    disp('Extracting final spike times')
    rez = fullMPMU(rez, DATA); % extract final spike times (overlapping extraction)

    t = toc;
    disp(['Total spike sorting time: ' num2str(t)])
    rez.ops.basepath = pwd;
    rez.ops.basename = fbasename;
    rez.ops.savepath = '.';
    disp('Saving rez file')

    save(fullfile(newDir,'rez.mat'), 'rez', '-v7.3');
    %% save python results file for Phy
    %disp('Converting to Phy format')
    %rezToPhy(rez,newDir);
    %% save python results file for Klusters
    %disp('Converting to Klusters format')
    ConvertKilosort2Neurosuite_GrpWrapper(rez,grpIx(elecGrp));
    %We need to update the parameter defining the number of samples in
    %spikes
    UpdateXml_SpkGrps([fbasename '.xml'])
    
    %% Remove temporary file
    %delete(ops.fproc);
    %delete(newDat)
    disp('Kilosort Processing complete')
end    
