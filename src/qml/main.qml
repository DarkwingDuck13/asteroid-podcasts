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

    // Clean, universal time-formatter helper
    function formatTime(ms) {
        var totalSec = Math.floor(ms / 1000);
        var m = Math.floor(totalSec / 60);
        var s = totalSec % 60;
        return m + ":" + (s < 10 ? "0" : "") + s;
    }

    // Native AsteroidOS Faceted Low-Poly Background
    FacetedBackground { anchors.fill: parent }

    SwipeView {
        id: swipeView
        anchors.fill: parent
        currentIndex: 1 // Starts on Screen 1 (Player / Home)
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

                            // Circular Play Button (Asteroid OS Style)
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
