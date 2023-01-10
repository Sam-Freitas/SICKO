% This script combines all the associated csvs' that are created when the manual SICKO analysis is performed. 
% Each Day of recorded data should have
% 6 csvs that will be automatically scraped and combined in this script 
% censored.csv - dead.csv - fled.csv - image_integral_areas.csv 
% image_integral_intensities.csv - image_names.csv
% When this script is finished, there should be a '_outputs' folder
% adjacent to where the data folder is located, this will contain the
% combined csv labeled as the experiments overarching name.csv
% 
% [fList1,pList1] = matlab.codetools.requiredFilesAndProducts([pwd '/Worm_paparazzi_setupv2.m']);
clear all
close all force hidden
curr_path = pwd;

% This script will error out if there are either too many or too few csvs
% in the folders, nothing will be overwritten but it will not finish 

% must select the experiment folder
data_path = fullfile("Y:\Users\Luis Espejo\SICKO\Experiments");
overarching_folder = uigetdir(data_path);

% get the file parts of the selected experiment folder
[final_save_path,final_save_name,~] = fileparts(overarching_folder);
disp(['Combining all CSVs for ' char(final_save_name)])
disp(' ')

overarching_dir = dir(overarching_folder);
dirFlags = [overarching_dir.isdir]; % check for folders (directories)
overarching_dir = overarching_dir(dirFlags); % keep only directories
overarching_dir(ismember( {overarching_dir.name}, {'.', '..'})) = [];  %remove . and ..

% get the biological replicated and names 
biorep_names = strings(length(overarching_dir),1);
disp('Found biological replicates:')
for i = 1:length(overarching_dir)
    biorep_names(i) = overarching_dir(i).name;
    disp(biorep_names(i))
end

row_index_count = 1;

% this loops over every biological replicate to populate a final table
% which combines all the associated data into a single csv
for n = 1:length(overarching_dir)
    
    % get the n'th bio repliacte dir and assocaited information 
    bio_replicate_dir = dir(fullfile(overarching_dir(n).folder,overarching_dir(n).name));
    dirFlags = [bio_replicate_dir.isdir];
    bio_replicate_dir = bio_replicate_dir(dirFlags);
    bio_replicate_dir(ismember( {bio_replicate_dir.name}, {'.', '..','Settings', 'settings'})) = [];  %remove . and ..

    % find the conditions named by the inner folders
    condition = strings(length(bio_replicate_dir),1);
    disp(' ')
    disp(['For --' char(biorep_names(n)) '-- Found experiments:'])
    for i = 1:length(bio_replicate_dir)
        condition(i) = bio_replicate_dir(i).name;
        disp(condition(i))
    end

    % find the names of the sessions (days) and number of sessions (days) that each
    % condition will have 
    k=1;
    inner_session_names = strings(length(bio_replicate_dir),1);
    num_sessions_per_exp = zeros(1,length(bio_replicate_dir));
    for i = 1:length(bio_replicate_dir)
        % temp_dir_step is stepping into each bio replicate
        temp_dir_step = dir(fullfile(bio_replicate_dir(i).folder,bio_replicate_dir(i).name));
        dirFlags = [temp_dir_step.isdir];
        temp_dir_step = temp_dir_step(dirFlags);
        temp_dir_step(ismember( {temp_dir_step.name}, {'.', '..'})) = [];  %remove . and ..
        
        num_sessions_per_exp(i) = length(temp_dir_step);
        for j = 1:length(temp_dir_step)
            inner_session_names(k) = temp_dir_step(j).name;
            k=k+1;
        end
    end

    % convert the strings of the D1,D2...DN to a number 1,2...N
    days = zeros(1,sum(num_sessions_per_exp));
    for i = 1:length(inner_session_names)
        temp_string = char(inner_session_names(i));
        %finds and isolates the last underscore
        underscore_indices = strfind(temp_string, '_');
        this_day = temp_string(underscore_indices(end)+2:end);
        days(i) = str2double(this_day);
    end
    clear this_day underscore_indices temp_string
    
    % this converts the condition names from a Nx1 array to a 1x(number of
    % sessions per condition) 
    k=1;
    for i = 1:length(condition)
        for j = 1:num_sessions_per_exp(i)
            condition2(k) = condition(i);
            k=k+1;
        end
    end
    condition = condition2;
    clear condition2
    
    % this entire block of code recursively finds all the CVSs in the given
    % folder and outputs the full paths of every one 
    if ispc
        [~,message,~] = fileattrib([fullfile(overarching_dir(n).folder,overarching_dir(n).name),'\*']);
    else
        [~,message,~] = fileattrib([fullfile(overarching_dir(n).folder,overarching_dir(n).name),'/*']);
    end
    fprintf('There are %i total files & folders in this biological repeat.\n',numel(message));
    allExts = cellfun(@(s) s(end-2:end), {message.Name},'uni',0); % Get exts
    CSVidx = ismember(allExts,'csv');    % Search ext for "CSV" at the end
    CSV_filepaths = {message(CSVidx).Name};  % Use CSVidx to list all paths.
    [~,CSV_names,~] = fileparts(CSV_filepaths); %not including GUI files in final CSV
    CSV_flag = ones(1,length(CSV_names));
    for c = 1:length(CSV_names) % get rid of the GUI stuff
        if isequal(CSV_names{c},'GUI_dead_data')
            CSV_flag(c) = 0;
        elseif isequal(CSV_names{c},'GUI_fled_data')
            CSV_flag(c) = 0;
        end
    end
    CSV_filepaths = CSV_filepaths(logical(CSV_flag));
    fprintf('There are %i files with *.CSV exts.\n',numel(CSV_filepaths));

    % censored,dead,fled,areas,intensities,names
    % Read in each of the associated CVSs
    csv_cells = cell(1,length(CSV_filepaths)); 
    for i = 1:numel(CSV_filepaths)
        csv_cells{i}= readcell(CSV_filepaths{i}); 
    end
    
    % this gets the path names for each of the specified csvs and make sure
    % theyre associated to the correct indexes
    k=1;
    for i = 1:6:length(csv_cells)
        [filepath,~,~] = fileparts(CSV_filepaths{i});
        [~,path_names{k},~] = fileparts(filepath);
        k=k+1;
    end
    clear filepath CSVidx message CSV_flag CSV_names CSV_filepaths allExts
    
    % this loop isolates many of the parts of CSVs that were just read into
    % memory and assigns them to a variable for easier reading and-
    % combining into a single csv
    k=1;
    for i = 6:6:length(csv_cells)
        wells_and_replicates{k} = csv_cells{i};
        wells_and_replicates{k} = erase(wells_and_replicates{k},'.tif');

        for j = 1:length(wells_and_replicates{k})
            temp = wells_and_replicates{k}{j};
            split_idx = regexp(temp,'[abcdefghijklmnopABCDEFGHIJKLMNOP]'); 
            % this splits into what well and what repliacte each of the
            % data sessions 
            wells{k}{j} = temp(1:split_idx);
            replicates{k}{j} = temp(split_idx+1:end);
            
        end
        
        k=k+1;
    end
    clear temp temp_dir_step split_idx
    
    % this isolated the sessions variable
    k=1;
    for i = 1:length(bio_replicate_dir)
        for j = 1:num_sessions_per_exp(i)
            sessions{k} = zeros(1,length(wells{k}))+j;
            k=k+1;
        end
    end
    
    % this isolated the censors dead fled areas and integrated intensities
    k=1;
    for i = 1:6:length(csv_cells)
        censors{k} = csv_cells{i};
        dead{k} = csv_cells{i+1};
        fled{k} = csv_cells{i+2};
        areas{k} = csv_cells{i+3};
        int_inten{k} = csv_cells{i+4};
        k=k+1;
    end
    
    % this is the start of the csv populating, it takes each csv and puts
    % it into a easily acessable place that can be accessed easily
