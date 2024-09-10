# HW_LFA

## Implementation Overview

This project implements a Flex lexer for parsing Markdown files. The main approach involves step-by-step parsing of the input text, with dedicated states for each important Markdown element.

### Key Components

1. **State-Based Parsing**:
   - Each important Markdown element (list, emphasis, paragraph, etc.) has a corresponding state (LIST, CODE_BL, etc.).
   - Special cases are handled for each text element (e.g., incorrect setext headers).

2. **List Handling**:
   - Intermediate states (PREP_LIST, PREP_LIST_DECISION, etc.) are used for processing list elements.
   - Handles nested elements within lists, including code blocks.

3. **CONSUME State**:
   - Allows step-by-step summarization of important elements after punctuation marks (except commas).
   - Works in conjunction with the DECISION state to continue parsing.

4. **Analysis States**:
   - Used to test the correctness of images, lists, and links in the text.
   - Utilizes the `yyless()` function for proper processing of current candidates.

5. **Paragraph Summarization**:
   - Special handling for paragraphs within list elements, considering indentation.

6. **Customization**:
   - The implementation slightly personalizes the example provided in the assignment statement.

## Special Considerations

- Setext Headers: Checks for correct number of '-' or '=' characters.
- Lists: Handles nested elements and indentation.
- Images, Links: Verifies correct format before processing.
- Paragraphs in Lists: Determines inclusion based on indentation.

## Testing Environment

- Platform: Linux (Ubuntu distribution)
- Test Files: test1 and test2 (customized versions of the provided example)

## References

1. [Markdown Syntax](https://daringfireball.net/projects/markdown/syntax)
2. [Wikipedia: Markdown](https://en.wikipedia.org/wiki/Markdown)
3. [Flex++ Input Format](https://manpages.debian.org/testing/flexc++/flexc++input.7.en.html)
