.pragma library

function resolve(pin, notification, packages, playing, llm) {
    if (notification) return "notifications";
    if (pin !== "auto") return pin;
    if (packages) return "packages";
    if (playing) return "media";
    if (llm) return "llm";
    return "clock";
}

function page(mode) {
    return ({media: 0, notifications: 4, system: 5, packages: 5, llm: 5})[mode] || 0;
}
