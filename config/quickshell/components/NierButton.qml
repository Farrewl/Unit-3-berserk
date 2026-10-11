import QtQuick

// NieR button: fill-slide hover + flash on click
// Usage :
//   NierButton { label: "PLAY"; onClicked: doSomething() }

Item {
    id: root

    property string label:      ""
    property color  fgColor:    Qt.rgba(235/255, 227/255, 209/255, 0.5)
    property color  fgHover:    Qt.rgba(13/255, 10/255, 7/255,  1.0)
    property color  fillColor:  Qt.rgba(235/255, 227/255, 209/255, 1.0)
    property color  borderColor: Qt.rgba(235/255, 227/255, 209/255, 0.18)
    property int    fontSize:   8
    property real   letterSpacing: 1.5
    property int    padH:       12   // padding horizontal
    property int    padV:       5    // padding vertical
    property int    radius:     6    // rounded corners

    signal clicked

    implicitWidth:  label_text.implicitWidth + padH * 2
    implicitHeight: label_text.implicitHeight + padV * 2

    // Border
    Rectangle {
        anchors.fill: parent
        color:        "transparent"
        border.color: root.borderColor
        border.width: 1
        radius:       root.radius
        clip:         true
    }

    // Fill slide (left to right)
    Rectangle {
        id:     fillRect
        anchors {
            left:   parent.left
            top:    parent.top
            bottom: parent.bottom
        }
        width: 0
        color: root.fillColor
        radius: root.radius

        Behavior on width {
            NumberAnimation {
                duration: 220
                easing.type: Easing.InOutQuart
            }
        }
    }

    // Flash on click
    Rectangle {
        id:      clickFlash
        anchors.fill: parent
        color:   Qt.rgba(1, 1, 1, 0)
        opacity: 0
        radius:  root.radius

        NumberAnimation {
            id:       flashAnim
            target:   clickFlash
            property: "opacity"
            from:     0.18
            to:       0
            duration: 280
            easing.type: Easing.OutQuad
        }
    }

    // Label
    Text {
        id:             label_text
        anchors.centerIn: parent
        text:           root.label
        font.family:    "Share Tech Mono"
        font.pixelSize: root.fontSize
        font.letterSpacing: root.letterSpacing
        color: ma.containsMouse ? root.fgHover : root.fgColor

        Behavior on color {
            ColorAnimation { duration: 150 }
        }

        // Z-order positioning above the fill
        z: 1
    }

    MouseArea {
        id:           ma
        anchors.fill: parent
        hoverEnabled: true

        onEntered: fillRect.width = root.width
        onExited:  fillRect.width = 0

        onClicked: {
            flashAnim.start()
            root.clicked()
        }
    }
}
