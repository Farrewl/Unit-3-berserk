pragma Singleton
import QtQuick
import Quickshell

// ╔══════════════════════════════════════════════════════════════╗
// ║  SETTINGS — Unit-3 rice configuration options                ║
// ║  Edit the values below to customize the behaviour.           ║
// ╚══════════════════════════════════════════════════════════════╝

QtObject {

    // ── GLOBAL SCALE ────────────────────────────────────────────

    // Global multiplier applied to all sizes.
    // 1.0 = normal size, 1.25 = 25% larger, 0.8 = 20% smaller
    readonly property real scale: 1

    // Dimensions of the primary screen (equivalent to 100vw / 100vh)
    readonly property real screenW: Quickshell.screens.length > 0
                                    ? Quickshell.screens[0].width  : 1920
    readonly property real screenH: Quickshell.screens.length > 0
                                    ? Quickshell.screens[0].height : 1080

    // Relative units — usage: Settings.vw(5) = 5% of screen width
    function vw(pct) { return Math.round(screenW * pct / 100) }
    function vh(pct) { return Math.round(screenH * pct / 100) }

    // Scaled unit — applies scale on top of the base size.
    // Usage: Settings.s(320) = 320 * scale
    function s(px)   { return Math.round(px * scale) }

    // ── PLAYER ──────────────────────────────────────────────────

    // Player background: true = dark opaque background / false = transparent
    readonly property bool playerBackground: true

    // Background color (used only when playerBackground = true)
    readonly property color playerBgColor: Qt.rgba(13/255, 10/255, 7/255, 0.92)

    // Vertical position of the player (0.0 = top, 1.0 = bottom of screen)
    readonly property real playerPositionY: 0.39

    // Distance from the right edge in pixels
    readonly property int playerMarginRight: s(20)

    // Player width in pixels (scaled automatically)
    readonly property int playerWidth: s(320)


    // ── GLOBAL COLORS ───────────────────────────────────────────

    // Berserk palette (ink/blood/paper). Only change if you switch themes.
    readonly property color bg:   "#0D0A07"      // deepest background
    readonly property color bg2:  "#14100B"      // primary surface
    readonly property color bg3:  "#1D1913"      // raised surface
    readonly property color fg:   "#EBE3D1"      // parchment, primary text
    readonly property color fg2:  "#B3A88C"      // secondary text
    readonly property color fg3:  "#857B66"      // muted text
    readonly property color a1:   "#8C1A16"      // blood red accent
    readonly property color a2:   "#B42E28"      // bright red (hover)
    readonly property color a3:   "#C5A253"      // gold accent
    readonly property color ln:   Qt.rgba(235/255, 227/255, 209/255, 0.14)  // thin border
    readonly property color lnm:  Qt.rgba(235/255, 227/255, 209/255, 0.24)  // medium border
    readonly property color curtainColor: "#EBE3D1"  // wipe curtain color

    // ── ROUNDED SHAPES ──────────────────────────────────────────

    // Corner radius tokens — shared by all panels/buttons/bars.
    readonly property int radPanel: 14   // main panels (menu, control center, lockscreen, picker)
    readonly property int radCard:  10   // cards & popups
    readonly property int radBtn:   6    // buttons, inputs, chips


    // ── ANIMATIONS ──────────────────────────────────────────────

    // Reveal duration (ms)
    readonly property int revealDuration: 460

    // Hide duration (ms)
    readonly property int hideDuration: 380

    // Blocky cover transition duration (ms per step)
    readonly property int coverTransitionStep: 30


    // ── WAYBAR ──────────────────────────────────────────────────

    // Waybar height in pixels
    readonly property int waybarHeight: 28


    // ── KEYBINDS (must also be declared in hyprland.lua) ────────
    //   SUPER + Tab           → toggle Control Center (qs ctrl.sh)
    //   SUPER + Return        → show/hide player       (/tmp/qs-toggle)
    //   SUPER + SHIFT + Return→ player front/back      (/tmp/qs-front)
    //   SUPER + SHIFT + V     → toggle audio visualizer
    //   SUPER + P             → wallpaper picker
}