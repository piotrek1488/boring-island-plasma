.pragma library

function resolve(pin, notification, packages, playing, llm, shelfCount, notificationCount) {
    if (notification) return "notifications";
    if (playing) return "media";
    if (shelfCount > 0) return "shelf";
    if (packages) return "packages";
    if (llm) return "llm";
    if (pin === "notifications" && notificationCount > 0) return "notifications";
    if (pin === "system") return "system";
    return "clock";
}
function page(mode) {
    return ({media: 0, shelf: 1, notifications: 4, system: 5, packages: 5, llm: 5})[mode] || 0;
}
function timeLabel(microseconds) {
    const seconds = Math.max(0, Math.floor(Number(microseconds || 0) / 1000000));
    const hours = Math.floor(seconds / 3600);
    return (hours ? hours + ":" + String(Math.floor(seconds / 60) % 60).padStart(2,"0") : Math.floor(seconds / 60))
        + ":" + String(seconds % 60).padStart(2,"0");
}

function idleText(style, now, locale) {
    const date = now.toLocaleDateString(locale, "d MMM yyyy");
    if (style === "date") return date;
    const clock = now.toLocaleTimeString(locale, "hh:mm");
    return style === "dateClock" ? date + " · " + clock : clock;
}
