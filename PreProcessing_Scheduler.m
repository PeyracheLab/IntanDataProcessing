filename = '~/IntanProcessing_Schedule.txt';
baseData = '/media/DataAdrienBig/PeyracheLabData/';

S = 1;

while ~isempty(S) 
    
    fid = fopen(fname,'r');
    S = fscanf(fid, '%c');
    fclose(fid);
    [dset, S] = strtok(S,'\n');
    fid = fopen(fname,'w');
    fprintf(fid,'%c',S);
    fclose(fid);    
    
    dset = fullfile(baseData,dset);
    if ~exist(dset,'dir')
        printf('Sorry! %s does not exist, skipping\n',dset);
    else
        printf('Found dataset %s to process\n',dset);
    end
    
    [animalID,~,~] = fileparts(dset);
    [~,animalID,~] = fileparts(animalID);
    
    try
       cd(dset)
       MasterPreProcessing_Intan (animalID)
    catch
        warning(lasterr)
        printf('There''s been an error during the execution of MasterPreProcessing (see above), sorry for that\n')
    end
    
end

    
   