const http = require('node:http');

const port = Number.parseInt(process.env.PORT ?? '8080', 10);
const startupDelayMs = Number.parseInt(process.env.STARTUP_DELAY_MS ?? '20000', 10);
const startedAt = Date.now();

function isHealthy(now = Date.now()) {
  return now - startedAt >= startupDelayMs;
}

function json(response, statusCode, body) {
  response.writeHead(statusCode, { 'content-type': 'application/json' });
  response.end(JSON.stringify(body));
}

function handleRequest(request, response) {
  if (request.url === '/healthz' || request.url === '/readyz') {
    const healthy = isHealthy();
    json(response, healthy ? 200 : 503, {
      status: healthy ? 'healthy' : 'starting',
      uptimeSeconds: Math.floor((Date.now() - startedAt) / 1000),
    });
    return;
  }

  if (request.url === '/api/status') {
    json(response, 200, {
      service: 'customer-api',
      version: process.env.APP_VERSION ?? 'unknown',
      status: 'ok',
    });
    return;
  }

  json(response, 404, { error: 'not_found' });
}

if (require.main === module) {
  const server = http.createServer(handleRequest);
  server.listen(port, '0.0.0.0', () => {
    console.log(`customer-api listening on port ${port}`);
    console.log(`startup checks will pass after ${startupDelayMs}ms`);
  });
}

module.exports = { handleRequest, isHealthy };
