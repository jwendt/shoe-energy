function [s s_v m] = AddSensor(s_0, ...
                               s_v0, ...
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
%   s_0: vector of previous predictors
%        i -- sensor
%          -- 1 if sensor i has been chosen
%   v_0: vector of previous sensor validity
%        i -- sensor
%          -- 1 if sensor i should be considered
%   g: adjacency matrix
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
% s: vectors of new predictors
%    i -- choice
%    j -- sensor
%      -- 1 if sensor j is a predictor in choice i
% v: vectors of new sensor validity
%    i -- choice
%    j -- sensor
%      -- 1 if sensor j should be considered in choice i
% m: vector of metric prediction errors
%    i -- choice
%    j -- metric
%      -- prediction error of metric j in choice i
%
% ------------
% CONSTRAINTS:
% ------------
%
% required globals:
%   -- dlds
%   -- amp
%   -- lateral
%   -- heeltoe
%   -- dlds_at_sensor
%   -- amp_at_sensor
%   -- land_at_sensor
%   -- RANKING_ERROR_THRESHOLDS
%   -- RANKING_ERROR_DIRECTIONS

  num_sensors = length(g);

  s = zeros(num_sensors, num_sensors);
  m = zeros(num_sensors, 4);

  sensors_added = 0;
  for j = 1:num_sensors
    % ignore sensor if it's already in the chosen list
    if s_0(j) == 1
      continue;
    end
    % ignore sensor if it's not a valid sensor
    if v_0(j) == 0
      continue;
    end

    % try adding this sensor
    s(sensors_added,:) = s_0;
    s(sensors_added,j) = 1;

    % compute prediction errors
    dlds_errors = ComputePredictionError(dlds, ...
        dlds_at_sensor([s_0 s]));
    amp_errors = ComputePredictionError(amp, ...
        amp_at_sensor([s_0 s]));
    lateral_errors = ComputePredictionError(lateral, ...
        land_at_sensor([s_0 s]));
    heeltoe_errors = ComputePredictionError(heeltoe, ...
        land_at_sensor([s_0 s]));

    % combine errors
    m(sensors_added,:) = CombineErrors(dlds_errors, ...
                                       amp_errors, ...
                                       lateral_errors, ...
                                       heeltoe_errors);
    sensors_added = sensors_added + 1;
  end

  % strip off trailing predictions from initialization
  m = m(1:count,:);

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
  v = zeros(length(ranked_indices), num_sensors);
  for i = 1:length(s)
    v(i,:) = v_0;
    v(i,s(i,:)) = 0;
    for j = 1:num_sensors
      v(g(s(i,:),j) == 1) = 0;
    end
  end

% Compute RMS errors
function m = CombineErrors(dlds_errors, ...
                           amp_errors, ...
                           lateral_errors, ...
                           heeltoe_errors)
  m = zeros(1, 4);
  m(1) = sqrt(sum(dlds_errors.^2) / length(dlds_errors));
  m(2) = sqrt(sum(amp_errors.^2) / length(amp_errors));
  m(3) = sqrt(sum(lateral_errors.^2) / length(lateral_errors));
  m(4) = sqrt(sum(heeltoe_errors.^2) / length(heeltoe_errors));
