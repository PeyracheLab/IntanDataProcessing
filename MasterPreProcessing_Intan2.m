% How to use it:
% create a folder whose name is typically Animal-YYMMDD
% This folder should contain the successive Intan recordings of the day.
% Make sure sure the first recording of the day (at least) contains a
% proper xml file.
% Launch MasterPreProcessing_Intan
% You should get data ready to be manually spike sorted soon!
%
% USAGE: MasterPreProcessing_Intan(fbasename)
% where fbasename is the base name of the Intan recording (everything until
% the last '_', e.g. 'MouseXXX_YYMMDD')

%Adrien Peyrache, 2017

function MasterPreProcessing_Intan2(fbasename,varargin)

% %% Message for slack
% msg_starting = MakeSlackAttachment('New open task [urgent]: <link.to.website>', '', '', '#ff0000', {'KiloSort starting', ['doing animal ' fbasename]});
% SendSlackNotification('https://hooks.slack.com/services/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', '', '#kilosort', 'Kilosort', 'http://www.icon.com/url/to/icon/image.png', [], msg_starting);


mergename = Process_Intan2ConcatenateDat(fbasename);

%Now we can cd to the new 'mergename' folder
if ~exist(mergename,'dir')
    warning(['Folder ' mergename ' has not been created!! Type ''dbquit'' to exit debugging mode'])
    keyboard
end
cd(mergename)

datName = [mergename '.dat'];
disp('Renaming files DONE! Now KiloSort')
if ~exist(datName,'file')
    error('No dat file!')
end

%% TODO INSERT DOWNSAMPLING DAT FILE
%Process_LFPfromDat

%% Comment these two lines to get rid of new processing
eval(['!cp ' datName ' ' datName '_backup']);

if exist([mergename '.xml'],'file')
    par = LoadXml([mergename '.xml']);
else
    error('No xml file!')
end

% Process_RemoveMedianHighFq(mergename,par.nChannels);
UpdateXml_SpkGrps([mergename '.xml']);

%%% Uncomment this to reverse to old processing
%if ~isempty(varargin)
%    Process_KiloSortGrp(mergename,varargin{1})
%else
%Process_KiloSortGrp(mergename)
%end

%% Comment these two lines to get rid of new processing
KiloSort2Wrapper;
system(['mv ' datName '_backup ' datName ])
cd('..')
system(['rm -r ' mergename '-0*'])
system(['mv ' mergename '/* ./'])
system(['rm -r ' mergename '/'])

%% Message for slack
%msg_finished = MakeSlackAttachment('New open task [urgent]: <link.to.website>', '', '', '#0000ff', {'KiloSort finished', ['done animal ' fbasename]});
%SendSlackNotification('https://hooks.slack.com/services/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', '', '#kilosort', 'Kilosort', 'http://www.icon.com/url/to/icon/image.png', [], msg_finished);

%Give writing access to all members of the 'datausers' group
%cmd = ['chown -R adrien.adrien ' mergename];
%system(cmd)

%Add stuff relative to video here...
