function err = ComputeLinearPredictionError(actual, predictors)
% ComputeLinearPreditionError Computes the error given the actual measurements
%                             and the predictors' measurements. The error is
%                             computed by measuring the differences between the
%                             actual values and the linear model trained from
%                             the predictors and the actual values.
%
%    ComputeLinearPredictionError(ACTUAL, PREDICTORS)
%
%      ACTUAL is a vector of size N of actual values
%
%      PREDICTORS is a matrix of size NxM with M predictor measurements
[num_observations num_predictors] = size(predictors);
X = [ones(size(actual)) predictors];
b = regress(actual, X);
y = X*b;
err = y - actual;
