clear all
clc

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

% initalize indexing variables for
% worms that got infected
idx_infected = (mean(data_area,2,'omitnan')>0);
% that are NOT censored
idx_good_wells = (data_sess_censored==0);
% that are not dead
idx_not_dead = (data_sess_died==0);
% worms that only have a single data point that didnt die
idx_only_single_point = (sum(data_area>0,2)==1).*(~(data_sess_died>0));

idx_yes = logical(idx_infected.*(~idx_only_single_point));

% start with keep everything
idx_2d_data_to_keep = ones(size(data_dead));
% remove all censored data
idx_2d_data_to_keep(data_censor==1) = NaN;
% remove all dead data
for i = 1:length(data_sess_died)
    if data_sess_died(i) > 0 
        idx_2d_data_to_keep(i,data_sess_died(i):end) = NaN;
    end
end

non_cen_data_area = data_area.*idx_2d_data_to_keep;
non_cen_data_intensity = data_intensity.*idx_2d_data_to_keep;

display_data(non_cen_data_area,idx_yes,conditions,csv_table,data_censor,'Integrated_Area')

plot_data(non_cen_data_area,idx_yes,conditions,csv_table,'auto','Integrated_Area')
plot_data(non_cen_data_area,idx_yes,conditions,csv_table,'max','Integrated_Area')

plot_data(non_cen_data_intensity,idx_yes,conditions,csv_table,'auto','Integrated_Intensity')
plot_data(non_cen_data_intensity,idx_yes,conditions,csv_table,'max','Integrated_Intensity')



function plot_data(this_data,idx_yes,conditions,csv_table,ylim_mode,title_ext)

figure;

overall_max = max(max(this_data(idx_yes,:)));

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
            
            this_worm = mean(this_conditon2,1,'omitnan');
            
            plot(x,this_worm,'LineWidth',4,'Color','k')
            
        else
            this_worm = this_conditon(j,:);
            
            plot(x,this_worm);
        end
        
    end
    
    hold off
    
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