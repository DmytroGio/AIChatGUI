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
    initDatabase();
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

    saveChatToDb(newChat);  // Изменено
    m_chats.prepend(newChat);
    m_currentChatId = newChat.id;

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
    deleteChatFromDb(chatId);  // Добавлено

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
    for (auto &chat : m_chats) {
        if (chat.id == m_currentChatId) {
            Message msg;
            msg.text = text;
            msg.isUser = isUser;
            msg.timestamp = QDateTime::currentDateTime().toString("yyyy-MM-dd hh:mm:ss");

            // ✅ ИСПРАВЛЕНО: Парсим ВСЕ сообщения от AI (не только первое)
            if (!isUser) {
                msg.parsed = parseMarkdown(text);
                qDebug() << "Parsed" << msg.parsed.blocks.size() << "blocks for AI message";
            }

            chat.messages.append(msg);
            chat.lastMessage = text.left(50) + (text.length() > 50 ? "..." : "");
            chat.lastTimestamp = msg.timestamp;

            // Автогенерация названия для первого сообщения пользователя
            if (chat.title == "New Chat" && isUser && !text.isEmpty()) {
                chat.title = generateTitle(text);
            }

            // Сохраняем сообщение в БД
            QSqlQuery query;
            query.prepare("INSERT INTO messages (chat_id, text, isUser, timestamp) VALUES (?, ?, ?, ?)");
            query.addBindValue(chat.id);
            query.addBindValue(msg.text);
            query.addBindValue(msg.isUser);
            query.addBindValue(msg.timestamp);

            if (!query.exec()) {
                qDebug() << "Failed to save message:" << query.lastError().text();
            }

            // Обновляем чат в БД
            updateChatInDb(chat);

            break;
        }
    }

    emit messageAdded(text, isUser);
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

                // ✅ НОВОЕ: добавляем распарсенные блоки
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
            updateChatInDb(chat);  // Добавлено
            break;
        }
    }

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

    QSqlQuery query;

    // Создаём таблицу чатов
    query.exec("CREATE TABLE IF NOT EXISTS chats ("
               "id TEXT PRIMARY KEY, "
               "title TEXT, "
               "lastMessage TEXT, "
               "lastTimestamp TEXT, "
               "created_at TEXT)");

    // Создаём таблицу сообщений
    query.exec("CREATE TABLE IF NOT EXISTS messages ("
               "id INTEGER PRIMARY KEY AUTOINCREMENT, "
               "chat_id TEXT, "
               "text TEXT, "
               "isUser INTEGER, "
               "timestamp TEXT, "
               "FOREIGN KEY(chat_id) REFERENCES chats(id) ON DELETE CASCADE)");

    qDebug() << "Database initialized";
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

        // Загружаем сообщения для этого чата
        QSqlQuery msgQuery;
        msgQuery.prepare("SELECT text, isUser, timestamp FROM messages WHERE chat_id = ? ORDER BY id ASC");
        msgQuery.addBindValue(chat.id);
        msgQuery.exec();

        while (msgQuery.next()) {
            Message msg;
            msg.text = msgQuery.value(0).toString();
            msg.isUser = msgQuery.value(1).toBool();
            msg.timestamp = msgQuery.value(2).toString();


            if (!msg.isUser) {
                msg.parsed = parseMarkdown(msg.text);
                qDebug() << "Loaded AI message with" << msg.parsed.blocks.size() << "blocks";
            }
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

    // Удаляем сообщения (если не настроен CASCADE)
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

    // Regex для поиска блоков
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

    // Находим все <think> блоки
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

    // Находим все code блоки
    QRegularExpressionMatchIterator codeIt = codeRegex.globalMatch(text);
    while (codeIt.hasNext()) {
        QRegularExpressionMatch match = codeIt.next();
        Block block;
        block.start = match.capturedStart();
        block.end = match.capturedEnd();
        block.type = ContentType::Code;
        block.language = match.captured(1).isEmpty() ? "text" : match.captured(1);
        block.content = match.captured(2);
        // Убираем лишние переносы в начале и конце
        block.content.replace(QRegularExpression("^\\n+"), "");
        block.content.replace(QRegularExpression("\\n+$"), "");
        block.isClosed = match.captured(0).endsWith("```");
        allBlocks.append(block);
    }

    // Сортируем блоки по позиции
    std::sort(allBlocks.begin(), allBlocks.end(),
              [](const Block &a, const Block &b) { return a.start < b.start; });

    // Собираем результат
    int currentIndex = 0;

    for (const Block &block : allBlocks) {
        // Добавляем текст перед блоком
        if (block.start > currentIndex) {
            QString textBefore = text.mid(currentIndex, block.start - currentIndex).trimmed();
            if (!textBefore.isEmpty()) {
                ContentBlock textBlock;
                textBlock.type = ContentType::Text;
                textBlock.content = textBefore;
                result.blocks.append(textBlock);
            }
        }

        // Добавляем сам блок
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

    // Добавляем оставшийся текст
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
