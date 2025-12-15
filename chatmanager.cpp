#include "chatmanager.h"
#include <QDir>
#include <QDateTime>
#include <QDebug>
#include <QUuid>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>
#include <QStandardPaths>

ChatManager::ChatManager(QObject *parent)
    : QObject(parent)
{
    m_messageModel = new MessageListModel(this);
    initDatabase();
    m_messageModel->setDatabase(&m_db);
    loadExampleQuestions();
    loadChats();
    createNewWelcomeChat();
}

void ChatManager::createNewChat()
{
    Chat newChat;
    newChat.id = generateChatId();
    newChat.title = "New Chat";
    newChat.lastMessage = "";
    newChat.lastTimestamp = QDateTime::currentDateTime().toString("yyyy-MM-dd hh:mm:ss");

    saveChatToDb(newChat);
    m_chats.prepend(newChat);
    m_currentChatId = newChat.id;

    emit chatListChanged();
    emit currentChatChanged();
    emit messagesChanged();
}

void ChatManager::createNewWelcomeChat()
{
    m_currentChatId = "welcome";
    m_messageModel->clear();

    emit currentChatChanged();
    emit messagesChanged();
    emit chatListChanged();

    qDebug() << "Welcome chat created";
}

void ChatManager::switchToChat(const QString &chatId)
{
    if (m_currentChatId != chatId) {
        m_currentChatId = chatId;
        m_messageModel->loadMessages(chatId, 30);

        emit currentChatChanged();
        emit messagesChanged();
        emit chatListChanged();
    }
}

void ChatManager::deleteChat(const QString &chatId)
{
    deleteChatFromDb(chatId);

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

    emit chatListChanged();
    emit currentChatChanged();
    emit messagesChanged();
}

void ChatManager::addMessage(const QString &text, bool isUser)
{
    // Create real chat on first user message from welcome screen
    if (m_currentChatId == "welcome" && isUser) {
        qDebug() << "Creating new chat from welcome screen";
        createNewChat();
    }

    for (auto &chat : m_chats) {
        if (chat.id == m_currentChatId) {
            Message msg;
            msg.text = text;
            msg.isUser = isUser;
            msg.timestamp = QDateTime::currentDateTime().toString("yyyy-MM-dd hh:mm:ss");

            // Parse all AI messages
            if (!isUser) {
                msg.parsed = parseMarkdown(text);
                qDebug() << "Parsed" << msg.parsed.blocks.size() << "blocks for AI message";
            }

            chat.messages.append(msg);
            chat.lastMessage = text.left(50) + (text.length() > 50 ? "..." : "");
            chat.lastTimestamp = msg.timestamp;

            // Auto-generate title from first user message
            if (chat.title == "New Chat" && isUser && !text.isEmpty()) {
                chat.title = generateTitle(text);
            }

            // Save message with blocks_json
            QSqlQuery query;
            query.prepare("INSERT INTO messages (chat_id, text, isUser, timestamp, blocks_json) "
                          "VALUES (?, ?, ?, ?, ?)");
            query.addBindValue(chat.id);
            query.addBindValue(msg.text);
            query.addBindValue(msg.isUser);
            query.addBindValue(msg.timestamp);

            if (!isUser && !msg.parsed.blocks.isEmpty()) {
                query.addBindValue(serializeBlocks(msg.parsed));
            } else {
                query.addBindValue(QVariant());
            }

            if (!query.exec()) {
                qDebug() << "Failed to save message:" << query.lastError().text();
            }

            updateChatInDb(chat);
            m_messageModel->appendMessage(msg);
            break;
        }
    }

    emit messageAdded(text, isUser);
    emit chatListChanged();
    emit messagesChanged();
}

QString ChatManager::serializeBlocks(const ParsedContent& parsed)
{
    QJsonArray blocksArray;

    for (const auto& block : parsed.blocks) {
        QJsonObject blockObj;
        blockObj["type"] = static_cast<int>(block.type);
        blockObj["content"] = block.content;
        blockObj["language"] = block.language;
        blockObj["isClosed"] = block.isClosed;
        blockObj["lineCount"] = block.lineCount;
        blocksArray.append(blockObj);
    }

    QJsonDocument doc(blocksArray);
    return doc.toJson(QJsonDocument::Compact);
}

