# altcalconv
Alternative function calling conventions for use in bash

## classical calling convention in bash

Classically, Both `functions` and `programs` in bash are `commands` that accept input and produce output in pretty much the same way. There are alternatives to this, but this is how it generally works:

    (returnCode,stdout,stderr) = command(args,stdin,env)

## Program inputs

### arguments

You may feed arguments to the command. For example, you may feed the `-l` argument to the `ls` program:

    $ ls -l
    total 28
    -rw-r--r-- 1 ontop ontop 3438 May 25 13:46 altcalconv.sh
    ...

The argument `-l` tells the `ls` program to use the long format for files and subfolders, and to display privileges and ownership for them.

### stdin

You may feed an input stream to the command. For example:

    $ echo hello | sed 's/ll/xx/'
    hexxo

We feed the `hello` string as a stream to the `sed` command, asking it to replace the characters 'll' by 'xx' in its input.

### env

You may feed environment variables to the command. For example:

    $ myvar=12 echo "whatever: $myvar"
    whatever: 12

By feeding the environment variable `myvar` to the echo command, it will be able to resolve its value and use it inside the program.


## Program outputs



