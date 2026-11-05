.pragma library

function stamp(value) {
    if (value === undefined || value === null) return null;
    const number = new Date(value).getTime();
    return isFinite(number) ? number : null;
}
function sameDay(left, right) {
    return left.getFullYear() === right.getFullYear() && left.getMonth() === right.getMonth() && left.getDate() === right.getDate();
}
function indices(events, selectedDate, now) {
    const today = sameDay(selectedDate, now);
    const time = now.getTime();
    return Array.from(events).map((event, index) => {
        const start = stamp(event.startDateTime);
        const rawEnd = stamp(event.endDateTime);
        const end = rawEnd === null || (start !== null && rawEnd < start) ? start : rawEnd;
        let group;
        if (!today) group = event.isAllDay ? 0 : 1;
        else if (event.isAllDay) group = 2;
        else if (start === null) group = 4;
        else if (start <= time && end > time) group = 0;
        else if (start >= time) group = 1;
        else group = 3;
        return {index: index, group: group, start: start, end: end};
    }).sort((left, right) => {
        if (left.group !== right.group) return left.group - right.group;
        const a = today && left.group === 3 ? left.end : left.start;
        const b = today && right.group === 3 ? right.end : right.start;
        if (a === null && b !== null) return 1;
        if (b === null && a !== null) return -1;
        if (a !== b) return today && left.group === 3 ? b - a : a - b;
        return left.index - right.index;
    }).map(row => row.index);
}
