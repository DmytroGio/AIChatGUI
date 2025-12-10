#ifndef MODELINFO_H
#define MODELINFO_H

#include <QObject>
#include <QString>
#include <QTimer>
#include <llama.h>
#include <QAbstractListModel>

#ifdef _WIN32
#include <comdef.h>
#include <Wbemidl.h>
#pragma comment(lib, "wbemuuid.lib")
#endif

// Model for logging queries
class RequestLogModel : public QAbstractListModel
{
    Q_OBJECT

public:
    enum RequestRoles {
        TimeRole = Qt::UserRole + 1,
        TokensInRole,
        TokensOutRole,
        SpeedRole,
        DurationRole
    };

    explicit RequestLogModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    Q_INVOKABLE void addRequest(const QString &time, int tokensIn, int tokensOut,
                                float speed, double duration);
    Q_INVOKABLE void clear();

private:
    struct RequestEntry {
        QString time;
        int tokensIn;
        int tokensOut;
        float speed;
        double duration;
    };

    QList<RequestEntry> m_requests;
};

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
    Q_PROPERTY(QObject* requestLog READ requestLog CONSTANT)

    // GPU Properties
    Q_PROPERTY(bool gpuAvailable READ gpuAvailable NOTIFY gpuMetricsChanged)
    Q_PROPERTY(QString gpuName READ gpuName NOTIFY gpuMetricsChanged)
    Q_PROPERTY(int gpuTemp READ gpuTemp NOTIFY gpuMetricsChanged)
    Q_PROPERTY(int gpuUtil READ gpuUtil NOTIFY gpuMetricsChanged)
    Q_PROPERTY(int gpuMemUsed READ gpuMemUsed NOTIFY gpuMetricsChanged)
    Q_PROPERTY(int gpuMemTotal READ gpuMemTotal NOTIFY gpuMetricsChanged)
    Q_PROPERTY(int gpuPower READ gpuPower NOTIFY gpuMetricsChanged)
    Q_PROPERTY(int gpuClock READ gpuClock NOTIFY gpuMetricsChanged)

    // CPU
    Q_PROPERTY(QString cpuName READ cpuName NOTIFY cpuMetricsChanged)
    Q_PROPERTY(int cpuTemp READ cpuTemp NOTIFY cpuMetricsChanged)
    Q_PROPERTY(int cpuUsage READ cpuUsage NOTIFY cpuMetricsChanged)
    Q_PROPERTY(int cpuClock READ cpuClock NOTIFY cpuMetricsChanged)
    // RAM
    Q_PROPERTY(float modelMemoryUsed READ modelMemoryUsed NOTIFY statsChanged)

    // Model list properties
    Q_PROPERTY(QString modelsFolder READ modelsFolder WRITE setModelsFolder NOTIFY modelsFolderChanged)
    Q_PROPERTY(QVariantList availableModels READ availableModels NOTIFY availableModelsChanged)
    Q_PROPERTY(QString autoLoadModelPath READ autoLoadModelPath WRITE setAutoLoadModelPath NOTIFY autoLoadModelPathChanged)

public:
    explicit ModelInfo(QObject *parent = nullptr);
    ~ModelInfo();

    void setModel(llama_model *model, llama_context *ctx, const QString &path);
    void clearModel();
    void updateStats(llama_context *ctx);
    void recordGeneration(int n_tokens, double duration_ms);
    void setGenerating(bool generating);

    QObject* requestLog() const { return m_requestLog; }

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

    // GPU getters
    bool gpuAvailable() const { return m_gpuAvailable; }
    QString gpuName() const { return m_gpuName; }
    int gpuTemp() const { return m_gpuTemp; }
    int gpuUtil() const { return m_gpuUtil; }
    int gpuMemUsed() const { return m_gpuMemUsed; }
    int gpuMemTotal() const { return m_gpuMemTotal; }
    int gpuPower() const { return m_gpuPower; }
    int gpuClock() const { return m_gpuClock; }

    // CPU getters
    QString cpuName() const { return m_cpuName; }
    int cpuTemp() const { return m_cpuTemp; }
    int cpuUsage() const { return m_cpuUsage; }
    int cpuClock() const { return m_cpuClock; }

    // RAM getters
    float modelMemoryUsed() const { return m_modelMemoryUsed; }

    // Model list
    QString modelsFolder() const { return m_modelsFolder; }
    void setModelsFolder(const QString &folder);
    QVariantList availableModels() const { return m_availableModels; }
    QString autoLoadModelPath() const { return m_autoLoadModelPath; }
    void setAutoLoadModelPath(const QString &path);

    Q_INVOKABLE void scanModelsFolder();
    Q_INVOKABLE void saveSettings();
    Q_INVOKABLE void loadSettings();

signals:
    void modelChanged();
    void statsChanged();
    void speedDataPoint(float speed);
    void gpuMetricsChanged();
    void cpuMetricsChanged();
    void modelsFolderChanged();
    void availableModelsChanged();
    void autoLoadModelPathChanged();

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

    RequestLogModel *m_requestLog;


    int m_lastTokensIn = 0;

    void updateGPUMetrics();
    // GPU monitoring
    bool m_gpuAvailable = false;
    QString m_gpuName = "N/A";
    int m_gpuTemp = 0;
    int m_gpuUtil = 0;
    int m_gpuMemUsed = 0;
    int m_gpuMemTotal = 0;
    int m_gpuPower = 0;
    int m_gpuClock = 0;
    QTimer *m_gpuTimer = nullptr;

    #ifdef _WIN32
    void* m_nvmlDevice = nullptr;
    void* m_nvmlLib = nullptr;
    #endif

    // CPU monitoring
    QString m_cpuName = "N/A";
    int m_cpuTemp = 0;
    int m_cpuUsage = 0;
    int m_cpuClock = 0; // MHz

    void updateCPUMetrics();
    int m_cpuBaseFreq = 0;  // MHz
    int m_cpuCurrentFreq = 0;  // MHz

    float m_modelMemoryUsed = 0.0f;

    // Model list
    QString m_modelsFolder;
    QVariantList m_availableModels;
    QString m_autoLoadModelPath;

    struct ModelFileInfo {
        QString fileName;
        QString fullPath;
        qint64 sizeBytes;
        QString sizeString;
        QString parameters; // Extracted from file name
    };

    ModelFileInfo parseModelFile(const QString &filePath);
};

#endif // MODELINFO_H
