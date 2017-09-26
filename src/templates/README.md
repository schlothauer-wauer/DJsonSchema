# DJsonSchema templates

DJsonSchema uses *Mustache* as template engine so you can modifiy the existing ones or write you own templates.

- [Mustache](http://mustache.github.io/) - Logic-less templates
- [Introduction to Mustache syntax](http://blog.synopse.info/post/2014/04/28/Mustache-Logic-less-templates-for-Delphi-part-2)

## Template files

- The given template directory will be scanned for template files with the format `{*}.pas`.
- Single curly braces will just be removed, so you will get the file `JsonHelper.pas` for `{JsonHelper}.pas` in the output directory.
- Double curly braces are indicators for Mustache *template markers* and will be parsed by the Mustache engine, so the file name `{{class.unit}}.pas` will be evaluated to `Draft_04_schema.pas` if the name of the input JSON Schema file would be `draft-04-schema.json`.
