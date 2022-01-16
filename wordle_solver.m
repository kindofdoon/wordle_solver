% function wordle_solver

    % A simple computer program to solve the word-guessing game "Wordle",
    % located at https://www.powerlanguage.co.uk/wordle/
    
    % Starts with a complete dictionary and uses random guesses and process
    % of elimination to determine the solution. User must manually type in
    % their guess and the response after each round. Case-sensitive. Use
    % lower case.
    
    % Responses must use the following syntax:
        % 'k': gray, not in word
        % 'y': yellow, in word, but not in that spot
        % 'g': green, in word, in that spot
    
    % Daniel W. Dichter
    % 2022-01-11:
        % First version
    % 2022-01-16:
        % Revised to support words with multi-instance letters, e.g. WADED, DOORS, etc.
        % Swapped in a better dictionary with 4k 5-letter words (previously, 16k)
    
    %%
    
    clear
    clc
    
    %% Inputs
    
    word_length = 5;  % number of letters in the word to be guessed
    rand_show   = 25; % number of random valid words to show after every guess
    dict_source = 'C:\Users\Admin\Desktop\wordle\english_usa.txt';
    
    %% Load dictionary
    
    dict_word = importdata(dict_source);
    dict_length = zeros(size(dict_word,1),1);
    for w = 1 : length(dict_word)
        if isempty(regexprep(dict_word{w},'[a-z]','')); % skip non-valid words, e.g. with punctuation
            dict_length(w) = length(dict_word{w});
        end
    end
    
    ind_valid_length = find(dict_length == word_length);
    List = dict_word(ind_valid_length);
    
    %% Main body
    
    while length(List) > 1
        
        % Status update
        disp('============')
        disp(['Words remaining: ' num2str(length(List))])
        disp(' ')
        ind_show = randperm(length(List), min([length(List), rand_show]));
        for i = 1 : length(ind_show)
            disp(List{ind_show(i)})
        end
        disp('============')
        
        % Guess
        guess = input('Guess:    ','s');
        if length(guess) ~= word_length
            warning('Invalid length')
            continue
        end
        if length(find(strcmp(dict_word, guess))) ~= 1
            warning('Invalid word')
            continue
        end
        
        % Response
        response = input('Response: ','s');
        if length(response) ~= word_length
            warning('Invalid length')
            continue
        end
        if length(regexprep(response, '[kyg]', '')) > 0
            warning('Invalid response, must solely contain [kyg]')
            continue
        end
        
        % Eliminate all entries from the list that are not consistent with
        % the most recent guess/response pair
        
        to_eliminate = zeros(length(List),1);
        
        for ind = 1 : word_length % for each letter
            
            letter = guess(ind);
            
            switch response(ind)
                
                case 'k'
                    
                    response_match = response(find(guess == letter));
                    if length(regexprep(response_match, 'k', '')) == 0 % All tile(s) of this letter were gray
                        
                        % Eliminate all words that contain this letter
                        for w = 1 : length(List)
                            if length(regexprep(List{w}, letter, '')) ~= word_length
                                to_eliminate(w) = 1;
                            end
                        end
                        
                    else
                        
                        % This is a gray tile, but there are other tile(s)
                        % of either yellow or green of the same letter. We
                        % know that the solution does not contain this
                        % letter at this position.
                        
                        % Eliminate words that contain this letter in this position
                        for w = 1 : length(List)
                            if strcmp(List{w}(ind), letter)
                                to_eliminate(w) = 1;
                            end
                        end
                        
                    end
                    
                case 'y'
                    
                    % Eliminate words that contain this letter in this position
                    for w = 1 : length(List)
                        if strcmp(List{w}(ind), letter)
                            to_eliminate(w) = 1;
                        end
                    end
                    
                    % Eliminate words that do not contain this letter in non-green non-matching tiles
                    ind_search = intersect(find(response~='g'), find(guess~=letter));
                    for w = 1 : length(List)
                        if length(find(List{w}(ind_search) == letter)) == 0
                            to_eliminate(w) = 1;
                        end
                    end
                    
                case 'g'
                    
                    % Eliminate words that do not contain this letter in this position
                    for w = 1 : length(List)
                        if ~strcmp(List{w}(ind), letter)
                            to_eliminate(w) = 1;
                        end
                    end
                    
                otherwise
                    error('Unrecognized response')
                    
            end
            
        end
        
        % Eliminate words
        List = List(find(~to_eliminate));
        
    end
    
    if length(List) == 0
        error('Guesses did not converge')
    else
        disp('============')
        disp(['Solution: ' List{:}])
    end
    
% end













































