[(self: super: {
  neovim =
    let myVimBundle = with super.vimPlugins; {
      start = [
        LanguageClient-neovim
        ncm2
        ncm2-bufword
        ncm2-ultisnips
        UltiSnips
      ];
    };
    in (super.neovim.override {
    vimAlias = true;
    withPython = true;
    configure = {
      customRC = '';
        if filereadable($HOME . "/.vimrc")
          source ~/.vimrc
        endif

        " enable ncm2 for all buffers
        autocmd BufEnter * call ncm2#enable_for_buffer()

        " IMPORTANT: :help Ncm2PopupOpen for more information
        set completeopt=noinsert,menuone,noselect

        let g:LanguageClient_serverCommands = {
          \ 'python': ['pyls'],
          \ }

        nnoremap <F5> :call LanguageClient_contextMenu()<CR>
        " Or map each action separately
        nnoremap <silent> K :call LanguageClient#textDocument_hover()<CR>
        nnoremap <silent> gd :call LanguageClient#textDocument_definition()<CR>
        nnoremap <silent> <F2> :call LanguageClient#textDocument_rename()<CR>
      '';
      packages.nixbundle = myVimBundle;
    };
  });
})]
