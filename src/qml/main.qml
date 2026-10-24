import QtQuick
import QtQuick.Controls

Item {
    id: root
    width: 400
    height: 400

    property string currentShowTitle: ""

    // State for Long-Press Delete
    property string deleteShowTitle: ""
    property string deleteEpTitle: ""

    // Native AsteroidOS Deep Teal Gradient (Matching Image 2)
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#0c2430" }
            GradientStop { position: 0.7; color: "#06131a" }
            GradientStop { position: 1.0; color: "#02070a" }
        }
    }

    SwipeView {
        id: swipeView
        anchors.fill: parent
        currentIndex: 1 // Opens to Player (Image 2 style)
        interactive: !radialOsk.visible && !deleteConfirmOverlay.visible

        // ==========================================
        // SCREEN 0: SUBSCRIPTIONS & EPISODES (NATIVE LIST)
        // ==========================================
        Item {
            Flickable {
                anchors.fill: parent
                anchors.margins: 35
                contentWidth: width
                contentHeight: subsCol.height
                clip: true

                Column {
                    id: subsCol
                    width: parent.width
                    spacing: 14

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Subscriptions"
                        color: "#ffffff"
                        font.bold: true
                        font.pixelSize: 22
                    }

                    // --- SECTION A: READY ON WATCH ---
                    Text {
                        text: "READY ON WATCH"
                        color: "#00ffcc"
                        font.bold: true
                        font.pixelSize: 13
                        visible: engine.downloadedEpisodes.length > 0
                    }

                    Repeater {
                        model: engine.downloadedEpisodes
                        delegate: Item {
                            width: subsCol.width
                            height: 60

                            Column {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 65

                                Text {
                                    text: modelData.epTitle
                                    color: "#ffffff"
                                    font.bold: true
                                    font.pixelSize: 15
                                    elide: Text.ElideRight
                                    width: parent.width
                                }
                                Text {
                                    text: modelData.showTitle + " • " + modelData.sizeMB
                                    color: "#00d2ff"
                                    font.pixelSize: 12
                                    elide: Text.ElideRight
                                    width: parent.width
                                }
                            }

                            // Circular Play Outline Button
                            Rectangle {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                width: 48
                                height: 48
                                radius: 24
                                color: playBtnMouse.pressed ? "#00ffcc" : "transparent"
                                border.color: playBtnMouse.pressed ? "#00ffcc" : "#ffffff"
                                border.width: 2

                                Text {
                                    anchors.centerIn: parent
                                    text: "▶"
                                    color: playBtnMouse.pressed ? "#000000" : "#ffffff"
                                    font.pixelSize: 18
                                }

                                MouseArea {
                                    id: playBtnMouse
                                    anchors.fill: parent
                                    onClicked: {
                                        engine.buzz(35);
                                        engine.playDirectFile(modelData.filePath, modelData.epTitle);
                                        swipeView.currentIndex = 1;
                                    }
                                    onPressAndHold: {
                                        engine.buzz(50);
                                        root.deleteShowTitle = modelData.showTitle;
                                        root.deleteEpTitle = modelData.epTitle;
                                        deleteConfirmOverlay.visible = true;
                                    }
                                }
                            }
                        }
                    }

                    Item { width: 1; height: 4; visible: engine.downloadedEpisodes.length > 0 }

                    // --- SECTION B: SHOW CHANNELS ---
                    Text {
                        text: "CHANNELS"
                        color: "#00d2ff"
                        font.bold: true
                        font.pixelSize: 13
                        visible: engine.subscriptions.length > 0
                    }

                    Repeater {
                        model: engine.subscriptions
                        delegate: Item {
                            width: subsCol.width
                            height: 56

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    engine.buzz(25);
                                    root.currentShowTitle = modelData.title;
                                    engine.loadEpisodes(modelData.title, modelData.feedUrl);
                                    episodeOverlay.open();
                                }
                            }

                            Text {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.title
                                color: "#ffffff"
                                font.bold: true
                                font.pixelSize: 16
                                width: parent.width - 55
                                elide: Text.ElideRight
                            }

                            // Circular Unsubscribe (✕)
                            Rectangle {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                width: 40
                                height: 40
                                radius: 20
                                color: unsubMouse.pressed ? "#ff4444" : "transparent"
                                border.color: "#ffffff"
                                border.width: 1.5

                                Text {
                                    anchors.centerIn: parent
                                    text: "✕"
                                    color: unsubMouse.pressed ? "#000" : "#ffffff"
                                    font.pixelSize: 16
                                }

                                MouseArea {
                                    id: unsubMouse
                                    anchors.fill: parent
                                    onClicked: {
                                        engine.buzz(40);
                                        engine.unsubscribe(modelData.feedUrl);
                                    }
                                }
                            }
                        }
                    }
                    Item { width: 1; height: 40 }
                }
            }
        }

        // ==========================================
        // SCREEN 1: NOW PLAYING (EXACT ASTEROID OS IMAGE 2 & 3 STYLE!)
        // ==========================================
        Item {
            // TOP: Track Title (Bold White) & Show Name (Regular White) - MATCHING IMAGE 2!
            Column {
                anchors.top: parent.top
                anchors.topMargin: 35
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - 50
                spacing: 4

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: engine.currentTrackTitle.length > 0 ? engine.currentTrackTitle : "Ready to Play"
                    color: "#ffffff"
                    font.bold: true
                    font.pixelSize: 22
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Radio Rental"
                    color: "#b0d8e8"
                    font.pixelSize: 15
                    elide: Text.ElideRight
                }
            }

            // CENTER CONTROLS: EXACT IMAGE 2 (PLAY) & IMAGE 3 (VOL - / VOL +)
            Row {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: 15
                spacing: 24

                // Circular VOL - Button ((-) directly from Image 3!)
                Rectangle {
                    width: 58
                    height: 58
                    radius: 29
                    color: volDownMouse.pressed ? "#00ffcc" : "transparent"
                    border.color: volDownMouse.pressed ? "#00ffcc" : "#ffffff"
                    border.width: 2.5

                    Text {
                        anchors.centerIn: parent
                        text: "−"
                        color: volDownMouse.pressed ? "#000000" : "#ffffff"
                        font.pixelSize: 28
                    }

                    MouseArea {
                        id: volDownMouse
                        anchors.fill: parent
                        onClicked: engine.volumeDown()
                    }
                }

                // Giant Solid White Play/Pause Glyph (DIRECTLY FROM IMAGE 2!)
                Item {
                    width: 68
                    height: 68

                    Text {
                        anchors.centerIn: parent
                        text: engine.playing ? "⏸" : "▶"
                        color: "#ffffff"
                        font.pixelSize: 52
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            engine.buzz(45);
                            engine.togglePlayPause();
                        }
                    }
                }

                // Circular VOL + Button ((+) directly from Image 3!)
                Rectangle {
                    width: 58
                    height: 58
                    radius: 29
                    color: volUpMouse.pressed ? "#00ffcc" : "transparent"
                    border.color: volUpMouse.pressed ? "#00ffcc" : "#ffffff"
                    border.width: 2.5

                    Text {
                        anchors.centerIn: parent
                        text: "+"
                        color: volUpMouse.pressed ? "#000000" : "#ffffff"
                        font.pixelSize: 28
                    }

                    MouseArea {
                        id: volUpMouse
                        anchors.fill: parent
                        onClicked: engine.volumeUp()
                    }
                }
            }

            // BOTTOM: Thin White Timeline & Monospace Timestamp
            Column {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 30
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - 60
                spacing: 6

                Slider {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width
                    from: 0
                    to: Math.max(1, engine.duration)
                    value: engine.position
                    onMoved: engine.seek(value)
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    function fmt(ms) {
                        var s = Math.floor(ms / 1000);
                        var m = Math.floor(s / 60);
                        return m + ":" + (s % 60 < 10 ? "0" : "") + (s % 60);
                    }
                    text: fmt(engine.position) + " / " + fmt(engine.duration)
                    color: "#00ffcc"
                    font.family: "Monospace"
                    font.pixelSize: 14
                }
            }
        }

        // ==========================================
        // SCREEN 2: SEARCH TO ADD
        // ==========================================
        Item {
            Flickable {
                anchors.fill: parent
                anchors.margins: 35
                contentWidth: width
                contentHeight: searchCol.height
                clip: true

                Column {
                    id: searchCol
                    width: parent.width
                    spacing: 14

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Add Podcasts"
                        color: "#ffffff"
                        font.bold: true
                        font.pixelSize: 22
                    }

                    // Circular Search Target
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: parent.width - 20
                        height: 54
                        radius: 27
                        color: searchBtnMouse.pressed ? "#00ffcc" : "transparent"
                        border.color: searchBtnMouse.pressed ? "#00ffcc" : "#ffffff"
                        border.width: 2

                        Row {
                            anchors.centerIn: parent
                            spacing: 8
                            Text { text: "🔍"; font.pixelSize: 18 }
                            Text {
                                text: "SEARCH PODCASTS"
                                color: searchBtnMouse.pressed ? "#000" : "#ffffff"
                                font.bold: true
                                font.pixelSize: 14
                            }
                        }

                        MouseArea {
                            id: searchBtnMouse
                            anchors.fill: parent
                            onClicked: {
                                engine.buzz(35);
                                radialOsk.open("");
                            }
                        }
                    }

                    Text {
                        text: engine.searching ? "Searching Apple Directory..." : (engine.searchResults.length > 0 ? "RESULTS" : "")
                        color: "#00ffcc"
                        font.bold: true
                        font.pixelSize: 13
                    }

                    Repeater {
                        model: engine.searchResults
                        delegate: Item {
                            width: searchCol.width
                            height: 60

                            Column {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 60

                                Text {
                                    text: modelData.title
                                    color: "#ffffff"
                                    font.bold: true
                                    font.pixelSize: 15
                                    elide: Text.ElideRight
                                    width: parent.width
                                }
                                Text {
                                    text: modelData.artist
                                    color: "#00d2ff"
                                    font.pixelSize: 12
                                    elide: Text.ElideRight
                                    width: parent.width
                                }
                            }

                            // Circular Subscribe Button (+)
                            Rectangle {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                width: 44
                                height: 44
                                radius: 22
                                color: subMouse.pressed ? "#00ffcc" : "transparent"
                                border.color: "#ffffff"
                                border.width: 2

                                Text {
                                    anchors.centerIn: parent
                                    text: "+"
                                    color: subMouse.pressed ? "#000" : "#ffffff"
                                    font.bold: true
                                    font.pixelSize: 22
                                }

                                MouseArea {
                                    id: subMouse
                                    anchors.fill: parent
                                    onClicked: {
                                        engine.buzz(45);
                                        engine.subscribe(modelData.title, modelData.feedUrl);
                                        swipeView.currentIndex = 0;
                                    }
                                }
                            }
                        }
                    }
                    Item { width: 1; height: 40 }
                }
            }
        }
    }

    // ==========================================
    // EPISODE LIST OVERLAY
    // ==========================================
    Rectangle {
        id: episodeOverlay
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#0c2430" }
            GradientStop { position: 1.0; color: "#02070a" }
        }
        visible: false

        function open() { visible = true; }
        function close() { visible = false; }

        Flickable {
            anchors.fill: parent
            anchors.margins: 35
            contentWidth: width
            contentHeight: epCol.height
            clip: true

            Column {
                id: epCol
                width: parent.width
                spacing: 12

                Row {
                    spacing: 10
                    // Circular Back Button (<)
                    Rectangle {
                        width: 44; height: 44; radius: 22
                        color: "transparent"
                        border.color: "#ffffff"
                        border.width: 2
                        Text { anchors.centerIn: parent; text: "‹"; color: "#fff"; font.bold: true; font.pixelSize: 24 }
                        MouseArea { anchors.fill: parent; onClicked: episodeOverlay.close() }
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.currentShowTitle
                        color: "#ffffff"
                        font.bold: true
                        font.pixelSize: 16
                        width: 150
                        elide: Text.ElideRight
                    }
                }

                // Download Progress
                Rectangle {
                    width: parent.width
                    height: 20
                    color: "#0a1820"
                    radius: 10
                    visible: engine.downloading

                    Rectangle {
                        height: parent.height
                        width: parent.width * (engine.downloadProgress / 100.0)
                        color: "#00ffcc"
                        radius: 10
                    }
                    Text {
                        anchors.centerIn: parent
                        text: "Downloading " + engine.downloadProgress + "%"
                        color: "#000000"
                        font.pixelSize: 11
                        font.bold: true
                    }
                }

                Repeater {
                    model: engine.episodes
                    delegate: Item {
                        width: epCol.width
                        height: 60

                        Column {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 60

                            Text {
                                text: modelData.title
                                color: "#ffffff"
                                font.bold: true
                                font.pixelSize: 14
                                elide: Text.ElideRight
                                width: parent.width
                            }
                            Text {
                                text: modelData.isDownloaded ? "On Watch" : "Cloud"
                                color: modelData.isDownloaded ? "#00ffcc" : "#6ea0b5"
                                font.pixelSize: 11
                            }
                        }

                        // Circular Action Button (▶ or ⬇)
                        Rectangle {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            width: 48
                            height: 48
                            radius: 24
                            color: epActionMouse.pressed ? "#00ffcc" : "transparent"
                            border.color: "#ffffff"
                            border.width: 2

                            Text {
                                anchors.centerIn: parent
                                text: modelData.isDownloaded ? "▶" : "⬇"
                                color: epActionMouse.pressed ? "#000" : "#ffffff"
                                font.pixelSize: 18
                            }

                            MouseArea {
                                id: epActionMouse
                                anchors.fill: parent
                                onClicked: {
                                    engine.buzz(30);
                                    if (modelData.isDownloaded) {
                                        engine.playEpisode(root.currentShowTitle, modelData.title);
                                        episodeOverlay.close();
                                        swipeView.currentIndex = 1;
                                    } else {
                                        engine.downloadEpisode(root.currentShowTitle, modelData.title, modelData.audioUrl);
                                    }
                                }
                                onPressAndHold: {
                                    if (modelData.isDownloaded) {
                                        engine.buzz(50);
                                        root.deleteShowTitle = root.currentShowTitle;
                                        root.deleteEpTitle = modelData.title;
                                        deleteConfirmOverlay.visible = true;
                                    }
                                }
                            }
                        }
                    }
                }
                Item { width: 1; height: 40 }
            }
        }
    }

    // ==========================================
    // LONG-PRESS DELETE MODAL (IMAGE 1 STYLE: (✕) and (✓))
    // ==========================================
    Rectangle {
        id: deleteConfirmOverlay
        anchors.fill: parent
        color: "#eb000000"
        visible: false
        z: 99

        Rectangle {
            width: 260
            height: 200
            radius: 130
            color: "#0c1820"
            border.color: "#ff4444"
            border.width: 2
            anchors.centerIn: parent

            Column {
                anchors.centerIn: parent
                spacing: 10
                width: parent.width - 30

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "DELETE EPISODE?"
                    color: "#ff4444"
                    font.bold: true
                    font.pixelSize: 14
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.deleteEpTitle
                    color: "#ffffff"
                    font.bold: true
                    font.pixelSize: 13
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    maximumLineCount: 2
                    wrapMode: Text.Wrap
                    elide: Text.ElideRight
                }

                // Circular Choice Buttons: (✕) and (✓)
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 24

                    Rectangle {
                        width: 50; height: 50; radius: 25
                        color: "transparent"
                        border.color: "#ffffff"
                        border.width: 2
                        Text { anchors.centerIn: parent; text: "✕"; color: "#fff"; font.pixelSize: 20 }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                engine.buzz(20);
                                deleteConfirmOverlay.visible = false;
                            }
                        }
                    }

                    Rectangle {
                        width: 50; height: 50; radius: 25
                        color: "transparent"
                        border.color: "#ff4444"
                        border.width: 2
                        Text { anchors.centerIn: parent; text: "✓"; color: "#ff4444"; font.pixelSize: 22; font.bold: true }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                engine.buzz(50);
                                engine.deleteDownloadedEpisode(root.deleteShowTitle, root.deleteEpTitle);
                                deleteConfirmOverlay.visible = false;
                            }
                        }
                    }
                }
            }
        }
    }

    // FULL-SCREEN RADIAL KEYBOARD OVERLAY
    RadialKeyboard {
        id: radialOsk
        anchors.fill: parent
        onAccepted: function(queryText) {
            if (queryText.trim().length > 0) {
                engine.search(queryText.trim());
                swipeView.currentIndex = 2;
            }
        }
    }
}
