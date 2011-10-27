function err = ComputeLinearPredictionError(train, train_predictors, test, test_predictors)
% ComputeLinearPreditionError
%    Finds the linear equation to apply 
%                             and the train_predictors' measurements. The error is
%                             computed by measuring the differences between the
%                             train values and the linear model trained from
%                             the train_predictors and the train values.
%
%    ComputeLinearPredictionError(TRAIN, TRAIN_PREDICTORS)
%
%      TRAIN is a vector of size N of train values
%
%      TRAIN_PREDICTORS is a matrix of size NxM with M predictor measurements
[num_observations num_train_predictors] = size(train_predictors);
Xtrain = [ones(size(train)) train_predictors];
b = regress(train, Xtrain);
Xtest = [ones(size(test)) test_predictors];
y = Xtest*b;
err = y - test;
