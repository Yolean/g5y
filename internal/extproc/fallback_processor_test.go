package extproc

import (
	"context"
	"log/slog"
	"testing"

	corev3 "github.com/envoyproxy/go-control-plane/envoy/config/core/v3"
	extprocv3 "github.com/envoyproxy/go-control-plane/envoy/service/ext_proc/v3"
	"github.com/stretchr/testify/require"
)

func TestServer_RegisterFallbackProcessor(t *testing.T) {
	s, err := NewServer(slog.Default())
	require.NoError(t, err)
	s.config = &processorConfig{}

	s.RegisterFallbackProcessor()

	t.Run("fallback matches any path", func(t *testing.T) {
		headers := map[string]string{":path": "/any/path/here"}
		processor, err := s.processorForPath(headers, false)
		require.NoError(t, err)
		require.NotNil(t, processor)
	})

	t.Run("exact match still takes precedence", func(t *testing.T) {
		s.Register("/exact", func(*processorConfig, map[string]string, *slog.Logger, bool) (Processor, error) {
			return &mockProcessor{}, nil
		})

		headers := map[string]string{":path": "/exact"}
		processor, err := s.processorForPath(headers, false)
		require.NoError(t, err)
		require.IsType(t, &mockProcessor{}, processor)
	})
}

func TestFallbackProcessor(t *testing.T) {
	logger, buf := newTestLoggerWithBuffer()
	ctx := context.Background()

	p := &fallbackProcessor{logger: logger}

	t.Run("logs request headers", func(t *testing.T) {
		buf.Reset()
		hm := &corev3.HeaderMap{
			Headers: []*corev3.HeaderValue{
				{Key: ":path", Value: "/test"},
				{Key: "authorization", Value: "Bearer secret"},
			},
		}
		resp, err := p.ProcessRequestHeaders(ctx, hm)
		require.NoError(t, err)
		require.NotNil(t, resp)

		logOutput := buf.String()
		require.Contains(t, logOutput, "fallback processor - request headers")
		require.Contains(t, logOutput, ":path")
		require.Contains(t, logOutput, "/test")
		require.Contains(t, logOutput, "[REDACTED]")
		require.NotContains(t, logOutput, "Bearer secret")
	})

	t.Run("logs response headers", func(t *testing.T) {
		buf.Reset()
		hm := &corev3.HeaderMap{
			Headers: []*corev3.HeaderValue{
				{Key: ":status", Value: "200"},
				{Key: "content-type", Value: "application/json"},
			},
		}
		resp, err := p.ProcessResponseHeaders(ctx, hm)
		require.NoError(t, err)
		require.NotNil(t, resp)

		logOutput := buf.String()
		require.Contains(t, logOutput, "fallback processor - response headers")
		require.Contains(t, logOutput, ":status")
		require.Contains(t, logOutput, "200")
		require.Contains(t, logOutput, "application/json")
	})

	t.Run("passes through request body", func(t *testing.T) {
		resp, err := p.ProcessRequestBody(ctx, &extprocv3.HttpBody{})
		require.NoError(t, err)
		require.NotNil(t, resp)
		require.IsType(t, &extprocv3.ProcessingResponse_RequestBody{}, resp.Response)
	})

	t.Run("passes through response body", func(t *testing.T) {
		resp, err := p.ProcessResponseBody(ctx, &extprocv3.HttpBody{})
		require.NoError(t, err)
		require.NotNil(t, resp)
		require.IsType(t, &extprocv3.ProcessingResponse_ResponseBody{}, resp.Response)
	})
}
