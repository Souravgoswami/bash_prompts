To compile this file, you need MRuby compiled with UTF-8 support, and GCC.

Compile with this:

```
$ gcc bash_prompt.mruby.c -lm -I ~/mruby/include/ ~/mruby/build/host/lib/libmruby.a -o ~/.bash_prompt_lite
$ strip --strip-unneeded ~/.bash_prompt_lite
```

Once the file is compiled, you're free to remove MRuby and GCC.
You're left with an executable called .bash_prompt_lite in your $HOME directory.
You can execute the binary to see a bash prompt output.

Execute:

```
$ ~/.bash_prompt_lite
```

Using in .bashrc as PS1:

```
PS1="\$(~/.bash_prompt_lite)"
```

In any case, if you've trouble, you can get a binary from the Binary/ directory.