#include "modelinfo.h"
#include <QFileInfo>
#include <QDateTime>
#include <cmath>

#ifdef _WIN32
#include <windows.h>

// NVML function pointers
typedef int (*nvmlInit_t)();
typedef int (*nvmlShutdown_t)();
typedef int (*nvmlDeviceGetHandleByIndex_t)(unsigned int, void**);
typedef int (*nvmlDeviceGetName_t)(void*, char*, unsigned int);
typedef int (*nvmlDeviceGetTemperature_t)(void*, int, unsigned int*);
typedef int (*nvmlDeviceGetUtilizationRates_t)(void*, void*);
typedef int (*nvmlDeviceGetMemoryInfo_t)(void*, void*);
typedef int (*nvmlDeviceGetPowerUsage_t)(void*, unsigned int*);
typedef int (*nvmlDeviceGetClockInfo_t)(void*, int, unsigned int*);

struct nvmlUtilization_t {
    unsigned int gpu;
    unsigned int memory;
};

struct nvmlMemory_t {
    unsigned long long total;
    unsigned long long free;
    unsigned long long used;
};
#endif

// RequestLogModel implementation
RequestLogModel::RequestLogModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int RequestLogModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    return m_requests.count();
}

QVariant RequestLogModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_requests.count())
        return QVariant();

    const RequestEntry &entry = m_requests.at(index.row());

    switch (role) {
    case TimeRole:
        return entry.time;
    case TokensInRole:
        return entry.tokensIn;
    case TokensOutRole:
        return entry.tokensOut;
    case SpeedRole:
        return entry.speed;
    case DurationRole:
        return entry.duration;
    default:
        return QVariant();
    }
}

QHash<int, QByteArray> RequestLogModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[TimeRole] = "time";
    roles[TokensInRole] = "tokensIn";
    roles[TokensOutRole] = "tokensOut";
    roles[SpeedRole] = "speed";
    roles[DurationRole] = "duration";
    return roles;
}

void RequestLogModel::addRequest(const QString &time, int tokensIn, int tokensOut,
                                 float speed, double duration)
{
    beginInsertRows(QModelIndex(), 0, 0);
    m_requests.prepend({time, tokensIn, tokensOut, speed, duration});

    if (m_requests.count() > 100) {
        m_requests.removeLast();
    }

    endInsertRows();
}

void RequestLogModel::clear()
{
    beginResetModel();
    m_requests.clear();
    endResetModel();
}

ModelInfo::ModelInfo(QObject *parent)
    : QObject(parent)
    , m_ctx(nullptr)
    , m_lastTokensIn(0)
{
    m_requestLog = new RequestLogModel(this);
    m_statsTimer = new QTimer(this);
    connect(m_statsTimer, &QTimer::timeout, this, &ModelInfo::updateCurrentStats);
    m_statsTimer->setInterval(1000);  // Обновление каждую секунду

    // GPU monitoring setup (добавить в конец конструктора после m_statsTimer->setInterval(1000);)
    m_gpuTimer = new QTimer(this);
    connect(m_gpuTimer, &QTimer::timeout, this, &ModelInfo::updateGPUMetrics);
    m_gpuTimer->setInterval(500);
    m_gpuTimer->start();

#ifdef _WIN32
    // Initialize NVML
    m_nvmlLib = LoadLibraryA("nvml.dll");
    if (m_nvmlLib) {
        auto nvmlInit = (nvmlInit_t)GetProcAddress((HMODULE)m_nvmlLib, "nvmlInit_v2");
        auto nvmlDeviceGetHandleByIndex = (nvmlDeviceGetHandleByIndex_t)GetProcAddress((HMODULE)m_nvmlLib, "nvmlDeviceGetHandleByIndex_v2");
        auto nvmlDeviceGetName = (nvmlDeviceGetName_t)GetProcAddress((HMODULE)m_nvmlLib, "nvmlDeviceGetName");

        if (nvmlInit && nvmlDeviceGetHandleByIndex && nvmlDeviceGetName) {
            if (nvmlInit() == 0) {
                if (nvmlDeviceGetHandleByIndex(0, &m_nvmlDevice) == 0) {
                    char name[256] = {0};
                    if (nvmlDeviceGetName(m_nvmlDevice, name, sizeof(name)) == 0) {
                        m_gpuName = QString::fromLocal8Bit(name);
                        m_gpuAvailable = true;
                        m_gpuTimer->start();
                    }
                }
            }
        }
    }
#endif

    updateGPUMetrics();
}

