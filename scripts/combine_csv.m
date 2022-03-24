clear all
curr_path = pwd;

data_path = fullfile('/Volumes/Sutphin server/Users/Luis Espejo/SICKO/Experiments/');

overarching_folder = uigetdir(data_path);

[final_save_path,final_save_name,~] = fileparts(overarching_folder);

ovr_dir = dir(overarching_folder);
dirFlags = [ovr_dir.isdir];
ovr_dir = ovr_dir(dirFlags);
ovr_dir(ismember( {ovr_dir.name}, {'.', '..'})) = [];  %remove . and ..

biorep_names = strings(length(ovr_dir),1);


for i = 1:length(ovr_dir)
    biorep_names(i) = ovr_dir(i).name;
    disp(biorep_names(i))
end

row_index_count = 1;
r = row_index_count;

for n = 1:length(ovr_dir)
    
    inner_dir = dir(fullfile(ovr_dir(n).folder,ovr_dir(n).name));
    dirFlags = [inner_dir.isdir];
    inner_dir = inner_dir(dirFlags);
    inner_dir(ismember( {inner_dir.name}, {'.', '..'})) = [];  %remove . and ..
    
    group_names = strings(length(inner_dir),1);
    inner_session_names = strings(length(inner_dir),1);
    disp('Found experiments:')
    for i = 1:length(inner_dir)
        group_names(i) = inner_dir(i).name;
        disp(group_names(i))
    end
    k=1;
    
    num_sessions_per_exp = zeros(1,length(inner_dir));
    for i = 1:length(inner_dir)
        temp_dir_step = dir(fullfile(inner_dir(i).folder,inner_dir(i).name));
        dirFlags = [temp_dir_step.isdir];
        temp_dir_step = temp_dir_step(dirFlags);
        temp_dir_step(ismember( {temp_dir_step.name}, {'.', '..'})) = [];  %remove . and ..
        
        num_sessions_per_exp(i) = length(temp_dir_step);
        for j = 1:length(temp_dir_step)
            inner_session_names(k) = temp_dir_step(j).name;
            k=k+1;
        end
    end
    % creates blank vector
    days = zeros(1,sum(num_sessions_per_exp));
    % iterates through inner names and converts to days
    for i = 1:length(inner_session_names)
        temp_string = char(inner_session_names(i));
        %finds and isolates the last underscore
        underscore_indices = strfind(temp_string, '_');
        this_day = temp_string(underscore_indices(end)+2:end);
        
        days(i) = str2double(this_day);
        
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
    if ispc
        [~,message,~] = fileattrib([fullfile(ovr_dir(n).folder,ovr_dir(n).name),'\*']);
    else
        [~,message,~] = fileattrib([fullfile(ovr_dir(n).folder,ovr_dir(n).name),'/*']);
    end
    
    fprintf('\nThere are %i total files & folders in the overarching folder.\n',numel(message));
    
    allExts = cellfun(@(s) s(end-2:end), {message.Name},'uni',0); % Get exts
    
    CSVidx = ismember(allExts,'csv');    % Search ext for "CSV" at the end
    CSV_filepaths = {message(CSVidx).Name};  % Use CSVidx to list all paths.
    
    fprintf('There are %i files with *.CSV exts.\n',numel(CSV_filepaths));
    
    csv_cells = cell(1,length(CSV_filepaths));
    % censored,dead,areas,intensities,names
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
    for i = 6:6:length(csv_cells)
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
    for i = 1:length(inner_dir)
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
    csv_header = ["Full Path","Biological Replicate","Strain (group)","Session","Day","ID (well location)","Picture Replicate","Intensity","Area","Censored","Dead","Fled"];
    
    k=1;
    for i = 1:length(path_names)
        for j = 1:length(wells{i})
            final_csv(r,1) = {path_names{i}};
            final_csv(r,2) = {biorep_names(n)};                  %biological replicate
            final_csv(r,3) = {group_names(i)};
            final_csv(r,4) = {sessions{i}(j)};
            final_csv(r,5) = {days(i)};                  %days
            final_csv(r,6) = {wells{i}{j}};
            final_csv(r,7) = {replicates{i}{j}};
            final_csv(r,8) = {int_inten{i}{j}};
            final_csv(r,9) = {areas{i}{j}};
            final_csv(r,10) = {censors{i}{j}};
            final_csv(r,11) = {dead{i}{j}};
            final_csv(r,12) = {dead{i}{j}};       
            r=r+1;
        end
        
    end
end

mkdir(fullfile(final_save_path,[final_save_name '_outputs']));

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



