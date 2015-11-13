// emitElapsed.js
// ------------------------------------------------------------------

var start, end, delta;

start = context.getVariable('target.sent.start.timestamp');
end = context.getVariable('target.received.end.timestamp');
delta = Math.floor(end - start);
context.proxyResponse.headers['X-time-target-elapsed'] = delta;

start = context.getVariable('client.received.start.timestamp');
end = context.getVariable('system.timestamp');
delta = Math.floor(end - start);
context.proxyResponse.headers['X-time-total-elapsed'] = delta;

