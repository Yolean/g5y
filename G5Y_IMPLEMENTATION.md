
# g5y - Gateway for k8s

Gateway is Yolean's fifth generation gateway. It can:

- Use any [Envoy](https://www.envoyproxy.io/) [config](https://www.envoyproxy.io/docs/envoy/v1.34.1/start/quick-start/configuration-static.html) as template.
- Discover endpoints and scale workloads to/from zero.
- Authorize using ext_authz.
- Filter using ext_proc.

It's _not_ dependent on a CRD or operator
because at Yolean we run hundreds of gateways
and we need to be able to manage major version changes
with zero risk of disturbance to existing rollouts.

## Getting started

To see Gateway in action with a test setup, run:

```sh
kubectl -n g5y-example apply -k github.com/yolean/g5y/examples/noauth/?ref=main
```

## Configuration

We run Gateway as a sidecar to every Envoy replica.
That way we can allocate resources based on the traffic volumes each pod should handle,
and scale horizontally with the gateway.

The sidecar container needs:

- An envoy config file template that's valid YAML if all [template](https://pkg.go.dev/text/template) parameters are replaced with values.
- A secret populated with template parameters such as `SITE` and `REALM`

## auth features

Authorization is based on [ext_authz](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/ext_authz_filter).

## filter features

The filter feature is based on [ext_proc](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/ext_proc_filter) and is required for feedback during scale-from-zero.
While it's there it can also be used for custom request and response transformations.

## scale-to-zero

Gateway can watch endpoints for clusters that are configured for EDS.
It can use each service's labels to scale the backing workload.
Scaling is inspired by KEDA: it only does -to-one and -to-zero.
A regular HorizontalPodAutoscaler can scale up from that.

Using a watcher Gateway will now instantly on a request to that cluster
that it needs to be scaled up
and the ext_proc filter can serve a loading page while waiting for availability.

Multiple replicas of Gateway can still be unaware of each other because
they're very likely to take the same scaling decision
(unlike scale above 1 that would depend on traffic volumes).

A configurable cooldown period triggers scale down.
With very low traffic volumes the lack of coordination can be an issue here,
so use long cooldown periods in such scenarios.

## Tests

The implementation is less important than the test automation for this component.
Tests are found in the [scenarios](./scenarios) folder.
Each scenario consists of one config (k8s resources + template + secret)
and a set of HTTP client and/or browser replay tests.
The latter uses [Puppeteer](https://pptr.dev/) syntax.

## Dependencies

Gateway has the following requirements:

- Kubernetes 1.31+
- [Gateway API](https://gateway-api.sigs.k8s.io/) 1.3+
- Envoy 1.34+
