# altcalconv

Alternative function calling conventions for use in Bash

## 1. Classical calling convention in Bash

Both `functions` and `programs` in Bash are `commands` that accept input and produce output in pretty much the same way. There are alternatives to this, but this is how it generally works:

    (returnCode,stdout,stderr) = command(arguments,stdin,env)

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

    $ env DISPLAY=:0 xeyes

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
 
Note that both `stdout` and `stderr` are both dumped in the terminal. So, you tend to see both intermixed, even though they are separate streams. If we mute `stderr`, you can see:

    $ ls some-file-not-there.txt 2> /dev/null ; echo "returned: $?"
    returned: 2

### 1.3. Processing the output of a command

One not so good but widespread habit in shell programming, is to forget looking at the return code for a command or to forget to handle errors. Many shell scripts just continue with the next command if an error has occurred. Quite often, success of the previous command was really needed for the next command. Otherwise, why execute such command, if it does not matter that it went right? In that case, spare yourself the trouble and do not execute it at all, I would say.

Outside programs, even on different systems could execute a command and desire to know what in what status it ended up:

    command arg arg ...
    if ! success; then
        handleError errorMessage
    fi
    nextCommand arg arg ...
    nextCommand arg arg ...

In case of success, the program should just continue and use the command's output. In case of failure, it should take a different route and take into account the command's error message on stderr.

## 2. Simultaneously capturing all output

### 2.1. The capture function

In order to facilitate program behaviour that effectively handles error conditions, the `altcalconv.sh` script the `capture` function:

```bash
#!/usr/bin/env bash

source altcalconv.sh

function mycommand {
    echo "whatever $1 to stdout"
    stderr "whatever $1 to stderr"
    return 42
}

source <(capture ret out err := mycommand "hello friends")

echo "ret:$ret"
echo "out:$out"
echo "err:$err"

```
    output:
    ret:42
    out:mycommand hello friends to stdout
    err:mycommand hello friends to stderr

The `capture` function will capture the output of the `mycommand "hello friends"` command into three variables of which you can choose the names.

By the way, the expression:

    source <(capture ret out err := mycommand "hello friends")

and:

    eval $(capture ret out err := mycommand "hello friends")

are equivalent.

However, the `eval` version will produce better error messages in case of issues.

But then again, since the Church of the Anti-Eval Fanatics insist that `eval` is evil, while they have never successfully managed to also demonize the use of the `source` command (that would probably be another church with another doctrine), you may still want to use `source` instead of `eval`, and in that way avoid embarrassing accusations of heresy.

### 2.2. Injecting local versus global variables

In the following example, the capture function will inject local variables in a function, instead of global ones:

```bash
function myfunction {

    source <(capture local returnCode output errors := mycommand "hello friends")

    if equal $returnCode 0 ; then
        echo "success"
        echo "this is the output: $output"
    else
        echo "failure, these are the error messages: $errors"
    fi        

}
```

Note that Bash does not allow for the use the keyword `local` outside function bodies. Therefore, injecting local variables into the global namespace will lead to Bash reprimanding you.

## 3. A more traditional calling convention

### 3.1. The assign and transmit functions

Sometimes, you may wish that you could use a more traditional way of using functions in Bash. The `transmit` and `assign` combo allows you to do this. For example:

```bash
#!/usr/bin/env bash

source altcalconv.sh

function func2 {
    transmit 4 3 12 $(((99+$1)))
}

eval $(assign x1 x2 x3 x4 := func2 53)

echo "x1:$x1"
echo "x2:$x2"
echo "x3:$x3"
echo "x4:$x4"

```
    output:
    x1:4
    x2:3
    x3:12
    x4:152

You can obviously also use the alternative syntax, using process substitution:

    source <(assign x1 x2 x3 x4 := func2 53)

This function result transmission mechanism quite simulates how other programming languages return results from the callee to the caller.

The `transmit` function creates a (temporary) stack, and pushes the values transmitted onto this stack. The `assign` function pops these results from the stack, assigns them to the variables mentioned, and then clears the stack.

Of course, it does not simulate the practice in truly native programs to use CPU registers as the top locations of the stack, in order to speed up the calling convention.

Since the calling convention triangulates over exactly one global stack data structure, just like in the real world, it is not thread safe, just like in the real world, where each thread must also have its own stack.

