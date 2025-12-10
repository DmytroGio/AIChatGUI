#include "syntaxhighlighter.h"
#include <QQuickTextDocument>

SyntaxHighlighter::SyntaxHighlighter(QObject *parent)
    : QSyntaxHighlighter(parent)
{
    // VS Code Dark+ theme colors
    // Keywords (if, for, class, etc.) - blue
    m_keywordFormat.setForeground(QColor("#569cd6"));
    m_keywordFormat.setFontWeight(QFont::Bold);

    // Strings - orange/brown
    m_stringFormat.setForeground(QColor("#ce9178"));

    // Comments - gray-green
    m_commentFormat.setForeground(QColor("#6a9955"));
    m_commentFormat.setFontItalic(true);

    // Numbers - light green
    m_numberFormat.setForeground(QColor("#b5cea8"));

    // Operators - white
    m_operatorFormat.setForeground(QColor("#d4d4d4"));

    // Additional formats
    m_functionFormat.setForeground(QColor("#dcdcaa")); // Functions - yellow
    m_functionFormat.setFontWeight(QFont::Bold);

    m_typeFormat.setForeground(QColor("#4ec9b0")); // Data types - turquoise

    m_preprocessorFormat.setForeground(QColor("#c586c0")); // Preprocessor/Decorators - pink
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
    // C++ Keywords
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

    // Data Types
    QStringList types = {"std::", "QString", "QObject", "QWidget", "size_t", "uint32_t", "int32_t"};
    for (const QString &type : types) {
        QRegularExpression expression("\\b" + QRegularExpression::escape(type) + "\\w*");
        QRegularExpressionMatchIterator i = expression.globalMatch(text);
        while (i.hasNext()) {
            QRegularExpressionMatch match = i.next();
            setFormat(match.capturedStart(), match.capturedLength(), m_typeFormat);
        }
    }

    // Functions - words before an opening parenthesis
    QRegularExpression functionExpression("\\b([a-zA-Z_]\\w*)\\s*(?=\\()");
    QRegularExpressionMatchIterator funcIterator = functionExpression.globalMatch(text);
    while (funcIterator.hasNext()) {
        QRegularExpressionMatch match = funcIterator.next();
        setFormat(match.capturedStart(), match.capturedLength(), m_functionFormat);
    }

    // Preprocessor directives
    QRegularExpression preprocExpression("^\\s*#\\w+");
    QRegularExpressionMatchIterator preprocIterator = preprocExpression.globalMatch(text);
    while (preprocIterator.hasNext()) {
        QRegularExpressionMatch match = preprocIterator.next();
        setFormat(match.capturedStart(), match.capturedLength(), m_preprocessorFormat);
    }

    // Double-quoted strings
    QRegularExpression stringExpression("\"([^\"\\\\]|\\\\.)*\"");
    QRegularExpressionMatchIterator stringIterator = stringExpression.globalMatch(text);
    while (stringIterator.hasNext()) {
        QRegularExpressionMatch match = stringIterator.next();
        setFormat(match.capturedStart(), match.capturedLength(), m_stringFormat);
    }

    // Single-quoted characters
    QRegularExpression charExpression("'([^'\\\\]|\\\\.)+'");
    QRegularExpressionMatchIterator charIterator = charExpression.globalMatch(text);
    while (charIterator.hasNext()) {
        QRegularExpressionMatch match = charIterator.next();
        setFormat(match.capturedStart(), match.capturedLength(), m_stringFormat);
    }

    // Single-line comments
    QRegularExpression singleCommentExpression("//[^\n]*");
    QRegularExpressionMatchIterator singleIterator = singleCommentExpression.globalMatch(text);
    while (singleIterator.hasNext()) {
        QRegularExpressionMatch match = singleIterator.next();
        setFormat(match.capturedStart(), match.capturedLength(), m_commentFormat);
    }

    // Numbers
    QRegularExpression numberExpression("\\b\\d+(\\.\\d+)?([eE][+-]?\\d+)?[fFlL]?\\b");
    QRegularExpressionMatchIterator numberIterator = numberExpression.globalMatch(text);
    while (numberIterator.hasNext()) {
        QRegularExpressionMatch match = numberIterator.next();
        setFormat(match.capturedStart(), match.capturedLength(), m_numberFormat);
    }
}

