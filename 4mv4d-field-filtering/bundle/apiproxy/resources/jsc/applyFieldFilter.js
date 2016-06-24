// applyFieldFilter.js
// ------------------------------------------------------------------
//
// Retrieve desired fields for this request, if any,
// and then apply the filter as appropriate.
//
// example usage:
//
//    <Javascript name='JS-FilterFields-Course' timeLimit='800' >
//      <Properties>
//        <Property name='action'>exclude</Property> <!-- or include -->
//        <Property name='fields'>curriculum.href,current.href</Property>
//      </Properties>
//      <IncludeURL>jsc://fieldFiltering.js</IncludeURL>
//      <ResourceURL>jsc://applyFieldFilter.js</ResourceURL>
//    </Javascript>
//
// created: Wed Jan 13 12:12:56 2016
// last saved: <2016-June-24 08:25:03>
/* jshint -W053 */
/* jshint -W002 */

var disabled = requestHasDisabledFiltering();

if ( ! disabled) {
  var action = getFilterAction();
  var namedFields = getNamedFieldsToFilter();
  context.setVariable('filterAction', action); // diagnostics
  context.setVariable('filterFields', JSON.stringify(namedFields)); // diagnostics
  var newResponse = applyFieldFilter(action, JSON.parse(response.content), namedFields);
  // pretty print the output
  response.content = JSON.stringify(newResponse, null, 2) + '\n';
}


// ====================================================================

function requestHasDisabledFiltering() {
  // Just for purposes of the demonstration, we can show how to disable
  // this filtering at runtime based on the presence of a special HTTP
  // header in the request.
  var re1a = new RegExp('[ ,]'),
      hdr = context.getVariable('request.header.X-tweak.values') + '',
      tweak = hdr.toLowerCase().substring(1, hdr.length-1).split(re1a);
  return tweak.indexOf('no-filter') !== -1;
}

function getFilterAction() {
  var action = properties.action, re1 = new RegExp('{([^ ,}]+)}'), match;
  if ('' + action == "undefined") { return 'include'; }

  // resolve any variable contained within curly braces
  match = action.match(re1);
  if (match && match[1]) {
    action = context.getVariable(match[1]);
  }
  return action;
}

function getNamedFieldsToFilter() {
  var fields = [], v, re1 = new RegExp('{([^ ,}]+)}'), match;

  // The fields property should contain either:
  //
  //  - a comma-separated list of fields to filter.
  //
  //  - the name of a context-variable surrounded in curly-braces which
  //    contains a comma-separated list of fields to filter.  The
  //    variable might be one retrieved from a custom attribute on a
  //    token, a developer app, or an API product.

  if ('' + properties.fields != "undefined") {
    v = properties.fields;
    // resolve any variable contained within curly braces
    match = v.match(re1);
    if (match && match[1]) {
      v = context.getVariable(match[1]);
    }
  }
  if (v) { fields = v.split(','); }
  return fields;
}
