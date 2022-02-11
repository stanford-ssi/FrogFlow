function rel_err = relative_error(expected, actual)
    rel_err = abs(actual-expected)/expected;
end