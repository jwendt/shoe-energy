function [groupings_list...
          groupings_matrix...
          outer_side_indices...
          inner_side_indices...
          heel_side_indices...
          toe_side_indices] = GetSensorGroupingsFromPedar(varargin)
% GetSensorGroupingsFromPedar   Returns a cell array of N sensor groupings (vectors) as
%                               well as a Nx99 matrix of logicals in which the (i,j)
%                               element is 1 if group i contains sensor j and 0
%                               otherwise. The sensor groupings are created by applying
%                               the variable number of variable sized matrices
%                               exhaustively across the Pedar shoe sensor mapping
%                               matrix.
%
%                               Calling GetSensorGroupingsFromPedar with no
%                               masks passed in will automatically return shoe
%                               mappings for the single sensor. Therefore, it
%                               is not necessary to pass the single sensor in
%                               as a parameter.
%
%    GetSensorGroupingsFromPedar(VARARGIN)
%
%    VARARGIN is any number of arbitrarily sized matrices of logicals (1s and
%             0s). These masks are applied on the equivalently sized
%             sub-matrices of the Pedar shoe sensor mapping matrix.
%
%    Example masks include the following:
%
%      masks{1} = [1 1];
%
%      masks{2} = [1;
%                  1];
%
%      masks{3} = [1 1;
%                  1 1];
%
%      masks{4} = [1 1 1 1;
%                  1 1 1 1];
%
%      masks{5} = [1 1;
%                  1 1;
%                  1 1;
%                  1 1];
%
%      masks{6} = [1 1 0 0;
%                  1 1 0 0;
%                  1 1 1 1;
%                  1 1 1 1];
%
%      masks{7} = rot90(masks{6});
%
%      masks{8} = rot90(masks{7});
%
%      masks{9} = rot90(masks{8});
%
%
%    Example calling the function:
%
%      [groupings_list groupings_matrix] = GetSensorGroupingsFromPedar(masks{1}, masks{2});
%
%      [groupings_list groupings_matrix] = GetSensorGroupingsFromPedar(masks{:});

% shoe_image represents the sensors on the Hermes shoe platform for the right
% foot. The left foot is simply the reflection of this matrix about the y axis,
% this means no transformation from left to right is necessary. E.g. sensor
% 1 corresponds to the inner heel on both the left and right foot.
shoe_image = [ NaN 96 97 98 99  NaN  NaN;
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

% Get left, right, heel, and toe indices, from here, we work
LoadConstants;
shoe_right = config.inner_side_indices;
shoe_left = config.outer_side_indices;
shoe_heel = config.heel_side_indices;
shoe_toe = config.toe_side_indices;

% Flip shoe upside down just so that we always start our groupings enumerations
% with sensor 1. This step is not necessary, but helps a little with radability
% if/when debugging the sensor groupings.
shoe_image = flipud(shoe_image);
[shoe_length shoe_width] = size(shoe_image);

num_groupings = 0;
groupings_list = {};
groupings_matrix = [];
outer_side_indices = [];
inner_side_indices = [];
heel_side_indices = [];
toe_side_indices = [];

masks = {[1] varargin{:}};

% Apply each mask to each same sized sub-matrix in the Pedar shoe mapping
for grouping_index = 1:size(masks,2)
  mask = logical(masks{grouping_index});
  [mask_length mask_width] = size(mask);

  % Check that the mask dimensions fall within the shoe matrix
  if(mask_length > shoe_length || mask_width > shoe_width)
    fprintf('Error: sensor mask dimensions must be less than or equal to the Pedar shoe dimensions (about 15x7 to an approximation)\n');
    clear groupings_list, groupings_matrix;
    return
  end

  % Loop through entire shoe (but only so far as the mask dimensions allow)
  for i=1:shoe_length-mask_length+1
    for j=1:shoe_width-mask_width+1
      % Grab a temporary portion of the shoe that has the same dimension as the
      % mask
      shoe_portion = shoe_image(i:i+mask_length-1, j:j+mask_width-1);

      % Grab the sensors in this shoe_portion corresponding to the mask and
      % convert that matrix to a vector.
      sensors = shoe_portion(mask);
      sensors = reshape(sensors,1,numel(sensors));
      sensors = sort(sensors);

      % Only add sensor groupings to the list/matrix if the mask successfully
      % overlays only sensors
      if(sum(isnan(sensors)) == 0)
        num_groupings = num_groupings + 1;

        % Append sensor list to groupings list
        groupings_list{num_groupings} = sensors;

        % Append row to groupings matrix where columns corresponding to sensor
        % list are set to 1
        groupings_matrix = [groupings_matrix; zeros(1,99)];
        groupings_matrix(num_groupings, sensors) = 1;

        % If more of the groupings are in the shoe_left than in shoe_right then
        % we deem this sensor grouping to be on the left side, vice versa for
        % the right side, and likewise for the heel and toe side
        if(sum(ismember(sensors, shoe_left)) > sum(ismember(sensors, shoe_right)))
          outer_side_indices = [outer_side_indices num_groupings];
        elseif(sum(ismember(sensors, shoe_right)) > sum(ismember(sensors, shoe_left)))
          inner_side_indices = [inner_side_indices num_groupings];
        end

        if(sum(ismember(sensors, shoe_heel)) > sum(ismember(sensors, shoe_toe)))
          heel_side_indices = [heel_side_indices num_groupings];
        elseif(sum(ismember(sensors, shoe_toe)) > sum(ismember(sensors, shoe_heel)))
          toe_side_indices = [toe_side_indices num_groupings];
        end
      end
    end
  end
end

groupings_matrix = logical(groupings_matrix);
