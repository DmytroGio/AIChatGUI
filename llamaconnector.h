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
    void stopGeneration();

signals:
    void messageReceived(const QString &response);
    void errorOccurred(const QString &error);
    void modelLoadedSuccessfully();
    void generationFinished(int tokens, double duration_ms);
    void generationStarted();
    void tokenGenerated(const QString &token);
    void generationStopped();

private:

    llama_sampler *sampler = nullptr;
    const llama_vocab *vocab = nullptr;
    QAtomicInt m_shouldStop;
};

class LlamaConnector : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool isGenerating READ isGenerating NOTIFY generatingChanged)
public:
    explicit LlamaConnector(QObject *parent = nullptr);
    ~LlamaConnector();

    Q_INVOKABLE void sendMessage(const QString &message);
    Q_INVOKABLE bool loadModel(const QString &modelPath);

    ModelInfo* getModelInfo() const { return modelInfo; }

    Q_INVOKABLE void stopGeneration();  // НОВЫЙ МЕТОД
    bool isGenerating() const { return m_isGenerating; }

signals:
    void modelLoadingStarted();
    void modelLoadingFinished(bool success);
    void messageReceived(const QString &response);
    void errorOccurred(const QString &error);
    void tokenGenerated(const QString &token);
    void generationFinished(int tokens, double duration_ms);
    void generatingChanged();

private:
    QThread workerThread;
    LlamaWorker *worker;

    ModelInfo *modelInfo;
    bool m_isGenerating = false;

signals:
    void requestProcessing(const QString &message);
};

#endif // LLAMACONNECTOR_H
