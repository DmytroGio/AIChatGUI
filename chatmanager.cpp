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

    m_dataPath += "/chats.json";

    qDebug() << "Chat file path:" << m_dataPath;

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
        emit chatListChanged();
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
    qDebug() << "Saving chats, count:" << m_chats.size();

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

    QFile file(m_dataPath);
    if (file.open(QIODevice::WriteOnly)) {
        file.write(doc.toJson());
        file.close(); // ДОБАВИТЬ
        qDebug() << "Chats saved successfully to:" << m_dataPath; // ДОБАВИТЬ
    } else {
        qDebug() << "Failed to save chats to:" << m_dataPath; // ДОБАВИТЬ
    }
}

void ChatManager::loadChats()
{
    qDebug() << "Loading chats from:" << m_dataPath;

    QFile file(m_dataPath);
    if (!file.open(QIODevice::ReadOnly)) {
        qDebug() << "File not found or cannot open:" << m_dataPath; // ДОБАВИТЬ
        return; // Выходим, конструктор создаст новый чат
    }

    QByteArray data = file.readAll();
    file.close();
    qDebug() << "Loaded data size:" << data.size();

    if (data.isEmpty()) {
        qDebug() << "Chats file is empty";
        return; // Выходим, конструктор создаст новый чат
    }

    QJsonDocument doc = QJsonDocument::fromJson(data);
    if (doc.isNull()) {
        qDebug() << "Failed to parse chats file";
        return; // Выходим, конструктор создаст новый чат
    }

    m_chats.clear();

    // Проверяем новый формат (с корневым объектом)
    if (doc.isObject()) {
        QJsonObject rootObj = doc.object();

        if (rootObj.contains("chats") && rootObj.contains("currentChatId")) {
            // Новый формат
            m_currentChatId = rootObj["currentChatId"].toString();
            QJsonArray chatsArray = rootObj["chats"].toArray();

            for (const auto &value : chatsArray) {
                QJsonObject chatObj = value.toObject();

                Chat chat;
                chat.id = chatObj["id"].toString();
                chat.title = chatObj["title"].toString();
                chat.lastMessage = chatObj["lastMessage"].toString();
                chat.lastTimestamp = chatObj["lastTimestamp"].toString();

                QJsonArray messagesArray = chatObj["messages"].toArray();
                for (const auto &msgValue : messagesArray) {
                    QJsonObject messageObj = msgValue.toObject();
                    Message message;
                    message.text = messageObj["text"].toString();
                    message.isUser = messageObj["isUser"].toBool();
                    message.timestamp = messageObj["timestamp"].toString();
                    chat.messages.append(message);
                }

                m_chats.append(chat);
            }

            qDebug() << "Loaded chats in new format:" << m_chats.size();
        } else {
            qDebug() << "Object format but not recognized, will create new chat";
            return; // Конструктор создаст новый чат
        }
    }
    // Проверяем старый формат (массив чатов в корне)
    else if (doc.isArray()) {
        QJsonArray chatsArray = doc.array();

        for (const auto &value : chatsArray) {
            QJsonObject chatObj = value.toObject();

            Chat chat;
            chat.id = chatObj.contains("id") ? chatObj["id"].toString() : generateChatId();
            chat.title = chatObj.contains("title") ? chatObj["title"].toString() : "Restored Chat";
            chat.lastMessage = chatObj.contains("lastMessage") ? chatObj["lastMessage"].toString() : "";
            chat.lastTimestamp = chatObj.contains("lastTimestamp") ? chatObj["lastTimestamp"].toString() : QDateTime::currentDateTime().toString(Qt::ISODate);

            if (chatObj.contains("messages")) {
                QJsonArray messagesArray = chatObj["messages"].toArray();
                for (const auto &msgValue : messagesArray) {
                    QJsonObject messageObj = msgValue.toObject();
                    Message message;
                    message.text = messageObj["text"].toString();
                    message.isUser = messageObj["isUser"].toBool();
                    message.timestamp = messageObj.contains("timestamp") ? messageObj["timestamp"].toString() : chat.lastTimestamp;
                    chat.messages.append(message);
                }
            }

            m_chats.append(chat);
        }

        if (!m_chats.isEmpty()) {
            m_currentChatId = m_chats.first().id;
            saveChats(); // Сохраняем в новом формате
            qDebug() << "Converted old format to new format:" << m_chats.size();
        }
    }

    // Проверяем, что текущий чат существует
    if (!m_currentChatId.isEmpty() && !m_chats.isEmpty()) {
        bool found = false;
        for (const auto &chat : m_chats) {
            if (chat.id == m_currentChatId) {
                found = true;
                break;
            }
        }
        if (!found) {
            m_currentChatId = m_chats.first().id;
        }
    }

    qDebug() << "Successfully loaded" << m_chats.size() << "chats, current:" << m_currentChatId;
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

int ChatManager::getMessageCount() const
{
    for (const auto& chat : m_chats) {
        if (chat.id == m_currentChatId) {
            return chat.messages.size();
        }
    }
    return 0;
}
