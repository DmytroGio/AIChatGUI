#ifndef MESSAGE_H
#define MESSAGE_H

#include <QString>
#include <QList>

enum class ContentType {
    Text,
    Code,
    Think
};

struct ContentBlock {
    ContentType type;
    QString content;
    QString language;  // Для code блоков
    bool isClosed;     // Для code и think блоков
    int lineCount;     // Для code блоков
};

struct ParsedContent {
    QList<ContentBlock> blocks;
};

struct Message {
    QString text;           // Оригинальный текст (для истории)
    bool isUser;
    QString timestamp;
    ParsedContent parsed;   // Готовый распарсенный контент
};

struct Chat {
    QString id;
    QString title;
    QString lastMessage;
    QString lastTimestamp;
    QList<Message> messages;
};

#endif // MESSAGE_H
