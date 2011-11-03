function [dlds...
          amp...
          lateral...
          heeltoe...
          dlds_at_sensor...
          amp_at_sensor...
          land_at_sensor...
          step_starts...
          step_ends...
          test_dlds...
          test_amp...
          test_lateral...
          test_heeltoe...
          test_dlds_at_sensor...
          test_amp_at_sensor...
          test_land_at_sensor...
          test_step_starts...
          test_step_ends...
          raw_data] = GetMetrics(input,...
                      feet,...
                      groupings_list,...
                      outer_side_indices,...
                      inner_side_indices,...
                      heel_side_indices,...
                      toe_side_indices)
% GetMetrics(FILENAMES, FEET, GROUPINGS, OUTER_SIDE_INDICES, INNER_SIDE_INDICES, HEEL_SIDE_INDICES, TOE_SIDE_INDICES)
% 
%   Parameters:
%     FILENAMES  A cell array of filename paths to *.mat files with left_foot
%                right_foot matrices
%
%     FEET       A cell array of one or two elements with values 'left' and/or
%                'right'
%
%     GROUPINGS  A cell array of vectors corresponding to groupings of
%                individual sensors. These vectors should only have values
%                raning from 1 to 99 for the Pedar shoe mapping. This cell
%                array can be generated using the GetSensorGroupingsFromPedar
%                function.
%
%     OUTER_SIDE_INDICES  A vector of indices of the sensor groupings in
%                         GROUPINGS sensor that correspond to the outer side of
%                         the foot. This can be generated from the
%                         GetSensorGroupingsFromPedar function.
%
%     INNER_SIDE_INDICES  A vector of indices of the sensor groupings in
%                         GROUPINGS sensor that correspond to the inner side of
%                         the foot. This can be generated from the
%                         GetSensorGroupingsFromPedar function.
%
%     HEEL_SIDE_INDICES  A vector of indices of the sensor groupings in
%                        GROUPINGS sensor that correspond to the heel side of
%                        the foot. This can be generated from the
%                        GetSensorGroupingsFromPedar function.
%
%     TOE_SIDE_INDICES  A vector of indices of the sensor groupings in
%                       GROUPINGS sensor that correspond to the toe side of
%                       the foot. This can be generated from the
%                       GetSensorGroupingsFromPedar function.
%
%   Output:
%     The variables outputted are in the following order.
%
%     DLDS  A vector of length N with change in length of step values.
%
%     AMP  A vector of length N with average maximum amplitude values at each
%          step.
%
%     LATERAL  A vector of length N with differences between the average
%              maximum outer and average inner amplitudes.
%
%     HEELTOE  A vector of length N with differences between the average heel
%              land time and average toe land time.
%
%     DLDS_AT_SENSOR  A matrix of size NxM with change in length of step values
%                     measured at each of the M sensor groupings.
%
%     AMP_AT_SENSOR  A matrix of size NxM with max amplitude values at each
%                    step for each of the M sensor groupings.
%
%     LAND_AT_SENSOR  A matrix of size NxM with land times at each step for
%                     each of the M sensor groupings.
%
%     STEP_STARTS  A vector of length N of step start times.
%
%     STEP_ENDS  A vector of length N of step end times.
%
%     ...  Another nine more variables like those above are returned. These are
%          the TEST_DLDS, TEST_AMP, TEST_LATERAL, TEST_HEELTOE,
%          TEST_DLDS_AT_SENSOR, etc. variables to be used in testing. These are
%          20% of the data loaded from INPUT.
THRESHOLD_FRACTION = 0.15;
TESTING_PORTION = 0.2;

% Training Data
dlds = [];
amp = [];
lateral = [];
heeltoe = [];

dlds_at_sensor = [];
amp_at_sensor = [];
land_at_sensor = [];

step_starts = [];
step_ends = [];

% Testing data
test_dlds    = [];
test_amp     = [];
test_lateral = [];
test_heeltoe = [];

test_dlds_at_sensor    = [];
test_amp_at_sensor     = [];
test_land_at_sensor = [];

test_step_starts = [];
test_step_ends = [];

