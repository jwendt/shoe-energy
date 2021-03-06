function [s ...
          v ...
          m ...
          dlds_at_sensor ...
          amp_at_sensor ...
          land_at_sensor] = SelectSamples(samples_to_remove, ...
                                          K1, ...
                                          K2, ...
                                          data, ...
                                          step_starts, ...
                                          step_ends, ...
                                          dlds_at_sensor_in, ...
                                          amp_at_sensor_in, ...
                                          land_at_sensor_in, ...
                                          dlds, ...
                                          amp, ... 
                                          lateral, ...
                                          heeltoe)
% samples_to_remove is 412 (or 412/4?)
%
% data comes from train_data from GetMetrics
%
% step_starts comes from train_step_starts from GetMetrics
%
% step_ends comes from train_step_starts from GetMetrics
%
% *_at_sensor_in is a subset of dlds_at_sensor(:,cols) where cols is some
% number of wants sensors
%
% dlds,amp,lateral,heeltoe are the regular vectors used everywhere
%
%
%
%
%
  LoadConstants;

  [num_inputs num_feet] = size(step_ends);
  num_samples = 0;
  for i = 1:num_inputs
    for j = 1:num_feet
      if num_samples < max(step_ends{i,j} - step_starts{i,j}) + 1
        num_samples = max(step_ends{i,j} - step_starts{i,j}) + 1;
      end
    end
  end

  [num_steps num_sensors] = size(dlds_at_sensor_in);

  s = logical(ones(samples_to_remove, K2, num_samples, num_sensors));
  v = logical(ones(samples_to_remove, K2, num_samples, num_sensors));
  m = zeros(samples_to_remove, K2, 4);
  dlds_at_sensor = zeros(samples_to_remove, K2, num_steps, num_sensors);
  amp_at_sensor = zeros(samples_to_remove, K2, num_steps, num_sensors);
  land_at_sensor = zeros(samples_to_remove, K2, num_steps, num_sensors);

  s_0 = logical(ones(1, num_samples, num_sensors));
  v_0 = logical(ones(1, num_samples, num_sensors));
  dlds_at_sensor_0 = zeros(1, num_steps, num_sensors);
  amp_at_sensor_0 = zeros(1, num_steps, num_sensors);
  land_at_sensor_0 = zeros(1, num_steps, num_sensors);

  dlds_at_sensor_0(1,:,:) = dlds_at_sensor_in;
  amp_at_sensor_0(1,:,:) = amp_at_sensor_in;
  land_at_sensor_0(1,:,:) = land_at_sensor_in;

  h = waitbar(0, '');
  h2 = waitbar(0, '');
  for select = 159:samples_to_remove
    waitbar(0, h, sprintf('... Removing Sample %d ...', select));

    s_K2 = logical(ones(K1*K2, num_samples, num_sensors));
    v_K2 = logical(ones(K1*K2, num_samples, num_sensors));
    m_K2 = zeros(K1*K2, 4);
    dlds_at_sensor_K2 = zeros(K1*K2, num_steps, num_sensors);
    amp_at_sensor_K2 = zeros(K1*K2, num_steps, num_sensors);
    land_at_sensor_K2 = zeros(K1*K2, num_steps, num_sensors);

    [num_configs nada1 nada2] = size(s_0);
    next_config = 1;
    for c = 1:num_configs
      waitbar((c-1) / num_configs, h);
      waitbar(0, h2, sprintf('... Trying Config %d/%d ...', c, num_configs));

      [s_1 ...
       v_1 ...
       m_1 ...
       dlds_at_sensor_1 ...
       amp_at_sensor_1 ...
       land_at_sensor_1] = RemoveSample(squeeze(s_0(c,:,:)), ...
                                        squeeze(v_0(c,:,:)), ...
                                        squeeze(dlds_at_sensor_0(c,:,:)), ...
                                        squeeze(amp_at_sensor_0(c,:,:)), ...
                                        squeeze(land_at_sensor_0(c,:,:)), ...
                                        K1, ...
                                        data, ...
                                        step_starts, ...
                                        step_ends, ...
                                        dlds, ...
                                        amp, ...
                                        lateral, ...
                                        heeltoe, ...
                                        h2);
      [configs_added nada1 nada2] = size(s_1);

      s_K2(next_config:(next_config+configs_added-1),:,:) = s_1;
      v_K2(next_config:(next_config+configs_added-1),:,:) = v_1;
      m_K2(next_config:(next_config+configs_added-1),:) = m_1;
      dlds_at_sensor_K2(next_config:(next_config+configs_added-1),:,:) = ...
          dlds_at_sensor_1;
      amp_at_sensor_K2(next_config:(next_config+configs_added-1),:,:) = ...
          amp_at_sensor_1;
      land_at_sensor_K2(next_config:(next_config+configs_added-1),:,:) = ...
          land_at_sensor_1;

      next_config = next_config + configs_added;
    end

    % strip off trailing predictions from initialization
    m_K2 = m_K2(1:next_config-1,:);

    % rank predictors
    [ranked_indices, thresholds_reached] = ...
        RankByThresholdDirection(m_K2, ...
                                 config.ranking_error_thresholds, ...
                                 config.ranking_error_directions);

    % keep at most top K2 predictors
    if next_config-1 > K2
      ranked_indices = ranked_indices(1:K2);
    end
    s_0 = s_K2(ranked_indices,:,:);
    v_0 = v_K2(ranked_indices,:,:);
    m_0 = m_K2(ranked_indices,:);
    dlds_at_sensor_0 = dlds_at_sensor_K2(ranked_indices,:,:);
    amp_at_sensor_0 = amp_at_sensor_K2(ranked_indices,:,:);
    land_at_sensor_0 = land_at_sensor_K2(ranked_indices,:,:);

    s(select,:,:,:) = s_0;
    v(select,:,:,:) = v_0;
    m(select,:,:) = m_0;
    dlds_at_sensor(select,:,:,:) = dlds_at_sensor_0;
    amp_at_sensor(select,:,:,:) = amp_at_sensor_0;
    land_at_sensor(select,:,:,:) = land_at_sensor_0;
  end
  close(h)
  close(h2)
