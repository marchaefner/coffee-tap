#!/bin/env coffee

DEFAULT_PARSER_MODULE = './'

# Module functionality
# --------------------
flatten = (arr, result = []) ->
  for item in arr
    if item.length?
    then flatten item, result
    else result.push item
  result

LOCATION_COLUMN = '             '
LOCATION_ERROR  = '<no location>'
TOKEN_COLUMN    = '               '

formatLocationColumn = (locationData) ->
  return LOCATION_ERROR unless locationData?
  {first_line, first_column, last_line, last_column} = locationData
  location = "#{first_line+1}:#{first_column+1}"
  if last_line != first_line or first_column != last_column
    location += "-#{last_line+1}:#{last_column+1}"
  location += LOCATION_COLUMN.substring(location.length)

exports.formatTokens = formatTokens = (tokens) ->
  (for token in tokens
    line = [
      formatLocationColumn token[2]
      token[0] + TOKEN_COLUMN.substring token[0].length
    ]

    if token[0] in [
          'IDENTIFIER', 'NUMBER', 'STRING', 'UNARY', 'BOOL', 'MATH', 'COMPARE',
          'COMPOUND_ASSIGN']
      line.push token[1].toString().replace /\n/, '\\n'

    if token.generated or token.explicit
      line.push '(generated)'

    line.join(' ')
  ).join('\n')

exports.formatNodes = formatNodes = (node, parts=[], prefix='', is_last) ->
  isRoot = !parts.length
  nodeName = node.constructor.name

  parts.push formatLocationColumn node.locationData
  unless isRoot
    parts.push prefix
    if is_last
        parts.push  ' └─ '
        prefix +=   '    '
    else
        parts.push  ' ├─ '
        prefix +=   ' │  '
  parts.push nodeName
  parts.push '?' if node.soak
  parts.push switch nodeName
    when 'Literal'  then ' "'+node.value+'"'
    when 'Op'       then ' "'+node.operator+'"'
    when 'In'       then node.negated and ' (negated)' or ''
    else ''

  children = []
  for attrName in node.children ? [] when node[attrName]
    children.push (flatten [node[attrName]])...
  last_index = children.length-1
  for child, i in children
    parts.push '\n'
    if child?
      formatNodes child, parts, prefix, i is last_index

  return parts.join('') if isRoot


# CLI stuff
# ---------
if require.main is module
  banner = 'Token and AST Printer for CoffeeScript'
  usage = """
    Usage: tap.coffee (nodes|tokens|lex) [-l] [-m MODULE] [source.coffee]

      nodes       Print out the parse tree.
      tokens      Print out the tokens lexer and rewriter produce.
      lex         Print out the (unrewritten) tokens that the lexer produces.
      -l          Treat source as literate code.
      -m MODULE   Parser module from which to get tokens or nodes.
                  (Defaults to '#{DEFAULT_PARSER_MODULE}')

      If no source file is supplied, stdin will be used.
  """

  opts =
    command:  null
    literate: no
    module:   null
    fileName: null

  readCommandLine = ->
    args = process.argv[(process.argv.indexOf(__filename) + 1 or 2)...]
    return banner unless args
    while arg = args.shift()
      if arg[i=0] is '-'
        while shortOpt = arg[i+=1]
          if      shortOpt is 'l'   then opts.literate = yes
          else if shortOpt in 'h?'  then return banner
          else if shortOpt is 'm'
            opts.module = arg[i+1...] or args.shift()
            break
          else return 'Unknown option.'
      else if not opts.command
        if (arg = arg.toLowerCase()) in ['nodes', 'tokens', 'lex']
        then opts.command = arg
        else return 'Unknown or missing command.'
      else if not opts.fileName
        opts.fileName = arg
      else
        return 'o_O ? These options confuse me.'
    opts.module ?= DEFAULT_PARSER_MODULE
    return 'Missing command.' unless opts.command

  readFile = (cb) ->
    (require 'fs').readFile opts.fileName, (err, code) ->
      die err.message if err
      cb String code

  readStdin = (cb) ->
    code = ''
    stdin = process.openStdin()
    stdin.on 'data',  (buffer) -> code += buffer.toString() if buffer
    stdin.on 'end',   -> cb String code

  getSource = (cb) -> if opts.fileName then (readFile cb) else (readStdin cb)

  die = (msg) ->
    console.error 'Failed: ' + msg
    process.exit 1

  # ### main ### #

  if msg = readCommandLine()
    console.log msg + '\n\n' + usage
    process.exit 1

  CoffeeScript = require opts.module

  CSOptions =
    filename: opts.fileName or '[stdin]'
    literate: opts.literate or /\.(litcoffee|coffee\.md)\s*/.test opts.fileName
    rewrite:  opts.command isnt 'lex'

  getSource (source) ->
    try
      if opts.command is 'nodes'
        console.log formatNodes CoffeeScript.nodes source, CSOptions
      else
        console.log formatTokens CoffeeScript.tokens source, CSOptions
    catch ex
      die ex.message if ex instanceof SyntaxError
      throw ex
