% function format_wordle_game

    % The purpose of this function is to take plain-text-formatted Wordle
    % games, and reformat them for LaTeX documents
    
    %%

    clear
    clc
    
    fn_log = 'format_wordle_game_input.txt';
    
    %%
    
    log = regexp(fileread(fn_log), '\r?\n', 'split')';
    log = [log{:}]; % concatenate everything together
    tok = regexp(log, '([0-9]+)([a-z]{5}) - ([kyg]{5})', 'tokens')';
    
    %%

    output = cell(size(tok,1),1);
    
    prefix = '\noindent \vspace{0 mm} \texttt{\textcolor{white}{\textbf{';

    for line = 1 : size(tok,1)
        
        output{line} = prefix;
        
        for tile = 1 : length(tok{1}{2})
            
            output{line} = [output{line} '\colorbox{' tok{line}{3}(tile) '}{' upper(tok{line}{2}(tile)) '}\hspace{1 mm}'];
            
        end
        
        output{line} = [output{line} '}}}'];
        output{line} = [output{line} ' & ' tok{line}{1}];
        output{line} = [output{line} '\\'];
        
    end

% end