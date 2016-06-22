// validateUser.js
// ------------------------------------------------------------------
//
// validate the user based on the passed-in values.
// This code relies on the user database stored / embedded in userDb.js .
//
// created: Tue Jan 26 14:07:19 2016
// last saved: <2016-June-21 15:05:57>

var username = context.getVariable('request.formparam.username');
var password = context.getVariable('request.formparam.password');
var statusVar = 'user_is_authentic';
var groupsVar = 'user_groups';
var result = false;

if (username && password) {
  if (userDb && userDb[username]) {
    var storedRecord = userDb[username];
    if (storedRecord) {
      // user has been found
      var storedHash = userDb[username].hash;
      var computedHash = sjcl.hash.sha256.hash(password);
      var computedHashHexString = sjcl.codec.hex.fromBits(computedHash);
      if (storedHash && computedHashHexString == storedHash) {
        result = true; // authenticated
        context.setVariable(groupsVar, userDb[username].groups.join(','));
      }
    }
  }
}

context.setVariable(statusVar, result);
