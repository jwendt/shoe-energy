function [conf_limit_pos conf_limit_neg] = ComputeCI(distribution, alpha)

N = length(distribution);
upper_critical_value = tinv(1 - alpha/2, N-1);
conf_limit_pos = mean(distribution) + upper_critical_value * std(distribution) / sqrt(N);
conf_limit_neg = mean(distribution) - upper_critical_value * std(distribution) / sqrt(N);
