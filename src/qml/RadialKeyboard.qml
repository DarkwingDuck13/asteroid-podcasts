/*
 * =====================================================================
 * Part of the AsteroidOS Custom Software Suite
 * Architecture, Engine & UI Engineering by Gemini (Google)
 * Co-Developed & Tested on-device by DarkwingDuck13
 *
 * Platform: AsteroidOS (Linux / Qt6 / OpenEmbedded / TicWatch Pro)
 * =====================================================================
 */

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
        text = initialText || "";
        currentMode = 0;
        dialRotation = 0;
        visible = true;
    }

    function close() {
        visible = false;
    }

    function hapticPulse(ms) {
        if (typeof engine !== "undefined" && engine.buzz) {
            engine.buzz(ms || 30);
        }
    }

    readonly property var bankNames: ["CAPITALS", "LOWERCASE", "NUMBERS", "SYMBOLS"]
    readonly property var charBanks: [
        "ABCDEFGHIJKLMNOPQRSTUVWXYZ",
        "abcdefghijklmnopqrstuvwxyz",
        "1234567890.,-_/@?!:",
        "+=*&%$#()_+-=/?!.,:;@~"
    ]

    function currentChars() {
        return charBanks[currentMode + 1];
    }

    FacetedBackground { anchors.fill: parent }

    Rectangle {
        anchors.fill: parent
        color: "#bf000000"
    }

    // ==========================================
    // 1. TOP TARGET APERTURE (12:00 INDICATOR)
    // ==========================================
    Text {
        anchors.top: parent.top
        anchors.topMargin: 4
        anchors.horizontalCenter: parent.horizontalCenter
        text: "\u25BC"
        color: "#ffffff"
        font.pixelSize: 14
        z: 30
    }

    // ==========================================
    // 2. THE ROTATING DIAL (FERRIS WHEEL UPRIGHT LETTERS)
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
                
                property real baseAngleDeg: (index / keyboardRoot.currentChars().length) * 360.0 - 90.0
                property real angleRad: baseAngleDeg * (Math.PI / 180.0)
                property string ch: keyboardRoot.currentChars()[index]

                x: 200 + 168 * Math.cos(angleRad) - width / 2
                y: 200 + 168 * Math.sin(angleRad) - height / 2

                property real effectiveAngle: (baseAngleDeg + keyboardRoot.dialRotation + 90.0) % 360.0
                property real normalizedAngle: (effectiveAngle < 0 ? effectiveAngle + 360.0 : effectiveAngle)
                property real distToTop: Math.min(normalizedAngle, 360.0 - normalizedAngle)
                property bool isAtTop: distToTop < (180.0 / keyboardRoot.currentChars().length)

                Text {
                    anchors.centerIn: parent
                    text: parent.ch
                    color: "#ffffff"
                    opacity: parent.isAtTop ? 1.0 : (parent.distToTop < 45 ? 0.75 : 0.4)
                    font.bold: parent.isAtTop
                    font.pixelSize: parent.isAtTop ? 38 : (parent.distToTop < 45 ? 20 : 16)
                    font.family: "Monospace"

                    // FERRIS WHEEL COUNTER-ROTATION: KEEPS CHARACTERS PERFECTLY UPRIGHT!
                    rotation: -dialContainer.rotation

                    Behavior on font.pixelSize { NumberAnimation { duration: 60 } }
                    Behavior on opacity { NumberAnimation { duration: 60 } }
                }
            }
        }
    }

    // ==========================================
    // 3. DIAL TOUCH & LUBRICATED FLICK INERTIA
    // ==========================================
    MouseArea {
        id: rimTouch
        anchors.fill: parent
        z: 1

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

            if (delta > 180) delta -= 360;
            if (delta < -180) delta += 360;

            keyboardRoot.dialRotation += (delta * 1.25);
            angularVelocity = delta;
            lastAngle = curAngle;

            updateSelection();
        }

        onReleased: function(mouse) {
            if (keyboardRoot.selectedChar.length > 0) {
                keyboardRoot.hapticPulse(65); // Solid 65ms selection thud!
                keyboardRoot.text += keyboardRoot.selectedChar;
            }

            if (Math.abs(angularVelocity) > 1.5) {
                inertiaAnim.from = keyboardRoot.dialRotation;
                inertiaAnim.to = keyboardRoot.dialRotation + (angularVelocity * 18);
                inertiaAnim.start();
            }
        }

        function updateSelection() {
            var chars = keyboardRoot.currentChars();
            var step = 360.0 / chars.length;
            var rot = (-keyboardRoot.dialRotation) % 360.0;
            if (rot < 0) rot += 360.0;

            var idx = Math.round(rot / step) % chars.length;
            if (idx !== keyboardRoot.selectedIndex) {
                keyboardRoot.selectedIndex = idx;
                keyboardRoot.selectedChar = chars[idx];
                keyboardRoot.hapticPulse(30); // 30ms mechanical tick
            }
        }
    }

    NumberAnimation {
        id: inertiaAnim
        target: keyboardRoot
        property: "dialRotation"
        duration: 900
        easing.type: Easing.OutCubic
        onRunningChanged: {
            if (!running) rimTouch.updateSelection();
        }
    }

    // ==========================================
    // 4. FLOATING CENTER HUB (NO BLUE CIRCLE, NO TUTORIAL TEXT)
    // ==========================================
    Item {
        anchors.centerIn: parent
        width: 230
        height: 230
        z: 10

        Column {
            anchors.fill: parent
            spacing: 6

            // Top Header: Active Bank Label + Dots (Shifted Up)
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 8

                Text {
                    text: keyboardRoot.bankNames[keyboardRoot.currentMode + 1]
                    color: "#ffffff"
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
                            color: "#ffffff"
                            opacity: (index - 1 === keyboardRoot.currentMode) ? 1.0 : 0.35
                        }
                    }
                }
            }

            // Clean Floating Output Text (Large 24px)
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - 20
                text: keyboardRoot.text.length > 0 ? keyboardRoot.text : " "
                color: "#ffffff"
                font.pixelSize: 24
                font.bold: true
                elide: Text.ElideLeft
                horizontalAlignment: Text.AlignHCenter
            }

            Item { width: 1; height: 4 }

            // 1. PROMINENT CONFIRM BUTTON (✓) ON ITS OWN LINE
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 62
                height: 62
                radius: 31
                color: okBtnMouse.pressed ? "#40ffffff" : "transparent"
                border.color: "#ffffff"
                border.width: 2.5

                Text {
                    anchors.centerIn: parent
                    text: "\u2713"
                    color: "#ffffff"
                    font.bold: true
                    font.pixelSize: 32
                }

                MouseArea {
                    id: okBtnMouse
                    anchors.fill: parent
                    onClicked: {
                        keyboardRoot.hapticPulse(65);
                        keyboardRoot.accepted(keyboardRoot.text);
                        keyboardRoot.close();
                    }
                }
            }

            // 2. LOWER ROW: BACKSPACE & SPACE (PULLED INWARD AWAY FROM RIM)
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 24

                // Backspace (⌫)
                Rectangle {
                    width: 54
                    height: 54
                    radius: 27
                    color: delBtnMouse.pressed ? "#40ffffff" : "transparent"
                    border.color: "#ffffff"
                    border.width: 2

                    Text {
                        anchors.centerIn: parent
                        text: "\u232B"
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

                // Space (␣)
                Rectangle {
                    width: 54
                    height: 54
                    radius: 27
                    color: spaceBtnMouse.pressed ? "#40ffffff" : "transparent"
                    border.color: "#ffffff"
                    border.width: 2

                    Text {
                        anchors.centerIn: parent
                        text: "\u2423"
                        color: "#ffffff"
                        font.pixelSize: 22
                    }

                    MouseArea {
                        id: spaceBtnMouse
                        anchors.fill: parent
                        onClicked: {
                            keyboardRoot.hapticPulse(30);
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
            height: 90
            anchors.top: parent.top
            z: 15
            property real startX: 0

            onPressed: function(mouse) { startX = mouse.x; }
            onReleased: function(mouse) {
                var delta = mouse.x - startX;
                if (Math.abs(delta) > 30) {
                    keyboardRoot.hapticPulse(40);
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
