clear all
clc
close all force hidden

% get csv
[CSV_filename,CSV_filepath] = uigetfile('/Volumes/Sutphin server/Users/Luis Espejo/SICKO/Experiments/*.csv',...
    'Select the Compiled csv File');
% read table
csv_table= readtable(fullfile(CSV_filepath,CSV_filename),'VariableNamingRule','preserve'); % Your parsing will be different

% get conditions
conditions = string(natsort(unique((csv_table.Condition))));
condition_idx = 1:length(conditions);

% get names of the csv
csv_names = csv_table.Properties.VariableNames;

% set up variables
col_intensity = contains(string(csv_names),"Intensity");
col_area = contains(string(csv_names),"Area");
col_censor = contains(string(csv_names),"Censored");
col_dead = contains(string(csv_names),"Dead");
col_defaults = zeros(size(col_dead)); col_defaults(1:3) = 1;

%isolate tables
table_inten = csv_table(:,logical(col_defaults+col_intensity));
table_area = csv_table(:,logical(col_defaults+col_area));

% isolate datasets
data_intensity = table2array(csv_table(:,col_intensity));
data_area = table2array(csv_table(:,col_area));
data_censor = table2array(csv_table(:,col_censor));
data_dead = table2array(csv_table(:,col_dead));

% initalize datasets
data_sess_died = zeros(length(data_dead),1);
data_sess_censored = zeros(length(data_dead),1);

% get all the days that a worm died on
% effective lifespan

%step through all data_dead
for i = 1:length(data_dead)
    % find the first time there is a 1 in the dead section
    sess_died = find(data_dead(i,:)>0,1,'first');
    % if its not empty then make a sess_died
    if ~isempty(sess_died)
        data_sess_died(i) = sess_died;
    end
    % do the same thing but find the censored day
    sess_censored = find(data_censor(i,:)>0,1,'first');
    if ~isempty(sess_censored)
        data_sess_censored(i) = sess_censored;
    end
    
end
clear sess_censored sess_died i

% if the worm was not dead then set its day of death to end + 1
data_sess_died_plot = data_sess_died;
data_sess_died_plot(data_sess_died_plot==0) = (size(data_dead,2) + 1);

% initalize indexing variables for
% worms that got infected
idx_infected = (mean(data_area,2,'omitnan')>0);
% that are NOT censored
idx_good_wells = (data_sess_censored==0);
% that are not dead
idx_not_dead = (data_sess_died==0);
% worms that only have a single data point that didnt die
idx_only_single_point = (sum(data_area>0,2)==1).*(~(data_sess_died>0));

idx_yes = logical(~idx_only_single_point);

% start with keep everything
idx_2d_data_to_keep = ones(size(data_dead));
% remove all censored data
idx_2d_data_to_keep(data_censor==1) = NaN;
% remove all dead data
for i = 1:length(data_sess_died)
    if data_sess_died(i) > 0 
        idx_2d_data_to_keep(i,data_sess_died(i):end) = -1;
    end
end

non_cen_data_area = data_area.*idx_2d_data_to_keep;
non_cen_data_area(idx_2d_data_to_keep==-1) = -1;
non_cen_data_intensity = data_intensity.*idx_2d_data_to_keep;
non_cen_data_intensity(idx_2d_data_to_keep==-1) = -1;

display_data(non_cen_data_area,logical(idx_infected.*(~idx_only_single_point)),...
    conditions,csv_table,data_censor,'Integrated_Area')

heatmap_data(non_cen_data_area,idx_yes,conditions,csv_table,data_sess_died_plot,'Integrated_Area')
heatmap_data(non_cen_data_intensity,idx_yes,conditions,csv_table,data_sess_died_plot,'Integrated_Intensity')



function heatmap_data(this_data,idx_yes,conditions,csv_table,data_sess_died,title_ext)

overall_max = max(max(this_data(idx_yes,:)));

figure('units','normalized','outerposition',[0 0 1 1]);

x = 1:size(this_data,2);
for i = 1:length(conditions)
    subplot(2,3,i)
    
    % find the index that represents this condition
    this_condition_idx = string(csv_table.Condition) == conditions(i);
    this_condition_idx = logical(idx_yes.*this_condition_idx);
    % isolate its data
    this_conditions_data = this_data(this_condition_idx,:);
    this_conditions_death = data_sess_died(this_condition_idx);
    % integrate across time for sorting
    data_across_time_integrated = sum(this_conditions_data,2,'omitnan');
    % combine first the death then integrated datats into a single martrix
    combined_data_for_sorting = [this_conditions_death,data_across_time_integrated];
    % first sort by day of death then sort by integrated data across time
    % categorically 
    [~,sort_idx] = sortrows(combined_data_for_sorting,[1,2]);
    % get the final data representation
    this_conditions_data = this_conditions_data(sort_idx,:);
    % scale the data
    this_scale = round((max(this_conditions_data(:))/overall_max)*255);
    % to rgb
    temp_img = ind2rgb(round(rescale(this_conditions_data,0,this_scale))...
        , parula(256));
    % make it square
    temp_img = imresize(temp_img,[size(temp_img,1),size(temp_img,1)],'nearest');
    this_conditions_data_sq = imresize(this_conditions_data,[size(temp_img,1),size(temp_img,1)],'nearest');
    % find deaths and censors
    [row_death,col_death] = find(this_conditions_data_sq == -1);
    [row_nan,col_nan] = find(isnan(this_conditions_data_sq));
    % replace death with red and nan with black
    for j = 1:length(row_death)
        temp_img(row_death(j),col_death(j),:) = [255,0,0];
    end
    for j = 1:length(row_nan)
        temp_img(row_nan(j),col_nan(j),:) = [0,0,0];
    end
    
    num_dead = length(unique(row_death));
    num_worms = sum(this_condition_idx);
    num_infected = sum(data_across_time_integrated>0);
    
    temp_img = imresize(temp_img,[1000,1000],'nearest');
    imshow(temp_img);
    xlabel('sessions');
    ylabel(["individual animals", ...
        string([num2str(num_dead) '/' num2str(num_worms) ' dead']), ...
        string([num2str(num_infected) '/' num2str(num_worms) ' infected'])]);
    title([char(conditions(i)) '_' char(title_ext)],'interpreter','none');

    
end

end


function display_data(this_data,idx_yes,conditions,csv_table,data_censor,title_ext)

non_cen_data = this_data.*imcomplement(data_censor);

for i = 1:length(conditions)
    
    disp([char(conditions(i)) '_' char(title_ext)])
    
    this_condition_idx = string(csv_table.Condition) == conditions(i);
    
    this_condition_idx = logical(idx_yes.*this_condition_idx);
    
    disp([num2str(sum(this_condition_idx)) ' Infected Worms'])
    
    this_conditon = this_data(this_condition_idx,:);
    
end

end