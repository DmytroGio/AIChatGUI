#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QFile>
#include <QIcon>
#include <QtCore/QString>
#include <QClipboard>
#include "llamaconnector.h"
#include "chatmanager.h"
#include "clipboardhelper.h"
#include "syntaxhighlighter.h"

using namespace Qt::StringLiterals;

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    // Enable dark mode
    app.setAttribute(Qt::AA_UseStyleSheetPropagationInWidgetStyles, true);
    qputenv("QT_QUICK_CONTROLS_STYLE", "Material");
    qputenv("QT_QUICK_CONTROLS_MATERIAL_THEME", "Dark");

    // Set application icon
    QIcon appIcon;
    appIcon.addFile(":/icons/App_Icon_128.ico");
    app.setWindowIcon(appIcon);

    app.setApplicationName("AI Chat Assistant");
    app.setOrganizationName("DmytroVision");

    QQmlApplicationEngine engine;

    LlamaConnector connector;

    // Load settings
    connector.getModelInfo()->loadSettings();

    // Auto-load model if configured
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

    // Register context properties
    engine.rootContext()->setContextProperty("llamaConnector", &connector);
    engine.rootContext()->setContextProperty("modelInfo", connector.getModelInfo());
    engine.rootContext()->setContextProperty("chatManager", &chatManager);
    engine.rootContext()->setContextProperty("clipboardHelper", &clipboardHelper);
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
