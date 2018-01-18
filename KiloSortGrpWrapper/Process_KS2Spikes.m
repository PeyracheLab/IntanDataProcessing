function Process_KS2Spikes(targetDir,varargin)

if isempty(varargin)
    [~,fbasename,~] = fileparts(pwd);
else
    fbasename = varargin{1};
end

listDir = dir([fbasename,'_Grp*']);

shank = [];
cellIx = [];
S = {};
MUA = {};

for ii=1:length(listDir)
    
    mua = [];
    
    folderName = listDir(ii).name;
    k = strfind(listDir(ii).name,'_Grp');
    shNb = str2num(folderName(k+4:length(folderName)));
    
    cluInfo = readtable(fullfile(folderName,'cluster_groups.csv'));
    
    clu = readNPY(fullfile(folderName,'spike_clusters.npy'));
    tim = readNPY(fullfile(folderName,'spike_times.npy'));
    
    for c=1:length(cluInfo.cluster_id)
        if strcmp(cluInfo.group{c},'good')
            t = double(tim(clu==cluInfo.cluster_id(c)))/20000;
            S = [S;{ts(t)}];
            shank = [shank;shNb];
            cellIx = [cellIx;cluInfo.cluster_id(c)];
        elseif strcmp(cluInfo.group{c},'mua')
            t = double(tim(clu==cluInfo.cluster_id(c)))/20000;
            mua = [mua;t];
        end
    end

    mua = sort(mua);
    
    MUA = [MUA;{shNb ts(mua) }];
end

S = tsdArray(S);

dataDir = fullfile(targetDir,fbasename);
if ~exist(dataDir,'dir')
    mkdir(dataDir)
end

SaveAnalysis(dataDir,'SpikeData',{S;MUA;shank;cellIx},{'S';'MUA';'shank';'cellIx'})
