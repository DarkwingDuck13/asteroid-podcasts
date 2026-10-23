import QtQuick
import QtQuick.Controls

Item {
    id: root
    width: 400
    height: 400

    property string currentShowTitle: ""
    property string activeView: "subs"

    Rectangle {
        anchors.fill: parent
        color: "#000000"
    }

    // ==========================================
    // VIEW 1: SUBSCRIPTIONS
    // ==========================================
    Item {
        anchors.fill: parent
        visible: root.activeView === "subs"

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
                    text: "Podcasts"
                    color: "#ffffff"
                    font.bold: true
                    font.pixelSize: 22
                }

                // Huge, easy-to-tap Search Button (54px tall)
                Button {
                    width: parent.width
                    height: 52
                    palette.buttonText: "#00d2ff"
                    text: "🔍 Search Podcasts"
                    onClicked: {
                        engine.buzz(25);
                        radialOsk.open("");
                    }
                }

                Button {
                    width: parent.width
                    height: 42
                    text: "▶ Resume Playing"
                    palette.buttonText: "#2ecc71"
                    visible: engine.currentTrackTitle.length > 0
                    onClicked: {
                        engine.buzz(20);
                        root.activeView = "player";
                    }
                }

                Text {
                    text: "SUBSCRIPTIONS"
                    color: "#8e44ad"
                    font.bold: true
                    font.pixelSize: 11
                    visible: engine.subscriptions.length > 0
                }

                Repeater {
                    model: engine.subscriptions
                    delegate: Rectangle {
                        width: subsCol.width
                        height: 56
                        color: "#181818"
                        radius: 8
                        border.color: "#333333"

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                engine.buzz(20);
                                root.currentShowTitle = modelData.title;
                                engine.loadEpisodes(modelData.title, modelData.feedUrl);
                                root.activeView = "episodes";
                            }
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.title
                            color: "#ffffff"
                            font.bold: true
                            font.pixelSize: 13
                            width: 170
                            elide: Text.ElideRight
                        }

                        Button {
                            anchors.right: parent.right
                            anchors.rightMargin: 6
                            anchors.verticalCenter: parent.verticalCenter
                            width: 34
                            height: 34
                            text: "✕"
                            palette.buttonText: "#ff4444"
                            onClicked: {
                                engine.buzz(30);
                                engine.unsubscribe(modelData.feedUrl);
                            }
                        }
                    }
                }
                Item { width: 1; height: 35 }
            }
        }
    }

    // ==========================================
    // VIEW 2: SEARCH RESULTS
    // ==========================================
    Item {
        anchors.fill: parent
        visible: root.activeView === "search"

        Flickable {
            anchors.fill: parent
            anchors.margins: 35
            contentWidth: width
            contentHeight: searchCol.height
            clip: true

            Column {
                id: searchCol
                width: parent.width
                spacing: 10

                Row {
                    spacing: 8
                    Button {
                        text: "← Back"
                        width: 75
                        height: 34
                        onClicked: {
                            engine.buzz(20);
                            root.activeView = "subs";
                        }
                    }
                    Button {
                        text: "New Search"
                        width: 110
                        height: 34
                        onClicked: {
                            engine.buzz(20);
                            radialOsk.open("");
                        }
                    }
                }

                Text {
                    text: engine.searching ? "Searching Apple Directory..." : "SEARCH RESULTS"
                    color: "#00d2ff"
                    font.bold: true
                    font.pixelSize: 11
                }

                Repeater {
                    model: engine.searchResults
                    delegate: Rectangle {
                        width: searchCol.width
                        height: 56
                        color: "#161616"
                        radius: 8

                        Column {
                            anchors.left: parent.left
                            anchors.leftMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            width: 150

                            Text {
                                text: modelData.title
                                color: "#ffffff"
                                font.bold: true
                                font.pixelSize: 12
                                elide: Text.ElideRight
                                width: parent.width
                            }
                            Text {
                                text: modelData.artist
                                color: "#888888"
                                font.pixelSize: 10
                                elide: Text.ElideRight
                                width: parent.width
                            }
                        }

                        Button {
                            anchors.right: parent.right
                            anchors.rightMargin: 6
                            anchors.verticalCenter: parent.verticalCenter
                            text: "+ Sub"
                            width: 64
                            height: 34
                            palette.buttonText: "#00ff66"
                            onClicked: {
                                engine.buzz(35);
                                engine.subscribe(modelData.title, modelData.feedUrl);
                                root.activeView = "subs";
                            }
                        }
                    }
                }
                Item { width: 1; height: 35 }
            }
        }
    }

    // ==========================================
    // VIEW 3: EPISODES
    // ==========================================
    Item {
        anchors.fill: parent
        visible: root.activeView === "episodes"

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
                    Button {
                        text: "← Back"
                        width: 75
                        height: 34
                        onClicked: {
                            engine.buzz(20);
                            root.activeView = "subs";
                        }
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.currentShowTitle
                        color: "#8e44ad"
                        font.bold: true
                        font.pixelSize: 14
                        width: 130
                        elide: Text.ElideRight
                    }
                }

                // Download progress bar
                Rectangle {
                    width: parent.width
                    height: 20
                    color: "#222222"
                    radius: 4
                    visible: engine.downloading

                    Rectangle {
                        height: parent.height
                        width: parent.width * (engine.downloadProgress / 100.0)
                        color: "#2ecc71"
                        radius: 4
                    }
                    Text {
                        anchors.centerIn: parent
                        text: "Downloading " + engine.downloadProgress + "%"
                        color: "#ffffff"
                        font.pixelSize: 10
                        font.bold: true
                    }
                }

                Text {
                    text: engine.loadingEpisodes ? "Fetching episodes..." : "EPISODES"
                    color: "#888888"
                    font.bold: true
                    font.pixelSize: 11
                }

                Repeater {
                    model: engine.episodes
                    delegate: Rectangle {
                        width: epCol.width
                        height: 58
                        color: "#181818"
                        radius: 8
                        border.color: modelData.isDownloaded ? "#2ecc71" : "#2a2a2a"

                        Column {
                            anchors.left: parent.left
                            anchors.leftMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            width: 140

                            Text {
                                text: modelData.title
                                color: "#ffffff"
                                font.bold: true
                                font.pixelSize: 12
                                elide: Text.ElideRight
                                width: parent.width
                            }
                            Text {
                                text: modelData.isDownloaded ? "Ready on Watch" : "Cloud"
                                color: modelData.isDownloaded ? "#2ecc71" : "#666666"
                                font.pixelSize: 10
                            }
                        }

                        Button {
                            anchors.right: parent.right
                            anchors.rightMargin: 6
                            anchors.verticalCenter: parent.verticalCenter
                            width: 62
                            height: 36
                            text: modelData.isDownloaded ? "▶ Play" : "⬇ Get"
                            palette.buttonText: modelData.isDownloaded ? "#00ff66" : "#ffffff"
                            onClicked: {
                                engine.buzz(25);
                                if (modelData.isDownloaded) {
                                    engine.playEpisode(root.currentShowTitle, modelData.title);
                                    root.activeView = "player";
                                } else {
                                    engine.downloadEpisode(root.currentShowTitle, modelData.title, modelData.audioUrl);
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
    // VIEW 4: PLAYER (NOW PLAYING)
    // ==========================================
    Item {
        anchors.fill: parent
        visible: root.activeView === "player"

        Column {
            anchors.fill: parent
            anchors.margins: 40
            spacing: 12

            Button {
                text: "← Back"
                width: 75
                height: 34
                onClicked: {
                    engine.buzz(20);
                    root.activeView = "subs";
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: engine.currentTrackTitle
                color: "#ffffff"
                font.bold: true
                font.pixelSize: 14
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                maximumLineCount: 3
                elide: Text.ElideRight
            }

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
                spacing: 6

                Text {
                    function fmt(ms) {
                        var s = Math.floor(ms / 1000);
                        var m = Math.floor(s / 60);
                        s = s % 60;
                        return m + ":" + (s < 10 ? "0" : "") + s;
                    }
                    text: fmt(engine.position) + " / " + fmt(engine.duration)
                    color: "#888888"
                    font.family: "Monospace"
                    font.pixelSize: 12
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 12

                Button {
                    text: "-15s"
                    width: 55
                    height: 44
                    onClicked: {
                        engine.buzz(15);
                        engine.skip(-15);
                    }
                }

                Button {
                    text: engine.playing ? "⏸ Pause" : "▶ Play"
                    width: 80
                    height: 44
                    onClicked: {
                        engine.buzz(25);
                        engine.togglePlayPause();
                    }
                }

                Button {
                    text: "+30s"
                    width: 55
                    height: 44
                    onClicked: {
                        engine.buzz(15);
                        engine.skip(30);
                    }
                }
            }
        }
    }

    // ==========================================
    // 5. THE RADIAL KEYBOARD OVERLAY
    // ==========================================
    RadialKeyboard {
        id: radialOsk
        anchors.fill: parent
        onAccepted: (queryText) => {
            if (queryText.trim().length > 0) {
                engine.search(queryText.trim());
                root.activeView = "search";
            }
        }
    }
}
