# Templates

This subdirectory contains plain text templates for miscellaneous file formats.

(This is always work in progress – the content of such files is naturally very arbitrary and always subject to change.)

## skeleton.sh

`skeleton.sh` is a bash script template. It is a fully running script with an example action.

### Features

  * a safe script initialization
  * simple colored output
  * checking of availability of commands necessary for the script
  * prepared command line argument handling including
    - usage help
    - script version
    - verbosity
  * creation of a temporary directory, which will be automagically cleaned up on script exit (also e.g. on pressing `<Ctrl-c>`)

#### Colored output

Use the `color <color>` function similar to `echo`:

`color blue 'Show some info.'`

does the same as 

`echo 'Show some info.'`

but prints the output in blue color.

See the `colors` array for supported colors.

#### Checking availability of commands

Add a call of

`check_cmd <my_cmd>`

to the `function check_necessary_commands`.

The check will be run, if the script is executed with options `-vh` or `-vvV`.

#### Temporary directory

To create one, call the `create_temp_directory` function. The path will be stored in `${temp_dir}`.
