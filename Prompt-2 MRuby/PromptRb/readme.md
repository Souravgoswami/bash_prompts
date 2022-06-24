Do not run this file.
Use this as a reference to `bash_prompt.rb.h`

This file is intended to get compiled into C `char *`.
So the binary can be moved elsewhere without worrying.

To achieve that, you need to run:

```
$ ruby ruby_to_c_char*_converter.rb
```

It will dump the C String conversion from the Ruby string.
Copy the dumped content to `bash_prompt.rb.h` in the above directory.
