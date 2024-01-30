% this script is the analysis for all the previously collected, combined, compiled data. 
% This script also implements the SICKO coefficient and plots the heatmaps of the infection data
% The input data is the compiled.csv and outputs an analyzed data csv along
% as a heatmap image of each of the conditions

% analysis csv will output data with either a number (measured data), NaN
% (censored data), -1 (worm is dead), or 0 (no measured data)

clear all
close all force hidden

csv_output_header = ["Biological Replicate","Condition","ID (well location)",...
    "Is Dead","Is Last Day Censored","Last Day of Observation","First Day of nonzero data",...
    ...
    "Intensity at First Day of Infection","Intensity at Last Day of Observation",...
    "Intensity Integrated Across Time","Max Intensity Slope to a Point"...
    ...
    "Area at First Day of Infection","Area at Last Day of Observation",...
    "Area Integrated Across Time","Max Area Slope to a Point"];

% Get CSV
[CSV_filename,CSV_filepath] = uigetfile('/Volumes/Sutphin server/Users/Luis Espejo/SICKO/Experiments/*.csv',...
    'Select the Compiled csv File');
% Read table
csv_table = readtable(fullfile(CSV_filepath,CSV_filename),'VariableNamingRule','preserve');
% Get condition names
conditions = string(natsort(unique((csv_table.Condition))));
% condition_idx = 1:length(conditions);

% Get SICKO coefficient 
answer = questdlg('Use the SICKO coefficient?', ...
	'SICKO analysis option', ...
	'Yes','No','Cancel','Cancel');

% Handle responses
switch answer
    case 'Yes'
        SICKO_coef_option = 1;
        num_worms_after_pass = inputdlg(cellstr(conditions)',...
            'Number of worms remaining after passing', [1,100]);
        if isempty(num_worms_after_pass)
            error('No data inputted')
        end
        
        num_worms_died_dur_pass = inputdlg(cellstr(conditions)',...
            'Number of worms died during passing', [1,100]);
        if isempty(num_worms_died_dur_pass)
            error('No data inputted')
        end
        
    case 'No'
        SICKO_coef_option = 0;
        num_worms_died_dur_pass = [];
        num_worms_after_pass = [];
    case 'Cancel'
        error('Canceled');
end

% Get names of the csv
csv_names = csv_table.Properties.VariableNames;

% Set up variables
col_intensity = contains(string(csv_names),"Intensity");
col_area = contains(string(csv_names),"Area");
col_censor = contains(string(csv_names),"Censored");
col_dead = contains(string(csv_names),"Dead");
col_defaults = zeros(size(col_dead)); col_defaults(1:3) = 1;

% Isolate tables
table_inten = csv_table(:,logical(col_defaults+col_intensity));
table_area = csv_table(:,logical(col_defaults+col_area));

% Isolate datasets
data_intensity = table2array(csv_table(:,col_intensity));
data_area = table2array(csv_table(:,col_area));
data_censor = table2array(csv_table(:,col_censor));
data_dead = table2array(csv_table(:,col_dead));

clear col_area col_censor col_dead col_defaults col_intensity csv_names

% Initalize datasets
data_sess_died = zeros(length(data_dead),1);
% data_sess_censored = zeros(length(data_dead),1);

% Get all the days that a worm died on
% Effective lifespan

% Step through all data_dead and data_censor
for i = 1:length(data_dead)
    % Find the first time there is a 1 in the dead section
    sess_died = find(data_dead(i,:)>0,1,'first');
    % If it's not empty, make a sess_died
    if ~isempty(sess_died)
        data_sess_died(i) = sess_died;
    end   
end
clear sess_censored sess_died i

% If the worm was not dead then set its day of death to end + 1
data_sess_died_plot = data_sess_died;
data_sess_died_plot(data_sess_died_plot==0) = (size(data_dead,2) + 1);

% Initalize indexing variables for
% Worms that got infected
idx_infected = (mean(data_area,2,'omitnan')>0);

% Worms that only have a single data point that didn't die
% most of the time these worms seem to be noise and throw off the data
% calculations, if you want to include the "singletons" then change idx_yes
% to logical(ones(size(idx_infected)))
idx_only_single_point = (sum(data_area>0,2)==1).*(~(data_sess_died>0));

