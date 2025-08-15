#include "syntaxhighlighter.h"
#include <QQuickTextDocument>

SyntaxHighlighter::SyntaxHighlighter(QObject *parent)
    : QSyntaxHighlighter(parent)
{
    // VS Code Dark+ theme colors
    // Keywords (if, for, class, etc.) - синий
    m_keywordFormat.setForeground(QColor("#569cd6"));
    m_keywordFormat.setFontWeight(QFont::Bold);

    // Strings - зеленый
    m_stringFormat.setForeground(QColor("#ce9178"));

    // Comments - серо-зеленый
    m_commentFormat.setForeground(QColor("#6a9955"));
    m_commentFormat.setFontItalic(true);

    // Numbers - светло-зеленый
    m_numberFormat.setForeground(QColor("#b5cea8"));

    // Operators - белый
    m_operatorFormat.setForeground(QColor("#d4d4d4"));

    // Добавим дополнительные форматы
    m_functionFormat.setForeground(QColor("#dcdcaa")); // функции - желтый
    m_functionFormat.setFontWeight(QFont::Bold);

    m_typeFormat.setForeground(QColor("#4ec9b0")); // типы данных - бирюзовый

    m_preprocessorFormat.setForeground(QColor("#c586c0")); // препроцессор - розовый
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
    QStringList keywords = {"int", "void", "return", "class", "struct",
                            "double", "float", "char", "bool", "const", "static",
                            "public", "private", "protected", "virtual", "namespace",
                            "using", "if", "else", "for", "while", "do", "switch",
                            "case", "break", "continue", "try", "catch", "throw",
                            "new", "delete", "this", "nullptr", "auto", "template"};

    for (const QString &keyword : keywords) {
        QRegularExpression expression("\\b" + keyword + "\\b");
        QRegularExpressionMatchIterator i = expression.globalMatch(text);
        while (i.hasNext()) {
            QRegularExpressionMatch match = i.next();
            setFormat(match.capturedStart(), match.capturedLength(), m_keywordFormat);
        }
    }

    // Типы данных
    QStringList types = {"std::", "QString", "QObject", "QWidget", "size_t", "uint32_t", "int32_t"};
    for (const QString &type : types) {
        QRegularExpression expression("\\b" + QRegularExpression::escape(type) + "\\w*");
        QRegularExpressionMatchIterator i = expression.globalMatch(text);
        while (i.hasNext()) {
            QRegularExpressionMatch match = i.next();
            setFormat(match.capturedStart(), match.capturedLength(), m_typeFormat);
        }
    }

    // Функции - слова перед открывающей скобкой
    QRegularExpression functionExpression("\\b([a-zA-Z_]\\w*)\\s*(?=\\()");
    QRegularExpressionMatchIterator funcIterator = functionExpression.globalMatch(text);
    while (funcIterator.hasNext()) {
        QRegularExpressionMatch match = funcIterator.next();
        setFormat(match.capturedStart(), match.capturedLength(), m_functionFormat);
    }

    // Препроцессор
    QRegularExpression preprocExpression("^\\s*#\\w+");
    QRegularExpressionMatchIterator preprocIterator = preprocExpression.globalMatch(text);
    while (preprocIterator.hasNext()) {
        QRegularExpressionMatch match = preprocIterator.next();
        setFormat(match.capturedStart(), match.capturedLength(), m_preprocessorFormat);
    }

    // Строки в двойных кавычках
    QRegularExpression stringExpression("\"([^\"\\\\]|\\\\.)*\"");
    QRegularExpressionMatchIterator stringIterator = stringExpression.globalMatch(text);
    while (stringIterator.hasNext()) {
        QRegularExpressionMatch match = stringIterator.next();
        setFormat(match.capturedStart(), match.capturedLength(), m_stringFormat);
    }

    // Символы в одинарных кавычках
    QRegularExpression charExpression("'([^'\\\\]|\\\\.)+'");
    QRegularExpressionMatchIterator charIterator = charExpression.globalMatch(text);
    while (charIterator.hasNext()) {
        QRegularExpressionMatch match = charIterator.next();
        setFormat(match.capturedStart(), match.capturedLength(), m_stringFormat);
    }

    // Однострочные комментарии
    QRegularExpression singleCommentExpression("//[^\n]*");
    QRegularExpressionMatchIterator singleIterator = singleCommentExpression.globalMatch(text);
    while (singleIterator.hasNext()) {
        QRegularExpressionMatch match = singleIterator.next();
        setFormat(match.capturedStart(), match.capturedLength(), m_commentFormat);
    }

    // Числа
    QRegularExpression numberExpression("\\b\\d+(\\.\\d+)?([eE][+-]?\\d+)?[fFlL]?\\b");
    QRegularExpressionMatchIterator numberIterator = numberExpression.globalMatch(text);
    while (numberIterator.hasNext()) {
        QRegularExpressionMatch match = numberIterator.next();
        setFormat(match.capturedStart(), match.capturedLength(), m_numberFormat);
    }
}

