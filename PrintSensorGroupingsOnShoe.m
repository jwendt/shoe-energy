function shoe_image = PrintSensorGroupingsOnShoe(filename, groupings)
% PrintShoeSensorConfiguration  Saves a pretty picture of a shoe with the
%                               sensors in groupings shaded.
%
%    GetSensorGroupingsFromPedar(FILENAME, GROUPINGS)
%
%    FILENAME  is a string of the image to write
%
%    GROUPINGS  a cell array of vectors of sensors ranging from 1 to 99

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
%shoe_map = flipud(shoe_map);

sensor_vector = zeros(1,99);
for i = 1:length(groupings)
  for j = 1:length(groupings{i})
    sensor_vector(groupings{i}(j)) = i;
  end
end

% Set all sensors that aren't selected to the highest value in our colormapping
% so that they are colored white
sensor_vector(sensor_vector == 0) = length(groupings)+1;

h = PlotFoot(sensor_vector,[0 length(groupings)+1],'invert');
saveas(h, filename);

% DEPRECATED
%{
shoe_image = zeros(size(shoe_map));
for i=1:length(groupings)
  for j=1:length(groupings{i})
    shoe_image(find(shoe_map == groupings{i}(j))) = i;
  end
end

% background will be white (flip range from 0 to length and background becomes
% black and color switch)
I = mat2gray(shoe_image, [length(groupings)+1 0]);

% Color non-sensors black
I(isnan(shoe_map)) = 0;

% Spread values from 0 to 256 (so that we can map it to hot)
I = I*256;

% Resize and save the image
largeI = imresize(I,32,'nearest');

% TODO why does this only work manually, but fail once I run the function over
% a for loop?
imwrite(largeI, hot, filename);
%h = imshow(largeI,hot);
%saveas(h, filename);
%}
