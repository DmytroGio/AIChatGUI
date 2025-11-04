#ifndef CHATMANAGER_H
#define CHATMANAGER_H

#include <QObject>
#include <QJsonObject>
#include <QJsonArray>
#include <QString>
#include <QVariantList>
#include <QStandardPaths>
#include <QSqlDatabase>

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
    ParsedContent parsed;   // ✅ НОВОЕ: готовый распарсенный контент
};

struct Chat {
    QString id;
    QString title;
    QString lastMessage;
    QString lastTimestamp;
    QList<Message> messages;
};

class ChatManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantList chatList READ getChatList NOTIFY chatListChanged)
    Q_PROPERTY(QString currentChatId READ getCurrentChatId NOTIFY currentChatChanged)
    Q_PROPERTY(QString currentChatTitle READ getCurrentChatTitle NOTIFY currentChatChanged)
    Q_PROPERTY(int messageCount READ getMessageCount NOTIFY messagesChanged)

public:
    explicit ChatManager(QObject *parent = nullptr);

    Q_INVOKABLE void createNewChat();
    Q_INVOKABLE void switchToChat(const QString &chatId);
    Q_INVOKABLE void deleteChat(const QString &chatId);
    Q_INVOKABLE void addMessage(const QString &text, bool isUser);
    Q_INVOKABLE QVariantList getCurrentMessages();
    Q_INVOKABLE void renameChatTitle(const QString &chatId, const QString &newTitle);

    QVariantList getChatList() const;
    QString getCurrentChatId() const { return m_currentChatId; }
    QString getCurrentChatTitle() const;
    int getMessageCount() const;

signals:
    void chatListChanged();
    void currentChatChanged();
    void messagesChanged();
    void messageAdded(const QString& text, bool isUser);

private:
    void initDatabase();
    void loadChats();
    void saveChatToDb(const Chat &chat);
    void updateChatInDb(const Chat &chat);
    void deleteChatFromDb(const QString &chatId);
    QString generateChatId();
    QString generateTitle(const QString &firstMessage);

    QList<Chat> m_chats;
    QString m_currentChatId;
    QSqlDatabase m_db;

    ParsedContent parseMarkdown(const QString &text);
};

#endif // CHATMANAGER_H
