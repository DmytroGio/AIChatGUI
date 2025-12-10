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
    QString language;  // For code blocks
    bool isClosed;     // For code and think blocks
    int lineCount;     // For code blocks
};

struct ParsedContent {
    QList<ContentBlock> blocks;
};

struct Message {
    QString text;           // Original text (for history/storage)
    bool isUser;
    QString timestamp;
    ParsedContent parsed;   // Parsed content ready for display
};

struct Chat {
    QString id;
    QString title;
    QString lastMessage;
    QString lastTimestamp;
    QList<Message> messages;
};

#endif // MESSAGE_H
