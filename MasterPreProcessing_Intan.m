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

function MasterPreProcessing_Intan(fbasename,varargin)

mergename = Process_Intan2ConcatenateDat(fbasename);

%Now we can cd to the new 'mergename' folder
if ~exist(mergename,'dir')
    warning(['Folder ' mergename ' has not been created!! Type ''dbquit'' to exit debugging mode'])
    keyboard
end
cd(mergename)

disp('Renaming files DONE! Now KiloSort')
if ~isempty(varargin)
    Process_KiloSortGrp(mergename,varargin{1})
else
    Process_KiloSortGrp(mergename)
end

%Give writing access to all members of the 'datausers' group
cmd = ['chown -R adrien.datausers ' mergename];
system(cmd)

%Add stuff relative to video here...
