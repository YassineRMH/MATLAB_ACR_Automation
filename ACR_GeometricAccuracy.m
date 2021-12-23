%% ACR Geometric Accuracy
% by Yassine Azma (Oct 2021)
%
% This script takes the two image series and measures the end-to-end length
% of the phantom in the sagittal localiser, the vertical and horizontal
% diameters in the resolution insert slice, and the 8-point compass diameters 
% in the grid slice. The results are visualised.

function L = ACR_GeometricAccuracy(img_loc,img_ACR,obj_loc,obj_ACR)
close all

if size(img_ACR,4) > 1 % check if input array contains multiple ACR series
    img_insert = squeeze(double(img_ACR(:,:,1,1))); % if yes, only process the first
    img_grid = squeeze(double(img_ACR(:,:,5,1))); % if yes, only process the first
    waitfor(msgbox('4D array detected. Only processing first axial series.'));
else
    img_insert = double(img_ACR(:,:,1));
    img_grid = double(img_ACR(:,:,5));
end

if ~isempty(obj_loc)
    if isempty(obj_loc.getAttributeByName('PixelSpacing')) %Multi-frame check
        list = obj_loc.getAttributeByName('PerFrameFunctionalGroupsSequence');
        res_loc = list.Item_1.PixelMeasuresSequence.Item_1.PixelSpacing;
    else
        res_loc = obj_loc.getAttributeByName('PixelSpacing'); % retrieve localiser in-plane resolution
    end
end

if isempty(obj_ACR.getAttributeByName('PixelSpacing')) % Multi-frame check
    list = obj_ACR.getAttributeByName('PerFrameFunctionalGroupsSequence');
    res_ACR = list.Item_1.PixelMeasuresSequence.Item_1.PixelSpacing;
else
    res_ACR = obj_ACR.getAttributeByName('PixelSpacing'); % retrieve ACR in-plane resolution
end
%% Localiser

if ~isempty(img_loc)
    img_loc = double(img_loc);
    img_hull_loc = bwareaopen(img_loc > 0.1*max(img_loc(:)),5000); % create mask

    centroid_loc = round(regionprops(img_hull_loc,'Centroid').Centroid); % determine centroid from convex hull image

    loc_dist_list = zeros(1,size(img_loc,1));

    for k = centroid_loc(1)-10:centroid_loc(1)+10
        line_prof(:,k) = improfile(img_hull_loc,[k k],[1 size(img_loc,2)]); % take a vertical line profile
        loc_extent = find(line_prof(:,k)); % find non-zeros
        if isempty(loc_extent)
            loc_dist_list(k) = 0;
        else
            loc_dist_list(k) = (loc_extent(end)-loc_extent(1))*res_loc(2); % multiply length of non-zeros by column resolution
        end
    end

    [~,closestIndex] = min(abs(loc_dist_list-148)); % find closest to 148mm
    loc_dist = loc_dist_list(closestIndex); % select line profile closest to 148mm

    quiver_start = find(line_prof(:,closestIndex),1);
    quiver_end = find(line_prof(:,closestIndex),1,'last');

    figure
    imshow(img_loc,[])
    % axis image
    hold on
    quiver(closestIndex,quiver_start,0,quiver_end-quiver_start,0,'color','r') % display arrow representing vertical line
    % text(centroid_loc(1),loc_extent(1),sprintf('L = %.1fmm',loc_dist),'color','w') % label with measured distance
    title('Localiser')
end
%% Resolution Insert
img_hull_insert = bwconvhull(bwareaopen(img_insert > 0.2*max(img_insert(:)),50)); % use convex hull in case of air bubble!

centroid_insert = regionprops(img_hull_insert,'Centroid').Centroid; % determine centroid from convex hull image

line_prof_v = improfile(img_hull_insert,[centroid_insert(2) centroid_insert(2)],[1 size(img_insert,2)]); % take a vertical line profile
line_prof_h = improfile(img_hull_insert,[1 size(img_insert,1)],[centroid_insert(1) centroid_insert(1)]); % take a horizontal line profile

insert_extent_v = find(line_prof_v); % find non-zeros
insert_extent_h = find(line_prof_h); % find non-zeros

insert_dist_v = (insert_extent_v(end)-insert_extent_v(1))*res_ACR(2); % multiply length of non-zeros by column resolution
insert_dist_h = (insert_extent_h(end)-insert_extent_h(1))*res_ACR(1); % multiply length of non-zeros by row resolution

figure
imshow(img_insert,[])
axis image
hold on
quiver(centroid_insert(1),insert_extent_v(1),0,insert_extent_v(end)-insert_extent_v(1),0,'color','r') % display arrow representing vertical line
% text(centroid_insert(1),insert_extent_v(1),sprintf('L = %.1fmm',insert_dist_v),'color','w') % label with measured distance

