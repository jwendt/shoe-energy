matlabpool 3;

output = 'output';

num_sensors = 15;

K1 = 20;

K2 = 20;

input = {'data/S1.mat',
         'data/S2.mat',
         'data/S3.mat',
         'data/S4.mat',
         'data/S5.mat'};

input_name = {'S1',
              'S2',
              'S3',
              'S5',
              'S5'};

feet = {{'left'},{'right'},{'left','right'}};

% Create premutations of all input paths and input names
inputs = cell(1,2^length(input)-1);
input_names = cell(1,2^length(input_name)-1);
count = 0;
for i=1:length(input)
  tmp_input_names = nchoosek(input_name,i);
  tmp_inputs = nchoosek(input,i);
  [rows cols] = size(tmp_inputs);
  for r = 1:rows
    [single_inputs{1:cols,1}] = deal(tmp_inputs{r,:});
    single_input_names = [];
    for c = 1:cols
      if(single_input_names)
        single_input_names = [single_input_names '_' tmp_input_names{r,c}];
      else
        single_input_names = tmp_input_names{r,c};
      end
    end
    count = count + 1;
    inputs{count} = single_inputs;
    input_names{count} = single_input_names;
  end
end

% Parallel for loop
parfor i=1:length(inputs)
  for f=1:length(feet)
    fprintf('--------------------------\n');
    fprintf('inputs = %s\n', cell2mat(inputs{i}'));
    fprintf('input_names = %s\n', input_names{i});
    fprintf('feet = %s\n', cell2mat(feet{f}));
    fprintf('--------------------------\n');
    output_path = sprintf('%s/%d-%d-%d-%s-%s',output, num_sensors, K1, K2, input_names{i}, cell2mat(feet{f}));
    RunPipeline(num_sensors, K1, K2, inputs{i}, feet{f}, output_path);
  end
end

matlabpool close;


%for i = 1:length(inputs)


%for f=1:length(feet)

%RunPipeline(num_sensors, K1, K2, input, {'left','right'}, sprintf('output/%d-%d-%d-S1_S2_S3_S4_S5-left_right',num_sensors,K1,K2));

