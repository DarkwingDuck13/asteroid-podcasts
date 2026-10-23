#include <QGuiApplication>
#include <QQuickView>
#include <QQmlContext>
#include "podcastengine.h"

int main(int argc, char *argv[]) {
    QGuiApplication app(argc, argv);
    app.setApplicationName("asteroid-podcasts");

    QQuickView view;
    // Set default canvas to pure OLED black (no more flashlights!)
    view.setColor(QColor("#000000"));

    PodcastEngine engine;
    view.rootContext()->setContextProperty("engine", &engine);
    view.setSource(QUrl("qrc:/qml/main.qml"));
    view.setResizeMode(QQuickView::SizeRootObjectToView);
    view.showFullScreen();

    return app.exec();
}
