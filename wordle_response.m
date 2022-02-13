function response = wordle_response(solution, guess)

    len_sol = length(solution);

    if len_sol ~= length(guess)
        error('length(solution) ~= length(guess)')
    end
    
    % Initialize as gray
    response = 'k';
    response = response(:,ones(1,len_sol)); % equivalent to repmat('k',[1,length(solution)]), but faster
    
    % Green tiles
    for i = 1 : length(solution)
        
        if guess(i) == solution(i)
            response(i) = 'g';
            solution(i) = 'X'; % prevent double-matching
        end
        
    end
    
    % Yellow tiles
    for i = 1 : length(solution)
        
        if response(i) == 'g'
            continue % do not overwrite green tiles
        end
        
        ind_match = find(guess(i)==solution);
        
        if length(ind_match) > 0 % && guess(i)~=solution(i)
            
            response(i) = 'y';
            ind_match_first = min(ind_match);
            solution(ind_match_first) = 'X'; % prevent double-matching
            
        end
        
    end

end




















