raw_data = cell(length(input),length(feet));
% Grab all inputs
for i = 1:length(input)
  fprintf('Loading ''%s''\n', input{i});
  data = load(input{i});

  % TODO Plotting function below is unnecessary
  %figure(i); clf; hold on;

  for f = 1:length(feet)
    foot_data = [];
    if(strcmp(feet{f},'left'))
      foot_data = data.left_foot;
    elseif(strcmp(feet{f},'right'))
      foot_data = data.right_foot;
    else
      error('feet must be either "left" or "right"\n');
    end

    % Get sample indices of beginning and ending
    [tmp_step_starts tmp_step_ends] = GetSteps(sum(foot_data,2), THRESHOLD_FRACTION);
    %[right_step_starts right_step_ends] = GetSteps(sum(data.right_foot,2), THRESHOLD_FRACTION);
  
    % Use the indices from GetSensorGroupingsFromPedar to build sensor groupings and
    % append them to our data matrices. Previously we found left_dlds, left_amp,
    % etc. using GetMetrics(data.left_foot, ...). Now we append to
    % data.left_foot the mean values of each sensor grouping.
    num_samples = size(foot_data,1);
    fprintf('Calculating %d data samples for each %d sensor groupings for %s foot\n', num_samples, length(groupings_list), feet{f});
    tmp_foot_with_groupings = nan(num_samples, length(groupings_list));
    for group = 1:length(groupings_list)
      tmp_foot_with_groupings(:,group) = mean(foot_data(:,groupings_list{group}),2);
    end
  
    % Calculate metrics
    % TODO: GetMetrics does not know how to compute lateral and heeltoe from
    %       the sensor groupings defined by GetSensorGroupingsFromPedar (main
    %       issue is we're calculating lateral using outer_side_indices and
    %       inner_side_indices, when really we should only be using the defaults.
    fprintf('Calculating %s foot metrics\n', feet{f});
    [tmp_dlds...
     tmp_amp...
     tmp_lateral...
     tmp_heeltoe...
     tmp_dlds_at_sensor...
     tmp_amp_at_sensor...
     tmp_land_at_sensor] = GetMetricsFromSingleDataSource(tmp_foot_with_groupings,...
                                                          tmp_step_starts,...
                                                          tmp_step_ends,...
                                                          THRESHOLD_FRACTION,...
                                                          outer_side_indices,...
                                                          inner_side_indices,...
                                                          heel_side_indices,...
                                                          toe_side_indices);
    raw_data{i, f} = tmp_foot_with_groupings;
    % TODO Plotting function below is unnecessary
    %{
    subplot(2,1,f);
    plot(sum(foot_data,2), '-b');
    hold on;
    a = axis; max_amp = a(3); min_amp = a(4);
    title(sprintf('%s S%d', feet{f}, i));
    for j=1:length(tmp_step_starts)
      plot([tmp_step_starts(j) tmp_step_starts(j)],[min_amp max_amp],'-g');
      plot([tmp_step_ends(j) tmp_step_ends(j)],[min_amp max_amp],'-k');
    end
    %}

    % TODO This section is currently a bottleneck. Must speed it up and try to
    % decrease the memory footprint that it leaves.
    % Split the data into a training portion and testing portions.
    fprintf('Splitting data into train and test\n');
  
    testing_length = ceil(TESTING_PORTION*length(tmp_dlds));
  
    test_dlds = [test_dlds; tmp_dlds(1:testing_length)];
    test_amp = [test_amp; tmp_amp(1:testing_length)];
    test_lateral = [test_lateral; tmp_lateral(1:testing_length)];
    test_heeltoe = [test_heeltoe; tmp_heeltoe(1:testing_length)];
  
    test_dlds_at_sensor = [test_dlds_at_sensor; tmp_dlds_at_sensor(1:testing_length,:)];
    test_amp_at_sensor = [test_amp_at_sensor; tmp_amp_at_sensor(1:testing_length,:)];
    test_land_at_sensor = [test_land_at_sensor; tmp_land_at_sensor(1:testing_length,:,:)];
  
    test_step_starts = [test_step_starts tmp_step_starts(1:testing_length)];
    test_step_ends = [test_step_ends tmp_step_ends(1:testing_length)];
  
    dlds = [dlds; tmp_dlds(testing_length+1:length(tmp_dlds))];
    amp = [amp; tmp_amp(testing_length+1:length(tmp_amp))];
    lateral = [lateral; tmp_lateral(testing_length+1:length(tmp_lateral))];
    heeltoe = [heeltoe; tmp_heeltoe(testing_length+1:length(tmp_heeltoe))];
  
    dlds_at_sensor = [dlds_at_sensor; tmp_dlds_at_sensor(testing_length+1:length(tmp_dlds),:)];
    amp_at_sensor = [amp_at_sensor; tmp_amp_at_sensor(testing_length+1:length(tmp_amp),:)];
    land_at_sensor = [land_at_sensor; tmp_land_at_sensor(testing_length+1:length(tmp_lateral),:,:)];
    
    step_starts = [step_starts tmp_step_starts(testing_length+1:length(tmp_step_starts))];
    step_ends = [step_ends tmp_step_ends(testing_length+1:length(tmp_step_ends))];
  
    % TODO implement testing_portion and training_portion over the five sets of
    % possible testing and training portions (five because we do 80/20 training
    % to testing ratio)
    %testing_length = ceil(TESTING_PORTION*length(tmp_dlds));
    %count = 0;
    %for start = 0:testing_length:length(tmp_dlds)
    %  count = count + 1;
    %  theend = start+testing_length;
    %  if start+testing_length > length(tmp_dlds)
    %    theend = length(tmp_dlds);
    %  end
    %  testing_indices = start+1:theend;
    %  test_portion_dlds{count} = [test_portion_dlds{count}; tmp_dlds(testing_indices)];
    %  test_portion_amp{count} = [test_portion_amp{count}; tmp_amp(testing_indices)];
    %  test_portion_lateral{count} = [test_portion_lateral{count}; tmp_lateral(testing_indices)];
    %
    %  training_indices_A = 1:start;
    %  training_indices_B = theend+1:length(tmp_dlds);
    %  if training_indices_A
    %    train_portion_dlds{count} = [train_portion_dlds{count}; tmp_dlds(training_indices_A)];
    %    train_portion_amp{count} = [train_portion_amp{count}; tmp_amp(training_indices_A)];
    %    train_portion_lateral{count} = [train_portion_lateral{count}; tmp_lateral(training_indices_A)];
    %  end
    %  if training_indices_B
    %    train_portion_dlds{count} = [train_portion_dlds{count}; tmp_dlds(training_indices_B)];
    %    train_portion_amp{count} = [train_portion_amp{count}; tmp_amp(training_indices_B)];
    %    train_portion_lateral{count} = [train_portion_lateral{count}; tmp_lateral(training_indices_B)];
    %  end
    %end

    clear -regexp 'tmp*'
  end
  clear data
end

%clear -regexp 'left_'


% JAMES HACK to elimate crappy testing data
% 1. load Saro's output.mat or good_results.mat
% 2. run prerun.m
% 3. run print_results.m
%{
start = 1;
%finish = 50;
finish = length(test_dlds);
test_dlds = test_dlds(start:finish);
test_amp = test_amp(start:finish);
test_lateral = test_lateral(start:finish);
test_heeltoe = test_heeltoe(start:finish);

test_dlds_at_sensor = test_dlds_at_sensor(start:finish,:);
test_amp_at_sensor = test_amp_at_sensor(start:finish,:);
test_land_at_sensor = test_land_at_sensor(start:finish,:,:);

test_step_starts = test_step_starts(start:finish);
test_step_ends = test_step_ends(start:finish);
%}
% SEMAJ

end

function [step_starts step_ends] = GetSteps(data, threshold_fraction)
% GetSteps(DATA, THRESHOLD_FRACTION)
%   Returns the step start indices and step end indices given a vector pressure
%   data points. When the data passes the THRESHOLD_FRACTION of it's max data
%   point, a step beings. When the data cross below the THRESHOLD_FRACTION, the
%   step ends.
threshold = threshold_fraction*max(data);

num_samples = length(data);

in_air = (data(1) <= threshold);
marked_in_air = (data(1) <= threshold);

number_of_steps = 0;
for i=1:num_samples
  % data was in the air, now the pressure is large (step beginning)
  %if(in_air(sensor_index) && data(i,sensor_index) > threshold_step)
  if(in_air && data(i) > threshold)
    in_air = false;

    if(marked_in_air)
      marked_in_air = false;

      % update so we know where the step start was
      number_of_steps = number_of_steps + 1;
      step_starts(number_of_steps) = i;
      %plot([i i],[min_amplitude max_amplitude],'-g');
    end

  % data is on the ground, pressure is now relieving (step ending)
  %elseif(~in_air(sensor_index) && data(i,sensor_index) <= threshold_step)
  elseif(~in_air && data(i) <= threshold)
    in_air = true;
    if(~marked_in_air)
      marked_in_air = true;

      % update so we know where the step ends
      if(number_of_steps > 0) % ensures that we always begin with a starting step, not an ending one
        step_ends(number_of_steps) = i;
      end
      %plot([i i],[min_amplitude max_amplitude],'-r');
      %fprintf('sensor %d: step @ %d, time %f\n', sensor_index, i, time(i));
    end
  end
end

end
