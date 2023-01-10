% this script isolates a single (or multiple worms on the same repeat) worms to plot the images as a tiled sequence for easy viewing

% you MUST change 
% worm condition (must be exact match to the folder that its stored in -- capitalization matters)
% worm location (capitalization matters) - can enter multiple if on same repeat
% biological repeat - bio_repeat just give it a number 
% image threhold - I use 3x the threshold from the analysis portion
% overarching folder - the place where the images (not the analyzed csvs) are stored

clear all
curr_path = pwd;

% WORM_TO_ISOLATE
worm_condition =  "N2"; %"KU25";
worm_location =  ["6b"]%,"11c"]; %["2b"]; %
bio_repeat = 1;
img_thresh = 3500*3;

% overarching_folder = 'Y:\Users\Luis Espejo\SICKO\Experiments\Test Dual Validation - Copy';
overarching_folder = 'Y:\Users\Luis Espejo\SICKO\Experiments\N2_KU25_GOP50 - Copy';
% overarching_folder = '/Volumes/Sutphin server/Users/Luis Espejo/Terasaki Validation SU10';

[final_save_path,final_save_name,~] = fileparts(overarching_folder);

ovr_dir = dir(overarching_folder);
dirFlags = [ovr_dir.isdir];
ovr_dir = ovr_dir(dirFlags);
ovr_dir(ismember( {ovr_dir.name}, {'.', '..'})) = [];  %remove . and ..

biorep_names = strings(length(ovr_dir),1);

disp('found repeats:')
for i = 1:length(ovr_dir)
    biorep_names(i) = ovr_dir(i).name;
    disp(biorep_names(i))
end

row_index_count = 1;
r = row_index_count;

for n = 1:length(ovr_dir)

    if sum(bio_repeat==n) 

        % mainFolder = uigetdir();    % Selectyour Main folder
        disp('Reading all file attributes (might take a while)')
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

        for j = 1:length(worm_location)

            this_worm_location = char(worm_location(j));

            this_worm_condition = char(worm_condition);

            disp([this_worm_condition ' -- ' this_worm_location ' -- ' char(biorep_names(n))])
            
            if ispc
                single_worm_idx = contains(string(TIF_filepaths),['\' this_worm_location]).*...
                    contains(string(TIF_filepaths),['\' this_worm_condition '\']);
            else
                single_worm_idx = contains(string(TIF_filepaths),['/' this_worm_location]).*...
                    contains(string(TIF_filepaths),['/' this_worm_condition '/']);
            end

            fprintf('There are %i files for this single worm.\n',sum(single_worm_idx));

            single_worm_filepaths = TIF_filepaths(logical(single_worm_idx))';

            se = strel('disk',3);
            clear temp2
            if ispc
                for i = 1:length(single_worm_filepaths)
                    temp = single_worm_filepaths{i};
                    temp2{i} = temp(find(temp=='D',1,'last')+1:find(temp=='\',1,'last')-1);
                end
            else
                for i = 1:length(single_worm_filepaths)
                    temp = single_worm_filepaths{i};
                    temp2{i} = temp(find(temp=='D',1,'last')+1:find(temp=='/',1,'last')-1);
                end
            end
            [days_to_sort,ndx,dbg] = natsort(temp2');
            days_to_sort = str2double(string(days_to_sort));

            single_worm_filepaths = single_worm_filepaths(ndx);

            count = 1;
            imgs = cell(1,length(single_worm_filepaths)/3);
            masks = cell(1,length(single_worm_filepaths)/3);
            disp('Reading in images')
            for i = 1:3:length(single_worm_filepaths)
                imgs{count} = double(imread(single_worm_filepaths{i}));
                count = count + 1;
            end

            unique_days_to_sort = sort(unique(days_to_sort),'ascend');

            imgs2 = cell(size(imgs));
            for i = 1:length(imgs)
                temp_img = imgs{i}/img_thresh;
                imgs2{i} = insertText(temp_img,[1,1],...
                    ['Day ' num2str(unique_days_to_sort(i))],'FontSize', 100);
            end

            tiled_img = imtile(imgs2);
            file_name = [this_worm_condition '_' this_worm_location '_out2.jpg'];

            imwrite(tiled_img,file_name)
            disp(file_name)
            disp(' ')
        end
    end
    %     imwrite(out2,'out2.png')

end

% mkdir(fullfile(final_save_path,[final_save_name '_outputs']));
%  data_path = fullfile('/Volumes/Sutphin server/Users/Luis Espejo/SICKO/Experiments/');
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


