Evanesco
========

Evanesco is a plugin geared towards automatically clearing Vim's search
highlighting whenever the cursor moves or insert mode is entered.  It has a
feature set similar to [vim-oblique][] and I really just built this to scratch
an itch.  I ran into a lot of problems with vim-oblique and it seemed simpler to
re-implement the subset of the features that I actually use.

The only reason to use this plugin over vim-oblique is that it's arguably less
of a hack, doesn't have any plugin dependencies, and the code is significantly
smaller.

Installation
------------

* [Pathogen][]
    * `cd ~/.vim/bundle && git clone https://github.com/pgdouyon/vim-evanesco.git`
* [Vim-Plug][]
    * `Plug 'pgdouyon/vim-evanesco'`
* Manual Install
    * Copy all the files into the appropriate directory under `~/.vim` on \*nix or
      `$HOME/_vimfiles` on Windows

License
-------

Copyright (c) 2015 Pierre-Guy Douyon.  Distributed under the MIT License.


[vim-oblique]: https://github.com/junegunn/vim-oblique
[Pathogen]: https://github.com/tpope/vim-pathogen
[Vim-Plug]: https://github.com/junegunn/vim-plug
