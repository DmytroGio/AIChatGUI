#ifndef LLAMACONNECTOR_H
#define LLAMACONNECTOR_H

#include <QObject>
#include <QThread>
#include <llama.h>
#include "modelinfo.h"

class LlamaWorker : public QObject
{
    Q_OBJECT
public:
    explicit LlamaWorker(QObject *parent = nullptr);
    ~LlamaWorker();

    bool initialize(const QString &modelPath);
    llama_model *model = nullptr;
    llama_context *ctx = nullptr;

public slots:
    void processMessage(const QString &message);

signals:
    void messageReceived(const QString &response);
    void errorOccurred(const QString &error);
    void modelLoadedSuccessfully();
    void generationFinished(int tokens, double duration_ms);
    void generationStarted();

private:

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

    ModelInfo* getModelInfo() const { return modelInfo; }

signals:
    void messageReceived(const QString &response);
    void errorOccurred(const QString &error);

private:
    QThread workerThread;
    LlamaWorker *worker;

    ModelInfo *modelInfo;

signals:
    void requestProcessing(const QString &message);
};

#endif // LLAMACONNECTOR_H
