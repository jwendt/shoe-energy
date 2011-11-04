function dlds = ChangeInLength(data, threshold_percent);
% ChangeInLength
%    ChangeInLength(D, T) finds the change in length of steps between each
%    step in the raw data, D. The start of a step occurs when the signal
%    in D rises above T*max(D). The step ends when the signal in D falls
%    below T*max(D).

threshold = threshold_percent*max(data);

% set stepping flags
marked_in_air = (data(1) <= threshold);
in_air = (data(1) <= threshold);
%in_air = false;
%marked_in_air = false;

num_samples = length(data);

number_of_steps = 0;
for i=1:num_samples
  % data was in the air, now the pressure is large (step beginning)
  %if(in_air(sensor_index) && data(i,sensor_index) > threshold_step)
  if(in_air && data(i) > threshold)
    in_air = false;

    if(marked_in_air)
      marked_in_air = false;

      % update so we know where the step start was
      number_of_steps = number_of_steps + 1;
      step_start_sum(number_of_steps) = i;
      %plot([i i],[min_amplitude max_amplitude],'-g');
    end

  % data is on the ground, pressure is now relieving (step ending)
  %elseif(~in_air(sensor_index) && data(i,sensor_index) <= threshold_step)
  elseif(~in_air && data(i) <= threshold)
    in_air = true;
    if(~marked_in_air)
      marked_in_air = true;

      % update so we know where the step ends
      if(number_of_steps ~= 0)
        step_end_sum(number_of_steps) = i;
        %plot([i i],[min_amplitude max_amplitude],'-r');
        %fprintf('sensor : step @ %d, time %f\n', i, time(i));
      end
    end
  end
end

%fprintf('number_of_steps = %d, \n', number_of_steps);
if(number_of_steps < 3)
  % TODO If dlds cannot be measured at a given sensor (due to missing a step),
  % technically that sensor should still trigger once the following step comes,
  % effectively doubling its measured dlds value. For simplicity, we just set
  % dlds to 0.
  dlds = 0; %nan; %-9999
else
  dlds = (step_start_sum(3) - step_start_sum(2)) - (step_start_sum(2) - step_start_sum(1));
end

end