% we removed worms that didnt die and only had a single point of infection data 
% these seems to be not infected and only noise 
idx_yes = logical(~idx_only_single_point);

% Start with keep everything
idx_2d_data_to_keep = ones(size(data_dead));
% Remove all censored data
idx_2d_data_to_keep(data_censor==1) = NaN;
% Remove all dead data
for i = 1:length(data_sess_died)
    if data_sess_died(i) > 0 
        idx_2d_data_to_keep(i,data_sess_died(i):end) = -1;
    end
end

% this is a backwards fit becuase for some reason there is a lot of NaN
% values in the data_intensity variable, basically replace all the nans
% with ones then multiply out the idx_data to keep to replace 1s with
% censored data (NaNs) and dead data (-1) 
temp_area = data_area;
temp_inten = data_intensity;
% get all the nan values that came with the loaded data
prev_nan_in_area = isnan(temp_area);
prev_nan_in_inten = isnan(temp_inten);
temp_area(isnan(temp_area)) = 0;
temp_inten(isnan(temp_inten)) = 0;

temp_area = temp_area.*idx_2d_data_to_keep;
temp_inten = temp_inten.*idx_2d_data_to_keep;
% d is where both signals are 0 representing a true zero not a over
% corrected signal 
d = ((temp_area.*temp_inten)==0);
temp_inten = temp_inten+1;
temp_area = temp_area+1;
temp_inten(d) = 0;
temp_area(d) = 0;

temp_inten(idx_2d_data_to_keep==-1) = -1;
temp_inten(temp_inten==1) = 0;
non_cen_data_intensity = temp_inten;

temp_area(idx_2d_data_to_keep==-1) = -1;
temp_area(temp_area==1) = 0;
non_cen_data_area = temp_area;

% % % % apply the censored data (NaN) and dead (-1) to data
%%%% this is the old way of doing this and above is the new
% % % non_cen_data_area = data_area.*idx_2d_data_to_keep;
% % % non_cen_data_area(idx_2d_data_to_keep==-1) = -1;
% % % non_cen_data_intensity = data_intensity.*idx_2d_data_to_keep;
% % % non_cen_data_intensity(idx_2d_data_to_keep==-1) = -1;

[~,exp_name,~] = fileparts(CSV_filename);

% this implements the sicko coefficient as a time series 
if SICKO_coef_option
    SICKO_coef_time = compute_SICKO_coef(non_cen_data_area,idx_yes,conditions,csv_table,...
        num_worms_died_dur_pass,num_worms_after_pass,CSV_filepath,exp_name);
else
    SICKO_coef_time = ones(1,size(data_area,2));
end
% output the analyzed data into a csv
data_to_csv(csv_output_header,csv_table,...
    CSV_filename,CSV_filepath,...
    data_intensity,data_area,data_censor,data_dead,...
    data_sess_died,non_cen_data_area,non_cen_data_intensity);
% display the data to the user
display_data(logical(idx_infected.*(~idx_only_single_point)),...
    conditions,csv_table)

% this plots the the heatmap data and then the cumulative data plots
if ~SICKO_coef_option

    disp("No SICKO Coeff used");
    heatmap_data(non_cen_data_area,idx_yes,conditions,csv_table,...
        data_sess_died_plot,'Integrated_Area',CSV_filepath,exp_name,...
        SICKO_coef_option,SICKO_coef_time)
    heatmap_data(non_cen_data_intensity,idx_yes,conditions,csv_table,...
        data_sess_died_plot,'Integrated_Intensity',CSV_filepath,exp_name,...
        SICKO_coef_option,SICKO_coef_time)
    close all
    plot_data(non_cen_data_area,idx_yes,conditions,csv_table,...
        'max','Integrated_Area',1,exp_name,CSV_filepath,SICKO_coef_option,...
        SICKO_coef_time)
    plot_data(non_cen_data_intensity,idx_yes,conditions,csv_table,...
        'max','Integrated_Intensity',1,exp_name,CSV_filepath,SICKO_coef_option,...
        SICKO_coef_time)
    
