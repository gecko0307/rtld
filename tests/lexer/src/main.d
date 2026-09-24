module main;

import rtld;

int main()
{
    string[] delimiters =
    [
        "(", ")", ";", " ", "{", "}", ".", "\n", "\r", "=", "++", "<"
    ];
    auto input = "for (int i=0; i<arr.length; ++i)\r\n{doThing();}\n";
    
    Lexer lexer;
    lexer.ignoreWhitespaces = true;
    lexer.ignoreNewlines = true;
    lexer.start(input, delimiters);
    
    Array!string tokens;
    while(true)
    {
        auto lexeme = lexer.getLexeme();
        if (lexeme.length == 0)
            break;
        tokens.append(lexeme);
    }
    
    printLn(tokens.data);

    return 0;
}
