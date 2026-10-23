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

    // Trigger watch haptic feedback
    function hapticPulse(ms) {
        // Triggers Linux kernel vibrator driver directly
        var duration = ms || 18;
        var doc = new XMLHttpRequest();
        // Fallback or direct sysfs trigger via engine if exposed
        if (typeof engine !== "undefined" && engine.buzz) {
            engine.buzz(duration);
        }
    }

    // Character Banks
    readonly property var charBanks: [
        "ABCDEFGHIJKLMNOPQRSTUVWXYZ",                     // -1: CAPS
        "abcdefghijklmnopqrstuvwxyz",                     //  0: lowercase (Home)
        "1234567890.,-_/@?!:",                            //  1: Numbers & Punctuation
        "+=*&%$#()[]{}\\|<>\"'~^;"                        //  2: Extended Symbols
    ]

    function currentChars() {
        return charBanks[currentMode + 1];
    }

    Rectangle {
        anchors.fill: parent
        color: "#000000"
    }

    // ==========================================
    // 1. THE RADIAL CHARACTER RIM
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
                id: charItem
                width: 32
                height: 32
                
                // Calculate position on the outer rim (radius: 170px)
                property real angleDeg: (index / keyboardRoot.currentChars().length) * 360.0 - 90.0
                property real angleRad: angleDeg * (Math.PI / 180.0)
                property string ch: keyboardRoot.currentChars()[index]

                x: 200 + 168 * Math.cos(angleRad) - width / 2
                y: 200 + 168 * Math.sin(angleRad) - height / 2

                Text {
                    anchors.centerIn: parent
                    text: parent.ch
                    color: (keyboardRoot.activeHoverChar === parent.ch) ? "#00ff66" : "#aaaaaa"
                    font.bold: keyboardRoot.activeHoverChar === parent.ch
                    font.pixelSize: (keyboardRoot.activeHoverChar === parent.ch) ? 22 : 13
                    font.family: "Monospace"

                    Behavior on font.pixelSize {
                        NumberAnimation { duration: 100 }
                    }
                }
            }
        }
    }

    // ==========================================
    // 2. THE CENTER HUB (Controls & Preview)
    // ==========================================
    Rectangle {
        id: centerHub
        width: 250
        height: 250
        radius: 125
        anchors.centerIn: parent
        color: "#121214"
        border.color: "#28282c"
        border.width: 1

        Column {
            anchors.centerIn: parent
            spacing: 6
            width: parent.width - 30

            // Pagination Dots [ A | a | 123 | # ]
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 8
                Repeater {
                    model: 4
                    Rectangle {
                        width: (index - 1 === keyboardRoot.currentMode) ? 14 : 6
                        height: 6
                        radius: 3
                        color: (index - 1 === keyboardRoot.currentMode) ? "#8e44ad" : "#444444"
                        Behavior on width { NumberAnimation { duration: 150 } }
                    }
                }
            }

            // Text Preview Box
            Rectangle {
                width: parent.width
                height: 36
                color: "#1c1c1f"
                radius: 8
                clip: true

                Text {
                    anchors.centerIn: parent
                    width: parent.width - 16
                    text: keyboardRoot.text.length > 0 ? keyboardRoot.text : "..."
                    color: keyboardRoot.text.length > 0 ? "#ffffff" : "#666666"
                    font.pixelSize: 15
                    font.bold: true
                    elide: Text.ElideLeft
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            // The Magnifier Lens (Mirrors the hovered letter)
            Rectangle {
                width: 50
                height: 50
                radius: 25
                color: keyboardRoot.isScrubbing ? "#2c123a" : "transparent"
                border.color: keyboardRoot.isScrubbing ? "#8e44ad" : "transparent"
                border.width: 2
                anchors.horizontalCenter: parent.horizontalCenter

                Text {
                    anchors.centerIn: parent
                    text: keyboardRoot.activeHoverChar
                    color: "#00ff66"
                    font.bold: true
                    font.pixelSize: 32
                    visible: keyboardRoot.isScrubbing
                }
            }

            // Action Buttons
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 6

                Button {
                    text: "⌫"
                    width: 44
                    height: 36
                    palette.buttonText: "#ff4444"
                    onClicked: {
                        keyboardRoot.hapticPulse(25);
                        if (keyboardRoot.text.length > 0) {
                            keyboardRoot.text = keyboardRoot.text.substring(0, keyboardRoot.text.length - 1);
                        }
                    }
                }

                Button {
                    text: "␣"
                    width: 54
                    height: 36
                    onClicked: {
                        keyboardRoot.hapticPulse(18);
                        keyboardRoot.text += " ";
                    }
                }

                Button {
                    text: "↵ Done"
                    width: 68
                    height: 36
                    palette.buttonText: "#00ff66"
                    onClicked: {
                        keyboardRoot.hapticPulse(35);
                        keyboardRoot.accepted(keyboardRoot.text);
                        keyboardRoot.close();
                    }
                }
            }
        }

        // Center Swipe Area (Swapping Character Banks)
        MouseArea {
            anchors.fill: parent
            preventStealing: true
            property real startX: 0

            onPressed: (mouse) => {
                startX = mouse.x;
            }

            onReleased: (mouse) => {
                var delta = mouse.x - startX;
                if (Math.abs(delta) > 35) {
                    keyboardRoot.hapticPulse(25);
                    if (delta < 0) {
                        // Swipe Left: Next bank
                        if (keyboardRoot.currentMode < 2) {
                            keyboardRoot.currentMode++;
                            dial.rotation -= 30;
                        }
                    } else {
                        // Swipe Right: Previous bank
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
    // 3. RADIAL TOUCH TRACKER (THE RIM)
    // ==========================================
    MouseArea {
        id: rimTouch
        anchors.fill: parent

        function updateHover(mouse) {
            var dx = mouse.x - 200;
            var dy = mouse.y - 200;
            var dist = Math.sqrt(dx * dx + dy * dy);

            // Only track if touch is in the outer ring zone (125px to 200px)
            if (dist >= 120 && dist <= 210) {
                keyboardRoot.isScrubbing = true;
                
                // Calculate angle: 0 deg = Top (-90 in standard math)
                var angle = Math.atan2(dy, dx) * (180.0 / Math.PI) + 90.0;
                if (angle < 0) angle += 360.0;

                var chars = keyboardRoot.currentChars();
                var index = Math.floor((angle / 360.0) * chars.length) % chars.length;
                var newChar = chars[index];

                if (newChar !== keyboardRoot.activeHoverChar) {
                    keyboardRoot.activeHoverChar = newChar;
                    keyboardRoot.hapticPulse(12); // Crisp mechanical tick!
                }
            } else {
                keyboardRoot.isScrubbing = false;
                keyboardRoot.activeHoverChar = "";
            }
        }

        onPressed: (mouse) => updateHover(mouse)
        onPositionChanged: (mouse) => updateHover(mouse)
        onReleased: (mouse) => {
            if (keyboardRoot.isScrubbing && keyboardRoot.activeHoverChar.length > 0) {
                // Lift-Off Stamp: Commit the selected character!
                keyboardRoot.hapticPulse(30);
                keyboardRoot.text += keyboardRoot.activeHoverChar;
                
                // Auto-return to lowercase if we typed a capital letter
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