else 
    temp = SICKO_coef_time; % cache the sicko coefficient
    %Create figures with and without the SICKO coefficient ----- pretty hardcode-y ugh
    for i = 1:2    
        % this is for the second loop to remove the sicko coefficient from
        % the data 
        if SICKO_coef_option == 0
            SICKO_coef_time = ones(1,size(data_area,2));
        end
        % plot the heatmap data with/without sicko coefficient
        heatmap_data(non_cen_data_area,idx_yes,conditions,csv_table,...
            data_sess_died_plot,'Integrated_Area',CSV_filepath,exp_name,...
            SICKO_coef_option,SICKO_coef_time)        
        heatmap_data(non_cen_data_intensity,idx_yes,conditions,csv_table,...
            data_sess_died_plot,'Integrated_Intensity',CSV_filepath,exp_name,...
            SICKO_coef_option,SICKO_coef_time)
        close all
        % plot the data
        plot_data_individual(non_cen_data_area,idx_yes,conditions,csv_table,...
            'max','Integrated_Area',1,exp_name,CSV_filepath,SICKO_coef_option,...
            SICKO_coef_time)
        plot_data_individual(non_cen_data_intensity,idx_yes,conditions,csv_table,...
            'max','Integrated_Intensity',1,exp_name,CSV_filepath,SICKO_coef_option,...
            SICKO_coef_time)
        % Also create figures without SICKO coefficient
        % this is the hardcoded bit 
        SICKO_coef_option = 0; 
    end
    SICKO_coef_option = 1;
    SICKO_coef_time = temp;
end

disp('EOF');
close all






% functions for analysis, plotting, and exportation of data

function SICKO_coef_time = compute_SICKO_coef(this_data,...
    idx_yes,conditions,csv_table,num_worms_died_dur_pass,num_worms_after_pass,...
    CSV_filepath,exp_name)

header = ["Condition","survived_passing","died_in_passing","SICKO_coeff"];

for i = 1:length(conditions)
    
    this_condition_idx = string(csv_table.Condition) == conditions(i);
    
    this_condition_idx = logical(idx_yes.*this_condition_idx);
    % Find the relative condition
    this_conditon = this_data(this_condition_idx,:);
    
    % all dead worms are marked as -1 
    % if the worm died with no infection then its sum across its data will be negative
    num_died_not_infected_observed = sum(sum(this_conditon,2,'omitnan')<0);
    % this finds all the worms that died (-1) then finds if there is 
    % any signal on that data, use an 'and' gate for died and had infection
    % for num that died while infected and observed 
    num_died_infected_observed = sum((sum(this_conditon,2,'omitnan')>0).*(sum(this_conditon == -1,2)>0));
%     num_died_infected_observed = sum(sum(this_conditon,2,'omitnan')>0);
    total_died_during_observation = sum([num_died_not_infected_observed,num_died_infected_observed]); 
    
    % Assuming cond gls130,ku25,n2 for testing
    inital_count = str2double(string(num_worms_after_pass));
    died_during_passing = str2double(string(num_worms_died_dur_pass));
    
    worms_in_this_exp = size(this_conditon,1);
    
    did_not_die_normally = ~(sum(this_conditon,2,'omitnan')<0);
    data_died_infected = this_conditon(did_not_die_normally,:);
    died_over_time_from_infection = sum(data_died_infected==-1);
    
    remaining_after_passing = (inital_count - died_during_passing);
    
    percent_died_to_infection = num_died_infected_observed/total_died_during_observation;
    died_during_passing_to_infection = died_during_passing(i)*percent_died_to_infection;
    
    non_healthy_of_population = (num_died_infected_observed/worms_in_this_exp)...
        *remaining_after_passing(i) + died_during_passing_to_infection;
    non_healthy_of_population_fraction = non_healthy_of_population/(inital_count(i) + died_during_passing);
        
    healthy_factor = 1/sqrt(1-non_healthy_of_population_fraction);
    
    unhealthy_factor = non_healthy_of_population./ ...
        (((non_healthy_of_population - ...
        (died_during_passing_to_infection + died_over_time_from_infection))));
    
    SICKO_coef_time(i,:) = healthy_factor*unhealthy_factor;
end

SICKO_coef_time_cell = cell(length(conditions),1);
for i = 1:length(conditions)
    SICKO_coef_time_cell{i} = SICKO_coef_time(i,:);