void ModelInfo::setModel(llama_model *model, llama_context *ctx, const QString &path)
{
    if (!model || !ctx) return;

    m_ctx = ctx;
    m_isLoaded = true;
    m_modelPath = path;

    QFileInfo fileInfo(path);
    m_modelName = fileInfo.fileName();

    // Размер файла модели
    qint64 fileSize = fileInfo.size();
    m_modelSize = QString::number(fileSize / (1024.0 * 1024.0 * 1024.0), 'f', 1) + "GB";

    // Информация из модели
    m_layers = llama_model_n_layer(model);
    m_contextSize = QString::number(llama_model_n_ctx_train(model));

    uint64_t n_params = llama_model_n_params(model);
    if (n_params >= 1000000000) {
        m_parameters = QString::number(n_params / 1000000000.0, 'f', 1) + "B";
    } else if (n_params >= 1000000) {
        m_parameters = QString::number(n_params / 1000000.0, 'f', 1) + "M";
    }

    m_embedding = QString::number(llama_model_n_embd(model));

    const llama_vocab *vocab = llama_model_get_vocab(model);
    if (vocab) {
        m_vocabSize = QString::number(llama_vocab_n_tokens(vocab));
    }

    // Определяем тип квантизации из имени файла
    QString fileName = m_modelName.toLower();
    if (fileName.contains("q4_0")) m_quantization = "Q4_0";
    else if (fileName.contains("q4_1")) m_quantization = "Q4_1";
    else if (fileName.contains("q5_0")) m_quantization = "Q5_0";
    else if (fileName.contains("q5_1")) m_quantization = "Q5_1";
    else if (fileName.contains("q8_0")) m_quantization = "Q8_0";
    else if (fileName.contains("f16")) m_quantization = "F16";
    else if (fileName.contains("f32")) m_quantization = "F32";
    else m_quantization = "Unknown";

    // Определяем тип модели
    char model_desc[128];
    llama_model_desc(model, model_desc, sizeof(model_desc));
    m_modelType = QString::fromUtf8(model_desc);

    m_loadedTime = QDateTime::currentDateTime().toString("yyyy-MM-dd HH:mm:ss");

    m_threads = llama_n_threads(ctx);

    m_statsTimer->start();

    m_statsTimer->start();
    if (m_gpuTimer) {
        m_gpuTimer->start();
    }

    emit modelChanged();
}

void ModelInfo::clearModel()
{
    m_statsTimer->stop();
    m_ctx = nullptr;

    m_isLoaded = false;
    m_modelName = "No Model Loaded";
    m_modelSize = "0.0GB";
    m_contextSize = "-";
    m_modelType = "-";
    m_quantization = "-";
    m_parameters = "-";
    m_embedding = "-";
    m_vocabSize = "-";
    m_modelPath = "-";
    m_loadedTime = "-";
    m_layers = 0;

    m_speed = 0.0f;
    m_memoryUsed = 0.0f;
    m_memoryTotal = 0.0f;
    m_memoryPercent = 0;
    m_status = "Idle";
    m_tokensIn = 0;
    m_tokensOut = 0;

    emit modelChanged();

    if (m_gpuTimer) {
        m_gpuTimer->stop();
    }

#ifdef _WIN32
    if (m_nvmlLib) {
        auto nvmlShutdown = (nvmlShutdown_t)GetProcAddress((HMODULE)m_nvmlLib, "nvmlShutdown");
        if (nvmlShutdown) {
            nvmlShutdown();
        }
        FreeLibrary((HMODULE)m_nvmlLib);
        m_nvmlLib = nullptr;
        m_nvmlDevice = nullptr;
    }
#endif

    emit statsChanged();
}

void ModelInfo::updateStats(llama_context *ctx)
{
    if (!ctx) return;

    // Обновляем статистику производительности
    auto perf = llama_perf_context(ctx);

    if (perf.n_eval > 0) {
        m_speed = (perf.n_eval * 1000.0) / perf.t_eval_ms;
        emit speedDataPoint(m_speed);
    }

    m_tokensIn = perf.n_p_eval;
    m_tokensOut = perf.n_eval;

    // Примерная оценка памяти (можно улучшить)
    m_memoryTotal = 8.0f; // Примерное значение, нужно получать от системы
    m_memoryUsed = m_memoryTotal * 0.0f; // Требует доступа к внутренним данным llama.cpp
    m_memoryPercent = static_cast<int>((m_memoryUsed / m_memoryTotal) * 100);

    m_status = (perf.n_eval > 0) ? "Generating" : "Idle";

    emit statsChanged();
}

