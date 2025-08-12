#include "syntaxhighlighter.h"
#include <QRegularExpression>

SyntaxHighlighter::SyntaxHighlighter(QObject *parent)
    : QObject(parent)
{
}

QString SyntaxHighlighter::highlightCode(const QString &code, const QString &language)
{
    QString lang = language.toLower();

    if (lang == "cpp" || lang == "c++" || lang == "c") {
        return highlightCpp(code);
    } else if (lang == "python" || lang == "py") {
        return highlightPython(code);
    } else if (lang == "javascript" || lang == "js") {
        return highlightJavaScript(code);
    } else if (lang == "qml") {
        return highlightQml(code);
    }

    return escapeHtml(code);
}

QString SyntaxHighlighter::escapeHtml(const QString &text)
{
    QString result = text;
    result.replace("&", "&amp;");
    result.replace("<", "&lt;");
    result.replace(">", "&gt;");
    result.replace("\"", "&quot;");

    // Обрабатываем строки построчно для сохранения отступов
    QStringList lines = result.split('\n');
    for (int i = 0; i < lines.size(); ++i) {
        QString &line = lines[i];
        // Заменяем ведущие пробелы и табы
        int leadingSpaces = 0;
        while (leadingSpaces < line.length() && (line[leadingSpaces] == ' ' || line[leadingSpaces] == '\t')) {
            if (line[leadingSpaces] == '\t') {
                line.replace(leadingSpaces, 1, "&nbsp;&nbsp;&nbsp;&nbsp;");
                leadingSpaces += 23; // длина "&nbsp;&nbsp;&nbsp;&nbsp;" - 1
            } else {
                line.replace(leadingSpaces, 1, "&nbsp;");
                leadingSpaces += 5; // длина "&nbsp;" - 1
            }
            leadingSpaces++;
        }
    }

    return lines.join("<br>");
}

QString SyntaxHighlighter::highlightCpp(const QString &code)
{
    QString highlighted = escapeHtml(code);

    // Комментарии (обновленные регексы с учетом <br>)
    highlighted.replace(QRegularExpression("(//[^<]*?)(<br>|$)"),
                        "<span style=\"color: #6a994e;\">\\1</span>\\2");
    highlighted.replace(QRegularExpression("(/\\*.*?\\*/)"),
                        "<span style=\"color: #6a994e;\">\\1</span>");

    // Строки
    highlighted.replace(QRegularExpression("(&quot;[^&<]*?&quot;)"),
                        "<span style=\"color: #f77f00;\">\\1</span>");

    // Ключевые слова
    QStringList keywords = {"int", "void", "return", "if", "else", "for", "while",
                            "class", "struct", "double", "float", "char", "bool",
                            "const", "static", "public", "private", "protected",
                            "virtual", "namespace", "using", "main", "#include", "#define"};

    for (const QString &keyword : keywords) {
        highlighted.replace(QRegularExpression(QString("\\b%1\\b(?![^<]*</span>)").arg(keyword)),
                            QString("<span style=\"color: #d62828;\">%1</span>").arg(keyword));
    }

    // Числа
    highlighted.replace(QRegularExpression("\\b(\\d+\\.?\\d*)\\b(?![^<]*</span>)"),
                        "<span style=\"color: #457b9d;\">\\1</span>");

    return highlighted;
}

QString SyntaxHighlighter::highlightPython(const QString &code)
{
    QString highlighted = escapeHtml(code);

    // Комментарии
    highlighted.replace(QRegularExpression("(#[^<]*?)(<br>|$)"),
                        "<span style=\"color: #6a994e;\">\\1</span>\\2");

    // Строки
    highlighted.replace(QRegularExpression("(&quot;[^&<]*?&quot;|'[^'<]*?')"),
                        "<span style=\"color: #f77f00;\">\\1</span>");

    // Ключевые слова Python
    QStringList keywords = {"def", "class", "if", "elif", "else", "for", "while",
                            "try", "except", "finally", "with", "as", "import",
                            "from", "return", "yield", "lambda", "and", "or", "not",
                            "in", "is", "None", "True", "False", "print"};

    for (const QString &keyword : keywords) {
        highlighted.replace(QRegularExpression(QString("\\b%1\\b(?![^<]*</span>)").arg(keyword)),
                            QString("<span style=\"color: #d62828;\">%1</span>").arg(keyword));
    }

    // Числа
    highlighted.replace(QRegularExpression("\\b(\\d+\\.?\\d*)\\b(?![^<]*</span>)"),
                        "<span style=\"color: #457b9d;\">\\1</span>");

    return highlighted;
}

