# Token and AST Printer for CoffeeScript

Easy and pretty parser introspection for your [coffee-script](https://github.com/jashkenas/coffee-script) fork.

```sh

    $ echo "console.log 'Hello World'" > hello.coffee

    $ ./tap.coffee tokens hello.coffee
    1:1-1:7       IDENTIFIER      console
    1:8           .
    1:9-1:11      IDENTIFIER      log
    1:11          CALL_START      (generated)
    1:13-1:25     STRING          'Hello World'
    1:25          CALL_END        (generated)
    1:26          TERMINATOR

    $ ./tap.coffee nodes < hello.coffee
    1:1-1:25     Block
    1:1-1:25      └─ Call
    1:1-1:7           ├─ Value
    1:1-1:7           │   ├─ Literal "console"
    1:8-1:11          │   └─ Access
    1:9-1:11          │       └─ Literal "log"
    1:13-1:25         └─ Value
    1:13-1:25             └─ Literal "'Hello World'"
```

How to use
----------
On the command line

 * Drop `tap.coffee` next to `package.json` or point to your coffee-script module with the `-m` option. (Or just change `DEFAULT_PARSER_MODULE` to your liking.)

 * Specify a file or use a pipe. (Use `-l` for literate code.)

As a module

```coffee

    CoffeeScript = require 'coffee-script'
    CoffeeTAP    = require './tap.coffee'
    console.log CoffeeTAP.formatNodes CoffeeScript.nodes source
```

But... why?
-----------

The CoffeeScript compiler itself offers rudimentary introspection (via `--nodes` and `--tokens` switches). Alas, this is not always good enough. `coffee-tap` brings these enhancements:

  * Show location data.
  * Option to print tokens as returned by the lexer (without rewrite).
  * Mark tokens added by the rewriter.
  * Overall prettiness.