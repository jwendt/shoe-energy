function percentile = GetPercentileFromCDF(value, cdf)
% GetPercentileFromCDF   Computes the percentile that a value falls into within
%                        the given CDF. If the value lies between two
%                        observations that represent the CDF, linear
%                        interpolation is used to estimtae the value's
%                        percentile.
%
%    GetPercentileFromCDF(VALUE, CDF) returns a percentile ranging from 0 to 1.
%
%    VALUE is scalar
%    CDF is a sorted vector in ascending order representing the cumulative
%        distribution function.
for i = 1:length(cdf)
  % Value is less than the smallest value, default to 0th percentile
  if i == 1 && value < cdf(i)
    percentile = 0;
    return
  end

  if value == cdf(i)
    percentile = i/length(cdf);
    return
  elseif value < cdf(i)
    % do linear interpolation between values inside the discrete representation
    % of the CDF
    percentile = (i-1)/length(cdf) + (1/length(cdf))*(value-cdf(i-1))/(cdf(i)-cdf(i-1));
    return
  end
end

% Value is larger than the entire distribution, default to 100th percentile
percentile = 1;
end
