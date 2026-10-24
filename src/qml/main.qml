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
    id: root
    width: 400
    height: 400

    property string currentShowTitle: ""
    property string deleteShowTitle: ""
    property string deleteEpTitle: ""

    function formatTime(ms) {
        var totalSec = Math.floor(ms / 1000);
        var m = Math.floor(totalSec / 60);
        var s = totalSec % 60;
        return m + ":" + (s < 10 ? "0" : "") + s;
    }

    // Native AsteroidOS Faceted Low-Poly Background
    FacetedBackground {
        anchors.fill: parent
    }

    SwipeView {
        id: swipeView
        anchors.fill: parent
        currentIndex: 1 // Opens to Player
        interactive: !radialOsk.visible && !deleteConfirmOverlay.visible

        // ==========================================
        // SCREEN 0: SUBSCRIPTIONS & EPISODES
        // ==========================================
        Item {
            id: screenSubs

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
                                    text: modelData.showTitle + " - " + modelData.sizeMB
                                    color: "#ffffff"
                                    opacity: 0.6
                                    font.pixelSize: 13
                                    elide: Text.ElideRight
                                    width: parent.width
                                }
                            }

                            // Circular Play Button
                            Rectangle {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                width: 50
                                height: 50
                                radius: 25
                                color: playBtnMouse.pressed ? "#40ffffff" : "transparent"
                                border.color: "#ffffff"
                                border.width: 2

                                Text {
                                    anchors.centerIn: parent
                                    anchors.horizontalCenterOffset: 2
                                    text: "\u25B6"
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

                    Item {
                        width: 1
                        height: 4
                        visible: engine.downloadedEpisodes.length > 0
                    }

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

                            // Circular Unsubscribe (X)
                            Rectangle {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                width: 44
                                height: 44
                                radius: 22
                                color: unsubMouse.pressed ? "#40ffffff" : "transparent"
                                border.color: "#ffffff"
                                border.width: 2

                                Text {
                                    anchors.centerIn: parent
                                    text: "\u2715"
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

                    Item {
                        width: 1
                        height: 40
                    }
                }
            }
        }

        // ==========================================
        // SCREEN 1: NOW PLAYING (OSCILLOSCOPE SINE WAVE)
        // ==========================================
        Item {
            id: screenPlayer

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

            // EQUATOR: OSCILLATING SINE-WAVE TIMELINE
            Item {
                id: waveTimeline
                anchors.centerIn: parent
                width: parent.width - 50
                height: 50

                property real progress: (engine.duration > 0) ? (engine.position / engine.duration) : 0
                property real wavePhase: 0
                property real waveAmp: engine.playing ? 10 : 0

                Behavior on waveAmp {
                    NumberAnimation { duration: 350; easing.type: Easing.OutCubic }
                }

                Timer {
                    id: waveTimer
                    interval: 33
                    running: engine.playing || waveTimeline.waveAmp > 0.1
                    repeat: true
                    onTriggered: {
                        waveTimeline.wavePhase += 0.14;
                        waveCanvas.requestPaint();
                    }
                }

                Canvas {
                    id: waveCanvas
                    anchors.fill: parent

                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);

                        var midY = height / 2;
                        var amp = waveTimeline.waveAmp;
                        var phase = waveTimeline.wavePhase;
                        var progX = Math.max(0, Math.min(width, waveTimeline.progress * width));

                        // 1. Played Section
                        ctx.lineWidth = 2.5;
                        ctx.strokeStyle = "#ffffff";
                        ctx.beginPath();
                        for (var x = 0; x <= progX; x += 2) {
                            var y = midY + amp * Math.sin((x * 0.05) + phase);
                            if (x === 0) ctx.moveTo(x, y);
                            else ctx.lineTo(x, y);
                        }
                        ctx.stroke();

                        // 2. Unplayed Section
                        ctx.lineWidth = 1.5;
                        ctx.strokeStyle = "rgba(255, 255, 255, 0.35)";
                        ctx.beginPath();
                        for (var x2 = progX; x2 <= width; x2 += 2) {
                            var y2 = midY + amp * Math.sin((x2 * 0.05) + phase);
                            if (x2 === progX) ctx.moveTo(x2, y2);
                            else ctx.lineTo(x2, y2);
                        }
                        ctx.stroke();

                        // 3. Glowing Progress Dot
                        var dotY = midY + amp * Math.sin((progX * 0.05) + phase);

                        ctx.fillStyle = "rgba(255, 255, 255, 0.35)";
                        ctx.beginPath();
                        ctx.arc(progX, dotY, 7, 0, 2 * Math.PI);
                        ctx.fill();

                        ctx.fillStyle = "#ffffff";
                        ctx.beginPath();
                        ctx.arc(progX, dotY, 4, 0, 2 * Math.PI);
                        ctx.fill();
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: function(mouse) {
                        var ratio = Math.max(0, Math.min(1, mouse.x / width));
                        engine.seek(ratio * engine.duration);
                        engine.buzz(20);
                    }
                }

                Text {
                    anchors.top: parent.bottom
                    anchors.topMargin: 2
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.formatTime(engine.position) + " / " + root.formatTime(engine.duration)
                    color: "#ffffff"
                    font.family: "Monospace"
                    font.bold: true
                    font.pixelSize: 14
                }
            }

            // BOTTOM CONTROLS: CIRCULAR WIREFRAME
            Row {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 25
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 28

                // (-) Vol Down
                Rectangle {
                    width: 64
                    height: 64
                    radius: 32
                    color: volDownMouse.pressed ? "#40ffffff" : "transparent"
                    border.color: "#ffffff"
                    border.width: 2.5

                    Text {
                        anchors.centerIn: parent
                        text: "-"
                        color: "#ffffff"
                        font.pixelSize: 32
                    }

                    MouseArea {
                        id: volDownMouse
                        anchors.fill: parent
                        onClicked: engine.volumeDown()
                    }
                }

                // Giant Solid Play/Pause Glyph
                Item {
                    width: 72
                    height: 72

                    Text {
                        anchors.centerIn: parent
                        anchors.horizontalCenterOffset: engine.playing ? 0 : 4
                        text: engine.playing ? "\u23F8" : "\u25B6"
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

                // (+) Vol Up
                Rectangle {
                    width: 64
                    height: 64
                    radius: 32
                    color: volUpMouse.pressed ? "#40ffffff" : "transparent"
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
            id: screenSearch

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

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: parent.width - 10
                        height: 56
                        radius: 28
                        color: searchBtnMouse.pressed ? "#40ffffff" : "transparent"
                        border.color: "#ffffff"
                        border.width: 2

                        Text {
                            anchors.centerIn: parent
                            text: "SEARCH PODCASTS"
                            color: "#ffffff"
                            font.bold: true
                            font.pixelSize: 15
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

                            Rectangle {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                width: 48
                                height: 48
                                radius: 24
                                color: subMouse.pressed ? "#40ffffff" : "transparent"
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

                    Item {
                        width: 1
                        height: 40
                    }
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
        visible: false

        function open() { visible = true; }
        function close() { visible = false; }

        FacetedBackground {
            anchors.fill: parent
        }

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
                            text: "\u2715"
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

                Rectangle {
                    width: parent.width
                    height: 20
                    color: "#26ffffff"
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

                        Rectangle {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            width: 50
                            height: 50
                            radius: 25
                            color: epActionMouse.pressed ? "#40ffffff" : "transparent"
                            border.color: "#ffffff"
                            border.width: 2

                            Text {
                                anchors.centerIn: parent
                                anchors.horizontalCenterOffset: modelData.isDownloaded ? 2 : 0
                                text: modelData.isDownloaded ? "\u25B6" : "\u2B07"
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

                Item {
                    width: 1
                    height: 40
                }
            }
        }
    }

    // ==========================================
    // DELETE CONFIRMATION DIALOG
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
                        width: 52
                        height: 52
                        radius: 26
                        color: "transparent"
                        border.color: "#ffffff"
                        border.width: 2
                        Text {
                            anchors.centerIn: parent
                            text: "\u2715"
                            color: "#ffffff"
                            font.pixelSize: 22
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                engine.buzz(20);
                                deleteConfirmOverlay.visible = false;
                            }
                        }
                    }

                    Rectangle {
                        width: 52
                        height: 52
                        radius: 26
                        color: "transparent"
                        border.color: "#ffffff"
                        border.width: 2
                        Text {
                            anchors.centerIn: parent
                            text: "\u2713"
                            color: "#ffffff"
                            font.pixelSize: 26
                            font.bold: true
                        }
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
