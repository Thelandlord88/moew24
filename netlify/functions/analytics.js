exports.handler = async (event) => {
  if (event.httpMethod !== 'POST') return { statusCode: 405, body: 'Method Not Allowed' };
  // minimal privacy-first ledger: count only event type + path (no PII)
  const { eventType, path } = JSON.parse(event.body||'{}');
  console.log(JSON.stringify({ t: Date.now(), eventType, path }));
  return { statusCode: 204, body: '' };
};
