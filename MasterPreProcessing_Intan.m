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

function MasterPreProcessing_Intan(fbasename)

mergename = Process_Intan2ConcatenateDat(fbasename);

%Now we can cd to the new 'mergename' folder
if ~exist(mergename,'dir')
    warning(['Folder ' mergename ' has not been created!! Type ''dbquit'' to exit debugging mode')
    keyboard
end
cd(mergename)

Process_KiloSortGrp(mergename)

%Add stuff relative to video here...
