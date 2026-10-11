import QtQuick
import QtMultimedia
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
    id: root

    // ── Fast mode (skip reveal animation, used for lid-switch lock) ──
    property bool fastMode: Quickshell.env("UNIT3_LOCK_FAST") === "1"

    // ── Shared state ──
    property bool   revealing: false   // reveal video is playing
    property bool   frozen:    false   // reveal frozen on last frame
    property bool   hiding:    false   // hide video is playing
    property bool   done:      false   // everything finished

    // ── Generic paths (portable) ──
    property string home:          Quickshell.env("HOME")
    property string xdgConfigHome: Quickshell.env("XDG_CONFIG_HOME") || (home + "/.config")

    // ── Shared auth ──
    property string lockInput:   ""
    property bool   lockError:   false
    property bool   lockPending: false

    property string currentUser: "user"
    Process {
        id: getUserProc; command:["sh","-c","echo $USER"]; running:true
        stdout: SplitParser { onRead: data => { var u=data.trim(); if(u!=="") root.currentUser=u } }
    }

    // ── Live system info (hostname, kernel, GPU) ──
    property string currentHost: "host"
    Process {
        id: getHostProc; command:["sh","-c","hostname"]; running:true
        stdout: SplitParser { onRead: data => { var h=data.trim(); if(h!=="") root.currentHost=h } }
    }
    property string kernelStr: "6.x"
    Process {
        id: getKernelProc; command:["sh","-c","uname -r | cut -d- -f1 2>/dev/null"]; running:true
        stdout: SplitParser { onRead: data => { var k=data.trim(); if(k!=="") root.kernelStr=k } }
    }
    property string gpuStr: ""
    Process {
        id: getGpuProc; command:["sh","-c","lspci | grep -i 'vga\\|3d' | head -1 | sed 's/.*\\[\\(.*\\)\\].*/\\1/' | cut -c1-16"]; running:true
        stdout: SplitParser { onRead: data => { var g=data.trim(); if(g!=="") root.gpuStr=g } }
    }

    Process {
        id: authProc
        command:["/bin/bash","-c",
            "printf '%s\\n' \"$LOCKPWD\" | pamtester qs-lock \"$LOCKUSER\" authenticate >/dev/null 2>&1 && echo OK || echo FAIL"]
        running: false
        property string envPwd:""; property string envUser:""
        environment:({"LOCKPWD":authProc.envPwd,"LOCKUSER":authProc.envUser})
        stdout: StdioCollector { onStreamFinished: {
            root.lockPending = false
            if (this.text.trim() === "OK") {
                root.lockInput = ""
                root.lockError = false
                root.doHide()   // auth OK → start hide
            } else {
                root.lockError = true
                root.lockInput = ""
                errTimer.restart()
            }
        }}
    }
    Timer { id:errTimer; interval:800; repeat:false; onTriggered: root.lockError=false }

    function doAuth() {
        if (root.lockPending || root.lockInput === "") return
        root.lockPending = true
        authProc.envPwd  = root.lockInput
        authProc.envUser = root.currentUser
        authProc.running = true
    }

    function doHide() {
        root.hiding = true
    }

    // ── Hyprland cursor handling ──
    // The native Hyprland cursor stays; nothing to do on the lockscreen side.

    Component.onCompleted: {
        if (root.fastMode) {
            // Skip reveal animation entirely
            root.frozen = true
        } else {
            root.revealing = true
        }
    }

    // ── Screens ──
    Variants {
        model: Quickshell.screens
        PanelWindow {
            required property var modelData
            screen: modelData
            anchors.top:true;anchors.left:true;anchors.right:true;anchors.bottom:true
            exclusionMode: ExclusionMode.Ignore
            color: "black"
            implicitWidth: modelData.width; implicitHeight: modelData.height
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: (root.frozen && !root.hiding && !root.done)
                ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            property bool isPrimary: modelData.name === Quickshell.screens[0].name

            // ── Fast mode background ──
            // Shows the last frame of wave_reveal.mp4 as a static image.
            // Instant loading (no FFmpeg, no video codec).
            Image {
                id: fastBg
                anchors.fill: parent
                source: root.fastMode ? ("file://" + root.xdgConfigHome + "/quickshell/videos/wave_last_frame.png") : ""
                visible: root.fastMode && !root.hiding && !root.done
                fillMode: Image.PreserveAspectCrop
                asynchronous: false
                cache: true
                z: 0
            }

            // ── Reveal ──
            MediaPlayer {
                id: reveal
                source: root.fastMode ? "" : ("file://" + root.xdgConfigHome + "/quickshell/videos/wave_reveal.mp4")
                videoOutput: voReveal
                audioOutput: null
                loops: 1
                autoPlay: false
                onPositionChanged: function() {
                    if (root.hiding || root.done) return
                    var pos = reveal.position
                    var dur = reveal.duration
                    if (dur > 0 && pos >= dur - 34) {
                        reveal.pause()
                        root.revealing = false
                    }
                }
            }
            VideoOutput {
                id: voReveal
                anchors.fill: parent
                visible: !root.fastMode && !root.done
            }

            // ── Hide ──
            MediaPlayer {
                id: hide
                source: root.fastMode ? "" : ("file://" + root.xdgConfigHome + "/quickshell/videos/wave_hide.mp4")
                videoOutput: voHide
                audioOutput: null
                loops: 1
                autoPlay: false
                onMediaStatusChanged: function() {
                    // Close handled by hideFadeAnim.onFinished
                }
            }
            VideoOutput {
                id: voHide
                anchors.fill: parent
                z: 1
                visible: !root.fastMode && (root.hiding || root.done)
                opacity: 1.0
            }

            // Fade + close 1s before hide ends
            Timer {
                id: hideFadeTimer
                interval: 1200
                repeat: false
                onTriggered: hideFadeAnim.start()
            }
            NumberAnimation {
                id: hideFadeAnim
                target: voHide; property: "opacity"
                from: 1.0; to: 0.0
                duration: 400
                easing.type: Easing.InQuad
                onFinished: {
                    root.done = true
                    exitTimer.restart()
                }
            }

            // ── UI Lockscreen ──
            Item {
                anchors.fill: parent
                visible: !root.done
                z: 2

                property real uiOp: (root.frozen || root.revealing) ? 1 : 0
                Behavior on uiOp {
                    enabled: !root.fastMode
                    NumberAnimation { duration: 400 }
                }

                // Central panel — slides from the top (except in fast mode)
                Item {
                    id: panelHost
                    width: 380
                    height: panelRect.height
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter:   parent.verticalCenter
                    z: 6
                    opacity: root.fastMode ? 1 : 0

                    SequentialAnimation {
                        id: panelReveal
                        PropertyAction{target:panelHost;property:"anchors.verticalCenterOffset";value:-200}
                        PropertyAction{target:panelHost;property:"opacity";value:0}
                        PropertyAction{target:wipeScale;property:"yScale";value:1}
                        ParallelAnimation {
                            NumberAnimation{target:panelHost;property:"anchors.verticalCenterOffset";to:0;duration:580;easing.type:Easing.OutExpo}
                            NumberAnimation{target:panelHost;property:"opacity";to:1;duration:320}
                        }
                        NumberAnimation{target:wipeScale;property:"yScale";to:0;duration:460;easing.type:Easing.OutExpo}
                        onFinished: {
                            if (isPrimary) {
                                pwInput.forceActiveFocus()
                                focusRetry.restart()
                            }
                        }
                    }

                    SequentialAnimation {
                        id: panelHide
                        NumberAnimation{target:wipeScale;property:"yScale";from:0;to:1;duration:210;easing.type:Easing.InQuart}
                        ParallelAnimation{
                            NumberAnimation{target:panelHost;property:"anchors.verticalCenterOffset";to:-200;duration:360;easing.type:Easing.InExpo}
                            NumberAnimation{target:panelHost;property:"opacity";to:0;duration:280}
                        }
                    }

                    SequentialAnimation { id:shakeAnim
                        NumberAnimation{target:panelHost;property:"anchors.horizontalCenterOffset";from:0;to:-10;duration:55}
                        NumberAnimation{target:panelHost;property:"anchors.horizontalCenterOffset";to:10;duration:75}
                        NumberAnimation{target:panelHost;property:"anchors.horizontalCenterOffset";to:-7;duration:65}
                        NumberAnimation{target:panelHost;property:"anchors.horizontalCenterOffset";to:7;duration:65}
                        NumberAnimation{target:panelHost;property:"anchors.horizontalCenterOffset";to:0;duration:55}
                    }

                    Rectangle {
                        id: panelRect
                        width:380; color:"#EBE3D1"
                        height: panelCol.implicitHeight + 72
                        border.color:"#857B66"; border.width:1
                        radius: 16
                        clip: true

                        Repeater { model:20; Rectangle{x:index*20;y:0;width:1;height:panelRect.height;color:Qt.rgba(43/255, 36/255, 25/255,0.06)} }
                        Repeater { model:Math.ceil(panelRect.height/20); Rectangle{x:0;y:index*20;width:panelRect.width;height:1;color:Qt.rgba(43/255, 36/255, 25/255,0.06)} }

                        Rectangle {
                            x:0;width:parent.width;height:1;z:20
                            gradient:Gradient{ orientation:Gradient.Horizontal
                                GradientStop{position:0;color:"transparent"}
                                GradientStop{position:0.5;color:"#8C1A16"}
                                GradientStop{position:1;color:"transparent"} }
                            SequentialAnimation on y {
                                running:root.frozen;loops:Animation.Infinite
                                NumberAnimation{from:0;to:panelRect.height;duration:3500;easing.type:Easing.Linear}
                                PauseAnimation{duration:600}
                            }
                        }

                        Rectangle {
                            id:wipeCurtain;anchors.fill:parent;color:"#EBE3D1";z:50
                            transform:Scale{id:wipeScale;xScale:1;yScale:1;origin.x:0;origin.y:0}
                        }

                        Column {
                            id: panelCol
                            width:308
                            anchors{top:parent.top;topMargin:36;horizontalCenter:parent.horizontalCenter}
                            spacing:0

                            Item { width:parent.width;height:90
                                Rectangle{width:76;height:76;border.color:"#857B66";border.width:1;color:"transparent"
                                    anchors.horizontalCenter:parent.horizontalCenter
                                    Rectangle{width:52;height:52;color:"#857B66";anchors.centerIn:parent
                                        transform:Rotation{angle:45;origin.x:26;origin.y:26}}
                                    Text{text:"NR";font.family:"Share Tech Mono";font.pixelSize:7;color:"#B3A88C";opacity:0.5;anchors.top:parent.top;anchors.left:parent.left;anchors.margins:3}
                                    Text{text:"2B";font.family:"Share Tech Mono";font.pixelSize:7;color:"#B3A88C";opacity:0.5;anchors.bottom:parent.bottom;anchors.right:parent.right;anchors.margins:3}
                                }
                            }
                            Text{text:root.currentUser.toUpperCase();font.family:"Share Tech Mono";font.pixelSize:13;font.letterSpacing:3;color:"#857B66";anchors.horizontalCenter:parent.horizontalCenter}
                            Item{width:1;height:4}
                            Text{text:"UNIT · ACTIVE";font.family:"Share Tech Mono";font.pixelSize:8;font.letterSpacing:2;color:"#B3A88C";anchors.horizontalCenter:parent.horizontalCenter}
                            Item{width:1;height:20}
                            Text{text:root.clockStr;font.family:"Share Tech Mono";font.pixelSize:46;font.letterSpacing:2;color:"#857B66";anchors.horizontalCenter:parent.horizontalCenter}
                            Item{width:1;height:6}
                            Text{text:root.dateStr;font.family:"Share Tech Mono";font.pixelSize:9;font.letterSpacing:3;color:"#B3A88C";anchors.horizontalCenter:parent.horizontalCenter}
                            Item{width:1;height:20}
                            Rectangle{width:parent.width;height:1;color:Qt.rgba(43/255, 36/255, 25/255,0.22)}
                            Item{width:1;height:22}

                            Item { width:parent.width;height:40
                                Rectangle{anchors.fill:parent;color:"transparent"
                                    border.color:inputScope.activeFocus?"#857B66":Qt.rgba(43/255, 36/255, 25/255,0.22);border.width:1
                                    radius: 8
                                    Behavior on border.color{ColorAnimation{duration:200}}}
                                Text{anchors.left:parent.left;anchors.leftMargin:10;anchors.verticalCenter:parent.verticalCenter;text:"▸";font.pixelSize:10;color:"#8C1A16"}
                                FocusScope {
                                    id:inputScope
                                    anchors{fill:parent;leftMargin:26;rightMargin:10}
                                    focus: root.frozen
                                    TextInput {
                                        id:pwInput;anchors.fill:parent
                                        verticalAlignment:TextInput.AlignVCenter
                                        font.family:"Share Tech Mono";font.pixelSize:12;font.letterSpacing:2
                                        color:"#857B66";echoMode:TextInput.Password;passwordCharacter:"·"
                                        focus:true;readOnly:false
                                        text:root.lockInput
                                        onTextEdited: { root.lockInput=text }
                                        Keys.onReturnPressed: { root.doAuth() }
                                        Keys.onEscapePressed: { root.lockInput="" }
                                        Text{visible:parent.text==="";anchors.verticalCenter:parent.verticalCenter
                                            text:"password...";font.family:"Share Tech Mono";font.pixelSize:11;font.italic:true;color:"#B3A88C";opacity:0.5}
                                    }
                                }
                            }
                            Item{width:1;height:8}

                            Row{anchors.horizontalCenter:parent.horizontalCenter;spacing:6
                                Repeater{model:6;Rectangle{width:6;height:6;color:"transparent";border.color:"#B3A88C";border.width:1
                                    Rectangle{visible:index<root.lockInput.length;anchors.fill:parent;color:"#857B66"}}}}
                            Item{width:1;height:6}

                            Text{text:"AUTHENTICATION FAILED";font.family:"Share Tech Mono";font.pixelSize:8;font.letterSpacing:2;color:"#8C1A16"
                                anchors.horizontalCenter:parent.horizontalCenter
                                opacity:root.lockError?1:0;height:14;Behavior on opacity{NumberAnimation{duration:200}}}
                            Item{width:1;height:10}

                            Item{width:parent.width;height:42
                                Rectangle{anchors.fill:parent;color:"transparent";border.color:"#857B66";border.width:1;radius:8;clip:true}
                                Rectangle{id:unlockFill;anchors.left:parent.left;anchors.top:parent.top;anchors.bottom:parent.bottom;color:"#857B66";width:0;radius:8
                                    Behavior on width{NumberAnimation{duration:280;easing.type:Easing.InOutQuart}}}
                                Text{anchors.centerIn:parent;text:"Login";font.family:"Share Tech Mono";font.pixelSize:10;font.letterSpacing:3
                                    color:unlockMA.containsMouse?"#EBE3D1":"#857B66";Behavior on color{ColorAnimation{duration:200}}}
                                MouseArea{id:unlockMA;anchors.fill:parent;hoverEnabled:true
                                    onEntered:unlockFill.width=parent.width;onExited:unlockFill.width=0
                                    onClicked:root.doAuth()}
                            }
                        }
                    }
                }

                Timer {
                    id: focusRetry
                    interval: 100
                    repeat: true
                    running: root.frozen && !root.hiding && !root.done
                    onTriggered: if (!pwInput.activeFocus) pwInput.forceActiveFocus()
                }

                Rectangle {
                    anchors.fill: parent
                    color: "black"
                    z: 10
                    visible: root.done
                }

                Timer {
                    id: exitTimer; interval: 50; repeat: false
                    onTriggered: Qt.quit()
                }
            }

            Connections {
                target: root
                function onFrozenChanged() {
                    if (root.fastMode && root.frozen) {
                        panelOpenTimer.restart()
                    }
                }
                function onHidingChanged() {
                    if (root.hiding) {
                        if (root.fastMode) {
                            root.done = true
                            if (isPrimary) exitTimer.restart()
                            return
                        }
                        reveal.stop()
                        panelHide.start()
                        hide.position = 0
                        hide.play()
                        if (isPrimary) hideFadeTimer.restart()
                    }
                }
                function onRevealingChanged() {
                    if (root.revealing) {
                        root.frozen = true
                        reveal.position = 0
                        reveal.play()
                        panelOpenTimer.restart()
                    }
                }
                function onLockErrorChanged() {
                    if (root.lockError) shakeAnim.restart()
                }
            }

            Timer {
                id: panelOpenTimer
                interval: 100
                repeat: false
                onTriggered: {
                    if (root.fastMode) {
                        wipeScale.yScale = 0
                        if (isPrimary) {
                            pwInput.forceActiveFocus()
                            focusRetry.restart()
                        }
                    } else {
                        panelReveal.start()
                    }
                }
            }

            Component.onCompleted: {
                if (!root.fastMode) {
                    reveal.position = 0
                    reveal.play()
                }
            }
        }
    }

    // Clock
    property string clockStr:  "--:--"
    property string dateStr:   "---- / -- / --"
    property string clockFull: "--:--:--"
    Timer {
        interval:1000;running:true;repeat:true
        onTriggered:{
            var d=new Date(),p=function(x){return String(x).padStart(2,"0")}
            root.clockStr  = p(d.getHours())+":"+p(d.getMinutes())
            root.clockFull = p(d.getHours())+":"+p(d.getMinutes())+":"+p(d.getSeconds())
            root.dateStr   = d.getFullYear()+" / "+p(d.getMonth()+1)+" / "+p(d.getDate())
        }
    }
}
