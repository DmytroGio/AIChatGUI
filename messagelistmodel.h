#ifndef MESSAGELISTMODEL_H
#define MESSAGELISTMODEL_H

#include <QAbstractListModel>
#include <QSqlQuery>
#include <QSqlError>
#include <QDebug>
#include <QSqlDatabase>
#include "message.h"
#include <QElapsedTimer>

class MessageListModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)
    Q_PROPERTY(bool hasMoreMessages READ hasMoreMessages NOTIFY hasMoreMessagesChanged)

public:
    enum MessageRoles {
        TextRole = Qt::UserRole + 1,
        IsUserRole,
        TimestampRole,
        BlocksRole
    };

    explicit MessageListModel(QObject *parent = nullptr);

    // QAbstractListModel interface
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    // Data Management
    Q_INVOKABLE void loadMessages(const QString &chatId, int limit = 30);
    Q_INVOKABLE void loadOlderMessages(int count = 20);
    Q_INVOKABLE void appendMessage(const Message &msg);
    Q_INVOKABLE void updateLastMessage(const Message &msg);
    Q_INVOKABLE void clear();

    bool hasMoreMessages() const { return m_hasMoreMessages; }

    // C++ specific methods
    void setDatabase(QSqlDatabase *db);
    ParsedContent deserializeBlocks(const QString &json);

signals:
    void countChanged();
    void hasMoreMessagesChanged();

private:
    QList<Message> m_messages;
    QString m_currentChatId;
    int m_oldestLoadedId = INT_MAX;
    bool m_hasMoreMessages = true;
    QSqlDatabase *m_db = nullptr;
};

#endif // MESSAGELISTMODEL_H