void SyntaxHighlighter::highlightPython(const QString &text)
{
    // Python Keywords
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

    // Built-in constants and types
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

    // Function definitions - words after def
    QRegularExpression defExpression("\\bdef\\s+([a-zA-Z_]\\w*)");
    QRegularExpressionMatchIterator defIterator = defExpression.globalMatch(text);
    while (defIterator.hasNext()) {
        QRegularExpressionMatch match = defIterator.next();
        setFormat(match.capturedStart(1), match.capturedLength(1), m_functionFormat);
    }

    // Function calls - words before an opening parenthesis
    QRegularExpression functionExpression("\\b([a-zA-Z_]\\w*)\\s*(?=\\()");
    QRegularExpressionMatchIterator funcIterator = functionExpression.globalMatch(text);
    while (funcIterator.hasNext()) {
        QRegularExpressionMatch match = funcIterator.next();
        QString word = match.captured(1);
        if (!keywords.contains(word) && !builtins.contains(word)) {
            setFormat(match.capturedStart(), match.capturedLength(), m_functionFormat);
        }
    }

    // Class definitions - words after class
    QRegularExpression classExpression("\\bclass\\s+([a-zA-Z_]\\w*)");
    QRegularExpressionMatchIterator classIterator = classExpression.globalMatch(text);
    while (classIterator.hasNext()) {
        QRegularExpressionMatch match = classIterator.next();
        setFormat(match.capturedStart(1), match.capturedLength(1), m_typeFormat);
    }

    // Decorators
    QRegularExpression decoratorExpression("@[a-zA-Z_]\\w*");
    QRegularExpressionMatchIterator decoratorIterator = decoratorExpression.globalMatch(text);
    while (decoratorIterator.hasNext()) {
        QRegularExpressionMatch match = decoratorIterator.next();
        setFormat(match.capturedStart(), match.capturedLength(), m_preprocessorFormat);
    }

    // Double-quoted strings
    QRegularExpression doubleStringExpression("\"([^\"\\\\]|\\\\.)*\"");
    QRegularExpressionMatchIterator doubleIterator = doubleStringExpression.globalMatch(text);
    while (doubleIterator.hasNext()) {
        QRegularExpressionMatch match = doubleIterator.next();
        setFormat(match.capturedStart(), match.capturedLength(), m_stringFormat);
    }

    // Single-quoted strings
    QRegularExpression singleStringExpression("'([^'\\\\]|\\\\.)*'");
    QRegularExpressionMatchIterator singleIterator = singleStringExpression.globalMatch(text);
    while (singleIterator.hasNext()) {
        QRegularExpressionMatch match = singleIterator.next();
        setFormat(match.capturedStart(), match.capturedLength(), m_stringFormat);
    }

    // Multi-line strings (triple quotes)
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

    // Comments
    QRegularExpression commentExpression("#[^\n]*");
    QRegularExpressionMatchIterator commentIterator = commentExpression.globalMatch(text);
    while (commentIterator.hasNext()) {
        QRegularExpressionMatch match = commentIterator.next();
        setFormat(match.capturedStart(), match.capturedLength(), m_commentFormat);
    }

    // Numbers (including float, scientific notation)
    QRegularExpression numberExpression("\\b\\d+(\\.\\d+)?([eE][+-]?\\d+)?\\b");
    QRegularExpressionMatchIterator numberIterator = numberExpression.globalMatch(text);
    while (numberIterator.hasNext()) {
        QRegularExpressionMatch match = numberIterator.next();
        setFormat(match.capturedStart(), match.capturedLength(), m_numberFormat);
    }

    // Operators
    QRegularExpression operatorExpression("[+\\-*/=<>!&|%^~]");
    QRegularExpressionMatchIterator operatorIterator = operatorExpression.globalMatch(text);
    while (operatorIterator.hasNext()) {
        QRegularExpressionMatch match = operatorIterator.next();
        setFormat(match.capturedStart(), match.capturedLength(), m_operatorFormat);
    }
}

