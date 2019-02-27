( function _CommandsAggregator_test_s_() {

'use strict';

if( typeof module !== 'undefined' )
{

  let _ = require( '../../../Tools.s' );

  _.include( 'wTesting' );

  require( '../../l7/commands/CommandsAggregator.s' );

}

var _global = _global_;
var _ = _global_.wTools;

// --
//
// --

function trivial( test )
{

  var executed1 = 0;
  function executable1( e )
  {
    executed1 = 1;
    console.log( 'Executable1' );
  }

  var Commands =
  {
    'action1' : { e : executable1, h : 'Some action' },
    'action2' : 'Action2.s',
    'action3' : 'Action3.s',
  }

  var ca = _.CommandsAggregator
  ({
    basePath : __dirname,
    commands : Commands,
    commandPrefix : 'node ',
  }).form();

  var appArgs = Object.create( null );
  appArgs.subject = 'action1';
  appArgs.map = { action1 : true };
  appArgs.maps = [ appArgs.map ];
  appArgs.subjects = [ 'action1' ];
  executed1 = 0;
  ca.performApplicationArguments({ appArgs : appArgs, allowingDotless : 1 });
  test.identical( executed1,1 );

  var appArgs = Object.create( null );
  appArgs.subject = 'help';
  appArgs.map = { help : true };
  appArgs.maps = [ appArgs.map ];
  appArgs.subjects = [ 'help' ];
  ca.performApplicationArguments({ appArgs : appArgs, allowingDotless : 1 });
  test.identical( executed1,1 );

  var appArgs = Object.create( null );
  appArgs.map = { action2 : true };
  appArgs.maps = [ appArgs.map ];
  appArgs.subject = 'action2';
  appArgs.subjects = [ 'action2' ];

  return ca.performApplicationArguments({ appArgs : appArgs, allowingDotless : 1 })
  .finally( function( err, arg )
  {
    test.is( !err );
    test.is( !!arg );
    var appArgs = Object.create( null );
    appArgs.map = { '.action3' : true };
    appArgs.maps = [ appArgs.map ];
    appArgs.subject = '.action3';
    appArgs.subjects = [ '.action3' ];
    return ca.performApplicationArguments({ appArgs : appArgs });
  })

  return result;
}

//

function argumentWithSpace( test )
{

  function execWith( e )
  {
    let ca = e.ca;
    debugger;
    let isolated = ca.nextCommandIsolate( e.subject );

    test.will = 'argument for first command should have spaces';
    test.identical( isolated.subject, 'path to dir' );
    test.will = 'second command should be list'
    test.identical( isolated.secondCommand, '.list' );
    test.identical( isolated.secondSubject, '' );
  }

  function execList( e )
  {
    debugger;
    let ca = e.ca;
  }

  var Commands =
  {
    'with' : { e : execWith, h : 'With' },
    'list' : { e : execList, h : 'List' },
  }

  var ca = _.CommandsAggregator
  ({
    basePath : __dirname,
    commands : Commands,
  }).form();

  var appArgs = Object.create( null );
  appArgs.subject = '.with path to dir .list';
  appArgs.map = {};
  appArgs.maps = [ appArgs.map ];
  appArgs.subjects = [ appArgs.subject  ];

  // ca.performCommands({ commands : appArgs, propertiesMaps : appArgs.map });
  // commands : null,
  // propertiesMaps : null,

  ca.performApplicationArguments({ appArgs : appArgs, allowingDotless : 1 });
}

// --
//
// --

var Self =
{

  name : 'Tools/mid/CommandsAggregator',
  silencing : 1,

  tests :
  {

    trivial,
    argumentWithSpace,

  }

}

Self = wTestSuite( Self );
if( typeof module !== 'undefined' && !module.parent )
wTester.test( Self.name );

})();