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

    // 3-SCREEN SWIPEABLE CAROUSEL
    SwipeView {
        id: swipeView
        anchors.fill: parent
        currentIndex: 1 // Starts on Screen 1 (Player / Home)
        interactive: !radialOsk.visible // Locks swiping while typing!

        // ==========================================
        // SCREEN 0: SUBSCRIPTIONS & EPISODES
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
                    spacing: 12

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Subscriptions"
                        color: "#ffffff"
                        font.bold: true
                        font.pixelSize: 22
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Swipe right for Player ➔"
                        color: "#00d2ff"
                        font.bold: true
                        font.pixelSize: 12
                    }

                    Repeater {
                        model: engine.subscriptions
                        delegate: Rectangle {
                            width: subsCol.width
                            height: 64
                            color: "#181822"
                            radius: 12
                            border.color: "#00d2ff"
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
                                color: "#441111"

                                Text {
                                    anchors.centerIn: parent
                                    text: "✕"
                                    color: "#ff4444"
                                    font.bold: true
                                    font.pixelSize: 18
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
                    Item { width: 1; height: 35 }
                }
            }
        }

        // ==========================================
        // SCREEN 1: NOW PLAYING (HOME - FULL WATCHFACE)
        // ==========================================
        Item {
            Column {
                anchors.fill: parent
                anchors.margins: 25
                spacing: 8

                // Header
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "NOW PLAYING"
                    color: "#00d2ff"
                    font.bold: true
                    font.pixelSize: 14
                }

                // Giant Track Title
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: engine.currentTrackTitle.length > 0 ? engine.currentTrackTitle : "Ready to Play"
                    color: "#ffffff"
                    font.bold: true
                    font.pixelSize: 18
                    width: parent.width - 20
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }

                // Full-Width Progress Slider
                Slider {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width
                    from: 0
                    to: Math.max(1, engine.duration)
                    value: engine.position
                    onMoved: engine.seek(value)
                }

                // Bold Time Readout
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
                    font.pixelSize: 15
                }

                Item { width: 1; height: 4 }

                // FULL-WIDTH CURVED ACTION COCKPIT (Zero Gaps, Fills Bottom)
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width + 10
                    height: 80
                    radius: 16
                    color: "#14141c"
                    border.color: "#282836"
                    border.width: 1

                    Row {
                        anchors.centerIn: parent
                        spacing: 8

                        // -15s Button
                        Rectangle {
                            width: 68; height: 62; radius: 10
                            color: btnMinus.pressed ? "#444455" : "#222230"
                            Text { anchors.centerIn: parent; text: "-15s"; color: "#ffffff"; font.bold: true; font.pixelSize: 16 }
                            MouseArea {
                                id: btnMinus
                                anchors.fill: parent
                                onClicked: { engine.buzz(25); engine.skip(-15); }
                            }
                        }

                        // Massive Green Play/Pause
                        Rectangle {
                            width: 120; height: 62; radius: 12
                            color: btnPlay.pressed ? "#1ea852" : "#00ff66"
                            Text {
                                anchors.centerIn: parent
                                text: engine.playing ? "⏸ PAUSE" : "▶ PLAY"
                                color: "#000000"
                                font.bold: true
                                font.pixelSize: 18
                            }
                            MouseArea {
                                id: btnPlay
                                anchors.fill: parent
                                onClicked: { engine.buzz(45); engine.togglePlayPause(); }
                            }
                        }

                        // +30s Button
                        Rectangle {
                            width: 68; height: 62; radius: 10
                            color: btnPlus.pressed ? "#444455" : "#222230"
                            Text { anchors.centerIn: parent; text: "+30s"; color: "#ffffff"; font.bold: true; font.pixelSize: 16 }
                            MouseArea {
                                id: btnPlus
                                anchors.fill: parent
                                onClicked: { engine.buzz(25); engine.skip(30); }
                            }
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
                anchors.margins: 35
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

                    // MASSIVE SOLID CYAN SEARCH BAR (Black Text)
                    Rectangle {
                        width: parent.width
                        height: 60
                        radius: 12
                        color: searchBtnMouse.pressed ? "#0099cc" : "#00d2ff"

                        Text {
                            anchors.centerIn: parent
                            text: "🔍 TAP TO SEARCH"
                            color: "#000000"
                            font.bold: true
                            font.pixelSize: 17
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
                        font.pixelSize: 13
                    }

                    Repeater {
                        model: engine.searchResults
                        delegate: Rectangle {
                            width: searchCol.width
                            height: 64
                            color: "#181822"
                            radius: 10

                            Column {
                                anchors.left: parent.left
                                anchors.leftMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                width: 140

                                Text {
                                    text: modelData.title
                                    color: "#ffffff"
                                    font.bold: true
                                    font.pixelSize: 14
                                    elide: Text.ElideRight
                                    width: parent.width
                                }
                                Text {
                                    text: modelData.artist
                                    color: "#00d2ff"
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                    width: parent.width
                                }
                            }

                            Rectangle {
                                anchors.right: parent.right
                                anchors.rightMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                width: 72
                                height: 42
                                radius: 8
                                color: "#00ff66"

                                Text {
                                    anchors.centerIn: parent
                                    text: "+ SUB"
                                    color: "#000000"
                                    font.bold: true
                                    font.pixelSize: 14
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
                    Item { width: 1; height: 35 }
                }
            }
        }
    }

    // EPISODE LIST OVERLAY (Native Item overlay)
    Rectangle {
        id: episodeOverlay
        anchors.fill: parent
        color: "#000000"
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
                spacing: 10

                Row {
                    spacing: 8
                    Rectangle {
                        width: 75; height: 36; radius: 8; color: "#222230"
                        Text { anchors.centerIn: parent; text: "← Close"; color: "#00d2ff"; font.bold: true; font.pixelSize: 13 }
                        MouseArea { anchors.fill: parent; onClicked: episodeOverlay.close() }
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.currentShowTitle
                        color: "#ffffff"
                        font.bold: true
                        font.pixelSize: 14
                        width: 140
                        elide: Text.ElideRight
                    }
                }

                // Download Progress Banner
                Rectangle {
                    width: parent.width
                    height: 24
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
                        font.pixelSize: 12
                        font.bold: true
                    }
                }

                Repeater {
                    model: engine.episodes
                    delegate: Rectangle {
                        width: epCol.width
                        height: 64
                        color: "#181822"
                        radius: 10
                        border.color: modelData.isDownloaded ? "#00ff66" : "#2a2a36"

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
                            width: 72
                            height: 42
                            radius: 8
                            color: modelData.isDownloaded ? "#00ff66" : "#2a2a38"

                            Text {
                                anchors.centerIn: parent
                                text: modelData.isDownloaded ? "▶ PLAY" : "⬇ GET"
                                color: modelData.isDownloaded ? "#000000" : "#ffffff"
                                font.bold: true
                                font.pixelSize: 13
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
                Item { width: 1; height: 35 }
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
