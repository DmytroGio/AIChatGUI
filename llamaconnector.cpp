#include "llamaconnector.h"
#include <QDebug>
#include <QFile>

LlamaWorker::LlamaWorker(QObject *parent)
    : QObject(parent)
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

bool LlamaWorker::initialize(const QString &modelPath)
{
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

    return true;
}

void LlamaWorker::processMessage(const QString &message)
{
    if (!model || !ctx || !vocab) {
        emit errorOccurred("Model not loaded");
        return;
    }

    QString prompt = "<|im_start|>system\nYou are a helpful assistant.<|im_end|>\n"
                     "<|im_start|>user\n" + message + "<|im_end|>\n"
                                 "<|im_start|>assistant\n";

    std::string prompt_str = prompt.toStdString();

    // Токенизация
    const int max_tokens_input = 2048;
    std::vector<llama_token> tokens(max_tokens_input);
    int n_tokens = llama_tokenize(
        vocab,  // используем vocab вместо model
        prompt_str.c_str(),
        prompt_str.length(),
        tokens.data(),
        max_tokens_input,
        true,
        true
        );

    if (n_tokens < 0) {
        emit errorOccurred("Failed to tokenize");
        return;
    }
    tokens.resize(n_tokens);

    // Создание batch
    llama_batch batch = llama_batch_init(n_tokens, 0, 1);

    // Добавление токенов в batch
    for (int i = 0; i < n_tokens; i++) {
        batch.token[i] = tokens[i];
        batch.pos[i] = i;
        batch.n_seq_id[i] = 1;
        batch.seq_id[i][0] = 0;
        batch.logits[i] = false;
    }
    batch.logits[n_tokens - 1] = true;
    batch.n_tokens = n_tokens;

    if (llama_decode(ctx, batch) != 0) {
        emit errorOccurred("Failed to decode");
        llama_batch_free(batch);
        return;
    }

    QString response;
    int n_cur = n_tokens;
    int n_gen = 0;
    const int max_gen_tokens = 2048;

    while (n_gen < max_gen_tokens) {
        llama_token new_token = llama_sampler_sample(sampler, ctx, -1);

        // Проверка на конец генерации
        if (llama_vocab_is_eog(vocab, new_token)) {  // используем vocab
            break;
        }

        // Преобразование токена в текст
        char piece[128];
        int n_chars = llama_token_to_piece(
            vocab,  // используем vocab вместо model
            new_token,
            piece,
            sizeof(piece),
            0,
            true
            );

        if (n_chars > 0) {
            response += QString::fromUtf8(piece, n_chars);
        }

        // Подготовка следующего токена
        batch.n_tokens = 0;
        batch.token[0] = new_token;
        batch.pos[0] = n_cur++;
        batch.n_seq_id[0] = 1;
        batch.seq_id[0][0] = 0;
        batch.logits[0] = true;
        batch.n_tokens = 1;

        if (llama_decode(ctx, batch) != 0) {
            break;
        }

        n_gen++;
    }

    llama_batch_free(batch);

    response = response.remove("<|im_end|>").trimmed();

    emit messageReceived(response);
}

// LlamaConnector implementation

LlamaConnector::LlamaConnector(QObject *parent)
    : QObject(parent)
{
    worker = new LlamaWorker();
    worker->moveToThread(&workerThread);

    connect(&workerThread, &QThread::finished, worker, &QObject::deleteLater);
    connect(this, &LlamaConnector::requestProcessing, worker, &LlamaWorker::processMessage);
    connect(worker, &LlamaWorker::messageReceived, this, &LlamaConnector::messageReceived);
    connect(worker, &LlamaWorker::errorOccurred, this, &LlamaConnector::errorOccurred);

    workerThread.start();
}

LlamaConnector::~LlamaConnector()
{
    workerThread.quit();
    workerThread.wait();
}

bool LlamaConnector::loadModel(const QString &modelPath)
{
    return worker->initialize(modelPath);
}

void LlamaConnector::sendMessage(const QString &message)
{
    emit requestProcessing(message);
}
