.pragma library

function key(value) {
    return value.getFullYear() + "-" + String(value.getMonth() + 1).padStart(2, "0") + "-" + String(value.getDate()).padStart(2, "0");
}
function monthDays(selected, firstDayOfWeek) {
    const first = new Date(selected.getFullYear(), selected.getMonth(), 1, 12);
    const offset = (first.getDay() - firstDayOfWeek % 7 + 7) % 7;
    const days = [];
    for (let i = 0; i < 42; ++i) days.push(new Date(first.getFullYear(), first.getMonth(), 1 - offset + i, 12));
    return days;
}
function moveMonth(selected, offset) {
    const first = new Date(selected.getFullYear(), selected.getMonth() + offset, 1, 12);
    const last = new Date(first.getFullYear(), first.getMonth() + 1, 0, 12).getDate();
    return new Date(first.getFullYear(), first.getMonth(), Math.min(selected.getDate(), last), 12);
}
