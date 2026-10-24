import QtQuick
import QtQuick.Controls

Item {
    id: root
    width: 400
    height: 400

    property string currentShowTitle: ""

    // Dialog state for long-press deletion
    property string deleteShowTitle: ""
    property string deleteEpTitle: ""

    Rectangle {
        anchors.fill: parent
        color: "#000000"
    }

    SwipeView {
        id: swipeView
        anchors.fill: parent
        currentIndex: 1 // Starts on Screen 1 (Player / Home)
        interactive: !radialOsk.visible

        // ==========================================
        // SCREEN 0: SUBSCRIPTIONS & EPISODES
        // ==========================================
        Item {
            Flickable {
                anchors.fill: parent
                anchors.margins: 30
                contentWidth: width
                contentHeight: subsCol.height
                clip: true

                Column {
                    id: subsCol
                    width: parent.width
                    spacing: 12

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Subscriptions"
                        color: "#ffffff"
                        font.bold: true
                        font.pixelSize: 22
                    }

                    // --- SECTION A: READY ON WATCH (OFFLINE) ---
                    Text {
                        text: "READY ON WATCH (OFFLINE)"
                        color: "#00ff66"
                        font.bold: true
                        font.pixelSize: 13
                        visible: engine.downloadedEpisodes.length > 0
                    }

                    Repeater {
                        model: engine.downloadedEpisodes
                        delegate: Rectangle {
                            width: subsCol.width
                            height: 64
                            color: "#142416"
                            radius: 12
                            border.color: "#00ff66"
                            border.width: 1

                            Column {
                                anchors.left: parent.left
                                anchors.leftMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                width: 140

                                Text {
                                    text: modelData.epTitle
                                    color: "#ffffff"
                                    font.bold: true
                                    font.pixelSize: 14
                                    elide: Text.ElideRight
                                    width: parent.width
                                }
                                Text {
                                    text: modelData.showTitle + " • " + modelData.sizeMB
                                    color: "#00ff66"
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                    width: parent.width
                                }
                            }

                            // 1-Tap Offline Play + Long Press to Delete
                            Rectangle {
                                anchors.right: parent.right
                                anchors.rightMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                width: 72
                                height: 46
                                radius: 10
                                color: "#00ff66"

                                Text {
                                    anchors.centerIn: parent
                                    text: "▶ PLAY"
                                    color: "#000000"
                                    font.bold: true
                                    font.pixelSize: 14
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        engine.buzz(35);
                                        engine.playDirectFile(modelData.filePath, modelData.epTitle);
                                        swipeView.currentIndex = 1; // Jump to Player!
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

                    Item { width: 1; height: 6; visible: engine.downloadedEpisodes.length > 0 }

                    // --- SECTION B: SHOW CHANNELS ---
                    Text {
                        text: "SHOW CHANNELS"
                        color: "#00d2ff"
                        font.bold: true
                        font.pixelSize: 13
                        visible: engine.subscriptions.length > 0
                    }

                    Repeater {
                        model: engine.subscriptions
                        delegate: Rectangle {
                            width: subsCol.width
                            height: 64
                            color: "#181824"
                            radius: 12
                            border.color: "#333344"
                            border.width: 1

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
                                anchors.leftMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.title
                                color: "#ffffff"
                                font.bold: true
                                font.pixelSize: 15
                                width: 150
                                elide: Text.ElideRight
                            }

                            Rectangle {
                                anchors.right: parent.right
                                anchors.rightMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                width: 44
                                height: 44
                                radius: 8
                                color: "#551111"

                                Text {
                                    anchors.centerIn: parent
                                    text: "✕"
                                    color: "#ff4444"
                                    font.bold: true
                                    font.pixelSize: 20
                                }

                                MouseArea {
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
        // SCREEN 1: NOW PLAYING (FULL WATCHFACE COCKPIT)
        // ==========================================
        Item {
            // 1. TOP HEADER & TITLE
            Column {
                anchors.top: parent.top
                anchors.topMargin: 20
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - 40
                spacing: 4

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "NOW PLAYING"
                    color: "#00d2ff"
                    font.bold: true
                    font.pixelSize: 13
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: engine.currentTrackTitle.length > 0 ? engine.currentTrackTitle : "Ready to Play"
                    color: "#ffffff"
                    font.bold: true
                    font.pixelSize: 19
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }
            }

            // 2. EQUATOR TIMELINE & SYSTEM VOLUME
            Column {
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: 0
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - 30
                spacing: 3

                Slider {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width
                    from: 0
                    to: Math.max(1, engine.duration)
                    value: engine.position
                    onMoved: engine.seek(value)
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 16

                    Text {
                        function fmt(ms) {
                            var s = Math.floor(ms / 1000);
                            var m = Math.floor(s / 60);
                            return m + ":" + (s % 60 < 10 ? "0" : "") + (s % 60);
                        }
                        text: fmt(engine.position) + " / " + fmt(engine.duration)
                        color: "#00ff66"
                        font.family: "Monospace"
                        font.bold: true
                        font.pixelSize: 16
                    }

                    Text {
                        text: "🔊 " + engine.currentVolume + "%"
                        color: "#00d2ff"
                        font.bold: true
                        font.pixelSize: 15
                    }
                }
            }

            // 3. FULL BOTTOM COCKPIT (VOL - / PLAY / VOL +)
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 10
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - 20
                height: 96
                radius: 22
                color: "#12121c"
                border.color: "#28283c"
                border.width: 2

                Row {
                    anchors.centerIn: parent
                    spacing: 8

                    // Hardware Volume Down
                    Rectangle {
                        width: 74; height: 72; radius: 14
                        color: btnVolDown.pressed ? "#444455" : "#222234"
                        border.color: "#343448"
                        border.width: 1

                        Text { anchors.centerIn: parent; text: "🔉 VOL-"; color: "#ffffff"; font.bold: true; font.pixelSize: 15 }
                        MouseArea {
                            id: btnVolDown
                            anchors.fill: parent
                            onClicked: engine.volumeDown()
                        }
                    }

                    // Giant Play/Pause Slab
                    Rectangle {
                        width: 132; height: 72; radius: 16
                        color: btnPlay.pressed ? "#1ea852" : "#00ff66"

                        Text {
                            anchors.centerIn: parent
                            text: engine.playing ? "⏸ PAUSE" : "▶ PLAY"
                            color: "#000000"
                            font.bold: true
                            font.pixelSize: 20
                        }
                        MouseArea {
                            id: btnPlay
                            anchors.fill: parent
                            onClicked: {
                                engine.buzz(45);
                                engine.togglePlayPause();
                            }
                        }
                    }

                    // Hardware Volume Up
                    Rectangle {
                        width: 74; height: 72; radius: 14
                        color: btnVolUp.pressed ? "#444455" : "#222234"
                        border.color: "#343448"
                        border.width: 1

                        Text { anchors.centerIn: parent; text: "🔊 VOL+"; color: "#ffffff"; font.bold: true; font.pixelSize: 15 }
                        MouseArea {
                            id: btnVolUp
                            anchors.fill: parent
                            onClicked: engine.volumeUp()
                        }
                    }
                }
            }
        }

        // ==========================================
        // SCREEN 2: SEARCH TO ADD
        // ==========================================
        Item {
            Flickable {
                anchors.fill: parent
                anchors.margins: 30
                contentWidth: width
                contentHeight: searchCol.height
                clip: true

                Column {
                    id: searchCol
                    width: parent.width
                    spacing: 12

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Add Podcasts"
                        color: "#ffffff"
                        font.bold: true
                        font.pixelSize: 22
                    }

                    Rectangle {
                        width: parent.width
                        height: 64
                        radius: 14
                        color: searchBtnMouse.pressed ? "#0099cc" : "#00d2ff"

                        Text {
                            anchors.centerIn: parent
                            text: "🔍 TAP TO SEARCH"
                            color: "#000000"
                            font.bold: true
                            font.pixelSize: 18
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
                        color: "#00ff66"
                        font.bold: true
                        font.pixelSize: 14
                    }

                    Repeater {
                        model: engine.searchResults
                        delegate: Rectangle {
                            width: searchCol.width
                            height: 68
                            color: "#181822"
                            radius: 12

                            Column {
                                anchors.left: parent.left
                                anchors.leftMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                width: 140

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

                            Rectangle {
                                anchors.right: parent.right
                                anchors.rightMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                width: 78
                                height: 46
                                radius: 10
                                color: "#00ff66"

                                Text {
                                    anchors.centerIn: parent
                                    text: "+ SUB"
                                    color: "#000000"
                                    font.bold: true
                                    font.pixelSize: 15
                                }

                                MouseArea {
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

    // EPISODE LIST OVERLAY
    Rectangle {
        id: episodeOverlay
        anchors.fill: parent
        color: "#000000"
        visible: false

        function open() { visible = true; }
        function close() { visible = false; }

        Flickable {
            anchors.fill: parent
            anchors.margins: 30
            contentWidth: width
            contentHeight: epCol.height
            clip: true

            Column {
                id: epCol
                width: parent.width
                spacing: 12

                Row {
                    spacing: 8
                    Rectangle {
                        width: 80; height: 40; radius: 8; color: "#222232"
                        Text { anchors.centerIn: parent; text: "← Close"; color: "#00d2ff"; font.bold: true; font.pixelSize: 14 }
                        MouseArea { anchors.fill: parent; onClicked: episodeOverlay.close() }
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.currentShowTitle
                        color: "#ffffff"
                        font.bold: true
                        font.pixelSize: 15
                        width: 140
                        elide: Text.ElideRight
                    }
                }

                // Download Progress Banner
                Rectangle {
                    width: parent.width
                    height: 26
                    color: "#222228"
                    radius: 6
                    visible: engine.downloading

                    Rectangle {
                        height: parent.height
                        width: parent.width * (engine.downloadProgress / 100.0)
                        color: "#00ff66"
                        radius: 6
                    }
                    Text {
                        anchors.centerIn: parent
                        text: "Downloading " + engine.downloadProgress + "%"
                        color: "#000000"
                        font.pixelSize: 13
                        font.bold: true
                    }
                }

                Repeater {
                    model: engine.episodes
                    delegate: Rectangle {
                        width: epCol.width
                        height: 68
                        color: "#181824"
                        radius: 12
                        border.color: modelData.isDownloaded ? "#00ff66" : "#2a2a38"

                        Column {
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            width: 135

                            Text {
                                text: modelData.title
                                color: "#ffffff"
                                font.bold: true
                                font.pixelSize: 13
                                elide: Text.ElideRight
                                width: parent.width
                            }
                            Text {
                                text: modelData.isDownloaded ? "On Watch" : "Cloud"
                                color: modelData.isDownloaded ? "#00ff66" : "#00d2ff"
                                font.pixelSize: 11
                            }
                        }

                        // Play/Download Button + Long Press to Delete
                        Rectangle {
                            anchors.right: parent.right
                            anchors.rightMargin: 6
                            anchors.verticalCenter: parent.verticalCenter
                            width: 76
                            height: 44
                            radius: 10
                            color: modelData.isDownloaded ? "#00ff66" : "#2a2a38"

                            Text {
                                anchors.centerIn: parent
                                text: modelData.isDownloaded ? "▶ PLAY" : "⬇ GET"
                                color: modelData.isDownloaded ? "#000000" : "#ffffff"
                                font.bold: true
                                font.pixelSize: 14
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    engine.buzz(30);
                                    if (modelData.isDownloaded) {
                                        engine.playEpisode(root.currentShowTitle, modelData.title);
                                        episodeOverlay.close();
                                        swipeView.currentIndex = 1; // Jump to Player!
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

    // LONG-PRESS DELETE CONFIRMATION MODAL
    Rectangle {
        id: deleteConfirmOverlay
        anchors.fill: parent
        color: "#d9000000"
        visible: false
        z: 99

        Rectangle {
            width: 280
            height: 190
            radius: 16
            color: "#181822"
            border.color: "#ff4444"
            border.width: 2
            anchors.centerIn: parent

            Column {
                anchors.centerIn: parent
                spacing: 10
                width: parent.width - 24

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "DELETE EPISODE?"
                    color: "#ff4444"
                    font.bold: true
                    font.pixelSize: 15
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

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 12

                    Rectangle {
                        width: 90; height: 40; radius: 8; color: "#333344"
                        Text { anchors.centerIn: parent; text: "Cancel"; color: "#fff"; font.bold: true; font.pixelSize: 14 }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                engine.buzz(20);
                                deleteConfirmOverlay.visible = false;
                            }
                        }
                    }

                    Rectangle {
                        width: 90; height: 40; radius: 8; color: "#ff4444"
                        Text { anchors.centerIn: parent; text: "Delete"; color: "#000"; font.bold: true; font.pixelSize: 14 }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                engine.buzz(45);
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