void SyntaxHighlighter::highlightJavaScript(const QString &text)
{
    // JavaScript Keywords
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

    // Built-in objects and types
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

    // Function declarations - function name() or name = function()
    QRegularExpression funcDeclExpression("\\bfunction\\s+([a-zA-Z_$]\\w*)");
    QRegularExpressionMatchIterator funcDeclIterator = funcDeclExpression.globalMatch(text);
    while (funcDeclIterator.hasNext()) {
        QRegularExpressionMatch match = funcDeclIterator.next();
        setFormat(match.capturedStart(1), match.capturedLength(1), m_functionFormat);
    }

    // Arrow functions - name = () => or const name = () =>
    QRegularExpression arrowFuncExpression("([a-zA-Z_$]\\w*)\\s*=\\s*\\([^)]*\\)\\s*=>");
    QRegularExpressionMatchIterator arrowIterator = arrowFuncExpression.globalMatch(text);
    while (arrowIterator.hasNext()) {
        QRegularExpressionMatch match = arrowIterator.next();
        setFormat(match.capturedStart(1), match.capturedLength(1), m_functionFormat);
    }

    // Function and method calls - name() or object.method()
    QRegularExpression callExpression("([a-zA-Z_$]\\w*)\\s*(?=\\()");
    QRegularExpressionMatchIterator callIterator = callExpression.globalMatch(text);
    while (callIterator.hasNext()) {
        QRegularExpressionMatch match = callIterator.next();
        QString word = match.captured(1);
        if (!keywords.contains(word) && !builtins.contains(word)) {
            setFormat(match.capturedStart(1), match.capturedLength(1), m_functionFormat);
        }
    }

    // Classes - class ClassName
    QRegularExpression classExpression("\\bclass\\s+([a-zA-Z_$]\\w*)");
    QRegularExpressionMatchIterator classIterator = classExpression.globalMatch(text);
    while (classIterator.hasNext()) {
        QRegularExpressionMatch match = classIterator.next();
        setFormat(match.capturedStart(1), match.capturedLength(1), m_typeFormat);
    }

    // Double-quoted strings
    QRegularExpression doubleStringExpression("\"([^\"\\\\]|\\\\.)*\"");
    QRegularExpressionMatchIterator doubleIterator = doubleStringExpression.globalMatch(text);
    while (doubleIterator.hasNext()) {
        QRegularExpressionMatch match = doubleIterator.next();
        setFormat(match.capturedStart(), match.capturedLength(), m_stringFormat);
    }

    // Single-quoted strings
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

    // Regular expressions
    QRegularExpression regexExpression("/([^/\\\\\\n]|\\\\.)+/[gimuy]*");
    QRegularExpressionMatchIterator regexIterator = regexExpression.globalMatch(text);
    while (regexIterator.hasNext()) {
        QRegularExpressionMatch match = regexIterator.next();
        setFormat(match.capturedStart(), match.capturedLength(), m_preprocessorFormat);
    }

    // Single-line comments
    QRegularExpression singleCommentExpression("//[^\n]*");
    QRegularExpressionMatchIterator singleCommentIterator = singleCommentExpression.globalMatch(text);
    while (singleCommentIterator.hasNext()) {
        QRegularExpressionMatch match = singleCommentIterator.next();
        setFormat(match.capturedStart(), match.capturedLength(), m_commentFormat);
    }

    // Multi-line comments
    QRegularExpression multiCommentExpression("/\\*[\\s\\S]*?\\*/");
    QRegularExpressionMatchIterator multiCommentIterator = multiCommentExpression.globalMatch(text);
    while (multiCommentIterator.hasNext()) {
        QRegularExpressionMatch match = multiCommentIterator.next();
        setFormat(match.capturedStart(), match.capturedLength(), m_commentFormat);
    }

    // JSDoc comments
    QRegularExpression jsdocExpression("/\\*\\*[\\s\\S]*?\\*/");
    QRegularExpressionMatchIterator jsdocIterator = jsdocExpression.globalMatch(text);
    while (jsdocIterator.hasNext()) {
        QRegularExpressionMatch match = jsdocIterator.next();
        setFormat(match.capturedStart(), match.capturedLength(), m_commentFormat);
    }

    // Numbers (including hex, binary, octal, float, scientific)
    QRegularExpression numberExpression("\\b(0[xX][0-9a-fA-F]+|0[bB][01]+|0[oO][0-7]+|\\d+(\\.\\d+)?([eE][+-]?\\d+)?)\\b");
    QRegularExpressionMatchIterator numberIterator = numberExpression.globalMatch(text);
    while (numberIterator.hasNext()) {
        QRegularExpressionMatch match = numberIterator.next();
        setFormat(match.capturedStart(), match.capturedLength(), m_numberFormat);
    }

    // Operators
    QRegularExpression operatorExpression("(===|!==|==|!=|<=|>=|<<|>>|\\+\\+|--|\\+=|-=|\\*=|/=|%=|&=|\\|=|\\^=|&&|\\|\\||[+\\-*/=<>!&|%^~?:])");
    QRegularExpressionMatchIterator operatorIterator = operatorExpression.globalMatch(text);
    while (operatorIterator.hasNext()) {
        QRegularExpressionMatch match = operatorIterator.next();
        setFormat(match.capturedStart(), match.capturedLength(), m_operatorFormat);
    }

    // Object properties - object.property
    QRegularExpression propertyExpression("\\.([a-zA-Z_$]\\w*)");
    QRegularExpressionMatchIterator propertyIterator = propertyExpression.globalMatch(text);
    while (propertyIterator.hasNext()) {
        QRegularExpressionMatch match = propertyIterator.next();
        setFormat(match.capturedStart(1), match.capturedLength(1), m_functionFormat);
    }
}

