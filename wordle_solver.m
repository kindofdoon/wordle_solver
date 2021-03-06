% function wordle_solver

    % A computer program to solve the word-guessing game "Wordle",
    % located at https://www.powerlanguage.co.uk/wordle/
    
    % Uses statistically-informed guesses, game heuristics, and process of
    % elimination to determine the solution in as few moves as possible.
    
    % Case-sensitive. Must use lowercase only.
    
    % Usermodes:
        % 'manual'
            % The program suggests optimal next guesses. The player
            % manually informs the program of their guesses and the
            % responses.
        % 'auto'
            % The program plays against itself. The user can specify a set
            % of solutions to solve, or the number of randomized games to
            % play.
        % 'debug'
            % The program plays against itself as in 'auto' mode, but
            % pauses after each move to show some diagnostic data
    
    % Responses use the following syntax:
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
            % Added actual Wordle guess and solution dictionaries
            % Now can automatically play against itself
            % 100 trials, 3.69 mean, 0.61 stdev, worst score of 5
        % 2022-01-25:
            % Minor cleanup, documentation improvements
        % 2022-01-28:
            % Improved guess selection by seeing if any top-value guesses
            % are also possible solutions. Fixed a bug that was penalizing
            % words with repeated letters. Improved elimination with gray
            % tiles and matching letters.
        % 2022-02-06:
            % Various speedups. For all 2,315 games (about two hours),
            % mean of 3.692, stdev of 0.734, worst score of 6. Slight
            % improvement to the probability-value transfer function -
            % moved from Gaussian to sine, though kept the option to use
            % Gaussian if desired. Also experimented with a triangle wave.
        % 2022-02-08
            % Huge speedups, now runs all 2,315 games in ~17 min
        % 2022-02-09
            % Slight performance improvement, misc. cleanup.
            % Added some new transfer function shapes
            % Mean: 3.5961, Stdev. 0.67916, Worst 6 (for all 2,315)
        % 2022-02-11
            % Major simplification to the elimination algorithm. Now, I
            % simply check against wordle_response.m for consistency and
            % eliminate that way, rather that checking tile-by-tile
    
    %%
    
    clear
    clc
    
    %% Inputs
    
    record_log    = 0;
    show_graphics = 1;
    usermode      = 'auto'; % 'auto', 'manual', or 'debug'
    qty_suggest   = 10;     % 'manual' usermode - number of words to show after every guess
    auto_game_qty = 2315;   % 'auto'   usermode - number of random games to play; if set to 2315, plays all games in order
    auto_list     = {       % 'auto'   usermode - specific solutions to solve; leave empty if not using

                    };
    
    fn_dict_solutions = 'wordlist_solutions.txt';
    fn_dict_guesses   = 'wordlist_guesses.txt';
    
    % Solver parameters
    P_vs_V.shape = 'sine'; % transfer function, probability vs. value
    WEIGHT       = zeros(5)+1/2 + (1/2).*eye(5);
    QUALITY      = [1 1/2 1/3 0 0; 0 1/4 1/4 0 0; 0 0 1/3 0 0; 0 0 0 0 0; 0 0 0 0 0];
    
    %% Generate transfer function
    % Probability P vs. value V (one-dimensional)
    
    P_vs_V.res  = 1000;
    P_vs_V.prob = linspace(0,1,P_vs_V.res);
    switch P_vs_V.shape
        case 'gaussian'
            P_vs_V.mean  = 0.5;
            P_vs_V.stdev = 0.15;
            P_vs_V.val   = (1./(P_vs_V.stdev.*sqrt(2.*pi))) .* exp((-1/2).*((P_vs_V.prob-P_vs_V.mean)./P_vs_V.stdev).^2);
            P_vs_V.val([1,end]) = 0;
            P_vs_V.val = P_vs_V.val ./ max(P_vs_V.val(:));
        case 'triangle'
            P_vs_V.val = interp1([0 0.5 1], [0 1 0], P_vs_V.prob);
        case 'sine'            
            P_vs_V.val = sin(P_vs_V.prob*pi) .^ (2/3);
            P_vs_V.val([1,end]) = 0;
        case 'parabola'
            P_vs_V.val = -(P_vs_V.prob-0.5).^2;
            P_vs_V.val = (P_vs_V.val-min(P_vs_V.val)) ./ (max(P_vs_V.val)-min(P_vs_V.val));
        case 'quartic'
            P_vs_V.val = -(P_vs_V.prob-0.5).^4;
            P_vs_V.val = (P_vs_V.val-min(P_vs_V.val)) ./ (max(P_vs_V.val)-min(P_vs_V.val));
        case 'quartic_parabola_blend'
            P_vs_V.val = 4.*-(P_vs_V.prob-0.5).^4 -(P_vs_V.prob-0.5).^2;
            P_vs_V.val = (P_vs_V.val-min(P_vs_V.val)) ./ (max(P_vs_V.val)-min(P_vs_V.val));
        case 'arc'
            th = linspace(pi,0,length(P_vs_V.prob));
            x = cos(th);
            y = sin(th);
            P_vs_V.val = interp1(x,y,linspace(-1,1,1000));
            P_vs_V.val([1,end]) = 0;
        otherwise
            error('P_vs_S.shape not recognized')
    end
    
    switch usermode
        case 'debug'
            figure(1)
            clf
            set(gcf,'color','white')
            plot(P_vs_V.prob, P_vs_V.val, 'k')
            set(gca,'xtick',0:0.1:1)
            set(gca,'ytick',0:0.1:1)
            grid on
            grid minor
            xlabel('Probability, ~')
            ylabel('Value, ~')
            axis square
            axis equal
            drawnow
        otherwise
            % Do nothing
    end
    
    %% Constants
    
    moves_to_win = 6; % only used to calculate win rate, does not limit the number of moves
    alphabet = 'abcdefghijklmnopqrstuvwxyz';
    
    % Alphabet cell array, just for labeling plots
    alpha_cell_array = cell(length(alphabet),1);
    for ind_letter = 1 : length(alphabet)
        alpha_cell_array{ind_letter} = alphabet(ind_letter);
    end
    
    % Official Wordle colors
    color_g = [129,170,105];
    color_y = [195,180,95];
    color_k = [121,124,126];
    
    %% Load dictionaries
    
    DICT_SOL_read_only = sort(importdata(fn_dict_solutions));
    DICT_GUE           = sort(importdata(fn_dict_guesses));
    
    word_length = length(DICT_SOL_read_only{1});
    
    %% Pre-calculate quantities for speed
    
    % Alphabetical indices, and quantity of letter-matching tiles
    IA = zeros(length(DICT_GUE),word_length); % index, alphabetical
    QM = zeros(length(DICT_GUE),word_length); % quantity, letter-matching tiles
    for w = 1 : length(DICT_GUE) % for each word
        this_word = DICT_GUE{w};
        for t = 1 : word_length % for each tile
            this_letter = this_word(t);
            IA(w,t) = find(this_letter == alphabet); % alphabetical index of this tile
            ind_match = find(this_letter == this_word); % indices of tiles with this letter
            QM(w,t) = length(ind_match); % number of tiles of this letter
        end
    end
    
    One_Col_Vect = ones(word_length,1);

    %% Main body for all game(s)
    
    ind_game = 1;
    
    switch usermode
        case {'auto', 'debug'}
            if length(auto_list) >= 1
                auto_game_qty = length(auto_list);
            end
        case 'manual'
            auto_game_qty = 1;
    end
    
    % Record some information
    SCORES = [];
    
    if record_log
        timestamp = datestr(now,'yyyy_mm_dd_HH_MM_SS_AM');
        timestamp = regexprep(timestamp, ' ', ''); % delete spaces
        fn_diary = [mfilename '_log_' timestamp '.txt'];
        diary(fn_diary)
        diary on
        disp(fn_diary)
    end
    
    tic
    
    correct_response = repmat('g',[1,word_length]);
    
    while ind_game <= auto_game_qty

        %% Initialize

        DICT_SOL = DICT_SOL_read_only;          % reset the solutions
        response = repmat('k',[1,word_length]); % initialize as all wrong
       
        if show_graphics
            figure(5)
            clf
            set(gcf,'color','white')
            hold on
        end
                
        % Generate the solution
        switch usermode
            case {'auto', 'debug'}
                
                if auto_game_qty == length(DICT_SOL_read_only) % user wants to play every game
                    SOLUTION = DICT_SOL_read_only{ind_game};
                    
                elseif length(auto_list) >= 1 % user has specified which specific games they want to play
                    SOLUTION = auto_list{ind_game};
                    
                else
                    i_sol = randi(length(DICT_SOL),1);
                    SOLUTION = DICT_SOL{i_sol};
                    
                end
                disp(['Game #' num2str(ind_game) ': ' SOLUTION])
            case 'manual'
                % Do nothing
        end

        ind_round = 0;
        
        while ~strcmp(response,correct_response) && length(DICT_SOL)>=1 % while you haven't gotten it right, but still have more words to guess
            
            ind_round = ind_round + 1;
            disp(' ')
            disp(['Words remaining: ' num2str(length(DICT_SOL))])

            %% Probability distributions for possible solutions

            PROB = zeros(length(alphabet), word_length);

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
            end

            switch usermode
                case 'debug'
                    figure(2)
                        clf
                        set(gcf,'color','white')
                        pos = get(gcf,'position');
                        set(gcf,'position',[pos(1) 50 560 900])
                    for ind_position = 1 : word_length
                        subplot(word_length,1,ind_position)
                        cla
                        bar(1:length(alphabet), PROB(:,ind_position), 'FaceColor', zeros(1,3)+0.5)
                        grid on
                        grid minor
                        set(gca,'xtick',1:length(alphabet))
                        set(gca,'xticklabel',alpha_cell_array)
                        pos = get(gca,'position');
                        set(gca,'position', [pos(1)+0.02 pos(2)+0.01 pos(3:4)])
                        title(['\rmProbability of ' num2str(length(DICT_SOL)) ' Valid ' num2str(word_length) '-Letter Words By Position #' num2str(ind_position) '\rm'])
                        xlim([0 length(alphabet)+1])
                        ylim([0 ceil(max(PROB(:))/0.05)*0.05])
                    end
                otherwise
                    % Do nothing
            end

            %% Value distributions for possible solutions

            VALUE = interp1(P_vs_V.prob, P_vs_V.val, PROB(:));
            [val_top, ind_top] = sort(VALUE, 'descend');
            [row_top, col_top] = ind2sub(size(PROB),ind_top);
            VALUE = reshape(VALUE, size(PROB));

            switch usermode
                case 'debug'
                    figure(3)
                        clf
                        set(gcf,'color','white')
                        pos = get(gcf,'position');
                        set(gcf,'position',[pos(1) 50 560 900])

                    for ind_position = 1 : word_length
                        % Plot the result
                        subplot(word_length,1,ind_position)
                        cla
                        bar(1:length(alphabet), VALUE(:,ind_position), 'FaceColor', zeros(1,3)+0.5)
                        grid on
                        grid minor
                        set(gca,'xtick',1:length(alphabet))
                        set(gca,'xticklabel',alpha_cell_array)
                        xlim([0 length(alphabet)+1])
                        if max(VALUE(:)) > 0
                            ylim([0 max(VALUE(:))])
                        end
                        title(['\rmValue of ' num2str(length(DICT_SOL)) ' Valid ' num2str(word_length) '-Letter Words By Position #' num2str(ind_position) '\rm'])
                    end
                otherwise
                    % Do nothing
            end

            %% Score guesses

            Score_Gue = zeros(length(DICT_GUE),1);
            
            % Calculate the quantity of unity-probability tiles for each letter
            QU = zeros(length(alphabet),1);
            for ind_alpha = 1 : length(alphabet)
                ind_u = find(PROB(ind_alpha,:)==1); % indices of unity-probability letter-matching tiles
                QU(ind_alpha) = length(ind_u); % number of green tiles of this letter
            end
            
            for w = 1 : length(DICT_GUE) % for each word
                
                ind_alpha = IA(w,:);
                q_m       = QM(w,:);
                q_u       = QU(ind_alpha);
                lin_ind   = q_u+1 + (q_m'-1)*word_length; % equivalent to sub2ind, but faster
                Qual      = QUALITY(lin_ind);
                
                prob   = PROB(ind_alpha,:);
                skip   = find(diag(prob)==1);
                Toggle = ones(word_length,1);
                Toggle(skip) = 0;
                
%                 Score_Gue(w) = sum( sum(VALUE(ind_alpha,:).*WEIGHT, 2) .* Qual.*Toggle, 1);
                Score_Gue(w) = ((VALUE(ind_alpha,:).*WEIGHT) * One_Col_Vect .* Qual .* Toggle)' * One_Col_Vect;

            end
            
            ms = max(Score_Gue(:));
            if ms ~= 0 % prevent divide-by-zero
                Score_Gue = Score_Gue ./ ms; % normalize 0-1
            end

            [~, ind_best_gue] = sort(Score_Gue,'descend');
            
            switch usermode
                case 'auto'
                    % Do nothing
                case {'manual','debug'}
                    disp(' ')
                    disp('Guesses, top valuable, to advance:')
                    for i = 1 : qty_suggest
                        disp([num2str(i) '. ' DICT_GUE{ind_best_gue(i)} ' (' num2str(Score_Gue(ind_best_gue(i))) ')'])
                    end
            end

            %% Show remaining solutions
            
            switch usermode
                case 'auto'
                    % Do nothing
                case {'manual','debug'}
                    disp(' ')
                    disp('Guesses, alphabetical, to win:')
                    for i = 1 : min([length(DICT_SOL) qty_suggest])
                        disp([num2str(i) '. ' DICT_SOL{i}])
                    end
                    disp(' ')
            end

            %% Get a guess/response pair

            switch usermode

                case {'auto', 'debug'}

                    switch length(DICT_SOL)
                        case 1
                            % We already know the solution by process of
                            % elimination, and just need to formally guess it
                            guess = DICT_SOL{:};
                        case 2
                            % Two solutions remain, we may as well pick one
                            guess = DICT_SOL{1}; % pick the alphabetical first one
                        otherwise
                            % Three or more solutions remain, must continue
                            % advancing rather than trying to win
                            
                            % If there is a tie among the most valuable
                            % words, see if any one is also a solution, and
                            % if so, pick it. Otherwise just pick the most
                            % valuable word.
                            
                            ind_top_gue  = find(Score_Gue == max(Score_Gue));
                            top_gue      = DICT_GUE(ind_top_gue);
                            top_intersec = intersect(top_gue, DICT_SOL);
                            
                            if ~isempty(top_intersec) % one word is both most valuable and most probable
                                guess = top_intersec{:};
                            else
                                guess = DICT_GUE{ind_best_gue(1)};
                            end
                            
                    end
                        
                    response = wordle_response(SOLUTION, guess);
                    disp([guess ' - ' response])

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

            to_eliminate = zeros(length(DICT_SOL),1);
            
            for s = 1 : length(DICT_SOL)
                response_hypothetical = wordle_response(DICT_SOL{s}, guess);    
                if ~strcmp(response_hypothetical, response)
                    to_eliminate(s) = 1;
                end
            end
            
            DICT_SOL = DICT_SOL(find(~to_eliminate));
            
            %% Show the game state
            
            if show_graphics
                    
                figure(5)
                y = -ind_round;

                for t = 1 : word_length

                    switch response(t)
                        case 'k'
                            col = color_k;
                        case 'y'
                            col = color_y;
                        case 'g'
                            col = color_g;
                    end

                    square_size = 0.90;
                    fill_x = [1 1 0 0].*square_size - 1/2*square_size;
                    fill_y = [1 0 0 1].*square_size - 1/2*square_size;
                    fill(t+fill_x, y+fill_y, col./255)
                    text(t,y, ['\bf '  upper(guess(t)) ' '],'Color', 'w', 'FontSize',25,'FontName','FixedWidth','HorizontalAlignment','center','VerticalAlignment','middle')
                    axis equal
                    xlim([0 6])
                    ylim([-7 0])

                end

                drawnow
                
            end
            
            switch usermode
                case 'debug'
                    pause
                otherwise
                    % Do nothing
            end
        
        end % At this point, have either won the game or run out of possible solutions

        if length(DICT_SOL) ~= 1
            warning('Guesses did not converge')
        else
            SCORES(ind_game) = ind_round;
            
            disp(' ')
            disp(['Score: ' num2str(ind_round)]);
            disp(['Mean:  ' num2str(mean(SCORES(:)))])
            disp(['Stdev: ' num2str(std(SCORES(:)))])
            disp(['Worst: ' num2str(max(SCORES(:)))])
            disp(['Wins:  ' num2str(length(find(SCORES<=moves_to_win))/length(SCORES)*100,'%.2f') '%'])
            disp([])
            rate = toc/ind_game; % sec/game
            games_remaining = auto_game_qty - ind_game;
            time_remaining  = games_remaining * rate; % sec
            time_remaining_mm = floor(time_remaining/60);
            time_remaining_ss = round(time_remaining - time_remaining_mm*60);
            disp(['Left:  ' num2str(time_remaining_mm) 'm' num2str(time_remaining_ss) 's'])
            disp('===========================')
            
            switch usermode
                case 'auto'
                    % Show a persistent monitor so the user doesn't have to
                    % read moving text in Command Window
                    figure(4)
                    clf
                    set(gcf,'color','white')
                    axis off
                    text(0,mean(ylim),{
                        ['\bfGame #' num2str(ind_game) ': ' SOLUTION '\rm']
                        ['Score: ' num2str(ind_round)]
                        ['Mean:  ' num2str(mean(SCORES(:)))]
                        ['Stdev: ' num2str(std(SCORES(:)))]
                        ['Worst: ' num2str(max(SCORES(:)))]
                        ['Wins:  ' num2str(length(find(SCORES<=moves_to_win))/length(SCORES)*100,'%.2f') '%']
                        ['Left:  ' num2str(time_remaining_mm) 'm' num2str(time_remaining_ss) 's']
                        },'FontName','FixedWidth','FontSize',12)
                    drawnow
                otherwise
                    % Do nothing
            end

        end
        
        ind_game = ind_game + 1;
        
    end
    
    if record_log
        diary off
    end
    
% end

















































