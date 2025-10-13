#include "llamaconnector.h"
#include <QDebug>
#include <QFile>
#include <chrono>
#include <QCoreApplication>

LlamaWorker::LlamaWorker(QObject *parent)
    : QObject(parent), m_shouldStop(0)
{

    llama_backend_init();

    // ДОБАВИТЬ:
    qDebug() << "=== llama.cpp system info ===";
    qDebug() << llama_print_system_info();
}

LlamaWorker::~LlamaWorker()
{
    if (sampler) llama_sampler_free(sampler);
    if (ctx) llama_free(ctx);
    if (model) llama_model_free(model);  // было llama_free_model
    llama_backend_free();
}

void LlamaWorker::stopGeneration()
{
    m_shouldStop.storeRelaxed(1);
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

    // Всегда пробуем GPU, даже если проверка не прошла
    qDebug() << "GPU offload support:" << llama_supports_gpu_offload();
    model_params.n_gpu_layers = 0;  // ВРЕМЕННО отключаем GPU
    // model_params.main_gpu = 0;  // ЗАКОММЕНТИРУЙТЕ
    // model_params.split_mode = LLAMA_SPLIT_MODE_NONE;  // ЗАКОММЕНТИРУЙТЕ

    qDebug() << "Loading model from:" << modelPath;
    model = llama_model_load_from_file(modelPath.toUtf8().constData(), model_params);

    if (!model) {
        emit errorOccurred("Failed to load model");
        return false;
    }

    vocab = llama_model_get_vocab(model);

    if (!vocab) {
        emit errorOccurred("Failed to get vocabulary");
        llama_model_free(model);
        model = nullptr;
        return false;
    }

    llama_context_params ctx_params = llama_context_default_params();
    ctx_params.n_ctx = 2048;
    ctx_params.n_batch = 512;  // обратно для стабильности
    ctx_params.n_ubatch = 512;  // ДОБАВИТЬ эту строку
    ctx_params.n_threads = 8;   // ИЗМЕНЕНО с 4 на 8
    ctx_params.n_threads_batch = 8;

    // ВСЕГДА включаем GPU параметры
    ctx_params.offload_kqv = true;
    ctx_params.flash_attn_type = LLAMA_FLASH_ATTN_TYPE_DISABLED;  //отключаем flash attention для совместимости

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

    // КРИТИЧНО: Очистка KV cache перед новым сообщением
    llama_memory_t memory = llama_get_memory(ctx);
    llama_memory_clear(memory, false);
    qDebug() << "KV cache cleared";

    QString prompt = "<|im_start|>system\nYou are a helpful assistant.<|im_end|>\n"
                     "<|im_start|>user\n" + message + "<|im_end|>\n"
                                 "<|im_start|>assistant\n";

    std::string prompt_str = prompt.toStdString();
    qDebug() << "Prompt length:" << prompt_str.length();

    // Токенизация
    std::vector<llama_token> tokens(prompt_str.size() + 128);
    int n_tokens = llama_tokenize(
        vocab,
        prompt_str.c_str(),
        prompt_str.length(),
        tokens.data(),
        tokens.size(),
        true,
        true
        );

    if (n_tokens < 0) {
        qDebug() << "Resizing tokens buffer to" << -n_tokens;
        tokens.resize(-n_tokens);
        n_tokens = llama_tokenize(vocab, prompt_str.c_str(), prompt_str.length(),
                                  tokens.data(), tokens.size(), true, true);
    }

    if (n_tokens <= 0) {
        qDebug() << "ERROR: Tokenization failed, n_tokens =" << n_tokens;
        emit errorOccurred("Failed to tokenize");
        return;
    }

    tokens.resize(n_tokens);
    qDebug() << "Tokenized successfully, n_tokens:" << n_tokens;

    // ИСПРАВЛЕНО: Правильное создание batch для промпта
    qDebug() << "Creating batch for prompt...";
    llama_batch batch = llama_batch_init(n_tokens, 0, 1);

    for (int i = 0; i < n_tokens; i++) {
        batch.token[i] = tokens[i];
        batch.pos[i] = i;
        batch.n_seq_id[i] = 1;
        batch.seq_id[i] = (llama_seq_id*)malloc(sizeof(llama_seq_id));
        batch.seq_id[i][0] = 0;
        batch.logits[i] = (i == n_tokens - 1) ? 1 : 0;  // только последний
    }
    batch.n_tokens = n_tokens;

    qDebug() << "Decoding prompt...";
    int decode_result = llama_decode(ctx, batch);
    qDebug() << "Decode result:" << decode_result;

    // Освобождение памяти batch
    for (int i = 0; i < n_tokens; i++) {
        if (batch.seq_id[i]) free(batch.seq_id[i]);
    }
    llama_batch_free(batch);

    if (decode_result != 0) {
        qDebug() << "ERROR: Failed to decode prompt, code:" << decode_result;
        emit errorOccurred("Failed to decode prompt, code: " + QString::number(decode_result));
        return;
    }

    qDebug() << "Prompt decoded successfully";
    emit generationStarted();

    QString response;
    int n_gen = 0;
    const int max_gen_tokens = 512;

    qDebug() << "Starting generation loop...";

    while (n_gen < max_gen_tokens) {
        if (m_shouldStop.loadRelaxed() == 1) {
            qDebug() << "Generation stopped by user at token" << n_gen;
            response = response.remove("<|im_end|>").trimmed();

            auto end_time = std::chrono::high_resolution_clock::now();
            auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(end_time - start_time);

            emit generationStopped();
            emit generationFinished(n_gen, duration.count());
            emit messageReceived(response.isEmpty() ? "Generation stopped" : response);
            return;
        }

        llama_token new_token = llama_sampler_sample(sampler, ctx, -1);

        if (new_token < 0 || llama_vocab_is_eog(vocab, new_token)) {
            qDebug() << "EOG token at position" << n_gen;
            break;
        }

        char piece[128];
        int n_chars = llama_token_to_piece(vocab, new_token, piece, sizeof(piece), 0, true);

        if (n_chars > 0) {
            QString tokenText = QString::fromUtf8(piece, n_chars);
            response += tokenText;
            emit tokenGenerated(tokenText);
        }

        // ИСПРАВЛЕНО: Правильное создание batch для одного токена
        llama_batch single_batch = llama_batch_init(1, 0, 1);
        single_batch.token[0] = new_token;
        single_batch.pos[0] = n_tokens + n_gen;
        single_batch.n_seq_id[0] = 1;
        single_batch.seq_id[0] = (llama_seq_id*)malloc(sizeof(llama_seq_id));
        single_batch.seq_id[0][0] = 0;
        single_batch.logits[0] = 1;
        single_batch.n_tokens = 1;

        int result = llama_decode(ctx, single_batch);

        // Освобождение
        if (single_batch.seq_id[0]) free(single_batch.seq_id[0]);
        llama_batch_free(single_batch);

        if (result != 0) {
            qDebug() << "Decode failed at token" << n_gen << "with code" << result;
            break;
        }

        n_gen++;
    }

    qDebug() << "Generation loop finished, tokens:" << n_gen;

    response = response.remove("<|im_end|>").trimmed();

    if (response.isEmpty()) {
        qDebug() << "WARNING: Empty response";
        response = "Error: No response generated";
    }

    auto end_time = std::chrono::high_resolution_clock::now();
    auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(end_time - start_time);

    qDebug() << "Response length:" << response.length();
    emit generationFinished(n_gen, duration.count());
    emit messageReceived(response);
    qDebug() << "=== processMessage FINISHED ===";
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
    connect(worker, &LlamaWorker::messageReceived, this, &LlamaConnector::messageReceived);
    connect(worker, &LlamaWorker::errorOccurred, this, &LlamaConnector::errorOccurred);
    connect(worker, &LlamaWorker::tokenGenerated, this, &LlamaConnector::tokenGenerated);

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
