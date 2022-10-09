#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include "network/ircsocket.h"
#include "network/webchanneltransport.h"
#include "src/gameengine.h"
#include "src/blockcpp.h"
#include "src/blockqueue.h"
int main(int argc, char *argv[])
{


    QGuiApplication app(argc, argv);

    QQmlApplicationEngine engine;
    GameEngine gameEngine;
    qmlRegisterType<IRCSocket>("com.blockwars.network", 1, 0, "IRCSocket");
    qmlRegisterType<GameEngine>("com.blockwars.network", 1, 0, "GameEngine");
    qmlRegisterType<BlockCPP>("com.blockwars.network", 1, 0, "BlockCPP");
    qmlRegisterType<BlockQueue>("com.blockwars.network", 1, 0, "BlockQueue");
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