ParsedContent ChatManager::deserializeBlocks(const QString& json)
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

    for (const QJsonValue& value : blocksArray) {
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

                QVariantList blocks;
                for (const auto &block : msg.parsed.blocks) {
                    QVariantMap blockMap;
                    blockMap["type"] = static_cast<int>(block.type);
                    blockMap["content"] = block.content;
                    blockMap["language"] = block.language;
                    blockMap["isClosed"] = block.isClosed;
                    blockMap["lineCount"] = block.lineCount;
                    blocks.append(blockMap);
                    qDebug() << "Block type:" << static_cast<int>(block.type)
                             << "content:" << block.content.left(50);
                }
                msgMap["blocks"] = blocks;

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
            updateChatInDb(chat);
            break;
        }
    }

    emit chatListChanged();
}

void ChatManager::updateLastMessage(const QString &text)
{
    for (auto &chat : m_chats) {
        if (chat.id == m_currentChatId && !chat.messages.isEmpty()) {
            auto &lastMsg = chat.messages.last();
            if (!lastMsg.isUser) {
                lastMsg.text = text;
                lastMsg.parsed = parseMarkdown(text);

                QSqlQuery query;
                query.prepare("UPDATE messages SET text = ?, blocks_json = ? "
                              "WHERE chat_id = ? AND id = (SELECT MAX(id) FROM messages WHERE chat_id = ?)");
                query.addBindValue(text);
                query.addBindValue(serializeBlocks(lastMsg.parsed));
                query.addBindValue(chat.id);
                query.addBindValue(chat.id);

                if (!query.exec()) {
                    qDebug() << "Failed to update message blocks:" << query.lastError().text();
                }

                m_messageModel->updateLastMessage(lastMsg);
                emit messagesChanged();
                return;
            }
        }
    }
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

void ChatManager::initDatabase()
{
    QString dataPath = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir dir(dataPath);
    if (!dir.exists()) {
        dir.mkpath(dataPath);
    }

    QString dbPath = dataPath + "/chats.db";
    qDebug() << "Database path:" << dbPath;

    m_db = QSqlDatabase::addDatabase("QSQLITE");
    m_db.setDatabaseName(dbPath);

    if (!m_db.open()) {
        qDebug() << "Failed to open database:" << m_db.lastError().text();
        return;
    }

    // SQLite optimizations
    QSqlQuery pragmaQuery;
    pragmaQuery.exec("PRAGMA journal_mode=WAL");
    pragmaQuery.exec("PRAGMA synchronous=NORMAL");
    pragmaQuery.exec("PRAGMA cache_size=-32000");
    pragmaQuery.exec("PRAGMA temp_store=MEMORY");

    qDebug() << "SQLite optimizations applied";

    QSqlQuery query;

    query.exec("CREATE TABLE IF NOT EXISTS chats ("
               "id TEXT PRIMARY KEY, "
               "title TEXT, "
               "lastMessage TEXT, "
               "lastTimestamp TEXT, "
               "created_at TEXT)");

    query.exec("CREATE TABLE IF NOT EXISTS messages ("
               "id INTEGER PRIMARY KEY AUTOINCREMENT, "
               "chat_id TEXT, "
               "text TEXT, "
               "isUser INTEGER, "
               "timestamp TEXT, "
               "blocks_json TEXT, "
               "FOREIGN KEY(chat_id) REFERENCES chats(id) ON DELETE CASCADE)");

    query.exec("CREATE TABLE IF NOT EXISTS settings ("
               "key TEXT PRIMARY KEY, "
               "value TEXT)");

    qDebug() << "Settings table created";

    // Add blocks_json column if it doesn't exist
    QSqlQuery checkColumn;
    checkColumn.exec("PRAGMA table_info(messages)");
    bool hasBlocksJson = false;
    while (checkColumn.next()) {
        if (checkColumn.value(1).toString() == "blocks_json") {
            hasBlocksJson = true;
            break;
        }
    }

    if (!hasBlocksJson) {
        qDebug() << "Adding blocks_json column to existing messages table";
        query.exec("ALTER TABLE messages ADD COLUMN blocks_json TEXT");
    }

    // Create index for fast sorting
    query.exec("CREATE INDEX IF NOT EXISTS idx_chat_messages_desc "
               "ON messages(chat_id, id DESC)");

    qDebug() << "Database initialized with blocks_json support";
}

void ChatManager::loadChats()
{
    m_chats.clear();

    QSqlQuery query("SELECT id, title, lastMessage, lastTimestamp FROM chats ORDER BY lastTimestamp DESC");

    while (query.next()) {
        Chat chat;
        chat.id = query.value(0).toString();
        chat.title = query.value(1).toString();
        chat.lastMessage = query.value(2).toString();
        chat.lastTimestamp = query.value(3).toString();

        // Load messages with blocks_json
        QSqlQuery msgQuery;
        msgQuery.prepare("SELECT text, isUser, timestamp, blocks_json FROM messages WHERE chat_id = ? ORDER BY id ASC");
        msgQuery.addBindValue(chat.id);
        msgQuery.exec();

        while (msgQuery.next()) {
            Message msg;
            msg.text = msgQuery.value(0).toString();
            msg.isUser = msgQuery.value(1).toBool();
            msg.timestamp = msgQuery.value(2).toString();
            QString blocksJson = msgQuery.value(3).toString();

            if (!msg.isUser) {
                if (!blocksJson.isEmpty()) {
                    // Load from cache
                    msg.parsed = deserializeBlocks(blocksJson);
                    qDebug() << "Loaded cached blocks:" << msg.parsed.blocks.size();
                } else {
                    // Parse and cache (migration for old messages)
                    msg.parsed = parseMarkdown(msg.text);
                    qDebug() << "Parsed and caching blocks:" << msg.parsed.blocks.size();

                    QSqlQuery updateQuery;
                    updateQuery.prepare("UPDATE messages SET blocks_json = ? WHERE chat_id = ? AND text = ?");
                    updateQuery.addBindValue(serializeBlocks(msg.parsed));
                    updateQuery.addBindValue(chat.id);
                    updateQuery.addBindValue(msg.text);
                    updateQuery.exec();
                }
            }

            chat.messages.append(msg);
        }

        m_chats.append(chat);
    }

    if (!m_chats.isEmpty()) {
        m_currentChatId = m_chats.first().id;
    }

    qDebug() << "Loaded" << m_chats.size() << "chats from database";
}

void ChatManager::saveChatToDb(const Chat &chat)
{
    QSqlQuery query;
    query.prepare("INSERT INTO chats (id, title, lastMessage, lastTimestamp, created_at) "
                  "VALUES (?, ?, ?, ?, ?)");
    query.addBindValue(chat.id);
    query.addBindValue(chat.title);
    query.addBindValue(chat.lastMessage);
    query.addBindValue(chat.lastTimestamp);
    query.addBindValue(chat.lastTimestamp);

    if (!query.exec()) {
        qDebug() << "Failed to save chat:" << query.lastError().text();
    }
}

void ChatManager::updateChatInDb(const Chat &chat)
{
    QSqlQuery query;
    query.prepare("UPDATE chats SET title = ?, lastMessage = ?, lastTimestamp = ? WHERE id = ?");
    query.addBindValue(chat.title);
    query.addBindValue(chat.lastMessage);
    query.addBindValue(chat.lastTimestamp);
    query.addBindValue(chat.id);

    if (!query.exec()) {
        qDebug() << "Failed to update chat:" << query.lastError().text();
    }
}

void ChatManager::deleteChatFromDb(const QString &chatId)
{
    QSqlQuery query;
    query.prepare("DELETE FROM chats WHERE id = ?");
    query.addBindValue(chatId);

    if (!query.exec()) {
        qDebug() << "Failed to delete chat:" << query.lastError().text();
    }

    // Delete messages (if CASCADE is not configured)
    query.prepare("DELETE FROM messages WHERE chat_id = ?");
    query.addBindValue(chatId);
    query.exec();
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

ParsedContent ChatManager::parseMarkdown(const QString &text)
{
    ParsedContent result;

    qDebug() << "=== parseMarkdown called ===";
    qDebug() << "Text length:" << text.length();
    qDebug() << "Text preview:" << text.left(100);

    QRegularExpression thinkRegex("<think>([\\s\\S]*?)(?:</think>|$)");
    QRegularExpression codeRegex("```(\\w*)\\n?([\\s\\S]*?)(?:```|$)");

    struct Block {
        int start;
        int end;
        ContentType type;
        QString content;
        QString language;
        bool isClosed;
    };

    QList<Block> allBlocks;

    // Find all <think> blocks
    QRegularExpressionMatchIterator thinkIt = thinkRegex.globalMatch(text);
    while (thinkIt.hasNext()) {
        QRegularExpressionMatch match = thinkIt.next();
        Block block;
        block.start = match.capturedStart();
        block.end = match.capturedEnd();
        block.type = ContentType::Think;
        block.content = match.captured(1).trimmed();
        block.isClosed = match.captured(0).contains("</think>");
        allBlocks.append(block);
    }

    // Find all code blocks
    QRegularExpressionMatchIterator codeIt = codeRegex.globalMatch(text);
    while (codeIt.hasNext()) {
        QRegularExpressionMatch match = codeIt.next();
        Block block;
        block.start = match.capturedStart();
        block.end = match.capturedEnd();
        block.type = ContentType::Code;
        block.language = match.captured(1).isEmpty() ? "text" : match.captured(1);
        block.content = match.captured(2);
        block.content.replace(QRegularExpression("^\\n+"), "");
        block.content.replace(QRegularExpression("\\n+$"), "");
        block.isClosed = match.captured(0).endsWith("```");
        allBlocks.append(block);
    }

    // Sort blocks by position
    std::sort(allBlocks.begin(), allBlocks.end(),
              [](const Block &a, const Block &b) { return a.start < b.start; });

    // Build result
    int currentIndex = 0;

    for (const Block &block : allBlocks) {
        // Add text before block
        if (block.start > currentIndex) {
            QString textBefore = text.mid(currentIndex, block.start - currentIndex).trimmed();
            if (!textBefore.isEmpty()) {
                ContentBlock textBlock;
                textBlock.type = ContentType::Text;
                textBlock.content = textBefore;
                result.blocks.append(textBlock);
            }
        }

        // Add the block itself
        ContentBlock contentBlock;
        contentBlock.type = block.type;
        contentBlock.content = block.content;
        contentBlock.isClosed = block.isClosed;

        if (block.type == ContentType::Code) {
            contentBlock.language = block.language;
            contentBlock.lineCount = block.content.count('\n') + 1;
        }

        result.blocks.append(contentBlock);
        currentIndex = block.end;
    }

    // Add remaining text
    if (currentIndex < text.length()) {
        QString remainingText = text.mid(currentIndex).trimmed();
        if (!remainingText.isEmpty()) {
            ContentBlock textBlock;
            textBlock.type = ContentType::Text;
            textBlock.content = remainingText;
            result.blocks.append(textBlock);
        }
    }

    qDebug() << "=== parseMarkdown finished ===";
    qDebug() << "Total blocks parsed:" << result.blocks.size();
    for (int i = 0; i < result.blocks.size(); i++) {
        qDebug() << "Block" << i << "- Type:" << static_cast<int>(result.blocks[i].type)
        << "Content length:" << result.blocks[i].content.length();
    }

    return result;
}

void ChatManager::loadExampleQuestions()
{
    m_exampleQuestions.clear();

    QSqlQuery query;
    query.prepare("SELECT value FROM settings WHERE key = ?");
    query.addBindValue("example_questions");

    if (query.exec() && query.next()) {
        QString json = query.value(0).toString();
        QJsonDocument doc = QJsonDocument::fromJson(json.toUtf8());

        if (doc.isArray()) {
            QJsonArray arr = doc.array();
            for (const QJsonValue &val : arr) {
                m_exampleQuestions.append(val.toString());
            }
        }
    }


    if (m_exampleQuestions.isEmpty()) {
        m_exampleQuestions << "💡 Explain quantum physics in simple terms"
                           << "📝 Help me write Python code"
                           << "🎨 Give me interface design tips";
        saveExampleQuestions();
    }

    qDebug() << "Loaded example questions:" << m_exampleQuestions.size();
}

void ChatManager::saveExampleQuestions()
{
    QJsonArray arr;
    for (const QString &q : m_exampleQuestions) {
        arr.append(q);
    }

    QJsonDocument doc(arr);
    QString json = doc.toJson(QJsonDocument::Compact);

    QSqlQuery query;
    query.prepare("INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)");
    query.addBindValue("example_questions");
    query.addBindValue(json);

    if (!query.exec()) {
        qDebug() << "Failed to save example questions:" << query.lastError().text();
    } else {
        qDebug() << "Example questions saved";
    }
}

void ChatManager::updateExampleQuestion(int index, const QString &text)
{
    if (index >= 0 && index < m_exampleQuestions.size()) {
        m_exampleQuestions[index] = text;
        saveExampleQuestions();
        emit exampleQuestionsChanged();
        qDebug() << "Updated example question" << index << "to:" << text;
    }
}

QVariantList ChatManager::getExampleQuestions() const
{
    QVariantList list;
    for (const QString &q : m_exampleQuestions) {
        list.append(q);
    }
    return list;
}
