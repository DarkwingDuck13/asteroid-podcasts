import QtQuick
import QtQuick.Controls

Item {
    id: keyboardRoot
    width: 400
    height: 400
    visible: false

    property string text: ""
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

    // Native AsteroidOS Deep Teal Background
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#0c2430" }
            GradientStop { position: 0.7; color: "#06131a" }
            GradientStop { position: 1.0; color: "#02070a" }
        }
    }

    // ==========================================
    // 1. ROTARY LETTER RIM
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
                    color: (keyboardRoot.activeHoverChar === parent.ch) ? "#00ffcc" : "#ffffff"
                    font.bold: true
                    font.pixelSize: (keyboardRoot.activeHoverChar === parent.ch) ? 34 : 17
                    font.family: "Monospace"

                    Behavior on font.pixelSize {
                        NumberAnimation { duration: 70 }
                    }
                }
            }
        }
    }

    // ==========================================
    // 2. RIM TOUCH SENSOR (Z=1, NEVER INTERFERES WITH BUTTONS)
    // ==========================================
    MouseArea {
        id: rimTouch
        anchors.fill: parent
        z: 1

        function updateHover(mouse) {
            var dx = mouse.x - 200;
            var dy = mouse.y - 200;
            var dist = Math.sqrt(dx * dx + dy * dy);

            // Ring touch zone strictly on outer rim
            if (dist >= 135 && dist <= 205) {
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

    // ==========================================
    // 3. CIRCULAR CENTER CONTROL HUB (ASTEROID STYLE)
    // ==========================================
    Rectangle {
        id: centerHub
        width: 240
        height: 240
        radius: 120
        anchors.centerIn: parent
        color: "#0a1820"
        border.color: "#00d2ff"
        border.width: 2
        z: 10

        Column {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 6

            // Header: Dial Bank + Page Dots
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 8

                Text {
                    text: keyboardRoot.bankNames[keyboardRoot.currentMode + 1]
                    color: "#00d2ff"
                    font.bold: true
                    font.pixelSize: 12
                }

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4
                    Repeater {
                        model: 4
                        Rectangle {
                            width: (index - 1 === keyboardRoot.currentMode) ? 14 : 5
                            height: 5
                            radius: 2.5
                            color: (index - 1 === keyboardRoot.currentMode) ? "#00ffcc" : "#ffffff"
                        }
                    }
                }
            }

            // Output Box
            Rectangle {
                width: parent.width - 20
                height: 36
                anchors.horizontalCenter: parent.horizontalCenter
                color: "#050d12"
                radius: 18
                border.color: "#163442"

                Text {
                    anchors.centerIn: parent
                    width: parent.width - 20
                    text: keyboardRoot.text.length > 0 ? keyboardRoot.text : "Touch rim to type..."
                    color: keyboardRoot.text.length > 0 ? "#00ffcc" : "#6ea0b5"
                    font.pixelSize: 15
                    font.bold: true
                    elide: Text.ElideLeft
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            // Lens & Swipe Guide
            Rectangle {
                width: parent.width - 20
                height: 38
                anchors.horizontalCenter: parent.horizontalCenter
                color: "transparent"

                Text {
                    anchors.centerIn: parent
                    text: keyboardRoot.activeHoverChar.length > 0 ? keyboardRoot.activeHoverChar : "◄ Swipe Hub to Flip ►"
                    color: keyboardRoot.isScrubbing ? "#00ffcc" : "#ffffff"
                    font.bold: true
                    font.pixelSize: keyboardRoot.isScrubbing ? 34 : 11
                }
            }

            // CIRCULAR WIREFRAME BUTTON PANEL (MATCHING ASTEROID OS!)
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 16

                // 1. Circular Backspace (-)
                Rectangle {
                    width: 52
                    height: 52
                    radius: 26
                    color: delBtnMouse.pressed ? "#441a1a" : "transparent"
                    border.color: "#ffffff"
                    border.width: 2

                    Text {
                        anchors.centerIn: parent
                        text: "⌫"
                        color: "#ffffff"
                        font.pixelSize: 22
                    }

                    MouseArea {
                        id: delBtnMouse
                        anchors.fill: parent
                        onClicked: {
                            keyboardRoot.hapticPulse(35);
                            if (keyboardRoot.text.length > 0) {
                                keyboardRoot.text = keyboardRoot.text.substring(0, keyboardRoot.text.length - 1);
                            }
                        }
                    }
                }

                // 2. Circular Confirm (✓) - IDENTICAL TO IMAGE 1!
                Rectangle {
                    width: 60
                    height: 60
                    radius: 30
                    color: okBtnMouse.pressed ? "#00ffcc" : "transparent"
                    border.color: okBtnMouse.pressed ? "#00ffcc" : "#ffffff"
                    border.width: 2.5

                    Text {
                        anchors.centerIn: parent
                        text: "✓"
                        color: okBtnMouse.pressed ? "#000000" : "#ffffff"
                        font.bold: true
                        font.pixelSize: 28
                    }

                    MouseArea {
                        id: okBtnMouse
                        anchors.fill: parent
                        onClicked: {
                            keyboardRoot.hapticPulse(50);
                            keyboardRoot.accepted(keyboardRoot.text);
                            keyboardRoot.close();
                        }
                    }
                }

                // 3. Circular Space (␣)
                Rectangle {
                    width: 52
                    height: 52
                    radius: 26
                    color: spaceBtnMouse.pressed ? "#163442" : "transparent"
                    border.color: "#ffffff"
                    border.width: 2

                    Text {
                        anchors.centerIn: parent
                        text: "␣"
                        color: "#ffffff"
                        font.pixelSize: 22
                    }

                    MouseArea {
                        id: spaceBtnMouse
                        anchors.fill: parent
                        onClicked: {
                            keyboardRoot.hapticPulse(25);
                            keyboardRoot.text += " ";
                        }
                    }
                }
            }
        }

        // Swipe Area (Top half of hub)
        MouseArea {
            id: hubSwipe
            width: parent.width
            height: 120
            anchors.top: parent.top
            z: 15
            property real startX: 0

            onPressed: function(mouse) { startX = mouse.x; }
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
}
