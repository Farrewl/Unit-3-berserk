pragma Singleton
import QtQuick

QtObject {
  // Couleurs principales
  readonly property color bg:     "#14100B"
  readonly property color bg2:    "#1D1913"
  readonly property color bg3:    "#26211B"
  readonly property color fg:     "#E0DBCA"
  readonly property color fgd:    Qt.rgba(224/255, 219/255, 202/255, 0.5)
  readonly property color fgdd:   Qt.rgba(224/255, 219/255, 202/255, 0.2)

  // Accents
  readonly property color a1:     "#AD2E2A"
  readonly property color a2:     "#7A7568"
  readonly property color a3:     "#6A6358"
  readonly property color a4:     "#A89A78"

  // Bordures
  readonly property color ln:     Qt.rgba(224/255, 219/255, 202/255, 0.12)
  readonly property color lnm:    Qt.rgba(224/255, 219/255, 202/255, 0.22)

  // Font
  readonly property string mono:  "Share Tech Mono"

  // Timings animations
  readonly property int durationFast:   150
  readonly property int durationMid:    380
  readonly property int durationSlow:   650
}