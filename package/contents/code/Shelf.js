.pragma library
// Store references only: never copy, execute, or delete the user's files.
function allowed(url) {
    return typeof url === "string" && /^file:\/\/\//i.test(url) && !/[\u0000-\u001f]/.test(url);
}
function merge(existing, urls) {
    var result = existing.filter(allowed).slice(0, 24);
    for (var i = 0; i < urls.length && result.length < 24; ++i) {
        var url = String(urls[i]);
        if (allowed(url) && result.indexOf(url) < 0) result.push(url);
    }
    return result;
}
function decode(json) {
    try { var value = JSON.parse(json); return Array.isArray(value) ? merge([], value) : []; }
    catch (error) { return []; }
}
function name(url) {
    var part = url.split("/").pop() || url;
    try { return decodeURIComponent(part); } catch (error) { return part; }
}
