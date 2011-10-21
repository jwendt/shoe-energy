function combined_error = CombineErrors(error_vals)
  combined_error = sqrt(sum(error_vals.^2) / length(error_vals));
