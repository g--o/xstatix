## xStatix

a continuation of statix.sh (simple static site generator). unstable

the core script allows to make different static systems. each system should have it's own scripts and blocks that use xstatix. useful systems will be added to this repo in the examples directory. you're free to suggest your own in a pull request or issue.

## how to use

xstatix allows to write, edit and publish drafts. you can generate instructions and variables via command line.

e.g: set a var in a draft (edit)
`./xstatix.sh -s =@var=val -e draft`

for more info: `./xstatix.sh -h` and check out the examples directory.

## creating blocks - updated statix directives

- Include directive `<!--#include:other-template.html-->` allows including another block to reuse existing (HTML) code.
- Set directive `<!--#set:variable=some new value-->` allows setting a variable to the specific string value.
- Use directive: a bit different from <diff> convention the directives are:
	- `<!--=@variable-->` to insert a previously set variable value
	- `<!---@variable-->` to prepend previously set variable
	- `<!--+@variable-->` to append previously set variable