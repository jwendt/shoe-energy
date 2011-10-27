function [g] = BuildPredictionDiffGraph(dlds, ...
                                        amp, ...
                                        lateral, ...
                                        heeltoe, ...
                                        dlds_at_sensor, ...
                                        amp_at_sensor, ...
                                        land_at_sensor)
% BuildPredictionDiffGraph Builds a sensor-sensor mapping
%                          of prediction differences between
%                          each sensor pair for each metric. 
%
% -------
% INPUTS:
% -------
%
%   dlds...heeltoe: metrics to predict
%   *_at_sensor: predictor metrics at each sensor
%
% --------
% OUTPUTS:
% --------
%
% g: vector of metric prediction errors
%    i -- sensor
%    j -- sensor
%    k -- metric
%      -- prediction error difference between sensor i and
%         sensor j for metric k
  [num_steps num_sensors] = size(dlds_at_sensor);
  g = zeros(num_sensors, num_sensors, 4);

  dlds_error = zeros(1, num_sensors);
  amp_error = zeros(1, num_sensors);
  lateral_error = zeros(1, num_sensors);
  heeltoe_error = zeros(1, num_sensors);
  for i = 1:num_sensors
    dlds_error(i) = CombineErrors( ...
        ComputeLinearPredictionError(dlds, dlds_at_sensor(:,i),...
                                     dlds, dlds_at_sensor(:,i)));
    amp_error(i) = CombineErrors( ...
        ComputeLinearPredictionError(amp, amp_at_sensor(:,i),...
                                     amp, amp_at_sensor(:,i)));
    lateral_error(i) = CombineErrors( ...
        ComputeLinearPredictionError(lateral, land_at_sensor(:,i),...
                                     lateral, land_at_sensor(:,i)));
    heeltoe_error(i) = CombineErrors( ...
        ComputeLinearPredictionError(heeltoe, land_at_sensor(:,i),...
                                     heeltoe, land_at_sensor(:,i)));
  end

  for i = 1:num_sensors
    for j = 1:num_sensors
      g(i,j,1) = dlds_error(i) - dlds_error(j);
      g(i,j,2) = amp_error(i) - amp_error(j);
      g(i,j,3) = lateral_error(i) - lateral_error(j);
      g(i,j,4) = heeltoe_error(i) - heeltoe_error(j);
    end
  end
