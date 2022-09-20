clear all
curr_path = pwd;

% WORM_TO_ISOLATE
worm_condition = 'SU10_EV';
worm_location = '2g';
img_thresh = 150;

data_path = fullfile('/Volumes/Sutphin server/Users/Luis Espejo/SICKO/Experiments/');

overarching_folder = 'Y:\Users\Luis Espejo\SICKO\Experiments\Test Dual Validation - Copy';
overarching_folder = '/Volumes/Sutphin server/Users/Luis Espejo/Terasaki Validation SU10';

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
    inner_dir(ismember( {inner_dir.name}, {'.', '..','Settings', 'settings'})) = [];  %remove . and ..
    
    condition = strings(length(inner_dir),1);
    inner_session_names = strings(length(inner_dir),1);
    disp('Found experiments:')
    for i = 1:length(inner_dir)
        condition(i) = inner_dir(i).name;
        disp(condition(i))
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
    for i = 1:length(condition)
        for j = 1:num_sessions_per_exp(i)
            condition2(k) = condition(i);
            k=k+1;
        end
    end
    condition = condition2;
    clear condition2
    
    % mainFolder = uigetdir();    % Selectyour Main folder
    if ispc
        [~,message,~] = fileattrib([fullfile(ovr_dir(n).folder,ovr_dir(n).name),'\*']);
    else
        [~,message,~] = fileattrib([fullfile(ovr_dir(n).folder,ovr_dir(n).name),'/*']);
    end
    
    fprintf('\nThere are %i total files & folders in the overarching folder.\n',numel(message));
    
    allExts = cellfun(@(s) s(end-2:end), {message.Name},'uni',0); % Get exts
    
    TIFidx = ismember(allExts,'tif');    % Search ext for "CSV" at the end
    TIF_filepaths = {message(TIFidx).Name};  % Use CSVidx to list all paths.
    
    [~,TIF_names,~] = fileparts(TIF_filepaths); %not including GUI files in final CSV
    CSV_flag = ones(1,length(TIF_names));
    
    TIF_filepaths = TIF_filepaths(CSV_flag == 1);
    
    fprintf('There are %i files with *.TIF exts.\n',numel(TIF_filepaths));
    
    single_worm_idx = contains(string(TIF_filepaths),worm_location).*contains(string(TIF_filepaths),worm_condition);
    
    fprintf('There are %i files for this single worm.\n',sum(single_worm_idx));
    
    single_worm_filepaths = TIF_filepaths(logical(single_worm_idx))';
    
    se = strel('disk',3);

    for i = 1:length(single_worm_filepaths)
        temp = single_worm_filepaths{i};
        temp2{i} = temp(find(temp=='D',1,'last')+1:find(temp=='/',1,'last')-1);
    end
    [days_to_sort,ndx,dbg] = natsort(temp2');
    days_to_sort = str2double(string(days_to_sort));
    clear temp2
    single_worm_filepaths = single_worm_filepaths(ndx);
    
    count = 1;
    imgs = cell(1,length(single_worm_filepaths)/3);
    for i = 1:3:length(single_worm_filepaths)
        disp(i)
        imgs{count} = double(imread(single_worm_filepaths{i}));
        masks{count} = bwareafilt(imclose(bwareaopen(imgs{count}>img_thresh,10,4),se),1);
        count = count + 1;
    end
    
    unique_days_to_sort = sort(unique(days_to_sort),'ascend');
    overall_max = 0;
    for i = 1:length(imgs)
        if overall_max < max(imgs{i}(:))
            overall_max = max(imgs{i}(:));
        end
    end

    overall_max = 750;

    for i = 1:length(imgs)
        temp_img = imgs{i}/overall_max;
        imgs2{i} = insertText(temp_img,[1,1],...
            ['Day ' num2str(unique_days_to_sort(i))],'FontSize', 100);
    end
        
    tiled_img = imtile(imgs2);
    tiled_mask = imtile(masks);
%     
%     out1 = imfuse(tiled_img,tiled_mask);    
%     imshow(out1)
%     
%     d = 250;
%     for i = 1:length(imgs)
%         s = regionprops(masks{i},'Centroid');
%         cent{i} = round([s.Centroid(2),s.Centroid(1)]);
%         
%         cropx = [cent{i}(1)-d,cent{i}(1)+d];
%         cropy = [cent{i}(2)-d,cent{i}(2)+d];
%         
%         if any(cropy < 0)
%             cropy = cropy - min(cropy) + 1;
%         end
%         if any(cropx < 0)
%             cropx = cropx - min(cropx) + 1;
%         end
%         
%         img_size = size(masks{1},1);
%         if any(cropy > img_size)
%             cropy = cropy - (max(cropy)-img_size);
%         end
%         if any(cropx > img_size)
%             cropx = cropx - (max(cropx)-img_size);
%         end
%         
%         imgs3{i} = imgs{i}(cropx(1) : cropx(2),cropy(1) : cropy(2)); 
%         masks2{i} = masks{i}(cropx(1) : cropx(2),cropy(1) : cropy(2)); 
%     end
%     
%     first_mean = mean2(imgs3{1});
%     imgs3{1} = insertText(imgs3{1}/max(imgs3{1}(:)),[100,100],['Day ' num2str(1)],'FontSize', 48);
%     for i = 2:length(imgs)
%         scaler = mean2(imgs3{i})/first_mean;
%         imgs3{i} = imgs3{i}/scaler;
%         imgs3{i} = insertText(imgs3{i}/max(imgs3{i}(:)),[100,100],['Day ' num2str(i)],'FontSize', 48);
%         disp(mean2(imgs3{i}))
%     end
%     
%     
%     tiled_img = imtile(imgs3,'GridSize',[2,3]);
%     tiled_mask = imtile(masks2,'GridSize',[2,3]);
    
    figure;
    out2 = imfuse(tiled_img,tiled_mask/2,'Scaling','joint');    
    imshow(out2)
    
    imwrite(out2,'out2.png')
%     imwrite(out2,'out2.png')
    
end

% mkdir(fullfile(final_save_path,[final_save_name '_outputs']));
% 
% try
%     T = cell2table(final_csv,'VariableNames',csv_header);
%     writetable(T,fullfile(final_save_path,[final_save_name '_outputs'],[final_save_name '.csv']))
%     
%     disp('Data saved to:')
%     disp(fullfile(final_save_path,[final_save_name '_outputs']))
% catch
%     disp('CSV probably open, saving to _1')
%     T = cell2table(final_csv,'VariableNames',csv_header);
%     writetable(T,fullfile(data_path,[final_save_name '_1.csv']))
% end