end

to_csv_cells = [cellstr(conditions),num_worms_after_pass,...
    num_worms_died_dur_pass,SICKO_coef_time_cell];

T = cell2table(to_csv_cells,'VariableNames',header);

writetable(T,fullfile(CSV_filepath,[exp_name '_SICKO.csv']))
    
end


function heatmap_data(this_data,idx_yes,conditions,csv_table,data_sess_died,title_ext,CSV_filepath,exp_name,...
    SICKO_coef_option,SICKO_coef_time)

overall_max = max(max(this_data(idx_yes,:)));

for i = 1:length(conditions)
    % this is all to find the overall max if the sicko coeff is used
    this_condition_idx = string(csv_table.Condition) == conditions(i);
    this_condition_idx = logical(idx_yes.*this_condition_idx);
    this_conditions_data = this_data(this_condition_idx,:);
    if SICKO_coef_option
        temp = this_conditions_data.*SICKO_coef_time(i,:);
        temp(temp<0) = -1;
        this_conditions_data = temp;
        if max(this_conditions_data(:)) > overall_max
            overall_max = max(this_conditions_data(:));
        end
    end
end

g = figure('units','normalized','outerposition',[0 0 1 1]);

for i = 1:length(conditions)
    
    subplot(1,length(conditions),i)
    
    % find the index that represents this condition
    this_condition_idx = string(csv_table.Condition) == conditions(i);
    this_condition_idx = logical(idx_yes.*this_condition_idx);
    % isolate its data
    this_conditions_data = this_data(this_condition_idx,:);
    this_conditions_death = data_sess_died(this_condition_idx);
    % integrate across time for sorting
    data_across_time_integrated = sum(...
        (this_conditions_data.*(this_conditions_data>0))...
        ,2,'omitnan');
    % invert the data
    data_across_time_integrated_inverted = 1-...
        (data_across_time_integrated/max(data_across_time_integrated(:)));
    % find if infected at all
    data_is_infected_bool = ~(data_across_time_integrated>0);
    % find number of censored points
    censor_across_time_integrated = sum(~isnan(this_conditions_data),2);
    % invert the censor
    censor_across_time_integrated_inverted = 1-...
        (censor_across_time_integrated/max(censor_across_time_integrated(:)));
    % combine first the death then integrated datats into a single martrix
    combined_data_for_sorting = [data_is_infected_bool,...
        this_conditions_death,...
        data_across_time_integrated_inverted,...
        censor_across_time_integrated_inverted];
    % first sort by day of death then sort by integrated data across time
    % categorically
    [~,sort_idx] = sortrows(combined_data_for_sorting,[1,2,3,4]);
    % get the final data representation
    this_conditions_data = this_conditions_data(sort_idx,:);

    % if using SICKO coefficient
    if SICKO_coef_option
        temp = this_conditions_data.*SICKO_coef_time(i,:);
        temp(temp<0) = -1;
        this_conditions_data = temp;
    end

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
    % Find the seperation between infected and not
    infection_seperation_idx = find(data_is_infected_bool(sort_idx)==1,1,'first');
    % add a white line that seperates the infected from the not infected
    if ~isempty(infection_seperation_idx)
        white_line = 255*ones(1,size(temp_img,2),3);
        temp_img2 = [temp_img(1:infection_seperation_idx-1,:,:);...
            white_line;...
            temp_img(infection_seperation_idx:end,:,:)];
    else
        temp_img2 = temp_img;
    end
    
    % final export of the images 
    num_dead = length(unique(row_death));
    num_worms = sum(this_condition_idx);
    num_infected = sum(data_across_time_integrated>0);
    % make the heatmap larger
    temp_img2 = imresize(temp_img2,[1000,1000],'nearest');
    imshow(temp_img2);
    xlabel('sessions');
    ylabel(["individual animals", ...
        string([num2str(num_dead) '/' num2str(num_worms) ' dead']), ...
        string([num2str(num_infected) '/' num2str(num_worms) ' infected'])]);
    title([char(conditions(i)) '_' char(title_ext)],'interpreter','none');
    
    