void SyntaxHighlighter::highlightPython(const QString &text)
{
    // Ключевые слова Python
    QStringList keywords = {"def", "class", "if", "elif", "else", "for", "while",
                            "try", "except", "finally", "with", "as", "import",
                            "from", "return", "yield", "lambda", "and", "or", "not",
                            "in", "is", "pass", "break", "continue", "raise", "assert",
                            "del", "global", "nonlocal", "async", "await"};

    for (const QString &keyword : keywords) {
        QRegularExpression expression("\\b" + keyword + "\\b");
        QRegularExpressionMatchIterator i = expression.globalMatch(text);
        while (i.hasNext()) {
            QRegularExpressionMatch match = i.next();
            setFormat(match.capturedStart(), match.capturedLength(), m_keywordFormat);
        }
    }

    // Встроенные константы и типы
    QStringList builtins = {"None", "True", "False", "self", "cls", "__init__", "__name__",
                            "int", "str", "list", "dict", "tuple", "set", "bool", "float",
                            "len", "range", "print", "input", "open", "type", "isinstance"};

    for (const QString &builtin : builtins) {
        QRegularExpression expression("\\b" + QRegularExpression::escape(builtin) + "\\b");
        QRegularExpressionMatchIterator i = expression.globalMatch(text);
        while (i.hasNext()) {
            QRegularExpressionMatch match = i.next();
            setFormat(match.capturedStart(), match.capturedLength(), m_typeFormat);
        }
    }

    // Функции - слова после def или слова перед открывающей скобкой
    QRegularExpression defExpression("\\bdef\\s+([a-zA-Z_]\\w*)");
    QRegularExpressionMatchIterator defIterator = defExpression.globalMatch(text);
    while (defIterator.hasNext()) {
        QRegularExpressionMatch match = defIterator.next();
        setFormat(match.capturedStart(1), match.capturedLength(1), m_functionFormat);
    }

    // Вызовы функций - слова перед скобкой
    QRegularExpression functionExpression("\\b([a-zA-Z_]\\w*)\\s*(?=\\()");
    QRegularExpressionMatchIterator funcIterator = functionExpression.globalMatch(text);
    while (funcIterator.hasNext()) {
        QRegularExpressionMatch match = funcIterator.next();
        // Пропускаем если это уже ключевое слово
        QString word = match.captured(1);
        if (!keywords.contains(word) && !builtins.contains(word)) {
            setFormat(match.capturedStart(), match.capturedLength(), m_functionFormat);
        }
    }

    // Классы - слова после class
    QRegularExpression classExpression("\\bclass\\s+([a-zA-Z_]\\w*)");
    QRegularExpressionMatchIterator classIterator = classExpression.globalMatch(text);
    while (classIterator.hasNext()) {
        QRegularExpressionMatch match = classIterator.next();
        setFormat(match.capturedStart(1), match.capturedLength(1), m_typeFormat);
    }

    // Декораторы
    QRegularExpression decoratorExpression("@[a-zA-Z_]\\w*");
    QRegularExpressionMatchIterator decoratorIterator = decoratorExpression.globalMatch(text);
    while (decoratorIterator.hasNext()) {
        QRegularExpressionMatch match = decoratorIterator.next();
        setFormat(match.capturedStart(), match.capturedLength(), m_preprocessorFormat);
    }

    // Строки в двойных кавычках
    QRegularExpression doubleStringExpression("\"([^\"\\\\]|\\\\.)*\"");
    QRegularExpressionMatchIterator doubleIterator = doubleStringExpression.globalMatch(text);
    while (doubleIterator.hasNext()) {
        QRegularExpressionMatch match = doubleIterator.next();
        setFormat(match.capturedStart(), match.capturedLength(), m_stringFormat);
    }

    // Строки в одинарных кавычках
    QRegularExpression singleStringExpression("'([^'\\\\]|\\\\.)*'");
    QRegularExpressionMatchIterator singleIterator = singleStringExpression.globalMatch(text);
    while (singleIterator.hasNext()) {
        QRegularExpressionMatch match = singleIterator.next();
        setFormat(match.capturedStart(), match.capturedLength(), m_stringFormat);
    }

    // Многострочные строки (triple quotes)
    QRegularExpression tripleDoubleExpression("\"\"\"[\\s\\S]*?\"\"\"");
    QRegularExpressionMatchIterator tripleDoubleIterator = tripleDoubleExpression.globalMatch(text);
    while (tripleDoubleIterator.hasNext()) {
        QRegularExpressionMatch match = tripleDoubleIterator.next();
        setFormat(match.capturedStart(), match.capturedLength(), m_stringFormat);
    }

    QRegularExpression tripleSingleExpression("'''[\\s\\S]*?'''");
    QRegularExpressionMatchIterator tripleSingleIterator = tripleSingleExpression.globalMatch(text);
    while (tripleSingleIterator.hasNext()) {
        QRegularExpressionMatch match = tripleSingleIterator.next();
        setFormat(match.capturedStart(), match.capturedLength(), m_stringFormat);
    }

    // f-strings
    QRegularExpression fStringExpression("[fF]\"([^\"\\\\]|\\\\.)*\"");
    QRegularExpressionMatchIterator fStringIterator = fStringExpression.globalMatch(text);
    while (fStringIterator.hasNext()) {
        QRegularExpressionMatch match = fStringIterator.next();
        setFormat(match.capturedStart(), match.capturedLength(), m_stringFormat);
    }

    // Комментарии
    QRegularExpression commentExpression("#[^\n]*");
    QRegularExpressionMatchIterator commentIterator = commentExpression.globalMatch(text);
    while (commentIterator.hasNext()) {
        QRegularExpressionMatch match = commentIterator.next();
        setFormat(match.capturedStart(), match.capturedLength(), m_commentFormat);
    }

    // Числа (включая float, scientific notation)
    QRegularExpression numberExpression("\\b\\d+(\\.\\d+)?([eE][+-]?\\d+)?\\b");
    QRegularExpressionMatchIterator numberIterator = numberExpression.globalMatch(text);
    while (numberIterator.hasNext()) {
        QRegularExpressionMatch match = numberIterator.next();
        setFormat(match.capturedStart(), match.capturedLength(), m_numberFormat);
    }

    // Операторы
    QRegularExpression operatorExpression("[+\\-*/=<>!&|%^~]");
    QRegularExpressionMatchIterator operatorIterator = operatorExpression.globalMatch(text);
    while (operatorIterator.hasNext()) {
        QRegularExpressionMatch match = operatorIterator.next();
        setFormat(match.capturedStart(), match.capturedLength(), m_operatorFormat);
    }
}

