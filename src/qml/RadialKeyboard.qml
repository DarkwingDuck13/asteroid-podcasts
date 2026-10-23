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

    Rectangle {
        anchors.fill: parent
        color: "#000000"
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
                width: 36
                height: 36
                
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

            // Ring touch zone strictly on outer rim (135px to 205px)
            if (dist >= 135 && dist <= 205) {
                keyboardRoot.isScrubbing = true;
                
                var angle = Math.atan2(dy, dx) * (180.0 / Math.PI) + 90.0;
                if (angle < 0) angle += 360.0;

                var chars = keyboardRoot.currentChars();
                var index = Math.floor((angle / 360.0) * chars.length) % chars.length;
                var newChar = chars[index];

                if (newChar !== keyboardRoot.activeHoverChar) {
                    keyboardRoot.activeHoverChar = newChar;
                    keyboardRoot.hapticPulse(25); // Stronger 25ms tick
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
    // 3. CURVED CENTER CONTROL HUB (Z=10, 100% TOUCH PRIORITY)
    // ==========================================
    Rectangle {
        id: centerHub
        width: 270
        height: 270
        radius: 135
        anchors.centerIn: parent
        color: "#0d0d12"
        border.color: "#00d2ff"
        border.width: 2
        clip: true
        z: 10

        // TOP: Text preview & Lens
        Column {
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width
            spacing: 0

            // Header: Dial Bank + Page Dots
            Rectangle {
                width: parent.width
                height: 38
                color: "#181824"

                Row {
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        text: keyboardRoot.bankNames[keyboardRoot.currentMode + 1]
                        color: "#00d2ff"
                        font.bold: true
                        font.pixelSize: 13
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
                                color: (index - 1 === keyboardRoot.currentMode) ? "#00ff66" : "#ffffff"
                            }
                        }
                    }
                }
            }

            // High-Contrast Output Box
            Rectangle {
                width: parent.width
                height: 42
                color: "#000000"

                Text {
                    anchors.centerIn: parent
                    width: parent.width - 24
                    text: keyboardRoot.text.length > 0 ? keyboardRoot.text : "TOUCH RIM TO TYPE"
                    color: keyboardRoot.text.length > 0 ? "#00ff66" : "#00d2ff"
                    font.pixelSize: 18
                    font.bold: true
                    elide: Text.ElideLeft
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            // The Magnifier Lens
            Rectangle {
                width: parent.width
                height: 44
                color: keyboardRoot.isScrubbing ? "#2c123a" : "#0d0d12"

                Text {
                    anchors.centerIn: parent
                    text: keyboardRoot.activeHoverChar.length > 0 ? keyboardRoot.activeHoverChar : "◄ SWIPE HERE TO FLIP ►"
                    color: keyboardRoot.isScrubbing ? "#00ff66" : "#ffffff"
                    font.bold: true
                    font.pixelSize: keyboardRoot.isScrubbing ? 38 : 12
                }
            }
        }

        // BOTTOM: CURVED BUTTON COCKPIT (Hugs the bottom arc flush!)
        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: 146
            color: "#121218"

            Column {
                anchors.fill: parent

                // Row 1: Backspace & Space (Height 64px)
                Row {
                    width: parent.width
                    height: 64

                    // Giant Backspace Button
                    Rectangle {
                        width: parent.width / 2
                        height: parent.height
                        color: delMouse.pressed ? "#991111" : "#551111"
                        border.color: "#772222"
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "⌫ DEL"
                            color: "#ffffff"
                            font.bold: true
                            font.pixelSize: 19
                        }

                        MouseArea {
                            id: delMouse
                            anchors.fill: parent
                            z: 20
                            onClicked: {
                                keyboardRoot.hapticPulse(35);
                                if (keyboardRoot.text.length > 0) {
                                    keyboardRoot.text = keyboardRoot.text.substring(0, keyboardRoot.text.length - 1);
                                }
                            }
                        }
                    }

                    // Giant Space Button
                    Rectangle {
                        width: parent.width / 2
                        height: parent.height
                        color: spaceMouse.pressed ? "#444455" : "#242432"
                        border.color: "#343444"
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "␣ SPACE"
                            color: "#ffffff"
                            font.bold: true
                            font.pixelSize: 19
                        }

                        MouseArea {
                            id: spaceMouse
                            anchors.fill: parent
                            z: 20
                            onClicked: {
                                keyboardRoot.hapticPulse(25);
                                keyboardRoot.text += " ";
                            }
                        }
                    }
                }

                // Row 2: Giant Green SEARCH Bar (Curved bottom corners match centerHub circle!)
                Rectangle {
                    width: parent.width
                    height: 82
                    radius: 135
                    color: enterMouse.pressed ? "#1ea852" : "#00ff66"

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: 16
                        text: "↵ SEARCH"
                        color: "#000000"
                        font.bold: true
                        font.pixelSize: 22
                    }

                    MouseArea {
                        id: enterMouse
                        anchors.fill: parent
                        z: 20
                        onClicked: {
                            keyboardRoot.hapticPulse(50);
                            keyboardRoot.accepted(keyboardRoot.text);
                            keyboardRoot.close();
                        }
                    }
                }
            }
        }

        // Swipe Detector
        MouseArea {
            id: hubSwipe
            width: parent.width
            height: 124
            anchors.top: parent.top
            z: 15
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
}
