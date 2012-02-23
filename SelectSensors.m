function [s v m] = SelectSensors(sensors_to_add, ...
                                 g, ...
                                 K1, ...
                                 K2, ...
                                 dlds, ...
                                 amp, ...
                                 lateral, ...
                                 heeltoe, ...
                                 dlds_at_sensor, ...
                                 amp_at_sensor, ...
                                 land_at_sensor, ...
                                 greed_choice)
% SelectSensors Returns top K sets of predictors.
%
% -------
% INPUTS:
% -------
%
%   sensors_to_add: number of steps to take (total number
%                      of sensors to select)
%   g: logical adjacency matrix
%      i: sensor
%      j: sensor
%         -- 1 if sensors i and j give similar predictions
%            for all metrics
%   K1: number of new predictor sets to return for each call
%   K2: number of new predictor sets to return for each step
%   dlds...heeltoe: metrics to predict
%   *_at_sensor: predictor metrics at each sensor
%   greed_choice: 'greedy', 'rep', or 'greedy-rep' from GetIndices.m
%
% --------
% OUTPUTS:
% --------
%
% s: ranked vector of logical vectors of new predictors
%    i -- step
%    j -- choice
%    k -- sensor
%      -- 1 if sensor k is a predictor in choice j at step i
% v: logical vectors of new sensor validity
%    i -- step
%    j -- choice
%    k -- sensor
%      -- 1 if sensor k should be considered in choice j at step i
% m: vector of metric prediction errors
%    i -- step
%    j -- choice
%    k -- metric (1:dlds, 2:amp, 3:lateral, 4:heeltoe)
%      -- prediction error of metric k in choice j at step i
  LoadConstants;

  [num_steps num_sensors] = size(dlds_at_sensor);

  s = logical(zeros(sensors_to_add, K2, num_sensors));
  v = logical(ones(sensors_to_add, K2, num_sensors));
  m = zeros(sensors_to_add, K2, 4);

  s_0 = logical(zeros(1, num_sensors));
  v_0 = logical(ones(1, num_sensors));

  h = waitbar(0, '');
  for select = 1:sensors_to_add
    waitbar(0, h, sprintf('... Adding Sensor %d ...', select));

    s_K2 = logical(zeros(K1*K2, num_sensors));
    v_K2 = logical(ones(K1*K2, num_sensors));
    m_K2 = zeros(K1*K2, 4);

    [num_configs nada] = size(s_0);
    next_config = 1;
    for c = 1:num_configs
      waitbar(c / num_configs, h);

      [s_1 v_1 m_1] = AddSensor(s_0(c,:), ...
                                v_0(c,:), ...
                                g, ...
                                K1, ...
                                dlds, ...
                                amp, ...
                                lateral, ...
                                heeltoe, ...
                                dlds_at_sensor, ...
                                amp_at_sensor, ...
                                land_at_sensor, ...
                                greed_choice);
      [configs_added nada] = size(s_1);

      s_K2(next_config:(next_config+configs_added-1),:) = s_1;
      v_K2(next_config:(next_config+configs_added-1),:) = v_1;
      m_K2(next_config:(next_config+configs_added-1),:) = m_1;

      next_config = next_config + configs_added;
    end

    % strip off trailing predictions from initialization
    m_K2 = m_K2(1:next_config-1,:);

    % rank predictors
    [ranked_indices, thresholds_reached nada ranked_errors] = ...
        RankByThresholdDirection(m_K2, ...
                                 config.ranking_error_thresholds, ...
                                 config.ranking_error_directions);

    %size(ranked_indices)
    %next_config

    %figure(select);
    %hist(ranked_errors);
    %title(sprintf('select %d', select));

    % keep at most top K2 predictors
    if next_config-1 > K2
      %ranked_indices = ranked_indices(1:K2)e
      ranked_indices = ranked_indices(GetIndices(K, length(ranked_indices), greed_choice));
    end
    s_0 = s_K2(ranked_indices,:);
    v_0 = v_K2(ranked_indices,:);
    m_0 = m_K2(ranked_indices,:);

    s(select,:,:) = s_0;
    v(select,:,:) = v_0;
    m(select,:,:) = m_0;
  end
  close(h)

