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
    * `cd ~/.vim/bundle && git clone https://github.com/pgdouyon/vim-niffler.git`
* [Vim-Plug][]
    * `Plug 'pgdouyon/vim-niffler'`
* Manual Install
    * Copy all the files into the appropriate directory under `~/.vim` on \*nix or
      `$HOME/_vimfiles` on Windows

Known Bugs
----------

- Evanesco doesn't play well with the expression prompt (`:h c_ctrl-r_=`), any
  expression entered there is automatically appeneded to the search term and
  it's impossible edit the search query after leaving the expression prompt.
    - There are no plans to address this in the near future.
- Evanesco doesn't currently recognize mappings to <Esc>, though this should be
  fixed soon.


License
-------

Copyright (c) 2015 Pierre-Guy Douyon.  Distributed under the MIT License.


[vim-oblique]: https://github.com/junegunn/vim-oblique
[Pathogen]: https://github.com/tpope/vim-pathogen
[Vim-Plug]: https://github.com/junegunn/vim-plug
