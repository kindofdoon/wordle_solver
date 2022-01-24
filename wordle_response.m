function response = wordle_response(solution, guess)

    if length(solution) ~= length(guess)
        error('length(solution) ~= length(guess)')
    end
    
    % Initialize as gray
    response = repmat('k', [1,length(solution)]);
    
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
        
        if guess(i)~=solution(i) && length(find(guess(i)==solution))>0
            
            response(i) = 'y';
            i_match = min(find(solution==guess(i)));
            solution(i_match) = 'X'; % prevent double-matching
            
        end
        
    end

end




















































