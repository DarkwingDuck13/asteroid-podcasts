#include <QGuiApplication>
#include <QQuickView>
#include <QQmlContext>
#include "podcastengine.h"

int main(int argc, char *argv[]) {
    QGuiApplication app(argc, argv);
    app.setApplicationName("asteroid-podcasts");

    QQuickView view;
    PodcastEngine engine;

    view.rootContext()->setContextProperty("engine", &engine);
    view.setSource(QUrl("qrc:/qml/main.qml"));
    view.setResizeMode(QQuickView::SizeRootObjectToView);
    view.showFullScreen();

    return app.exec();
}
