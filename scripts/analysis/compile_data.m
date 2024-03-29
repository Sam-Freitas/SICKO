% This script takes the combined csvs and compiles the data into a longitudinal study for future analysis 
% The input is the combined csv (named just the experiment name.csv) 
% data where each row has all the associated data for that specific day or
% session
clear all
close all force hidden

% get csv filepath of the initial combined file
[CSV_filename,CSV_filepath] = uigetfile('/Volumes/Sutphin server/Users/Luis Espejo/SICKO/Experiments/*.csv',...
                        'Select the Experiment csv File');
csv_table = readtable(fullfile(CSV_filepath,CSV_filename),'VariableNamingRule','preserve'); % Your parsing will be different

% this fixes the 001-009 export problem that can happen
days = csv_table.Day;
days = str2double(erase(string(days),{'001','002','003','004','005','006','007','008','009'}));
csv_table.Day = days;

% sometimes there is a problem with the naming scheme and the sessions get
% mixed up so the session variable gets removed
csv_table.Session = ones(size(csv_table.Session));

% find the "intensity" data as its the first data location
imported_csv_header = csv_table.Properties.VariableNames;
idx_of_intensity = string(imported_csv_header) == 'Intensity';
idx_of_intensity = nonzeros((1:length(idx_of_intensity)).*(idx_of_intensity));

% convert identifiers to cell
identifiers = table2cell(csv_table(:,[2:6]));
data = table2array(csv_table(:,[8:12]));
full_paths = csv_table.("Full Path");
repeats = csv_table.("Biological Replicate");
try
    conditions = csv_table.Condition;
catch
    disp('conditions not found using Strain (group) instead')
    conditions = csv_table.("Strain (group)");
end
% sessions = csv_table.Session;
% days = csv_table.Day;
locations = csv_table.("ID (well location)");

% initalize arrays
identifiers_idx = zeros(size(identifiers));
unique_iden = cell(1,size(identifiers,2));
unique_iden_str = unique(string(identifiers),'rows');

% this transforms the indentifiers (day,session,condition,location,etc) and
% into indexable numbers for ease of data parsing 

% step through each identifier
for i = 1:size(identifiers,2)
    
    % isolate single iden
    this_iden = identifiers(:,i);
    
    % check if numeric 
    if isnumeric(this_iden{1})
        this_iden = cellstr(string(this_iden));
    end
    
    % sort the idenification after finding unique values
    unique_iden{1,i} = natsort(unique(this_iden));
    
    % step through each unique identifier
    for j = 1:length(unique_iden{1,i})
        
        % find and the index of matching strings
        this_identifier_idx = string(this_iden)==string(unique_iden{1,i}{j});
        % and create the identity matrix 
        identifiers_idx(this_identifier_idx,i) = j;
    end
end
clear i j this_identifier_idx

% all this does is create a numerical representation of the unique iden
unique_iden2 = cell(max(cellfun(@length,unique_iden)),size(identifiers,2));
for i = 1:size(identifiers,2)
    this_iden = unique_iden{i};
    unique_iden2(1:length(this_iden),i) = this_iden;
    clear this_iden
end

% find all the uniqe identifiers 
unique_rows_idx = unique(identifiers_idx,'rows');
% initalize the averaged data 
data_means = zeros(length(unique_rows_idx),5);
% createa a index list 
idx = (1:length(identifiers))';

% this averages the data through the picture replicates 
% iterate through the unique rows
for i = 1:length(unique_rows_idx)
    % isolate 
    this_unique_row = unique_rows_idx(i,:);
    % repeat the row
    repeated_row = repmat(this_unique_row,[length(identifiers_idx),1]);
    
    % isolate the indexes of the unique data
    this_idx = (sum(abs(identifiers_idx-repeated_row),2)==0);
    this_idx = nonzeros(this_idx.*idx);
    
    % isolate and create the means of the data points (there are usually 3
    % that are combined into one)
    this_data = data(this_idx,:);
    this_data = mean(this_data);
    this_data(3:4) = (this_data(3:4)>0);
    
    % populate the data 
    data_means(i,:) = round(this_data,2);
        
