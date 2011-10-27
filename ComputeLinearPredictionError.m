function err = ComputeLinearPredictionError(train, train_predictors, test, test_predictors)
% ComputeLinearPreditionError
%     Takes in a training dataset along with the values of the training
%     predictors, computes the linear equation to apply to a row vector of such
%     training predictors, then applys this equation to the testing predictors
%     and returns the error of these predictions on the testing vector.
%
%    ComputeLinearPredictionError(TRAIN, TRAIN_PREDICTORS, TEST, TEST_PREDICTORS)
%
%      TRAIN is a vector of size N of training values
%
%      TRAIN_PREDICTORS is a matrix of size NxM with M predictor measurements
%
%      TEST is a vector of size P of training values
%
%      TEST_PREDICTORS is a matrix of size PxM with M predictor measurements
[num_observations num_train_predictors] = size(train_predictors);
Xtrain = [ones(size(train)) train_predictors];
b = regress(train, Xtrain);
Xtest = [ones(size(test)) test_predictors];
y = Xtest*b;
err = y - test;
