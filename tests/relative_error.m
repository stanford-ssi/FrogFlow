function relerr = relative_error(expected, actual)
    relerr = abs(actual-expected)/expected;
end