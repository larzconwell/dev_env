call plug#begin("~/.vim/plugins")

Plug 'dracula/vim', { 'as': 'dracula' }

" Behavior
Plug 'tpope/vim-sleuth'
Plug 'spf13/vim-autoclose'
Plug 'myusuf3/numbers.vim'
Plug 'vim-scripts/restore_view.vim'
Plug 'alvan/vim-closetag'
Plug 'vim-airline/vim-airline'
Plug 'dense-analysis/ale'

if $SYS_ENV == 'work'
    Plug 'prettier/vim-prettier', { 'do': 'yarn install --frozen-lockfile --production' }
endif

" Syntax
Plug 'pangloss/vim-javascript'
Plug 'leshill/vim-json'
Plug 'fatih/vim-go'
Plug 'kchmck/vim-coffee-script'
Plug 'cespare/vim-toml'
Plug 'rust-lang/rust.vim'
Plug 'PProvost/vim-ps1'
Plug 'NoahTheDuke/vim-just'

call plug#end()
