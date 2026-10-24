import QtQuick
import QtQuick.Controls

Item {
    id: root
    width: 400
    height: 400

    property string currentShowTitle: ""
    property string deleteShowTitle: ""
    property string deleteEpTitle: ""

    // Native AsteroidOS Low-Poly Faceted Background
    FacetedBackground { anchors.fill: parent }

    SwipeView {
        id: swipeView
        anchors.fill: parent
        currentIndex: 1 // Opens to Player (Image 2 style)
        interactive: !radialOsk.visible && !deleteConfirmOverlay.visible

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
                    spacing: 16

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Subscriptions"
                        color: "#ffffff"
                        font.bold: true
                        font.pixelSize: 24
                    }

                    // --- SECTION A: READY ON WATCH ---
                    Text {
                        text: "READY ON WATCH"
                        color: "#ffffff"
                        opacity: 0.6
                        font.bold: true
                        font.pixelSize: 13
                        visible: engine.downloadedEpisodes.length > 0
                    }

                    Repeater {
                        model: engine.downloadedEpisodes
                        delegate: Item {
                            width: subsCol.width
                            height: 68

                            Column {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 65

                                Text {
                                    text: modelData.epTitle
                                    color: "#ffffff"
                                    font.bold: true
                                    font.pixelSize: 17
                                    elide: Text.ElideRight
                                    width: parent.width
                                }
                                Text {
                                    text: modelData.showTitle + " • " + modelData.sizeMB
                                    color: "#ffffff"
                                    opacity: 0.6
                                    font.pixelSize: 13
                                    elide: Text.ElideRight
                                    width: parent.width
                                }
                            }

                            // Circular Play Button (Asteroid OS Image 2 Style)
                            Rectangle {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                width: 50
                                height: 50
                                radius: 25
                                color: playBtnMouse.pressed ? "rgba(255, 255, 255, 0.25)" : "transparent"
                                border.color: "#ffffff"
                                border.width: 2

                                Text {
                                    anchors.centerIn: parent
                                    anchors.horizontalCenterOffset: 2
                                    text: "▶"
                                    color: "#ffffff"
                                    font.pixelSize: 20
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

                    // --- SECTION B: CHANNELS ---
                    Text {
                        text: "CHANNELS"
                        color: "#ffffff"
                        opacity: 0.6
                        font.bold: true
                        font.pixelSize: 13
                        visible: engine.subscriptions.length > 0
                    }

                    Repeater {
                        model: engine.subscriptions
                        delegate: Item {
                            width: subsCol.width
                            height: 60

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
                                font.pixelSize: 17
                                width: parent.width - 55
                                elide: Text.ElideRight
                            }

                            // Circular Unsubscribe (✕)
                            Rectangle {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                width: 44
                                height: 44
                                radius: 22
                                color: unsubMouse.pressed ? "rgba(255, 255, 255, 0.25)" : "transparent"
                                border.color: "#ffffff"
                                border.width: 2

                                Text {
                                    anchors.centerIn: parent
                                    text: "✕"
                                    color: "#ffffff"
                                    font.pixelSize: 18
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
        // SCREEN 1: NOW PLAYING (EXACT IMAGE 2 & 3 PARITY)
        // ==========================================
        Item {
            // TOP: Track Title & Show (Matching Image 2)
            Column {
                anchors.top: parent.top
                anchors.topMargin: 30
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - 40
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
                    color: "#ffffff"
                    opacity: 0.65
                    font.pixelSize: 16
                    elide: Text.ElideRight
                }
            }

            // EQUATOR: OSCILLATING MONOCHROME FREQUENCY TIMELINE
            Item {
                id: timelineEquator
                anchors.centerIn: parent
                width: parent.width - 40
                height: 40

                // Oscillating Frequency Bars (Pure White, Opacity Animated)
                Row {
                    anchors.centerIn: parent
                    spacing: 4
                    visible: engine.playing

                    Repeater {
                        model: 18
                        Rectangle {
                            width: 3
                            height: 6 + Math.abs(Math.sin((waveTimer.step + index * 0.4)) * 16)
                            radius: 1.5
                            color: "#ffffff"
                            opacity: 0.75
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                Timer {
                    id: waveTimer
                    property real step: 0
                    interval: 60
                    running: engine.playing
                    repeat: true
                    onTriggered: step += 0.3
                }

                Slider {
                    anchors.centerIn: parent
                    width: parent.width
                    from: 0
                    to: Math.max(1, engine.duration)
                    value: engine.position
                    onMoved: engine.seek(value)
                    opacity: engine.playing ? 0.3 : 0.9
                }

                // Breathing Progress Indicator Dot
                Rectangle {
                    x: (parent.width - 12) * (engine.duration > 0 ? (engine.position / engine.duration) : 0)
                    anchors.verticalCenter: parent.verticalCenter
                    width: 12
                    height: 12
                    radius: 6
                    color: "#ffffff"
                    visible: engine.playing

                    SequentialAnimation on scale {
                        loops: Animation.Infinite
                        running: engine.playing
                        PropertyAnimation { to: 1.35; duration: 400 }
                        PropertyAnimation { to: 1.0; duration: 400 }
                    }
                }

                Text {
                    anchors.top: parent.bottom
                    anchors.topMargin: 2
                    anchors.horizontalCenter: parent.horizontalCenter
                    function fmt(ms) {
                        var s = Math.floor(ms / 1000);
                        var m = Math.floor(s / 60);
                        return m + ":" + (s % 60 < 10 ? "0" : "") + (s % 60);
                    }
                    text: fmt(engine.position) + " / " + fmt(engine.duration)
                    color: "#ffffff"
                    font.family: "Monospace"
                    font.bold: true
                    font.pixelSize: 14
                }
            }

            // BOTTOM CONTROLS: EXACT IMAGE 2 & 3 STYLE
            Row {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 25
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 28

                // (-) Volume Down Button (Image 3)
                Rectangle {
                    width: 64
                    height: 64
                    radius: 32
                    color: volDownMouse.pressed ? "rgba(255, 255, 255, 0.25)" : "transparent"
                    border.color: "#ffffff"
                    border.width: 2.5

                    Text {
                        anchors.centerIn: parent
                        text: "−"
                        color: "#ffffff"
                        font.pixelSize: 32
                    }

                    MouseArea {
                        id: volDownMouse
                        anchors.fill: parent
                        onClicked: engine.volumeDown()
                    }
                }

                // Giant Solid White Play/Pause Glyph (Image 2)
                Item {
                    width: 72
                    height: 72

                    Text {
                        anchors.centerIn: parent
                        anchors.horizontalCenterOffset: engine.playing ? 0 : 4
                        text: engine.playing ? "⏸" : "▶"
                        color: "#ffffff"
                        font.pixelSize: 58
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            engine.buzz(45);
                            engine.togglePlayPause();
                        }
                    }
                }

                // (+) Volume Up Button (Image 3)
                Rectangle {
                    width: 64
                    height: 64
                    radius: 32
                    color: volUpMouse.pressed ? "rgba(255, 255, 255, 0.25)" : "transparent"
                    border.color: "#ffffff"
                    border.width: 2.5

                    Text {
                        anchors.centerIn: parent
                        text: "+"
                        color: "#ffffff"
                        font.pixelSize: 32
                    }

                    MouseArea {
                        id: volUpMouse
                        anchors.fill: parent
                        onClicked: engine.volumeUp()
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
                anchors.margins: 35
                contentWidth: width
                contentHeight: searchCol.height
                clip: true

                Column {
                    id: searchCol
                    width: parent.width
                    spacing: 16

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Add Podcasts"
                        color: "#ffffff"
                        font.bold: true
                        font.pixelSize: 24
                    }

                    // Pure White Wireframe Search Bar
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: parent.width - 10
                        height: 56
                        radius: 28
                        color: searchBtnMouse.pressed ? "rgba(255, 255, 255, 0.25)" : "transparent"
                        border.color: "#ffffff"
                        border.width: 2

                        Row {
                            anchors.centerIn: parent
                            spacing: 8
                            Text { text: "🔍"; font.pixelSize: 18; color: "#ffffff" }
                            Text {
                                text: "SEARCH PODCASTS"
                                color: "#ffffff"
                                font.bold: true
                                font.pixelSize: 15
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
                        text: engine.searching ? "Searching..." : (engine.searchResults.length > 0 ? "RESULTS" : "")
                        color: "#ffffff"
                        opacity: 0.65
                        font.bold: true
                        font.pixelSize: 14
                    }

                    Repeater {
                        model: engine.searchResults
                        delegate: Item {
                            width: searchCol.width
                            height: 64

                            Column {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 60

                                Text {
                                    text: modelData.title
                                    color: "#ffffff"
                                    font.bold: true
                                    font.pixelSize: 16
                                    elide: Text.ElideRight
                                    width: parent.width
                                }
                                Text {
                                    text: modelData.artist
                                    color: "#ffffff"
                                    opacity: 0.6
                                    font.pixelSize: 13
                                    elide: Text.ElideRight
                                    width: parent.width
                                }
                            }

                            // Circular (+) Subscribe Wireframe
                            Rectangle {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                width: 48
                                height: 48
                                radius: 24
                                color: subMouse.pressed ? "rgba(255, 255, 255, 0.25)" : "transparent"
                                border.color: "#ffffff"
                                border.width: 2

                                Text {
                                    anchors.centerIn: parent
                                    text: "+"
                                    color: "#ffffff"
                                    font.bold: true
                                    font.pixelSize: 26
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
    // EPISODE LIST OVERLAY (CENTERED BACK BUTTON)
    // ==========================================
    Rectangle {
        id: episodeOverlay
        anchors.fill: parent
        visible: false

        function open() { visible = true; }
        function close() { visible = false; }

        FacetedBackground { anchors.fill: parent }

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

                // TOP CENTERED BACK BUTTON & TITLE
                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 6
                    width: parent.width

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 48
                        height: 48
                        radius: 24
                        color: "transparent"
                        border.color: "#ffffff"
                        border.width: 2

                        Text {
                            anchors.centerIn: parent
                            text: "✕"
                            color: "#ffffff"
                            font.bold: true
                            font.pixelSize: 20
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: episodeOverlay.close()
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.currentShowTitle
                        color: "#ffffff"
                        font.bold: true
                        font.pixelSize: 18
                        width: parent.width - 20
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                    }
                }

                // Download Progress
                Rectangle {
                    width: parent.width
                    height: 20
                    color: "rgba(255, 255, 255, 0.15)"
                    radius: 10
                    visible: engine.downloading

                    Rectangle {
                        height: parent.height
                        width: parent.width * (engine.downloadProgress / 100.0)
                        color: "#ffffff"
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
                        height: 68

                        Column {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 65

                            Text {
                                text: modelData.title
                                color: "#ffffff"
                                font.bold: true
                                font.pixelSize: 16
                                elide: Text.ElideRight
                                width: parent.width
                            }
                            Text {
                                text: modelData.isDownloaded ? "On Watch" : "Cloud"
                                color: "#ffffff"
                                opacity: modelData.isDownloaded ? 1.0 : 0.5
                                font.pixelSize: 13
                            }
                        }

                        // Circular Action Button (▶ or ⬇)
                        Rectangle {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            width: 50
                            height: 50
                            radius: 25
                            color: epActionMouse.pressed ? "rgba(255, 255, 255, 0.25)" : "transparent"
                            border.color: "#ffffff"
                            border.width: 2

                            Text {
                                anchors.centerIn: parent
                                anchors.horizontalCenterOffset: modelData.isDownloaded ? 2 : 0
                                text: modelData.isDownloaded ? "▶" : "⬇"
                                color: "#ffffff"
                                font.pixelSize: 20
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
    // DELETE CONFIRMATION DIALOG (IMAGE 1 STYLE: (✕) and (✓))
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
            color: "#081d28"
            border.color: "#ffffff"
            border.width: 2
            anchors.centerIn: parent

            Column {
                anchors.centerIn: parent
                spacing: 12
                width: parent.width - 30

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "DELETE EPISODE?"
                    color: "#ffffff"
                    font.bold: true
                    font.pixelSize: 15
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.deleteEpTitle
                    color: "#ffffff"
                    opacity: 0.8
                    font.pixelSize: 14
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    maximumLineCount: 2
                    wrapMode: Text.Wrap
                    elide: Text.ElideRight
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 26

                    Rectangle {
                        width: 52; height: 52; radius: 26
                        color: "transparent"
                        border.color: "#ffffff"
                        border.width: 2
                        Text { anchors.centerIn: parent; text: "✕"; color: "#fff"; font.pixelSize: 22 }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                engine.buzz(20);
                                deleteConfirmOverlay.visible = false;
                            }
                        }
                    }

                    Rectangle {
                        width: 52; height: 52; radius: 26
                        color: "transparent"
                        border.color: "#ffffff"
                        border.width: 2
                        Text { anchors.centerIn: parent; text: "✓"; color: "#fff"; font.pixelSize: 26; font.bold: true }
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

    // FULL-SCREEN ROTARY KEYBOARD WITH INERTIA & 12:00 APERTURE
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
