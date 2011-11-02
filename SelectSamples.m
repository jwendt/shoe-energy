function [s v m] = SelectSamples(samples_to_remove, ...
                                 sensors, ...
                                 K1, ...
                                 K2, ...
                                 data, ...
                                 step_starts, ...
                                 step_ends, ...
                                 threshold_percent, ...
                                 dlds, ...
                                 amp, ... 
                                 lateral, ...
                                 heeltoe)
  LoadConstants;

  num_samples = max(step_starts - step_ends);
  num_sensors = length(find(sensors));

  s = logical(ones(samples_to_remove, K2, num_samples, num_sensors));
  v = logical(ones(samples_to_remove, K2, num_samples, num_sensors));
  m = zeros(samples_to_remove, K2, 4);

  s_0 = logical(ones(1, num_samples, num_sensors));
  v_0 = logical(ones(1, num_samples, num_sensors));

  h = waitbar(0, '');
  for select = 1:samples_to_remove
    waitbar(0, h, sprintf('... Removing Sensor %d ...', select));

    s_K2 = logical(ones(K1*K2, num_samples, num_sensors));
    v_K2 = logical(ones(K1*K2, num_samples, num_sensors));
    m_K2 = zeros(K1*K2, 4);

    [num_configs nada1 nada2] = size(s_0);
    next_config = 1;
    for c = 1:num_configs
      waitbar(c / num_configs, h);
      
      [s_1 v_1 m_1] = RemoveSample(s_0(c,:,:), ...
                                   v_0(c,:,:), ...
                                   K1, ...
                                   data, ...
                                   step_starts, ...
                                   step_ends, ...
                                   threshold_percent, ...
                                   dlds, ...
                                   amp, ...
                                   lateral, ...
                                   heeltoe);
      [configs_added nada1 nada2] = size(s_1);

      s_K2(next_config:(next_config*configs_added-1),:,:) = s_1;
      v_K2(next_config:(next_config*configs_added-1),:,:) = v_1;
      m_K2(next_config:(next_config*configs_added-1),:) = m_1;

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

    s(select,:,:,:) = s_0;
    v(select,:,:,:) = v_0;
    m(select,:,:) = m_0;
  end
  close(h)

