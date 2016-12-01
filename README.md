# reality-generators

[![Build Status](https://secure.travis-ci.org/realityforge/reality-generators.png?branch=master)](http://travis-ci.org/realityforge/reality-generators)

A basic toolkit for abstrcting the generation of files from model objects. These classes
were extracted from several existing toolkits, primarily [Domgen](https://github.com/realityforge/domgen).
All of these toolkits have mechanisms for constructing model objects that were then passed to
the generators framework that generated one or more files from the model object.

The framework consists of the following elements:

## TemplateSets

A `TemplateSet` is a named container for templates. It also declares dependencies on other `TemplateSet`
instances and provides a description.

## Templates

Templates are the basic element of the framework. They take a model object and emit one or more files
from the model object. There are different types of templates based on the technology used to perform
the generation. These templates types included in the base framework include;

* `ErbTemplate` - Output is generated using an `ERB` template. The model object is supplied as an instance
  method in the templates context.
* `RubyTemplate` - Output is generated by loading a ruby file to define a module and calling a method 
  supplying the model object as a parameter. The method returns the file contents as a string.

Templates are typically defined as rules such as; all models of a particular type, matching a particular
criteria should generate files using template X. Templates typically configure these other characteristics
but these vary based on the particular template type but commonly include:

* `target` - A short name that selects the type of model objects against which template should
  run. See below for more details.
* `guard` - A snippet of ruby code that is evaluated to determine whether the template should run
  on a particular model object instance.
* `facets` - A list of `facets` that must be enabled on the model object instance for the template
  to be applied. This is in effect a standardized `guard`. Almost all templates will define a list
  of required `facets` but very few will supply a custom `guard` so that the `facets` attribute 
  is just shorthand for a common pattern.
* `output_filename_pattern` - A ruby string that is evaluated to determine the output filename for
  a particular model object instance. This is only applicable for templates that generate a single file.
* `target` - A short name that selects the type of model objects against which template should
  run. See below for more details.
* `template_filename` - The filename of the file that template loads if it loads one. 

## Targets

Targets define the type of model objects that a template can be applied to. The target type is defined
using a `Symbol` or `String` and not a classname and these are typically short, semantic names that make
sense in the host framework. i.e. Targets names may include concepts such as `:entity`, `:attribute`
`:component` etc. It is typically the responsibility of the host framework to ensure that the correct
model objects are passed to the template.

The target name is also used as the name under which the model object is bound. This is used when evaluating
`output_filename_pattern` or `guard` as well as in templates like `erb` templates.

## Helpers

A `Helper` is simply a module that is mixed into the rendering context when evaluating attributes such
as `output_filename_pattern` or `guard` as well as in templates like `erb` templates. Helpers are a useful
mechanism for extracting complex or duplicated code from multiple templates.
