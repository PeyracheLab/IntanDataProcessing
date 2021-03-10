function Process_ExtractLargeSpk(rez,varargin)

%Parameters
nFeatures = 3; %Range, power and time

if isempty(varargin)
    nSamples = 32;
else
    nSamples = varargin{1};
end

spikeTimes = uint64(rez.st3(:,1)); % uint64
spikeTemplates = uint32(rez.st3(:,2)); % uint32 % template id for each spike
kcoords = rez.ops.kcoords;
basename = rez.ops.basename;

Nchan = rez.ops.Nchan;

% Adrian's modification below
templates = gpuArray(zeros(Nchan, size(rez.W,1), size(rez.U,2), 'single'));
for iNN = 1:size(rez.U,2)%rez.ops.Nfilt %

    templates(:,:,iNN) = squeeze(rez.U(:,iNN,:)) * squeeze(rez.W(:,iNN,:))';
end

templates = gather(templates);

% original code below

% templates = zeros(Nchan, size(rez.W,1), rez.ops.Nfilt, 'single');
% for iNN = 1:rez.ops.Nfilt
%     templates(:,:,iNN) = squeeze(rez.U(:,iNN,:)) * squeeze(rez.W(:,iNN,:))';
% end

amplitude_max_channel = [];
for i = 1:size(templates,3)
    [~,amplitude_max_channel(i)] = max(range(templates(:,:,i)'));
end

ops = rez.ops;
NT = ops.NT;

kcoords = ops.kcoords;
d = dir(ops.fbinary);

NchanTOT = ops.NchanTOT;
chanMap = ops.chanMap;

%chanMapConn = chanMap(rez.connected>1e-6);
chanMapConn = chanMap;
kcoords = ops.kcoords;
ia = rez.ia;
spikeTimes = rez.st3(:,1);


ops.ForceMaxRAMforDat   = 10000000000;
memallocated = ops.ForceMaxRAMforDat;
nint16s      = memallocated/2;
 
NT          = 2^14*32+ ops.ntbuff;
NTbuff      = NT + 4*ops.ntbuff;
Nbatch      = ceil(d.bytes/2/NchanTOT /(NT-ops.ntbuff));

%Nbatch_buff = floor(4/5 * nint16s/ops.Nchan /(NT-ops.ntbuff)); % factor of 4/5 for storing PCs of spikes
%Nbatch_buff = min(Nbatch_buff, Nbatch);
        
        
if isfield(ops,'fslow')&&ops.fslow<ops.fs/2
    [b1, a1] = butter(3, [ops.fshigh/ops.fs,ops.fslow/ops.fs]*2, 'bandpass');
else
    [b1, a1] = butter(3, ops.fshigh/ops.fs*2, 'high');
end
        
if isfield(ops,'xml')
    disp('Loading xml from rez for probe layout')
    xml = ops.xml;
elseif exist(fullfile(ops.root,[ops.basename,'.xml']),'file')
    disp('Loading xml for probe layout from root folder')
    xml = LoadXml(fullfile(ops.root,[ops.basename,'.xml']));
    ops.xml = xml;
end
        
fid = fopen(ops.fbinary, 'r');

template_kcoords = kcoords(amplitude_max_channel);
kcoords2 = unique(template_kcoords);

channel_order = {};
indicesTokeep = {};

fidSpk  = cell(length(kcoords2),1);
fidFet  = cell(length(kcoords2),1);
spkT    = cell(length(kcoords2),1);

for i = 1:length(kcoords2)
    kcoords3    = kcoords2(i);

    spkT{i}     = zeros(length(spikeTimes(ia{i})),1); %indices to make sure spikes are not counted twice. Quick and dirty fix    
    
    fidSpk{i}   = fopen([basename,'.spk.',num2str(kcoords2(i))],'w');
    fidFet{i}   = fopen([basename,'.fet.',num2str(kcoords3)],'w');
    fprintf(fidFet{i}, '%d\n',nFeatures);


    if exist('xml')
        %channel_order = xml.AnatGrps(kcoords2(i)).Channels+1;
        channel_order = xml.AnatGrps(kcoords2(i)).Channels+1;
        [~,~,indicesTokeep{i}] = intersect(channel_order,chanMapConn,'stable');

    end
end
        
    fprintf('Extraction of waveforms begun \n')

    for ibatch = 1:Nbatch
        
        waveforms_all = cell(length(kcoords2),1);
        
        if mod(ibatch,10)==0
            if ibatch~=10
                fprintf(repmat('\b',[1 length([num2str(round(100*(ibatch-10)/Nbatch)), ' percent complete'])]))
            end
            fprintf('%d percent complete', round(100*ibatch/Nbatch));
        end

        offset = max(0, 2*NchanTOT*((NT - ops.ntbuff) * (ibatch-1) - 2*ops.ntbuff));
        if ibatch==1
            ioffset = 0;
        else
            ioffset = ops.ntbuff;
        end
        fseek(fid, offset, 'bof');
        buff = fread(fid, [NchanTOT NTbuff], '*int16');

        %         keyboard;

        if isempty(buff)
            break;
        end
        nsampcurr = size(buff,2);
        if nsampcurr<NTbuff
            buff(:, nsampcurr+1:NTbuff) = repmat(buff(:,nsampcurr), 1, NTbuff-nsampcurr);
        end
        if ops.GPU
            dataRAW = gpuArray(buff);
        else
            dataRAW = buff;
        end
        
        clear buff

        dataRAW = dataRAW';
        dataRAW = single(dataRAW);
        dataRAW = dataRAW(:, chanMapConn);
        dataRAW = dataRAW-median(dataRAW,2);
        dataRAW = filter(b1, a1, dataRAW);
        dataRAW = flipud(dataRAW);
        dataRAW = filter(b1, a1, dataRAW);
        dataRAW = flipud(dataRAW);
        dataRAW = gather_try(int16( dataRAW(ioffset + (1:NT),:)));
        
        dat_offset = offset/NchanTOT/2+ioffset;
        
        % Saves the waveforms occuring within each batch
        for i = 1:length(kcoords2)
            temp = ismember(spikeTimes(ia{i}), [nSamples/2+1:size(dataRAW,1)-nSamples/2] + dat_offset) & ~spkT{i};
            spkT{i}(temp) = 1; %now these spikes have been detected, let's not repeat it.
            temp2 = spikeTimes(ia{i}(temp))-dat_offset;

            startIndicies = temp2-nSamples/2+1;
            stopIndicies = temp2+nSamples/2;
            X = cumsum(accumarray(cumsum([1;stopIndicies(:)-startIndicies(:)+1]),[startIndicies(:);0]-[0;stopIndicies(:)]-1)+1);
            X = X(1:end-1);
            
            waveforms = reshape(dataRAW(X,indicesTokeep{i})',size(indicesTokeep{i},1),nSamples,[]);
            
            fwrite(fidSpk{i},waveforms(:),'int16');
            
            %Compute features (only 2)
            w2 = reshape(waveforms,[size(waveforms,1)*size(waveforms,2),size(waveforms,3)]);
            wranges = int64(range(w2,1));
            wpowers = int64(sum(w2.^2,1)/size(w2,1)/100);
             
            Fet = double([wranges; wpowers; spikeTimes(ia{i}(temp))']);
            fprintf(fidFet{i},'%d\t%d\t%d\n',Fet);
            
        end
        
        clear dataRAW
        
    end
    
    for i = 1:length(kcoords2)
        fclose(fidSpk{i});
        fclose(fidFet{i});
    end
end