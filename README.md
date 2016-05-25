# altcalconv
Alternative function calling conventions for use in bash

## 1. Classical calling convention in bash

Classically, Both `functions` and `programs` in bash are `commands` that accept input and produce output in pretty much the same way. There are alternatives to this, but this is how it generally works:

    (returnCode,stdout,stderr) = command(args,stdin,env)

## 1.1. Program inputs

### 1.1.1. arguments

You may feed arguments to the command. For example, you may feed the `-l` argument to the `ls` program:

    $ ls -l
    total 28
    -rw-r--r-- 1 ontop ontop 3438 May 25 13:46 altcalconv.sh
    ...

The argument `-l` tells the `ls` program to use the long format for files and subfolders, and to display privileges and ownership for them.

### 1.1.2. stdin

You may feed an input stream to the command. For example:

    $ echo hello | sed 's/ll/xx/'
    hexxo

We feed the `hello` string as a stream to the `sed` command, asking it to replace the characters 'll' by 'xx' in its input.

### 1.1.3. env

You may feed environment variables to the command. For example:

    $ myvar=12 echo "whatever: $myvar"
    whatever: 12

By feeding the environment variable `myvar` to the echo command, it will be able to resolve its value and use it inside the program.


## 1.2. Program outputs

### 1.2.1. return code

The program will terminate with an integer value. Conventionally, this will either be 0 in case of success, and 1,2, or another non-zero integer value in case of failure. In the following example, we see that the `grep` program returns 0 when it has found a particular pattern in its search:

    $ grep transmit altcalconv.sh ; echo "returned: $?"
    function transmit {
    returned: 0


The return code of the last command executed is available in the variable `$?`. In case, it cannot find the pattern, it returns 1:

    $ grep alan altcalconv.sh ; echo "returned: $?"
    returned: 1

### 1.2.2. stdout

The normal output stream for the program is `stdout`. For example, the `echo` command will output its arguments to `stdout`:

    $ echo hello
    hello

### 1.2.3. stderr

The error messages for the program go to `stderr`. For example, when `ls` cannot find a file, it will output:

    $ ls some-file-not-there.txt ; echo "returned: $?"
    ls: cannot access some-file-not-there.txt: No such file or directory
    returned: 2
 
Note that both `stdout` and `stderr` are dumped into the terminal. So, you tend to see both intermixed, even though they are separate streams. If we mute `stderr`, you can see:

    $ ls some-file-not-there.txt 2> /dev/null ; echo "returned: $?"
    returned: 2

### 1.3. Processing the output of a command

One not so good but widespread habit in shell programming, is to forget looking at the return code for a command and to handle errors. Many shell scripts just continue with the next command if an error has occurred. Quite often, success of the previous command was really needed for the next command; otherwise, why execute such command, if it does not matter than it went right? 

Outside programs, even on different systems could execute a command and desire to know what in what status it ended up:

    command arg arg ...
    if ! success; then
        handleError errorMessage
    fi
    nextCommand arg arg ...
    nextCommand arg arg ...

In case of success, the program should just continue and use the command's output. In case of failure, it should take a different route and use the command's error message on stderr.

## 2. Simultaneously capturing all output

### 2.1. The capture function

In order to facilitate program behaviour that effectively handles error conditions, we can use the `capture` function:

#!/usr/bin/env bash

```bash
source altcalconv.sh

function mycommand {
    echo "whatever $1 to stdout"
    stderr "whatever $1 to stderr"
    return 42
}

source <(capture ret out err := mycommand "hello friends")

echo "ret:$ret out:$out err:$err"
```
    output:
    ret:42 out:mycommand hello friends to stdout err:mycommand hello friends to stderr

The `capture` function will capture the output of `mycommand "hello friends"` into three variables of which you can choose the names.

The expression:

    source <(capture ret out err := mycommand "hello friends")

and:

    eval $(capture ret out err := mycommand "hello friends")

are equivalent. However, the `eval` version will produce better error messages in case of issues.

But then again, since the Church of the Anti-Eval Fanatics insist that eval is evil, and since they have never successfully managed to demonize the source command too (that would probably be another church with another doctrine), you may still want to use source instead of eval, and in that way avoid embarrassing accusations of heresy.

### 2.2. Injecting local versus global variables

In the following example, the capture function will inject local variables in a function, instead of global ones:

    function myfunction {

        source <(capture local returnCode output errors := mycommand "hello friends")

        if equal $returnCode 0 ; then
            echo "success"
            echo "this is the output: $output"
        else
            echo "failure, these are the error messages: $errors"
        fi        

    }

Note that bash does not allow the use the keyword `local` outside function bodies. Therefore, injecting local variables in the global namespace will lead to an error message.

## 3. A more traditional calling convention

### 3.1. The assign and transmit functions

Sometimes, you may wish that you could use a more traditional way of using functions in Bash. The `transmit` and `assign` combo allows you to do example that:

```bash
#!/usr/bin/env bash

source altcalconv.sh

function func2 {
    transmit 4 3 12 $(((99+$1)))
}

eval $(assign x1 x2 x3 x4 := func2 53)

echo "x1:$x1 x2:$x2 x3:$x3 x4:$x4"

```
    output:
    x1:4 x2:3 x3:12 x4:152


You can obviously also use the alternative syntax using process substitution:

    source <(assign x1 x2 x3 x4 := func2 53)

This transmission mechanism simulates how other programming languages return results from the function called, the callee, to the caller. The transmit function creates a (temporary) stack, and pushes the values transmitted onto this stack. The assign function pops these results from the stack, assigns them to the variables mentioned, and then clears the stack.

### 3.2. Injecting local versus global variables

The assign function can also inject local variables instead of global ones. For example:

    function myfunction {

        eval $(assign local x1 x2 x3 x4 := func2 53)

    }


