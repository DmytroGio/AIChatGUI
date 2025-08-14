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
        // Заменяем табы на 4 пробела
        line.replace("\t", "    ");

        // Заменяем ведущие пробелы на &nbsp;
        int leadingSpaces = 0;
        while (leadingSpaces < line.length() && line[leadingSpaces] == ' ') {
            leadingSpaces++;
        }
        if (leadingSpaces > 0) {
            QString spaces = line.left(leadingSpaces);
            spaces.replace(" ", "&nbsp;");
            line = spaces + line.mid(leadingSpaces);
        }
    }

    return lines.join("<br>");
}

QString SyntaxHighlighter::highlightCpp(const QString &code)
{
    QString result = code;

    // Сначала экранируем HTML
    result.replace("&", "&amp;");
    result.replace("<", "&lt;");
    result.replace(">", "&gt;");
    result.replace("\"", "&quot;");

    // Более точные замены ключевых слов
    result.replace(QRegularExpression("\\b(int|void|return|main|class|struct|double|float|char|bool|const|static|public|private|protected|virtual|namespace|using)\\b"),
                   "<span style=\"color: #d62828;\">\\1</span>");

    // Препроцессорные директивы
    result.replace(QRegularExpression("^(\\s*)(#\\w+)", QRegularExpression::MultilineOption),
                   "\\1<span style=\"color: #d62828;\">\\2</span>");

    // Строки в кавычках (улучшенная версия)
    result.replace(QRegularExpression("&quot;([^&]*)&quot;"),
                   "<span style=\"color: #f77f00;\">&quot;\\1&quot;</span>");

    // Namespace и операторы
    result.replace(QRegularExpression("\\b(std|cout|endl)\\b"),
                   "<span style=\"color: #6c5ce7;\">\\1</span>");

    // Числа
    result.replace(QRegularExpression("\\b(\\d+)\\b"),
                   "<span style=\"color: #457b9d;\">\\1</span>");

    // Операторы
    result.replace("::", "<span style=\"color: #e74c3c;\">::</span>");
    result.replace("&lt;&lt;", "<span style=\"color: #e74c3c;\">&lt;&lt;</span>");

    // Обрабатываем отступы и переносы
    QStringList lines = result.split('\n');
    for (int i = 0; i < lines.size(); ++i) {
        QString &line = lines[i];
        line.replace("\t", "&nbsp;&nbsp;&nbsp;&nbsp;");

        // Заменяем ведущие пробелы на &nbsp;
        int leadingSpaces = 0;
        while (leadingSpaces < line.length() && line[leadingSpaces] == ' ') {
            leadingSpaces++;
        }
        if (leadingSpaces > 0) {
            QString spaces = QString("&nbsp;").repeated(leadingSpaces);
            line = spaces + line.mid(leadingSpaces);
        }
    }

    return lines.join("<br>");
}

QString SyntaxHighlighter::highlightPython(const QString &code)
{
    QString result = code;

    // Комментарии #
    result.replace(QRegularExpression("#(.*)$", QRegularExpression::MultilineOption),
                   "COMMENT_START\\1COMMENT_END");

    // Строки в кавычках (одинарные и двойные)
    result.replace(QRegularExpression("\"([^\"\\\\]*(\\\\.[^\"\\\\]*)*)\""),
                   "STRING_START\\1STRING_END");
    result.replace(QRegularExpression("'([^'\\\\]*(\\\\.[^'\\\\]*)*)'"),
                   "STRING2_START\\1STRING2_END");

    // Ключевые слова Python
    QStringList keywords = {"def", "class", "if", "elif", "else", "for", "while",
                            "try", "except", "finally", "with", "as", "import",
                            "from", "return", "yield", "lambda", "and", "or", "not",
                            "in", "is", "None", "True", "False", "print"};

    for (const QString &keyword : keywords) {
        result.replace(QRegularExpression(QString("\\b%1\\b").arg(keyword)),
                       QString("KEYWORD_START%1KEYWORD_END").arg(keyword));
    }

    // Числа
    result.replace(QRegularExpression("\\b(\\d+\\.?\\d*)\\b"),
                   "NUMBER_START\\1NUMBER_END");

    // Экранируем HTML
    result.replace("&", "&amp;");
    result.replace("<", "&lt;");
    result.replace(">", "&gt;");
    result.replace("\"", "&quot;");

    // Заменяем маркеры
    result.replace("COMMENT_START", "<span style=\"color: #6a994e;\">#");
    result.replace("COMMENT_END", "</span>");
    result.replace("STRING_START", "<span style=\"color: #f77f00;\">&quot;");
    result.replace("STRING_END", "&quot;</span>");
    result.replace("STRING2_START", "<span style=\"color: #f77f00;\">'");
    result.replace("STRING2_END", "'</span>");
    result.replace("KEYWORD_START", "<span style=\"color: #d62828;\">");
    result.replace("KEYWORD_END", "</span>");
    result.replace("NUMBER_START", "<span style=\"color: #457b9d;\">");
    result.replace("NUMBER_END", "</span>");

    // Обрабатываем отступы
    QStringList lines = result.split('\n');
    for (int i = 0; i < lines.size(); ++i) {
        QString &line = lines[i];
        line.replace("\t", "    ");

        int leadingSpaces = 0;
        while (leadingSpaces < line.length() && line[leadingSpaces] == ' ') {
            leadingSpaces++;
        }
        if (leadingSpaces > 0) {
            QString spaces = line.left(leadingSpaces);
            spaces.replace(" ", "&nbsp;");
            line = spaces + line.mid(leadingSpaces);
        }
    }

    return lines.join("<br>");
}

QString SyntaxHighlighter::highlightJavaScript(const QString &code)
{
    QString highlighted = escapeHtml(code);

    // Комментарии
    highlighted.replace(QRegularExpression("(//[^<]*?)(?=<br>|$)"),
                        "<span style=\"color: #6a994e;\">\\1</span>");
    highlighted.replace(QRegularExpression("(/\\*[\\s\\S]*?\\*/)"),
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
        highlighted.replace(QRegularExpression(QString("\\b%1\\b(?![^<]*</span>)").arg(QRegularExpression::escape(keyword))),
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
