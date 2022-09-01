function [dead_data, fled_data] = SICKO_GUI(wells,worms,img_dir_path,days)

close all force hidden

% Initializing variables
answer = 0;
grid_data = zeros(worms, wells);
dead_data = zeros(worms, wells);
fled_data = zeros(worms, wells);

hold on;

% Normal = white, dead = red, fled = black
% Can change this to any color palette 
cmap = colormap(flipud(hot));  
colorbar;

h = figure(1);
imshow(grid_data,cmap);

h.Units = 'normalized';
h.Position = [5.2083e-04 0.0565 0.4990 0.8481];

grid_data = make_grid_line(grid_data,wells,worms);

a = 0;

previous_grid_data = grid_data;

while~a
    [worm_well,worm_number] = get_locations();     % Gets all points on figure at one time
    
    for w = 1:length(worm_well)
        worm_well(w) = round(worm_well(w));
    end
    
    for n = 1:length(worm_number)
        worm_number(n) = round(worm_number(n));
    end
    
    get_rid_idx = zeros(size(worm_number));
    for n = 1:length(worm_number)
        if (worm_well(n) > wells) || (worm_well(n) < 1 ||...
                (worm_number(n) > worms) || (worm_number(n) < 1))
            get_rid_idx(n) = 1;
        end
    end
    worm_well = worm_well(~get_rid_idx);
    worm_number = worm_number(~get_rid_idx);
    
    for i = 1:length(worm_number)
        
        if  grid_data(worm_number(i),worm_well(i)) == 128
            grid_data(worm_number(i),worm_well(i)) = 255;
        elseif grid_data(worm_number(i),worm_well(i)) == 255
            grid_data(worm_number(i),worm_well(i)) = 0;
        else
            grid_data(worm_number(i),worm_well(i)) = 128;
        end
    end
    
    imshow(grid_data,cmap);
    grid_data = make_grid_line(grid_data,wells, worms);
    
    drawnow
    
    selection = questdlg('Is this correct? Y to save, N to keep selecting points, R to redo selections:','Save',...
        'Y','N','R','N');
    
    if selection == 'Y'
        a = 1;
        disp('Saving points');
        break
    elseif selection == 'R'
        grid_data = previous_grid_data;
        imshow(grid_data,cmap);
        grid_data = make_grid_line(grid_data,wells,worms);
        drawnow
    else
        a = 0;
        ('Continue selecting points');
    end
    
end


for i = 1:worms
    for j = 1:wells
        if  grid_data(i,j) == 128     % Worms that are dead
            location = well_loc(j);
            prompt = ['Enter the day number that worm ' num2str(i) location ' died'];
            dlgtitle = 'Worm Die';
            definput = {'1'};
            dims = [1 40];
            opts.Interpreter = 'tex';
            answer = inputdlg(prompt,dlgtitle,dims,definput,opts);
            dead_data(i,j) = str2double(cell2mat(answer));
            flag_days = dead_data(i,j);
            
            while  (flag_days < 1 || flag_days > days)
                f = msgbox("Days out bounds, please select again");
                pause(2);
                delete(f);
                prompt = ['Enter the day number that worm ' num2str(i) location ' died'];
                dlgtitle = 'Worm Die';
                definput = {'1'};
                dims = [1 40];
                opts.Interpreter = 'tex';
                answer = inputdlg(prompt,dlgtitle,dims,definput,opts);
                dead_data(i,j) = str2double(cell2mat(answer));
                flag_days = dead_data(i,j);
            end
            
        elseif grid_data(i,j) == 255      % Worms that fled
            location = well_loc(j);
            prompt = ['Enter the day number that worm ' num2str(i) location ' fled'];
            dlgtitle = 'Worm Die';
            definput = {'1'};
            dims = [1 40];
            opts.Interpreter = 'tex';
            answer = inputdlg(prompt,dlgtitle,dims,definput,opts);
            fled_data(i,j) = str2double(cell2mat(answer));
            flag_days = fled_data(i,j);
            
            while (flag_days < 1 || flag_days > days)
                f = msgbox("Days out bounds, please select again");
                pause(2);
                delete(f);
                prompt = ['Enter the day number that worm ' num2str(i) location ' fled'];
                dlgtitle = 'Worm Die';
                definput = {'1'};
                dims = [1 40];
                opts.Interpreter = 'tex';
                answer = inputdlg(prompt,dlgtitle,dims,definput,opts);
                fled_data(i,j) = str2double(cell2mat(answer));
                flag_days = fled_data(i,j);  
            end
            
        end
    end
end

writematrix(dead_data,fullfile(img_dir_path,'GUI_dead_data.csv'));
writematrix(fled_data,fullfile(img_dir_path,'GUI_fled_data.csv'));

close all

    function letter = well_loc(well_num)
        switch well_num
            case 1
                letter = 'A';
            case 2
                letter = 'B';
            case 3
                letter = 'C';
            case 4
                letter = 'D';
            case 5
                letter = 'E';
            case 6
                letter = 'F';
            case 7
                letter = 'G';
            case 8
                letter = 'H';
        end
    end



    function a = make_grid_line(grid_data,wells, worms)   % Makes grid lines on figure
        
        axis on;
        
        ax = gca;
        title({'Select Dead or Censored','Press enter when done','Red(1) - Dead; Black(2) - Fled'})
        set(gca,'xaxisLocation','top');
        % Set where ticks will be
        ax.YTick = 1:worms;
        ax.XTick = 1:wells;
        ax.XTickLabel = { 'A','B','C','D','E','F','G','H'};
        xlabel('Well'); ylabel('Worm #');
        
        
        for j = 1:length(grid_data)+1
            plot([0.5,wells+0.5],[j-.5,j-.5],'b');
        end
        
        for i = 1:width(grid_data)+1
            plot([i-.5,i-.5],[0.5,worms+0.5],'b');
        end
        
        a = grid_data;
    end

    function [day, number] = get_locations()  %gets points from user
        [worm_well,worm_number] = getpts();
        day = worm_well;
        number = worm_number;
    end

end