void SyntaxHighlighter::highlightQml(const QString &text)
{
    // QML Components and Types
    QStringList qmlTypes = {"Rectangle", "Text", "Image", "MouseArea", "Column", "Row",
                            "Grid", "Flow", "Item", "Window", "ApplicationWindow",
                            "ScrollView", "ListView", "GridView", "Repeater", "Loader",
                            "Timer", "Animation", "NumberAnimation", "ColorAnimation",
                            "PropertyAnimation", "SequentialAnimation", "ParallelAnimation",
                            "Behavior", "Transition", "State", "PropertyChanges",
                            "Component", "QtObject", "Connections", "Binding",
                            "TextField", "Button", "CheckBox", "RadioButton", "ComboBox",
                            "Slider", "ProgressBar", "SpinBox", "TextArea", "Label",
                            "GroupBox", "TabView", "SplitView", "StackView", "Dialog",
                            "Popup", "Drawer", "Menu", "MenuBar", "ToolBar", "StatusBar",
                            "Canvas", "WebView", "VideoOutput", "Camera", "MediaPlayer"};

    // QML Keywords (including JS keywords used in QML)
    QStringList qmlKeywords = {"import", "as", "property", "alias", "readonly", "signal",
                               "function", "default", "required", "component", "pragma",
                               "if", "else", "for", "while", "do", "switch", "case",
                               "break", "continue", "return", "try", "catch", "finally",
                               "throw", "new", "delete", "typeof", "instanceof", "in",
                               "var", "let", "const"};

    // QML Built-in properties and constants
    QStringList qmlBuiltins = {"parent", "children", "anchors", "width", "height", "x", "y", "z",
                               "visible", "enabled", "opacity", "scale", "rotation", "color",
                               "border", "radius", "clip", "focus", "activeFocus", "Keys",
                               "true", "false", "null", "undefined", "console", "Qt",
                               "Math", "Date", "String", "Number", "Array", "Object", "JSON"};

    // QML Global objects and functions
    QStringList qmlGlobals = {"qmlRegisterType", "qsTr", "qsTranslate", "Qt.quit",
                              "Qt.createComponent", "Qt.createQmlObject", "Qt.binding",
                              "Qt.callLater", "Qt.md5", "Qt.btoa", "Qt.atob", "Qt.locale",
                              "Qt.formatDate", "Qt.formatTime", "Qt.formatDateTime"};

    // Highlight QML Types
    for (const QString &type : qmlTypes) {
        QRegularExpression expression("\\b" + QRegularExpression::escape(type) + "\\b");
        QRegularExpressionMatchIterator i = expression.globalMatch(text);
        while (i.hasNext()) {
            QRegularExpressionMatch match = i.next();
            setFormat(match.capturedStart(), match.capturedLength(), m_typeFormat);
        }
    }

    // Highlight Keywords
    for (const QString &keyword : qmlKeywords) {
        QRegularExpression expression("\\b" + QRegularExpression::escape(keyword) + "\\b");
        QRegularExpressionMatchIterator i = expression.globalMatch(text);
        while (i.hasNext()) {
            QRegularExpressionMatch match = i.next();
            setFormat(match.capturedStart(), match.capturedLength(), m_keywordFormat);
        }
    }

    // Highlight Built-in properties and constants
    for (const QString &builtin : qmlBuiltins) {
        QRegularExpression expression("\\b" + QRegularExpression::escape(builtin) + "\\b");
        QRegularExpressionMatchIterator i = expression.globalMatch(text);
        while (i.hasNext()) {
            QRegularExpressionMatch match = i.next();
            setFormat(match.capturedStart(), match.capturedLength(), m_preprocessorFormat);
        }
    }

    // Highlight Global objects
    for (const QString &global : qmlGlobals) {
        QRegularExpression expression("\\b" + QRegularExpression::escape(global) + "\\b");
        QRegularExpressionMatchIterator i = expression.globalMatch(text);
        while (i.hasNext()) {
            QRegularExpressionMatch match = i.next();
            setFormat(match.capturedStart(), match.capturedLength(), m_functionFormat);
        }
    }

    // Object IDs - id: someName
    QRegularExpression idExpression("\\bid\\s*:\\s*([a-zA-Z_]\\w*)");
    QRegularExpressionMatchIterator idIterator = idExpression.globalMatch(text);
    while (idIterator.hasNext()) {
        QRegularExpressionMatch match = idIterator.next();
        setFormat(match.capturedStart(1), match.capturedLength(1), m_functionFormat);
    }

    // Properties - property type name: value
    QRegularExpression propExpression("\\bproperty\\s+(\\w+)\\s+([a-zA-Z_]\\w*)");
    QRegularExpressionMatchIterator propIterator = propExpression.globalMatch(text);
    while (propIterator.hasNext()) {
        QRegularExpressionMatch match = propIterator.next();
        setFormat(match.capturedStart(1), match.capturedLength(1), m_typeFormat);
        setFormat(match.capturedStart(2), match.capturedLength(2), m_functionFormat);
    }

    // Signals - signal signalName(parameters)
    QRegularExpression signalExpression("\\bsignal\\s+([a-zA-Z_]\\w*)");
    QRegularExpressionMatchIterator signalIterator = signalExpression.globalMatch(text);
    while (signalIterator.hasNext()) {
        QRegularExpressionMatch match = signalIterator.next();
        setFormat(match.capturedStart(1), match.capturedLength(1), m_functionFormat);
    }

    // Functions - function functionName()
    QRegularExpression funcExpression("\\bfunction\\s+([a-zA-Z_]\\w*)");
    QRegularExpressionMatchIterator funcIterator = funcExpression.globalMatch(text);
    while (funcIterator.hasNext()) {
        QRegularExpressionMatch match = funcIterator.next();
        setFormat(match.capturedStart(1), match.capturedLength(1), m_functionFormat);
    }

    // Function and property calls - name() or object.property
    QRegularExpression callExpression("([a-zA-Z_]\\w*)(?=\\s*[\\(\\.:])");
    QRegularExpressionMatchIterator callIterator = callExpression.globalMatch(text);
    while (callIterator.hasNext()) {
        QRegularExpressionMatch match = callIterator.next();
        QString word = match.captured(1);
        // Skip if already highlighted as a keyword or type
        if (!qmlKeywords.contains(word) && !qmlTypes.contains(word) && !qmlBuiltins.contains(word)) {
            setFormat(match.capturedStart(1), match.capturedLength(1), m_functionFormat);
        }
    }

    // Binding expressions - property: value
    QRegularExpression bindingExpression("([a-zA-Z_]\\w*)\\s*:");
    QRegularExpressionMatchIterator bindingIterator = bindingExpression.globalMatch(text);
    while (bindingIterator.hasNext()) {
        QRegularExpressionMatch match = bindingIterator.next();
        QString property = match.captured(1);
        if (!qmlKeywords.contains(property) && !qmlTypes.contains(property)) {
            setFormat(match.capturedStart(1), match.capturedLength(1), m_preprocessorFormat);
        }
    }

    // Double-quoted strings
    QRegularExpression doubleStringExpression("\"([^\"\\\\]|\\\\.)*\"");
    QRegularExpressionMatchIterator doubleIterator = doubleStringExpression.globalMatch(text);
    while (doubleIterator.hasNext()) {
        QRegularExpressionMatch match = doubleIterator.next();
        setFormat(match.capturedStart(), match.capturedLength(), m_stringFormat);
    }

    // Single-quoted strings
    QRegularExpression singleStringExpression("'([^'\\\\]|\\\\.)*'");
    QRegularExpressionMatchIterator singleIterator = singleStringExpression.globalMatch(text);
    while (singleIterator.hasNext()) {
        QRegularExpressionMatch match = singleIterator.next();
        setFormat(match.capturedStart(), match.capturedLength(), m_stringFormat);
    }

    // Single-line comments
    QRegularExpression singleCommentExpression("//[^\n]*");
    QRegularExpressionMatchIterator singleCommentIterator = singleCommentExpression.globalMatch(text);
    while (singleCommentIterator.hasNext()) {
        QRegularExpressionMatch match = singleCommentIterator.next();
        setFormat(match.capturedStart(), match.capturedLength(), m_commentFormat);
    }

    // Multi-line comments
    QRegularExpression multiCommentExpression("/\\*[\\s\\S]*?\\*/");
    QRegularExpressionMatchIterator multiCommentIterator = multiCommentExpression.globalMatch(text);
    while (multiCommentIterator.hasNext()) {
        QRegularExpressionMatch match = multiCommentIterator.next();
        setFormat(match.capturedStart(), match.capturedLength(), m_commentFormat);
    }

    // Numbers (including versions, hex, float)
    QRegularExpression numberExpression("\\b(\\d+\\.\\d+|\\d+)([eE][+-]?\\d+)?\\b");
    QRegularExpressionMatchIterator numberIterator = numberExpression.globalMatch(text);
    while (numberIterator.hasNext()) {
        QRegularExpressionMatch match = numberIterator.next();
        setFormat(match.capturedStart(), match.capturedLength(), m_numberFormat);
    }

    // Operators
    QRegularExpression operatorExpression("[+\\-*/=<>!&|%^~?:]");
    QRegularExpressionMatchIterator operatorIterator = operatorExpression.globalMatch(text);
    while (operatorIterator.hasNext()) {
        QRegularExpressionMatch match = operatorIterator.next();
        setFormat(match.capturedStart(), match.capturedLength(), m_operatorFormat);
    }

    // Import versions - import QtQuick 2.15
    QRegularExpression importVersionExpression("\\bimport\\s+[a-zA-Z.]+ (\\d+\\.\\d+)");
    QRegularExpressionMatchIterator importVersionIterator = importVersionExpression.globalMatch(text);
    while (importVersionIterator.hasNext()) {
        QRegularExpressionMatch match = importVersionIterator.next();
        setFormat(match.capturedStart(1), match.capturedLength(1), m_numberFormat);
    }

    // Q_INVOKABLE, Q_PROPERTY and other Qt macros (if found in QML)
    QRegularExpression qtMacroExpression("\\bQ_[A-Z_]+\\b");
    QRegularExpressionMatchIterator qtMacroIterator = qtMacroExpression.globalMatch(text);
    while (qtMacroIterator.hasNext()) {
        QRegularExpressionMatch match = qtMacroIterator.next();
        setFormat(match.capturedStart(), match.capturedLength(), m_preprocessorFormat);
    }
}

void SyntaxHighlighter::setDocument(QQuickTextDocument *document)
{
    if (document && document->textDocument()) {
        QSyntaxHighlighter::setDocument(document->textDocument());
    }
}
