function indices = GetIndices(K, num_values, choice)
% TODO - should be GetTopIndicesFromDiscreteDistribution(K, num_indices, choice)
%
% I = GetIndices(K, NV, CHOICE)
%
% Description    Returns K indices according to the choice distribution. K <= NV
%
% Input
%   K       Number of top indices to return (scalar value)
%
%   NV      Number of indices to choose from (scalar value)
%
%   CHOICE  One of the following options
%             'greedy'      Returns 1:K
%
%             'rep'         Returns K evenly distributed values from 1 to NV
%
%             'greedy-rep'  Returns top K/2 values and K/2 values distributed
%                           from 1+K/2 to NV
%
%             'power'       NOT YET IMPLEMENTED
%                           Returns K power-law distributed values from 1 to NV
%
% Output
%   I       Top K indices as decided by the choice of algorithm

if(K > num_values)
  error('K must be <= NV');
end

if(strcmp(choice,'greedy'))
  indices = 1:K;
elseif(strcmp(choice,'rep'))
  indices = 1:round(num_values/K):num_values;
elseif(strcmp(choice,'greedy-rep'))
  num_of_greedy = round(K/2);
  num_of_rep = K - num_of_greedy;
  indices = 1:num_of_greedy;

  num_of_rep_values = num_values-num_of_greedy;
  increment = round(num_of_rep_values/num_of_rep);

  indices = [indices num_of_greedy+round(increment/2):increment:num_values];

elseif(strcmp(choice,'power'))
  error('"%s" choice is currently not implemented', choice);
  x = 1:num_values;
  %pow = exp(-x);
  a = 3;
  pow = x.^(-a);
  max_val = max(pow);
  pow = pow*length(pow)/max_val;
  pow = fliplr(pow);
  % TODO not quite done yet
  %      must round all pow values to nearest integer and make sure they are
  %      all unique...  so if two values next to each other are 1 and 1, they
  %      should be changed to 1 and 2, I think. :-/
  [pow_indices pow_values] = GetTop(K, round(pow), 'rep');
  indices = pow_values;
  %indices = pow(1:round(length(pow)/K):length(pow));
  %values = values(indices);
else
  error('wrong input for CHOICE parameter');
end
