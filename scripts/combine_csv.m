curr_path = pwd;

data_path = fullfile(erase(curr_path,'scripts'),'data');

overarching_folder = uigetdir(data_path);

[~,final_save_name,~] = fileparts(overarching_folder);

% mainFolder = uigetdir();    % Selectyour Main folder
[~,message,~] = fileattrib([overarching_folder,'\*']);

fprintf('\n There are %i total files & folders.\n',numel(message));

allExts = cellfun(@(s) s(end-2:end), {message.Name},'uni',0); % Get exts

CSVidx = ismember(allExts,'csv');    % Search ext for "CSV" at the end
CSV_filepaths = {message(CSVidx).Name};  % Use CSVidx to list all paths.

fprintf('There are %i files with *.CSV exts.\n',numel(CSV_filepaths));

csv_cells = cell(1,length(CSV_filepaths));
% areas,intesities,names
for ii = 1:numel(CSV_filepaths)
    csv_cells{ii}= readcell(CSV_filepaths{ii}); % Your parsing will be different
end

csv_header = ["Experiment","Image name","Integrated area","Integrated intensity"];

total_cells = sum(cellfun(@(x) numel(x),csv_cells));

final_csv = cell(total_cells/4 ,4);

k=1;
for i = 1:3:length(csv_cells)
    [filepath,~,~] = fileparts(CSV_filepaths{i});
    [~,exp_name,~] = fileparts(filepath);
    % import experimental names
    for j = 1:length(csv_cells{i})
        final_csv(k,1) = {exp_name};
        final_csv(k,2) = csv_cells{i+2}(j);
        final_csv(k,3) = csv_cells{i}(j);
        final_csv(k,4) = csv_cells{i+1}(j);
        k=k+1;
    end
    
end

T = cell2table(final_csv,'VariableNames',csv_header);
writetable(T,fullfile(data_path,[final_save_name '.csv']))

