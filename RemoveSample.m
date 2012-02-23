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
                                         heeltoe, ...
                                         h);
  THRESHOLD_FRACTION = 0.15;
  TESTING_PORTION = 0.2;
  EXTRA = 20;

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
  for j = 1:(num_samples/4)
    for k = 1:num_sensors
      waitbar(((j-1)*num_sensors+(k-1))/(num_samples/4*num_sensors), h);
      % ignore sample if it's already in the removed list
      if ~s_0((j-1)*4+1,k)
        continue;
      end
      % ignore sample if it's not a valid sample
      if ~v_0((j-1)*4+1,k)
        continue;
      end

      % try removing this sample
      samples_removed = samples_removed + 1;
      s(samples_removed,:,:) = s_0;
      s(samples_removed,(j-1)*4+1,k) = 0;
      s(samples_removed,(j-1)*4+2,k) = 0;
      s(samples_removed,(j-1)*4+3,k) = 0;
      s(samples_removed,(j-1)*4+4,k) = 0;

      dlds_at_sensor(samples_removed,:,:) = dlds_at_sensor_0;
      amp_at_sensor(samples_removed,:,:) = amp_at_sensor_0;
      land_at_sensor(samples_removed,:,:) = land_at_sensor_0;

      % augment the _at_sensor values for this sample
      for input_i = 1:num_inputs
        for foot_i = 1:num_feet
          % calculate step offset as steps in all previous inputs
          % plus step in previous foot (if applicable)
          step_offset = sum(sum(num_steps_per_set(1:(input_i-1), :)));
          step_offset = step_offset + ...
              sum(num_steps_per_set(input_i, 1:(foot_i-1)));

          % remove sample from all steps (augment predictors)
          for step_i = 1:num_steps_per_set(input_i, foot_i)
            flattened_step_i = step_i + step_offset;
            sample_i = step_starts{input_i, foot_i}(step_i) + j;
            if sample_i <= step_ends{input_i, foot_i}(step_i)
              % augment dlds
              if step_i+1 < num_steps_per_set(input_i, foot_i)
                lower1 = step_starts{input_i, foot_i}(step_i);
                upper1 = step_ends{input_i, foot_i}(step_i);
                lower2 = step_starts{input_i, foot_i}(step_i+1);
                upper2 = step_ends{input_i, foot_i}(step_i+1);
                lower3 = step_starts{input_i, foot_i}(step_i+2);
                upper3 = step_ends{input_i, foot_i}(step_i+2);

                data1 = data{input_i, foot_i}(lower1:upper1, k);
                data2 = data{input_i, foot_i}(lower2:upper2, k);
                data3 = data{input_i, foot_i}(lower3:upper3, k);

                data1(~s(samples_removed,1:(upper1-lower1+1),k)) = nan;
                data2(~s(samples_removed,1:(upper2-lower2+1),k)) = nan;
                data3(~s(samples_removed,1:(upper3-lower3+1),k)) = nan;

                if step_i > 1
                  data0 = data{input_i, foot_i}(lower1-EXTRA:(lower1-1), k);
                else
                  data0 = zeros(0,1);
                end
                if step_i+2 < num_steps_per_set(input_i, foot_i)
                  data4 = data{input_i, foot_i}((upper3+1):upper3+EXTRA, k);
                else
                  data4 = zeros(0,1);
                end

                zero1 = zeros(lower2-upper1-1,1);
                zero2 = zeros(lower3-upper2-1,1);

                new_data = [data0; data1; zero1; data2; zero2; data3; data4];

                dlds_at_sensor(samples_removed, flattened_step_i, k) = ...
                    ChangeInLength(new_data, THRESHOLD_FRACTION);
              end

              % augment amp
              lower = step_starts{input_i, foot_i}(step_i);
              upper = step_ends{input_i, foot_i}(step_i);

              subset_data = data{input_i, foot_i}(lower:upper, k);
              valid_data = subset_data( ...
                  s(samples_removed,1:(upper-lower+1),k));

              [num_new_samples nada] = size(valid_data);
              if num_new_samples == 0
                amp_at_sensor(samples_removed, flattened_step_i, k) = 0;
              else
                amp_at_sensor(samples_removed, flattened_step_i, k) = ...
                    max(valid_data);
              end

              % augment land
              data1 = data{input_i, foot_i}(lower:upper, k);
              if step_i > 1
                new_lower = lower-1;
                data0 = data{input_i, foot_i}(lower-1, k);
              else
                new_lower = lower;
                data0 = zeros(0,1);
              end
              if step_i < num_steps_per_set(input_i, foot_i)
                new_upper = upper+1;
                data2 = data{input_i, foot_i}(upper+1, k);
              else
                new_upper = upper;
                data2 = zeros(0,1);
              end
              data1(~s(samples_removed,1:(upper-lower+1),k)) = nan;
              new_data = [data0; data1; data2];

              new_land = nan;
              threshold = THRESHOLD_FRACTION * max(new_data);
              for di=1:length(new_data)
                if new_data(di) > threshold
                  new_land = di+new_lower-1;
                  break;
                end
              end
              land_at_sensor(samples_removed, flattened_step_i, k) = new_land;

              % interpolate nans in land_at_sensor
              for nan_i=1:size(land_at_sensor,3)
                dd = land_at_sensor(samples_removed,:,nan_i);
                dd_x = find(~isnan(dd));
                dd_y = dd(~isnan(dd));
                if(size(dd_y,1) > 1)
                  yi = interp1(dd_x,dd_y,1:length(dd));
                  land_at_sensor(samples_removed,:,nan_i) = yi;
                else
                  land_at_sensor(samples_removed,:,nan_i) = 0;
                end
              end

              % finish interpolation
              %col = 1;
              %while col <= size(land_at_sensor,3)
              %  row = 1;
              %  while row <= size(land_at_sensor,2)
              %    nan_start = row;
              %    non_nan = row;
              %    while non_nan <= size(land_at_sensor,2) && ...
              %        isnan(land_at_sensor(samples_removed, non_nan, col))
              %      non_nan = non_nan + 1;
              %    end
              %    if non_nan > size(land_at_sensor, 2)
              %      land_at_sensor(samples_removed, ...
              %                     nan_start:non_nan-1,col) = ...
              %          land_at_sensor(samples_removed, nan_start-1,col);
              %    else
              %      land_at_sensor(samples_removed, ...
              %                     nan_start:non_nan-1,col) = ...
              %          land_at_sensor(samples_removed, non_nan, col);
              %    end
              %    row = non_nan+1;
              %  end
              %  col = col + 1;
              %end

              % sanity check
              land_at_sensor(samples_removed, ...
                  isnan(land_at_sensor(samples_removed,:,:))) = 0;
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
