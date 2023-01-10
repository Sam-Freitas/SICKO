clear all
close all force hidden 

num_days = randi([2 5],1);       %this will be replaced with the data from SICKO runs
worms = randi([10 20],1);

% num_days = 5;
% worms = 5;

answer = 0;

grid_data = zeros(worms,num_days);

hold on;

% CustomColor = [0,0,0;1,1,1;1,0,0]; %normal = white, dead = red, censored = black
% cmap = colormap(CustomColor);
cmap = colormap('hot');   %can change this to any color palette you want
colorbar;

% figure('units','normalized','outerposition',[0 0 1 1]);
h = imshow(grid_data,cmap);

grid_data = make_grid_line(grid_data,num_days, worms);

a = 0;

previous_grid_data = grid_data; 

while~a
    [worm_day,worm_number] = get_locations();     %gets all points on figure at one time

    for w = 1:length(worm_day)
        worm_day(w) = round(worm_day(w));
    end

    for n = 1:length(worm_number)
        worm_number(n) = round(worm_number(n));
    end
    
    get_rid_idx = zeros(size(worm_number));
    for n = 1:length(worm_number)
        if (worm_day(n) > num_days) || (worm_day(n) < 1 ||...
                (worm_number(n) > worms) || (worm_number(n) < 1))
            get_rid_idx(n) = 1;
        end
    end
    worm_day = worm_day(~get_rid_idx);
    worm_number = worm_number(~get_rid_idx);
    
    for i = 1:length(worm_number)
        
        if  grid_data(worm_number(i),worm_day(i)) == 128
            grid_data(worm_number(i),worm_day(i)) = 255;
        elseif grid_data(worm_number(i),worm_day(i)) == 255
            grid_data(worm_number(i),worm_day(i)) = 0;
        else
            grid_data(worm_number(i),worm_day(i)) = 128;
        end
    end

    imshow(grid_data,cmap);
    grid_data = make_grid_line(grid_data,num_days, worms);

    drawnow

    answer = questdlg('Is this correct? Y to save, N to keep selecting points, R to redo selections:','Save',...
                        'Y','N','R','N');

    if answer == 'Y'
        a = 1;
        disp('Saving points');
        break
    elseif answer == 'R'
        grid_data = previous_grid_data;
        imshow(grid_data,cmap);
        grid_data = make_grid_line(grid_data,num_days, worms);
        drawnow
    else
        a = 0;
        ('Continue selecting points');
    end
end

close all

function a = make_grid_line(grid_data,num_days, worms)   %makes grid lines on fig
    
        axis on;

        ax = gca;
        title({'Select Dead or Censored','Press enter when done','Red(1) - Dead; White(2) - Censored'})
        set(gca,'xaxisLocation','top');
        % Set where ticks will be
        ax.YTick = 1:worms;
        ax.XTick = 1:num_days;
        xlabel('Day'); ylabel('Worm #');

        
    for j = 1:length(grid_data)+1
        plot([0.5,num_days+0.5],[j-.5,j-.5],'w-');
    end
    
    for i = 1:width(grid_data)+1
        plot([i-.5,i-.5],[0.5,worms+0.5],'w-');
    end
    
    a = grid_data;
end

function [day, number] = get_locations()  %gets points from user
    [worm_day,worm_number] = getpts();
    day = worm_day;
    number = worm_number; 
end

%     for j = 1:width(grid_data)+1
%         plot([0.5,num_days+0.5],[j-.5,j-.5],'w-');
%     end
%     
%     for i = 1:length(grid_data)+1
%         plot([i-.5,i-.5],[0.5,worms+0.5],'w-');
%     end






