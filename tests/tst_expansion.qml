import QtQuick
import QtTest
import QtQuick.Layouts
import "../package/contents/ui" as UI

Item {
    width: 1100; height: 950
    QtObject {
        id: media
        property bool available: true
        property bool playing: false
        property string title: "Test track"
        property string artist: "Test artist"
        property string artwork: ""
        property string identity: "Fixture"
        property bool canToggle: true
        property bool canPrevious: true
        property bool canNext: true
        property bool canSeek: true
        property real duration: 100000000
        property real position: 20000000
        property real volume: 0.5
        property bool hasBattery: true
        property int percent: 80
        property bool charging: false
        function toggle() { playing = !playing; }
        function next() {}
        function previous() {}
        function seek(value) { position = value; }
        function setVolume(value) { volume = value; }
    }
    ListModel { id: historyModel }
    QtObject {
        id: notifications
        property var preview: null
        property var history: historyModel
        property int count: historyModel.count
        property bool available: true
        function clearAll() { historyModel.clear(); }
        function closeId(id) { for (let i=historyModel.count-1;i>=0;--i) if (historyModel.get(i).id === id) historyModel.remove(i); }
    }
    QtObject {
        id: activities
        property bool systemEnabled: true
        property bool packagesEnabled: true
        property bool llmEnabled: true
        property var system: ({cpu: 42, ram: 60, gpus: [{name: "Test GPU", util: 25}]})
        property var packages: ({active: false})
        property var llm: ({active: false})
        property string audio: "Test speaker"
        property string error: ""
        function open(kind) {}
    }
    UI.ExpandingIsland {
        id: shell
        backend: media; notifications: notifications; activities: activities
        onPinRequested: mode => pinnedMode = mode
    }
    UI.CompactView { id: compactTest; backend: media; width: 240; height: 64; visible: false }
    RowLayout {
        width: 900; height: 64
        visible: false
        UI.CompactView {
            id: panelCompact
            backend: media
            Layout.fillHeight: true
            Layout.preferredWidth: Math.min(500, naturalWidth) * compactScale
        }
    }
    TestCase {
        name: "Expansion"; when: windowShown
        function init() { shell.opened=false; shell.fullView=false; shell.presentedFullView=false; shell.fixedViewport=false; shell.reduceMotion=true; shell.notch=false; shell.uiScale=1; shell.initialPage=0; historyModel.clear(); }
        function test_shapes_and_scaling_data() {
            return [{tag:"island",notch:false},{tag:"notch",notch:true}];
        }
        function test_shapes_and_scaling(data) {
            shell.notch=data.notch; shell.fullView=true; shell.opened=true;
            compare(shell.width,520); compare(shell.height,446);
            shell.uiScale=1.5;
            compare(shell.width,780); compare(shell.height,669);
            shell.opened=false;
            compare(shell.width,240); compare(shell.height,42);
        }
        function test_animation() {
            shell.reduceMotion=false; shell.fullView=true; shell.opened=true;
            wait(90); verify(shell.progress>0 && shell.progress<1);
            tryCompare(shell,"progress",1,600);
            shell.opened=false;
            wait(90); verify(shell.progress>0 && shell.progress<1);
            tryCompare(shell,"progress",0,600);
        }
        function test_fixed_viewport_does_not_resize_during_animation() {
            shell.fixedViewport=true; shell.fullView=true; shell.reduceMotion=false;
            const initialWidth=shell.width, initialHeight=shell.height;
            shell.opened=true; wait(100);
            compare(shell.width,initialWidth); compare(shell.height,initialHeight);
            verify(shell.surfaceWidth>240 && shell.surfaceWidth<520);
            tryCompare(shell,"progress",1,800);
        }
        function test_tab_layout_data() { return [{tag:"en",language:"en"},{tag:"pl",language:"pl"}]; }
        function test_tab_layout(data) {
            shell.language=data.language; shell.fullView=true; shell.opened=true;
            wait(80);
            const flow=findChild(shell,"tabs");
            const tabs=Array.from(flow.children).filter(item => item.hasOwnProperty("showTooltip"));
            verify(tabs.length===5);
            for (let i=0;i<tabs.length;i++) {
                verify(tabs[i].width>=tabs[i].contentItem.implicitWidth+20);
                verify(!tabs[i].showTooltip);
                for (let j=i+1;j<tabs.length;j++) {
                    const a=tabs[i], b=tabs[j];
                    verify(a.x+a.width<=b.x || b.x+b.width<=a.x || a.y+a.height<=b.y || b.y+b.height<=a.y);
                }
            }
            shell.language="en";
        }
        function test_notification_history() {
            historyModel.append({id:"a", applicationName:"Fixture",summary:"Hello",body:"World"});
            shell.fullView=true; shell.opened=true; shell.initialPage=4;
            tryVerify(() => findChild(shell,"notificationsPage") !== null);
            compare(findChild(shell,"notificationsTab").text,"Notifications · 1");
            notifications.closeId("a");
            compare(historyModel.count,0);
            shell.language="pl";
            compare(findChild(shell,"notificationsTab").text,"Powiadomienia · 0");
            shell.language="en";
        }
        function test_expansion_keeps_origin_and_text_layout() {
            shell.fixedViewport=true; shell.notch=true; shell.fullView=true; shell.reduceMotion=false;
            const morph=findChild(shell,"morphSurface"), header=findChild(shell,"expandedHeader");
            const layoutWidth=header.width, fontSize=findChild(header,"compactTitle").font.pixelSize;
            shell.opened=true;
            for (let i=0;i<4;++i) {
                wait(60); compare(morph.y,0); compare(header.width,layoutWidth);
                compare(findChild(header,"compactTitle").font.pixelSize,fontSize);
            }
            tryCompare(shell,"progress",1,600);
        }
        function test_panel_manual_height_and_scale() {
            panelCompact.autoHeight=false; panelCompact.compactScale=1; panelCompact.compactHeight=24;
            wait(30); compare(panelCompact.height,64); compare(panelCompact.effectiveHeight,24);
            panelCompact.compactHeight=48; compare(panelCompact.effectiveHeight,48);
            panelCompact.compactScale=0.5; wait(30); compare(panelCompact.effectiveHeight,24);
            panelCompact.autoHeight=true; panelCompact.compactScale=1; wait(30);
            const initialWidth=panelCompact.width;
            panelCompact.compactScale=1.5; wait(30);
            verify(panelCompact.width>initialWidth); compare(panelCompact.effectiveHeight,64);
        }
        function test_compact_scale_and_manual_height() {
            compactTest.autoHeight=true; compactTest.compactScale=0.5;
            compare(compactTest.effectiveHeight,32);
            compactTest.compactScale=2; compare(compactTest.effectiveHeight,64);
            compactTest.autoHeight=false; compactTest.compactHeight=20; compactTest.compactScale=1.5;
            compare(compactTest.effectiveHeight,30);
        }
        function test_expanded_header_insets() {
            shell.fullView=true; shell.opened=true; wait(30);
            const header=findChild(shell,"expandedHeader");
            const title=findChild(header,"compactTitle"), battery=findChild(header,"compactBattery");
            const morph=findChild(shell,"morphSurface");
            const a=title.mapToItem(morph,0,0), b=battery.mapToItem(morph,battery.width,battery.height);
            verify(a.x>=30); verify(b.x<=morph.width-30);
            verify(title.font.pixelSize>=16); verify(battery.font.pixelSize>=16);
        }
        function test_activity_page() {
            shell.fullView=true; shell.opened=true; shell.initialPage=5;
            tryVerify(() => findChild(shell,"activityPage") !== null);
            verify(shell.height>400);
        }
    }
}