QString SyntaxHighlighter::highlightJavaScript(const QString &code)
{
    QString highlighted = escapeHtml(code);

    // Комментарии
    highlighted.replace(QRegularExpression("(//[^<]*?)(<br>|$)"),
                        "<span style=\"color: #6a994e;\">\\1</span>\\2");
    highlighted.replace(QRegularExpression("(/\\*.*?\\*/)"),
                        "<span style=\"color: #6a994e;\">\\1</span>");

    // Строки
    highlighted.replace(QRegularExpression("(&quot;[^&<]*?&quot;|'[^'<]*?'|`[^`<]*?`)"),
                        "<span style=\"color: #f77f00;\">\\1</span>");

    // Ключевые слова JS
    QStringList keywords = {"function", "var", "let", "const", "if", "else", "for",
                            "while", "return", "class", "extends", "import", "export",
                            "from", "async", "await", "try", "catch", "finally",
                            "true", "false", "null", "undefined", "new", "this"};

    for (const QString &keyword : keywords) {
        highlighted.replace(QRegularExpression(QString("\\b%1\\b(?![^<]*</span>)").arg(keyword)),
                            QString("<span style=\"color: #d62828;\">%1</span>").arg(keyword));
    }

    // Числа
    highlighted.replace(QRegularExpression("\\b(\\d+\\.?\\d*)\\b(?![^<]*</span>)"),
                        "<span style=\"color: #457b9d;\">\\1</span>");

    return highlighted;
}

QString SyntaxHighlighter::highlightQml(const QString &code)
{
    QString highlighted = escapeHtml(code);

    // Комментарии
    highlighted.replace(QRegularExpression("(//[^<]*?)(<br>|$)"),
                        "<span style=\"color: #6a994e;\">\\1</span>\\2");
    highlighted.replace(QRegularExpression("(/\\*.*?\\*/)"),
                        "<span style=\"color: #6a994e;\">\\1</span>");

    // Строки
    highlighted.replace(QRegularExpression("(&quot;[^&<]*?&quot;)"),
                        "<span style=\"color: #f77f00;\">\\1</span>");

    // QML ключевые слова и компоненты
    QStringList keywords = {"import", "property", "signal", "function", "Rectangle",
                            "Text", "MouseArea", "Column", "Row", "Item", "Component",
                            "Connections", "Timer", "ListView", "if", "else", "for", "while",
                            "anchors", "width", "height", "color", "visible", "opacity",
                            "true", "false", "parent", "children"};

    for (const QString &keyword : keywords) {
        highlighted.replace(QRegularExpression(QString("\\b%1\\b(?![^<]*</span>)").arg(keyword)),
                            QString("<span style=\"color: #d62828;\">%1</span>").arg(keyword));
    }

    // Числа
    highlighted.replace(QRegularExpression("\\b(\\d+\\.?\\d*)\\b(?![^<]*</span>)"),
                        "<span style=\"color: #457b9d;\">\\1</span>");

    // QML свойства (например: anchors.centerIn, parent.width)
    highlighted.replace(QRegularExpression("\\b(anchors|parent|children)\\.([a-zA-Z_][a-zA-Z0-9_]*)"),
                        "<span style=\"color: #d62828;\">\\1</span>.<span style=\"color: #457b9d;\">\\2</span>");

    return highlighted;
}
