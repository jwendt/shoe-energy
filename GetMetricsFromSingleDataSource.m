function [dlds...
          amp...
          lateral...
          heeltoe...
          dlds_at_sensor...
          amp_at_sensor...
          land_at_sensor] = GetMetricsFromSingleDataSource(data,...
                                                           step_starts,...
                                                           step_ends,...
                                                           threshold_percent,...
                                                           varargin)
% GetMetricsFromSingleDataSource(DATA, STEP_STARTS, STEP_ENDS, THREHOLD)
%
% GetMetricsFromSingleDataSource(DATA, STEP_STARTS, STEP_ENDS, THREHOLD, OUTER_SIDE_INDICES, INNER_SIDE_INDICES, HEEL_SIDE_INDICES, TOE_SIDE_INDICS)
%
%    GetMetricsFromSingleDataSource returns measurements for change in step stride (dlds),
%    maximum amplitude (amp), lateral difference between left and right
%    sides of the foot, and time difference between heel and toe landing (not
%    yet implemented). It also returns those values measured at each sensor.
%    length(STEP_STARTS) and length(STEP_ENDS) must be the same.
LoadConstants;
if (length(varargin) == 4)
  outer_side_indices = varargin{1};
  inner_side_indices = varargin{2};
  heel_side_indices = varargin{3};
  toe_side_indices = varargin{4};
elseif (length(varargin) == 0)
  outer_side_indices = config.outer_side_indices;
  inner_side_indices = config.inner_side_indices;
  heel_side_indices = config.heel_side_indices;
  toe_side_indices = config.toe_side_indices;
else
  error('Must include left side, right side, heel side and toe side incides, or none at all');
end

EXTRA = 20;

num_steps = length(step_ends);
[num_samples num_sensors] = size(data);

dlds_at_sensor = zeros(num_steps, num_sensors);
amp_at_sensor = zeros(num_steps, num_sensors);
land_at_sensor = zeros(num_steps, num_sensors);
%lateral_at_sensor = nan(num_steps, num_sensors, num_sensors);
%heeltoe_at_sensor = nan(num_steps, num_sensors, num_sensors);

amp = zeros(num_steps,1);
dlds = zeros(num_steps,1);
lateral = nan(num_steps,1);
heeltoe = nan(num_steps,1);

%step
%fprintf('  amp & dlds\n');
for mi=1:num_steps
  running_amp_sum = 0;

  count = 0;
  %sensor
  for si=1:num_sensors
    % dlds_at_sensor
    if(mi+1 < num_steps)
      lower = step_starts(mi) - EXTRA;
      upper = step_ends(mi+2) + EXTRA;
      if( upper > num_samples )
        upper = num_samples;
      end
      if( lower < 1 )
        lower = 1;
      end
      if( lower < upper )
        dlds_at_sensor(mi, si) = ChangeInLength(data(lower:upper,si), threshold_percent);
      end
    end

    % amp & amp_at_sensor
    lower = step_starts(mi);
    upper = step_ends(mi);
    if(upper > num_samples)
      upper = num_samples;
      %fprintf('upper > num_samples!\n');
    end
    if(lower < upper)
      amp_at_sensor(mi, si) = max(data(lower:upper, si));
      running_amp_sum = running_amp_sum + max(data(lower:upper, si));
    end
  end

  amp(mi) = running_amp_sum/num_sensors;

  if(mi+1 < num_steps)
    dlds(mi) = (step_starts(mi+2) - step_starts(mi+1)) - (step_starts(mi+1) - step_starts(mi));
  end
end

% now that we've calculated all of the amp_at_sensor values, we use them
% to calculate the lateral_at_sensor and lateral values
%fprintf('  lateral\n');
for mi=1:num_steps
  % Nifty little bit of code here essentially does a cross product of the
  % left_sensor_amp and right_sensor_amp vectors using the division function
  % between them (L ./ R)
  %left_sensor_amp = amp_at_sensor(mi, outer_side_indices)';
  %right_sensor_amp = amp_at_sensor(mi, inner_side_indices);
  %L = repmat(left_sensor_amp, 1, length(right_sensor_amp));
  %R = repmat(right_sensor_amp, length(left_sensor_amp), 1);
  %lateral_at_sensor(mi, outer_side_indices, inner_side_indices) = L - R;

  % We only use config.outer_side_indices and config.inner_side_indices to
  % accurately describe the lateral difference
  lateral(mi) = mean(amp_at_sensor(mi,config.outer_side_indices)) - mean(amp_at_sensor(mi, config.inner_side_indices));
