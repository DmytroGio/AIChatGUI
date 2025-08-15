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

// В функции onReplyFinished замените обработку ответа на это:

void LMStudioConnector::onReplyFinished(QNetworkReply *reply)
{
    if (reply->error() != QNetworkReply::NoError) {
        qDebug() << "Network error:" << reply->errorString();
        emit messageReceived("Error: " + reply->errorString());
        reply->deleteLater();
        return;
    }

    QByteArray data = reply->readAll();
    QString response = QString::fromUtf8(data);

    // Логируем сырой ответ для отладки
    qDebug() << "Raw response:" << response;

    // Проверяем, является ли ответ streaming (начинается с "data: ")
    if (response.startsWith("data: ")) {
        handleStreamingResponse(response);
    } else {
        handleRegularResponse(response);
    }

    reply->deleteLater();
}

// Добавьте эти новые функции в класс:

void LMStudioConnector::handleStreamingResponse(const QString &response)
{
    QString fullMessage = "";
    QStringList lines = response.split("\n");

    for (const QString &line : lines) {
        if (line.startsWith("data: ")) {
            QString jsonStr = line.mid(6); // Убираем "data: "

            if (jsonStr.trimmed() == "[DONE]") {
                break;
            }

            QJsonParseError error;
            QJsonDocument doc = QJsonDocument::fromJson(jsonStr.toUtf8(), &error);

            if (error.error != QJsonParseError::NoError) {
                qDebug() << "JSON parse error in streaming:" << error.errorString();
                continue;
            }

            QJsonObject obj = doc.object();
            if (obj.contains("choices")) {
                QJsonArray choices = obj["choices"].toArray();
                if (!choices.isEmpty()) {
                    QJsonObject choice = choices[0].toObject();
                    if (choice.contains("delta")) {
                        QJsonObject delta = choice["delta"].toObject();
                        if (delta.contains("content")) {
                            fullMessage += delta["content"].toString();
                        }
                    }
                }
            }
        }
    }

    if (!fullMessage.isEmpty()) {
        emit messageReceived(fullMessage);
    }
}

void LMStudioConnector::handleRegularResponse(const QString &response)
{
    QJsonParseError error;
    QJsonDocument doc = QJsonDocument::fromJson(response.toUtf8(), &error);

    if (error.error != QJsonParseError::NoError) {
        qDebug() << "JSON parse error:" << error.errorString();
        qDebug() << "Response was:" << response;
        emit messageReceived("JSON Parse Error: " + error.errorString());
        return;
    }

    QJsonObject obj = doc.object();

    // Проверяем наличие ошибки
    if (obj.contains("error")) {
        QJsonObject errorObj = obj["error"].toObject();
        QString errorMsg = errorObj["message"].toString();
        emit messageReceived("API Error: " + errorMsg);
        return;
    }

    // Извлекаем сообщение
    if (obj.contains("choices")) {
        QJsonArray choices = obj["choices"].toArray();
        if (!choices.isEmpty()) {
            QJsonObject choice = choices[0].toObject();
            if (choice.contains("message")) {
                QJsonObject message = choice["message"].toObject();
                QString content = message["content"].toString();
                emit messageReceived(content);
            } else if (choice.contains("text")) {
                // Для completion API
                QString content = choice["text"].toString();
                emit messageReceived(content);
            }
        }
    } else {
        qDebug() << "Unexpected response format:" << response;
        emit messageReceived("Unexpected response format");
    }
}
