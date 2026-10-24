import QtQuick
import QtQuick.Controls

Item {
    id: keyboardRoot
    width: 400
    height: 400
    visible: false

    property string text: ""
    property int currentMode: 0
    property real dialRotation: 0
    property int selectedIndex: 0
    property string selectedChar: ""

    signal accepted(string resultText)
    signal canceled()

    function open(initialText) {
        text = initialText || ""
        currentMode = 0
        dialRotation = 0
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

    // Low-poly faceted background
    FacetedBackground { anchors.fill: parent }

    // Dim overlay
    Rectangle {
        anchors.fill: parent
        color: "#bf000000"
    }

    // ==========================================
    // 1. TOP TARGET APERTURE (12:00 INDICATOR)
    // ==========================================
    Text {
        anchors.top: parent.top
        anchors.topMargin: 2
        anchors.horizontalCenter: parent.horizontalCenter
        text: "▼"
        color: "#00ffcc"
        font.pixelSize: 13
        z: 30
    }

    // ==========================================
    // 2. THE ROTATING BEZEL DIAL
    // ==========================================
    Item {
        id: dialContainer
        anchors.centerIn: parent
        width: 400
        height: 400
        rotation: keyboardRoot.dialRotation

        Repeater {
            model: keyboardRoot.currentChars().length
            delegate: Item {
                width: 36
                height: 36
                
                // Position around the 168px radius rim
                property real baseAngleDeg: (index / keyboardRoot.currentChars().length) * 360.0 - 90.0
                property real angleRad: baseAngleDeg * (Math.PI / 180.0)
                property string ch: keyboardRoot.currentChars()[index]

                x: 200 + 168 * Math.cos(angleRad) - width / 2
                y: 200 + 168 * Math.sin(angleRad) - height / 2

                // Calculate angular distance to the 12:00 aperture (-90 degrees)
                property real effectiveAngle: (baseAngleDeg + keyboardRoot.dialRotation + 90.0) % 360.0
                property real normalizedAngle: (effectiveAngle < 0 ? effectiveAngle + 360.0 : effectiveAngle)
                property real distToTop: Math.min(normalizedAngle, 360.0 - normalizedAngle)
                property bool isAtTop: distToTop < (180.0 / keyboardRoot.currentChars().length)

                Text {
                    anchors.centerIn: parent
                    text: parent.ch
                    color: parent.isAtTop ? "#00ffcc" : (parent.distToTop < 45 ? "#ffffff" : "#99bacc")
                    font.bold: true
                    font.pixelSize: parent.isAtTop ? 36 : (parent.distToTop < 45 ? 20 : 16)
                    font.family: "Monospace"

                    Behavior on font.pixelSize { NumberAnimation { duration: 60 } }
                }
            }
        }
    }

    // ==========================================
    // 3. DIAL TOUCH & FLICK PHYSICS (ANYWHERE ON RIM / 6:00 THUMB)
    // ==========================================
    MouseArea {
        id: rimTouch
        anchors.fill: parent
        z: 1 // Lowest layer

        property real lastAngle: 0
        property real angularVelocity: 0

        function getAngle(mouse) {
            var dx = mouse.x - 200;
            var dy = mouse.y - 200;
            return Math.atan2(dy, dx) * (180.0 / Math.PI);
        }

        onPressed: function(mouse) {
            inertiaAnim.stop();
            lastAngle = getAngle(mouse);
            angularVelocity = 0;
        }

        onPositionChanged: function(mouse) {
            var curAngle = getAngle(mouse);
            var delta = curAngle - lastAngle;

            // Handle 180/-180 wrap
            if (delta > 180) delta -= 360;
            if (delta < -180) delta += 360;

            keyboardRoot.dialRotation += delta;
            angularVelocity = delta;
            lastAngle = curAngle;

            // Update selected character at 12:00
            updateSelection();
        }

        onReleased: function(mouse) {
            // Commit the selected letter at 12:00 on release!
            if (keyboardRoot.selectedChar.length > 0) {
                keyboardRoot.hapticPulse(35);
                keyboardRoot.text += keyboardRoot.selectedChar;
            }

            // Start kinetic flick spin
            if (Math.abs(angularVelocity) > 2) {
                inertiaAnim.from = keyboardRoot.dialRotation;
                inertiaAnim.to = keyboardRoot.dialRotation + (angularVelocity * 10);
                inertiaAnim.start();
            }
        }

        function updateSelection() {
            var chars = keyboardRoot.currentChars();
            var step = 360.0 / chars.length;
            // Calculate which index is sitting at -90 deg (12:00)
            var rot = (-keyboardRoot.dialRotation) % 360.0;
            if (rot < 0) rot += 360.0;

            var idx = Math.round(rot / step) % chars.length;
            if (idx !== keyboardRoot.selectedIndex) {
                keyboardRoot.selectedIndex = idx;
                keyboardRoot.selectedChar = chars[idx];
                keyboardRoot.hapticPulse(25); // Mechanical tactile click!
            }
        }
    }

    NumberAnimation {
        id: inertiaAnim
        target: keyboardRoot
        property: "dialRotation"
        duration: 600
        easing.type: Easing.OutCubic
        onRunningChanged: {
            if (!running) rimTouch.updateSelection();
        }
    }

    // ==========================================
    // 4. CLEAN CENTER HUB (NO BLUE CIRCLE, PURE FLOATING UI)
    // ==========================================
    Item {
        anchors.centerIn: parent
        width: 250
        height: 250
        z: 10

        Column {
            anchors.fill: parent
            spacing: 8

            // Top Header: Shifted Up
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
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
                            color: (index - 1 === keyboardRoot.currentMode) ? "#00ffcc" : "#66ffffff"
                        }
                    }
                }
            }

            // Pure Floating Text Input (No Box, Enlarged 22px Font)
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - 20
                text: keyboardRoot.text.length > 0 ? keyboardRoot.text : "Spin dial to type..."
                color: keyboardRoot.text.length > 0 ? "#ffffff" : "#66b2cc"
                font.pixelSize: 22
                font.bold: true
                elide: Text.ElideLeft
                horizontalAlignment: Text.AlignHCenter
            }

            Item { width: 1; height: 12 } // Spacer

            // 3 Pure Circular Wireframe Action Buttons (Matching Image 1 & Image 3!)
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 20

                // 1. Circular Backspace (⌫)
                Rectangle {
                    width: 54
                    height: 54
                    radius: 27
                    color: delBtnMouse.pressed ? "#441111" : "transparent"
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

                // 2. Circular Confirm (✓) - Directly from Image 1!
                Rectangle {
                    width: 64
                    height: 64
                    radius: 32
                    color: okBtnMouse.pressed ? "#00ffcc" : "transparent"
                    border.color: okBtnMouse.pressed ? "#00ffcc" : "#ffffff"
                    border.width: 2.5

                    Text {
                        anchors.centerIn: parent
                        text: "✓"
                        color: okBtnMouse.pressed ? "#000000" : "#ffffff"
                        font.bold: true
                        font.pixelSize: 32
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
                    width: 54
                    height: 54
                    radius: 27
                    color: spaceBtnMouse.pressed ? "#113344" : "transparent"
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

        // Center Swipe to Change Dial Banks
        MouseArea {
            id: hubSwipe
            width: parent.width
            height: 110
            anchors.top: parent.top
            z: 15
            property real startX: 0

            onPressed: function(mouse) { startX = mouse.x; }
            onReleased: function(mouse) {
                var delta = mouse.x - startX;
                if (Math.abs(delta) > 30) {
                    keyboardRoot.hapticPulse(35);
                    if (delta < 0) {
                        if (keyboardRoot.currentMode < 2) keyboardRoot.currentMode++;
                    } else {
                        if (keyboardRoot.currentMode > -1) keyboardRoot.currentMode--;
                    }
                    rimTouch.updateSelection();
                }
            }
        }
    }
}
