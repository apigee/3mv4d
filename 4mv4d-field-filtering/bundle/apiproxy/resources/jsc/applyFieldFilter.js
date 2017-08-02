// applyFieldFilter.js
// ------------------------------------------------------------------
//
// Retrieve desired fields for this request, if any,
// and then apply the filter as appropriate.
//
// Example usage:
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
// Example usage with GraphQL
//
//    <Javascript name='JS-FilterFields-Course' timeLimit='800' >
//      <Properties>
//        <Property name='action'>exclude</Property> <!-- or include -->
//        <Property name='fields'>{ curriculum { href } current { href } }</Property>
//      </Properties>
//      <IncludeURL>jsc://fieldFiltering.js</IncludeURL>
//      <ResourceURL>jsc://applyFieldFilter.js</ResourceURL>
//    </Javascript>
//
// created: Wed Jan 13 12:12:56 2016
// last saved: <2017-August-02 11:00:59>
/* jshint -W053 */
/* jshint -W002 */

var disabled = requestHasDisabledFiltering();

if ( ! disabled) {
  // apply the field filter, and replace the response output
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
  var fields = [], v, reVarName = new RegExp('^{([^ ,}]+)}$'), match;

  // There are two properties used to specify the list of fields to
  // include or exclude. In order of precedence, they are:
  //
  // filterResponse : the property value is the name of a context
  //      variable, which holds a response message from BaaS
  //      containing a single entity which contains a property
  //      named "fields".
  //
  // fields : the property value is a comma-separated list of fields to filter.
  //      Or, the name of a context-variable surrounded in curly-braces which
  //      contains a comma-separated list of fields to filter.
  //      The variable might be one retrieved from a custom attribute on
  //      a token, a developer app, or an API product.

  if ('' + properties.filterResponse != "undefined") {
    // retrieve fields to filter, from BaaS
    var filterResponse = context.getVariable(properties.filterResponse);
    filterResponse = JSON.parse(filterResponse);

    if (filterResponse.entities && filterResponse.entities[0]) {
      var entity = filterResponse.entities[0];
      fields = entity.fields;
    }
    return fields;
  }
  if ('' + properties.fields != "undefined") {
    v = properties.fields.trim();
    // resolve any variable contained within curly braces
    match = v.match(reVarName);
    if (match && match[1]) {
      v = context.getVariable(match[1]);
    }
    v = v.trim();
    return (v.indexOf('{')===0) ? v : v.split(',');
  }

  return null;

}
