# tmux-weather
Thanks to our great sponsor Yahoo!, who thankfully blocked original
powerline-based tmux-weather plugin, I wrote down another tmux-weather
plugin that runs with public(free) APIs, wasting my precious weekend
at Mar. 27, 2016. 


### Installation with [Tmux Plugin Manager](https://github.com/tmux-plugins/tpm) (recommended)

Add plugin to the list of TPM plugins in `.tmux.conf`:

    set -g @plugin 'forkjoseph/tmux-weather'

Hit `prefix + I` to fetch the plugin and source it. You should now be able to
use the plugin.

Optional (but recommended) install `gawk` via your package manager of choice
for better UTF-8 character support.

### Manual Installation

Clone the repo:

    $ git clone https://github.com/forkjoseph/tmux-weather ~/clone/path

Add this line to the bottom of `.tmux.conf`:

    run-shell ~/clone/path/weather.tmux

Reload TMUX environment with: `$ tmux source-file ~/.tmux.conf`. You should now
be able to use the plugin.

Optional (but recommended) install `gawk` via your package manager of choice
for better UTF-8 character support.

<!--
### Limitations

This plugin has some known limitations. Please read about it
[here](docs/limitations.md).
-->

### Docs

- Most of the behavior of tmux-copycat can be customized via tmux options.
  [Check out the full options list](docs/customizations.md).
- To speed up the workflow you can define new bindings in `.tmux.conf` for
  searches you use often, more info [here](docs/defining_new_stored_searches.md)

### Other goodies

`tmux-copycat` works great with:

- [tmux-battery](https://github.com/forkjoseph/tmux-battery) - battery status 

You might want to follow [@forkjoseph](https://twitter.com/forkjoseph) on
twitter if you want to hear about new tmux plugins or feature updates.

<!--
### Test suite

This plugin has a pretty extensive integration test suite that runs on
[travis](https://travis-ci.org/forkjoseph/tmux-weather).

When run locally, it depends on `vagrant`. Run it with:

    # within project top directory
    $ ./run-tests

By default tests run in 2 vagrant VMs: ubuntu and centos.
-->

### Contributions and new features

Bug fixes and contributions are welcome.

Feel free to suggest new features, via github issues.

If you have a bigger idea you'd like to work on, please get in touch, also via
github issues.

### License

[GNU](LICENSE.md)