end

%fprintf('  heeltoe\n');
% Compute the land_at_sensor values by inspecting the step 
land_at_sensor = nan(num_steps, num_sensors);
for mi=1:num_steps
  for si=1:num_sensors
    lower = step_starts(mi) - 1;
    upper = step_ends(mi) + 1;
    if(upper > num_samples)
      upper = num_samples;
      %fprintf('upper > num_samples!\n');
    end
    if(lower < upper)
      threshold = threshold_percent * max(data(lower:upper, si));
      for di=lower:upper
        if(data(di, si) > threshold)
          land_at_sensor(mi, si) = di;
          break;
        end
      end
    end
  end
end

for mi=1:num_steps
  % Nifty little bit of code here essentially does a cross product of the
  % heel_sensor_land and toe_sensor_land vectors for a given step using the
  % subtraction function between them (H - T)
  heel_sensor_land = land_at_sensor(mi, heel_side_indices)';
  toe_sensor_land = land_at_sensor(mi, toe_side_indices);
  %H = repmat(heel_sensor_land, 1, length(toe_sensor_land));
  %T = repmat(toe_sensor_land, length(heel_sensor_land), 1);
  %heeltoe_at_sensor(mi, heel_side_indices, toe_side_indices) = H - T;

  % Use only config.heel_side_indices and config.toe_sideindices to accurately
  % define the heeltoe metric
  heel_sensor_land = land_at_sensor(mi, config.heel_side_indices);
  toe_sensor_land = land_at_sensor(mi, config.toe_side_indices);

  % Use mean instead of min because min was much too noisy
  heeltoe(mi) = mean(heel_sensor_land(~isnan(heel_sensor_land))) - mean(toe_sensor_land(~isnan(toe_sensor_land)));
end

% After we've effectively measured land_at_sensor and heeltoe, we set all
% nan values in land_at_sensor (i.e. those sensors that never saw a rise in
% pressure above the threshold) to 0.
land_at_sensor(isnan(land_at_sensor)) = 0;

end


function dlds = ChangeInLength(data, threshold_percent);
% ChangeInLength
%    ChangeInLength(D, T) finds the change in length of steps between each
%    step in the raw data, D. The start of a step occurs when the signal
%    in D rises above T*max(D). The step ends when the signal in D falls
%    below T*max(D).

threshold = threshold_percent*max(data);

% set stepping flags
marked_in_air = (data(1) <= threshold);
in_air = (data(1) <= threshold);
%in_air = false;
%marked_in_air = false;

num_samples = length(data);

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
      step_start_sum(number_of_steps) = i;
      %plot([i i],[min_amplitude max_amplitude],'-g');
    end

  % data is on the ground, pressure is now relieving (step ending)
  %elseif(~in_air(sensor_index) && data(i,sensor_index) <= threshold_step)
  elseif(~in_air && data(i) <= threshold)
    in_air = true;
    if(~marked_in_air)
      marked_in_air = true;

      % update so we know where the step ends
      if(number_of_steps ~= 0)
        step_end_sum(number_of_steps) = i;
        %plot([i i],[min_amplitude max_amplitude],'-r');
        %fprintf('sensor : step @ %d, time %f\n', i, time(i));
      end
    end
  end
end

%fprintf('number_of_steps = %d, \n', number_of_steps);
if(number_of_steps < 3)
  % TODO If dlds cannot be measured at a given sensor (due to missing a step),
  % technically that sensor shoudl still trigger once the following step comes,
  % effectively doubling its measured dlds value. For simplicity, we just set
  % dlds to 0.
  dlds = 0; %nan; %-9999
else
  dlds = (step_start_sum(3) - step_start_sum(2)) - (step_start_sum(2) - step_start_sum(1));
end

end
