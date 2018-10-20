( function _CommandsAggregator_s_() {

'use strict';

/**
  @module Tools/mid/CommandsAggregator - Class aggregating several applications into single CLI. It can aggregate external binary applications as well as JS functions. Use it to expose CLI.
*/

/**
 * @file CommandsAggregator.s.
 */

if( typeof module !== 'undefined' )
{

  if( typeof _global_ === 'undefined' || !_global_.wBase )
  {
    let toolsPath = '../../../../dwtools/Base.s';
    let toolsExternal = 0;
    try
    {
      toolsPath = require.resolve( toolsPath );
    }
    catch( err )
    {
      toolsExternal = 1;
      require( 'wTools' );
    }
    if( !toolsExternal )
    require( toolsPath );
  }

  let _ = _global_.wTools;

  _.include( 'wCopyable' );
  _.include( 'wVocabulary' );
  _.include( 'wPathFundamentals' );
  _.include( 'wExternalFundamentals' );
  _.include( 'wFiles' );

}

//

let _ = _global_.wTools;
let Parent = null;
let Self = function wCommandsAggregator()
{
  return _.instanceConstructor( Self, this, arguments );
}

Self.shortName = 'CommandsAggregator';

//

function init( o )
{
  let self = this;

  _.assert( arguments.length === 0 || arguments.length === 1 );

  _.instanceInit( self );
  Object.preventExtensions( self )

  if( o )
  self.copy( o );

  if( self.logger === null )
  self.logger = new _.Logger({ output : _global_.logger });

}

//

function form()
{
  let self = this;

  _.assert( !self._formed );
  _.assert( _.objectIs( self.commands ) );
  _.assert( arguments.length === 0 );

  self.basePath = _.path.resolve( self.basePath );

  if( self.supplementingByHelp && !self.commands.help )
  {
    self.commands.help = { e : self._commandHelp.bind( self ), h : 'Get help' };
  }

  self._formVocabulary();

  self.vocabulary.onPhraseDescriptorMake = self._onPhraseDescriptorMake.bind( self ),

  self.commandsAdd( self.commands );

  self._formed = 1;
  return self;
}

//

function _formVocabulary()
{
  let self = this;
  _.assert( arguments.length === 0 );
  self.vocabulary = self.vocabulary || _.Vocabulary();
  self.vocabulary.addingDelimeter = self.addingDelimeter;
  self.vocabulary.lookingDelimeter = self.lookingDelimeter;
}

//

function exec()
{
  let self = this;
  let appArgs = _.appArgs();
  return self.proceedApplicationArguments({ appArgs : appArgs });
}

//

function proceedApplicationArguments( o )
{
  let self = this;

  _.assert( _.instanceIs( self ) );
  _.assert( !!self._formed );
  _.assert( arguments.length === 1 );
  _.routineOptions( proceedApplicationArguments, o );

  if( o.appArgs === null )
  o.appArgs = _.appArgs();

  /* */

  if( !o.allowingDotless )
  if( !_.strBegins( o.appArgs.subject, '.' ) || _.strBegins( o.appArgs.subject, './' ) || _.strBegins( o.appArgs.subject, '.\\' ) )
  {
    self.logger.error( 'Illformed request', self.logger.colorFormat( _.strQuote( o.appArgs.subject ), 'code' ) );
    self.onGetHelp();
    return;
  }

  if( o.printingEcho )
  self.logger.log( 'Request', self.logger.colorFormat( _.strQuote( o.appArgs.subject ), 'code' ) );

  /* */

  let subjects = _.strIsolateBeginOrAll( o.appArgs.subject.trim(), ' ' );
  let subjectDescriptors = self.vocabulary.subjectDescriptorFor( subjects[ 0 ] );
  let filteredSubjectDescriptors;

  return self.proceedAct
  ({
    command : subjects[ 0 ],
    subject : subjects[ 2 ],
    propertiesMap : o.appArgs.map,
  });

}

proceedApplicationArguments.defaults =
{
  printingEcho : 1,
  allowingDotless : 0,
  appArgs : null,
}

//

function proceedAct( o )
{
  let self = this;

  _.routineOptions( proceedAct, o );
  _.assert( _.strIs( o.subject ) );
  _.assert( _.strIs( o.command ) );
  _.assert( o.propertiesMap === null || _.objectIs( o.propertiesMap ) );
  _.assert( _.instanceIs( self ) );
  _.assert( !!self._formed );
  _.assert( arguments.length === 1 );

  o.propertiesMap = o.propertiesMap || Object.create( null );

  /* */

  let subjectDescriptors = self.vocabulary.subjectDescriptorFor( o.command );
  let filteredSubjectDescriptors;

  /* */

  if( !subjectDescriptors.length )
  {
    let s = 'Unknown subject ' + _.strQuote( o.command );
    if( self.vocabulary.descriptorMap[ 'help' ] )
    s += '\nTry subject ".help"';
    throw _.errBriefly( s );
  }
  else
  {
    filteredSubjectDescriptors = self.vocabulary.subjectsFilter( subjectDescriptors, { wholePhrase : o.command } );
    if( filteredSubjectDescriptors.length !== 1 )
    {
      self.logger.log( 'Ambiguity' );
      self.logger.log( self.vocabulary.helpForSubjectAsString( o.command ) );
      self.logger.log( '' );
    }
    if( filteredSubjectDescriptors.length !== 1 )
    return;
  }

  /* */

  let executable = filteredSubjectDescriptors[ 0 ].phraseDescriptor.executable;
  if( _.routineIs( executable ) )
  {
    return executable
    ({
      command : o.command,
      subject : o.subject,
      propertiesMap : o.propertiesMap,
      // appArgs : o.appArgs,
      ca : self,
      phrase : filteredSubjectDescriptors[ 0 ].phraseDescriptor.phrase,
    });
  }
  else
  {
    executable = _.path.nativize( executable );
    let mapStr = _.strJoinMap({ src : o.propertiesMap });
    let shellStr = self.commandPrefix + executable + ' ' + o.subject + ' ' + mapStr;
    let o2 = Object.create( null );
    o2.path = shellStr;
    return _.shell( o2 );
  }

}

proceedAct.defaults =
{
  command : null,
  subject : '',
  propertiesMap : null,
}

//

function commandsAdd( commands )
{
  let self = this;

  _.assert( !self._formed );
  _.assert( arguments.length === 1 );

  self._formVocabulary();

  self.vocabulary.phrasesAdd( commands );

  return self;
}

//

function _commandHelp( e )
{
  let self = this;
  let ca = e.ca;
  let logger = self.logger || ca.logger || _global_.logger;

  if( e.subject )
  {

    logger.log();
    logger.log( e.ca.vocabulary.helpForSubjectAsString( e.subject ) );
    logger.up();

    let subjects = e.ca.vocabulary.subjectDescriptorForWithClause({ phrase : e.subject });

    if( subjects.length === 0 )
    {
      logger.log( 'No command', e.subject );
    }
    else if( subjects.length === 1 )
    {
      let subject = subjects[ 0 ];
      if( subject.phraseDescriptor.executable && subject.phraseDescriptor.executable.commandProperties )
      {
        let properties = subject.phraseDescriptor.executable.commandProperties;
        logger.log( _.toStr( properties, { levels : 2, wrap : 0, multiline : 1 } ) );
      }
    }

    logger.down();
    logger.log();

  }
  else
  {

    logger.log();
    logger.log( e.ca.vocabulary.helpForSubjectAsString( '' ) );
    logger.log();

    //logger.log( 'Use ' + logger.colorFormat( '"ts .help"', 'code' ) + ' to get help' );

  }

  return self;
}

// function _commandHelp( e )
// {
//   let ca = e.ca;
//
//   _.assert( arguments.length === 1 ); xxx
//
//   ca.logger.log( 'Commands to use' );
//   ca.onPrintCommands();
//
// }

//

function onGetHelp()
{
  let self = this;

  _.assert( arguments.length === 0 );

  // self.logger.log( self.vocabulary.helpForSubjectAsString( subjects[ 0 ] ) );
  // self.logger.log( '' );

  if( self.vocabulary.subjectDescriptorFor( '.help' ).length )
  {
    self.proceedAct({ command : '.help' });
  }
  else
  {
    self._commandHelp({ ca : self });
  }

}

//

function onPrintCommands()
{
  let self = this;

  _.assert( arguments.length === 0 );

  self.logger.log();
  self.logger.log( self.vocabulary.helpForSubjectAsString( '' ) );
  self.logger.log();

}

//

function _onPhraseDescriptorMake( src )
{

  _.assert(  _.strIs( src ) || _.arrayIs( src ) );
  _.assert( arguments.length === 1 );

  let self = this;
  let result = Object.create( null );
  let phrase = src;
  let executable = null;

  if( phrase )
  {
    _.assert( phrase.length === 2 );
    executable = phrase[ 1 ];
    phrase = phrase[ 0 ];
  }

  let hint = phrase;

  if( _.objectIs( executable ) )
  {
    _.assertMapHasOnly( executable, { e : null, h : null } );
    hint = executable.h;
    executable = executable.e;
  }

  result.phrase = phrase;
  result.hint = hint;

  if( _.routineIs( executable ) )
  {
    result.executable = executable;
  }
  else
  {
    result.executable = _.path.resolve( self.basePath, executable );
    _.sure( !!_.fileProvider.fileStat( result.executable ), () => 'Application not found at ' + _.strQuote( result.executable ) );
  }

  return result;
}

// --
//
// --

let Composes =
{
  basePath : null,
  commandPrefix : '',
  addingDelimeter : ' ',
  lookingDelimeter : _.define.own([ '.' ]),
  supplementingByHelp : 1,
}

let Aggregates =
{
  onGetHelp : onGetHelp,
  onPrintCommands : onPrintCommands,
}

let Associates =
{
  logger : null,
  commands : null,
  vocabulary : null,
}

let Restricts =
{
  _formed : 0,
}

let Statics =
{
}

let Forbids =
{
}

let Accessors =
{
}

let Medials =
{
}

// --
// prototype
// --

let Proto =
{

  init : init,
  form : form,
  _formVocabulary : _formVocabulary,
  exec : exec,
  proceedApplicationArguments : proceedApplicationArguments,
  proceedAct : proceedAct,

  commandsAdd : commandsAdd,

  _commandHelp : _commandHelp,
  onGetHelp : onGetHelp,
  onPrintCommands : onPrintCommands,
  _onPhraseDescriptorMake : _onPhraseDescriptorMake,

  //

  Composes : Composes,
  Aggregates : Aggregates,
  Associates : Associates,
  Restricts : Restricts,
  Medials : Medials,
  Statics : Statics,
  Forbids : Forbids,
  Accessors : Accessors,

}

//

_.classDeclare
({
  cls : Self,
  parent : Parent,
  extend : Proto,
});

_.Copyable.mixin( Self );

//

_[ Self.shortName ] = Self;
if( typeof module !== 'undefined' && module !== null )
module[ 'exports' ] = Self;

})();
