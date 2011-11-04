function [s ...
          v ...
          m ...
          dlds_at_sensor ...
          amp_at_sensor ...
          land_at_sensor] = RemoveSample(s_0, ...
                                         v_0, ...
                                         dlds_at_sensor_0, ...
                                         amp_at_sensor_0, ...
                                         land_at_sensor_0, ...
                                         K, ...
                                         data, ...
                                         step_starts, ...
                                         step_ends, ...
                                         dlds, ...
                                         amp, ...
                                         lateral, ...
                                         heeltoe);
  THRESHOLD_FRACTION = 0.15;
  TESTING_PORTION = 0.2;

  LoadConstants;

  [num_inputs num_feet] = size(data);
  num_steps_per_set = zeros(num_inputs, num_feet);
  for i = 1:num_inputs
    for j = 1:num_feet
      num_steps_per_set(i,j) = length(step_starts{i,j});
    end
  end

  [num_samples num_sensors] = size(s_0);
  [num_steps nada] = size(dlds_at_sensor_0);
  s = logical(ones(num_samples*num_sensors, num_samples, num_sensors));
  m = zeros(num_samples*num_sensors, 4);
  dlds_at_sensor = zeros(num_samples*num_sensors, num_steps, num_sensors);
  amp_at_sensor = zeros(num_samples*num_sensors, num_steps, num_sensors);
  land_at_sensor = zeros(num_samples*num_sensors, num_steps, num_sensors);

  samples_removed = 0;
  for j = 1:num_samples
    for k = 1:num_sensors
      % ignore sample if it's already in the removed list
      if ~s_0(j,k)
        continue;
      end
      % ignore sample if it's not a valid sample
      if ~v_0(j,k)
        continue;
      end

      % try removing this sample
      samples_removed = samples_removed + 1;
      s(samples_removed,:,:) = s_0;
      s(samples_removed,j,k) = 0;

      dlds_at_sensor(samples_removed,:,:) = dlds_at_sensor_0;
      amp_at_sensor(samples_removed,:,:) = amp_at_sensor_0;
      land_at_sensor(samples_removed,:,:) = land_at_sensor_0;

      % augment the _at_sensor values for this sample
      for input_i = 1:num_inputs
        for foot_i = 1:num_feet
          step_offset = sum(sum(num_steps_per_set(1:(input_i-1), :)));
          step_offset = step_offset + sum(num_steps_per_set(input_i, 1:(foot_i-1)));
          for step_i = 1:num_steps_per_set(input_i, foot_i)
            flattened_step_i = step_i + step_offset;
            sample_i = step_starts{input_i, foot_i}(step_i) + j;
            if sample_i <= step_ends{input_i, foot_i}(step_i)
              v_temp = logical(v_0(:,k));
              v_temp(j) = 0;

              % augment dlds
              if step_i+2 <= num_steps_per_set(input_i, foot_i)
                lower1 = step_starts{input_i, foot_i}(step_i);
                upper1 = step_ends{input_i, foot_i}(step_i);
                lower2 = step_starts{input_i, foot_i}(step_i+1);
                upper2 = step_ends{input_i, foot_i}(step_i+1);
                lower3 = step_starts{input_i, foot_i}(step_i+2);
                upper3 = step_ends{input_i, foot_i}(step_i+2);

                data_temp1 = data{input_i, foot_i}(lower1:upper1, k);
                data_temp2 = data{input_i, foot_i}(lower2:upper2, k);
                data_temp3 = data{input_i, foot_i}(lower3:upper3, k);

                data_temp1(v_temp(1:(upper1-lower1))) = nan;
                data_temp2(v_temp(1:(upper2-lower2))) = nan;
                data_temp3(v_temp(1:(upper3-lower3))) = nan;

                zero1 = zeros(lower2-upper1-1,1);
                zero2 = zeros(lower3-upper2-1,1);

                new_dlds = ChangeInLength( ...
                    [data_temp1; zero1; data_temp2; zero2; data_temp3], ...
                    THRESHOLD_FRACTION);

                dlds_at_sensor(samples_removed, flattened_step_i, k) = new_dlds;
              end

              % augment amp
              lower = step_starts{input_i, foot_i}(step_i);
              upper = step_ends{input_i, foot_i}(step_i);

              subset_data = data{input_i, foot_i}(lower : upper, k);
              valid_data = subset_data(v_temp(1:(upper - lower)));

              [num_new_samples nada] = size(valid_data);
              if num_new_samples == 0
                amp_at_sensor(samples_removed, flattened_step_i, k) = 0;
              else
                new_amp = max(valid_data);
                amp_at_sensor(samples_removed, flattened_step_i, k) = new_amp;
              end

              % augment land
              new_land = 0;
              threshold = THRESHOLD_FRACTION * ...
                  max(data{input_i, foot_i}(lower : upper, k));
              for di=lower:upper
                if v_temp(di - lower + 1) & data{input_i, foot_i}(di, k) > threshold
                  new_land = di;
                  break;
                end
              end
              land_at_sensor(samples_removed, flattened_step_i, k) = new_land;
            end
          end
        end
      end

      % compute prediction errors
      dlds_errors = ComputeLinearPredictionError(dlds, ...
          squeeze(dlds_at_sensor(samples_removed,:,:)), dlds, ...
          squeeze(dlds_at_sensor(samples_removed,:,:)));
      amp_errors = ComputeLinearPredictionError(amp, ...
          squeeze(amp_at_sensor(samples_removed,:,:)), amp, ...
          squeeze(amp_at_sensor(samples_removed,:,:)));
      lateral_errors = ComputeLinearPredictionError(lateral, ...
          squeeze(amp_at_sensor(samples_removed,:,:)), lateral, ...
          squeeze(amp_at_sensor(samples_removed,:,:)));
      heeltoe_errors = ComputeLinearPredictionError(heeltoe, ...
          squeeze(land_at_sensor(samples_removed,:,:)), heeltoe, ...
          squeeze(land_at_sensor(samples_removed,:,:)));

      % combine errors
      m(samples_removed,1) = CombineErrors(dlds_errors);
      m(samples_removed,2) = CombineErrors(amp_errors);
      m(samples_removed,3) = CombineErrors(lateral_errors);
      m(samples_removed,4) = CombineErrors(heeltoe_errors);
    end
  end

  % strip off trailing predictions from initialization
  m = m(1:samples_removed,:);

  % rank predictors
  [ranked_indices, thresholds_reached] = ...
      RankByThresholdDirection(m, ...
                               config.ranking_error_thresholds, ...
                               config.ranking_error_directions);

  % keep at most top K predictors
  if samples_removed > K
    ranked_indices = ranked_indices(1:K);
  end
  m = m(ranked_indices,:);
  s = s(ranked_indices,:,:);
  dlds_at_sensor = dlds_at_sensor(ranked_indices,:,:);
  amp_at_sensor = amp_at_sensor(ranked_indices,:,:);
  land_at_sensor = land_at_sensor(ranked_indices,:,:);

  % invalidate samples that are predictors
  v = logical(ones(length(ranked_indices), num_samples, num_sensors));
  for i = 1:length(ranked_indices)
    v(i,:,:) = v_0;
    v(i,~s(i,:)) = 0;
  end
