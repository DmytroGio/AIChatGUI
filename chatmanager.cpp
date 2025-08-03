#include "chatmanager.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QDir>
#include <QFile>
#include <QDateTime>
#include <QDebug>
#include <QUuid>

ChatManager::ChatManager(QObject *parent)
    : QObject(parent)
{
    m_dataPath = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir dir(m_dataPath);
    if (!dir.exists()) {
        dir.mkpath(m_dataPath);
    }

    loadChats();

    if (m_chats.isEmpty()) {
        createNewChat();
    }
}

void ChatManager::createNewChat()
{
    Chat newChat;
    newChat.id = generateChatId();
    newChat.title = "New Chat";
    newChat.lastMessage = "";
    newChat.lastTimestamp = QDateTime::currentDateTime().toString("yyyy-MM-dd hh:mm:ss");

    m_chats.prepend(newChat);
    m_currentChatId = newChat.id;

    saveChats();
    emit chatListChanged();
    emit currentChatChanged();
    emit messagesChanged();
}

void ChatManager::switchToChat(const QString &chatId)
{
    if (m_currentChatId != chatId) {
        m_currentChatId = chatId;
        emit currentChatChanged();
        emit messagesChanged();
    }
}

void ChatManager::deleteChat(const QString &chatId)
{
    for (int i = 0; i < m_chats.size(); ++i) {
        if (m_chats[i].id == chatId) {
            m_chats.removeAt(i);
            break;
        }
    }

    if (m_currentChatId == chatId) {
        if (!m_chats.isEmpty()) {
            m_currentChatId = m_chats.first().id;
        } else {
            createNewChat();
            return;
        }
    }

    saveChats();
    emit chatListChanged();
    emit currentChatChanged();
    emit messagesChanged();
}

void ChatManager::addMessage(const QString &text, bool isUser)
{
    for (auto &chat : m_chats) {
        if (chat.id == m_currentChatId) {
            Message msg;
            msg.text = text;
            msg.isUser = isUser;
            msg.timestamp = QDateTime::currentDateTime().toString("yyyy-MM-dd hh:mm:ss");

            chat.messages.append(msg);
            chat.lastMessage = text.left(50) + (text.length() > 50 ? "..." : "");
            chat.lastTimestamp = msg.timestamp;

            // Автогенерация названия для первого сообщения пользователя
            if (chat.title == "New Chat" && isUser && !text.isEmpty()) {
                chat.title = generateTitle(text);
            }

            break;
        }
    }

    saveChats();
    emit chatListChanged();
    emit messagesChanged();
}

QVariantList ChatManager::getCurrentMessages()
{
    QVariantList messages;

    for (const auto &chat : m_chats) {
        if (chat.id == m_currentChatId) {
            for (const auto &msg : chat.messages) {
                QVariantMap msgMap;
                msgMap["text"] = msg.text;
                msgMap["isUser"] = msg.isUser;
                msgMap["timestamp"] = msg.timestamp;
                messages.append(msgMap);
            }
            break;
        }
    }

    return messages;
}

void ChatManager::renameChatTitle(const QString &chatId, const QString &newTitle)
{
    for (auto &chat : m_chats) {
        if (chat.id == chatId) {
            chat.title = newTitle;
            break;
        }
    }

    saveChats();
    emit chatListChanged();
}

QVariantList ChatManager::getChatList() const
{
    QVariantList chatList;

    for (const auto &chat : m_chats) {
        QVariantMap chatMap;
        chatMap["id"] = chat.id;
        chatMap["title"] = chat.title;
        chatMap["lastMessage"] = chat.lastMessage;
        chatMap["lastTimestamp"] = chat.lastTimestamp;
        chatMap["isCurrent"] = (chat.id == m_currentChatId);
        chatList.append(chatMap);
    }

    return chatList;
}

QString ChatManager::getCurrentChatTitle() const
{
    for (const auto &chat : m_chats) {
        if (chat.id == m_currentChatId) {
            return chat.title;
        }
    }
    return "New Chat";
}

void ChatManager::saveChats()
{
    QJsonArray chatsArray;

    for (const auto &chat : m_chats) {
        QJsonObject chatObj;
        chatObj["id"] = chat.id;
        chatObj["title"] = chat.title;
        chatObj["lastMessage"] = chat.lastMessage;
        chatObj["lastTimestamp"] = chat.lastTimestamp;

        QJsonArray messagesArray;
        for (const auto &msg : chat.messages) {
            QJsonObject msgObj;
            msgObj["text"] = msg.text;
            msgObj["isUser"] = msg.isUser;
            msgObj["timestamp"] = msg.timestamp;
            messagesArray.append(msgObj);
        }
        chatObj["messages"] = messagesArray;

        chatsArray.append(chatObj);
    }

    QJsonDocument doc(chatsArray);

    QFile file(m_dataPath + "/chats.json");
    if (file.open(QIODevice::WriteOnly)) {
        file.write(doc.toJson());
    }
}

void ChatManager::loadChats()
{
    QFile file(m_dataPath + "/chats.json");
    if (!file.open(QIODevice::ReadOnly)) {
        return;
    }

    QByteArray data = file.readAll();
    QJsonDocument doc = QJsonDocument::fromJson(data);
    QJsonArray chatsArray = doc.array();

    m_chats.clear();

    for (const auto &value : chatsArray) {
        QJsonObject chatObj = value.toObject();

        Chat chat;
        chat.id = chatObj["id"].toString();
        chat.title = chatObj["title"].toString();
        chat.lastMessage = chatObj["lastMessage"].toString();
        chat.lastTimestamp = chatObj["lastTimestamp"].toString();

        QJsonArray messagesArray = chatObj["messages"].toArray();
        for (const auto &msgValue : messagesArray) {
            QJsonObject msgObj = msgValue.toObject();

            Message msg;
            msg.text = msgObj["text"].toString();
            msg.isUser = msgObj["isUser"].toBool();
            msg.timestamp = msgObj["timestamp"].toString();

            chat.messages.append(msg);
        }

        m_chats.append(chat);
    }

    if (!m_chats.isEmpty()) {
        m_currentChatId = m_chats.first().id;
    }
}

QString ChatManager::generateChatId()
{
    return QUuid::createUuid().toString(QUuid::WithoutBraces);
}

QString ChatManager::generateTitle(const QString &firstMessage)
{
    QString title = firstMessage.left(30);
    if (firstMessage.length() > 30) {
        title += "...";
    }
    return title;
}
