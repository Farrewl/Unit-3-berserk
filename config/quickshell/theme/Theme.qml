pragma Singleton
import QtQuick

QtObject {
  // Main colors — Berserk parchment/blood palette
  readonly property color bg:     "#0D0A07"
  readonly property color bg2:    "#14100B"
  readonly property color bg3:    "#1D1913"
  readonly property color fg:     "#EBE3D1"
  readonly property color fgd:    Qt.rgba(235/255, 227/255, 209/255, 0.5)
  readonly property color fgdd:   Qt.rgba(235/255, 227/255, 209/255, 0.2)

  // Accents
  readonly property color a1:     "#8C1A16"
  readonly property color a2:     "#B42E28"
  readonly property color a3:     "#857B66"
  readonly property color a4:     "#C5A253"

  // Borders
  readonly property color ln:     Qt.rgba(235/255, 227/255, 209/255, 0.14)
  readonly property color lnm:    Qt.rgba(235/255, 227/255, 209/255, 0.24)

  // Rounded shapes
  readonly property int radPanel: 14
  readonly property int radCard:  10
  readonly property int radBtn:   6

  // Font
  readonly property string mono:  "Share Tech Mono"

  // Timings animations
  readonly property int durationFast:   150
  readonly property int durationMid:    380
  readonly property int durationSlow:   650
}