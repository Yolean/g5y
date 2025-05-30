package extproc

import (
	"context"
	"log/slog"

	"github.com/envoyproxy/ai-gateway/filterapi"
	"github.com/envoyproxy/ai-gateway/internal/extproc/backendauth"
	corev3 "github.com/envoyproxy/go-control-plane/envoy/config/core/v3"
	extprocv3 "github.com/envoyproxy/go-control-plane/envoy/service/ext_proc/v3"
)

// fallbackProcessor logs request and response headers then passes through the request.
type fallbackProcessor struct {
	logger *slog.Logger
}

// ProcessRequestHeaders implements [Processor.ProcessRequestHeaders].
func (p fallbackProcessor) ProcessRequestHeaders(ctx context.Context, headers *corev3.HeaderMap) (*extprocv3.ProcessingResponse, error) {
	if p.logger.Enabled(ctx, slog.LevelInfo) {
		filteredHdrs := filterSensitiveHeadersForLogging(headers, sensitiveHeaderKeys)
		p.logger.Info("fallback processor - request headers", slog.Any("headers", filteredHdrs))
	}
	return &extprocv3.ProcessingResponse{Response: &extprocv3.ProcessingResponse_RequestHeaders{}}, nil
}

// ProcessRequestBody implements [Processor.ProcessRequestBody].
func (p fallbackProcessor) ProcessRequestBody(context.Context, *extprocv3.HttpBody) (*extprocv3.ProcessingResponse, error) {
	return &extprocv3.ProcessingResponse{Response: &extprocv3.ProcessingResponse_RequestBody{}}, nil
}

// ProcessResponseHeaders implements [Processor.ProcessResponseHeaders].
func (p fallbackProcessor) ProcessResponseHeaders(ctx context.Context, headers *corev3.HeaderMap) (*extprocv3.ProcessingResponse, error) {
	if p.logger.Enabled(ctx, slog.LevelInfo) {
		filteredHdrs := filterSensitiveHeadersForLogging(headers, sensitiveHeaderKeys)
		p.logger.Info("fallback processor - response headers", slog.Any("headers", filteredHdrs))
	}
	return &extprocv3.ProcessingResponse{Response: &extprocv3.ProcessingResponse_ResponseHeaders{}}, nil
}

// ProcessResponseBody implements [Processor.ProcessResponseBody].
func (p fallbackProcessor) ProcessResponseBody(context.Context, *extprocv3.HttpBody) (*extprocv3.ProcessingResponse, error) {
	return &extprocv3.ProcessingResponse{Response: &extprocv3.ProcessingResponse_ResponseBody{}}, nil
}

// SetBackend implements [Processor.SetBackend].
func (p fallbackProcessor) SetBackend(context.Context, *filterapi.Backend, backendauth.Handler, Processor) error {
	return nil
}
