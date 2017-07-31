%function Process_KiloSort(fbasename)

%Version of KiloSortWrapper for all channels

xmlFile = [fbasename '.xml'];
datFile = [fbasename '.dat'];

par     = LoadXml(xmlFile);
nbChan = par.nChannels;
    
%CreateChannelMap
x = [];
y = [];
nElec = nbChan;
for ii =1:nElec
    x(ii) = nElec-ii;
    y(ii) = -ii*10;
    if mod(ii,2)
        x(ii) = -x(ii);
    end
end
xcoords     = x;
ycoords     = y;
kcoords     = ones(nElec,1);
connected   = true(nElec, 1);
chanMap     = 1:nElec;
chanMap0ind = chanMap - 1;

save('chanMap.mat', ...
'chanMap','connected', 'xcoords', 'ycoords', 'kcoords', 'chanMap0ind');

ops = StandardConfig_GrpWrapper(datFile,par,nbChan);
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

rez.ops.basepath = '.';
rez.ops.basename = fbasename;
rez.ops.savepath = '.';
disp('Saving rez file')

save('rez.mat', 'rez', '-v7.3');
%% save python results file for Phy
%disp('Converting to Phy format')
%rezToPhy(rez);
%% save python results file for Klusters
%disp('Converting to Klusters format')
%ConvertKilosort2Neurosuite_GrpWrapper(rez,elecGrp);
%% Remove temporary file
%delete(ops.fproc);
%disp('Kilosort Processing complete')
    