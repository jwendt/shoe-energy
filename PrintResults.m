function Y = PrintResults(output_path,...
                          predictors,...
                          groupings_list,...
                          training_error,...
                          dlds,...
                          amp,...
                          lateral,...
                          heeltoe,...
                          dlds_at_sensor,...
                          amp_at_sensor,...
                          land_at_sensor,...
                          test_dlds,...
                          test_amp,...
                          test_lateral,...
                          test_heeltoe,...
                          test_dlds_at_sensor,...
                          test_amp_at_sensor,...
                          test_land_at_sensor)
% PrintResults(PATH)
%   Function prints out some pretty graphs and saves them to the location
%   passed.
%
%   Parameters:
%
%     PATH  The file path to the directory to save figures and csv files
%
%     PREDICTORS  The matrix s outputted by SelectSensors. This is a matrix of
%                 logical values in which the (i,j,k) entry is 1 if sensor k is
%                 in the j ranked sensor grouping of size i.
%
%     TRAINING_ERROR  The matrix m outputted by SelectSensors. This is a matrix
%                     of prediction errors in which the (i,j,k) entry is the
%                     prediciton error for metric k (1:dlds, 2:amp, 3:lateral,
%                     4:heelto) for j ranked sensor grouping of size i.
%
%     DLDS, AMP, ALTERAL, HEELTOE, DLDS_AT_SENSOR, etc.

% make output directory if necessary
status = mkdir(output_path);
if(~status)
  error('Error creating output directory %s', output_path);
  return
end

%%%%%%%%%%%%%%%%%%%%%%%%
% Save the top sensors %
%%%%%%%%%%%%%%%%%%%%%%%%
[num_cica num_groupings num_sensors] = size(predictors);

filename = sprintf('%s/best_sensors.csv', output_path);
fid = fopen(filename, 'w');
% print column headers
fprintf(fid,'number of sensors');
for i=1:num_cica
  fprintf(fid,sprintf(',grouping %d',i));
end
fprintf(fid,'\n');

% now print data
for i=1:num_cica
  % print sensor size
  fprintf(fid,sprintf('%d,',i));
  best_sensors = find(predictors(i,1,:));
  for j = 1:length(best_sensors)
    % print each of the best sensors groupings
    for k = 1:length(groupings_list{best_sensors(j)})
      % print each of the sensors in each grouping
      fprintf(fid, sprintf('%d;',groupings_list{best_sensors(j)}(k)));
    end
    fprintf(fid, ',');
  end
  fprintf(fid, '\n');
end
fclose(fid);


%%%%%%%%%%%%%%%#%%%%%%%%%%%
% Plot the training error %
%%%%%%%%%%%%%%%#%%%%%%%%%%%
fprintf('Save training error\n');
M_DLDS = 1;
M_AMP = 2;
M_LAT = 3;
M_HT = 4;
[num_cica num_groupings num_metrics] = size(training_error);

dlds_train_err = training_error(:, 1, M_DLDS);
amp_train_err = training_error(:, 1, M_AMP);
lateral_train_err = training_error(:, 1, M_LAT);
heeltoe_train_err = training_error(:, 1, M_HT);

