import QtQuick
import QtQuick.Controls

Item {
    id: root
    width: 400
    height: 400

    property string currentShowTitle: ""

    Rectangle {
        anchors.fill: parent
        color: "#000000"
    }

    SwipeView {
        id: swipeView
        anchors.fill: parent
        currentIndex: 1 // Starts on Screen 1 (Player / Home)
        interactive: !radialOsk.visible // Locks swiping while typing!

        // ==========================================
        // SCREEN 0: SUBSCRIPTIONS & EPISODES (OFFLINE-FIRST)
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

                    // --- SECTION A: READY ON WATCH (ALWAYS VISIBLE OFFLINE!) ---
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

                            // 1-Tap Instant Offline Play
                            Rectangle {
                                anchors.right: parent.right
                                anchors.rightMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                width: 68
                                height: 44
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
                                        swipeView.currentIndex = 1; // Jump straight to Player!
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
                    font.pixelSize: 20
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }
            }

            // 2. EQUATOR TIMELINE & TIME
            Column {
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: 0
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - 30
                spacing: 2

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
                    color: "#00ff66"
                    font.family: "Monospace"
                    font.bold: true
                    font.pixelSize: 17
                }
            }

            // 3. MASSIVE BOTTOM COCKPIT (Fills the bottom 45% void!)
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

                    // -15s Button
                    Rectangle {
                        width: 74; height: 72; radius: 14
                        color: btnMinus.pressed ? "#444455" : "#222234"
                        border.color: "#343448"
                        border.width: 1

                        Text { anchors.centerIn: parent; text: "-15s"; color: "#ffffff"; font.bold: true; font.pixelSize: 18 }
                        MouseArea {
                            id: btnMinus
                            anchors.fill: parent
                            onClicked: { engine.buzz(25); engine.skip(-15); }
                        }
                    }

                    // Massive Play/Pause Slab
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
                            onClicked: { engine.buzz(45); engine.togglePlayPause(); }
                        }
                    }

                    // +30s Button
                    Rectangle {
                        width: 74; height: 72; radius: 14
                        color: btnPlus.pressed ? "#444455" : "#222234"
                        border.color: "#343448"
                        border.width: 1

                        Text { anchors.centerIn: parent; text: "+30s"; color: "#ffffff"; font.bold: true; font.pixelSize: 18 }
                        MouseArea {
                            id: btnPlus
                            anchors.fill: parent
                            onClicked: { engine.buzz(25); engine.skip(30); }
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

                    // MASSIVE SOLID CYAN SEARCH BAR
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
                            }
                        }
                    }
                }
                Item { width: 1; height: 40 }
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
                swipeView.currentIndex = 2; // Jump to Search results!
            }
        }
    }
}
