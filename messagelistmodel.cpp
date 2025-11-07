#include "messagelistmodel.h"
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>

MessageListModel::MessageListModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int MessageListModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    return m_messages.size();
}

QVariant MessageListModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_messages.size())
        return QVariant();

    const Message &msg = m_messages.at(index.row());

    switch (role) {
    case TextRole:
        return msg.text;
    case IsUserRole:
        return msg.isUser;
    case TimestampRole:
        return msg.timestamp;
    case BlocksRole: {
        // Конвертируем ParsedContent в QVariantList для QML
        QVariantList blocks;
        for (const auto &block : msg.parsed.blocks) {
            QVariantMap blockMap;
            blockMap["type"] = static_cast<int>(block.type);
            blockMap["content"] = block.content;
            blockMap["language"] = block.language;
            blockMap["isClosed"] = block.isClosed;
            blockMap["lineCount"] = block.lineCount;
            blocks.append(blockMap);
        }
        return blocks;
    }
    default:
        return QVariant();
    }
}

QHash<int, QByteArray> MessageListModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[TextRole] = "text";
    roles[IsUserRole] = "isUser";
    roles[TimestampRole] = "timestamp";
    roles[BlocksRole] = "blocks";
    return roles;
}

void MessageListModel::setDatabase(QSqlDatabase *db)
{
    m_db = db;
}

ParsedContent MessageListModel::deserializeBlocks(const QString &json)
{
    ParsedContent result;

    if (json.isEmpty()) {
        return result;
    }

    QJsonDocument doc = QJsonDocument::fromJson(json.toUtf8());
    if (!doc.isArray()) {
        qDebug() << "ERROR: blocks_json is not an array";
        return result;
    }

    QJsonArray blocksArray = doc.array();

    for (const QJsonValue &value : blocksArray) {
        if (!value.isObject()) continue;

        QJsonObject blockObj = value.toObject();

        ContentBlock block;
        block.type = static_cast<ContentType>(blockObj["type"].toInt());
        block.content = blockObj["content"].toString();
        block.language = blockObj["language"].toString();
        block.isClosed = blockObj["isClosed"].toBool();
        block.lineCount = blockObj["lineCount"].toInt();

        result.blocks.append(block);
    }

    return result;
}

void MessageListModel::loadMessages(const QString &chatId, int limit)
{
    if (!m_db || !m_db->isOpen()) {
        qDebug() << "Database not available";
        return;
    }

    beginResetModel();
    m_messages.clear();
    m_currentChatId = chatId;
    m_oldestLoadedId = INT_MAX;
    m_hasMoreMessages = true;
    endResetModel();

    // Загружаем последние N сообщений
    QSqlQuery query(*m_db);
    query.prepare("SELECT id, text, isUser, timestamp, blocks_json "
                  "FROM messages WHERE chat_id = ? "
                  "ORDER BY id DESC LIMIT ?");
    query.addBindValue(chatId);
    query.addBindValue(limit);

    if (!query.exec()) {
        qDebug() << "Failed to load messages:" << query.lastError().text();
        return;
    }

    QList<Message> loadedMessages;

    while (query.next()) {
        Message msg;
        int msgId = query.value(0).toInt();
        msg.text = query.value(1).toString();
        msg.isUser = query.value(2).toBool();
        msg.timestamp = query.value(3).toString();
        QString blocksJson = query.value(4).toString();

        // Десериализуем блоки
        if (!msg.isUser && !blocksJson.isEmpty()) {
            msg.parsed = deserializeBlocks(blocksJson);
        }

        loadedMessages.prepend(msg);  // Добавляем в начало (т.к. ORDER BY DESC)

        if (msgId < m_oldestLoadedId) {
            m_oldestLoadedId = msgId;
        }
    }

    if (!loadedMessages.isEmpty()) {
        beginInsertRows(QModelIndex(), 0, loadedMessages.size() - 1);
        m_messages = loadedMessages;
        endInsertRows();

        qDebug() << "Loaded" << m_messages.size() << "messages for chat" << chatId;
        emit countChanged();
    }

    // Проверяем, есть ли ещё сообщения
    QSqlQuery countQuery(*m_db);
    countQuery.prepare("SELECT COUNT(*) FROM messages WHERE chat_id = ? AND id < ?");
    countQuery.addBindValue(chatId);
    countQuery.addBindValue(m_oldestLoadedId);

    if (countQuery.exec() && countQuery.next()) {
        m_hasMoreMessages = countQuery.value(0).toInt() > 0;
        emit hasMoreMessagesChanged();
    }
}

void MessageListModel::loadOlderMessages(int count)
{
    if (!m_db || !m_db->isOpen() || !m_hasMoreMessages) {
        return;
    }

    QSqlQuery query(*m_db);
    query.prepare("SELECT id, text, isUser, timestamp, blocks_json "
                  "FROM messages WHERE chat_id = ? AND id < ? "
                  "ORDER BY id DESC LIMIT ?");
    query.addBindValue(m_currentChatId);
    query.addBindValue(m_oldestLoadedId);
    query.addBindValue(count);

    if (!query.exec()) {
        qDebug() << "Failed to load older messages:" << query.lastError().text();
        return;
    }

    QList<Message> olderMessages;

    while (query.next()) {
        Message msg;
        int msgId = query.value(0).toInt();
        msg.text = query.value(1).toString();
        msg.isUser = query.value(2).toBool();
        msg.timestamp = query.value(3).toString();
        QString blocksJson = query.value(4).toString();

        if (!msg.isUser && !blocksJson.isEmpty()) {
            msg.parsed = deserializeBlocks(blocksJson);
        }

        olderMessages.prepend(msg);

        if (msgId < m_oldestLoadedId) {
            m_oldestLoadedId = msgId;
        }
    }

    if (!olderMessages.isEmpty()) {
        beginInsertRows(QModelIndex(), 0, olderMessages.size() - 1);
        for (int i = olderMessages.size() - 1; i >= 0; --i) {
            m_messages.prepend(olderMessages.at(i));
        }
        endInsertRows();

        qDebug() << "Loaded" << olderMessages.size() << "older messages";
        emit countChanged();
    }

    // Обновляем флаг hasMoreMessages
    QSqlQuery countQuery(*m_db);
    countQuery.prepare("SELECT COUNT(*) FROM messages WHERE chat_id = ? AND id < ?");
    countQuery.addBindValue(m_currentChatId);
    countQuery.addBindValue(m_oldestLoadedId);

    if (countQuery.exec() && countQuery.next()) {
        m_hasMoreMessages = countQuery.value(0).toInt() > 0;
        emit hasMoreMessagesChanged();
    }
}

void MessageListModel::appendMessage(const Message &msg)
{
    beginInsertRows(QModelIndex(), m_messages.size(), m_messages.size());
    m_messages.append(msg);
    endInsertRows();
    emit countChanged();
}

void MessageListModel::updateLastMessage(const Message &msg)
{
    if (m_messages.isEmpty()) {
        return;
    }

    int lastIndex = m_messages.size() - 1;
    m_messages[lastIndex] = msg;

    QModelIndex index = createIndex(lastIndex, 0);
    emit dataChanged(index, index);
}

void MessageListModel::clear()
{
    beginResetModel();
    m_messages.clear();
    m_currentChatId.clear();
    m_oldestLoadedId = INT_MAX;
    m_hasMoreMessages = true;
    endResetModel();
    emit countChanged();
}
