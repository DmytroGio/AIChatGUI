#ifndef LMSTUDIOCONNECTOR_H
#define LMSTUDIOCONNECTOR_H

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>

class LMStudioConnector : public QObject
{
    Q_OBJECT
public:
    explicit LMStudioConnector(QObject *parent = nullptr);

    Q_INVOKABLE void sendMessage(const QString &message);

signals:
    void messageReceived(const QString &response);

private:
    QNetworkAccessManager manager;
    void handleStreamingResponse(const QString &response);
    void handleRegularResponse(const QString &response);

private slots:
    void onReplyFinished(QNetworkReply *reply);
};

#endif // LMSTUDIOCONNECTOR_H
