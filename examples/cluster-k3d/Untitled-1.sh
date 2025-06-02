

git checkout ai-gateway/main -- cmd/extproc internal/extproc internal/metrics internal/version filterapi internal/llmcostcel go.mod go.sum
git rm -f internal/extproc/chatcompletion_processor*
git rm -f internal/extproc/models_processor*
git rm -r -f internal/extproc/translator*
