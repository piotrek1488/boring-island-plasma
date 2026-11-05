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
        function closeId(id) { for (let i=historyModel.count-1;i>=0;--i) if (String(historyModel.get(i).notificationId) === String(id)) historyModel.remove(i); }
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
    QtObject {
        id: calendarFixture
        property date selectedDate: new Date(2026,8,19,12)
        property var events: []
        property var eventDays: ({})
        property bool providerAvailable: true
        property string errorMessage: ""
        function moveDay(offset) {}
        function resetToday() {}
        function reload() {}
    }
    UI.ExpandingIsland {
        id: shell
        calendarBackend: calendarFixture
        backend: media; notifications: notifications; activities: activities
        onPinRequested: mode => pinnedMode = mode
    }
    SignalSpy { id: interactionSpy; target: shell; signalName: "interactionRequested" }
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
        function init() { media.playing=false; notifications.preview=null; shell.animationStyle="smooth"; shell.maximumWidth=4096; shell.maximumHeight=4096; shell.bottomEdge=false; shell.editing=false; shell.reduceMotion=true; shell.opened=false; shell.fullView=false; shell.presentedFullView=false; shell.fixedViewport=false; shell.reduceMotion=true; shell.notch=false; shell.uiScale=1; shell.animationDuration=400; shell.initialPage=0; historyModel.clear(); wait(20); compare(shell.progress,0); }
        function test_shapes_and_scaling_data() {
            return [{tag:"island",notch:false},{tag:"notch",notch:true}];
        }
        function test_shapes_and_scaling(data) {
            shell.notch=data.notch; shell.fullView=true; shell.opened=true;
            compare(shell.width,600); compare(shell.height,400);
            shell.uiScale=1.5;
            compare(shell.width,900); compare(shell.height,600);
            shell.opened=false;
            compare(shell.width,240); compare(shell.height,42);
        }
        function test_animation() {
            shell.reduceMotion=false; shell.fullView=true; shell.opened=true;
            wait(90); verify(shell.progress>0 && shell.progress<1);
            tryCompare(shell,"progress",1,600);
            shell.opened=false;
            wait(60); verify(shell.progress>0 && shell.progress<1);
            tryCompare(shell,"progress",0,400);
        }
        function test_click_interaction_does_not_fire_on_hover() {
            shell.fullView=true; shell.opened=true; wait(30);
            interactionSpy.clear();
            const title=findChild(findChild(shell,"expandedHeader"),"compactTitle");
            mouseMove(title,10,10); wait(30); compare(interactionSpy.count,0);
            mouseClick(title); compare(interactionSpy.count,1);
        }
        function test_tab_click_keeps_its_action_and_requests_focus() {
            shell.fullView=true; shell.opened=true; wait(30);
            interactionSpy.clear();
            mouseClick(findChild(shell,"notificationsTab"));
            compare(interactionSpy.count,1);
            tryVerify(() => findChild(shell,"notificationsPage") !== null);
        }
        function test_collapse_has_visible_intermediate_frames() {
            shell.fullView=true; shell.opened=true;
            shell.reduceMotion=false; shell.opened=false;
            wait(50); verify(shell.progress>0.7 && shell.progress<1);
            wait(60); verify(shell.progress>0 && shell.progress<0.7);
            tryCompare(shell,"progress",0,400);
        }
        function test_edit_mode_immediately_dismisses_expansion() {
            shell.fullView=true; shell.opened=true; compare(shell.progress,1);
            shell.reduceMotion=false; shell.editing=true;
            compare(shell.progress,0); verify(!shell.enabled);
            interactionSpy.clear(); mouseClick(shell,100,20); compare(interactionSpy.count,0);
            shell.opened=false; shell.editing=false;
            verify(shell.enabled); compare(shell.progress,0);
        }
        function test_spring_motion_bounds_and_fixed_origin_data() {
            return [{tag:"island-top",notch:false,bottom:false},{tag:"notch-top",notch:true,bottom:false},{tag:"island-bottom",notch:false,bottom:true}];
        }
        function test_spring_motion_bounds_and_fixed_origin(data) {
            shell.animationStyle="spring"; shell.notch=data.notch; shell.bottomEdge=data.bottom;
            shell.fixedViewport=true; shell.fullView=true; shell.reduceMotion=false;
            const width=shell.width, height=shell.height;
            const morph=findChild(shell,"morphSurface");
            shell.opened=true;
            let bounced=false;
            for (let i=0;i<25;++i) {
                wait(20);
                bounced=bounced || shell.progress>1.005;
                verify(shell.progress>=0 && shell.progress<1.04);
                compare(shell.width,width); compare(shell.height,height);
                verify(morph.x>=0 && morph.x+morph.width<=width+0.1);
                verify(morph.y>=0 && morph.y+morph.height<=height+0.1);
                if (!data.bottom) compare(morph.y,0);
            }
            verify(bounced); tryCompare(shell,"progress",1,200);
            shell.opened=false; tryCompare(shell,"progress",0,400);
        }
        function test_spring_interruption_and_accessibility() {
            shell.animationStyle="spring"; shell.fullView=true; shell.reduceMotion=false;
            shell.opened=true; wait(80); shell.opened=false; wait(40); shell.opened=true;
            tryCompare(shell,"progress",1,700);
            shell.reduceMotion=true; shell.opened=false; compare(shell.progress,0);
            shell.opened=true; compare(shell.progress,1); verify(!shell.springMotion);
            shell.reduceMotion=false; shell.editing=true; compare(shell.progress,0);
        }
        function test_spring_respects_screen_limits() {
            shell.animationStyle="spring"; shell.fixedViewport=true;
            shell.maximumWidth=600; shell.maximumHeight=400; shell.fullView=true; shell.reduceMotion=false;
            shell.opened=true;
            for (let i=0;i<24;++i) {
                wait(20); verify(shell.surfaceWidth<=600); verify(shell.surfaceHeight<=400);
                verify(shell.width<=600); verify(shell.height<=400);
            }
            tryCompare(shell,"progress",1,200);
        }
        function test_animation_duration_setting_data() {
            return [{tag:"smooth",style:"smooth"},{tag:"spring",style:"spring"}];
        }
        function test_animation_duration_setting(data) {
            shell.animationStyle=data.style;
            shell.reduceMotion=false; shell.fullView=true; shell.animationDuration=800; shell.opened=true;
            wait(100); verify(shell.progress>0 && shell.progress<1);
            tryCompare(shell,"progress",1,1200);
            shell.animationDuration=50; shell.opened=false;
            tryCompare(shell,"progress",0,250);
            shell.reduceMotion=true; shell.animationDuration=1000; shell.opened=true;
            compare(shell.progress,1);
        }
        function test_fixed_viewport_does_not_resize_during_animation() {
            shell.fixedViewport=true; shell.fullView=true; shell.animationDuration=800; shell.reduceMotion=false;
            const initialWidth=shell.width, initialHeight=shell.height;
            shell.opened=true; wait(100);
            compare(shell.width,initialWidth); compare(shell.height,initialHeight);
            verify(shell.surfaceWidth>240 && shell.surfaceWidth<600);
            tryCompare(shell,"progress",1,1200);
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
            historyModel.append({notificationId:"a", applicationName:"Fixture",summary:"Hello",body:"World"});
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
            verify(panelCompact.width>initialWidth); compare(panelCompact.effectiveHeight,96);
        }
        function test_panel_padding_does_not_clip_manual_height() {
            panelCompact.panelItem=panelCompact.parent.parent;
            panelCompact.autoHeight=false; panelCompact.notch=true;
            panelCompact.compactHeight=80; panelCompact.compactScale=1.5;
            compare(panelCompact.effectiveHeight,120);
            compare(panelCompact.visualItem.parent,panelCompact.parent.parent);
            compare(panelCompact.visualItem.y,0);
            panelCompact.panelItem=null; panelCompact.notch=false;
        }
        function test_compact_scale_and_manual_height() {
            compactTest.autoHeight=true; compactTest.compactScale=0.5;
            compare(compactTest.effectiveHeight,32);
            compactTest.compactScale=2; compare(compactTest.effectiveHeight,128);
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
            verify(title.font.pixelSize>=16); verify(battery.fontSize>=16);
        }
        function test_delete_individual_history_notification() {
            historyModel.append({notificationId:"first",applicationName:"Fixture",summary:"First",body:""});
            historyModel.append({notificationId:"second",applicationName:"Fixture",summary:"Second",body:""});
            shell.fullView=true; shell.opened=true; shell.initialPage=4;
            tryVerify(() => findChild(shell,"deleteNotification_first") !== null);
            verify(waitForRendering(shell)); // Loader completion precedes layout on newer Qt.
            mouseClick(findChild(shell,"deleteNotification_first"));
            compare(historyModel.count,1); compare(historyModel.get(0).notificationId,"second");
            tryVerify(() => findChild(shell,"deleteNotification_second") !== null);
            verify(waitForRendering(shell));
            mouseClick(findChild(shell,"deleteNotification_second")); compare(historyModel.count,0);
        }
        function test_year_in_header() {
            shell.fullView=true; shell.opened=true;
            const label=findChild(shell,"headerDate");
            verify(label.text.indexOf(String(new Date().getFullYear()))>=0);
        }
        function test_calendar_keeps_brand_date_and_tab_position() {
            shell.fullView=true; shell.opened=true; wait(40);
            const brand=findChild(shell,"brandLabel"), date=findChild(shell,"headerDate"), tabs=findChild(shell,"tabs");
            const before=tabs.mapToItem(shell,0,0).y;
            shell.initialPage=3;
            tryVerify(() => findChild(shell,"calendarPage") !== null);
            verify(brand.visible); verify(date.visible);
            compare(tabs.mapToItem(shell,0,0).y,before);
            const pane=findChild(shell,"calendarMonthPane");
            tryVerify(() => pane.height>=200);
            const bottom=pane.mapToItem(shell,pane.width,pane.height);
            verify(bottom.y<=shell.height-25);
            compare(shell.height,400);
        }
        function test_notification_preserves_manual_shelf_and_playback() {
            shell.fullView=true; shell.opened=true; shell.initialPage=1; media.playing=true; wait(30);
            const tabs=findChild(shell,"tabs");
            const shelf=Array.from(tabs.children).find(child=>child.text && child.text.indexOf("Shelf")===0);
            verify(shelf.accent);
            notifications.preview={id:"message",application:"Mail",summary:"Hello",body:"World"}; wait(30);
            verify(media.playing); verify(shelf.accent);
            notifications.preview=null; verify(media.playing); verify(shelf.accent);
        }
        function test_activity_page() {
            shell.fullView=true; shell.opened=true; shell.initialPage=5;
            tryVerify(() => findChild(shell,"activityPage") !== null);
            verify(shell.height>=400);
        }
    }
}
