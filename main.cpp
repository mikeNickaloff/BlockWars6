#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include "network/ircsocket.h"
#include "network/webchanneltransport.h"

int main(int argc, char *argv[])
{


    QGuiApplication app(argc, argv);

    QQmlApplicationEngine engine;

    qmlRegisterType<IRCSocket>("com.blockwars.network", 1, 0, "IRCSocket");
    qmlRegisterType<WebChannelTransport>("com.blockwars.network", 1, 0, "ChannelTransport");
    const QUrl url(QStringLiteral("qrc:/main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}