By the way, contrary to popular belief, it is most likely possible to use threads in Bash. You could try with [ctypes.sh](https://github.com/taviso/ctypes.sh) to load the [pthread](http://man7.org/linux/man-pages/man7/pthreads.7.html) library, and use its functions to control your threads. If you intend to do that, you will have to modify the implementation of the altcalconv.sh `_pid()` function to take into account the thread identifier. From there on, it should be thread safe.

### 3.2. Injecting local versus global variables

The assign function can also inject local variables instead of global ones. For example:

```bash
function myfunction {

    eval $(assign local x1 x2 x3 x4 := func2 53)

}
```

### 4. Difference between functions and programs

Seen from the outside, an external program and a function look the same to their users. Unless you try to figure it out, you cannot know if a command has been implemented as a function or as an external program. The advantage of this policy is that programs and functions are (almost) perfectly interchangeable.

Therefore, the classical function calling convention in Bash certainly has its unique advantages.

A disadvantage of this policy is that functions in Bash do not work like functions in other programming languages.

At the basis, I very much like the classical policy, because it potentially allows for an error-handling style that is superior to traditional exception handling. The only problem is that you have to take tight control over the command's output, like with the `capture` function. If you don't do that, error handling could actually turn out to be worse than in an exception-handling context. So, the approach indeed has much better potential, but you will still have to make it happen.

Since everything revolves around processes in Bash, just like in the underlying OS itself, Bash has the advantage that it will automatically enlist all your machine cores to execute your program when it would be beneficial to do so. There is no need to use external libraries or commands to schedule co-routines or to spread the load across different CPUs.

Incessant process creation indeed causes overhead, but so does function call setup in other scripting languages. It is not that this would be for free either. Furthermore, in Bash, it is trivially easy to distribute processes across different machines across the internet. Instead of writing:

    command arg1 arg2 arg3 ...

Just write:

    ssh user@server command arg1 arg2 arg3 ...

I personally think that Bash is badly underrated.

I consider it to be a valid substitute for other scripting languages such as perl, python, php, lua, or javascript. For all practical purposes, its functions are first class. At its core, it uses a pure list notation: 

    command arg1 arg2 arg3 ...

allowing for nested expressions through the use of different types of parentheses: 

    command1 arg11 $(command2 arg21 arg22 arg23 ... ) arg13 arg14 ...

with the command substitution parenthesis type, `$()`, being clearly the most important one, since command output on `stdout` is rightfully considered to be the most important one.

Fixing Bash, is mostly a question of just adding a few sanitizing functions to bury its sometimes strange notational impurities behind a purer list notation, and to suppress unnecessary syntactic noise. For example, I do not use:

    if [ -z $string ] ; then
        ...
    fi

The standard bracketing is too noisy to my taste. Furthermore, I reject the conceptual burden of remembering what `-z` may mean. I just don't. I refuse to be bullied. Therefore, I have implemented a wrapper, that causes the code to look like this:

    if empty $string ; then
        ...
    fi

I prefer the looks of this notational purity. It is a quiet syntax, and self-evident for that matter. Unfortunately, the `then` keyword is not optional. It is mandatory, even though it is redundant. The language would be perfectly unambiguous without:

    if list 
        expression1
        expression2
        ...
    fi 

or:

    if list; expression1 ; expression2; ...; fi 

Therefore, the `then` keyword is one of the few unfortunate, mandatory impurities in the Bash language grammar.

Out of the box, the Euler notation typically in use in other scripting languages:

    f(x1,x2,x3)

Is much more noisy than the quiet list notation in use in Bash:

    f x1 x2 x3

Chaining function applications, is much cleaner in list notation than in Euler notation:

    g(f(x1,x2,x3))

versus:

    g f x1 x2 x3

or:

    g $(f x1 x2 x3)

if `g` happens to take more arguments than just a list, or if the arguments to `g` are generally supposed to be evaluated already.

Lots of issues can be solved just be prepending an additional function to the list. A typical incantation in Bash:

    command arg1 arg2 arg3 &> /dev/null

Can easily be made much quieter by implementing something like a `shutUp` function, and replace the expression above by:

    shutUp command arg1 arg2 arg3

Such `shutUp` function, that can also handle input on stdin, could look like this:

```bash
function shutUp {
    if test -s /dev/stdin ; then
        cat /dev/stdin | "$@" &> /dev/null
    else
        "$@" &> /dev/null
    fi
}
```

As you can see, the `shutUp` function concentrates syntactic noise that would otherwise just run loose in your own program. In fact, source code written in Bash can be very much sanitized to the point where only few notational impurities are left, along with the occasional unnecessary conceptual burden.

That can certainly produce a rather pleasantly quiet impression in Bash source code, in fact, much quieter than in other scripting languages, of which the noise of their Eulerian notation is fundamentally beyond repair.

Seeking to establish more notational purity in Bash, would certainly contribute to unleashing its amazing true potential.

