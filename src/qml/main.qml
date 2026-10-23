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
        currentIndex: 1 // Start on Screen 1 (Player / Home)
        
        // CRITICAL: Disable screen swiping whenever the keyboard is open!
        interactive: !radialOsk.visible

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
                        font.pixelSize: 20
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Swipe right for Player ➔"
                        color: "#666666"
                        font.pixelSize: 11
                    }

                    Repeater {
                        model: engine.subscriptions
                        delegate: Rectangle {
                            width: subsCol.width
                            height: 60
                            color: "#18181c"
                            radius: 10
                            border.color: "#333338"
                            border.width: 1

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    engine.buzz(25);
                                    root.currentShowTitle = modelData.title;
                                    engine.loadEpisodes(modelData.title, modelData.feedUrl);
                                    episodePopup.open();
                                }
                            }

                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.title
                                color: "#ffffff"
                                font.bold: true
                                font.pixelSize: 14
                                width: 160
                                elide: Text.ElideRight
                            }

                            Button {
                                anchors.right: parent.right
                                anchors.rightMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                width: 36
                                height: 36
                                text: "✕"
                                palette.buttonText: "#ff4444"
                                onClicked: {
                                    engine.buzz(35);
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
        // SCREEN 1: NOW PLAYING (HOME)
        // ==========================================
        Item {
            Column {
                anchors.fill: parent
                anchors.margins: 35
                spacing: 10

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Now Playing"
                    color: "#8e44ad"
                    font.bold: true
                    font.pixelSize: 18
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: engine.currentTrackTitle.length > 0 ? engine.currentTrackTitle : "No episode loaded"
                    color: "#ffffff"
                    font.bold: true
                    font.pixelSize: 14
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }

                Slider {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - 20
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
                    color: "#888888"
                    font.family: "Monospace"
                    font.pixelSize: 12
                }

                // Transport Controls
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 12

                    Rectangle {
                        width: 58; height: 48; radius: 8
                        color: "#222228"
                        Text { anchors.centerIn: parent; text: "-15s"; color: "#fff"; font.bold: true; font.pixelSize: 13 }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: { engine.buzz(20); engine.skip(-15); }
                        }
                    }

                    Rectangle {
                        width: 86; height: 48; radius: 8
                        color: "#00ff66"
                        Text {
                            anchors.centerIn: parent
                            text: engine.playing ? "⏸ PAUSE" : "▶ PLAY"
                            color: "#000000"
                            font.bold: true
                            font.pixelSize: 14
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: { engine.buzz(35); engine.togglePlayPause(); }
                        }
                    }

                    Rectangle {
                        width: 58; height: 48; radius: 8
                        color: "#222228"
                        Text { anchors.centerIn: parent; text: "+30s"; color: "#fff"; font.bold: true; font.pixelSize: 13 }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: { engine.buzz(20); engine.skip(30); }
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
                        font.pixelSize: 20
                    }

                    // MASSIVE HIGH-CONTRAST SEARCH BUTTON (Solid Cyan with Black Text)
                    Rectangle {
                        width: parent.width
                        height: 54
                        radius: 10
                        color: searchBtnMouse.pressed ? "#0099cc" : "#00d2ff"

                        Text {
                            anchors.centerIn: parent
                            text: "🔍 TAP TO SEARCH"
                            color: "#000000"
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
                        text: engine.searching ? "Searching Apple Directory..." : (engine.searchResults.length > 0 ? "RESULTS" : "")
                        color: "#00d2ff"
                        font.bold: true
                        font.pixelSize: 11
                    }

                    Repeater {
                        model: engine.searchResults
                        delegate: Rectangle {
                            width: searchCol.width
                            height: 60
                            color: "#18181c"
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
                                    font.pixelSize: 13
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

                            // Solid Green Subscribe Button
                            Rectangle {
                                anchors.right: parent.right
                                anchors.rightMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                width: 68
                                height: 38
                                radius: 8
                                color: "#00ff66"

                                Text {
                                    anchors.centerIn: parent
                                    text: "+ SUB"
                                    color: "#000000"
                                    font.bold: true
                                    font.pixelSize: 12
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        engine.buzz(45);
                                        engine.subscribe(modelData.title, modelData.feedUrl);
                                        swipeView.currentIndex = 0; // Jump to Subscriptions
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

    // EPISODE LIST MODAL (Opens when you tap a show in Subscriptions)
    Popup {
        id: episodePopup
        anchors.fill: parent
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle { color: "#000000" }

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
                        width: 70; height: 34; radius: 6; color: "#222"
                        Text { anchors.centerIn: parent; text: "← Close"; color: "#fff"; font.bold: true; font.pixelSize: 12 }
                        MouseArea { anchors.fill: parent; onClicked: episodePopup.close() }
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.currentShowTitle
                        color: "#8e44ad"
                        font.bold: true
                        font.pixelSize: 13
                        width: 140
                        elide: Text.ElideRight
                    }
                }

                // Download Progress Banner
                Rectangle {
                    width: parent.width
                    height: 22
                    color: "#222228"
                    radius: 4
                    visible: engine.downloading

                    Rectangle {
                        height: parent.height
                        width: parent.width * (engine.downloadProgress / 100.0)
                        color: "#00ff66"
                        radius: 4
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
                    delegate: Rectangle {
                        width: epCol.width
                        height: 60
                        color: "#16161a"
                        radius: 8

                        Column {
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            width: 135

                            Text {
                                text: modelData.title
                                color: "#ffffff"
                                font.bold: true
                                font.pixelSize: 12
                                elide: Text.ElideRight
                                width: parent.width
                            }
                            Text {
                                text: modelData.isDownloaded ? "On Watch" : "Cloud"
                                color: modelData.isDownloaded ? "#00ff66" : "#888888"
                                font.pixelSize: 10
                            }
                        }

                        // Play or Download Target
                        Rectangle {
                            anchors.right: parent.right
                            anchors.rightMargin: 6
                            anchors.verticalCenter: parent.verticalCenter
                            width: 66
                            height: 38
                            radius: 8
                            color: modelData.isDownloaded ? "#00ff66" : "#2a2a32"

                            Text {
                                anchors.centerIn: parent
                                text: modelData.isDownloaded ? "▶ PLAY" : "⬇ GET"
                                color: modelData.isDownloaded ? "#000000" : "#ffffff"
                                font.bold: true
                                font.pixelSize: 12
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    engine.buzz(30);
                                    if (modelData.isDownloaded) {
                                        engine.playEpisode(root.currentShowTitle, modelData.title);
                                        episodePopup.close();
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

    // ==========================================
    // THE FULL-SCREEN RADIAL KEYBOARD OVERLAY
    // ==========================================
    RadialKeyboard {
        id: radialOsk
        anchors.fill: parent
        onAccepted: (queryText) => {
            if (queryText.trim().length > 0) {
                engine.search(queryText.trim());
            }
        }
    }
}
