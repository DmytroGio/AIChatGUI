#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "lmstudioconnector.h"
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

    LMStudioConnector connector;
    ChatManager chatManager;

    ClipboardHelper clipboardHelper;
    engine.rootContext()->setContextProperty("clipboardHelper", &clipboardHelper);

    engine.rootContext()->setContextProperty("lmstudio", &connector);
    engine.rootContext()->setContextProperty("chatManager", &chatManager);
    engine.rootContext()->setContextProperty("clipboard", QGuiApplication::clipboard());
    qmlRegisterType<QObject>("CodeHighlighter", 1, 0, "CodeHighlighter");

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