end
% add a title that has or doesnt the sicko option
if SICKO_coef_option
    out_name = strrep(['heatmap_' exp_name '_' title_ext '_wSICKO_Coeff.pdf'],' ','_');
else
    out_name = strrep(['heatmap_' exp_name '_' title_ext '.pdf'],' ','_');
end

saveas(g,fullfile(CSV_filepath,out_name))

end


function display_data(idx_yes,conditions,csv_table)

for i = 1:length(conditions)
    
    disp(char(conditions(i)))
    
    this_condition_idx = string(csv_table.Condition) == conditions(i);
    this_condition_num = sum(string(csv_table.Condition) == conditions(i));
    
    this_condition_idx = logical(idx_yes.*this_condition_idx);
    
    disp([num2str(sum(this_condition_idx)) '/' num2str(this_condition_num) ' Infected Worms'])
        
end

end



function data_to_csv(csv_output_header,csv_table,...
    CSV_filename,CSV_filepath,...
    data_intensity,data_area,data_censor,data_dead,...
    data_sess_died,non_cen_data_area,non_cen_data_intensity)

% get names of the csv

csv_names = csv_table.Properties.VariableNames;

% get first three headers 
col_biorep = contains(string(csv_names),"Biological Replicate");
col_condition = contains(string(csv_names),"Condition");
col_location = contains(string(csv_names),"ID (well location)");

% get all the data as a cell array
data_cells = table2cell(csv_table);

% get the bioreps 
bioreps = data_cells(:,col_biorep);
conditions = data_cells(:,col_condition);
locations = data_cells(:,col_location);

% inialize the data 
intensity_integrated_across_time = zeros(size(data_sess_died));
intensity_max_gradient_at_point = zeros(size(data_sess_died));
first_sess_of_infection_intensity = nan(size(data_sess_died));
last_sess_of_infection_intensity = nan(size(data_sess_died));

area_integrated_across_time = zeros(size(data_sess_died));
area_max_gradient_at_point = zeros(size(data_sess_died));
first_sess_of_infection_area = nan(size(data_sess_died));
last_sess_of_infection_area = nan(size(data_sess_died));

final_data_censor = zeros(size(data_sess_died));
last_day_of_observation = nan(size(data_sess_died));
first_sess_nonzero_data = nan(size(data_sess_died));


%iterate through each animal
for i = 1:length(data_sess_died)
    % find the data for intesity or area doesnt really matter for this
    % animal in the data
    this_data_inten = non_cen_data_intensity(i,:);
    this_data_area = non_cen_data_area(i,:);
    this_data_censor = data_dead(i,:);
    this_data_censor(isnan(this_data_censor)) = 1;
    
    % try to find the first session that it was infected
    this_first_sess_idx = find((this_data_inten>0) == 1, 1, 'first');
    % if there is a death detected find the last day of observation 
    % that would be the day of death -1
    this_last_sess_idx = data_sess_died(i) - 1;
    % if the value of death day is negative then it is still alive and then
    % so the length of the experiment is the last observed day
    this_last_sess_idx(this_last_sess_idx<0) = size(data_area,2);
    
    if isequal(this_last_sess_idx,size(data_area,2))
        this_last_sess_idx = find(~logical(this_data_censor),1,'last');
        
        if isempty(this_last_sess_idx)
            this_last_sess_idx = NaN;
        end
    end
    
    % if there is a session with nonzeros isolate the specifc data 
    % then compile all the data into specific variables
    if ~isempty(this_first_sess_idx) && ~isnan(this_last_sess_idx)
        first_sess_nonzero_data(i) = this_first_sess_idx;
        
        first_sess_of_infection_intensity(i) = data_intensity(i,this_first_sess_idx);
        last_sess_of_infection_intensity(i) = data_intensity(i,this_last_sess_idx);
        
        first_sess_of_infection_area(i) = data_area(i,this_first_sess_idx);
        last_sess_of_infection_area(i) = data_area(i,this_last_sess_idx);
        
        intensity_integrated_across_time(i) = sum(this_data_inten,'omitnan');
        area_integrated_across_time(i) = sum(this_data_area,'omitnan');
        
        intensity_max_gradient_at_point(i) = max(gradient(this_data_inten));
        area_max_gradient_at_point(i) = max(gradient(this_data_area));
        
    end

    last_day_of_observation(i) = this_last_sess_idx;
    % get the censors and add if the final point is censored
    if isnan(data_censor(i,end))
        cen_idx = find(~isnan(data_censor(i,:)) == 1,1,'last');
        final_data_censor(i) = data_censor(i,cen_idx);
    else
        final_data_censor(i) = data_censor(i,end);
    end
    
