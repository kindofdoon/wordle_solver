% function compare_distributions

    clear
    clc
    
    %%
    
    opacity = 0.35;
    
    Dist = { % description, color, 
            'Author',   [1 0 0], [0,0.022462203023758,0.443196544276458,0.453563714902808,0.077321814254860,0.003455723542117,0]
            'Sanderson' [0 1 0], [1 83 1239 890 98 4 0]%[0 5 323 1403 548 36 0]
            'Twitter',  [0 0 1], [0.010593571474475,0.071463764145338,0.254661323655256,0.320308545097655,0.216871553509600,0.104942426487086,0.021158815630591]
           };
       
    %%
    
    figure(9)
    clf
    hold on
    set(gcf,'color','white')
    
    scores = 1 : 7;
    
    % Normalize
    for d = 1 : size(Dist,1)
        Dist{d,3} = Dist{d,3} ./ sum(Dist{d,3});
    end
    
    bars = cell2mat(Dist(:,3))';
    h_b = bar(bars);
    for b = 1 : size(Dist,1)
        h_b(b).FaceColor = (1-opacity).*ones(1,3) + opacity.*Dist{b,2};
        h_b(b).EdgeColor = 'none';
    end
    
    for d = 1 : size(Dist,1)
        
        av(d) = dot(scores, Dist{d,3});
        
        % Standard deviation
        mu(d) = 0;
        stdev(d) = 0;
        for s = 1 : length(scores)
            mu(d) = mu(d) + Dist{d,3}(s) * scores(s);
        end
        for s = 1 : length(scores)
            stdev(d) = stdev(d) + Dist{d,3}(s) * (scores(s)-mu(d))^2;
        end
        stdev(d) = sqrt(stdev(d));
        
        Gauss.res = 1000;
        Gauss.x   = linspace(0,8,Gauss.res);
        Gauss.y   = (1./(stdev(d).*sqrt(2.*pi))) .* exp((-1/2).*((Gauss.x-av(d))./stdev(d)).^2);
        plot(Gauss.x, Gauss.y, 'Color', Dist{d,2}, 'LineWidth', 2)
        
    end
    
    grid on
    grid minor
    
    xlim([0 8])
    set(gca,'xtick', 0:8)
    set(gca,'xticklabel', {'' '1' '2' '3' '4' '5' '6' 'x' ''})
    set(gca,'FontSize', 14)
    
    % Give a little headroom for the legend
%     ylim([0 max(ylim)+1*abs(mean(diff(get(gca,'ytick'))))])
    
    max_len = 0;
    for d = 1 : size(Dist,1)
        max_len = max([max_len length(Dist{d,1})]);
    end
    
    % Append to the legend
    for d = 1 : size(Dist,1)
        len = length(Dist{d,1});
%         Dist{d,1} = [Dist{d,1} ':' repmat(' ',[1,max_len-len]) ' Mean ' num2str(av(d),'%.3f') ', Stdev. ' num2str(stdev(d),'%.3f')];
    end
    
    legend(Dist(:,1), 'location', 'northwest')%, 'FontName', 'FixedWidth','Position',[0.17 0.80 0.76 0.18])
    
    pos = get(gca,'position');
    set(gca,'position',[pos(1,2)+[0.02 0.05] pos(3)*1.08 pos(4)*1])
    
    xlabel('Wordle Score')
    ylabel('Probability, ~')
    

% end



















































