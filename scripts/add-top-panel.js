// Optional: execute with Plasma's scripting console. Existing panels stay intact.
// API: https://develop.kde.org/docs/plasma/scripting/api/
(function () {
    const plugin = 'org.kde.plasma.boringisland';
    if (!knownWidgetTypes.includes(plugin)) throw new Error('Install Boring Island first.');
    const existing = panels();
    for (let i = 0; i < existing.length; i++) {
        if (existing[i].widgets(plugin).length) {
            print('Boring Island already exists in panel ' + existing[i].id);
            return;
        }
    }
    const panel = new Panel;
    panel.location = 'top';
    panel.alignment = 'center';
    panel.lengthMode = 'fit';
    panel.height = 48;
    panel.hiding = 'windowsgobelow';
    const widget = panel.addWidget(plugin);
    widget.currentConfigGroup = ['General'];
    widget.writeConfig('shape', 1);
    widget.writeConfig('compactWidth', 240);
    widget.reloadConfig();
    print('Created Boring Island panel ' + panel.id);
})();
