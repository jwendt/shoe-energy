function [indices, differences] = RankByThresholdProximity(observations, thresholds)
% RankByThresholdProximity Sorts measurement's rows in ascending order by their
%                          proximity to the desired thresholds.
%
%    RankByThresholdProximity(OBSERVATIONS, THRESHOLDS) returns a
%    list of indices and differences in which the errors most closely match the
%    desired thresholds.
%
%    OBSERVATIONS is a NxM matrix where N is the observations (possibly of
%                 different sensors) M is the number of signals predicted.
%    THRESHOLDS is a vector of size M containing the error threshold we wish
%               the final sensor set to follow.

% Deprecated
%    DIRECTIONS is a vector of size M with values -1, 1, and 0, corresponding
%               to keeping the error below the corresponding threshold, above,
%               or as close to it as possible. In all cases, this function will
%               attempt to keep as close to the threshold as possible, the 0
%               direction simply tries to find the sensor grouping with the
%               smallest absolute distance from the threshold.
%               measurement - threshold difference. 

[num_observations num_metrics] = size(observations);

% Create CDF each column in observations
cdf = zeros(num_observations, num_metrics);
for j = 1:num_metrics
  cdf(:,j) = sort(observations(:,j));
end

% Compute the "error"
differences = zeros(num_observations,1);
for i = 1:num_observations
  for j = 1:num_metrics
    % Here the "difference" is defined by absolute distance from the threshold
    differences(i) = differences(i) + abs(GetPercentileFromCDF(observations(i,j),cdf(:,j)) - GetPercentileFromCDF(thresholds(j), cdf(:,j)));
    %elseif (directions(j)*observations(i,j) > directions(j)*thresholds(j))
    %  % Here the "difference" is defined by absolute distance from the
    %  % thresholds provided that our observations are on the correct side of
    %  % the threshold.
    %  differences(i) = differences(i) + abs(GetPercentileFromCDF(observations(i,j), cdf(:,j)) - GetPercentileFromCDF(thresholds(j), cdf(:,j)));
    %else
    %  % Here we are on the incorrect side of the threshold
    %  differences(i) = Inf;
    %  break;
    %end
  end
end

[differences, indices] = sort(differences);
end
