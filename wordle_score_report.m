% function wordle_score_report

    clear
    clc
    
    fn_log = 'wordle_solver_log_2022_02_06_1_05_11_AM.txt';
    
    %%
    
    log = regexp(fileread(fn_log), '\r?\n', 'split')';
    log = [log{:}];
    tok = regexp(log, 'Score: ([0-9])', 'tokens')';
    
    scores = zeros(length(tok),1);
    for i = 1 : length(tok)
        s = tok{i};
        scores(i) = str2double(s{1});
    end
    
    disp(['Extracted ' num2str(length(scores)) ' scores'])
    
    bin.center = 1 : max(scores)+1;
    bin.qty = length(bin.center);
    
    for b = 1 : bin.qty
        bin.count(b) = length(find(bin.center(b) == scores));
    end
    
    bin.PDF = bin.count ./ sum(bin.count);
    bin.CDF = cumsum(bin.PDF);
    
    Gauss.mean = mean(scores);
    Gauss.stdev = std(scores);
    Gauss.res = 1000;
    Gauss.x   = linspace(0,max(scores),Gauss.res);
    Gauss.y   = (1./(Gauss.stdev.*sqrt(2.*pi))) .* exp((-1/2).*((Gauss.x-Gauss.mean)./Gauss.stdev).^2);
    Gauss.y   = Gauss.y ./ max(Gauss.y);
    
    figure(7)
    clf
    hold on
    set(gcf,'color','white')
    bar(bin.center, bin.count, 'FaceColor', zeros(1,3)+0.5)
    grid on
    grid minor
    xlabel('Wordle Score')
    ylabel('Number of Games')
    title({
            ['\bfDistribution of Scores for ' num2str(length(scores)) ' Wordle Games\rm\fontsize{9}']
            regexprep(fn_log,'\_','\\_')
            ['Mean: ' num2str(Gauss.mean,'%.3f') ', Standard Deviation: ' num2str(Gauss.stdev,'%.3f') ]
         })

    lbl = {'\bfScore Games PDF  CDF \rm'};
    lbl_latex = {'Score & Games & PDF & CDF\\'};
    for b = 1 : bin.qty
        game_qty_str = num2str(bin.count(b),'%04.f');
        lbl{end+1,1} = ['\bf' num2str(bin.center(b)) '\rm     ' game_qty_str '  ' num2str(bin.PDF(b),'%.3f') ' ' num2str(bin.CDF(b),'%.3f')];
        lbl_latex{end+1,1} = [num2str(bin.center(b)) ' & ' num2str(bin.count(b)) ' & ' num2str(bin.PDF(b),'%.3f') ' & ' num2str(bin.CDF(b),'%.3f') '\\'];
    end
    
    xlim([1 max(xlim)-1])
    ylim([0 max(ylim)+mean(abs(diff(get(gca,'ytick'))))]) % add some margin on top
    
    text(max(xlim), max(ylim), lbl, 'HorizontalAlignment','right','VerticalAlignment','top','FontName','FixedWidth', 'FontSize',10)
    
    plot(Gauss.x, Gauss.y .* max(bin.count), 'w','LineWidth',2)
    plot(Gauss.x, Gauss.y .* max(bin.count), 'k')

% end












































