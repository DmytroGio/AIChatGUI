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
    QUrl url("http://127.0.0.1:1234/v1/chat/completions"); // LM Studio endpoint
    QNetworkRequest request(url);
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    request.setRawHeader("User-Agent", "AIChatGUI/1.0");
    request.setRawHeader("Accept", "application/json");

    // Пример JSON запроса к LM Studio
    QJsonObject json;
    json["model"] = "qwen2.5-coder-3b-instruct"; // Название локальной модели
    QJsonArray messages;
    QJsonObject userMessage;
    userMessage["role"] = "user";
    userMessage["content"] = message;
    messages.append(userMessage);
    json["messages"] = messages;
    json["temperature"] = 0.7;
    json["max_tokens"] = 2048;
    json["stream"] = false;

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

    // ДОБАВИТЬ: Диагностика размера ответа
    qDebug() << "Response size:" << responseData.size() << "bytes";

    QJsonDocument jsonDoc = QJsonDocument::fromJson(responseData);
    QString content;

    if (jsonDoc.isObject()) {
        QJsonObject root = jsonDoc.object();
        if (root.contains("choices")) {
            QJsonArray choices = root["choices"].toArray();
            if (!choices.isEmpty()) {
                QJsonObject message = choices[0].toObject()["message"].toObject();
                content = message["content"].toString();

                // Обработка экранированных символов
                content = content.replace("\\n", "\n");
                content = content.replace("\\\"", "\"");
                content = content.replace("\\\\", "\\");
                content = content.replace("\\t", "\t");

                qDebug() << "Content length:" << content.length() << "characters";
            }
        }
    }

    // ДОБАВИТЬ: Проверка на пустой контент
    if (content.isEmpty()) {
        qDebug() << "Empty content received!";
        qDebug() << "Full response:" << responseData;
        content = "⚠️ Empty response received";
    }

    emit messageReceived(content);
    reply->deleteLater();
}
