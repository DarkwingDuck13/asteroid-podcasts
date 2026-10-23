import QtQuick
import QtQuick.Controls

Item {
    id: keyboardRoot
    width: 400
    height: 400
    visible: false

    property string text: ""
    // Mode: -1 = CAPS, 0 = lowercase (Home), 1 = Numbers, 2 = Symbols
    property int currentMode: 0
    property string activeHoverChar: ""
    property bool isScrubbing: false

    signal accepted(string resultText)
    signal canceled()

    function open(initialText) {
        text = initialText || ""
        currentMode = 0
        visible = true
    }

    function close() {
        visible = false
    }

    function hapticPulse(ms) {
        if (typeof engine !== "undefined" && engine.buzz) {
            engine.buzz(ms || 25);
        }
    }

    readonly property var bankNames: ["CAPITALS", "LOWERCASE", "NUMBERS", "SYMBOLS"]
    readonly property var charBanks: [
        "ABCDEFGHIJKLMNOPQRSTUVWXYZ",
        "abcdefghijklmnopqrstuvwxyz",
        "1234567890.,-_/@?!:",
        "+=*&%$#()[]{}\\|<>\"'~^;"
    ]

    function currentChars() {
        return charBanks[currentMode + 1];
    }

    Rectangle {
        anchors.fill: parent
        color: "#000000"
    }

    // ==========================================
    // 1. OUTER RIM (DIAL)
    // ==========================================
    Item {
        id: dial
        anchors.centerIn: parent
        width: 400
        height: 400

        Behavior on rotation {
            NumberAnimation { duration: 250; easing.type: Easing.OutBack }
        }

        Repeater {
            model: keyboardRoot.currentChars().length
            delegate: Item {
                width: 34
                height: 34
                
                property real angleDeg: (index / keyboardRoot.currentChars().length) * 360.0 - 90.0
                property real angleRad: angleDeg * (Math.PI / 180.0)
                property string ch: keyboardRoot.currentChars()[index]

                x: 200 + 168 * Math.cos(angleRad) - width / 2
                y: 200 + 168 * Math.sin(angleRad) - height / 2

                Text {
                    anchors.centerIn: parent
                    text: parent.ch
                    color: (keyboardRoot.activeHoverChar === parent.ch) ? "#00ff66" : "#ffffff"
                    font.bold: true
                    font.pixelSize: (keyboardRoot.activeHoverChar === parent.ch) ? 30 : 16
                    font.family: "Monospace"

                    Behavior on font.pixelSize {
                        NumberAnimation { duration: 80 }
                    }
                }
            }
        }
    }

    // ==========================================
    // 2. CENTER CONTROL PANEL
    // ==========================================
    Rectangle {
        id: centerHub
        width: 270
        height: 270
        radius: 135
        anchors.centerIn: parent
        color: "#111114"
        border.color: "#2a2a2e"
        border.width: 2
        clip: true

        Column {
            anchors.fill: parent
            spacing: 0

            // Header: Active Bank Label + Pagination
            Rectangle {
                width: parent.width
                height: 36
                color: "#1c1c22"

                Row {
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        text: keyboardRoot.bankNames[keyboardRoot.currentMode + 1]
                        color: "#00d2ff"
                        font.bold: true
                        font.pixelSize: 11
                    }

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4
                        Repeater {
                            model: 4
                            Rectangle {
                                width: (index - 1 === keyboardRoot.currentMode) ? 12 : 5
                                height: 5
                                radius: 2.5
                                color: (index - 1 === keyboardRoot.currentMode) ? "#00d2ff" : "#555555"
                            }
                        }
                    }
                }
            }

            // Live Text Output Box
            Rectangle {
                width: parent.width
                height: 38
                color: "#08080a"

                Text {
                    anchors.centerIn: parent
                    width: parent.width - 24
                    text: keyboardRoot.text.length > 0 ? keyboardRoot.text : "Tap rim to type..."
                    color: keyboardRoot.text.length > 0 ? "#ffffff" : "#666666"
                    font.pixelSize: 16
                    font.bold: true
                    elide: Text.ElideLeft
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            // The Magnifier Lens
            Rectangle {
                width: parent.width
                height: 44
                color: keyboardRoot.isScrubbing ? "#2c123a" : "#111114"

                Text {
                    anchors.centerIn: parent
                    text: keyboardRoot.activeHoverChar.length > 0 ? keyboardRoot.activeHoverChar : "◄ Swipe Hub ►"
                    color: keyboardRoot.isScrubbing ? "#00ff66" : "#444444"
                    font.bold: true
                    font.pixelSize: keyboardRoot.isScrubbing ? 34 : 12
                }
            }

            // SOLID TOUCH BUTTON PANEL
            Rectangle {
                width: parent.width
                height: 152
                color: "#16161a"

                Column {
                    anchors.fill: parent

                    // Row 1: Backspace & Space
                    Row {
                        width: parent.width
                        height: 52

                        Rectangle {
                            width: parent.width / 2
                            height: parent.height
                            color: delMouse.pressed ? "#661111" : "#2a1616"
                            border.color: "#3a2020"
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "⌫ DEL"
                                color: "#ff4444"
                                font.bold: true
                                font.pixelSize: 16
                            }

                            MouseArea {
                                id: delMouse
                                anchors.fill: parent
                                onClicked: {
                                    keyboardRoot.hapticPulse(35);
                                    if (keyboardRoot.text.length > 0) {
                                        keyboardRoot.text = keyboardRoot.text.substring(0, keyboardRoot.text.length - 1);
                                    }
                                }
                            }
                        }

                        Rectangle {
                            width: parent.width / 2
                            height: parent.height
                            color: spaceMouse.pressed ? "#333338" : "#222228"
                            border.color: "#333338"
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "␣ SPACE"
                                color: "#ffffff"
                                font.bold: true
                                font.pixelSize: 16
                            }

                            MouseArea {
                                id: spaceMouse
                                anchors.fill: parent
                                onClicked: {
                                    keyboardRoot.hapticPulse(25);
                                    keyboardRoot.text += " ";
                                }
                            }
                        }
                    }

                    // Row 2: Giant Green SEARCH Bar
                    Rectangle {
                        width: parent.width
                        height: 60
                        color: enterMouse.pressed ? "#22aa55" : "#00ff66"

                        Text {
                            anchors.centerIn: parent
                            text: "↵ SEARCH"
                            color: "#000000"
                            font.bold: true
                            font.pixelSize: 18
                        }

                        MouseArea {
                            id: enterMouse
                            anchors.fill: parent
                            onClicked: {
                                keyboardRoot.hapticPulse(50);
                                keyboardRoot.accepted(keyboardRoot.text);
                                keyboardRoot.close();
                            }
                        }
                    }
                }
            }
        }

        // Center Swipe Area (Swapping Character Banks)
        MouseArea {
            id: hubSwipe
            width: parent.width
            height: 118
            anchors.top: parent.top
            preventStealing: true
            property real startX: 0

            onPressed: function(mouse) {
                startX = mouse.x;
            }

            onReleased: function(mouse) {
                var delta = mouse.x - startX;
                if (Math.abs(delta) > 30) {
                    keyboardRoot.hapticPulse(35);
                    if (delta < 0) {
                        if (keyboardRoot.currentMode < 2) {
                            keyboardRoot.currentMode++;
                            dial.rotation -= 30;
                        }
                    } else {
                        if (keyboardRoot.currentMode > -1) {
                            keyboardRoot.currentMode--;
                            dial.rotation += 30;
                        }
                    }
                }
            }
        }
    }

    // ==========================================
    // 3. RADIAL TOUCH TRACKER
    // ==========================================
    MouseArea {
        id: rimTouch
        anchors.fill: parent

        function updateHover(mouse) {
            var dx = mouse.x - 200;
            var dy = mouse.y - 200;
            var dist = Math.sqrt(dx * dx + dy * dy);

            if (dist >= 125 && dist <= 210) {
                keyboardRoot.isScrubbing = true;
                
                var angle = Math.atan2(dy, dx) * (180.0 / Math.PI) + 90.0;
                if (angle < 0) angle += 360.0;

                var chars = keyboardRoot.currentChars();
                var index = Math.floor((angle / 360.0) * chars.length) % chars.length;
                var newChar = chars[index];

                if (newChar !== keyboardRoot.activeHoverChar) {
                    keyboardRoot.activeHoverChar = newChar;
                    keyboardRoot.hapticPulse(25);
                }
            } else {
                keyboardRoot.isScrubbing = false;
                keyboardRoot.activeHoverChar = "";
            }
        }

        onPressed: function(mouse) { updateHover(mouse); }
        onPositionChanged: function(mouse) { updateHover(mouse); }
        onReleased: function(mouse) {
            if (keyboardRoot.isScrubbing && keyboardRoot.activeHoverChar.length > 0) {
                keyboardRoot.hapticPulse(35);
                keyboardRoot.text += keyboardRoot.activeHoverChar;
                
                if (keyboardRoot.currentMode === -1) {
                    keyboardRoot.currentMode = 0;
                    dial.rotation += 30;
                }
            }
            keyboardRoot.isScrubbing = false;
            keyboardRoot.activeHoverChar = "";
        }
    }
}
