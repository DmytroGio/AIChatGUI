#include "syntaxhighlighter.h"
#include <QQuickTextDocument>

SyntaxHighlighter::SyntaxHighlighter(QObject *parent)
    : QSyntaxHighlighter(parent)
{
    // Настройка форматов
    m_keywordFormat.setForeground(QColor("#d62828"));
    m_keywordFormat.setFontWeight(QFont::Bold);

    m_stringFormat.setForeground(QColor("#f77f00"));

    m_commentFormat.setForeground(QColor("#6a994e"));
    m_commentFormat.setFontItalic(true);

    m_numberFormat.setForeground(QColor("#457b9d"));

    m_operatorFormat.setForeground(QColor("#e74c3c"));
}

void SyntaxHighlighter::setLanguage(const QString &language)
{
    if (m_language != language) {
        m_language = language.toLower();
        emit languageChanged();
        rehighlight();
    }
}

void SyntaxHighlighter::highlightBlock(const QString &text)
{
    if (m_language == "cpp" || m_language == "c++" || m_language == "c") {
        highlightCpp(text);
    } else if (m_language == "python" || m_language == "py") {
        highlightPython(text);
    } else if (m_language == "javascript" || m_language == "js") {
        highlightJavaScript(text);
    } else if (m_language == "qml") {
        highlightQml(text);
    }
}

void SyntaxHighlighter::highlightCpp(const QString &text)
{
    // Ключевые слова C++
    QStringList keywords = {"int", "void", "return", "main", "class", "struct",
                            "double", "float", "char", "bool", "const", "static",
                            "public", "private", "protected", "virtual", "namespace", "using"};

    for (const QString &keyword : keywords) {
        QRegularExpression expression("\\b" + keyword + "\\b");
        QRegularExpressionMatchIterator i = expression.globalMatch(text);
        while (i.hasNext()) {
            QRegularExpressionMatch match = i.next();
            setFormat(match.capturedStart(), match.capturedLength(), m_keywordFormat);
        }
    }

    // Строки
    QRegularExpression stringExpression("\".*\"");
    QRegularExpressionMatchIterator stringIterator = stringExpression.globalMatch(text);
    while (stringIterator.hasNext()) {
        QRegularExpressionMatch match = stringIterator.next();
        setFormat(match.capturedStart(), match.capturedLength(), m_stringFormat);
    }

    // Числа
    QRegularExpression numberExpression("\\b\\d+\\b");
    QRegularExpressionMatchIterator numberIterator = numberExpression.globalMatch(text);
    while (numberIterator.hasNext()) {
        QRegularExpressionMatch match = numberIterator.next();
        setFormat(match.capturedStart(), match.capturedLength(), m_numberFormat);
    }
}

void SyntaxHighlighter::highlightPython(const QString &text)
{
    QStringList keywords = {"def", "class", "if", "elif", "else", "for", "while",
                            "try", "except", "finally", "with", "as", "import",
                            "from", "return", "yield", "lambda", "and", "or", "not",
                            "in", "is", "None", "True", "False", "print"};

    for (const QString &keyword : keywords) {
        QRegularExpression expression("\\b" + keyword + "\\b");
        QRegularExpressionMatchIterator i = expression.globalMatch(text);
        while (i.hasNext()) {
            QRegularExpressionMatch match = i.next();
            setFormat(match.capturedStart(), match.capturedLength(), m_keywordFormat);
        }
    }

    // Комментарии
    QRegularExpression commentExpression("#[^\n]*");
    QRegularExpressionMatchIterator commentIterator = commentExpression.globalMatch(text);
    while (commentIterator.hasNext()) {
        QRegularExpressionMatch match = commentIterator.next();
        setFormat(match.capturedStart(), match.capturedLength(), m_commentFormat);
    }
}

void SyntaxHighlighter::highlightJavaScript(const QString &text)
{
    QStringList keywords = {"function", "var", "let", "const", "if", "else", "for",
                            "while", "return", "class", "extends", "import", "export",
                            "from", "async", "await", "try", "catch", "finally",
                            "true", "false", "null", "undefined", "new", "this"};

    for (const QString &keyword : keywords) {
        QRegularExpression expression("\\b" + keyword + "\\b");
        QRegularExpressionMatchIterator i = expression.globalMatch(text);
        while (i.hasNext()) {
            QRegularExpressionMatch match = i.next();
            setFormat(match.capturedStart(), match.capturedLength(), m_keywordFormat);
        }
    }
}

void SyntaxHighlighter::highlightQml(const QString &text)
{
    QStringList keywords = {"import", "property", "signal", "function", "Rectangle",
                            "Text", "MouseArea", "Column", "Row", "Item", "Component",
                            "Connections", "Timer", "ListView", "if", "else", "for", "while",
                            "anchors", "width", "height", "color", "visible", "opacity",
                            "true", "false", "parent", "children"};

    for (const QString &keyword : keywords) {
        QRegularExpression expression("\\b" + keyword + "\\b");
        QRegularExpressionMatchIterator i = expression.globalMatch(text);
        while (i.hasNext()) {
            QRegularExpressionMatch match = i.next();
            setFormat(match.capturedStart(), match.capturedLength(), m_keywordFormat);
        }
    }
}

void SyntaxHighlighter::setDocument(QQuickTextDocument *document)
{
    if (document && document->textDocument()) {
        QSyntaxHighlighter::setDocument(document->textDocument());
    }
}
