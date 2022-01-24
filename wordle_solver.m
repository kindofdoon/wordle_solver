% function wordle_solver

    % A simple computer program to solve the word-guessing game "Wordle",
    % located at https://www.powerlanguage.co.uk/wordle/
    
    % Starts with a complete dictionary and uses statistically-informed
    % guesses and process of elimination to determine the solution. User
    % must manually type in their guess and the response after each round.
    % Case-sensitive - use lower case only.
    
    % Responses must use the following syntax:
        % 'k': gray, not in word
        % 'y': yellow, in word, but not in that spot
        % 'g': green, in word, in that spot
    
    % Daniel W. Dichter
    % daniel.w.dichter@gmail.com
    
    % Changelog:
        % 2022-01-11:
            % First version
        % 2022-01-16:
            % Revised to support words with multi-instance letters, e.g. WADED, DOORS, etc.
            % Swapped in a better dictionary with 4k 5-letter words (previously, 16k)
        % 2022-01-19:
            % Added suggestions of good guesses based on letter distribution
        % 2022-01-23:
            % Now makes optimized guesses against the dictionary (rather than
            % the set of possible words) for faster convergence. For 25 trials,
            % produced MEAN of 3.88 with STDEV of 0.88
    
    %%
    
    clear
    clc
    
    %% Inputs
    
    word_length = 5;  % number of letters in the word to be guessed
    qty_suggest = 10; % number of random valid words to show after every guess
    dict_source = 'C:\Users\Admin\Desktop\wordle\english_usa.txt';
    
    % AI parameters
    green_yellow_ratio = 2; % value_green / value_yellow, relative
    Gauss.stdev = 0.15;
    Gauss.mean  = 0.5;

    %% Constants
    
    alphabet = 'abcdefghijklmnopqrstuvwxyz';
    
    Gauss.res   = 1000;
    Gauss.prob  = linspace(0,1,Gauss.res);
    Gauss.val   = (1./(Gauss.stdev.*sqrt(2.*pi))) .* exp((-1/2).*((Gauss.prob-Gauss.mean)./Gauss.stdev).^2);
    Gauss.val([1,end]) = 0;
    Gauss.val = Gauss.val ./ max(Gauss.val(:));
    
    alpha_cell_array = cell(length(alphabet),1);
    for ind_letter = 1 : length(alphabet)
        alpha_cell_array{ind_letter} = alphabet(ind_letter);
    end
    
    divider = '=================================';
    
    %% Show probability vs. value curve
    
    figure(5)
        clf
        set(gcf,'color','white')
        plot(Gauss.prob, Gauss.val, 'k')
        grid on
        grid minor
        xlabel('Probability, ~')
        ylabel('Value, ~')
    
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
    
    Dict = List; % copy of the full dictionary
    
    %% Main body
    
    ind_round = 1;
    
    while length(List) > 1
        
        %% Show the probability distributions for remaining words
        
        PROB = zeros(length(alphabet), word_length);
        
        figure(1)
            clf
            set(gcf,'color','white')
            pos = get(gcf,'position');
            set(gcf,'position',[pos(1:2) 560 900])

        for ind_position = 1 : word_length

            letters = repmat(' ',[length(List),1]);
            for w = 1 : length(List)
                letters(w) = List{w}(ind_position);
            end
            qty_words = zeros(length(alphabet),1);
            for ind_letter = 1 : length(alphabet)
                qty_words(ind_letter) = length(find(letters == alphabet(ind_letter)));
            end
            PROB(:,ind_position) = qty_words ./ length(List); % normalize from counts to probabilities

            % Plot the result
            subplot(word_length,1,ind_position)
            cla
            bar(1:length(alphabet), PROB(:,ind_position), 'FaceColor', zeros(1,3)+0.5)
            grid on
            grid minor
            set(gca,'xtick',1:length(alphabet))
            set(gca,'xticklabel',alpha_cell_array)
            xlim([0 length(alphabet)+1])
            ylim([0 max(PROB(:))])
            title(['\rmProbability of ' num2str(length(List)) ' Valid ' num2str(word_length) '-Letter Words By Position #' num2str(ind_position) '\rm'])

        end
        
        %% Convert probabilities into values
        
        VAL = interp1(Gauss.prob, Gauss.val, PROB(:));
        [val_top, ind_top] = sort(VAL, 'descend');
        [row_top, col_top] = ind2sub(size(PROB),ind_top);
        VAL = reshape(VAL, size(PROB));
        
        figure(2)
            clf
            set(gcf,'color','white')
            pos = get(gcf,'position');
            set(gcf,'position',[pos(1:2) 560 900])

        for ind_position = 1 : word_length

            % Plot the result
            subplot(word_length,1,ind_position)
            cla
            bar(1:length(alphabet), VAL(:,ind_position), 'FaceColor', zeros(1,3)+0.5)
            grid on
            grid minor
            set(gca,'xtick',1:length(alphabet))
            set(gca,'xticklabel',alpha_cell_array)
            xlim([0 length(alphabet)+1])
            ylim([0 max(VAL(:))])
            title(['\rmValue of ' num2str(length(List)) ' Valid ' num2str(word_length) '-Letter Words By Position #' num2str(ind_position) '\rm'])

        end
        
        %%
        
        disp(divider)
        disp(['ROUND            ' num2str(ind_round)])
        disp(['Words remaining: ' num2str(length(List))])
        
        %% Score the dictionary
        
        Score_Dict = zeros(length(Dict),1);

        for w = 1 : length(Dict) % for each word
            
            for i = 1 : word_length % for each tile
                
                ind_alpha = find(Dict{w}(i) == alphabet);
                
                gain_pos    = ones(1,word_length);
                gain_pos(i) = green_yellow_ratio;
                
                ind_green = find(PROB(ind_alpha,:)==1);
                qty_green = length(ind_green); % number of green tiles with this letter
                
                % If we know the word contains a certain letter, we might
                % still want to guess it elsewhere in the word. However, it
                % might just come up yellow, telling us basically what we
                % already knew (no new information).
                if qty_green>=1 && PROB(ind_alpha,i)~=1
                    gain_pos = gain_pos ./ green_yellow_ratio;
                end
                
                qty_match     = length(find(Dict{w}(i) == Dict{w})); % number of tiles with this letter
                qty_non_green = qty_match - qty_green;
                qty_non_green = max([1 qty_non_green]); % enforce non-zero, non-negative
                
                % If we guess a tile that we already know is correct,
                % it adds no value to any position (including its own)
                if PROB(ind_alpha, i) ~= 1
                    Score_Dict(w) = Score_Dict(w) + dot(VAL(ind_alpha,:), gain_pos) / qty_non_green;
                end
                
            end
            
        end
        
        disp(' ')
        [~, ind_best_dict] = sort(Score_Dict,'descend');
        disp('Most valuable guesses (to advance):')
        disp(' ')
        for i = 1 : qty_suggest
            disp([num2str(i) '. ' Dict{ind_best_dict(i)} ' (' num2str(Score_Dict(ind_best_dict(i))) ')'])
        end

        %% Score the remaining words
        
        Score_List = ones(length(List),1);
        for w = 1 : length(List)
            for i = 1 : word_length
                Score_List(w) = Score_List(w) * PROB(find(List{w}(i)==alphabet), i);
            end
        end
        
        disp(' ')
        [~, ind_best_list] = sort(Score_List,'descend');
        disp('Most probable guesses (to win):')
        disp(' ')
        for i = 1 : min([length(List) qty_suggest])
            disp([num2str(i) '. ' List{ind_best_list(i)} ' (' num2str(Score_List(ind_best_list(i))) ')'])
        end
        disp(' ')

        %% Collect a guess/response pair from user
        
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
        
        %% Eliminate words per guess/response pair
        
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
        
        ind_round = ind_round + 1;
        
    end
    
    if length(List) == 0
        error('Guesses did not converge')
    else
        disp(divider)
        disp(['Solution: ' List{:}])
    end
    
% end













































