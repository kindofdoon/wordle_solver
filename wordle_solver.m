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
    % 2022-01-11
    
    %%
    
    clear
    clc
    
    %% Inputs
    
    word_length = 5;  % number of letters in the word to be guessed
    rand_show   = 25; % number of random valid words to show after every guess
    dict_source = 'C:\Users\ddichter\Desktop\personal\wordle_solver\words_alpha.txt'; % dictionary
    
    %% Load dictionary
    
    dict_word = importdata(dict_source);
    dict_word_length = zeros(length(dict_word),1);
    for w = 1 : length(dict_word)
        dict_word_length(w) = length(dict_word{w});
    end
    ind_valid_length = find(dict_word_length == word_length);
    
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
                    % Eliminate words that contain this letter
                    for w = 1 : length(List)
                        if length(regexprep(List{w}, letter, '')) ~= word_length
                            to_eliminate(w) = 1;
                        end
                    end
                    
                case 'y'
                    % Eliminate words that contain this letter in this position
                    for w = 1 : length(List)
                        if strcmp(List{w}(ind), letter)
                            to_eliminate(w) = 1;
                        end
                    end
                    
                    % Eliminate words that do not contain this letter
                    for w = 1 : length(List)
                        if length(regexprep(List{w}, letter, '')) == word_length
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













































