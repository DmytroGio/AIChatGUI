#ifndef LLAMACONNECTOR_H
#define LLAMACONNECTOR_H

#include <QObject>
#include <QThread>
#include <llama.h>

class LlamaWorker : public QObject
{
    Q_OBJECT
public:
    explicit LlamaWorker(QObject *parent = nullptr);
    ~LlamaWorker();

    bool initialize(const QString &modelPath);

public slots:
    void processMessage(const QString &message);

signals:
    void messageReceived(const QString &response);
    void errorOccurred(const QString &error);

private:
    llama_model *model = nullptr;
    llama_context *ctx = nullptr;
    llama_sampler *sampler = nullptr;
    const llama_vocab *vocab = nullptr;
};

class LlamaConnector : public QObject
{
    Q_OBJECT
public:
    explicit LlamaConnector(QObject *parent = nullptr);
    ~LlamaConnector();

    Q_INVOKABLE void sendMessage(const QString &message);
    Q_INVOKABLE bool loadModel(const QString &modelPath);

signals:
    void messageReceived(const QString &response);
    void errorOccurred(const QString &error);

private:
    QThread workerThread;
    LlamaWorker *worker;

signals:
    void requestProcessing(const QString &message);
};

#endif // LLAMACONNECTOR_H
