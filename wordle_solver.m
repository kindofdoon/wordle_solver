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
        % 2022-01-24:
            % Now can automatically play against itself
            % 100 trials, 3.69 mean, 0.61 stdev
    
    %%
    
    clear
    clc
    
    %% Inputs
    
    usermode    = 'auto'; % 'auto' or 'manual'
    auto_iter   = 1; % 'auto' usermode - number of iterations to perform
    qty_suggest = 5; % 'manual' usermode - number of words to show after every guess
    
    fn_dict_solutions = 'wordlist_solutions.txt';
    fn_dict_guesses   = 'wordlist_guesses.txt';
    
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
    
    switch usermode
        case 'auto'
            % Do nothing
        case 'manual'
            figure(5)
                clf
                set(gcf,'color','white')
                plot(Gauss.prob, Gauss.val, 'k')
                grid on
                grid minor
                xlabel('Probability, ~')
                ylabel('Value, ~')
    end
    
    %% Main body
    
    ind_iter = 1;
    
    if strcmp(usermode, 'manual')
        auto_iter = 1;
    end
    
    SOLS   = {};
    SCORES = [];
    
    while ind_iter <= auto_iter

        %% Load dictionary

        DICT_SOL = sort(importdata(fn_dict_solutions));
        DICT_GUE = sort(importdata(fn_dict_guesses));
        word_length = length(DICT_SOL{1});

        %% Main body

        switch usermode

            case 'auto'

                i_sol = randi(length(DICT_SOL),1);
                SOLUTION = DICT_SOL{i_sol};
                disp(['Solution: ' SOLUTION])

            case 'manual'

                % Do nothing
        end

        ind_round = 1;

        while length(DICT_SOL) > 1

            %% Show the probability distributions for remaining words

            PROB = zeros(length(alphabet), word_length);

            if strcmp(usermode,'manual')
            figure(1)
                clf
                set(gcf,'color','white')
                pos = get(gcf,'position');
                set(gcf,'position',[pos(1:2) 560 900])
            end

            for ind_position = 1 : word_length

                letters = repmat(' ',[length(DICT_SOL),1]);
                for w = 1 : length(DICT_SOL)
                    letters(w) = DICT_SOL{w}(ind_position);
                end
                qty_words = zeros(length(alphabet),1);
                for ind_letter = 1 : length(alphabet)
                    qty_words(ind_letter) = length(find(letters == alphabet(ind_letter)));
                end
                PROB(:,ind_position) = qty_words ./ length(DICT_SOL); % normalize from counts to probabilities

                if strcmp(usermode,'manual')
                    % Plot the result
                    subplot(word_length,1,ind_position)
                    cla
                    bar(1:length(alphabet), PROB(:,ind_position), 'FaceColor', zeros(1,3)+0.5)
                    grid on
                    grid minor
                    set(gca,'xtick',1:length(alphabet))
                    set(gca,'xticklabel',alpha_cell_array)
                    xlim([0 length(alphabet)+1])
                    title(['\rmProbability of ' num2str(length(DICT_SOL)) ' Valid ' num2str(word_length) '-Letter Words By Position #' num2str(ind_position) '\rm'])
                end

            end

            if strcmp(usermode,'manual')
                for ind_position = 1 : word_length
                    subplot(word_length,1,ind_position)
                    ylim([0 max(PROB(:))])
                end
            end

            %% Convert probabilities into values

            VAL = interp1(Gauss.prob, Gauss.val, PROB(:));
            [val_top, ind_top] = sort(VAL, 'descend');
            [row_top, col_top] = ind2sub(size(PROB),ind_top);
            VAL = reshape(VAL, size(PROB));

            if strcmp(usermode,'manual')
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
                    title(['\rmValue of ' num2str(length(DICT_SOL)) ' Valid ' num2str(word_length) '-Letter Words By Position #' num2str(ind_position) '\rm'])

                end
            end

            %%

            disp(divider)
            disp(['Iteration:       ' num2str(ind_iter)])
            disp(['Round:           ' num2str(ind_round)])
            disp(['Words remaining: ' num2str(length(DICT_SOL))])

            %% Score guesses

            Score_Gue = zeros(length(DICT_GUE),1);

            for w = 1 : length(DICT_GUE) % for each word

                for i = 1 : word_length % for each tile

                    ind_alpha = find(DICT_GUE{w}(i) == alphabet);

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

                    qty_match     = length(find(DICT_GUE{w}(i) == DICT_GUE{w})); % number of tiles with this letter
                    qty_non_green = qty_match - qty_green;
                    qty_non_green = max([1 qty_non_green]); % enforce non-zero, non-negative

                    % If we guess a tile that we already know is correct,
                    % it adds no value to any position (including its own)
                    if PROB(ind_alpha, i) ~= 1
                        Score_Gue(w) = Score_Gue(w) + dot(VAL(ind_alpha,:), gain_pos) / qty_non_green;
                    end

                end

            end

            [~, ind_best_gue] = sort(Score_Gue,'descend');
            
            switch usermode
                case 'auto'
                    % Do nothing
                case 'manual'
                    disp(' ')
                    disp('Most valuable guesses (to advance):')
                    disp(' ')
                    for i = 1 : qty_suggest
                        disp([num2str(i) '. ' DICT_GUE{ind_best_gue(i)} ' (' num2str(Score_Gue(ind_best_gue(i))) ')'])
                    end
            end

            %% Score solutions

            Score_List = ones(length(DICT_SOL),1);
            for w = 1 : length(DICT_SOL)
                for i = 1 : word_length
                    Score_List(w) = Score_List(w) * PROB(find(DICT_SOL{w}(i)==alphabet), i);
                end
            end

            [~, ind_best_sol] = sort(Score_List,'descend');
            
            switch usermode
                case 'auto'
                    % Do nothing
                case 'manual'
            
                    disp(' ')
                    disp('Most probable guesses (to win):')
                    disp(' ')
                    for i = 1 : min([length(DICT_SOL) qty_suggest])
                        disp([num2str(i) '. ' DICT_SOL{ind_best_sol(i)} ' (' num2str(Score_List(ind_best_sol(i))) ')'])
                    end
                    disp(' ')
            end

            %% Collect a guess/response pair from user

            switch usermode

                case 'auto'

                    if length(DICT_SOL)==2
                        guess = DICT_SOL{1};
                    else
                        guess = DICT_GUE{ind_best_gue(1)};
                    end
                    response = wordle_response(SOLUTION, guess);
                    disp(['Guess:    ' guess])
                    disp(['Response: ' response])

                case 'manual'

                    guess = input('Guess:    ','s');
                    if length(guess) ~= word_length
                        warning('Invalid length')
                        continue
                    end
                    if length(find(strcmp(DICT_GUE, guess))) ~= 1
                        warning('Invalid word')
                        continue
                    end

                    response = input('Response: ','s');
                    if length(response) ~= word_length
                        warning('Invalid length')
                        continue
                    end
                    if length(regexprep(response, '[kyg]', '')) > 0
                        warning('Invalid response, must solely contain [kyg]')
                        continue
                    end

            end

            %% Eliminate words per guess/response pair

            % Eliminate all entries from the list that are not consistent with
            % the most recent guess/response pair

            to_eliminate = zeros(length(DICT_SOL),1);

            for ind = 1 : word_length % for each letter

                letter = guess(ind);

                switch response(ind)

                    case 'k'

                        response_match = response(find(guess == letter));
                        if length(regexprep(response_match, 'k', '')) == 0 % All tile(s) of this letter were gray

                            % Eliminate all words that contain this letter
                            for w = 1 : length(DICT_SOL)
                                if length(regexprep(DICT_SOL{w}, letter, '')) ~= word_length
                                    to_eliminate(w) = 1;
                                end
                            end

                        else

                            % This is a gray tile, but there are other tile(s)
                            % of either yellow or green of the same letter. We
                            % know that the solution does not contain this
                            % letter at this position.

                            % Eliminate words that contain this letter in this position
                            for w = 1 : length(DICT_SOL)
                                if strcmp(DICT_SOL{w}(ind), letter)
                                    to_eliminate(w) = 1;
                                end
                            end

                        end

                    case 'y'

                        % Eliminate words that contain this letter in this position
                        for w = 1 : length(DICT_SOL)
                            if strcmp(DICT_SOL{w}(ind), letter)
                                to_eliminate(w) = 1;
                            end
                        end

                        % Eliminate words that do not contain this letter in non-green non-matching tiles
                        ind_search = intersect(find(response~='g'), find(guess~=letter));
                        for w = 1 : length(DICT_SOL)
                            if length(find(DICT_SOL{w}(ind_search) == letter)) == 0
                                to_eliminate(w) = 1;
                            end
                        end

                    case 'g'

                        % Eliminate words that do not contain this letter in this position
                        for w = 1 : length(DICT_SOL)
                            if ~strcmp(DICT_SOL{w}(ind), letter)
                                to_eliminate(w) = 1;
                            end
                        end

                    otherwise
                        error('Unrecognized response')

                end

            end

            % Eliminate words
            DICT_SOL = DICT_SOL(find(~to_eliminate));
            if ~strcmp(response, repmat('g',[1,word_length])) % if it didn't come back all green, must go another round
                ind_round = ind_round + 1;
            end

        end

        if length(DICT_SOL) == 0
            error('Guesses did not converge')
        else
            SOLS{ind_iter}   = DICT_SOL{:};
            SCORES(ind_iter) = ind_round;
            
            disp(' ')
            disp(['Solution: ' DICT_SOL{:}])
            disp(['Score:    ' num2str(ind_round)]);
            disp(['Average:  ' num2str(mean(SCORES(:)))])
            disp(['St. dev.: ' num2str(std(SCORES(:)))])
            disp(divider)
            disp(divider)
            

        end
        
        ind_iter = ind_iter + 1;
        
    end
    
% end













































