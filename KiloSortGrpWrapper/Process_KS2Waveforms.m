function Process_KS2WAveforms(targetDir,varargin)

if isempty(varargin)
    [~,fbasename,~] = fileparts(pwd);
else
    fbasename = varargin{1};
end

listDir = dir([fbasename,'_Grp*']);
[~,fbasename,~] = fileparts(pwd);

par     = LoadXml([fbasename '.xml']);

cellWF = {};
cellWFdet = {};
fprintf('Processing...\n')

for ii=1:length(listDir)
    folderName = listDir(ii).name;
    k = strfind(folderName,'_Grp');
    shNb = str2num(folderName(k+4:length(folderName)));
    
    nbChans = length(par.ElecGp{shNb});
    
    fprintf('...Electrode group #%s\n',folderName(k+4:end))
   
    cluInfo = readtable(fullfile(folderName,'cluster_groups.csv'));
    
    clu = readNPY(fullfile(folderName,'spike_clusters.npy'));
    tim = readNPY(fullfile(folderName,'spike_times.npy'));
    
    for c=1:length(cluInfo.cluster_id)
        if strcmp(cluInfo.group{c},'good')
            t = double(tim(clu==cluInfo.cluster_id(c)));
            
            nRead = max(1000,round(length(t)/10));
            [meanWF,allWF] = readWaveformsFromDat(fullfile(folderName,[folderName '.dat']),nbChans, double(t), [-16 32],nRead);
            allWF = double(allWF);
            for ch=1:8
                allWF(ch,:,:) = mydetrend(double(squeeze(allWF(ch,:,:))));
            end
            meanWFdet = mean(allWF,3);
            
            cellWF = [cellWF;{meanWF}];
            cellWFdet = [cellWFdet;{meanWFdet}];
            
        end
    end

end

dataDir = fullfile(targetDir,fbasename);
if ~exist(dataDir,'dir')
    mkdir(dataDir)
end

SaveAnalysis(dataDir,'CellWaveForms',{cellWF;cellWFdet},{'cellWF';'cellWFdet'})
