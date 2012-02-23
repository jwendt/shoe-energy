function [indices, thresholds_reached, groupings, errors] = RankByThresholdDirection(observations, thresholds, directions)
% [INDICES, THRESHOLDS_REACHED, GROUPINGS, ERR] =
% RankByThresholdDirection Sorts measurement's rows in ascending order by a
%                          fancy pants algorithm.
%
%    RankByThresholdDirection(OBSERVATIONS, THRESHOLDS, DIRECTIONS) returns a
%    vector of indices corresponding to the top ranked observations given the
%    thresholds and directions provided.
%
%    OBSERVATIONS is a NxM matrix where N is the observations (possibly of
%                 different sensors) and M is the number of metrics observed.
%    THRESHOLDS is a vector of size M containing the error threshold we wish
%               the final sensor set to follow (or be better than).
%    DIRECTIONS is a vector of size M with values -1 and 1, corresponding
%               to minimizing the measurement beyond the given threshold or
%               maximizing the measurement beyond the given threshold.

[num_observations num_metrics] = size(observations);

% Create CDF of each metric in observations, for use in GetPercentileFromCDF
% function
% TODO consider allowing this information to be passed as a parameter in case
%      we wish to only rank a few observations but use CDFs derived from much
%      larger populations
cdf = zeros(num_observations, num_metrics);
for j = 1:num_metrics
  cdf(:,j) = sort(observations(:,j));
end

% Place each row into groupings such that the highest ranked group has all
% metrics on the correct side of the thresholds, the next highest ranked group
% has all but one metric on the correct side of the thresholds, and so on.
%
% groupings{M,1} contains a vector of N observation indices where M-1 metrics
%                are on the wrong side of the threshold.
% groupings{M,2} contains a Nx(M-1) matrix in which the N rows correspond to
%                the N entries in groupings{M,1} and the M-1 columns list the
%                metric indices that are on the incorrect side of the
%                threshold.
% groupings{M,3} contains a vector of that observations total error, ranging
%                from 0 to 1 and normalized using the metric's CDF.
num_groupings = num_metrics + 1;
groupings = cell(num_groupings, 3);
COL_OBSERVATION = 1;
COL_METRIC      = 2;
COL_ERROR       = 3;

for i = 1:num_observations
  grouping = 1;
  metric_index = [];
  for j = 1:num_metrics
    % Check if observation is on the incorrect side of the threshold
    if directions(j)*observations(i,j) < directions(j)*thresholds(j)
      grouping = grouping + 1;
      metric_index = [metric_index j];
    end
  end
  % Append the observation index i and its corresponding incorrect metrics to
  % the corresponding grouping
  groupings{grouping, COL_OBSERVATION} = [groupings{grouping, COL_OBSERVATION}; i];
  groupings{grouping, COL_METRIC} = [groupings{grouping, COL_METRIC}; metric_index];

  % Calculate error for the given grouping
  [grouping_observation num_incorrect_metrics] = size(groupings{grouping, COL_METRIC});
  if num_incorrect_metrics == 0
    % All metrics are on the correct side of the metric, err can now be treated
    % as how far away we are from +/-Inf. Simpler solution is to calculate
    % distance from thresholds (using percentiles) and treat err = 1 - distance
    % since the farther the distance, the better!
    % TODO is this the best way to do this?
    grouping_observation = length(groupings{grouping, COL_OBSERVATION});
    distance = 0;
    for k = 1:num_metrics
      % Since all metrics ar eon correct side, we measure all metrics (i.e.
      % 1:num_metrics).
      observation = groupings{grouping, COL_OBSERVATION}(grouping_observation,1);
      value = observations(observation, k);
      distance = distance + (1/num_metrics)*abs(GetPercentileFromCDF(value, cdf(:,k)) - GetPercentileFromCDF(thresholds(k), cdf(:,k)));
    end
    % The following err equation works since the farthest distance we can get
    % from the threshold is 1 (using GetPercentileFromCDF), thus an err value
    % of 0 (ranked best).
    err = 1 - distance;
    groupings{grouping, COL_ERROR} = [groupings{grouping, COL_ERROR}; err];
  elseif num_incorrect_metrics > 0
    % At least one metric is not on the correct side of the threshold
    observation = groupings{grouping, COL_OBSERVATION}(grouping_observation,1);
    err = 0;
    for k = 1:num_incorrect_metrics
      metric = groupings{grouping, COL_METRIC}(grouping_observation,k);
      value = observations(observation, metric);

      % Normalize the error between the observed value and the threshold using
      % GetPercentileFromCDF and divide by the number of incorrect metrics so that our
      % err value never exceeds 1.
      err = err + (1/num_incorrect_metrics)*abs(GetPercentileFromCDF(value, cdf(:,metric)) - GetPercentileFromCDF(thresholds(metric), cdf(:,metric)));
    end
    groupings{grouping, COL_ERROR} = [groupings{grouping, COL_ERROR}; err];
  end
end

% Simply sort each grouping individually and append (in order from first
% grouping to last) to final index vector
% TODO handle ties correctly
indices = [];
errors = [];
for i = 1:num_groupings
  [sorted_errors sorted_indices] = sort(groupings{i, COL_ERROR});
  if ~isempty(sorted_indices)
    indices = [indices; groupings{i, COL_OBSERVATION}(sorted_indices,1)];
    errors = [errors; sorted_errors];
  end
end

% Set thresholds_reached if an observation lies on the correct side of all of
% the thresholds
if isempty(groupings{1,1})
  thresholds_reached = false;
else
  thresholds_reached = true;
end
