#ifndef MODELINFO_H
#define MODELINFO_H

#include <QObject>
#include <QString>
#include <QTimer>
#include <llama.h>

class ModelInfo : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool isLoaded READ isLoaded NOTIFY modelChanged)
    Q_PROPERTY(QString modelName READ modelName NOTIFY modelChanged)
    Q_PROPERTY(QString modelSize READ modelSize NOTIFY modelChanged)
    Q_PROPERTY(QString contextSize READ contextSize NOTIFY modelChanged)
    Q_PROPERTY(QString modelType READ modelType NOTIFY modelChanged)
    Q_PROPERTY(QString quantization READ quantization NOTIFY modelChanged)
    Q_PROPERTY(QString parameters READ parameters NOTIFY modelChanged)
    Q_PROPERTY(QString embedding READ embedding NOTIFY modelChanged)
    Q_PROPERTY(QString vocabSize READ vocabSize NOTIFY modelChanged)
    Q_PROPERTY(QString modelPath READ modelPath NOTIFY modelChanged)
    Q_PROPERTY(QString loadedTime READ loadedTime NOTIFY modelChanged)
    Q_PROPERTY(int layers READ layers NOTIFY modelChanged)

    // Runtime stats
    Q_PROPERTY(float speed READ speed NOTIFY statsChanged)
    Q_PROPERTY(float memoryUsed READ memoryUsed NOTIFY statsChanged)
    Q_PROPERTY(float memoryTotal READ memoryTotal NOTIFY statsChanged)
    Q_PROPERTY(int memoryPercent READ memoryPercent NOTIFY statsChanged)
    Q_PROPERTY(int threads READ threads NOTIFY statsChanged)
    Q_PROPERTY(QString status READ status NOTIFY statsChanged)
    Q_PROPERTY(int tokensIn READ tokensIn NOTIFY statsChanged)
    Q_PROPERTY(int tokensOut READ tokensOut NOTIFY statsChanged)

public:
    explicit ModelInfo(QObject *parent = nullptr);

    void setModel(llama_model *model, llama_context *ctx, const QString &path);
    void clearModel();
    void updateStats(llama_context *ctx);
    void recordGeneration(int n_tokens, double duration_ms);
    void setGenerating(bool generating);

    // Getters
    bool isLoaded() const { return m_isLoaded; }
    QString modelName() const { return m_modelName; }
    QString modelSize() const { return m_modelSize; }
    QString contextSize() const { return m_contextSize; }
    QString modelType() const { return m_modelType; }
    QString quantization() const { return m_quantization; }
    QString parameters() const { return m_parameters; }
    QString embedding() const { return m_embedding; }
    QString vocabSize() const { return m_vocabSize; }
    QString modelPath() const { return m_modelPath; }
    QString loadedTime() const { return m_loadedTime; }
    int layers() const { return m_layers; }

    float speed() const { return m_speed; }
    float memoryUsed() const { return m_memoryUsed; }
    float memoryTotal() const { return m_memoryTotal; }
    int memoryPercent() const { return m_memoryPercent; }
    int threads() const { return m_threads; }
    QString status() const { return m_status; }
    int tokensIn() const { return m_tokensIn; }
    int tokensOut() const { return m_tokensOut; }

signals:
    void modelChanged();
    void statsChanged();
    void speedDataPoint(float speed);

public slots:
    void updateCurrentStats();

private:
    bool m_isLoaded = false;
    QString m_modelName;
    QString m_modelSize;
    QString m_contextSize;
    QString m_modelType;
    QString m_quantization;
    QString m_parameters;
    QString m_embedding;
    QString m_vocabSize;
    QString m_modelPath;
    QString m_loadedTime;
    int m_layers = 0;

    float m_speed = 0.0f;
    float m_memoryUsed = 0.0f;
    float m_memoryTotal = 0.0f;
    int m_memoryPercent = 0;
    int m_threads = 0;
    QString m_status = "Idle";
    int m_tokensIn = 0;
    int m_tokensOut = 0;

    QTimer *m_statsTimer;
    llama_context *m_ctx = nullptr;
};

#endif // MODELINFO_H
