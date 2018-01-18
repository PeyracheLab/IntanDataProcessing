function Process_KiloSortGrp(fbasename,varargin)

xmlFile = [fbasename '.xml'];

par     = LoadXml(xmlFile);
nbChan = par.nChannels;

if isempty(varargin)
    grpIx = 1:length(par.ElecGp);
else
    grpIx = varargin{1};
    grpIx = grpIx(:)';
end

nbChan = par.nChannels;

for elecGrp=1:length(grpIx)

    elecIx = par.ElecGp{grpIx(elecGrp)}+1;
    nElec = length(elecIx);

    newDir = [fbasename '_Grp' num2str(grpIx(elecGrp))];
    if ~exist(newDir,'dir')
        mkdir(newDir)
    end
    newDat = fullfile(newDir,[fbasename '_Grp' num2str(grpIx(elecGrp)) '.dat']);
    
    Process_ElecGrps2NewDat(fbasename,newDat,nbChan,elecIx);
    
    %CreateChannelMap
    createChannelMapFile_Grp(par,grpIx(elecGrp),newDir)

    ops = StandardConfig_GrpWrapper(newDat,par,nElec);
    if ops.GPU     
        disp('Initializing GPU')
        gpuDevice(1); % initialize GPU (will erase any existing GPU arrays)
    end

    disp('Running Kilosort pipeline')
    disp('PreprocessingData')
    [rez, DATA, uproj] = preprocessData_KSWrapper(ops); % preprocess data and extract spikes for initialization

    disp('Fitting templates')
    rez = fitTemplates(rez, DATA, uproj);  % fit templates iteratively

    disp('Extracting final spike times')
    rez = fullMPMU(rez, DATA); % extract final spike times (overlapping extraction)

    rez.ops.basepath = pwd;
    rez.ops.basename = fbasename;
    rez.ops.savepath = '.';
    disp('Saving rez file')

    save(fullfile(newDir,'rez.mat'), 'rez', '-v7.3');
    %% save python results file for Phy
    %disp('Converting to Phy format')
    rezToPhy(rez,newDir);
    %% save python results file for Klusters
    %disp('Converting to Klusters format')
    ConvertKilosort2Neurosuite_GrpWrapper(rez,grpIx(elecGrp));
    UpdateXml_SpkGrps([fbasename '.xml'])
    %% Remove temporary file
    delete(ops.fproc);
    disp('Kilosort Processing complete')
end    
