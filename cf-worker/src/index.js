// HomeoMind AI proxy — stateless CORS shim in front of api.openai.com.
//
// HomeoMind is a static Flutter Web app (GitHub Pages) with no backend, so
// the browser can't call api.openai.com directly: OpenAI doesn't send
// Access-Control-Allow-Origin headers for browser-origin requests, and every
// such call is blocked by CORS before it ever reaches OpenAI. This Worker
// sits in between, forwards the request byte-for-byte to OpenAI, and adds
// the CORS headers the browser needs to accept the response.
//
// It never sees or stores an OpenAI key of its own — each doctor's personal
// key (already stored client-side via flutter_secure_storage) is forwarded
// exactly as sent, in the `Authorization` header, so the app's existing
// per-doctor-key model is unchanged.

const ALLOWED_PATHS = new Set([
  '/v1/chat/completions',
  '/v1/audio/transcriptions',
]);

function corsHeaders(origin) {
  return {
    'Access-Control-Allow-Origin': origin || '*',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Authorization, Content-Type',
    'Access-Control-Max-Age': '86400',
    Vary: 'Origin',
  };
}

export default {
  async fetch(request) {
    const origin = request.headers.get('Origin') || '';
    const url = new URL(request.url);

    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: corsHeaders(origin) });
    }

    if (!ALLOWED_PATHS.has(url.pathname)) {
      return new Response('Not found', {
        status: 404,
        headers: corsHeaders(origin),
      });
    }
    if (request.method !== 'POST') {
      return new Response('Method not allowed', {
        status: 405,
        headers: corsHeaders(origin),
      });
    }

    const upstream = new URL(url.pathname, 'https://api.openai.com');

    const fwdHeaders = new Headers();
    const auth = request.headers.get('Authorization');
    if (auth) fwdHeaders.set('Authorization', auth);
    const contentType = request.headers.get('Content-Type');
    // Preserves the multipart boundary for Whisper (audio/transcriptions)
    // uploads — never hardcode this to application/json.
    if (contentType) fwdHeaders.set('Content-Type', contentType);

    let upstreamResp;
    try {
      upstreamResp = await fetch(upstream, {
        method: 'POST',
        headers: fwdHeaders,
        body: request.body,
        duplex: 'half',
      });
    } catch (err) {
      return new Response(
        JSON.stringify({ error: `Proxy fetch to OpenAI failed: ${err}` }),
        {
          status: 502,
          headers: { ...corsHeaders(origin), 'Content-Type': 'application/json' },
        },
      );
    }

    const respHeaders = new Headers(upstreamResp.headers);
    for (const [k, v] of Object.entries(corsHeaders(origin))) {
      respHeaders.set(k, v);
    }
    return new Response(upstreamResp.body, {
      status: upstreamResp.status,
      headers: respHeaders,
    });
  },
};
