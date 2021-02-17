clear all
close all
img_dir_path = uigetdir('\\fs.mcb.arizona.edu\LabSupport\Sutphin Lab\Projects\Worm infection\SICKO\');

img_paths = dir(fullfile(img_dir_path, '*.tif'));
[~,sort_idx,~] = natsort({img_paths.name});

img_paths = img_paths(sort_idx);

number_imgs_in_replicate = 3;

se = strel('disk',3);

figure;

image_integral_intensities = zeros(1,length(img_paths));
image_integral_areas = zeros(1,length(img_paths));

img_counter = 1;
for i = 1:length(img_paths)
    
    this_img = imread(fullfile(img_dir_path,img_paths(i).name));
    
    data = this_img;
    
    mask = imclose(bwareaopen(data>130,10,4),se);
    
    masked_data = mask.*double(data); % this converts the picture array to mathable stuff 
    
    if img_counter < 2
        imshowpair(masked_data,this_img,'montage')
        title(string(img_paths(i).name))
        drawnow;
        
        redo = questdlg({'Does this image have any contamination in it?',...
            'If so draw rectange around the worm and double click it'},'Redo?','Yes','No','No');
        
        rect = [1 1 size(this_img)];
        if isequal(redo,'Yes')
            
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
    
    close all
    
    image_integral_intensities(i) = sum(cropped_data(:));
    image_integral_areas(i) = sum(cropped_data(:)>0);
    
    linear_data = nonzeros(masked_data);
        
    [counts,binLoc] = hist(linear_data,255); 
%     stem(binLoc,counts)
        
end

writematrix(image_integral_intensities,[img_dir_path '\image_integral_intensities.csv']);
writematrix(image_integral_areas,[img_dir_path '\image_integral_areas.csv']);