void ModelInfo::recordGeneration(int n_tokens, double duration_ms)
{
    if (duration_ms > 0 && n_tokens > 0) {
        float speed = (n_tokens * 1000.0) / duration_ms;
        m_speed = speed;
        emit speedDataPoint(speed);

        int currentTokensIn = 0;
        if (m_ctx) {
            struct llama_perf_context_data perf = llama_perf_context(m_ctx);
            m_tokensIn = perf.n_p_eval;
            m_tokensOut = perf.n_eval;
            currentTokensIn = perf.n_p_eval;
        }

        // Добавляем запись в лог
        QString currentTime = QDateTime::currentDateTime().toString("HH:mm:ss");
        int tokensInThisRequest = currentTokensIn - m_lastTokensIn;
        m_lastTokensIn = currentTokensIn;

        m_requestLog->addRequest(currentTime, tokensInThisRequest, n_tokens, speed, duration_ms);

        m_status = "Idle";
        emit statsChanged();
    }
}

void ModelInfo::setGenerating(bool generating)
{
    m_status = generating ? "Generating" : "Idle";
    emit statsChanged();
}

void ModelInfo::updateCurrentStats()
{
    if (!m_ctx || !m_isLoaded) return;

    // Получаем данные производительности
    struct llama_perf_context_data perf = llama_perf_context(m_ctx);

    // Обновляем статус на основе количества сгенерированных токенов
    bool isGenerating = (perf.n_eval > m_tokensOut);
    m_status = isGenerating ? "Generating" : "Idle";

    // Обновляем скорость если есть генерация
    if (perf.n_eval > 0 && perf.t_eval_ms > 0) {
        m_speed = (perf.n_eval * 1000.0) / perf.t_eval_ms;

        // Отправляем точку данных для графика только если генерируем
        if (isGenerating) {
            emit speedDataPoint(m_speed);
        }
    }

    // Обновляем счетчики токенов
    m_tokensIn = perf.n_p_eval;
    m_tokensOut = perf.n_eval;

    // Примерная оценка памяти (TODO: получить реальные данные)
    // Можно использовать системные вызовы или оставить как есть
    m_memoryTotal = 8.0f;
    m_memoryUsed = 2.5f; // Временное значение
    m_memoryPercent = static_cast<int>((m_memoryUsed / m_memoryTotal) * 100);

    emit statsChanged();
}

void ModelInfo::updateGPUMetrics()
{
#ifdef _WIN32
    if (!m_gpuAvailable || !m_nvmlDevice || !m_nvmlLib) {
        return;
    }

    auto nvmlDeviceGetTemperature = (nvmlDeviceGetTemperature_t)GetProcAddress((HMODULE)m_nvmlLib, "nvmlDeviceGetTemperature");
    auto nvmlDeviceGetUtilizationRates = (nvmlDeviceGetUtilizationRates_t)GetProcAddress((HMODULE)m_nvmlLib, "nvmlDeviceGetUtilizationRates");
    auto nvmlDeviceGetMemoryInfo = (nvmlDeviceGetMemoryInfo_t)GetProcAddress((HMODULE)m_nvmlLib, "nvmlDeviceGetMemoryInfo");
    auto nvmlDeviceGetPowerUsage = (nvmlDeviceGetPowerUsage_t)GetProcAddress((HMODULE)m_nvmlLib, "nvmlDeviceGetPowerUsage");
    auto nvmlDeviceGetClockInfo = (nvmlDeviceGetClockInfo_t)GetProcAddress((HMODULE)m_nvmlLib, "nvmlDeviceGetClockInfo");

    // Temperature
    if (nvmlDeviceGetTemperature) {
        unsigned int temp = 0;
        if (nvmlDeviceGetTemperature(m_nvmlDevice, 0, &temp) == 0) {
            m_gpuTemp = static_cast<int>(temp);
        }
    }

    // Utilization
    if (nvmlDeviceGetUtilizationRates) {
        nvmlUtilization_t util;
        if (nvmlDeviceGetUtilizationRates(m_nvmlDevice, &util) == 0) {
            m_gpuUtil = static_cast<int>(util.gpu);
        }
    }

    // Memory
    if (nvmlDeviceGetMemoryInfo) {
        nvmlMemory_t mem;
        if (nvmlDeviceGetMemoryInfo(m_nvmlDevice, &mem) == 0) {
            m_gpuMemUsed = static_cast<int>(mem.used / (1024 * 1024)); // MB
            m_gpuMemTotal = static_cast<int>(mem.total / (1024 * 1024)); // MB
        }
    }

    // Power
    if (nvmlDeviceGetPowerUsage) {
        unsigned int power = 0;
        if (nvmlDeviceGetPowerUsage(m_nvmlDevice, &power) == 0) {
            m_gpuPower = static_cast<int>(power / 1000); // Convert mW to W
        }
    }

    // Clock speed
    if (nvmlDeviceGetClockInfo) {
        unsigned int clock = 0;
        if (nvmlDeviceGetClockInfo(m_nvmlDevice, 0, &clock) == 0) { // 0 = Graphics clock
            m_gpuClock = static_cast<int>(clock);
        }
    }

    emit gpuMetricsChanged();
#endif
}
