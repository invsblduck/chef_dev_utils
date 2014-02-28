# Attribute Mapping Scripts

Really filthy scripts to help me figure out which RCB attributes may translate
to StackForge attributes.

## Quick Start

```
$ ./scope_common.sh ./stackforge/openstack-common/attributes/default.rb
$ vim stack_common_scoped.rb  # edit resulting file to defang further

$ cp ./rcbops/cookbooks/glance/attributes/default.rb  glance.rb
$ cp ./stackforge/openstack-image/attributes/default.rb  image.rb
$ ./scope_munge.sh glance.rb image.rb
$ vim rpc_glance_scoped.rb stack_image_scoped.rb  # defang things

$ ./map.rb rpc_glance_scoped.rb stack_image_scoped.rb --regex
$ vim rpc_glance  # finalize mappings based on SHERLOCK HOLMESING
```

## Scripts

### `map.rb`

Main ruby script to walk attribute hashes and print potential matches. It also
writes a file with results for the direct/obvious mappings.  You will have to
study the stdout chaos and then edit the mappings to finish the rest of the
not-so-obvious translations.

```
[duck@foo]$ ./map.rb --help
usage: ./map.rb [options] <file1_scoped> <file2_scoped>
    -d, --debug               Enable debugging output
    -r, --regex, --loose      Enable loose key matching
    -h, --help                This useless garbage
```

### `scope_common.sh`

This script reads the StackForge common attributes file and writes a new file
named `stack_common_scoped.rb`, which replaces all calls to `default[` with a
variable assignment to `@common`.  Edit the new file and remove all the calls
to `node[` (by converting it to a string or replacing with another value).

```
[duck@foo]$ ./scope_common.sh 
usage: scope_common.sh <sf_common_attrs_file>

example:
    $ scope_common.sh ./stackforge/openstack-common/attributes/default.rb
```

### `scope_munge.sh`

This script reads an RPC attributes file and an equivalent StackForge
attributes file and writes 2 new files named `rpc_<foo>_scoped.rb` and 
`stack_<bar>_scoped.rb`. It replaces all calls to `default[` with variable
assignments to `@hash1` in the first file and `@hash2` in the second file.
Edit both new files and remove all the calls to `node[` (by converting it to a
string or replacing with another value).

```
[duck@foo]$ ./scope_munge.sh 
usage: scope_munge.sh <file1> <file2>

where <file1> contains RPC attrs and <file2> contains coresponding SF attrs.

example:
    $ scope_munge.sh glance.rb image.rb

```

#### Usage tip:

TIP: Rename your *input* attribute files for `scope_munge.sh` to be named by
the cookbook.
Eg.,
```
$ cp ./rcbops/cookbooks/glance/attributes/default.rb  glance.rb
$ cp ./stackforge/openstack-image/attributes/default.rb  image.rb
```

This is because `scope_munge.sh` uses `basename(1)` to name the output files,
so you would always end up with `rpc_default_scoped.rb` and
`stack_default_scoped.rb` if you just pointed at the default files. \*shrug\*
