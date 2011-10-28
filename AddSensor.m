function [s v m] = AddSensor(s_0, ...
                             v_0, ...
                             g, ...
                             K, ...
                             dlds, ...
                             amp, ...
                             lateral, ...
                             heeltoe, ...
                             dlds_at_sensor, ...
                             amp_at_sensor, ...
                             land_at_sensor)
% AddSensor Returns top K sets of predictors by adding 
%           one more predictor to the input set.
%
% -------
% INPUTS:
% -------
%
%   s_0: logical vector of previous predictors
%        i -- sensor
%          -- 1 if sensor i has been chosen
%   v_0: logical vector of previous sensor validity
%        i -- sensor
%          -- 1 if sensor i should be considered
%   g: logical adjacency matrix
%      i -- sensor
%      j -- sensor
%        -- 1 if sensors i and j give similar predictions
%           for all metrics
%   K: number of new predictor sets to return
%   dlds...heeltoe: metrics to predict
%   *_at_sensor: predictor metrics at each sensor
%
% --------
% OUTPUTS:
% --------
%
% s: ranked logical vectors of new predictors
%    i -- choice
%    j -- sensor
%      -- 1 if sensor j is a predictor in choice i
% v: ranked logical vectors of new sensor validity
%    i -- choice
%    j -- sensor
%      -- 1 if sensor j should be considered in choice i
% m: ranked vector of metric prediction errors
%    i -- choice
%    j -- metric
%      -- prediction error of metric j in choice i
  LoadConstants;

  num_sensors = length(g);

  s = logical(zeros(num_sensors, num_sensors));
  m = zeros(num_sensors, 4);

  sensors_added = 0;
  for j = 1:num_sensors
    % ignore sensor if it's already in the chosen list
    if s_0(j)
      continue;
    end
    % ignore sensor if it's not a valid sensor
    if ~v_0(j)
      continue;
    end

    % try adding this sensor
    sensors_added = sensors_added + 1;
    s(sensors_added,:) = s_0;
    s(sensors_added,j) = 1;

    % compute prediction errors
    dlds_errors = ComputeLinearPredictionError(dlds, ...
        dlds_at_sensor(:,s(sensors_added,:)), dlds, ...
        dlds_at_sensor(:,s(sensors_added,:)));
    amp_errors = ComputeLinearPredictionError(amp, ...
        amp_at_sensor(:,s(sensors_added,:)), amp, ...
        amp_at_sensor(:,s(sensors_added,:)));
    lateral_errors = ComputeLinearPredictionError(lateral, ...
        amp_at_sensor(:,s(sensors_added,:)), lateral, ...
        amp_at_sensor(:,s(sensors_added,:)));
    heeltoe_errors = ComputeLinearPredictionError(heeltoe, ...
        land_at_sensor(:,s(sensors_added,:)), heeltoe, ...
        land_at_sensor(:,s(sensors_added,:)));

    % combine errors
    m(sensors_added,1) = CombineErrors(dlds_errors);
    m(sensors_added,2) = CombineErrors(amp_errors);
    m(sensors_added,3) = CombineErrors(lateral_errors);
    m(sensors_added,4) = CombineErrors(heeltoe_errors);
  end

  % strip off trailing predictions from initialization
  m = m(1:sensors_added,:);

  % rank predictors
  [ranked_indices, thresholds_reached] = ...
      RankByThresholdDirection(m, ...
                               config.ranking_error_thresholds, ...
                               config.ranking_error_directions);

  % keep at most top K predictors
  if sensors_added > K
    ranked_indices = ranked_indices(1:K);
  end
  m = m(ranked_indices,:);
  s = s(ranked_indices,:);

  % invalidate sensors that are either predictors or
  % connected to predictors
  v = logical(zeros(length(ranked_indices), num_sensors));
  for i = 1:length(ranked_indices)
    v(i,:) = v_0;
    v(i,s(i,:)) = 0;
    for j = 1:num_sensors
      v(i,j) = ~logical(sum(g(s(i,:),j)));
    end
  end
