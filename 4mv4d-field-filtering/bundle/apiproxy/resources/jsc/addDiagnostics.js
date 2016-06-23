// addDiagnostics.js
// ------------------------------------------------------------------
//
// Inject some diagnostic information into the JSON response.
// This is done only for demonstration purposes.
//
// created: Wed Jan 13 16:15:23 2016
// last saved: <2016-June-23 13:27:02>

var c = JSON.parse(response.content);

c.diagnostics = {
  productName : context.getVariable('apiproduct.name'),
  appName : context.getVariable('developer.app.name'),
  proxyName : context.getVariable('apiproxy.name'),
  filterFields : JSON.parse(context.getVariable('filterFields')),
  filterAction : context.getVariable('filterAction')
};

// re-serialize and pretty-print
response.content = JSON.stringify(c,null,2) + '\n';
