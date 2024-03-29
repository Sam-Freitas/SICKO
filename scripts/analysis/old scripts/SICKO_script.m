clear all
close all

% number of images in the replicate
number_imgs_in_replicate = 3;

% image threshold
% 130 for RFP
% 750 for GFP
img_thresh = 2100;

% if you know 110% sure that there is ZERO contamination
% usually for testing only
% keep at 0
zero_contamination = 1;

% delete all .csv's in each session folder and start again
overwrite_csv = 1;

% Georges border subtraction for session to session fix
use_border_subtraction = 1;

curr_path = pwd;

data_path = fullfile(erase(curr_path,'scripts'),'data');
luis_path_mac = '/Volumes/Sutphin server/Users/Luis Espejo/SICKO/Experiments';

if isfolder(luis_path_mac)
    img_dir_path = uigetdir(luis_path_mac);
else
    img_dir_path = uigetdir(data_path);
end

if overwrite_csv
    csv_paths = dir(fullfile(img_dir_path,'*.csv'));
    
    for i = 1:length(csv_paths)
        delete(fullfile(csv_paths(i).folder,csv_paths(i).name));
    end
    
    if ~isempty(csv_paths)
        disp('Deleted old .csv files');
    else
        disp('No .csv to overwrite, starting from scratch');
    end
end

img_paths = dir(fullfile(img_dir_path, '*.tif'));
[~,sort_idx,~] = natsort({img_paths.name});

img_paths = img_paths(sort_idx);

check_replicate = length(img_paths)/number_imgs_in_replicate;

disp(['Processing data for: ' img_dir_path])

if check_replicate == floor(check_replicate)
    disp('All images in replicate')
else
    error('Not all images in replicate')
end

se = strel('disk',3);
writematrix(string({img_paths.name}),fullfile(img_dir_path,'image_names.csv'));

figure('units','normalized','outerposition',[0 0 1 1])

image_integral_intensities = zeros(1,length(img_paths));
image_integral_areas = zeros(1,length(img_paths));
dead = zeros(1,length(img_paths));
censored = zeros(1,length(img_paths));

img_counter = 1;
for i = 1:length(img_paths)
    
    this_img_path = fullfile(img_dir_path,img_paths(i).name);
    
    this_img = imread(this_img_path);
    
    data = this_img;
    
    mask = imclose(bwareaopen(data>img_thresh,10,4),se);
    
%     T = mean2(this_img)+3*std2(this_img);
%     mask2 = bwareaopen(bwareaopen(data>T,10,4)-bwperim(imfill(mask,'holes')),10,4);
%     mask2 = imgaussfilt(double(mask2),1.2)>0;
    
    masked_data = mask.*double(data); % this converts the picture array to mathable stuff 
    
    if img_counter < 2
        
        if ~zero_contamination
            figure('units','normalized','outerposition',[0 0 1 1])
            
            subplot(1,2,1)
            Ifill = imfill(imgaussfilt(masked_data,10)>0,'holes');
            B = bwboundaries(Ifill);
            stat = regionprops(Ifill,'Centroid');
            imshow(masked_data); hold on
            title([char(img_paths(i).name) ' perimeter image'])
            for k = 1 : length(B)
                b = B{k};
                c = stat(k).Centroid;
                plot(b(:,2),b(:,1),'g','linewidth',2);
                %             text(c(1),c(2),num2str(k),'backgroundcolor','g');
            end
            
            
            subplot(1,2,2)
            imshow(this_img,[])
        end
        
%         imshowpair(masked_data,this_img,'montage')
        title(string([img_paths(i).name ' --- ' 'img:' num2str(i)]))
        drawnow;
        
        if ~zero_contamination
            dlg_choice = questdlg({'Does this image have any contamination in it?',...
                'If so draw rectange around the worm and double click it'},'Redo?','Yes','No', 'Dead or Censored','No');
        else
            dlg_choice = 'No';
        end
        
        if isequal(dlg_choice,'Dead or Censored')
            dlg_choice2 = questdlg({'Is the worm dead or need to be censored?',...
                ''},'Dead or Censored','Dead','Censored','Nevermind', 'Nevermind');
        else 
            dlg_choice2 = [];
        end
      
        if isequal(dlg_choice2, 'Dead')
            dead(i:i+2) = 1;
        end
        
        if isequal(dlg_choice2, 'Censored')
            censored(i:i+2) = 1;
        end 
        
        if isequal(dlg_choice2,'Dead')
            dlg_choice3 = questdlg({'Do you need to crop for contamination?',...
                ''},'Crop', 'Yes', 'No', 'No');
            if isequal(dlg_choice3,'Yes')
                dlg_choice = 'Yes';
            else 
                dlg_choice3 = [];
            end
        else
           dlg_choice3 = [];
        end
          
        rect = [1 1 size(this_img)];
        if isequal(dlg_choice,'Yes')
            
            [~,rect] = imcrop(masked_data);
            close all
            rect = round(rect);
            
        end
        img_counter = img_counter+1;
        cropped_data = masked_data(rect(2):(rect(2)+rect(4)-1),rect(1):(rect(1)+rect(3)-1));
    else
        cropped_data = masked_data(rect(2):(rect(2)+rect(4)-1),rect(1):(rect(1)+rect(3)-1));
        img_counter = img_counter+1;
        
        if img_counter > 3
            img_counter=1;
        end
    end
    
    if ~zero_contamination
        close all
    end
    
    if use_border_subtraction
        % get the cropped data of the raw values
        cropped_data_raw = double(data(rect(2):(rect(2)+rect(4)-1),rect(1):(rect(1)+rect(3)-1)));
        cropped_data_mask = cropped_data>0;
        % use the inital mask and thicken it 25x then subtract the inital
        % mask off and create a mask from that, should be only thick borders 
        border_mask = (bwmorph(cropped_data_mask,'thicken',25)-cropped_data_mask)>0;
        % get all the pixels from the border mask (vector)
        border_pixels = nonzeros(border_mask.*cropped_data_raw);
        % get mean of said pixels
        mean_of_border_pixels_to_subtract = mean2(border_pixels);
        % subtract the mean off and round all negative values to zero
        cropped_data_norm = cropped_data - mean_of_border_pixels_to_subtract;
        cropped_data_norm(cropped_data_norm<0) = 0;
        % integrate across the masks
        image_integral_intensities(i) = sum(cropped_data_norm(:));
        image_integral_areas(i) = sum(cropped_data_norm(:)>0);
        
    else
        image_integral_intensities(i) = sum(cropped_data(:));
        image_integral_areas(i) = sum(cropped_data(:)>0);
    end
    
%     linear_data = nonzeros(masked_data);
%         
%     [counts,binLoc] = hist(linear_data,255); 
%     stem(binLoc,counts)
        
end
close all


if ~(isempty(img_paths))
    writematrix(image_integral_intensities,fullfile(img_dir_path,'image_integral_intensities.csv'));
    writematrix(image_integral_areas,fullfile(img_dir_path,'image_integral_areas.csv'));
    writematrix(dead,fullfile(img_dir_path,'dead.csv'));
    writematrix(censored,fullfile(img_dir_path,'censored.csv'));
else
    disp('No images were detected, please select the correct folder')
end
