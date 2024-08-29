# HW_LFA

Flex lexer for Markdown files.

## Implementation

The main idea of the solution consists of parsing the input text step by step. For each important element in the text (list, emphasis element, paragraph, etc.), there is a state that governs that respective element (LIST, CODE_BL, etc.).

For each text element, the aim was to handle special cases (an example would be the situation where a setext header is not correct due to the number of - or =).

Moreover, in the case of lists, the difficulty was related to summarizing the elements inside, obviously, it was chosen to design intermediate states for easier processing of these elements (PREP_LIST, PREP_LIST_DECISION, etc.).

An important element of the implementation is CONSUME, this state allows step-by-step summarization of important elements that are after a punctuation mark (other than comma) as it uses logic / reasoning together with the DECISION state. If, for example, the character '.' is encountered, then CONSUME will eliminate it and activate the DECISION state to continue parsing the text given in the input file. This step-by-step parsing algorithm is also used in the case of lists (as code blocks can appear inside).

When it comes to images, lists, links, their form in the text is first tested with the help of analysis states (if the form is correct, there are cases where the yyless() function is called to properly process the current candidate).

Another delicate situation was summarizing a paragraph in the context of a list element because, depending on indentation, that paragraph may or may not be part of that element.

I chose to slightly personalize the example received in the statement (the test files are test1 and test2).

The platform used is Linux (with Ubuntu distribution).

Some references:
https://daringfireball.net/projects/markdown/syntax
https://en.wikipedia.org/wiki/Markdown
https://manpages.debian.org/testing/flexc++/flexc++input.7.en.html
