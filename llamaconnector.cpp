#include "llamaconnector.h"
#include <QDebug>
#include <QFile>
#include <chrono>
#include <QCoreApplication>

LlamaWorker::LlamaWorker(QObject *parent)
    : QObject(parent), m_shouldStop(0)
{
#ifdef _WIN32
    _putenv("GGML_CUDA_FORCE_CUBLAS=1");
    _putenv("GGML_CUDA_NO_PEER_COPY=1");
    // ✅ НОВЫЕ оптимизации:
    _putenv("GGML_CUDA_FORCE_MMQ=1");        // Матричное умножение на GPU
    _putenv("GGML_CUDA_F16=1");              // FP16 для ускорения
    _putenv("CUDA_LAUNCH_BLOCKING=0");       // ❌ УБЕРИ блокировку!
#else
    setenv("GGML_CUDA_FORCE_CUBLAS", "1", 1);
    setenv("GGML_CUDA_NO_PEER_COPY", "1", 1);
    setenv("GGML_CUDA_FORCE_MMQ", "1", 1);
    setenv("GGML_CUDA_F16", "1", 1);
#endif

    llama_backend_init();

    // ДОБАВИТЬ:
    qDebug() << "=== llama.cpp system info ===";
    qDebug() << llama_print_system_info();

    // ДОБАВИТЬ эти проверки:
    qDebug() << "=== GPU Support Check ===";
    qDebug() << "GPU offload supported:" << llama_supports_gpu_offload();
    qDebug() << "MMAP supported:" << llama_supports_mmap();
    qDebug() << "MLOCK supported:" << llama_supports_mlock();
}

LlamaWorker::~LlamaWorker()
{
    if (sampler) llama_sampler_free(sampler);
    if (ctx) llama_free(ctx);
    if (model) llama_model_free(model);  // было llama_free_model
    llama_backend_free();
}

void LlamaWorker::unloadModel()
{
    qDebug() << "=== LlamaWorker::unloadModel ===";

    if (sampler) {
        llama_sampler_free(sampler);
        sampler = nullptr;
    }
    if (ctx) {
        llama_free(ctx);
        ctx = nullptr;
    }
    if (model) {
        llama_model_free(model);
        model = nullptr;
    }

    vocab = nullptr;
    m_n_past = 0;
    m_session_tokens.clear();

    qDebug() << "Model unloaded successfully";
}

bool LlamaWorker::initialize(const QString &modelPath)
{
    // Очищаем предыдущие ресурсы если есть
    if (sampler) {
        llama_sampler_free(sampler);
        sampler = nullptr;
    }
    if (ctx) {
        llama_free(ctx);
        ctx = nullptr;
    }
    if (model) {
        llama_model_free(model);
        model = nullptr;
    }

    if (!QFile::exists(modelPath)) {
        emit errorOccurred("Model file not found: " + modelPath);
        return false;
    }

    llama_model_params model_params = llama_model_default_params();

    qDebug() << "=== Model Loading Configuration ===";
    qDebug() << "GPU offload support:" << llama_supports_gpu_offload();

    if (llama_supports_gpu_offload()) {
        model_params.n_gpu_layers = 999;  // Все слои на GPU
        model_params.main_gpu = 0;
        model_params.split_mode = LLAMA_SPLIT_MODE_NONE;
        qDebug() << "GPU offload ENABLED, requesting" << model_params.n_gpu_layers << "layers";
    } else {
        qDebug() << "WARNING: GPU offload NOT supported!";
        model_params.n_gpu_layers = 0;
    }

    model_params.use_mmap = true;
    model_params.use_mlock = false;

    qDebug() << "Loading model from:" << modelPath;
    model = llama_model_load_from_file(modelPath.toUtf8().constData(), model_params);

    if (!model) {
        emit errorOccurred("Failed to load model");
        return false;
    }

    // ДОБАВИТЬ:
    qDebug() << "=== Model Loaded ===";
    qDebug() << "Requested GPU layers:" << model_params.n_gpu_layers;
    qDebug() << "Model total layers:" << llama_model_n_layer(model);
    qDebug() << "Model size:" << (llama_model_size(model) / (1024.0 * 1024.0 * 1024.0)) << "GB";

    vocab = llama_model_get_vocab(model);

    if (!vocab) {
        emit errorOccurred("Failed to get vocabulary");
        llama_model_free(model);
        model = nullptr;
        return false;
    }

    llama_context_params ctx_params = llama_context_default_params();
    ctx_params.n_ctx = 4096;
    ctx_params.n_batch = 8192;      // ✅ УВЕЛИЧЕНО: Было 2048
    ctx_params.n_ubatch = 2048;     // ✅ УВЕЛИЧЕНО: Было 512
    ctx_params.n_threads = 8;       // ✅ Оптимально для большинства CPU
    ctx_params.n_threads_batch = 8;

    // ВСЕГДА включаем GPU параметры
    // ДОБАВИТЬ эти строки:
    ctx_params.offload_kqv = true;  // Offload KV cache на GPU
    ctx_params.flash_attn_type = LLAMA_FLASH_ATTN_TYPE_ENABLED;  // Flash Attention

    // ✅ НОВОЕ: Включаем continuous batching для RTX GPU
    ctx_params.rope_scaling_type = LLAMA_ROPE_SCALING_TYPE_LINEAR;
    ctx_params.yarn_ext_factor = -1.0f;
    ctx_params.yarn_attn_factor = 1.0f;
    ctx_params.yarn_beta_fast = 32.0f;
    ctx_params.yarn_beta_slow = 1.0f;

    qDebug() << "=== Context Configuration ===";
    qDebug() << "Context size:" << ctx_params.n_ctx;
    qDebug() << "KQV offload:" << ctx_params.offload_kqv;
    qDebug() << "Flash attention:" << (ctx_params.flash_attn_type == LLAMA_FLASH_ATTN_TYPE_ENABLED ? "enabled" : "disabled");

    ctx = llama_init_from_model(model, ctx_params);

    if (!ctx) {
        emit errorOccurred("Failed to create context");
        llama_model_free(model);
        model = nullptr;
        vocab = nullptr;
        return false;
    }

    sampler = llama_sampler_chain_init(llama_sampler_chain_default_params());
    llama_sampler_chain_add(sampler, llama_sampler_init_temp(0.7f));
    llama_sampler_chain_add(sampler, llama_sampler_init_top_p(0.9f, 1));
    llama_sampler_chain_add(sampler, llama_sampler_init_dist(LLAMA_DEFAULT_SEED));

    qDebug() << "Model loaded successfully!";
    qDebug() << "GPU layers offloaded:" << model_params.n_gpu_layers;
    qDebug() << "Model total layers:" << llama_model_n_layer(model);

    m_n_past = 0;
    m_session_tokens.clear();

    emit modelLoadedSuccessfully();

    return true;
}

