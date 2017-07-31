function ConvertKilosort2Neurosuite_GrpWrapper(rez,grp)

% Converts KiloSort templates Klusta into klusters-compatible
% fet,res,clu,spk files.  Works on a single shank of a recording, assumes a
% 16bit .dat and an .xml file is present in "basepath" (home folder) and 
% that they are named basename.dat and basename.xml.  
% 
% Inputs:
%   basepath -  directory path to the main recording folder with .dat and .xml
%               as well as shank folders made by makeProbeMapKlusta2.m (default is
%               current directory matlab is pointed to)
%   basename -  shared file name of .dat and .xml (default is last part of
%               current directory path, ie most immediate folder name)

% Brendon Watson 2016, Adrien Peyrache 2017

savepath = rez.ops.savepath;
basepath = rez.ops.basepath;
basename = rez.ops.basename;

if ~exist('rez','var')
    load(fullfile(basepath,'rez.mat'))
end

nElec = length(rez.xc);

sbefore = 16;%samples before/after for spike extraction
safter  = 24;%... could read from SpkGroups in xml

if exist(rez.ops.fbinary,'file')
    datpath = rez.ops.fbinary;
end

spktimes    = uint64(rez.st3(:,1));
clu         = uint32(rez.st3(:,2));
pcFeatures  = rez.cProjPC;
pcFeatureInds = uint32(rez.iNeighPC);

mkdir(fullfile(savepath,'OriginalClus'))

templates   = rez.Wraw;
channellist = 1:nElec;
    
    %% spike extraction from dat
    dat             = memmapfile(datpath,'Format','int16');

    tsampsperwave   = (sbefore+safter);
    valsperwave     = tsampsperwave * nElec;
    wvforms_all     = zeros(length(spktimes)*tsampsperwave*nElec,1,'int16');
    wvranges        = zeros(length(spktimes),nElec);
    wvpowers        = zeros(1,length(spktimes));
    
    for j=1:length(spktimes)
        try
            w       = dat.data((double(spktimes(j))-sbefore)*nElec+1:(double(spktimes(j))+safter)*nElec);
            wvforms = reshape(w,nElec,[]);
            
    %         % detrend
    %         wvforms = floor(detrend(double(wvforms)));
            % median subtract
            wvforms = wvforms - repmat(median(wvforms')',1,sbefore+safter);
            wvforms = wvforms(:);
            
        catch
            disp(['Error extracting spike at sample ' int2str(double(tspktimes(j))) '. Saving as zeros']);
            disp(['Time range of that spike was: ' num2str(double(tspktimes(j))-sbefore) ' to ' num2str(double(tspktimes(j))+safter) ' samples'])
            wvforms = zeros(valsperwave,1);
        end

        %some processing for fet file
        wvaswv = reshape(wvforms,tsampsperwave,nElec);
        wvranges(j,:) = range(wvaswv);
        wvpowers(j) = sum(sum(wvaswv.^2));

        lastpoint = tsampsperwave*nElec*(j-1);
        wvforms_all(lastpoint+1 : lastpoint+valsperwave) = wvforms;
    %     wvforms_all(j,:,:)=int16(floor(detrend(double(wvforms)')));
        if rem(j,100000) == 0
            disp([num2str(j) ' out of ' num2str(length(spktimes)) ' done'])
        end
    end
    wvranges = wvranges';
    
    %% Spike features
%     for each template, rearrange the channels to reflect the shank order
    tdx = [];
    for tn = 1:size(templates,3)
        tTempPCOrder = pcFeatureInds(:,tn);%channel sequence used for pc storage for this template
        for k = 1:length(channellist)
            i = find(tTempPCOrder==channellist(k));
            if ~isempty(i)
                tdx(tn,k) = i;
            else
                tdx(tn,k) = nan;
            end
        end
    end
    
    % initialize fet file
    fets    = zeros(length(clu),size(pcFeatures,2),nElec);
    
    %for each cluster/template id, grab at once all spikes in that group
    %and rearrange their features to match the shank order
    allshankclu = unique(clu);
    
    for tc = 1:length(allshankclu)
        tsc     = allshankclu(tc);
        cluIx   = find(clu==tsc);
        tforig  = pcFeatures(cluIx,:,:);%the subset of spikes with this clu ide
        tfnew   = tforig; %will overwrite
        
        ii      = tdx(tc,:);%handling nan cases where the template channel used was not in the shank
        gixs    = ~isnan(ii);%good vs bad channels... those shank channels that were vs were not found in template pc channels
        bixs    = isnan(ii);
        g       = ii(gixs);
        
        tfnew(:,:,gixs) = tforig(:,:,g);%replace ok elements
        tfnew(:,:,bixs) = 0;%zero out channels that are not on this shank
        try
            fets(cluIx,:,:) = tfnew(:,:,1:nElec);
        catch
            keyboard
        end
    end
    %extract for relevant spikes only...
    % and heurstically on d3 only take fets for one channel for each original channel in shank... even though kilosort pulls 12 channels of fet data regardless
    tfet1 = squeeze(fets(:,1,1:nElec));%lazy reshaping
    tfet2 = squeeze(fets(:,2,1:nElec));
    tfet3 = squeeze(fets(:,3,1:nElec));
    fets = cat(2,tfet1,tfet2,tfet3)';%     fets = h5read(tkwx,['/channel_groups/' num2str(shank) '/features_masks']);

    %mean activity per spike
    fets = cat(1,double(fets),double(wvpowers),double(wvranges),double(spktimes'));
    fets = fets';

    %% writing to clu, res, fet, spk

    cluname = fullfile(savepath, [basename '.clu.' num2str(grp)]);
    resname = fullfile(savepath, [basename '.res.' num2str(grp)]);
    fetname = fullfile(savepath, [basename '.fet.' num2str(grp)]);
    spkname = fullfile(savepath, [basename '.spk.' num2str(grp)]);

    SaveFetIn(fetname,fets);

    %clu
    tclu    = [length(unique(clu));double(clu)];
    fid     = fopen(cluname,'w'); 
    fprintf(fid,'%.0f\n',tclu);
    fclose(fid);
    clear fid
 
    %res
    fid     = fopen(resname,'w'); 
    fprintf(fid,'%.0f\n',spktimes);
    fclose(fid);
    clear fid

    %spk
    fid     = fopen(spkname,'w'); 
    fwrite(fid,wvforms_all,'int16');
    fclose(fid);
    clear fid 

clear dat
copyfile(fullfile(savepath, [basename,'.clu.*']),fullfile(savepath, 'OriginalClus'))

function SaveFetIn(FileName, Fet, BufSize);

if nargin<3 | isempty(BufSize)
    BufSize = inf;
end

nFeatures = size(Fet, 2);
formatstring = '%d';
for ii=2:nFeatures
  formatstring = [formatstring,'\t%d'];
end
formatstring = [formatstring,'\n'];

outputfile = fopen(FileName,'w');
fprintf(outputfile, '%d\n', nFeatures);

if isinf(BufSize)
  
  temp = [round(100* Fet(:,1:end-1)) round(Fet(:,end))];
    fprintf(outputfile,formatstring,temp');
else
    nBuf = floor(size(Fet,1)/BufSize)+1;
    
    for i=1:nBuf 
        BufInd = [(i-1)*nBuf+1:min(i*nBuf,size(Fet,1))];
        temp = [round(100* Fet(BufInd,1:end-1)) round(Fet(BufInd,end))];
        fprintf(outputfile,formatstring,temp');
    end
end
fclose(outputfile);
