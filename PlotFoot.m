function h = PlotFoot(values, range, varargin)
% PlotFoot(VALUES, RANGE, VARARGIN)
%
%    VALUES  is a vector of 99 values
%
%    RANGE   is a vector of two values, applied to caxis
%
%    VARARGIN  optional variables include
%                'colorbar'  prints a colorbar on the figure
%                'invert'    inverts the colors of the non-sensor cells

for i = 1:length(varargin)
  if(strcmp(varargin{i},'colorbar'))
    display_colorbar = varargin{i};
  elseif(strcmp(varargin{i},'invert'))
    invert_color = varargin{i};
  end
end

shoe_map = [ NaN 96 97 98 99  NaN  NaN;
             90 91 92 93 94 95  NaN;
             83:89;
             76:82;
             69:75;
             62:68;
             55:61;
             48:54;
             41:47;
             34:40;
             27:33;
             20:26;
             13:19;
             6:12;
             NaN 1:5 NaN];
shoe_map = flipud(shoe_map);

% Fill the shoe image
shoe_image = zeros(size(shoe_map));
for sensor = 1:length(values)
  shoe_image(find(shoe_map == sensor)) = values(sensor);
end

% Replace NaN's with the lowest (or highest)) value in the provided range for
% aesthetics
if(exist('invert_color') && strcmp(invert_color,'invert'))
  shoe_image(isnan(shoe_map)) = range(1);
else
  shoe_image(isnan(shoe_map)) = range(2);
end

% For pcolor to show everything we trick it by adding a column of zeros on the
% right of the matrix and a row of zeros along the bottom of the matrix
shoe_image_grid = shoe_image;
[rows cols] = size(shoe_image_grid);
shoe_image_grid = [shoe_image_grid; zeros(1,cols)];
shoe_image_grid = [shoe_image_grid zeros(rows+1,1)];

colormap(hot);
h = pcolor(shoe_image_grid);
shading flat;
set(h,'edgecolor','black');
axis off;
axis equal;
if (exist('display_colorbar') && strcmp(display_colorbar,'colorbar'))
  colorbar;
end
caxis(range);
