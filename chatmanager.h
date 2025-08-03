#ifndef CHATMANAGER_H
#define CHATMANAGER_H

#include <QObject>
#include <QJsonObject>
#include <QJsonArray>
#include <QString>
#include <QVariantList>
#include <QStandardPaths>

struct Message {
    QString text;
    bool isUser;
    QString timestamp;
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

signals:
    void chatListChanged();
    void currentChatChanged();
    void messagesChanged();

private:
    void saveChats();
    void loadChats();
    QString generateChatId();
    QString generateTitle(const QString &firstMessage);

    QList<Chat> m_chats;
    QString m_currentChatId;
    QString m_dataPath;
};

#endif // CHATMANAGER_H
