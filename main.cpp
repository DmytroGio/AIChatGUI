#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "lmstudioconnector.h"
#include <QtCore/QString>
#include "chatmanager.h"
#include <QClipboard>

using namespace Qt::StringLiterals;

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setProperty("clipboard", QVariant::fromValue(QGuiApplication::clipboard()));
    QQmlApplicationEngine engine;

    LMStudioConnector connector;
    ChatManager chatManager;

    engine.rootContext()->setContextProperty("lmstudio", &connector);
    engine.rootContext()->setContextProperty("chatManager", &chatManager);

    // Используем путь к модулю вместо qrc
    const QUrl url(QStringLiteral("qrc:/AIChatGUI/Main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
                         if (!obj && url == objUrl)
                             QCoreApplication::exit(-1);
                     }, Qt::QueuedConnection);

    engine.load(url);
    return app.exec();
}