end

final_array = cell(size(data_area,1),length(csv_output_header));
% populate the final array
for i = 1:size(data_area,1)
    
    final_array{i,1} = bioreps{i};
    final_array{i,2} = conditions{i};
    final_array{i,3} = locations{i};
    
    final_array{i,4} = logical(data_sess_died(i));
    final_array{i,5} = logical(final_data_censor(i));
    final_array{i,6} = last_day_of_observation(i);
    final_array{i,7} = first_sess_nonzero_data(i);
    
    final_array{i,8}  = first_sess_of_infection_intensity(i);    
    final_array{i,9}  = last_sess_of_infection_intensity(i);  
    final_array{i,10} = intensity_integrated_across_time(i);  
    final_array{i,11} = intensity_max_gradient_at_point(i); 
    
    final_array{i,12} = first_sess_of_infection_area(i);    
    final_array{i,13} = last_sess_of_infection_area(i);  
    final_array{i,14} = area_integrated_across_time(i);  
    final_array{i,15} = area_max_gradient_at_point(i); 
    
end
% final name and path outputs
[~,out_name,~] = fileparts(char(CSV_filename));
output_name = [char(out_name) '_analyzed.csv'];
output_path = fullfile(CSV_filepath,output_name);
disp(output_path);
T = cell2table(final_array,'VariableNames',csv_output_header);

Area_data = non_cen_data_area;
T2 = array2table(Area_data);

Intensity_data = non_cen_data_intensity;
T3 = array2table(Intensity_data);

T4 = [T,T2,T3];

writetable(T4,output_path);

end




function plot_data(this_data,idx_yes,conditions,csv_table,ylim_mode,title_ext,sum_plot,exp_name,CSV_filepath,...
    SICKO_coef_option,SICKO_coef_time)

g = figure('units','normalized','outerposition',[0 0 1 1]);
title(exp_name,'Interpreter','None');

overall_max = max(max(this_data(idx_yes,:)));

if ~sum_plot
    
    x = 1:size(this_data,2);
    for i = 1:length(conditions)
        
        subplot(ceil(length(conditions)/2),2,i)
        
        title([conditions(i) '_' title_ext],'interpreter','none');
        hold on
        
        this_condition_idx = string(csv_table.Condition) == conditions(i);
        
        this_condition_idx = logical(idx_yes.*this_condition_idx);
        
        this_conditon = this_data(this_condition_idx,:);
        
        if isequal(ylim_mode,'max')
            ylim([0,overall_max])
        elseif isequal(ylim_mode,'auto')
            ylim([0,max(this_conditon(:))])
        end
        
        for j = 1:size(this_conditon,1) + 1
            
            if isequal(j,size(this_conditon,1) + 1)
                
                this_conditon2 = this_conditon;
                this_conditon2(this_conditon2==0) = NaN;
                
                for k = 1:size(this_conditon2,1)
                    this_conditon_temp = this_conditon2(k,:);
                    
                    this_conditon_temp(this_conditon_temp<0) = max(this_conditon_temp(:));
                    
                    this_conditon2(k,:) = this_conditon_temp;
                end
                this_worm = mean(this_conditon2,1,'omitnan');
                plot(x,this_worm,'LineWidth',4,'Color','k')
                
            else
                this_worm = this_conditon(j,:);
                plot(x,this_worm);
            end
        end
        hold off
        
    end
    
    output_name = [exp_name '_' title_ext '_' ylim_mode '.pdf'];
    
