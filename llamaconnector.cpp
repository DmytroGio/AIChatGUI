#include "llamaconnector.h"
#include <QDebug>
#include <QFile>
#include <chrono>

LlamaWorker::LlamaWorker(QObject *parent)
    : QObject(parent), m_shouldStop(0)
{
    llama_backend_init();
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

    // Остальной код
    if (!QFile::exists(modelPath)) {
        emit errorOccurred("Model file not found: " + modelPath);
        return false;
    }

    llama_model_params model_params = llama_model_default_params();
    model = llama_model_load_from_file(modelPath.toUtf8().constData(), model_params);

    if (!model) {
        emit errorOccurred("Failed to load model");
        return false;
    }

    vocab = llama_model_get_vocab(model);

    llama_context_params ctx_params = llama_context_default_params();
    ctx_params.n_ctx = 2048;
    ctx_params.n_batch = 512;
    ctx_params.n_threads = 4;

    ctx = llama_init_from_model(model, ctx_params);

    if (!ctx) {
        emit errorOccurred("Failed to create context");
        return false;
    }

    sampler = llama_sampler_chain_init(llama_sampler_chain_default_params());
    llama_sampler_chain_add(sampler, llama_sampler_init_temp(0.7f));
    llama_sampler_chain_add(sampler, llama_sampler_init_top_p(0.9f, 1));
    llama_sampler_chain_add(sampler, llama_sampler_init_dist(LLAMA_DEFAULT_SEED));

    emit modelLoadedSuccessfully();

    return true;
}

void LlamaWorker::processMessage(const QString &message)
{
    if (!model || !ctx || !vocab) {
        emit errorOccurred("Model not loaded");
        return;
    }

    m_shouldStop.storeRelaxed(0);

    auto start_time = std::chrono::high_resolution_clock::now();

    QString prompt = "<|im_start|>system\nYou are a helpful assistant.<|im_end|>\n"
                     "<|im_start|>user\n" + message + "<|im_end|>\n"
                                 "<|im_start|>assistant\n";

    std::string prompt_str = prompt.toStdString();

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
        tokens.resize(-n_tokens);
        n_tokens = llama_tokenize(vocab, prompt_str.c_str(), prompt_str.length(),
                                  tokens.data(), tokens.size(), true, true);
    }

    if (n_tokens <= 0) {
        emit errorOccurred("Failed to tokenize");
        return;
    }
    tokens.resize(n_tokens);

    llama_batch batch = llama_batch_get_one(tokens.data(), n_tokens);

    if (llama_decode(ctx, batch) != 0) {
        emit errorOccurred("Failed to decode prompt");
        return;
    }

    emit generationStarted();

    QString response;
    int n_gen = 0;
    const int max_gen_tokens = 512;

    while (n_gen < max_gen_tokens) {
        // Проверка флага остановки
        if (m_shouldStop.loadRelaxed() == 1) {
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
            break;
        }

        char piece[128];
        int n_chars = llama_token_to_piece(vocab, new_token, piece, sizeof(piece), 0, true);

        if (n_chars > 0) {
            QString tokenText = QString::fromUtf8(piece, n_chars);
            response += tokenText;
            emit tokenGenerated(tokenText);
        }

        batch = llama_batch_get_one(&new_token, 1);

        if (llama_decode(ctx, batch) != 0) {
            break;
        }

        n_gen++;
    }

    response = response.remove("<|im_end|>").trimmed();

    if (response.isEmpty()) {
        response = "Error: No response generated";
    }

    auto end_time = std::chrono::high_resolution_clock::now();
    auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(end_time - start_time);

    emit generationFinished(n_gen, duration.count());
    emit messageReceived(response);
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
    emit modelLoadingStarted();

    // Очищаем предыдущую модель если была
    if (worker->model || worker->ctx) {
        modelInfo->clearModel();
        QThread::msleep(100);
    }

    bool success = worker->initialize(modelPath);

    if (success) {
        modelInfo->setModel(worker->model, worker->ctx, modelPath);
    }

    emit modelLoadingFinished(success);

    return success;
}

void LlamaConnector::sendMessage(const QString &message)
{
    emit requestProcessing(message);
}