M = [(1:num_cica)' dlds_train_err amp_train_err lateral_train_err heeltoe_train_err];
filename = sprintf('%s/training_error.csv', output_path);
fid = fopen(filename, 'w');
fprintf(fid,'number of sensors, dlds train error, amp train error, lateral train err, heeltoe train err\n');
fclose(fid);
dlmwrite(filename, M, '-append')

%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plot the testing error %
%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf('Save testing error\n');
[num_cica num_groupings num_sensors] = size(predictors);
dlds_test_err = inf(1,num_cica);
amp_test_err = inf(1,num_cica);
lateral_test_err = inf(1,num_cica);
heeltoe_test_err = inf(1,num_cica);
for i = 1:num_cica
  dlds_test_err(i) = CombineErrors(...
      ComputeLinearPredictionError(dlds,...
                                   dlds_at_sensor(:,predictors(i,1,:)),...
                                   test_dlds,...
                                   test_dlds_at_sensor(:,predictors(i,1,:))));
  amp_test_err(i) = CombineErrors(...
      ComputeLinearPredictionError(amp,...
                                   amp_at_sensor(:,predictors(i,1,:)),...
                                   test_amp,...
                                   test_amp_at_sensor(:,predictors(i,1,:))));
  lateral_test_err(i) = CombineErrors(...
      ComputeLinearPredictionError(lateral,...
                                   amp_at_sensor(:,predictors(i,1,:)),...
                                   test_lateral,...
                                   test_amp_at_sensor(:,predictors(i,1,:))));
  heeltoe_test_err(i) = CombineErrors(...
      ComputeLinearPredictionError(heeltoe,...
                                   land_at_sensor(:,predictors(i,1,:)),...
                                   test_heeltoe,...
                                   test_land_at_sensor(:,predictors(i,1,:))));
end

M = zeros(num_cica, 4);
M = [(1:num_cica)' dlds_test_err' amp_test_err' lateral_test_err' heeltoe_test_err'];
filename = sprintf('%s/testing_error.csv', output_path);
fid = fopen(filename, 'w');
fprintf(fid,'number of sensors, dlds test error, amp test error, lateral test err, heeltoe test err\n');
fclose(fid);
dlmwrite(filename, M, '-append')


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plot metrics vs predicted on testing dataset %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf('Save testing dataset actual and predicted metrics\n');
[num_cica num_groupings num_sensors] = size(predictors);
dlds_predict = cell(1,num_cica);
amp_predict = cell(1,num_cica);
lateral_predict = cell(1,num_cica);
heeltoe_predict = cell(1,num_cica);
for i = 1:num_cica
  dlds_predict{i} = ComputeLinearPredictionError(dlds,...
                                                 dlds_at_sensor(:,predictors(i,1,:)),...
                                                 test_dlds,...
                                                 test_dlds_at_sensor(:,predictors(i,1,:)))...
                    + test_dlds;
  amp_predict{i} = ComputeLinearPredictionError(amp,...
                                                amp_at_sensor(:,predictors(i,1,:)),...
                                                test_amp,...
                                                test_amp_at_sensor(:,predictors(i,1,:)))...
                   + test_amp;
  lateral_predict{i} = ComputeLinearPredictionError(lateral,...
                                                    amp_at_sensor(:,predictors(i,1,:)),...
                                                    test_lateral,...
                                                    test_amp_at_sensor(:,predictors(i,1,:)))...
                       + test_lateral;
  heeltoe_predict{i} = ComputeLinearPredictionError(heeltoe,...
                                                    land_at_sensor(:,predictors(i,1,:)),...
                                                    test_heeltoe,...
                                                    test_land_at_sensor(:,predictors(i,1,:)))...
                       + test_heeltoe;
end

% Setup to write column headers and data to csv file
columns = 'actual test_dlds';
M = test_dlds;
for i = 1:num_cica
  columns = strcat(columns, sprintf(', test_dlds prediction (%d sensors)', i));
  M = [M dlds_predict{i}];
end

columns = strcat(columns, ', actual test_amp');
M = [M test_amp];
for i = 1:num_cica
  columns = strcat(columns, sprintf(', test_amp prediction (%d sensors)', i));
  M = [M amp_predict{i}];
end

columns = strcat(columns, ', actual test_lateral');
M = [M test_lateral];
for i = 1:num_cica
  columns = strcat(columns, sprintf(', test_lateral prediction (%d sensors)', i));
  M = [M lateral_predict{i}];
end

columns = strcat(columns, ', actual test_heeltoe');
M = [M test_heeltoe];
for i = 1:num_cica
  columns = strcat(columns, sprintf(', test_heeltoe prediction (%d sensors)', i));
  M = [M heeltoe_predict{i}];
end

columns = strcat(columns, '\n');

% Write column headers to csv file, followed by data using dlmwrite
filename = sprintf('%s/metric_prediction.csv', output_path);
fid = fopen(filename, 'w');
fprintf(fid, columns);
fclose(fid);
dlmwrite(filename, M, '-append')


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plot Confidence Intervals %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf('Save confidence intervals\n');
alpha = [0.1 0.05 0.01];
dlds_ci_pos = inf(num_cica, length(alpha));
dlds_ci_neg = inf(num_cica, length(alpha));
amp_ci_pos = inf(num_cica, length(alpha));
amp_ci_neg = inf(num_cica, length(alpha));
lateral_ci_pos = inf(num_cica, length(alpha));
lateral_ci_neg = inf(num_cica, length(alpha));
heeltoe_ci_pos = inf(num_cica, length(alpha));
heeltoe_ci_neg = inf(num_cica, length(alpha));
M = [];
for i=1:num_cica
  [dlds_ci_pos(i,:) dlds_ci_neg(i,:)] = ComputeCI(...
      ComputeLinearPredictionError(dlds,...
                                   dlds_at_sensor(:,predictors(i,1,:)),...
                                   test_dlds,...
                                   test_dlds_at_sensor(:,predictors(i,1,:))),...
      alpha);
  [amp_ci_pos(i,:) amp_ci_neg(i,:)] = ComputeCI(...
      ComputeLinearPredictionError(amp,...
                                   amp_at_sensor(:,predictors(i,1,:)),...
                                   test_amp,...
                                   test_amp_at_sensor(:,predictors(i,1,:))),...
      alpha);
  [lateral_ci_pos(i,:) lateral_ci_neg(i,:)] = ComputeCI(...
      ComputeLinearPredictionError(lateral,...
                                   amp_at_sensor(:,predictors(i,1,:)),...
                                   test_lateral,...
                                   test_amp_at_sensor(:,predictors(i,1,:))),...
      alpha);
  [heeltoe_ci_pos(i,:) heeltoe_ci_neg(i,:)] = ComputeCI(...
      ComputeLinearPredictionError(heeltoe,...
                                   land_at_sensor(:,predictors(i,1,:)),...
                                   test_heeltoe,...
                                   test_land_at_sensor(:,predictors(i,1,:))),...
      alpha);
end

M = [(1:num_cica)'...
     dlds_ci_pos dlds_ci_neg...
     amp_ci_pos amp_ci_neg...
     lateral_ci_pos lateral_ci_neg...
     heeltoe_ci_pos heeltoe_ci_neg];

columns = 'number of sensors';
for i=1:length(alpha)
  columns = strcat(columns, sprintf(', dlds_ci_pos (alpha %.2f)', alpha(i)));
end
for i=1:length(alpha)
  columns = strcat(columns, sprintf(', dlds_ci_neg (alpha %.2f)', alpha(i)));
end
for i=1:length(alpha)
  columns = strcat(columns, sprintf(', amp_ci_pos (alpha %.2f)', alpha(i)));
end
for i=1:length(alpha)
  columns = strcat(columns, sprintf(', amp_ci_neg (alpha %.2f)', alpha(i)));
end
for i=1:length(alpha)
  columns = strcat(columns, sprintf(', lateral_ci_pos (alpha %.2f)', alpha(i)));
end
for i=1:length(alpha)
  columns = strcat(columns, sprintf(', lateral_ci_neg (alpha %.2f)', alpha(i)));
end
for i=1:length(alpha)
  columns = strcat(columns, sprintf(', heeltoe_ci_pos (alpha %.2f)', alpha(i)));
end
for i=1:length(alpha)
  columns = strcat(columns, sprintf(', heeltoe_ci_neg (alpha %.2f)', alpha(i)));
end
columns = strcat(columns, '\n');
%num_metrics = 4;
%M = inf(num_cica, length(alpha)*num_metrics+1);
%M(:,1) = 1:num_cica;
%for i = 1:num_cica
%  for j = 1:length(alpha)
%    M(i,j:j+1) = [dlds_ci_pos(i,j) dlds_ci_neg(i,j)];

% Write column headers to csv file, followed by data using dlmwrite
filename = sprintf('%s/confidence_intervals.csv', output_path);
fid = fopen(filename, 'w');
fprintf(fid, columns);
fclose(fid);
dlmwrite(filename, M, '-append')