quiver(insert_extent_h(2),centroid_insert(2),insert_extent_h(end)-insert_extent_h(1),0,0','color','r') % display arrow representing horizontal line
% text(insert_extent_h(2),centroid_insert(2),sprintf('L = %.1fmm',insert_dist_h),'color','w') % label with measured distance
title('Resolution Insert')
%% Distortion Grid
img_hull_grid = bwconvhull(bwareaopen(img_grid > 0.3*max(img_grid(:)),50));

centroid_grid = regionprops(img_hull_grid,'Centroid').Centroid; % determine centroid from convex hull image

% Horizontal and Vertical
line_prof_v = improfile(img_hull_grid,[centroid_grid(1) centroid_grid(1)],[1 size(img_grid,2)]); % take a vertical line profile
line_prof_h = improfile(img_hull_grid,[1 size(img_grid,2)],[centroid_grid(2) centroid_grid(2)]); % take a horizontal line profile

grid_extent_v = find(line_prof_v); % find non-zeros
grid_extent_h = find(line_prof_h); % find non-zeros

grid_dist_v = (grid_extent_v(end) - grid_extent_v(1))*res_ACR(2); % multiply length of non-zeros by column resolution
grid_dist_h = (grid_extent_h(end) - grid_extent_h(1))*res_ACR(1); % multiply length of non-zeros by row resolution

% Diagonals
rot_matrix_se = [cosd(45) -sind(45); sind(45) cosd(45)]; % Create 45 degree rotation matrix
% rotate vertical line around centroid by 45 degrees
x_se = rot_matrix_se*[(1:size(img_grid,2))-centroid_grid(1);repmat(centroid_grid(2),1,size(img_grid,1))-centroid_grid(2)]; 
% take line profile along the nw -> se diagonal
line_prof_se = improfile(img_hull_grid,centroid_grid(1)+2+[x_se(1,1) x_se(1,end)],centroid_grid(2)+[x_se(2,1) x_se(2,end)]);

rot_matrix_sw = [cosd(90) -sind(90); sind(90) cosd(90)]; % Create 90 degree rotation matrix
x_sw = rot_matrix_sw*[x_se(1,:);x_se(2,:)]; % rotate nw->se by 90 degrees
% take line profile along the sw -> ne diagonal
line_prof_sw = improfile(img_hull_grid,centroid_grid(1)-2+[x_sw(1,1) x_sw(1,end)],centroid_grid(2)+[x_sw(2,1) x_sw(2,end)]);

grid_extent_se = find(line_prof_se); % find non-zeros
grid_extent_sw = find(line_prof_sw); % find non-zeros

prof_spacing_se = (1/mean(nonzeros(abs(diff(x_se,1,2))))); % find equivalent se diagonal distance in straight pixels
prof_spacing_sw = (1/mean(nonzeros(abs(diff(x_sw,1,2))))); % find equivalent sw diagonal distance in straight pixels
grid_dist_se = (grid_extent_se(end) - grid_extent_se(1))*prof_spacing_se*rms(res_ACR); % multiply length of non-zeros by hypotenuse of resolution
grid_dist_sw = (grid_extent_sw(end) - grid_extent_sw(1))*prof_spacing_sw*rms(res_ACR); % multiply length of non-zeros by hypotenuse of resolution

% Display
figure
imshow(img_grid,[])
axis image
hold on
quiver(centroid_grid(1),grid_extent_v(1),0,grid_extent_v(end)-grid_extent_v(1),0,'color','r') % display arrow representing vertical line
% text(centroid_grid(1),grid_extent_v(1),sprintf('L = %.1fmm',grid_dist_v),'color','w') % label with measured distance

quiver(grid_extent_h(2),centroid_grid(2),grid_extent_h(end)-grid_extent_h(1),0,0,'color','r') % display arrow representing horizontal line
% text(grid_extent_h(2),centroid_grid(2),sprintf('L = %.1fmm',grid_dist_h),'color','w') % label with measured distance

quiver(x_se(2,1)+centroid_grid(1)+grid_extent_se(1),x_se(1,1)+centroid_grid(2)+grid_extent_se(1),...
    grid_extent_se(end)-grid_extent_se(1),grid_extent_se(end)-grid_extent_se(1),0,'color','r') % display arrow representing se->nw line 
% text(x_se(2,1)+centroid_grid(1)+grid_extent_se(1),x_se(1,1)+centroid_grid(2)+grid_extent_se(1),...
%     sprintf('L = %.1fmm',grid_dist_se),'color','w') % label with measured distance

quiver(x_sw(1,1)+centroid_grid(1)-grid_extent_sw(1),x_sw(2,1)+centroid_grid(2)+grid_extent_sw(1),...
    grid_extent_sw(1)-grid_extent_sw(end),grid_extent_sw(end)-grid_extent_sw(1),0,'color','r') % display arrow representing sw->ne line
% text(x_sw(1,1)+centroid_grid(1)-grid_extent_sw(1),x_sw(2,1)+centroid_grid(2)+grid_extent_sw(1),...
%     sprintf('L = %.1fmm',grid_dist_sw),'color','w') % label with measured distance
title('Grid Insert')
% sgtitle('Geometric Accuracy')

if ~isempty(img_loc)
    L = round([loc_dist,insert_dist_v,insert_dist_h,grid_dist_v,grid_dist_h,grid_dist_se,grid_dist_sw],1); % output measured distances
else
    L = round([NaN,insert_dist_v,insert_dist_h,grid_dist_v,grid_dist_h,grid_dist_se,grid_dist_sw],1); % output measured distances without localiser
end