else
    
    if SICKO_coef_option
        title([exp_name '-' title_ext 'wSICKO - cumulative sum of the daily integral of the data'],'Interpreter','None')
    else
        title([exp_name '-' title_ext ' - cumulative sum of the daily integral of the data'],'Interpreter','None')
    end
    
    x = 1:size(this_data,2);
    for i = 1:length(conditions)
                
        hold on
        
        this_condition_idx = string(csv_table.Condition) == conditions(i);
        
        this_condition_idx = logical(idx_yes.*this_condition_idx);
        % find the relative condition 
        this_conditon = this_data(this_condition_idx,:);
        
        % replace death points with NaNs
        this_conditon2 = this_conditon;
        this_conditon2(this_conditon2<0) = NaN;
        this_worm = cumsum(sum(this_conditon2,1,'omitnan'),'omitnan');
        
        if SICKO_coef_option
            this_worm = this_worm.*SICKO_coef_time(i,:);
            worm_temp(i,:) = this_worm;
            
            if i == length(conditions)
                ylim([0,max(worm_temp(:))])
            end
        else
            worm_temp(i,:) = this_worm;
            
            if i == length(conditions)
                ylim([0,max(worm_temp(:))])
            end
        end
        
        l(i) = plot(x,this_worm,'LineWidth',4,'DisplayName',char(conditions(i)));
    end
    
    legend(l,'location','north','orientation','horizontal','Interpreter','None')
    
    hold off

    if SICKO_coef_option
        output_name = [exp_name '_' title_ext '_' ylim_mode '_wSICKO_Coeff.pdf'];
    else
        output_name = [exp_name '_' title_ext '_' ylim_mode '.pdf'];
    end
end

saveas(g,fullfile(CSV_filepath,output_name));

if sum_plot
    header = ["Condition",string(title_ext)];
    % this is for csv expoting 
    data_output = cell(length(conditions),1);
    for i = 1:length(conditions)
        data_output{i} = worm_temp(i,:);
    end

    to_csv_cells = [cellstr(conditions),data_output];

    T = cell2table(to_csv_cells,'VariableNames',header);

    writetable(T,fullfile(CSV_filepath,[exp_name '_SICKO_' title_ext '.csv']))
end

end


function plot_data_individual(this_data,idx_yes,conditions,csv_table,ylim_mode,title_ext,sum_plot,exp_name,CSV_filepath,...
    SICKO_coef_option,SICKO_coef_time)

g = figure();

if sum_plot
    
    if SICKO_coef_option
        title({[exp_name '-' title_ext] ,' wSICKO - mean of the cumulative sum of the daily integral of the data',''},'Interpreter','None')
    else
        title({[exp_name '-' title_ext] ,' - mean of the cumulative sum of the daily integral of the data',''},'Interpreter','None')
    end

    colors = ["r-","b-","g-","r--","b--","g--","r.","b.","g."];
    
    x = 1:size(this_data,2);
    for i = 1:length(conditions)
                
        hold on
        
        this_condition_idx = string(csv_table.Condition) == conditions(i);
        
        this_condition_idx = logical(idx_yes.*this_condition_idx);
        % find the relative condition 
        this_conditon = this_data(this_condition_idx,:);
        
        % replace death points with NaNs
        this_conditon2 = this_conditon;
        this_conditon2(this_conditon2<0) = NaN;
        
        if SICKO_coef_option
            each_worm = this_conditon2.*SICKO_coef_time(i,:);
            each_worm_cumsum = cumsum(each_worm,2,'omitnan');
        else
            each_worm = this_conditon2;
            each_worm_cumsum = cumsum(each_worm,2,'omitnan');
        end

        mean_line = mean(each_worm_cumsum,1,'omitnan');
        % standard error of the mean
        std_error = std(each_worm_cumsum,1)/sqrt(size(each_worm,1));
        
        l(i) = plot(x,mean_line,colors(i),'LineWidth',4,'DisplayName',char(conditions(i)));
        h(i) = errorbar(x,mean_line,std_error,colors(i),'LineWidth',1,'DisplayName',char(conditions(i)));
    end
    
    legend(l,'location','north','orientation','horizontal','Interpreter','None')
    
    hold off

    if SICKO_coef_option
        output_name = [exp_name '_' title_ext '_' ylim_mode '_wSICKO_Coeff.pdf'];
    else
        output_name = [exp_name '_' title_ext '_' ylim_mode '.pdf'];
    end
end

saveas(g,fullfile(CSV_filepath,output_name));

end




