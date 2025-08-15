#ifndef SYNTAXHIGHLIGHTER_H
#define SYNTAXHIGHLIGHTER_H

#include <QSyntaxHighlighter>
#include <QTextDocument>
#include <QTextCharFormat>
#include <QRegularExpression>
#include <QQmlEngine>
#include <QQuickTextDocument>

class SyntaxHighlighter : public QSyntaxHighlighter
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(QString language READ language WRITE setLanguage NOTIFY languageChanged)

public:
    explicit SyntaxHighlighter(QObject *parent = nullptr);

    QString language() const { return m_language; }
    void setLanguage(const QString &language);
    Q_INVOKABLE void setDocument(QQuickTextDocument *document);

signals:
    void languageChanged();

protected:
    void highlightBlock(const QString &text) override;

private:
    void highlightCpp(const QString &text);
    void highlightPython(const QString &text);
    void highlightJavaScript(const QString &text);
    void highlightQml(const QString &text);

    QString m_language;
    QTextCharFormat m_keywordFormat;
    QTextCharFormat m_stringFormat;
    QTextCharFormat m_commentFormat;
    QTextCharFormat m_numberFormat;
    QTextCharFormat m_operatorFormat;
    QTextCharFormat m_functionFormat;
    QTextCharFormat m_typeFormat;
    QTextCharFormat m_preprocessorFormat;
};

#endif // SYNTAXHIGHLIGHTER_H
