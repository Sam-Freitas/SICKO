clear all
close all

%Vanessa Silbar
%May 24, 2021
%find specific threshold for groups (control, op50, etc)
%read all imgs into cell array
%use imtile() to append all arrays, 95% (2 std) is consistent

% image threshold
% 130 for RFP
% 750 for GFP
% img_thresh = 130;

curr_path = pwd;

data_path = fullfile(erase(curr_path,'scripts'),'data');

img_dir_path = uigetdir(data_path);

img_paths = dir(fullfile(img_dir_path, '*.tif'));
[~,sort_idx,~] = natsort({img_paths.name});

img_paths = img_paths(sort_idx);

image_means = zeros(1,length(img_paths));
image_stds = zeros(1,length(img_paths));
image_thresholds = zeros(1,length(img_paths));
image_data = cell(1,length(img_paths));

%finds the threshold of each image + 2 standard deviations (95% normal distribution)
for i = 1:length(img_paths) 
    
   this_img_path = fullfile(img_dir_path,img_paths(i).name);
    
   this_img = imread(this_img_path);
   
   image_data{i} = this_img;
    
   image_means(i) = mean2(this_img);
   image_stds(i) = std2(this_img);
   image_thresholds(i) = image_stds(i)*2 + image_means(i);  
   
end

%across all images 
max_threshold = max(image_thresholds);
mean_threshold = mean(image_thresholds);
median_threshold = median(image_thresholds);

histogram(image_thresholds);

%iterates through all images and keeps data larger than defined threshold
for i = 1:length(img_paths)
    %max_threshold can be changed to any variable/value decided
    image_data{i} = image_data{i} > max_threshold; 
    
end

%imtile appends all images together
%use image_data(1:10) to see the first 10 images or any set you choose
imshow(imtile(image_data)) 
