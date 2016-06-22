// userDb.js
// ------------------------------------------------------------------
//
// This is a mock user validation database. The hash stores usernames and
// the hex-encoded sha256 of the passwords, as well as roles for the users.
//
// To generate additional sha256 passwords on macosx:
//
//   echo -n "password-value" | shasum -a 256
//
// This is a little bit elaborate for a fake user authentication system.
// I just wanted to show some of the things that could be done in a JS callout.
//
// -Dino
//
// created: Fri Mar 25 20:01:12 2016
// last saved: <2016-June-21 17:57:18>

var userDb = {
      Sydney : {
        hash: 'c430b84b99866d8447123b674486bd0304b2064e1f58a571aeaa65533327e050',
        groups: [ 'group01' ]
      },
      Kris : {
        hash: '334072cf0b21f8c1016257b28698d3054b2b2efb7c5d21f68129161886f86187',
        groups: [ 'group02', 'group03' ]
      },
      Evgeny : {
        hash: '1ed020b90feeeead64e25f60ad0fcd9a3debb2babafe593d81c54657ac75070d',
        groups: [ 'group04' ]
      },

      // Obviously, you can add more records here.  Also, you can add other
      // properties to each record. For example, beyond groups, you could add
      // roles, or whatever else makes sense in your desired system. If you DO add
      // other data items, then you would also need to modify the proxy to attach
      // those properties to a token issued by Edge.
      //
      // Follow the example in the GenerateAccessToken policy for the user_groups.

    };