void LlamaWorker::processMessage(const QString &message)
{
    qDebug() << "=== processMessage START ===";

    if (!model || !ctx || !vocab) {
        qDebug() << "ERROR: Model not loaded";
        emit errorOccurred("Model not loaded");
        return;
    }

    m_shouldStop.storeRelaxed(0);
    auto start_time = std::chrono::high_resolution_clock::now();

    // Формируем prompt только для нового сообщения
    QString prompt;
    if (m_n_past == 0) {
        // Первое сообщение - добавляем системный промпт
        prompt = "<|im_start|>system\nYou are a helpful assistant.<|im_end|>\n"
                 "<|im_start|>user\n" + message + "<|im_end|>\n"
                             "<|im_start|>assistant\n";
    } else {
        // Последующие сообщения - только новый user message
        prompt = "<|im_start|>user\n" + message + "<|im_end|>\n"
                                                  "<|im_start|>assistant\n";
    }

    std::string prompt_str = prompt.toStdString();
    qDebug() << "Prompt length:" << prompt_str.length();
    qDebug() << "Tokens in context (n_past):" << m_n_past;

    // Токенизация нового промпта
    std::vector<llama_token> tokens(prompt_str.size() + 128);
    int n_tokens = llama_tokenize(
        vocab,
        prompt_str.c_str(),
        prompt_str.length(),
        tokens.data(),
        tokens.size(),
        m_n_past == 0,  // add_special только для первого сообщения
        true
        );

    if (n_tokens < 0) {
        qDebug() << "Resizing tokens buffer to" << -n_tokens;
        tokens.resize(-n_tokens);
        n_tokens = llama_tokenize(vocab, prompt_str.c_str(), prompt_str.length(),
                                  tokens.data(), tokens.size(), m_n_past == 0, true);
    }

    if (n_tokens <= 0) {
        qDebug() << "ERROR: Tokenization failed, n_tokens =" << n_tokens;
        emit errorOccurred("Failed to tokenize");
        return;
    }

    tokens.resize(n_tokens);
    qDebug() << "Tokenized successfully, n_tokens:" << n_tokens;

    // Добавляем новые токены в историю сессии
    m_session_tokens.insert(m_session_tokens.end(), tokens.begin(), tokens.end());

    // Создаём batch ОДИН РАЗ для всего промпта
    llama_batch batch = llama_batch_init(n_tokens, 0, 1);

    for (int i = 0; i < n_tokens; i++) {
        batch.token[i] = tokens[i];
        batch.pos[i] = m_n_past + i;
        batch.n_seq_id[i] = 1;
        batch.seq_id[i][0] = 0;
        batch.logits[i] = (i == n_tokens - 1) ? 1 : 0;
    }
    batch.n_tokens = n_tokens;

    qDebug() << "Decoding prompt...";
    int decode_result = llama_decode(ctx, batch);
    qDebug() << "Decode result:" << decode_result;

    llama_batch_free(batch);

    if (decode_result != 0) {
        qDebug() << "ERROR: Failed to decode prompt, code:" << decode_result;
        emit errorOccurred("Failed to decode prompt, code: " + QString::number(decode_result));
        return;
    }

    // Обновляем позицию в контексте
    m_n_past += n_tokens;
    qDebug() << "Prompt decoded successfully, n_past now:" << m_n_past;
    emit generationStarted();

    QString response;
    int n_gen = 0;
    const int max_gen_tokens = 512;

    // ✅ НОВОЕ: Буфер для накопления токенов
    QString tokenBuffer;
    int tokensInBuffer = 0;
    const int EMIT_BATCH_SIZE = 5; // Отправляем по 5 токенов за раз

    // ✅ НОВОЕ: Используем std::string вместо QString для скорости
    std::string responseStr;
    responseStr.reserve(4096); // Предаллокация памяти

    llama_batch gen_batch = llama_batch_init(1, 0, 1);
    gen_batch.n_seq_id[0] = 1;
    gen_batch.seq_id[0][0] = 0;
    gen_batch.logits[0] = 1;
    gen_batch.n_tokens = 1;

    std::vector<llama_token> response_tokens;
    response_tokens.reserve(max_gen_tokens); // ✅ Предаллокация

    while (n_gen < max_gen_tokens) {
        if (m_shouldStop.loadRelaxed() == 1) {
            // Отправляем остаток буфера
            if (!tokenBuffer.isEmpty()) {
                emit tokenGenerated(tokenBuffer);
            }

            response = QString::fromStdString(responseStr);
            response = response.remove("<|im_end|>").trimmed();
            m_session_tokens.insert(m_session_tokens.end(),
                                    response_tokens.begin(),
                                    response_tokens.end());
            m_n_past += n_gen;

            auto end_time = std::chrono::high_resolution_clock::now();
            auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(
                end_time - start_time);

            llama_batch_free(gen_batch);
            emit generationStopped();
            emit generationFinished(n_gen, duration.count());
            emit messageReceived(response.isEmpty() ? "Generation stopped" : response);
            return;
        }

        llama_token new_token = llama_sampler_sample(sampler, ctx, -1);

        if (new_token < 0 || llama_vocab_is_eog(vocab, new_token)) {
            break;
        }

        response_tokens.push_back(new_token);

        // ✅ ОПТИМИЗАЦИЯ: Работаем с буфером напрямую
        char piece[128];
        int n_chars = llama_token_to_piece(vocab, new_token, piece,
                                           sizeof(piece), 0, true);

        if (n_chars > 0) {
            responseStr.append(piece, n_chars);

            // ✅ ИСПРАВЛЕНИЕ: Проверяем валидность UTF-8 перед добавлением
            QByteArray byteArray(piece, n_chars);
            QString decoded = QString::fromUtf8(byteArray);

            // Если декодирование успешно (нет замен на �)
            if (!decoded.contains(QChar(0xFFFD))) {
                tokenBuffer += decoded;
                tokensInBuffer++;
            } else {
                // Emoji разбит на части - накапливаем байты
                static QByteArray incompleteUtf8;
                incompleteUtf8.append(byteArray);

                // Пробуем декодировать накопленное
                QString fullDecoded = QString::fromUtf8(incompleteUtf8);
                if (!fullDecoded.contains(QChar(0xFFFD))) {
                    tokenBuffer += fullDecoded;
                    tokensInBuffer++;
                    incompleteUtf8.clear();
                }
                // Иначе продолжаем накапливать
            }

            if (tokensInBuffer >= EMIT_BATCH_SIZE) {
                emit tokenGenerated(tokenBuffer);
                tokenBuffer.clear();
                tokensInBuffer = 0;
            }
        }

        // Decode
        gen_batch.token[0] = new_token;
        gen_batch.pos[0] = m_n_past + n_gen;

        int result = llama_decode(ctx, gen_batch);

        if (result != 0) {
            qDebug() << "Decode failed at token" << n_gen << "with code" << result;
            break;
        }

        n_gen++;
    }

    // ✅ Отправляем остаток буфера
    if (!tokenBuffer.isEmpty()) {
        emit tokenGenerated(tokenBuffer);
    }

    llama_batch_free(gen_batch);

    m_session_tokens.insert(m_session_tokens.end(),
                            response_tokens.begin(),
                            response_tokens.end());
    m_n_past += n_gen;

    response = QString::fromStdString(responseStr);
    response = response.remove("<|im_end|>").trimmed();

    if (response.isEmpty()) {
        qDebug() << "WARNING: Empty response";
        response = "Error: No response generated";
    }

    auto end_time = std::chrono::high_resolution_clock::now();
    auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(
        end_time - start_time);

    qDebug() << "Response length:" << response.length();
    qDebug() << "Total tokens in context:" << m_n_past;
    emit generationFinished(n_gen, duration.count());
    emit messageReceived(response);
    qDebug() << "=== processMessage FINISHED ===";
}

