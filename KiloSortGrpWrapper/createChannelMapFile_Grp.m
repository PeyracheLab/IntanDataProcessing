function createChannelMapFile_Grp(par,elecGrp,savepath)
%  create a channel map file

xcoords = [];
ycoords = [];
ngroups = length(elecGrp);

if ~isfield(par,'nElecGps')
    warning('No Electrode/Spike Groups found in xml.  Using Anatomy Groups instead.')
    tgroups = par.ElecGp(elecGrp);
else
    t = par.AnatGrps;
    tgroups = cell(length(elecGrp),1);
    for g = 1:length(elecGrp)
        tgroups{g} = par.AnatGrps(elecGrp(g)).Channels;
    end
end
for a= 1:ngroups %being super lazy and making this map with loops
    x = [];
    y = [];
    tchannels  = tgroups{a};
    for i =1:length(tchannels)
        x(i) = length(tchannels)-i;
        y(i) = -i*10;
        if mod(i,2)
            x(i) = -x(i);
        end
    end
    x = x+a*200
    xcoords = [xcoords;x(:)];
    ycoords = [ycoords;y(:)];
end

Nchannels = length(xcoords);

kcoords = zeros(Nchannels,1);
for a= 1:ngroups
    kcoords(tgroups{a}+1) = a;
end

connected   = true(Nchannels, 1);
chanMap     = 1:Nchannels;
chanMap0ind = chanMap - 1;

save(fullfile(savepath,'chanMap.mat'),'chanMap','connected', 'xcoords', 'ycoords', 'kcoords', 'chanMap0ind')