end
clear this_data repeated_row this_idx this_unique_row

% this next part of the script is the putting the isolated columns into
% arrays for future analysis 
final_idx_no_day_session = unique_rows_idx(:,[1,2,5]);
unique_final_idx_no_day_session = unique(unique_rows_idx(:,[1,2,5]),'rows');

idx2 = (1:length(final_idx_no_day_session))';
isolated_intensity = cell(length(unique_final_idx_no_day_session),1);
isolated_area = cell(length(unique_final_idx_no_day_session),1);
isolated_censor = cell(length(unique_final_idx_no_day_session),1);
isolated_dead = cell(length(unique_final_idx_no_day_session),1);
isolated_fled = cell(length(unique_final_idx_no_day_session),1);

% loop over each index and populate the sub arrays that will make up the
% exported array
for i = 1:length(unique_final_idx_no_day_session)
    
    this_final_idx = unique_final_idx_no_day_session(i,:);
    
    repeated_row = repmat(this_final_idx,...
        [length(final_idx_no_day_session),1]);
    
    % isolate the indexes of the unique data
    this_idx = (sum(abs(final_idx_no_day_session-repeated_row),2)==0);
    this_idx = nonzeros(this_idx.*idx2);
    
    % isolate the indexes and populate the data 
    this_isolated_inten = cell(length(this_idx),1);
    this_isolated_area = cell(length(this_idx),1);
    this_isolated_censor = cell(length(this_idx),1);
    this_isolated_dead = cell(length(this_idx),1);
    this_isolated_fled = cell(length(this_idx),1);
    % populate the sub array data
    for j = 1:length(this_idx)
        sub_idx = this_idx(j);
        
        this_isolated_inten{j} = data_means(sub_idx,1);
        this_isolated_area{j} = data_means(sub_idx,2);
        this_isolated_censor{j} = data_means(sub_idx,3);
        this_isolated_dead{j} = data_means(sub_idx,4);
        this_isolated_fled{j} = data_means(sub_idx,5);
        
        if ~this_isolated_censor{j} && this_isolated_fled{j}
            this_isolated_censor{j} = 1;
        end
    end
    
    isolated_intensity{i} = cell2mat(this_isolated_inten)';
    isolated_area{i} = cell2mat(this_isolated_area)';
    isolated_censor{i} = cell2mat(this_isolated_censor)';
    isolated_dead{i} = cell2mat(this_isolated_dead)';
    isolated_fled{i} = cell2mat(this_isolated_fled)';
    
end
clear this_isolated_area this_isolated_inten this_isolated_censor this_isolated_dead this_isolated_fled

% isolate the data and combine them into a single large array 
isolated_data = [isolated_intensity,isolated_area,isolated_censor,isolated_dead,isolated_fled];

% find the unique parts of the system that need to be parsed out to make
% sure that the data is not overlapping itself
unique_repeats = natsort(unique(repeats));
unique_conditions = natsort(unique(conditions));
unique_locs = natsort(unique(locations));

unique_final_no_day_session = cell(size(unique_final_idx_no_day_session));

for i = 1:length(unique_repeats)
    this_idx = find(unique_final_idx_no_day_session(:,1)==i);
    unique_final_no_day_session(this_idx,1) = unique_repeats(i);
end
for i = 1:length(unique_conditions)
    this_idx = find(unique_final_idx_no_day_session(:,2)==i);
    unique_final_no_day_session(this_idx,2) = unique_conditions(i);
end
for i = 1:length(unique_locs)
    this_idx = find(unique_final_idx_no_day_session(:,3)==i);
    unique_final_no_day_session(this_idx,3) = unique_locs(i);
end

T1 = cell2table(unique_final_no_day_session);
T2 = cell2table(isolated_data);

final_table = [T1,T2];

header_names = cellstr(["Biological Replicate",...
    "Condition","ID (well location)",...
    "Intensity","Area","Censored","Dead","Fled"]);

final_table.Properties.VariableNames = header_names;

out_path = CSV_filepath;

[~,in_name,~] = fileparts(CSV_filename);
out_name =  [in_name '_compiled.csv'];

writetable(final_table,fullfile(out_path,out_name));





