clear all
curr_path = pwd;

data_path = fullfile(erase(curr_path,'scripts'),'data');

overarching_folder = uigetdir(data_path);

[~,final_save_name,~] = fileparts(overarching_folder);


ovr_dir = dir(overarching_folder);
dirFlags = [ovr_dir.isdir];
ovr_dir = ovr_dir(dirFlags);
ovr_dir(ismember( {ovr_dir.name}, {'.', '..'})) = [];  %remove . and ..

group_names = strings(length(ovr_dir),1);

disp('Found experiments:')
for i = 1:length(ovr_dir)
    group_names(i) = ovr_dir(i).name;
    disp(group_names(i))
end

num_sessions_per_exp = zeros(1,length(ovr_dir));
for i = 1:length(ovr_dir)
    temp_dir_step = dir(fullfile(ovr_dir(i).folder,ovr_dir(i).name));
    dirFlags = [temp_dir_step.isdir];
    temp_dir_step = temp_dir_step(dirFlags);
    temp_dir_step(ismember( {temp_dir_step.name}, {'.', '..'})) = [];  %remove . and ..
    
    num_sessions_per_exp(i) = length(temp_dir_step);
end

k=1;
for i = 1:length(group_names)
    for j = 1:num_sessions_per_exp(i)
        group_names2(k) = group_names(i);
        k=k+1;
    end
end
group_names = group_names2;
clear group_names2

% mainFolder = uigetdir();    % Selectyour Main folder
[~,message,~] = fileattrib([overarching_folder,'\*']);

fprintf('\nThere are %i total files & folders in the overarching folder.\n',numel(message));

allExts = cellfun(@(s) s(end-2:end), {message.Name},'uni',0); % Get exts

CSVidx = ismember(allExts,'csv');    % Search ext for "CSV" at the end
CSV_filepaths = {message(CSVidx).Name};  % Use CSVidx to list all paths.

fprintf('There are %i files with *.CSV exts.\n',numel(CSV_filepaths));

csv_cells = cell(1,length(CSV_filepaths));
% censored,dead,areas,intesities,names
for i = 1:numel(CSV_filepaths)
    csv_cells{i}= readcell(CSV_filepaths{i}); % Your parsing will be different
end

k=1;
for i = 1:5:length(csv_cells)
    [filepath,~,~] = fileparts(CSV_filepaths{i});
    [~,path_names{k},~] = fileparts(filepath);
    k=k+1;
end
clear filepath CSVidx message

k=1;
for i = 5:5:length(csv_cells)
    wells_and_replicates{k} = csv_cells{i};
    wells_and_replicates{k} = erase(wells_and_replicates{k},'.tif');
    
    for j = 1:length(wells_and_replicates{k})
        temp = wells_and_replicates{k}{j};
        split_idx = regexp(temp,'[abcdefghijklmnopABCDEFGHIJKLMNOP]');
        
        wells{k}{j} = temp(1:split_idx);
        replicates{k}{j} = temp(split_idx+1:end);
        
    end
    
    k=k+1;
end
clear temp temp_dir_step split_idx

k=1;
for i = 1:length(ovr_dir)
    for j = 1:num_sessions_per_exp(i)
        sessions{k} = zeros(1,length(wells{k}))+j;
    k=k+1;
    end
end

k=1;
for i = 1:5:length(csv_cells)
    censors{k} = csv_cells{i};
    dead{k} = csv_cells{i+1};
    areas{k} = csv_cells{i+2};
    int_inten{k} = csv_cells{i+3};
    k=k+1;
end


% csv_header = ["Full Path","Group","Well","Session","Picture Replicate","Area","Intensity"]; 
csv_header = ["Full Path","Biological Replicate","Strain (group)","Session","Day","ID (well location)","Picture Replicate","Intensity","Area","Censored","Dead"];

k=1;
for i = 1:length(path_names)
    for j = 1:length(wells{i})
        final_csv(k,1) = {path_names{i}};
        final_csv(k,2) = {path_names{i}};                  %biological replicate
        final_csv(k,3) = {group_names(i)};
        final_csv(k,4) = {sessions{i}(j)};
        final_csv(k,5) = {path_names{i}};                  %days
        final_csv(k,6) = {wells{i}{j}};
        final_csv(k,7) = {replicates{i}{j}};
        final_csv(k,8) = {int_inten{i}{j}};
        final_csv(k,9) = {areas{i}{j}};
        final_csv(k,10) = {censors{i}{j}};
        final_csv(k,11) = {dead{i}{j}};
        k=k+1;
    end
    
end

try
T = cell2table(final_csv,'VariableNames',csv_header);
writetable(T,fullfile(data_path,[final_save_name '.csv']))

disp('Data saved to:')
disp(fullfile(data_path,[final_save_name '.csv']))
catch
    disp('CSV probably open, saving to _1')
    T = cell2table(final_csv,'VariableNames',csv_header);
    writetable(T,fullfile(data_path,[final_save_name '_1.csv']))
end



