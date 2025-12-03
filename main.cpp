#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QFile>
#include <QIcon>
#include "llamaconnector.h"
#include <QtCore/QString>
#include "chatmanager.h"
#include <QClipboard>
#include "clipboardhelper.h"
#include "syntaxhighlighter.h"

using namespace Qt::StringLiterals;

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    app.setWindowIcon(QIcon(":/icons/App_Icon_256.ico"));

    app.setApplicationName("AI Chat Assistant");
    app.setOrganizationName("DmytroVision");

    QQmlApplicationEngine engine;

    LlamaConnector connector;

    // Загружаем настройки
    connector.getModelInfo()->loadSettings();

    // Проверяем, есть ли модель для автозагрузки
    QString autoLoadPath = connector.getModelInfo()->autoLoadModelPath();
    if (!autoLoadPath.isEmpty() && QFile::exists(autoLoadPath)) {
        qDebug() << "Auto-loading model from:" << autoLoadPath;
        if (connector.loadModel(autoLoadPath)) {
            qDebug() << "Model auto-loaded successfully!";
        } else {
            qWarning() << "Failed to auto-load model";
        }
    } else {
        qDebug() << "No model configured for auto-load";
    }

    ChatManager chatManager;

    ClipboardHelper clipboardHelper;
    engine.rootContext()->setContextProperty("clipboardHelper", &clipboardHelper);

    engine.rootContext()->setContextProperty("llamaConnector", &connector);
    engine.rootContext()->setContextProperty("modelInfo", connector.getModelInfo());
    engine.rootContext()->setContextProperty("chatManager", &chatManager);
    engine.rootContext()->setContextProperty("clipboard", QGuiApplication::clipboard());

    qmlRegisterType<SyntaxHighlighter>("SyntaxHighlighter", 1, 0, "SyntaxHighlighter");

    const QUrl url(QStringLiteral("qrc:/AIChatGUI/Main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
                         if (!obj && url == objUrl)
                             QCoreApplication::exit(-1);
                     }, Qt::QueuedConnection);

    engine.load(url);
    return app.exec();
}
