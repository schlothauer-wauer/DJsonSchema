# DJsonSchema
[JSON Schema](http://json-schema.org/) draft v4 reader and code generator for Delphi.

## Features

- command line tool for generation of boilerplate code to read JSON documents
- JSON Schema draft v4 is only partially supported
- Support for [Mustache](https://mustache.github.io/) templates

## Usage

```
djsonsgen.exe <json_schema> <template_dir> [options]

<json_schema>                    - JSON Schema file
<template_dir>                   - Template source directory
[-o<path>], [/output_dir:<path>] - Output directory (default = use json_schema
                                   filename as directory)
```

**Example:** `djsonsgen.exe draft-04-schema.json .\templates`

## Compilation/Contribution

These are the requirements if you want to compile the project for own purposes or if you like to contribute to this project:

- Project is written with *Delphi 10.1* (no idea what the minimum required version is) 
- [SynMustache](https://github.com/synopse/dmustache) is used as *Mustache* template engine