void LlamaWorker::stopGeneration()
{
    m_shouldStop.storeRelaxed(1);
}

// ДОБАВИТЬ ПОСЛЕ stopGeneration():
void LlamaWorker::clearContext()
{
    if (ctx) {
        llama_memory_t memory = llama_get_memory(ctx);
        llama_memory_clear(memory, false);
        m_n_past = 0;
        m_session_tokens.clear();
        qDebug() << "Context cleared manually";
    }
}

// LlamaConnector implementation

LlamaConnector::LlamaConnector(QObject *parent)
    : QObject(parent)
{
    modelInfo = new ModelInfo(this);

    worker = new LlamaWorker();
    worker->moveToThread(&workerThread);

    connect(&workerThread, &QThread::finished, worker, &QObject::deleteLater);
    connect(this, &LlamaConnector::requestProcessing, worker, &LlamaWorker::processMessage);
    connect(worker, &LlamaWorker::errorOccurred, this, &LlamaConnector::errorOccurred);
    connect(worker, &LlamaWorker::tokenGenerated, this, &LlamaConnector::tokenGenerated);

    connect(worker, &LlamaWorker::messageReceived, this, [this](const QString& response) {
        m_lastRawResponse = response;
        emit messageReceived(response);
    });

    connect(worker, &LlamaWorker::generationStarted, this, [this]() {
        modelInfo->setGenerating(true);
        m_isGenerating = true;
        emit generatingChanged();
    });

    connect(worker, &LlamaWorker::generationFinished, this, [this](int tokens, double duration_ms) {
        modelInfo->recordGeneration(tokens, duration_ms);
        m_isGenerating = false;
        emit generatingChanged();
        emit generationFinished(tokens, duration_ms);
    });

    connect(worker, &LlamaWorker::generationStopped, this, [this]() {
        m_isGenerating = false;
        emit generatingChanged();
    });

    workerThread.start();
}

