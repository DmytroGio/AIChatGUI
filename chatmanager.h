#ifndef CHATMANAGER_H
#define CHATMANAGER_H

#include <QObject>
#include <QJsonObject>
#include <QJsonArray>
#include <QString>
#include <QVariantList>
#include <QStandardPaths>
#include <QSqlDatabase>
#include "message.h"
#include "messagelistmodel.h"

class MessageListModel;

class ChatManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantList chatList READ getChatList NOTIFY chatListChanged)
    Q_PROPERTY(QString currentChatId READ getCurrentChatId NOTIFY currentChatChanged)
    Q_PROPERTY(QString currentChatTitle READ getCurrentChatTitle NOTIFY currentChatChanged)
    Q_PROPERTY(int messageCount READ getMessageCount NOTIFY messagesChanged)
    Q_PROPERTY(MessageListModel* messageModel READ messageModel CONSTANT)
    Q_PROPERTY(bool isWelcomeChat READ isWelcomeChat NOTIFY currentChatChanged)
    Q_PROPERTY(QVariantList exampleQuestions READ getExampleQuestions NOTIFY exampleQuestionsChanged)

public:
    explicit ChatManager(QObject *parent = nullptr);

    Q_INVOKABLE void createNewChat();
    Q_INVOKABLE void switchToChat(const QString &chatId);
    Q_INVOKABLE void deleteChat(const QString &chatId);
    Q_INVOKABLE void addMessage(const QString &text, bool isUser);
    Q_INVOKABLE QVariantList getCurrentMessages();
    Q_INVOKABLE void renameChatTitle(const QString &chatId, const QString &newTitle);
    Q_INVOKABLE void updateLastMessage(const QString &text);
    Q_INVOKABLE void createNewWelcomeChat();
    Q_INVOKABLE void updateExampleQuestion(int index, const QString &text);

    bool isWelcomeChat() const { return m_currentChatId == "welcome"; }
    MessageListModel* messageModel() const { return m_messageModel; }
    QVariantList getChatList() const;
    QString getCurrentChatId() const { return m_currentChatId; }
    QString getCurrentChatTitle() const;
    int getMessageCount() const;
    QVariantList getExampleQuestions() const;

signals:
    void chatListChanged();
    void currentChatChanged();
    void messagesChanged();
    void messageAdded(const QString& text, bool isUser);
    void exampleQuestionsChanged();

private:
    QString serializeBlocks(const ParsedContent& parsed);
    ParsedContent deserializeBlocks(const QString& json);

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

    MessageListModel* m_messageModel;

    void loadExampleQuestions();
    void saveExampleQuestions();
    QStringList m_exampleQuestions;
};

#endif // CHATMANAGER_H