void SyntaxHighlighter::highlightJavaScript(const QString &text)
{
    // Ключевые слова JavaScript
    QStringList keywords = {"function", "var", "let", "const", "if", "else", "for",
                            "while", "do", "return", "class", "extends", "import", "export",
                            "from", "async", "await", "try", "catch", "finally",
                            "new", "this", "super", "static", "get", "set",
                            "break", "continue", "switch", "case", "default",
                            "throw", "typeof", "instanceof", "in", "of", "delete",
                            "void", "with", "yield", "debugger"};

    for (const QString &keyword : keywords) {
        QRegularExpression expression("\\b" + keyword + "\\b");
        QRegularExpressionMatchIterator i = expression.globalMatch(text);
        while (i.hasNext()) {
            QRegularExpressionMatch match = i.next();
            setFormat(match.capturedStart(), match.capturedLength(), m_keywordFormat);
        }
    }

    // Встроенные объекты и типы
    QStringList builtins = {"true", "false", "null", "undefined", "NaN", "Infinity",
                            "console", "window", "document", "Array", "Object", "String",
                            "Number", "Boolean", "Date", "RegExp", "Math", "JSON",
                            "Promise", "Error", "TypeError", "SyntaxError", "Map", "Set",
                            "Symbol", "parseInt", "parseFloat", "isNaN", "isFinite"};

    for (const QString &builtin : builtins) {
        QRegularExpression expression("\\b" + QRegularExpression::escape(builtin) + "\\b");
        QRegularExpressionMatchIterator i = expression.globalMatch(text);
        while (i.hasNext()) {
            QRegularExpressionMatch match = i.next();
            setFormat(match.capturedStart(), match.capturedLength(), m_typeFormat);
        }
    }

    // Объявления функций - function name() или name = function()
    QRegularExpression funcDeclExpression("\\bfunction\\s+([a-zA-Z_$]\\w*)");
    QRegularExpressionMatchIterator funcDeclIterator = funcDeclExpression.globalMatch(text);
    while (funcDeclIterator.hasNext()) {
        QRegularExpressionMatch match = funcDeclIterator.next();
        setFormat(match.capturedStart(1), match.capturedLength(1), m_functionFormat);
    }

    // Arrow functions - name = () => или const name = () =>
    QRegularExpression arrowFuncExpression("([a-zA-Z_$]\\w*)\\s*=\\s*\\([^)]*\\)\\s*=>");
    QRegularExpressionMatchIterator arrowIterator = arrowFuncExpression.globalMatch(text);
    while (arrowIterator.hasNext()) {
        QRegularExpressionMatch match = arrowIterator.next();
        setFormat(match.capturedStart(1), match.capturedLength(1), m_functionFormat);
    }

    // Вызовы функций и методов - name() или object.method()
    QRegularExpression callExpression("([a-zA-Z_$]\\w*)\\s*(?=\\()");
    QRegularExpressionMatchIterator callIterator = callExpression.globalMatch(text);
    while (callIterator.hasNext()) {
        QRegularExpressionMatch match = callIterator.next();
        QString word = match.captured(1);
        if (!keywords.contains(word) && !builtins.contains(word)) {
            setFormat(match.capturedStart(1), match.capturedLength(1), m_functionFormat);
        }
    }

    // Классы - class ClassName
    QRegularExpression classExpression("\\bclass\\s+([a-zA-Z_$]\\w*)");
    QRegularExpressionMatchIterator classIterator = classExpression.globalMatch(text);
    while (classIterator.hasNext()) {
        QRegularExpressionMatch match = classIterator.next();
        setFormat(match.capturedStart(1), match.capturedLength(1), m_typeFormat);
    }

    // Строки в двойных кавычках
    QRegularExpression doubleStringExpression("\"([^\"\\\\]|\\\\.)*\"");
    QRegularExpressionMatchIterator doubleIterator = doubleStringExpression.globalMatch(text);
    while (doubleIterator.hasNext()) {
        QRegularExpressionMatch match = doubleIterator.next();
        setFormat(match.capturedStart(), match.capturedLength(), m_stringFormat);
    }

    // Строки в одинарных кавычках
    QRegularExpression singleStringExpression("'([^'\\\\]|\\\\.)*'");
    QRegularExpressionMatchIterator singleIterator = singleStringExpression.globalMatch(text);
    while (singleIterator.hasNext()) {
        QRegularExpressionMatch match = singleIterator.next();
        setFormat(match.capturedStart(), match.capturedLength(), m_stringFormat);
    }

    // Template literals (backticks)
    QRegularExpression templateExpression("`([^`\\\\]|\\\\.)*`");
    QRegularExpressionMatchIterator templateIterator = templateExpression.globalMatch(text);
    while (templateIterator.hasNext()) {
        QRegularExpressionMatch match = templateIterator.next();
        setFormat(match.capturedStart(), match.capturedLength(), m_stringFormat);
    }

    // Регулярные выражения
    QRegularExpression regexExpression("/([^/\\\\\\n]|\\\\.)+/[gimuy]*");
    QRegularExpressionMatchIterator regexIterator = regexExpression.globalMatch(text);
    while (regexIterator.hasNext()) {
        QRegularExpressionMatch match = regexIterator.next();
        setFormat(match.capturedStart(), match.capturedLength(), m_preprocessorFormat);
    }

    // Однострочные комментарии
    QRegularExpression singleCommentExpression("//[^\n]*");
    QRegularExpressionMatchIterator singleCommentIterator = singleCommentExpression.globalMatch(text);
    while (singleCommentIterator.hasNext()) {
        QRegularExpressionMatch match = singleCommentIterator.next();
        setFormat(match.capturedStart(), match.capturedLength(), m_commentFormat);
    }

    // Многострочные комментарии
    QRegularExpression multiCommentExpression("/\\*[\\s\\S]*?\\*/");
    QRegularExpressionMatchIterator multiCommentIterator = multiCommentExpression.globalMatch(text);
    while (multiCommentIterator.hasNext()) {
        QRegularExpressionMatch match = multiCommentIterator.next();
        setFormat(match.capturedStart(), match.capturedLength(), m_commentFormat);
    }

    // JSDoc комментарии
    QRegularExpression jsdocExpression("/\\*\\*[\\s\\S]*?\\*/");
    QRegularExpressionMatchIterator jsdocIterator = jsdocExpression.globalMatch(text);
    while (jsdocIterator.hasNext()) {
        QRegularExpressionMatch match = jsdocIterator.next();
        setFormat(match.capturedStart(), match.capturedLength(), m_commentFormat);
    }

    // Числа (включая hex, binary, octal, float, scientific)
    QRegularExpression numberExpression("\\b(0[xX][0-9a-fA-F]+|0[bB][01]+|0[oO][0-7]+|\\d+(\\.\\d+)?([eE][+-]?\\d+)?)\\b");
    QRegularExpressionMatchIterator numberIterator = numberExpression.globalMatch(text);
    while (numberIterator.hasNext()) {
        QRegularExpressionMatch match = numberIterator.next();
        setFormat(match.capturedStart(), match.capturedLength(), m_numberFormat);
    }

    // Операторы
    QRegularExpression operatorExpression("(===|!==|==|!=|<=|>=|<<|>>|\\+\\+|--|\\+=|-=|\\*=|/=|%=|&=|\\|=|\\^=|&&|\\|\\||[+\\-*/=<>!&|%^~?:])");
    QRegularExpressionMatchIterator operatorIterator = operatorExpression.globalMatch(text);
    while (operatorIterator.hasNext()) {
        QRegularExpressionMatch match = operatorIterator.next();
        setFormat(match.capturedStart(), match.capturedLength(), m_operatorFormat);
    }

    // Свойства объектов - object.property
    QRegularExpression propertyExpression("\\.([a-zA-Z_$]\\w*)");
    QRegularExpressionMatchIterator propertyIterator = propertyExpression.globalMatch(text);
    while (propertyIterator.hasNext()) {
        QRegularExpressionMatch match = propertyIterator.next();
        setFormat(match.capturedStart(1), match.capturedLength(1), m_functionFormat);
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
