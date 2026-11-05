.pragma library

function compactWidth(fit, minimum, maximum, natural, scale) {
    // The configured upper limit takes precedence if it is below the minimum.
    var width = fit ? Math.min(maximum, Math.max(minimum, natural)) : maximum;
    return Math.max(80, width * scale);
}
