// mapGroupsToScopes.js
// ------------------------------------------------------------------
//
// Map a set of user groups to a list of scopes. This would be
// better implemented as a micro-service, but this mock will serve
// the purpose for the demonstration.
//
// last saved: <2016-June-21 17:59:08>

var groupsVar = 'user_groups';
var scopesVar = 'user_scopes';
var groups = context.getVariable(groupsVar).split(',');
var result = [];
var groupToScopeMap = {
      'group01' : [ 'scope-01',
                    'scope-02',
                    'scope-03'
                  ],
      'group02' : [ 'scope-02',
                    'scope-04'
                  ],
      'group03' : [ 'scope-03'
                  ],
      'group04' : [ 'scope-05',
                    'scope-06'
                  ],
    };

groups.forEach(function(group){
  if (groupToScopeMap.hasOwnProperty(group)) {
    groupToScopeMap[group].forEach(function(scope){
      result.push(scope);
    });
  }
});

context.setVariable(scopesVar, result.sort().join(' '));