%    ["Full Path","Biological Replicate","Condition","Session","Day","ID (well location)","Picture Replicate","Intensity","Area","Censored","Dead","Fled"];

    k=1;
    for i = 1:length(path_names)
        for j = 1:length(wells{i})
            final_csv(row_index_count,1) = {path_names{i}};
            final_csv(row_index_count,2) = {biorep_names(n)};                  %biological replicate
            final_csv(row_index_count,3) = {condition(i)};
            final_csv(row_index_count,4) = {sessions{i}(j)};
            final_csv(row_index_count,5) = {days(i)};                  %days
            final_csv(row_index_count,6) = {wells{i}{j}};
            final_csv(row_index_count,7) = {replicates{i}{j}};
            final_csv(row_index_count,8) = {int_inten{i}{j}};
            final_csv(row_index_count,9) = {areas{i}{j}};
            final_csv(row_index_count,10) = {censors{i}{j}};
            final_csv(row_index_count,11) = {dead{i}{j}};
            final_csv(row_index_count,12) = {fled{i}{j}};       
            row_index_count=row_index_count+1;
        end
    end
    
    clearvars -except n csv_header final_csv data_path row_index_count overarching_folder final_save_path final_save_name overarching_dir dirFlags overarching_dir biorep_names

end
disp(' ')
disp('Finished combining CSVs, writing to disk')

% Make the output folder
mkdir(fullfile(final_save_path,[final_save_name '_outputs']));
% the header for the csv that is produced 
csv_header = ["Full Path","Biological Replicate","Condition","Session","Day","ID (well location)","Picture Replicate","Intensity","Area","Censored","Dead","Fled"];

try
    T = cell2table(final_csv,'VariableNames',csv_header);
    writetable(T,fullfile(final_save_path,[final_save_name '_outputs'],[final_save_name '.csv']))
    
    disp('Data saved to:')
    disp(fullfile(final_save_path,[final_save_name '_outputs']))
catch
    disp('CSV probably open, saving to _1')
    T = cell2table(final_csv,'VariableNames',csv_header);
    writetable(T,fullfile(data_path,[final_save_name '_1.csv']))
end