LlamaConnector::~LlamaConnector()
{
    workerThread.quit();
    workerThread.wait();
}

void LlamaConnector::unloadModel()
{
    qDebug() << "=== unloadModel called ===";

    if (m_isGenerating) {
        qDebug() << "Stopping generation before unloading...";
        worker->stopGeneration();

        int waitCount = 0;
        while (m_isGenerating && waitCount < 50) {
            QThread::msleep(100);
            QCoreApplication::processEvents();
            waitCount++;
        }
    }

    // Вызываем метод worker через Qt signal/slot систему для потокобезопасности
    QMetaObject::invokeMethod(worker, &LlamaWorker::unloadModel, Qt::BlockingQueuedConnection);

    modelInfo->clearModel();

    qDebug() << "Model unloaded successfully";
}

void LlamaConnector::stopGeneration()
{
    if (worker) {
        worker->stopGeneration();
    }
}

bool LlamaConnector::loadModel(const QString &modelPath)
{
    qDebug() << "=== loadModel called with:" << modelPath;
    emit modelLoadingStarted();

    // КРИТИЧНО: Правильная очистка ресурсов
    if (m_isGenerating) {
        qDebug() << "Stopping generation before loading new model...";
        worker->stopGeneration();

        // Ждём завершения генерации
        int waitCount = 0;
        while (m_isGenerating && waitCount < 50) {
            QThread::msleep(100);
            QCoreApplication::processEvents();
            waitCount++;
        }
    }

    if (worker->model || worker->ctx) {
        qDebug() << "Cleaning up previous model...";
        modelInfo->clearModel();

        // Дополнительная пауза для освобождения ресурсов
        QThread::msleep(300);
    }
    bool success = worker->initialize(modelPath);

    if (success) {
        qDebug() << "Model initialized, updating modelInfo...";
        modelInfo->setModel(worker->model, worker->ctx, modelPath);
    } else {
        qDebug() << "Failed to initialize model";
    }

    emit modelLoadingFinished(success);

    return success;
}

void LlamaConnector::sendMessage(const QString &message)
{
    emit requestProcessing(message);
}

void LlamaConnector::clearContext()
{
    QMetaObject::invokeMethod(worker, &LlamaWorker::clearContext, Qt::QueuedConnection);
}
