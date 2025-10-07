#include "modelinfo.h"
#include <QFileInfo>
#include <QDateTime>
#include <cmath>

ModelInfo::ModelInfo(QObject *parent)
    : QObject(parent)
    , m_ctx(nullptr)
{
    m_statsTimer = new QTimer(this);
    connect(m_statsTimer, &QTimer::timeout, this, &ModelInfo::updateCurrentStats);
    m_statsTimer->setInterval(1000);  // Обновление каждую секунду
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

    emit modelChanged();

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

        // Обновляем статистику
        if (m_ctx) {
            struct llama_perf_context_data perf = llama_perf_context(m_ctx);
            m_tokensIn = perf.n_p_eval;
            m_tokensOut = perf.n_eval;
        }

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
