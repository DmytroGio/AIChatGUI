#ifndef SYNTAXHIGHLIGHTER_H
#define SYNTAXHIGHLIGHTER_H

#include <QObject>
#include <QQmlEngine>

class SyntaxHighlighter : public QObject
{
    Q_OBJECT
    QML_ELEMENT

public:
    explicit SyntaxHighlighter(QObject *parent = nullptr);

    Q_INVOKABLE QString highlightCode(const QString &code, const QString &language);

private:
    QString highlightCpp(const QString &code);
    QString highlightPython(const QString &code);
    QString highlightJavaScript(const QString &code);
    QString highlightQml(const QString &code);
    QString escapeHtml(const QString &text);
};

#endif // SYNTAXHIGHLIGHTER_H
