module ceasttools;

import
    core.memory;
import
    std.array, std.getopt, std.stdio, std.path, std.algorithm;
import
    iz.memory;
import
    dparse.lexer, dparse.parser, dparse.ast, dparse.rollback_allocator;
import
    common, todos, symlist, imports, mainfun, runnableflags;


private __gshared bool storeAstErrors = void, deepSymList = true;
private __gshared const(Token)[] tokens;
private __gshared Module module_ = void;
private __gshared static Appender!(ubyte[]) source;
private __gshared RollbackAllocator allocator;
private __gshared LexerConfig config;
private __gshared static Appender!(AstErrors) errors;
private __gshared string[] files;


static this()
{
    GC.disable;
    source.reserve(1024^^2);
    errors.reserve(32);
}

void main(string[] args)
{
    version(devel)
    {
        mixin(logCall);
        File f = File(__FILE__, "r");
        foreach(buffer; f.byChunk(4096))
            source.put(buffer);
        f.close;
    }
    else
    {
        foreach(buffer; stdin.byChunk(4096))
            source.put(buffer);
    }

    if (args.length > 2)
        files = args[1].splitter(pathSeparator).array;

    config = LexerConfig("", StringBehavior.source, WhitespaceBehavior.skip);
    StringCache cache = StringCache(StringCache.defaultBucketCount);
    tokens = getTokensForParser(source.data, config, &cache);

    getopt(args, std.getopt.config.passThrough,
        "d", &deepSymList
    );

    getopt(args, std.getopt.config.passThrough,
        "i", &handleImportsOption,
        "m", &handleMainfunOption,
        "r", &handleRunnableFlags,
        "s", &handleSymListOption,
        "t", &handleTodosOption,
    );
}

void handleSymListOption()
{
    mixin(logCall);
    bool deep;
    storeAstErrors = true;
    parseTokens;
    listSymbols(module_, errors.data, deepSymList);
}

void handleTodosOption()
{
    mixin(logCall);
    const(Token)[]*[] tokensArray;
    if (tokens.length)
        tokensArray ~= &tokens;

    import std.file: exists;
    if (files.length)
    {
        StringCache cache = StringCache(StringCache.defaultBucketCount);
        foreach(fname; files)
            if (fname.exists)
        {
            try
            {
                File f = File(fname, "r");
                ubyte[] src;
                foreach(buffer; f.byChunk(4096))
                    src ~= buffer;
                //tokensArray ~= getTokensForParser(src, config, &cache);
                f.close;
            }
            catch (Exception e) continue;
        }
    }
    getTodos(tokensArray);
}

void handleRunnableFlags()
{
    mixin(logCall);
    getRunnableFlags(tokens);
}

void handleImportsOption()
{
    mixin(logCall);
    storeAstErrors = false;
    parseTokens;
    listImports(module_);
}

void handleMainfunOption()
{
    mixin(logCall);
    storeAstErrors = false;
    parseTokens;
    detectMainFun(module_);
}

void handleErrors(string fname, size_t line, size_t col, string message, bool err)
{
    if (storeAstErrors)
        errors ~= construct!(AstError)(cast(ErrorType) err, message, line, col);
}

void parseTokens()
{
    mixin(logCall);
    if (!module_)
        module_ = parseModule(tokens, "", &allocator, &handleErrors);
}

version(devel)
{
    version(none) import std.compiler;
    version(all) import std.uri;
    mixin(q{import std.c.time;});

    //TODO: something
}
