/*
 * =====================================================================
 * Part of the AsteroidOS Custom Software Suite
 * Architecture, Engine & UI Engineering by Gemini (Google)
 * Co-Developed & Tested on-device by DarkwingDuck13
 *
 * Platform: AsteroidOS (Linux / Qt6 / OpenEmbedded / TicWatch Pro)
 * =====================================================================
 */

#include <QGuiApplication>
#include <QQuickView>
#include <QQmlContext>
#include "podcastengine.h"

int main(int argc, char *argv[]) {
    QGuiApplication app(argc, argv);
    app.setApplicationName("asteroid-podcasts");

    // CRITICAL: Do NOT terminate the process when the display blanks or minimizes!
    QGuiApplication::setQuitOnLastWindowClosed(false);

    QQuickView view;
    view.setColor(QColor("#000000"));

    PodcastEngine engine;
    view.rootContext()->setContextProperty("engine", &engine);
    view.setSource(QUrl("qrc:/qml/main.qml"));
    view.setResizeMode(QQuickView::SizeRootObjectToView);
    view.showFullScreen();

    return app.exec();
}
