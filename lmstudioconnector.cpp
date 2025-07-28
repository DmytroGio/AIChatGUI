#include "lmstudioconnector.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QDebug>

LMStudioConnector::LMStudioConnector(QObject *parent)
    : QObject(parent)
{
    connect(&manager, &QNetworkAccessManager::finished,
            this, &LMStudioConnector::onReplyFinished);
}

void LMStudioConnector::sendMessage(const QString &message)
{
    QUrl url("http://localhost:1234/v1/chat/completions"); // LM Studio endpoint
    QNetworkRequest request(url);
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");

    // Пример JSON запроса к LM Studio
    QJsonObject json;
    json["model"] = "llama3"; // Название локальной модели
    QJsonArray messages;
    QJsonObject userMessage;
    userMessage["role"] = "user";
    userMessage["content"] = message;
    messages.append(userMessage);
    json["messages"] = messages;

    QJsonDocument doc(json);
    QByteArray data = doc.toJson();

    manager.post(request, data);
}

void LMStudioConnector::onReplyFinished(QNetworkReply *reply)
{
    if (reply->error() != QNetworkReply::NoError) {
        emit messageReceived("⚠️ Error: " + reply->errorString());
        reply->deleteLater();
        return;
    }

    QByteArray responseData = reply->readAll();
    QJsonDocument jsonDoc = QJsonDocument::fromJson(responseData);
    QString content;

    if (jsonDoc.isObject()) {
        QJsonObject root = jsonDoc.object();
        if (root.contains("choices")) {
            QJsonArray choices = root["choices"].toArray();
            if (!choices.isEmpty()) {
                QJsonObject message = choices[0].toObject()["message"].toObject();
                content = message["content"].toString();
            }
        }
    }

    emit messageReceived(content);
    reply->deleteLater();
}
