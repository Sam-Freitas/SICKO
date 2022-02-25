clear all 
close all 

% number of images in the replicate
number_imgs_in_replicate = 3;

% image threshold
% 130 for RFP
% 750 for GFP
img_thresh = 1200;

% if you know 110% sure that there is ZERO contamination
% usually for testing only
% keep at 0
zero_contamination = 0;

% delete all .csv's in each session folder and start again
overwrite_csv = 1;

% Georges border subtraction for session to session fix
use_border_subtraction = 0;

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

%using GUI prompts user to select dead/fled worms across experiment 
%gets dead and fled data
[dead_data,fled_data] = SICKO_GUI(8,12,img_dir_path);

ovr_dir = dir(img_dir_path);   %get directory of experiment
ovr_dir = ovr_dir([ovr_dir.isdir]);                   %flag and get only directorys
ovr_dir(ismember( {ovr_dir.name}, {'.', '..'})) = [];  %remove . and ..


for i = 1:length(ovr_dir)
    
    
    
    get_img_path();
    
end

function [x,y,z] = get_img_path(img_dir_path)

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
    
end
