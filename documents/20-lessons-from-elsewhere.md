# Lessons from Elsewhere

Amid this sea of machine-generated text, this page is just human prose.

The aim here is to gather notes from lessons learned elsewhere, and condense.
In the end, this turn into new prompts to feed into the machine.

Learned:

* Make the compiler a first-class directly visible object.
* Make the preprocessor(?) a first-class directly visible object.


Problems:

1. Preprocessor
    * external libraries (#include)
    * macros (#define with arguments)
    * builtins (__LINE__, __FILE__, etc.)
    * tricks
2. Compiler
    * #pragma
    * builtins (compiler query and control)

Discussions:

Macros in C are a function of the preprocessor.
This is a bit unfortunate as it does not allow for community experimentation.
In the Lisp community, you wrote macros in Lisp, and so there was a lot of experiments.



## Lessons from C2




## TODO - read and summarize

1. Macros and C2

## See also
