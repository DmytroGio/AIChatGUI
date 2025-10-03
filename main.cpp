#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
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
    QQmlApplicationEngine engine;

    LlamaConnector connector;

    QString modelPath = QCoreApplication::applicationDirPath() + "/models/qwen2.5-coder-3b-instruct-q4_k_m.gguf";
    qDebug() << "Loading model from:" << modelPath;

    if (!connector.loadModel(modelPath)) {
        qWarning() << "Failed to load model from:" << modelPath;
        qWarning() << "Make sure the model file exists at this location";
        return -1;
    }

    qDebug() << "Model loaded successfully!";

    ChatManager chatManager;

    ClipboardHelper clipboardHelper;
    engine.rootContext()->setContextProperty("clipboardHelper", &clipboardHelper);

    engine.rootContext()->setContextProperty("llamaConnector", &connector);
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
