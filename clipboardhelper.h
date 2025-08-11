#ifndef CLIPBOARDHELPER_H
#define CLIPBOARDHELPER_H

#include <QObject>
#include <QClipboard>
#include <QGuiApplication>

class ClipboardHelper : public QObject
{
    Q_OBJECT

public:
    explicit ClipboardHelper(QObject *parent = nullptr);

    Q_INVOKABLE void copyText(const QString &text);
    Q_INVOKABLE QString getText();

private:
    QClipboard *m_clipboard;
};

#endif // CLIPBOARDHELPER_H
