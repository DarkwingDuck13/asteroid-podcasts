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
                        font.pixelSize: 12
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
                        font.pixelSize: 12
                        visible: engine.subscriptions.length > 0
                    }

                    Repeater {
                        model: engine.subscriptions
                        delegate: Rectangle {
                            width: subsCol.width
                            height: 60
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
