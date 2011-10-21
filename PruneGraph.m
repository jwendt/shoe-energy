function [g] = PruneGraph(p, ...
                          groupings_matrix, ...
                          dlds_threshold, ...
                          amp_threshold, ...
                          lateral_threshold, ...
                          heeltoe_threshold)
% PruneGraph Prunes sensor graph such that there exists an edge
%            between two sensors only if they predict all metrics
%            similarly, within the given thresholds.
%
% -------
% INPUTS:
% -------
%
%   p: prediction diff graph
%      i -- sensor
%      j -- sensor
%      k -- metric
%        -- prediction error difference between sensor i and
%           sensor j for metric k
%   groupings_matrix: groupings matrix for grouped sensors
%   *_threshold: threshold for each metric error difference
%
% --------
% OUTPUTS:
% --------
%
%   g: pruned graph
%      i -- sensor
%      j -- sensor
%        -- 1 if sensor i and sensor j predict all metrics similarly
  [num_sensors nada1 nada2] = size(p);

  g = logical(zeros(num_sensors, num_sensors));

  abs_p = abs(p(:,:,:));
  gm = double(groupings_matrix);
  g = gm * gm' > 0;

  g(:,:) = g(:,:) | (abs_p(:,:,1) <= dlds_threshold & ...
                     abs_p(:,:,2) <= amp_threshold & ...
                     abs_p(:,:,3) <= lateral_threshold & ...
                     abs_p(:,:,4) <= heeltoe_threshold);
