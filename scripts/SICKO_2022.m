clear all 
close all 

%Y:\Users\Luis Espejo\SICKO\Experiments\Dual Validation\Repeat 1

% number of images in the replicate
number_imgs_in_replicate = 3;

% image threshold
% 130 for RFP


% 750 for GFP
img_thresh = 3200;

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
    exp_dir_path = uigetdir(luis_path_mac);
else
    exp_dir_path = uigetdir(data_path);
end

if overwrite_csv
    overwrite_file(exp_dir_path);
end 

ovr_dir = dir(exp_dir_path);   %get directory of experiment
ovr_dir = ovr_dir([ovr_dir.isdir]);                   %flag and get only directorys
ovr_dir(ismember( {ovr_dir.name}, {'.', '..'})) = [];  %remove . and ..

%using GUI prompts user to select dead/fled worms across experiment 
%gets dead and fled data
%(wells,worms,path)
[dead_data,fled_data] = SICKO_GUI(8,12,exp_dir_path,length(ovr_dir));

for img_count = 1:length(ovr_dir)
    
    img_dir_path = fullfile(exp_dir_path, ovr_dir(count).name);
    
    img_paths = get_img_paths(img_dir_path, number_imgs_in_replicate); %gets img paths per day
    
end

for count = 1:length(ovr_dir)
    
    img_dir_path = fullfile(exp_dir_path, ovr_dir(count).name);
     
    img_process(img_paths, img_dir_path, img_thresh, zero_contamination, use_border_subtraction,dead_data,fled_data);

end

function img_process(img_paths, img_dir_path, img_thresh, zero_contamination, use_border_subtraction,dead_data,fled_data)
    
    
    flag = 0;
    
    se = strel('disk',3);
    writematrix(string({img_paths.name}),fullfile(img_dir_path,'image_names.csv'));

    figure('units','normalized','outerposition',[0 0 1 1])

    image_integral_intensities = zeros(1,length(img_paths));
    image_integral_areas = zeros(1,length(img_paths));
    dead = zeros(1,length(img_paths));
    censored = zeros(1,length(img_paths));

    img_counter = 1;
    day = img_dir_path(end);
    
    for i = 1:length(img_paths)
    
        well_num = well_number(regexpi(img_paths(i).name,'[a-z]+','match','once'));
        worm_num = str2double(regexpi(img_paths(i).name,'\d*','match','once'));
       
        if (dead_data(worm_num,well_num)~=0 || fled_data(worm_num,well_num)~=0)
            if day >= (dead_data(worm_num,well_num) || fled_data(worm_num,well_num))
                if dead_data(worm_num,well_num)~=0
                    flag = 1;
                    dead(i:i+2) = 1;
                elseif fled_data(worm_num,well_num)~=0
                    flag = 2;
                else 
                    flag = 0;
                end
            end
        end
        
        this_img_path = fullfile(img_dir_path,img_paths(i).name);
        
        this_img = imread(this_img_path);

        data = this_img;

        mask = imclose(bwareaopen(data>img_thresh,10,4),se);

    %     T = mean2(this_img)+3*std2(this_img);
    %     mask2 = bwareaopen(bwareaopen(data>T,10,4)-bwperim(imfill(mask,'holes')),10,4);
    %     mask2 = imgaussfilt(double(mask2),1.2)>0;

        masked_data = mask.*double(data); % this converts the picture array to mathable stuff 
        prompt_quit = 'No';
        
            if img_counter < 2 && flag == 0

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
                    imshow(this_img,[0, img_thresh])
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
                elseif dlg_choice == ""
                    prompt_quit = questdlg('Do you want to quit?','Quit','Yes','No','No');
                    if isequal(prompt_quit,'Yes')
                        close all;
                        error('User quit');
                    else
                        dlg_choice2 = 'Nevermind';
                    end
                else
                    dlg_choice2 = 'Nevermind';
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
                        dlg_choice3 = 'No';
                    end
                elseif dlg_choice2 == ""
                    prompt_quit = questdlg('Do you want to quit?','Quit','Yes','No','No');
                    if isequal(prompt_quit,'Yes')
                        close all;
                        error('User quit');
                    else
                        dlg_choice3 = 'No';
                    end
                else
                    dlg_choice3 = 'No';
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

            if flag ~= 0
                img_counter = img_counter+1;
            end
            
            if img_counter > 3
                img_counter=1;
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
        flag = 0;
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
    
end


%gets img_paths, sorts, checks if imgs are in replicates
function img_paths = get_img_paths(img_dir_path, number_imgs_in_replicate) 

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


function overwrite_file(img_dir_path)  %overwrites any csv files that are in the folder
    
    dlg_choice = questdlg({'WARNING',...
    'If you continue, this will overwrite all csvs in the folder'},'WARNING','Continue','Quit','Quit');
    
    if isequal(dlg_choice, 'Quit')
        error('Quit program, begin again');
    end
                
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

function well = well_number(well_num)
    switch well_num
        case 'a'
            well = 1;
        case 'A'
            well = 1;
        case 'b'
            well = 2;
        case 'B'
            well = 2;
        case 'c'
            well = 3;
        case 'C'
            well = 3;
        case 'd'
            well = 4;
        case 'D'
            well = 4;
        case 'e'
            well = 5;
        case 'E'
            well = 5;
        case 'f'
            well = 6;
        case 'F'
            well = 6;
        case 'g'
            well = 7;
        case 'G'
            well = 7;
        case 'h' 
            well = 8;
        case 'H'
            well = 8;
    end
end
